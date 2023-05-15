"""
Script that bootstraps the operating system. (Analogous to init in busybox)
"""

using Logging

include("/lib/system.jl")

"""
    init()

Main function for initializing the operating system.
"""
function init()

    # If TERM isn't set, set it and call recursively
    if ENV["TERM"] == "linux"
        # Clear screen
        print("\033[2J")
        print("\x1b[H")
        @info "Setting environment variables..."
        ENV["TERM"] = "xterm"
        ENV["HOME"] = "/home"
        run(`/usr/bin/julia /app/init.jl`)
        return
    end

    @info "Mounting blocks..."
    # Mount /home as tmpfs
    System.mount("tmpfs", "/home", "tmpfs", UInt32(0), C_NULL)

    @info "Running init.d scripts..."
    for script in readdir("/etc/init.d")
        try
            @info "Running..." script
            path = joinpath("/etc/init.d", script)
            Base.invokelatest(include(path))
        catch e
            @error "Error running init.d script $script: $e"
            for (exc, bt) in current_exceptions()
                showerror(stdout, exc, bt)
                println(stdout)
            end
        end
    end

    @info "Init complete."
    # Loop for ever
    while true
        sleep(1)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    try
        init()
    catch e
        println("Error in init: $e")
        while true
            sleep(1)
        end
    end
end

init