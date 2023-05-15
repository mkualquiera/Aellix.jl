using Random

abstract type Filter end

SAMPLE_RATE = 11025

macro getinput(expr, args)
    :(
        if $(esc(expr)) isa Filter
            forward($(esc(expr)), $(esc(args)))
        else
            $(esc(expr))
        end
    )
end

macro getinput(expr)
    :(
        if $(esc(expr)) isa Filter
            forward($(esc(expr)))
        else
            $(esc(expr))
        end
    )
end

mutable struct SineSynth <: Filter
    frequency::Union{Filter, Float64}
    amplitude::Union{Filter, Float64}
    phase::Union{Filter, Float64}
    angle::Float64
end

function SineSynth(frequency, amplitude, phase)
    SineSynth(
        frequency,
        amplitude,
        phase,
        0.0,
    ) 
end

function forward(synth::SineSynth)::Array{Float64}
    frequency, = @getinput synth.frequency
    phase, = @getinput synth.phase
    amplitude, = @getinput synth.amplitude
    
    val = cos(synth.angle + phase) * amplitude

    synth.angle += frequency * 2 * pi / SAMPLE_RATE

    return [val]
end

struct Lerp <: Filter
    input::Filter
    input_a::Union{Filter, Float64}
    input_b::Union{Filter, Float64}
    output_a::Union{Filter, Float64}
    output_b::Union{Filter, Float64}
end

function forward(lerp::Lerp)::Array{Float64}
    input, = forward(lerp.input)
    input_a, = @getinput lerp.input_a
    input_b, = @getinput lerp.input_b
    output_a, = @getinput lerp.output_a
    output_b, = @getinput lerp.output_b

    val = (input - input_a) / (input_b - input_a) * (output_b - output_a) + output_a
    return [val] 
end

struct Quantize <: Filter
    input::Union{Filter, Float64}
    referencepitch::Float64
    referencenote::Int
    divisions::Int
end

function forward(quantize::Quantize)::Array{Float64}
    input, = @getinput quantize.input

    note = floor(input)
    
    result = (quantize.referencepitch * 
        (2^(1/quantize.divisions))^(note - quantize.referencenote))

    return [result]
end

TET12Quantize(input) = Quantize(input, 440, 0, 12)

mutable struct DiscreteMapper <: Filter
    input::Filter
    map::Array{Float64}
    octavelength::Float64
    lastindex::Int
    color::Any
end
colors = [:light_white, :light_red, :light_green, :light_yellow, :light_blue, :light_magenta, :light_cyan, :light_white]

function DiscreteMapper(input, map, octavelength)
    DiscreteMapper(
        input,
        map,
        octavelength,
        0,
        Base.text_colors[rand(colors)]
    )
end

function forward(discrete_mapper::DiscreteMapper)::Array{Float64}
    input, = forward(discrete_mapper.input)
    map = discrete_mapper.map
    
    in_range = input % 1
    #println(input)
    index = floor(Int64,in_range * length(map)) + 1

    if index != discrete_mapper.lastindex
        discrete_mapper.lastindex = index
        offset = 40
        for i in 1:map[index] + offset
            print(" ")
        end
        print(discrete_mapper.color)
        println(Char(0xF0))
    end

    octave = floor(input)

    return [map[index] + octave * discrete_mapper.octavelength]
end

MajorMapper(input::Filter,basenote::Int) = DiscreteMapper(
    input,
    basenote .+ [0.0,2.0,4.0,5.0,7.0,9.0,11.0],
    12.0
)

MinorMapper(input::Filter,basenote::Int) = DiscreteMapper(
    input,
    basenote .+ [0.0,2.0,3.0,5.0,7.0,8.0,10.0],
    12.0
)

BluesMapper(input::Filter,basenote::Int) = DiscreteMapper(
    input,
    basenote .+ [0.0,3.0,5.0,6.0,7.0,10.0],
    12.0
)

struct WhiteNoiseSynth <: Filter
    amplitude::Union{Filter, Float64}
end

function forward(noise::WhiteNoiseSynth)::Array{Float64}
    amplitude, = @getinput noise.amplitude
    return [amplitude * rand(Float64) * 2.0 - 1.0]
