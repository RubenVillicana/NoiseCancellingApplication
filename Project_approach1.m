%%Project:Voice Cancellation
%Approach I

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
noise= audioread('noise.wav');          %Read noise data                               
voice= audioread('noise_and_voice.wav');%Read noise+voice data
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
title("Spectrogram of voice+noise")
%% Finding local maxima of noise above threshold value 
threshold = 10;                         %Knob that changes the threshold
noise_fourier_shifted = fftshift(noise_fourier);
%find local maxima of noise_fourier above MinProminence according to f SamplePoints
maxIndices = islocalmax(noise_fourier_shifted,"MinProminence",threshold,"SamplePoints",f);

figure %Plotting noise_fourier with the local maxima
plot(f,noise_fourier_shifted,f(maxIndices),noise_fourier_shifted(maxIndices),'r*')
xlabel("Frequency [Hz]")
ylabel("Amplitude")
legend("Noise","Noise above threshold")
%% f0 Vector, Finding frecuencies to attenuate
if mod(samples_noise,2)==0 %Even samples_noise
    f0=f(samples_noise/2+1:end);        %Reading half of frequency interval
    max_f0 = maxIndices(samples_noise/2+1:end);%maxima in the half frequency interval
    f0_vector = f0'.*max_f0;            %frequencies with maxima indices
else
    f0=f((samples_noise+1)/2:end);      %Reading half of frequency interval
    max_f0 = maxIndices((samples_noise+1)/2:end);%maxima in the half frequency interval
    f0_vector = f0'.*max_f0;
end
%% Filtering
bw = (1/(Fs/2))*2;                      %Knob that changes the bandwith
voice_filtered = voice;                 %Initialize voice_filtered
attenuation_factor = 7;                 %Knob that changes how much in dB each component is affected
m = max(noise_fourier);                 %Maximum value in frequency domain
for i = 1:samples_noise/2  
    w0 = f0_vector(i,1)/(Fs/2);         %Normalized frequency where notch is located
    if w0 ~= 0                          %Check if contains frequencies
        at = noise_fourier(i,1)/m;      %attenuation proportion
        [b,a] = iirnotch(w0,bw,at*attenuation_factor);%Obtaining coefficients of filter notch
        voice_filtered=filter(b,a,voice_filtered); %Filtering 
    end
end
voice_fourier_filtered = fft(voice_filtered);%FFT of voice_filtered
%% Change of Volumen in Frequency Domain
gain_loss_threshold=3;%Threshold value to attenuate and amplify components
gain=2; %gain factor value from 0 to 10, try low values first
loss=0.6;%loss factor value from 0 to 1
for i = 1:samples_noise
    if abs(voice_fourier_filtered(i,1)) >gain_loss_threshold;
        voice_fourier_filtered(i,1) = voice_fourier_filtered(i,1)*gain;%Amplifying signal above threshold
    else
        voice_fourier_filtered(i,1) = voice_fourier_filtered(i,1)*loss;%Noise attenuation below threshold
    end
end
%% Plots of result
figure
subplot(2,1,1)
plot(f,fftshift(voice_fourier));        %Noise+Voice in frequency
xlabel("Frequency [Hz]")
ylabel("Amplitude")
title("Noise+Signal")
subplot(2,1,2)
plot(f,fftshift(abs(fft(voice_filtered))));%Noise+Voice filtered in frequency
xlabel("Frequency [Hz]")
ylabel("Amplitude")
title("Noise+Signal filtered")

figure
pspectrum(voice_filtered,t,"spectrogram")
title("Noise+Signal filtered")
%% Listen to the result audio
sound(voice,Fs);                        %play noise+voice
pause(s)
sound(voice_filtered,Fs);               %play noise+voice filtered