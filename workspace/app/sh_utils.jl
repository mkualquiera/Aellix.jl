
function ls(p::S)::Vector{Base.Filesystem.StatStruct} where {S<:AbstractString}
    if isdir(p)
        return stat.((x->joinpath(p,x)).(readdir(p)))
    else
        return [stat(p)]
    end
end


function Main.aellshow(io::IO, M::MIME"text/plain", x::Vector{Base.Filesystem.StatStruct})
    println(io, "$(length(x)) entries")
    if length(x) == 0
        return
    end
    # Sort by mode
    x = sort(x, by=x->x.mode)
    # show permissions, size, modification time, and name
    header = ["perm" "size" "mtime" "name"]
    tnow = round(UInt, time())
    rows = vcat(map(x -> [
        Base.Filesystem.filemode_string(x.mode) #=
        =# string(x.size) #=
        =# string(Base.Filesystem.iso_datetime_with_relative(x.mtime, tnow)) #=
        =# string(x.desc)
    ], x)...)

    alldata = [header; rows]

    col_lens = (x->maximum(length.(x))).(eachcol(alldata))

    padded = [ rpad(alldata[i,j], col_lens[j]) for i in axes(alldata,1), 
        j in axes(alldata,2) ]

    # Print
    for row in eachrow(padded)
        println(io, join(row, " "))
    end
end


"""
    ls()

List the contents of the current directory.
"""
ls() = ls(pwd())

struct ClearScreen end

"""
    clear()

Clear the screen.
"""
clear() = ClearScreen()

function Main.aellshow(io::IO, M::MIME"text/plain", x::ClearScreen)
    print(io,"\033[2J")
    print(io,"\x1b[H")
end

"""
    echo(any)

Print the argument to the screen.
"""
echo(x) = x