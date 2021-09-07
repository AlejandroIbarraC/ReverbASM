import math

import numpy as np
import scipy.signal
import soundfile


class AudioFun:
    def __init__(self, file_name, alpha, k_nosr, audio_bits):
        self.file_name = file_name
        self.alpha = alpha
        self.k_nosr = k_nosr
        self.audio_bits = audio_bits

    # Add or remove reverb in audio file
    # file_name - file name
    # is_add - flag if adding or removing reverb
    def reverb(self, is_add):
        # Read audio file and initialize k
        data, sample_rate = soundfile.read(self.file_name + ".wav")
        k = math.trunc(sample_rate * self.k_nosr)

        # Initialize poles and zeroes of filter
        poles = np.zeros(k)
        poles[0] = 1
        poles[k-1] = self.alpha
        zeroes = [1 - self.alpha]

        # Apply filter
        if is_add:
            out = scipy.signal.lfilter(zeroes, poles, data)
        else:
            out = scipy.signal.lfilter(poles, zeroes, data)

        # Write to new wav with reverb
        file_name_write = self.file_name
        if is_add:
            file_name_write += "-reverb.wav"
        else:
            file_name_write += "-noreverb.wav"
        soundfile.write(file_name_write, out, sample_rate)

    # Converts txt to wav file
    # file_name - name of file
    def txt_to_wav(self):
        dual_bits = 2 * self.audio_bits
        is_first = True
        sample_rate = 44100

        with open(self.file_name + "-reverb.txt", "r") as txt_in:
            audio_list = []

            while True:
                # Read txt input file until the end
                line = txt_in.readline()
                if line == "FINAL\n":
                    break

                if is_first:
                    # Get back sample rate from txt on first line
                    sample_rate = int(line)
                    is_first = False
                else:
                    # Convert to binary
                    bin_num = bin(int(line)).replace("0b", "")

                    # Filter out 0s
                    bin_num_int = int(bin_num, 2)
                    num = 0
                    if bin_num_int != 0:
                        # Append 0s
                        bin_bits = dual_bits - len(bin_num)
                        bin_num = append_zeroes(bin_num, bin_bits, True)

                        # Dissect string
                        sign_bit = bin_num[0]

                        # Convert back two's complement if number is negative
                        if sign_bit == "1":
                            bin_num = twos_complement(bin_num)

                        int_bits = bin_num[1:self.audio_bits]
                        flt_bits = bin_num[self.audio_bits:]

                        # Convert back from fixed point arithmetic
                        int_num = int(int_bits, 2)
                        flt_num = binary_to_float(flt_bits)
                        num = int_num + flt_num

                        # Invert number to negative if sign bit is 0
                        if sign_bit == "1":
                            num = num * -1

                    # Append new number to list
                    audio_list.append(num)

            # Write on new audio wav file
            soundfile.write(self.file_name + "-converted.wav", audio_list, sample_rate)

    # Convert audio wav file to a txt with fixed point arithmetic integer values
    # file_name - name of file to convert
    def wav_to_txt(self):
        # Read audio file
        data, sample_rate = soundfile.read(self.file_name + ".wav")
        k = math.trunc(sample_rate * self.k_nosr)

        # Replace first value in data with alpha
        data[0] = self.alpha

        # Store fixed point arithmetic in text file
        with open(self.file_name + ".txt", "w") as txt_out:
            # Write sample rate and k on first two lines
            sample_rate = str(sample_rate)
            k = str(k)

            # Append enough 0s to the left of number to make every number 5 bytes long
            sample_rate = append_zeroes(sample_rate, 5 - len(sample_rate), True)
            k = append_zeroes(k, 5 - len(k), True)

            # Write on txt
            txt_out.write(sample_rate + "\n")
            txt_out.write(k + "\n")

            # Write every other number using fixed point on txt
            for num in data:
                # Dissect integer part of number
                int_part = abs(int(num))
                bin_int = bin(int_part).replace("0b", "")
                int_bits = self.audio_bits - len(bin_int)
                bin_int = append_zeroes(bin_int, int_bits, True)

                # Dissect float part of number
                flt_part = abs(abs(num) - abs(int_part))
                bin_flt = float_to_binary(flt_part, self.audio_bits)
                flt_bits = self.audio_bits - len(bin_flt)
                bin_flt = append_zeroes(bin_flt, flt_bits, False)

                # Add the two parts
                bin_num = bin_int + bin_flt

                # Apply two's complement if number is negative
                if num < 0 and bin_num.find("1") != -1:
                    bin_num = twos_complement(bin_num)

                # Convert binary to decimal to save space
                dec_num = str(int(bin_num, 2))

                # Add enough 0s to the left to make number 5 bytes long
                dec_num = append_zeroes(dec_num, 5 - len(dec_num), True)

                # Write number in text file
                txt_out.write(dec_num + "\n")

            # Last line is FINAL keyword
            txt_out.write("FINAL")

        txt_out.close()


# Appends qnt zeroes to a string number to the left or right
# number - string number to append zeroes to
# qnt - amount of zeroes to append
# is_left - defines if zeroes are added to the left or right
def append_zeroes(num, qnt, is_left):
    result = num
    while qnt != 0:
        if is_left:
            result = "0" + result
        else:
            result += "0"
        qnt -= 1

    return result


# Converts binary number to float using fixed point arithmetic
# num - number to convert
def binary_to_float(num):
    result = 0
    expo = 1

    # Loop over binary number using 2 to an exponent
    while num != '':
        msb = int(num[0])
        if msb == 1:
            result += 1 / (2**expo)

        expo += 1
        num = num[1:]

    return result


# Converts float number to binary using fixed point arithmetic
# num - number to convert
def float_to_binary(num, audio_bits):
    result_list = []
    while len(result_list) < audio_bits:
        # Loop over every bit until 7
        curr_num = num * 2
        int_res = int(curr_num)

        # Append number to result
        result_list.append(str(int_res))

        # Detect if float result is 0
        flt_res = abs(abs(curr_num) - abs(int_res))
        if flt_res == 0:
            break
        else:
            num = flt_res

    # Convert result list to single string
    result = ""
    for ele in result_list:
        result += ele

    return result


# Calculates two's complement of input string
# num - number to calculate
def twos_complement(num):
    b_ctr = len(num) - 1
    result_left = ""
    result = ""

    for b in num:
        if b == "0":
            result_left += "1"
        else:
            result_left += "0"

    while b_ctr >= 0:
        if result_left[b_ctr] == "1":
            result = "0" + result
            b_ctr -= 1
        else:
            result = "1" + result
            b_ctr -= 1
            break

    while b_ctr >= 0:
        result = result_left[b_ctr] + result
        b_ctr -= 1

    return result
