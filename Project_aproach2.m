%%Project:Voice Cancellation
%Approach II

%Frida Berenice Rangel García        |A01651385
%Luis Arturo Dan Fong                |A01650672
%Alfredo Zhu Chen                    |A01651980
%José Rubén Villicaña Ibargüengoytia |A01654347

%%  Clear the enviroment
clear all
close all
clc

%% Read noise and voice+noise
Fs=44100;                               %Sampling frequency
Ts=1/Fs;                                %Sampling period
noise= audioread('noise_b.wav');    %Read noise data                               
voice= audioread('noise_and_voice_b.wav');%Read noise+voice data
samples_voice=length(voice);            %Length of voice+noise
samples_noise=length(noise);            %Length of noise(shoud be equal to voice+noise) 
s=Ts*samples_noise;                     %Sampling time in seconds            
t=(0:Ts:s-Ts)';                         %time interval
f=Fs*[0:samples_noise-1]/samples_noise-Fs/2;%frequency interval
%% **********Uncomment this section and comment the section above if you want 
%to sample your own noise and voice+noise
%This section helps to obtain the sound from the Computer
%{
%Assuming the signal is already filtered with antialiasing filter
s=5;                                    %Sampling time
Fs=44100;                               %Sampling period
t=0:seconds(1/Fs):seconds(s);           %Time interval of the recording
bits=24;                                %Sampling resolution

%Recording noise
recObj = audiorecorder(Fs,bits,1);      %Recording noise object        
disp('Start recording noise')
recordblocking(recObj, s);              %Start recording noise of s time                 
disp('End of recording noise');
noise = getaudiodata(recObj);           %Obtain noise samples
samples_noise=length(noise);            %Length of noise 
Ts=s/samples_noise;                     %Sampling period
%Wait for a number in command window to continue
ask = input("Ready? Enter a number in Command Window to continue ")

%Recording voice
disp('Start recording voice with noise')
recordblocking(recObj, s);              %Start recording voice+noise of s time                  
disp('End of recording voice with noise');
voice = getaudiodata(recObj);           %Obtain voice+noise samples
samples_voice=length(voice);            %Length of voice+noise  
%}
%% *******Uncomment this section to hear the audio****************
%{ 
%sound(noise,Fs);                       %play noise
%pause(s)                               %Pause to finish playing
%sound(voice,Fs);                       %play noise+voice
%pause(s)                              %Pause to finish playing noise+voice
%}
%% Applying FFT to noise and voie+noise
noise_fourier = abs(fft(noise));        %fft magnitude of noise
voice_fourier = abs(fft(voice));        %fft magnitude of voice+noise
%% Plots
%Plot of noise
figure 
subplot(2,1,1)
plot(t,noise);                          %noise in time domain
xlabel("Time [s]")
ylabel("Amplitude [V]")
title("Noise")
subplot(2,1,2)
plot(f,fftshift(noise_fourier));        %noise in frequency domain
ylabel("Amplitude")
xlabel("Frequency [Hz]")
title("Noise")
subplot(2,1,2)

%Plot of voice+noise
figure
subplot(2,1,1)
plot(t,voice);                          %voice+noise in time domain
xlabel("Time [s]")
ylabel("Amplitude [V]")
title("Noise+Signal")
subplot(2,1,2)
plot(f,fftshift(voice_fourier));        %voice+noise in frequency domain
xlabel("Frequency [Hz]")
ylabel("Amplitude")
title("Noise+Signal")

% Analyze voice+noise in the frequency and time-frequency domains
figure
pspectrum(voice,t,"spectrogram")
title("Spectrogram of Signal+noise")
%% Short Time Fourier Transform 
% define the analysis and synthesis parameters
wlen=1024;
hop = wlen/8;                           %hop size
nfft = 4*wlen;                          %number of FFT points

% generate analysis and synthesis windows
anal_win = blackmanharris(wlen, 'periodic'); 
synth_win = hamming(wlen, 'periodic');

