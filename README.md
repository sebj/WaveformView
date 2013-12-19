WaveformView
============

My take on an NSView subclass that can display the waveform for an audio file, allowing customisability of colors, play/stop control and image generation (from the view).

===

```WaveformView``` is the general waveform view, that can load a .wav file and display it.

===

```LiveWaveformView``` will show a live waveform for a given ```AVAudioRecorder```. It most probably will not be very accurate whatsoever, but is useful for illustrative purposes.

===

```HybridWaveformView``` is a hybrid/combination of both of these - it's a bit experimental and not perfect. It should display a rough "live" waveform, then switch to an accurate waveform once recording has stopped and the file has been saved and loaded.