end

mutable struct StickyNoiseSynth <: Filter
    amplitude::Union{Filter, Float64}
    probability::Float64
    value::Float64
end

function StickyNoiseSynth(amplitude, probability)
    StickyNoiseSynth(
        amplitude,
        probability,
        0.0,
    )
end

function forward(noise::StickyNoiseSynth)::Array{Float64}
    amplitude, = @getinput noise.amplitude

    if rand(Float64) < noise.probability
        noise.value = rand(Float64) * 2.0 - 1.0
    end

    return [amplitude * noise.value]
end

mutable struct ZeroOrderHold <: Filter
    input::Filter
    frequency::Float64
    value::Float64
    timer::Float64
end

function ZeroOrderHold(input::Filter, frequency::Float64)
    ZeroOrderHold(
        input,
        frequency,
        0.0,
        1/frequency,
    ) 
end

function forward(hold::ZeroOrderHold)::Array{Float64}

    inputval, = @getinput hold.input

    if hold.timer <= 0
        hold.value = inputval
        hold.timer = 1/hold.frequency + hold.timer
    end

    hold.timer -= 1/SAMPLE_RATE

    return [hold.value] 
end

struct Mixer <: Filter
    inputs::Array{Filter}
    gains::Array{Union{Filter, Float64}}
end

function forward(mixer::Mixer)::Array{Float64}

    result = 0.0

    for i = 1:length(mixer.inputs)
        inputval, = @getinput mixer.inputs[i]
        gain, = @getinput mixer.gains[i]
        result += inputval * gain
    end

    return [result]
end

function init_audio()

    # Try to play a sine wave
    # Open the device
    dsp = open("/dev/dsp", "w")
    dspfd = System.fd(dsp)
    @info "File descriptor" dspfd
    # Set the fragment size
    fragment_size_selector = 9
    fragment_size = 1 << fragment_size_selector 
    frag = (16 << 16) + fragment_size_selector
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

    
    bpm = 30
    bps = bpm / 60

    #=
    synth = Mixer(
        [
            SineSynth(
                # Frequency:
                TET12Quantize(
                    BluesMapper(
                        Lerp(
                            ZeroOrderHold(WhiteNoiseSynth(1.0),6*bps),
                            -1.0,
                            1.0,
                            0.0,
                            1.0
                        ),
                        -5
                    )
                ), 
                1.0, 0.0
            ),
            SineSynth(
                # Frequency:
                TET12Quantize(
                    MinorMapper(
                        Lerp(
                            ZeroOrderHold(WhiteNoiseSynth(1.0),(1/2)*bps),
                            -1.0,
                            1.0,
                            0.0,
                            1.0
                        ),
                        -5-24
                    )
                ), 
                1.0, 0.0
            ),
        ],
        [0.25,0.25])
    =#
    synth = Mixer(
        [
            SineSynth(
                # Frequency:
                TET12Quantize(
                    MinorMapper(
                        Lerp(
                            ZeroOrderHold(StickyNoiseSynth(1.0,0.0005),2*bps),
                            -1.0,
                            1.0,
                            0.0,
                            1.0
                        ),
                        -9
                    )
                ), 
                1.0, 0.0
            ),
            SineSynth(
                # Frequency:
                TET12Quantize(
                    MinorMapper(
                        Lerp(
                            ZeroOrderHold(WhiteNoiseSynth(1.0),(1/2)*bps),
                            -1.0,
                            1.0,
                            0.0,
                            1.0
                        ),
                        -9-24
                    )
                ), 
                1.0, 0.0
            ),
        ],
        [0.25,0.25])


    iter = 0

    buffer = zeros(Int16, fragment_size)
    buffer_pointer = 1

    # Generate a sine wave
    while true
        if buffer_pointer > fragment_size
            write(dsp, buffer)
            buffer_pointer = 1
        end
        val = forward(synth)[1]

        val = clamp(val, -1, 1)
        sample = round(Int16,32767 * val)
        buffer[buffer_pointer] = sample
        buffer_pointer += 1
        
        # Println every 1/4 second
        if iter % (SAMPLE_RATE / 8) == 0
            println()
        end 
        iter += 1
    end    
end
