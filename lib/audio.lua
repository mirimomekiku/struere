local Audio = {}

Audio.sfx = {}
Audio.master_vol = 0.8
Audio.sfx_vol = 1.0
Audio.music_vol = 0.5

function Audio.init()
    Audio.loadSFX()
end

function Audio.newSFX(freq, duration, waveform, volume)
    local sample_rate = 44100
    local samples = math.floor(sample_rate * duration)
    local sound = love.sound.newSoundData(samples, sample_rate, 16, 1)
    volume = volume or 0.5

    for i = 0, samples - 1 do
        local t = i / sample_rate
        local sample = 0

        if waveform == "sine" then
            sample = math.sin(2 * math.pi * freq * t)
        elseif waveform == "square" then
            sample = math.sin(2 * math.pi * freq * t) > 0 and 1 or -1
        elseif waveform == "saw" then
            sample = 2 * (freq * t % 1) - 1
        elseif waveform == "noise" then
            sample = math.random() * 2 - 1
        end

        local fade = 1
        if t < 0.01 then
            fade = t / 0.01
        elseif t > duration - 0.05 then
            fade = (duration - t) / 0.05
        end

        sound:setSample(i, sample * volume * fade)
    end

    return love.audio.newSource(sound)
end

function Audio.newChord(freqs, duration, waveform, volume)
    local sample_rate = 44100
    local samples = math.floor(sample_rate * duration)
    local sound = love.sound.newSoundData(samples, sample_rate, 16, 1)
    volume = volume or 0.3

    for i = 0, samples - 1 do
        local t = i / sample_rate
        local sample = 0
        local count = #freqs

        for _, freq in ipairs(freqs) do
            if waveform == "sine" then
                sample = sample + math.sin(2 * math.pi * freq * t) / count
            elseif waveform == "square" then
                sample = sample + (math.sin(2 * math.pi * freq * t) > 0 and 1 or -1) / count
            end
        end

        local fade = 1
        if t < 0.01 then
            fade = t / 0.01
        elseif t > duration - 0.1 then
            fade = (duration - t) / 0.1
        end

        sound:setSample(i, sample * volume * fade)
    end

    return love.audio.newSource(sound)
end

function Audio.newArpeggio(freqs, duration, waveform, volume)
    local sample_rate = 44100
    local samples = math.floor(sample_rate * duration)
    local sound = love.sound.newSoundData(samples, sample_rate, 16, 1)
    volume = volume or 0.4
    local note_dur = duration / #freqs

    for i = 0, samples - 1 do
        local t = i / sample_rate
        local note_idx = math.min(math.floor(t / note_dur) + 1, #freqs)
        local freq = freqs[note_idx]
        local note_t = t - (note_idx - 1) * note_dur
        local sample = 0

        if waveform == "sine" then
            sample = math.sin(2 * math.pi * freq * note_t)
        elseif waveform == "square" then
            sample = math.sin(2 * math.pi * freq * note_t) > 0 and 1 or -1
        end

        local fade = 1
        if note_t < 0.005 then
            fade = note_t / 0.005
        elseif note_t > note_dur - 0.02 then
            fade = (note_dur - note_t) / 0.02
        end

        sound:setSample(i, sample * volume * fade)
    end

    return love.audio.newSource(sound)
end

function Audio.loadSFX()
    Audio.sfx.move = Audio.newSFX(200, 0.05, "sine", 0.3)
    Audio.sfx.rotate = Audio.newSFX(400, 0.08, "sine", 0.4)
    Audio.sfx.lock = Audio.newSFX(100, 0.1, "square", 0.5)
    Audio.sfx.hard_drop = Audio.newSFX(80, 0.12, "square", 0.6)
    Audio.sfx.hold = Audio.newSFX(250, 0.05, "sine", 0.3)
    Audio.sfx.clear1 = Audio.newSFX(440, 0.15, "sine", 0.5)
    Audio.sfx.clear2 = Audio.newChord({440, 660}, 0.18, "sine", 0.5)
    Audio.sfx.clear3 = Audio.newChord({440, 660, 880}, 0.22, "sine", 0.5)
    Audio.sfx.tetris = Audio.newArpeggio({440, 554, 659, 880}, 0.35, "sine", 0.6)
    Audio.sfx.game_over = Audio.newSFX(220, 0.6, "saw", 0.5)
    Audio.sfx.victory = Audio.newChord({523, 659, 784, 1047}, 0.5, "sine", 0.6)
end

function Audio.play(name)
    if Audio.sfx[name] then
        local source = Audio.sfx[name]:clone()
        local vol = Audio.master_vol * Audio.sfx_vol
        source:setVolume(vol)
        source:play()
    end
end

function Audio.setMasterVolume(vol)
    Audio.master_vol = math.max(0, math.min(1, vol))
end

function Audio.setSFXVolume(vol)
    Audio.sfx_vol = math.max(0, math.min(1, vol))
end

function Audio.setMusicVolume(vol)
    Audio.music_vol = math.max(0, math.min(1, vol))
end

function Audio.update(dt)
end

return Audio
