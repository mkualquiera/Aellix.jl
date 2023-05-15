include("/lib/Aell/Aell.jl")

function init_aell()
    banner = read("/share/banner.txt", String)
    #println(banner)
    println(Base.text_colors[:normal])
    Core.eval(Main,:(include("/lib/Acorn/Acorn.jl")))
    Core.eval(Main,:(include("/lib/os_utils.jl")))
    while true
        try
            Aell.run()
        catch e
            @error "Error in Aell"
            for (exc, bt) in current_exceptions()
                showerror(stdout, exc, bt)
                println(stdout)
            end
        end
    end
end
