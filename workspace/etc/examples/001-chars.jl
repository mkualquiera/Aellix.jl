
function chars()
    return
    # Prints all ascii characters in a table
    for low in 0:15
        for high in 0:15
            print(string(Char(low * 16 + high), " "))
        end
        println()
    end

    while true
    end
end