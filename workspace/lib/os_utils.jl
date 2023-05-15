
module OsUtils

function ls(p::String)::Vector{Base.Filesystem.StatStruct}
    if isdir(p)
        return stat.((x->joinpath(p,x)).(readdir(p)))
    else
        return [stat(p)]
    end
end


function Main.aellshow(io::IO, M::MIME"text/plain", x::Vector{Base.Filesystem.StatStruct})
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

    padded = [ rpad(alldata[i,j], col_lens[j]) for i in 1:size(alldata,1), 
        j in 1:size(alldata,2) ]

    # Print
    for row in eachrow(padded)
        println(io, join(row, " "))
    end
end

end