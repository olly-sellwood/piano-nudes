/*
TODO

- server config: BelaServerOptions
- server boot
- script booting override Main.run?

- hardware input
- bela autoboot

DONE
- triggering samples
- reset points
- load samples (memory constraints, DiskIn)

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


~state = Dictionary[];
~state.put("nextIndex", 0);
~state.put("buffers", Dictionary[]); // mapping of index to Buffer
~state.put("paths", PathName(~samples_folder_path).files.collect {|pathName| pathName.fullPath });  // array of sample paths
~state.put("voices", Dictionary[]);  // mapping of Synth.nodeID to Buffer

SynthDef("sample-player-stereo", {|bufnum, out = 0|
    var sig = PlayBuf.ar(2, bufnum, doneAction: Done.freeSelf);
    Out.ar(out, sig);
}).add;

~free_buffer = {|index|
    var buffer = ~state["buffers"][index];

    if (buffer.notNil) {
        var path = buffer.path;
        buffer.free;
        ~state["buffers"].removeAt(index);

        ("freed buffer" + PathName(path).fileName).postln;
    };
};

~setIndex = {|index|
    var buffer_loading_lookahead = 10;
    var paths = ~state["paths"];

    ~state.put("nextIndex", index);

    if (index.notNil and: { index < paths.size }) {
        var last_index = (index + buffer_loading_lookahead).min(paths.lastIndex);

        ~state["buffers"].keys.do {|key|
            var is_out_of_range = (key < index) || (key > last_index);
            if (is_out_of_range) {
                ~free_buffer.(key);
            };
        };

        (index..last_index).do {|lookahead_index|
            if (~state["buffers"].includesKey(lookahead_index).not) {
                var path = paths[lookahead_index];
                var buffer = Buffer.read(s, path);

                ~state["buffers"].put(lookahead_index, buffer);
                ("loaded buffer:" + PathName(path).fileName).postln;
            };
        };
    };
};

~onTrigger = {
    var index = ~state["nextIndex"];

    if (index.notNil) {
        var buffer = ~state["buffers"][index];

        if (buffer.notNil) {
            var synth = Synth("sample-player-stereo", [\bufnum, buffer]);
            var nextIndex = if (index < ~state["paths"].lastIndex) { index + 1 } { nil };

            ~state["voices"][synth.nodeID] = buffer;
            ~state["buffers"].removeAt(index);

            ("playing" + PathName(buffer.path).fileName).postln;

            ~setIndex.(nextIndex);
        } {
            "piece finished".postln;
        };
    } {
        "piece finished".postln;
    };
};

~onResetButton = {|filenameWithoutExtension|
    var index = ~state["paths"].detectIndex {|path|
        PathName(path).fileNameWithoutExtension == filenameWithoutExtension;
    };

    if (index.notNil) {
        ~setIndex.(index);
        ("reset to" + filenameWithoutExtension).postln;
    } {
        "that file doesn't exist!".postln;
    };
};

~on_synth_done = {|nodeID|
    var buffer = ~state["voices"][nodeID];

    if (buffer.notNil) {
        buffer.free;
        ~state["voices"].removeAt(nodeID);
        ("cleaned up voice:" + nodeID).postln;
    } {
        "Error: buffer is nil".postln;
    };
};

OSCdef(\listener, {|msg|
    var nodeID = msg[1];
    ~on_synth_done.(nodeID);
}, "/n_end");



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

// testing code
~setIndex.(1038);

~onTrigger.();

~onResetButton12.()

~state["nextIndex"];
~state["buffers"];
~state["paths"];
~state["voices"];
