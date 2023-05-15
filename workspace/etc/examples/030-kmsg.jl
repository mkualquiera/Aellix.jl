

function kmsg()
    # Read /proc/kmsg and print to stdout
    while true
    end
    file = open("/proc/kmsg", "r")
    while !eof(file)
        println(readline(file))
    end
end