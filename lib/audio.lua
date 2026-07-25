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

function Audio.newSwoosh(start_freq, end_freq, duration, volume)
    local sample_rate = 44100
    local samples = math.floor(sample_rate * duration)
    local sound = love.sound.newSoundData(samples, sample_rate, 16, 1)
    volume = volume or 0.5

    local phase = 0
    for i = 0, samples - 1 do
        local t = i / sample_rate
        local progress = t / duration
        local freq = start_freq + (end_freq - start_freq) * (progress ^ 1.8)
        phase = phase + (2 * math.pi * freq / sample_rate)

        local sample = math.sin(phase) * 0.6 + (math.random() * 2 - 1) * 0.4 * (1 - progress)
        local fade = math.sin(progress * math.pi)

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
    Audio.sfx.swoosh = Audio.newSwoosh(750, 120, 0.25, 0.55)
    Audio.sfx.t_spin = Audio.newArpeggio({523, 659, 784}, 0.25, "square", 0.5)
    Audio.sfx.all_clear = Audio.newArpeggio({523, 659, 784, 1047, 1318}, 0.5, "sine", 0.7)

    Audio.loadBGM()
end

function Audio.generateBGMLoop(notes, note_dur, waveform, volume)
    local sample_rate = 44100
    local total_dur = #notes * note_dur
    local samples = math.floor(sample_rate * total_dur)
    local sound = love.sound.newSoundData(samples, sample_rate, 16, 1)
    volume = volume or 0.35

    for i = 0, samples - 1 do
        local t = i / sample_rate
        local note_idx = math.min(math.floor(t / note_dur) + 1, #notes)
        local freq = notes[note_idx]
        local note_t = t - (note_idx - 1) * note_dur
        local sample = 0

        if freq > 0 then
            if waveform == "square" then
                sample = (math.sin(2 * math.pi * freq * note_t) > 0 and 1 or -1) * 0.7
            elseif waveform == "saw" then
                sample = (2 * (freq * note_t % 1) - 1) * 0.6
            elseif waveform == "sine" then
                sample = math.sin(2 * math.pi * freq * note_t)
            end
        end

        local fade = 1
        if note_t < 0.005 then
            fade = note_t / 0.005
        elseif note_t > note_dur - 0.015 then
            fade = (note_dur - note_t) / 0.015
        end

        sound:setSample(i, sample * volume * fade)
    end

    local src = love.audio.newSource(sound)
    src:setLooping(true)
    return src
end

function Audio.loadBGM()
    Audio.bgm = {}
    -- Chiptune pack (Korobeiniki 8-bit retro melody)
    local chiptune_notes = {
        659, 493, 523, 587, 523, 493, 440, 440, 523, 659, 587, 523, 493, 523, 587, 659,
        523, 440, 440, 0,   587, 698, 880, 784, 698, 659, 523, 659, 587, 523, 493, 523,
        587, 659, 523, 440, 440, 0
    }
    Audio.bgm.chiptune = Audio.generateBGMLoop(chiptune_notes, 0.16, "square", 0.3)

    -- Synthwave pack (Retro 80s minor arpeggio)
    local synthwave_notes = {
        220, 330, 440, 554, 440, 330, 220, 165,
        174, 261, 349, 440, 349, 261, 174, 130,
        130, 196, 261, 329, 261, 196, 130, 196,
        146, 220, 293, 370, 293, 220, 146, 220
    }
    Audio.bgm.synthwave = Audio.generateBGMLoop(synthwave_notes, 0.18, "saw", 0.25)

    -- Classical pack (Polyphonic Baroque counterpoint motif)
    local classical_notes = {
        440, 523, 659, 523, 440, 392, 440, 493,
        523, 659, 784, 659, 523, 493, 440, 392,
        349, 440, 523, 440, 349, 329, 349, 392,
        440, 493, 523, 587, 659, 523, 493, 440
    }
    Audio.bgm.classical = Audio.generateBGMLoop(classical_notes, 0.20, "sine", 0.35)
end

function Audio.playBGM(pack_name)
    pack_name = pack_name or "chiptune"
    if Audio.current_bgm_pack == pack_name and Audio.current_bgm and Audio.current_bgm:isPlaying() then
        return
    end

    if Audio.current_bgm then
        Audio.current_bgm:stop()
    end

    if Audio.bgm[pack_name] then
        Audio.current_bgm = Audio.bgm[pack_name]
        Audio.current_bgm_pack = pack_name
        local vol = Audio.master_vol * Audio.music_vol
        Audio.current_bgm:setVolume(vol)
        Audio.current_bgm:setPitch(Audio.bgm_pitch or 1.0)
        Audio.current_bgm:play()
    end
end

function Audio.stopBGM()
    if Audio.current_bgm then
        Audio.current_bgm:stop()
        Audio.current_bgm = nil
        Audio.current_bgm_pack = nil
    end
end

function Audio.setBGMPitch(pitch)
    Audio.bgm_pitch = math.max(0.8, math.min(1.5, pitch or 1.0))
    if Audio.current_bgm then
        Audio.current_bgm:setPitch(Audio.bgm_pitch)
    end
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
    if Audio.current_bgm then
        Audio.current_bgm:setVolume(Audio.master_vol * Audio.music_vol)
    end
end

function Audio.setSFXVolume(vol)
    Audio.sfx_vol = math.max(0, math.min(1, vol))
end

function Audio.setMusicVolume(vol)
    Audio.music_vol = math.max(0, math.min(1, vol))
    if Audio.current_bgm then
        Audio.current_bgm:setVolume(Audio.master_vol * Audio.music_vol)
    end
end

function Audio.update(dt)
end

return Audio
