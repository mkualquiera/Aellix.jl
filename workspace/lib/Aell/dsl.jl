
module DSL

@enum TokenizerState begin
    NORMAL
    STRING
    COMMENT
    ESCAPE
    LITERAL
end

struct Token
    pos::Int64
    line::Int64
    col::Int64
    type::TokenizerState
    token::String
    complete::Bool
end

"""
    tokenize(text)

Tokenize an Aell string into an array of tokens
"""
function tokenize(text::String)::Vector{Token}
    tokens = Token[]
    pos = 1
    line = 1
    col = 1
    mode = TokenizerState[NORMAL]
    buffer = ""
    function addtoken!(type::TokenizerState; complete::Bool=true)
        if buffer != ""
            push!(tokens, Token(pos, line, col, type, buffer, complete))
        end
        buffer = ""
    end
    while true
        if pos > length(text)
            complete = !(mode[end] in (STRING, LITERAL))
            addtoken!(mode[end], complete=complete)
            break
        end
        char = text[pos]
        if mode[end] == ESCAPE
            buffer *= char
            pop!(mode)
        elseif mode[end] == STRING
            if char == '"'
                buffer *= char
                addtoken!(STRING)
                mode[end] = NORMAL
            elseif char == '\\'
                push!(mode, ESCAPE)
            else
                buffer *= char
            end
        elseif mode[end] == LITERAL
            buffer *= char
            if char == '{'
                push!(mode, LITERAL)
            elseif char == '}'
                pop!(mode)
                if mode[end] != LITERAL
                    addtoken!(LITERAL)
                end
            end
        elseif mode[end] == NORMAL
            if char == '"'
                buffer *= char
                mode[end] = STRING
            elseif char == '{'
                buffer *= char
                push!(mode, LITERAL)
            elseif char == '\\'
                push!(mode, ESCAPE)
            elseif char == '#'
                buffer *= char
                mode[end] = COMMENT
            elseif isspace(char)
                if buffer != ""
                    addtoken!(NORMAL)
                end
            else
                buffer *= char
            end
        elseif mode[end] == COMMENT
            if char == '\n'
                mode[end] = NORMAL
                addtoken!(COMMENT)
            else
                buffer *= char
            end
        end
        if char == '\n'
            line += 1
            col = 1
        else
            col += 1
        end
        pos += 1
    end
    return tokens
end

using Random

mutable struct StackValue
    identifier::Symbol
    value::Any
    visualize::Bool
end

struct DSLState
    stack::Vector{StackValue}
end

"""
    eval(text)

Evaluate an Aell string
"""
function eval(state::DSLState, text::String)
    tokens = tokenize(text)
    eval(state, tokens)
end



"""
    eval(tokens)

Evaluate an array of tokens. Returns the value at the top of the stack.
"""
function eval(state::DSLState, tokens::Vector{Token})::Any
    # This works basically like a stack machine, or a forth interpreter.
    # Except we know the methods of functions so we can actually know how many
    # arguments to pop off the stack.

    stack = state.stack
    for token in tokens
        token_text = token.token
        if token.type == LITERAL
            # Remove { and }
            token_text = token_text[2:end-1]
            token_text = "begin $token_text end"
        end
        token_ast = Meta.parse(token_text)

        # As long as the ast is not a Symbol, we can just eval it and put it on the stack
        if !(token_ast isa Symbol) && !((token_ast isa Expr) && (token_ast.head == Symbol(".")))
            if token_ast isa QuoteNode
                token_ast = token_ast.value
            end
            # Generate a random identifier for it
            identifier = Symbol(randstring(10))
            let_ast = :($identifier = $token_ast)
            #println(let_ast)
            value = Core.eval(Main, let_ast)
            push!(stack, StackValue(identifier, value, true))
            continue
        end

        # For now we will assume that the symbol always refers to a function

        function remove_varargs(x)
            result = []
            for elem in x 
                if !(elem isa Core.TypeofVararg)
                    push!(result, elem)
                end
            end
            return result
        end

        get_type_params(x::DataType) = remove_varargs(x.parameters)
        get_type_params(x::UnionAll) = get_type_params(x.body)

        # Get the methods and get the unique number of arguments
        func = Core.eval(Main, token_ast)
        methods = Base.methods(func)
        parameters(method::Method) = begin
            length(get_type_params(method.sig))
        end
        method_args = (parameters.(methods) .- 1) |> unique
        # Sort descending
        sort!(method_args, rev=true)
        found_method = false
        for num_args in method_args
            # Get the hypothetical arguments
            if length(stack) < num_args
                continue
            end
            relevant = stack[end-num_args+1:end]
            relevant = reverse(relevant)
            args = map(x -> x.value, relevant)
            identifiers = map(x -> x.identifier, relevant)
            args_tuple = Tuple(args)
            args_tuple_type = typeof(args_tuple)
            # Get the methods that match the arguments
            try
                method = Base.which(func, args_tuple_type)
            catch
                continue
            end
            # If we got this far we can just call the function
            # Build the AST for the call
            identifier = Symbol(randstring(10))
            call_ast = Expr(:call, token_ast, identifiers...)
            call_ast = :($identifier = $call_ast)
            # Evaluate the AST
            value = Core.eval(Main, call_ast)
            # Pop the arguments off the stack
            for identifier in identifiers
                Core.eval(Main, :($identifier = nothing))
                pop!(stack)
            end
            # Push the result onto the stack
            if !isnothing(value)
                push!(stack, StackValue(identifier, value, true))
            end
            found_method = true
            break
        end
        if !found_method
            error("No matching method found for $token_text. " *
                "Perhaps you meant :$token_text?")
        end
    end

    # Return the value at the top of the stack
    if length(stack) == 0
        return nothing
    end
    return stack[end]
end

end