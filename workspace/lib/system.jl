module System

"""
    mount(source, target, filesystem, flags, data)

Mounts a filesystem at a given location.
"""
function mount(source::String, target::String, filesystem::String,
    flags::UInt32, data::Any)
    ccall(:mount, Cint, (Cstring, Cstring, Cstring, Culong, Cstring),
        source, target, filesystem, flags, data)
end

"""
Struct for winsize
"""
mutable struct Winsize
    ws_row::UInt16
    ws_col::UInt16
    ws_xpixel::UInt16
    ws_ypixel::UInt16
end

"""
    ioctl(fd, request, arg)

Performs an ioctl on a file descriptor.
"""
function ioctl(fd::Cint, request::Culong, arg::Any)
    ccall(:ioctl, Cint, (Cint, Culong, Ptr{Cvoid}), fd, request, arg)
end
ioctl(fd::A, request::B, arg::Any) where {A<:Integer,B<:Integer} = 
    ioctl(Cint(fd), Culong(request), arg)


"""
    fd(io)

Gets the file descriptor for a given IO object.
"""
function fd(io)::Cint
    Base.cconvert(Cint,Base._fd(io))
end

TIOCSWINSZ = 0x5414
TIOCGWINSZ = 0x5413

# == ALSA OSS ==

SNDCTL_DSP_RESET  = 0x00005410
SNDCTL_DSP_SYNC   = 0x00005411
SNDCTL_DSP_SPEED  = 0xc0045002
SNDCTL_DSP_STEREO = 0xc0045003
SNDCTL_DSP_GETBLKSIZE = 0x80045004
SNDCTL_DSP_SETFMT = 0xc0045005
SNDCTL_DSP_CHANNELS = 0xc0045006
SOUND_PCM_WRITE_FILTER = 0x0000540e
SNDCTL_DSP_POST = 0x0000540f
SNDCTL_DSP_SUBDIVIDE = 0xc0045009
SNDCTL_DSP_SETFRAGMENT = 0xc004500a

AFMT_S16_LE = 0x00000010
AFMT_S16_BE = 0x00000020

"""
    getwinsize(fd)

Gets the current window size.
"""
function getwinsize(fd::Cint)::Tuple{UInt16,UInt16}
    # Create a winsize
    ws = Winsize(0, 0, 0, 0)

    # Create a pointer to the winsize
    pws = pointer_from_objref(ws)

    # Get the window size first
    result = ioctl(fd, Int32(TIOCGWINSZ), pws)

    return (ws.ws_row, ws.ws_col)
end

"""
    setwinsize(fd, rows, cols)

Sets the current window size.
"""
function setwinsize(fd::Cint, rows::UInt16, cols::UInt16)
    # Create a winsize
    ws = Winsize(rows, cols, 0, 0)

    # Create a pointer to the winsize
    pws = pointer_from_objref(ws)

    # Call ioctl
    result = ioctl(fd, Int32(TIOCSWINSZ), pws)
end

"""
    mknod(path, mode, dev)

Creates a node at a given path.
"""
function mknod(path::String, mode::UInt32, dev::UInt32)
    ccall(:mknod, Cint, (Cstring, Cuint, Cuint), path, mode, dev)
end
mknod(path::String, a::A, b::B) where {A<:Integer,B<:Integer} = 
    mknod(path, UInt32(a), UInt32(b))

S_IFREG = 0o100000
S_IFDIR = 0o040000
S_IFIFO = 0o010000
S_IFSOCK = 0o014000
S_IFBLK = 0o060000
S_IFCHR = 0o020000
S_IRUSR = 0o000400
S_IWUSR = 0o000200

"""
    makedev(major, minor)

Creates a device number from a major and minor number.
"""
function makedev(major::UInt64, minor::UInt64)::UInt32
    device  = (major & 0x00000FFF) << 8
    device |= (major & 0xFFFFF000) << 32
    device |= (minor & 0x000000FF) << 0
    device |= (minor & 0xFFFFFF00) << 12
    device
end
makedev(major::A, minor::B) where {A<:Integer,B<:Integer} = 
    makedev(UInt64(major), UInt64(minor))

FBIOGET_VSCREENINFO = 0x4600

struct fb_bitfield
    offset::UInt32
    length::UInt32
    msb_right::UInt32
end

mutable struct fb_var_screeninfo
    xres::UInt32
    yres::UInt32
    xres_virtual::UInt32
    yres_virtual::UInt32
    xoffset::UInt32
    yoffset::UInt32
    bits_per_pixel::UInt32
    grayscale::UInt32
    red::fb_bitfield
    green::fb_bitfield
    blue::fb_bitfield
    transp::fb_bitfield
    nonstd::UInt32
    activate::UInt32
    height::UInt32
    width::UInt32
    accel_flags::UInt32
    pixclock::UInt32
    left_margin::UInt32
    right_margin::UInt32
    upper_margin::UInt32
    lower_margin::UInt32
    hsync_len::UInt32
    vsync_len::UInt32
    sync::UInt32
    vmode::UInt32
    rotate::UInt32
    colorspace::UInt32
    reserved::UInt32
end

"""
    getfbinfo(fd)

Gets the framebuffer info.
"""
function getfbinfo(fd::Cint)::fb_var_screeninfo
    # Create a fb_var_screeninfo
    fbinfo = fb_var_screeninfo(0, 0, 0, 0, 0, 0, 0, 0, fb_bitfield(0, 0, 0),
        fb_bitfield(0, 0, 0), fb_bitfield(0, 0, 0), fb_bitfield(0, 0, 0), 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

    # Create a pointer to the fb_var_screeninfo
    pfbinfo = pointer_from_objref(fbinfo)

    # Call ioctl
    result = ioctl(fd, Int32(FBIOGET_VSCREENINFO), pfbinfo)

    return fbinfo
end

end