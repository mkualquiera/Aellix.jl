using Random

function init_audio()

    SAMPLE_RATE = 11025
    # Try to play a sine wave
    # Open the device
    dsp = open("/dev/dsp", "w")
    dspfd = System.fd(dsp)
    @info "File descriptor" dspfd
    # Set the fragment size
    fragment_size_selector = 5
    fragment_size = 1 << fragment_size_selector 
    frag = (1 << 16) + fragment_size_selector
    result = System.ioctl(dspfd, System.SNDCTL_DSP_SETFRAGMENT, Ref(frag))
    @warn "SNDCTL_DSP_SETFRAGMENT" result Libc.errno()
    # Set the sample rate
    result = System.ioctl(dspfd, System.SNDCTL_DSP_SPEED, Ref(SAMPLE_RATE))
    @warn "SNDCTL_DSP_SPEED" result Libc.errno()
    # Set the sample format
    System.ioctl(dspfd, System.SNDCTL_DSP_SETFMT, Ref(System.AFMT_S16_LE))
    @warn "SNDCTL_DSP_SETFMT" result Libc.errno()

    function semitone_to_freq(semitone)
        return 440 * 2 ^ (semitone / 12)
    end

    iter = 0

    buffer = zeros(Int16, fragment_size)
    buffer_pointer = 1

    theta = 0
    major_scale = [0, 2, 4, 5, 7, 9, 11, 12]
    note = major_scale[1]

    # Generate a sine wave
    while true
        if buffer_pointer > fragment_size
            write(dsp, buffer)
            buffer_pointer = 1
        end

        theta += 2 * pi * semitone_to_freq(note) / SAMPLE_RATE
        val = sin(theta)
        
        val = clamp(val, -1, 1)
        sample = round(Int16,32767 * val)
        buffer[buffer_pointer] = sample
        buffer_pointer += 1
        
        # Println every 1/4 second
        if iter % (SAMPLE_RATE / 8) == 0
            note = rand(major_scale)
            println("Note: $note")
        end 
        iter += 1
    end    
end
