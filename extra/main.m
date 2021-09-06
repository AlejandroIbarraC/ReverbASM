% Clear
clear
clc

% Read file
[file, fs] = audioread('audio.wav')

% Filter parameters
alpha = 0.6;
k_sinfs = 0.05;

% Adjust k
k = fs * k_sinfs;

% Floor k to be integer
k = floor(k);

% Create matrix of k rows full of 0s
polos = zeros(1, k);

% Add y(n)
polos(1) = 1;

% Add y(n-k)
polos(k) = alpha;

% Attenuation n(1- alpha) to x(n)
ceros = 1 - alpha;

% Apply filter
salida_filtro = filter(ceros, polos, file);
salida_filtro2 = filter(polos, ceros, salida_filtro);

% PLay sound
player_salida = audioplayer(salida_filtro, fs);
play(player_salida);