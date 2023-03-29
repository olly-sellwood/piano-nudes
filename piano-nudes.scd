/*
TODO

- server config: BelaServerOptions
- server boot
- script booting override Main.run?
- load samples (memory constraints, DiskIn)
- hardware input
- bela autoboot

DONE
- triggering samples
- reset points

*/

s.options.numBuffers = 2048;
s.boot;

~samples_folder_path = File.realpath(thisProcess.nowExecutingPath.dirname +/+ "../samples/");

if (~samples_folder_path.isNil) {
    "samples folder does not exist, the folder structure should be:".postln;
    "".postln;
    "project/ollie-sellwood-piano-nudes/piano-nudes.scd".postln;
    "project/samples/sample-0001.wav (etc)".postln;
    0.exit;
} {
    "samples folder exists".postln;
};

~sample_paths = PathName(~samples_folder_path).files.collect {|pathName| pathName.fullPath };

SynthDef("sample-player-stereo", {|bufnum, out = 0|
    var sig = PlayBuf.ar(2, bufnum, doneAction: Done.freeSelf);
    Out.ar(out, sig);
}).add;

~buffers = Dictionary[];
OSCdef(\listener, {|msg|
    var nodeID = msg[1];
    var buffer = ~buffers[nodeID];

    if (buffer.notNil) {
        var path = buffer.path;
        ~buffers[nodeID].free;
        ~buffers.removeAt(nodeID);
        ("freed buffer" + path).postln;
        ~buffers.postln;
    };

}, "/n_end");

~nextIndex = 0;

~onTrigger = {
    var index = ~nextIndex;
    if (index.notNil) {
        var buffer = Buffer.read(s, ~sample_paths[index]);
        var synth = Synth("sample-player-stereo", [\bufnum,~buffer]);

        ~buffers[synth.nodeID] = buffer;

        ("playing" + PathName(buffer.path).fileName).postln;

        ~nextIndex = if (index < ~sample_paths.lastIndex) { index + 1} { nil };
    } {
        "piece finished".postln;
    }
};

~onResetButton = {|filenameWithoutExtension|
    var bufferIndex = ~buffers.detectIndex {|buffer|
        PathName(buffer.path).fileNameWithoutExtension == filenameWithoutExtension;
    };

    if (bufferIndex.notNil) {
        ~nextIndex = bufferIndex;
        ("reset to" + filenameWithoutExtension).postln;
    } {
        "that file doesn't exist!".postln;
    };
};

~onResetButton1 = { ~onResetButton.("sample-0001"); };
~onResetButton2 = { ~onResetButton.("sample-0074"); };
~onResetButton3 = { ~onResetButton.("sample-0239"); };
~onResetButton4 = { ~onResetButton.("sample-0269"); };
~onResetButton5 = { ~onResetButton.("sample-0486"); };
~onResetButton6 = { ~onResetButton.("sample-0579"); };
~onResetButton7 = { ~onResetButton.("sample-0646"); };
~onResetButton8 = { ~onResetButton.("sample-0719"); };
~onResetButton9 = { ~onResetButton.("sample-0834"); };
~onResetButton10 = { ~onResetButton.("sample-0912"); };
~onResetButton11 = { ~onResetButton.("sample-0960"); };
~onResetButton12 = { ~onResetButton.("sample-0983"); };

~onTrigger.();
