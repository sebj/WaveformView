WaveformView
============
![WaveformView Preview](https://github.com/sebj/WaveformView/blob/master/Preview.png?raw=true)

My take on an NSView subclass that can display the waveform for an audio file, allowing customisability of colors, play/stop control and image generation (from the view).

**Note**
If you're looking for an extremely accurate high performance visualization of a sound file or live sound recording, there are most likely alternatives that would better suit you.

###Classes

===

```WaveformView``` is a general-purpose waveform view to visualize a .wav file.

===

```LiveWaveformView``` will show a live waveform for a given ```AVAudioRecorder```.

===

```HybridWaveformView``` is a hybrid/combination of both of these - it's a bit experimental and not perfect. It should display a rough "live" waveform, then switch to an accurate waveform once recording has stopped and the sound recording files has been saved and loaded.