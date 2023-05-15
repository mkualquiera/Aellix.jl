
function init_dev()
    result= System.mount("devtmpfs", "/dev", "devtmpfs", UInt32(0), C_NULL)
    @warn "devtmpfs mounted?" ispath("/dev") isdir("/dev") Libc.errno() result
end