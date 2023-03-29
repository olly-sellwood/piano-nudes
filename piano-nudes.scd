/*
TODO

- server config
- server boot
- script booting override Main.run?
- load samples (memory constraints, DiskIn)
- triggering samples
- reset points
- hardware input
- bela autoboot

*/

s.options.numBuffers = 2048
s.boot

~samples_path = File.realpath(thisProcess.nowExecutingPath.dirname +/+ "../samples/");


if (~samples_path.isNil) {
    "samples folder does not exist, the folder structure should be:".postln;
    "".postln;
    "project/ollie-sellwood-piano-nudes/piano-nudes.scd".postln;
    "project/samples/sample-0001.wav (etc)".postln;
    0.exit;
} {
    "samples folder exists".postln;
};


~sample_soundfiles = PathName(~samples_path).files.collect {|pathName| SoundFile.openRead(pathName.fullPath); };

~max_sample_duration_s = ~sample_soundfiles.maxItem {|soundfile| soundfile.duration; }.duration
// ("max sample duration: " + ~max_sample_duration_s).postln;

~buffers = ~sample_soundfiles.collect {|soundfile| Buffer.read(s, soundfile.path); }

~k_synth_name_mono = "sample-player-mono";
SynthDef(~k_synth_name_mono, {|bufnum, out = 0|
    var sig = PlayBuf.ar(1, bufnum, doneAction: Done.freeSelf);
    var panned = Pan2.ar(sig);

    Out.ar(out, panned);
}).add;


~k_synth_name_stereo = "sample-player-stereo";
SynthDef(~k_synth_name_stereo, {|bufnum, out = 0|
    var sig = PlayBuf.ar(2, bufnum, doneAction: Done.freeSelf);
    var panned = Pan2.ar(sig);

    Out.ar(out, panned);
}).add;

(
~play_buffer = {|buffer|
    var synth_name = switch(buffer.numChannels)
    { 1 } { ~k_synth_name_mono }
    { 2 } { ~k_synth_name_stereo }
    {nil};

    synth_name.postln;

    if (synth_name.isNil.not) {
        Synth(synth_name, [\bufnum, buffer]);
    } {
        ("Unsupported number of channels in buffer, falling back to stereo for buffer:" + buffer.path).postln;
    }
};

)

~play_buffer.(~buffers[2])