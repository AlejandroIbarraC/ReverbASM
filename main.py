import os

import simpleaudio as sa
import PySimpleGUI as sg

from fun import *

if __name__ == '__main__':
    # Reverb control variables
    alpha = 0.6
    k = 0.05

    # Conversion variables
    audio_bits = 8

    # File name
    file_name = "audio"

    a = AudioFun(file_name, alpha, k, audio_bits)

    # UI
    sg.theme("Black")

    title = sg.Text(text="ReverbASM", font="none 16 bold")
    title_down = sg.Text(text="by J.A Ibarra", font="none 12")

    # Unprocessed audio
    unp_subt = sg.Text(text="Unprocessed audio", font="none 14 italic")

    rev_unp_subt = sg.Text(text="No reverb", font="none 12")
    rev_unp_btn = Button = sg.Button(button_text="Play", key="play_audio_noreverb")

    norev_unp_subt = sg.Text(text="Reverb", font="none 12")
    norev_unp_btn = sg.Button(button_text="Play", key="play_audio_reverb")

    # Processed audio
    pro_subt = sg.Text(text="Processed audio", font="none 14 italic")

    rev_pro_subt = sg.Text(text="Reverb", font="none 12")
    rev_pro_btn = sg.Button(button_text="Play", key="play_audio_reverb_converted")

    norev_pro_subt = sg.Text(text="No reverb", font="none 12")
    norev_pro_btn = sg.Button(button_text="Play", key="play_audio_noreverb_converted")

    # Process audio
    pro_action_subt = sg.Text(text="Process Audio", font="none 14 italic")
    pro_action_btn = sg.Button(button_text="Process", key="process_audio")

    layout = [[title],
              [title_down],
              [unp_subt],
              [rev_unp_subt, rev_unp_btn],
              [norev_unp_subt, norev_unp_btn],
              [pro_subt],
              [rev_pro_subt, rev_pro_btn],
              [norev_pro_subt, norev_pro_btn],
              [pro_action_subt],
              [pro_action_btn]]

    window = sg.Window("ReverbASM", layout)

    while True:
        event, values = window.read()
        if event == sg.WIN_CLOSED or event == "Cancel":
            break
        if event == "play_audio_noreverb":
            window["play_audio_noreverb"].update(disabled=True)
            wave_obj = sa.WaveObject.from_wave_file(file_name + ".wav")
            play_obj = wave_obj.play()
            play_obj.wait_done()  # Wait until sound has finished playing
            window["play_audio_noreverb"].update(disabled=False)
        if event == "play_audio_reverb":
            window["play_audio_reverb"].update(disabled=True)
            wave_obj = sa.WaveObject.from_wave_file(file_name + "-known-reverb.wav")
            play_obj = wave_obj.play()
            play_obj.wait_done()  # Wait until sound has finished playing
            window["play_audio_reverb"].update(disabled=False)
        if event == "play_audio_reverb_converted":
            window["play_audio_reverb_converted"].update(disabled=True)
            wave_obj = sa.WaveObject.from_wave_file(file_name + "-reverb-converted.wav")
            play_obj = wave_obj.play()
            play_obj.wait_done()  # Wait until sound has finished playing
            window["play_audio_reverb_converted"].update(disabled=False)
        if event == "play_audio_noreverb_converted":
            window["play_audio_noreverb_converted"].update(disabled=True)
            wave_obj = sa.WaveObject.from_wave_file(file_name + "-noreverb-converted.wav")
            play_obj = wave_obj.play()
            play_obj.wait_done()  # Wait until sound has finished playing
            window["play_audio_noreverb_converted"].update(disabled=False)
        if event == "process_audio":
            window["process_audio"].update(disabled=True)
            # Add reverb to no reverb one
            a.wav_to_txt("audio", "audio")
            os.system("./reverb-exec")
            a.txt_to_wav("audio-reverb", "audio-reverb-converted")

            # Remove reverb to no reverb one
            a.wav_to_txt("audio-known-reverb", "audio-known-reverb")
            os.system("./noreverb-exec")
            a.txt_to_wav("audio-noreverb", "audio-noreverb-converted")
            window["process_audio"].update(disabled=False)

    window.close()
