module Aell

import Base.display

struct AellDisplay <: AbstractDisplay
    io::IO
end

display(d::AellDisplay, @nospecialize x) = display(d, MIME"text/plain"(), x)
display(d::AellDisplay, M::MIME"text/plain", @nospecialize x) = Main.aellshow(d.io, M, x)
Core.eval(Main, :(aellshow(io::IO, M::MIME"text/plain", @nospecialize x) = show(io, M, x)))

include("dsl.jl")

import REPL.LineEdit
import REPL.Terminals

function ps1()
    curr_dir = pwd()
    return "aellix [$(curr_dir)] \$ "
end

function run()

    state = DSL.DSLState([])

    term_env = get(ENV, "TERM", @static Sys.iswindows() ? "" : "dumb")
    term = Terminals.TTYTerminal(term_env, stdin, stdout, stderr)

    custom_display = AellDisplay(stdout)

    function my_callback(s)
        line = String(take!(copy(LineEdit.buffer(s))))
        tokens = DSL.tokenize(line)
        tokens[end].complete
    end

    myprompt = Nothing

    function do_respond(s, buf, ok::Bool)
        line = String(take!(buf)::Vector{UInt8})
        result = DSL.eval(state, line)
        if !isnothing(result) && result.visualize
            display(custom_display, result.value)
            println()
            result.visualize = false
        end
        myprompt.prompt = ps1()
    end

    myprompt = LineEdit.Prompt(ps1();
        prompt_prefix=Base.text_colors[:light_magenta],
        prompt_suffix=Base.text_colors[:normal],
        on_enter=my_callback, on_done=do_respond)

    modes = LineEdit.TextInterface[myprompt]

    interface = LineEdit.ModalInterface(modes)

    # recursively eval everything in $PATH
    function eval_dir(path::S) where {S<:AbstractString}
        for file in readdir(path)
            if isdir(joinpath(path, file))
                eval_dir(joinpath(path, file))
            else
                # See if it ends in .jl
                if endswith(file, ".jl")
                    # Eval it
                    try
                        file_path = joinpath(path, file)
                        Core.eval(Main, :(include($file_path)))
                    catch e
                        @error "Error running $file: $e"
                        for (exc, bt) in current_exceptions()
                            showerror(stdout, exc, bt)
                            println(stdout)
                        end
                    end
                end
            end
        end
    end

    for path in split(ENV["PATH"], ":")
        eval_dir(path)
    end

    LineEdit.run_interface(term, interface)
end

end