voice_len = length(voice);             % determination of the signal length 
wlen = length(anal_win);               % determination of the window length

% stft matrix size estimation and preallocation
NUP = ceil((1+nfft)/2);         % calculate the number of unique fft points
L = 1+fix((voice_len-wlen)/hop);    % calculate the number of signal frames
STFT = zeros(NUP, L);                  % preallocate the stft matrix
% STFT (via time-localized FFT)
for l = 0:L-1
    xw = voice(1+l*hop : wlen+l*hop).*anal_win; % windowing
    X = fft(xw, nfft);  % FFT
    STFT(:, 1+l) = X(1:NUP);           % update of the stft matrix
end

% calculation of the time and frequency vectors
STFT_t = (wlen/2:hop:wlen/2+(L-1)*hop)/Fs;
STFT_f = (0:NUP-1)*Fs/nfft;
%% Noise Cancellation
Factor = 47;                          %Multiplication factor                 
Th_noise = noise_fourier.*Factor;      %Noise threshold  
reduction = 0.1;                  %Noise cancellation multiplication factor
amp = 3;                               %Signal amplificaction factor

for i = 1:size(STFT,1)                 %row-time
    for j = 1:size(STFT,2)             %col-frequency
        if abs(Th_noise(i,1)) > abs(STFT(i,j))%Check if noise threshold is greater than the value
            STFT(i,j) = (STFT(i,j)).*reduction; %Noise attenuation
        else
            STFT(i,j) = (STFT(i,j)).*amp; %Voice signal amplifying
        end
    end
end

%% Inverse Short Time Fourier Transform(ISTFT)
L2 = size(STFT, 2);                 % determine the number of signal frames
wlen2 = length(synth_win);   % determine the length of the synthesis window
voice_filtered_len = wlen2+(L2-1)*hop;%estimate the length of the signal vector
voice_filtered = zeros(1, voice_filtered_len);%preallocate the signal vector
% reconstruction of the whole spectrum
if rem(nfft, 2)             
    % odd nfft excludes Nyquist point
    X = [STFT; conj(flipud(STFT(2:end, :)))];
else                        
    % even nfft includes Nyquist point
    X = [STFT; conj(flipud(STFT(2:end-1, :)))];
end
% columnwise IFFT on the STFT-matrix
xw = real(ifft(X));
xw = xw(1:wlen2, :);
% Weighted-OLA
for l = 1:L2
    voice_filtered(1+(l-1)*hop : wlen2+(l-1)*hop) = voice_filtered(1+(l-1)*hop : wlen2+(l-1)*hop) + ...
                                      (xw(:, l).*synth_win)';
end
W0 = sum(anal_win.*synth_win);         % scaling of the signal                 
voice_filtered = voice_filtered.*hop/W0;                      
t_voice_filtered = (0:voice_filtered_len-1)/Fs; % generation of the time vector
%% Plots of result
figure
subplot(2,1,1)
plot(f,fftshift(voice_fourier));         %Noise+Voice in frequency
xlabel("Frequency [Hz]")
ylabel("Amplitude")
title("Noise+Signal")
subplot(2,1,2)
plot(Fs*[0:size(voice_filtered,2)-1]/size(voice_filtered,2)-Fs/2,fftshift(abs(fft(voice_filtered))));%Noise+Voice filtered in frequency
xlabel("Frequency [Hz]")
ylabel("Amplitude")
title("Noise+Signal filtered")

figure
pspectrum(voice_filtered,t_voice_filtered,"spectrogram")
title("Noise+Signal filtered")
figure
plot(t_voice_filtered, voice_filtered)
legend('Signal filtered')
%% Listen to the result audio
sound(voice,Fs);                        %play noise+voice
pause(s)
sound(voice_filtered,Fs);               %play noise+voice filtered
%% References
%https://www.mathworks.com/matlabcentral/fileexchange/45577-inverse-short-time-fourier-transform-istft-with-matlab
