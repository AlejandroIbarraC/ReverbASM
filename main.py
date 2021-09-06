import simpleaudio as sa

from fun import *

if __name__ == '__main__':
    # Reverb control variables
    alpha = 0.6
    k = 0.05

    # Conversion variables
    audio_bits = 8

    # File name
    file_name = "halo3l"

    a = AudioFun(file_name, alpha, k, audio_bits)

    # Add reverb to audio
    # a.reverb(is_add=True)
    # print("Reverb added to " + file_name + ".wav")

    # Convert audio to txt
    a.wav_to_txt()
    print("Converted " + file_name + ".wav to txt")

    # Call assembly

    # Convert txt to audio list and play it back
    a.txt_to_wav()
    print("Converted " + file_name + "-text.txt to wav")

    # Remove reverb again
    # a.reverb(False)

    # Play new audio
    # wave_obj = sa.WaveObject.from_wave_file(file_name + "-converted.wav")
    # play_obj = wave_obj.play()
    # play_obj.wait_done()  # Wait until sound has finished playing

