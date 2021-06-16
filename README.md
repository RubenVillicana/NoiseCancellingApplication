# Noise Cancellation (Filtering and STFT)
INSTITUTO TECNOLÓGICO Y DE ESTUDIOS SUPERIORES DE MONTERREY

Project:	Noise Cancellation (Filtering and STFT)

Tema Members:

		Dan Fong, Luis Arturo
		Rangel García, Frida Berenice                                      
		Villicaña Ibargüengoytia, José Rubén
		Zhu Chen, Alfredo 

Abstract:

This repositroy contains the project form the Laboratory of Digital Signal Processing. It was developed a noise cancellation algorithm by using filters and the STFT. 

The first approach consists on using notch filters to attenuate the frequency componentes of the signal where the noise is allocated. 

The second approach uses the Short-time Fourier Transform (STFT) to analyse the signal in three dimentios: Time, frequency and aplitude. It is also knwon as Spectrogram. Mathematical opperation was applied to cancel unwanted noise.

There are a MATLAB script and a MATLAB live script for each approach in this folder. An Graphical User Interface (GUI) was also developed for the user. To use it, a MATLAB app should be installed.  

Users can use any audio to run the program. To demostrate its functionality, six different audios were provided. This algorithm works mainly with two aduios; the first one is only focused on the noise of the room (noise sensing), the second one is the message (voice, instrument, input signal, etc...) with the noise, naturally. It does not matter if the noise caputred on the second sample do not match with the noise obtained on the first audio (Actually, it needs to be different).
