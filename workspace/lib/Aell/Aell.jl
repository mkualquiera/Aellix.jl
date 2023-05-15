module Aell

import Base.display

struct AellDisplay <: AbstractDisplay
    io::IO
end

display(d::AellDisplay, @nospecialize x) = display(d, MIME"text/plain"(), x)
display(d::AellDisplay, M::MIME"text/plain", @nospecialize x) = Main.aellshow(d.io, M, x)
Core.eval(Main, :(aellshow(io::IO, M::MIME"text/plain", x::Any) = show(io,M,x)))

include("dsl.jl")

import REPL.LineEdit
import REPL.Terminals

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
        if result.visualize
            display(custom_display,result.value)
            result.visualize = false
        end
    end

    myprompt = LineEdit.Prompt("aell\$ ";
        prompt_prefix=Base.text_colors[:light_magenta],
        prompt_suffix=Base.text_colors[:normal],
        on_enter=my_callback, on_done=do_respond)

    modes = LineEdit.TextInterface[myprompt]

    interface = LineEdit.ModalInterface(modes)

    LineEdit.run_interface(term, interface)
end

end