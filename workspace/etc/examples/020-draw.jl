using Mmap

function draw()
    fb = open("/dev/fb0", "r+")

    fbinfo = System.getfbinfo(Int32(fd(fb)))

    println("xres: $(fbinfo.xres)")
    println("yres: $(fbinfo.yres)")
    println("bits_per_pixel: $(fbinfo.bits_per_pixel)")

    # MMap the framebuffer
    frame_memory = mmap(fb, Array{UInt8,1}, fbinfo.xres * fbinfo.yres * 4; grow=false)
    # Load image from /share/aella.raw
    im_height = 230
    im_width = 512
    img = Array{UInt8,1}(undef, im_width * im_height * 3)
    read!("/share/aella.raw", img)

    # Blit the image
    for y in 0:im_height-1
        for x in 0:im_width-1
            i = (y * im_width + x) * 3 + 1
            j = ((x + 100) * fbinfo.xres + (y + 100)) * 4
            frame_memory[j+0] = 0x0
            frame_memory[j+1] = img[i+2]
            frame_memory[j+2] = img[i+1]
            frame_memory[j+3] = img[i+0]
        end
    end

    run(`/usr/bin/julia`)
end
