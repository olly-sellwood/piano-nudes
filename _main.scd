/*
TODO

- server config: BelaServerOptions
- server auto boot
- script booting override Main.run?
- hardware input
- bela autoboot run script

DONE
- triggering samples
- reset points
- load samples (memory constraints, DiskIn)

*/

s = Server.default;

if (Platform.hasBelaSupport) {
    s.options.numAnalogInChannels = 8;
    s.options.numAnalogOutChannels = 8;
    s.options.numDigitalChannels = 16;

    s.options.blockSize = 16;
    s.options.numInputBusChannels = 2;
    s.options.numOutputBusChannels = 2;
};

s.options.postln;

~samples_folder_path = File.realpath(thisProcess.nowExecutingPath.dirname +/+ "../samples/");

if (~samples_folder_path.isNil) {
    "samples folder does not exist, the folder structure should be:".postln;
    "".postln;
    "piano-nudes/_main.scd".postln;
    "piano-nudes/samples/sample-0001.wav (etc)".postln;
    0.exit;
} {
    "the samples folder was found".postln;
};

// array of sample paths
~sample_paths = PathName(~samples_folder_path).files.collect {|pathName| pathName.fullPath };

// initialize state
~state = Dictionary[];
~state.put("nextIndex", 0);          // index of the next sample to play
~state.put("buffers", Dictionary[]); // mapping of index to Buffer
~state.put("voices", Dictionary[]);  // mapping of Synth.nodeID to Buffer
// Buffers are moved from state["buffers"] to state["voices"] when playback starts

// SynthDef for playback (assumes stereo files)
SynthDef("sample-player-stereo", {|bufnum, out = 0|
    var sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), doneAction: Done.freeSelf);
    Out.ar(out, sig);
}).add;

// state functions
// -----------------------------------------------------------------------------


// set the index of the next sample to play
// @index `Integer` or `nil`
~setIndex = {|index|
    // we always want to load 10 samples ahead of the current position
    var buffer_loading_lookahead = 10;

    ~state.put("nextIndex", index);

    // only load buffers if index is valid
    if (index.notNil and: { index < ~sample_paths.size }) {
        var last_index = (index + buffer_loading_lookahead).min(~sample_paths.lastIndex);

        // free and remove buffers that are earlier than the index, or after the lookahead index
        ~state["buffers"].keys.do {|key|
            if ((key < index) || (key > last_index)) {
                var buffer = ~state["buffers"][key];

                if (buffer.notNil) {
                    var path = buffer.path;

                    buffer.free;
                    ~state["buffers"].removeAt(key);

                    ("freed buffer" + PathName(path).fileName).postln;
                };
            };
        };

        // load buffers from the given index up to the lookahead index
        (index..last_index).do {|lookahead_index|
            var is_already_loaded = ~state["buffers"].includesKey(lookahead_index);
            if (is_already_loaded.not) {
                var path = ~sample_paths[lookahead_index];
                var buffer = Buffer.read(s, path);

                ~state["buffers"].put(lookahead_index, buffer);

                ("loaded buffer:" + PathName(path).fileName).postln;
            };
        };
    } {
        "piece finished".postln;
    };
};

// trigger function to be called on pedal press
~onTrigger = {
    var index = ~state["nextIndex"];

    if (index.notNil) {
        var buffer = ~state["buffers"][index];

        if (buffer.notNil) {
            // play the buffer, move it from state["buffers"] to state["voices"]
            // then increment the index

            var synth = Synth("sample-player-stereo", [\bufnum, buffer]);
            var nextIndex = if (index < ~sample_paths.lastIndex) { index + 1 } { nil };

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

// helper for the reset buttons
// @filenameWithoutExtension `String` name of the sample to reset to
~onResetButton = {|filenameWithoutExtension|
    var index = ~sample_paths.detectIndex {|path|
        PathName(path).fileNameWithoutExtension == filenameWithoutExtension;
    };

    if (index.notNil) {
        ~setIndex.(index);
        ("reset to" + filenameWithoutExtension).postln;
    } {
        "that file doesn't exist!".postln;
    };
};

// listen for synth end messages from the server, free and remove the buffer when finished.
OSCdef(\listener, {|msg|
    var nodeID = msg[1];
    var buffer = ~state["voices"][nodeID];

    if (buffer.notNil) {
        buffer.free;
        ~state["voices"].removeAt(nodeID);
        ("cleaned up voice:" + nodeID).postln;
    } {
        "Error: buffer is nil".postln;
    };
}, "/n_end");

// reset functions
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

)
// init
~onResetButton1.();

// to call on pedal press
~onTrigger.();

// to call on reset buttons
~onResetButton1.();
~onResetButton2.();
~onResetButton3.();
~onResetButton4.();
~onResetButton5.();
~onResetButton6.();
~onResetButton7.();
~onResetButton8.();
~onResetButton9.();
~onResetButton10.();
~onResetButton11.();
~onResetButton12.();

// inspect state
~state["nextIndex"];
~state["buffers"];
~state["voices"];
