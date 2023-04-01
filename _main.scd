/*
TODO

- hardware input
- bela autoboot run script // do this in Bela IDE, add instructions
- put samples into repo, once finalised (mono?)
- switch synthdef to mono, if mono

DONE
- triggering samples
- reset points
- load samples (memory constraints, DiskIn)
- server config: BelaServerOptions
- server auto boot

*/
(
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
~state.put("voices", Dictionary[]);  // mapping of Synth.nodeID to Dictionary [\synth -> Synth, \buffer -> Buffer, \index -> sampleIndex]);
// Buffers are moved from state["buffers"] to state["voices"] when playback starts

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
~playNextSample = {
    var index = ~state["nextIndex"];

    if (index.notNil) {
        var buffer = ~state["buffers"][index];

        if (buffer.notNil) {
            // play the buffer, move it from state["buffers"] to state["voices"]
            // then increment the index

            var synth = Synth("sample-player-stereo", [\bufnum, buffer]);
            var nextIndex = if (index < ~sample_paths.lastIndex) { index + 1 } { nil };

            ~state["voices"][synth.nodeID] = Dictionary.with(*[\synth -> synth, \buffer -> buffer, \index -> index]);
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
~resetToSample = {|filenameWithoutExtension|
    // find the index of the sample to jump to
    var index = ~sample_paths.detectIndex {|path|
        PathName(path).fileNameWithoutExtension == filenameWithoutExtension;
    };

    // free any playing voices
    ~state["voices"].values.do {|voice| voice[\synth].free; };
    ~state["voices"].clear;

    // free any buffers
    ~state["buffers"].values.do {|buffer| buffer.free; };
    ~state["buffers"].clear;

    // move to the new sample to play
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
    var voice = ~state["voices"][nodeID];

    if (voice.notNil) {
        var bufferIndex = voice[\index];
        voice[\buffer].free;
        ~state["voices"].removeAt(nodeID);
        ("cleaned up voice:" + nodeID + "(buffer:" + bufferIndex + ")").postln;
    };
}, "/n_end");

// reset functions
~resetToMarker1 = { ~resetToSample.("sample-0001"); };
~resetToMarker2 = { ~resetToSample.("sample-0074"); };
~resetToMarker3 = { ~resetToSample.("sample-0239"); };
~resetToMarker4 = { ~resetToSample.("sample-0269"); };
~resetToMarker5 = { ~resetToSample.("sample-0486"); };
~resetToMarker6 = { ~resetToSample.("sample-0579"); };
~resetToMarker7 = { ~resetToSample.("sample-0646"); };
~resetToMarker8 = { ~resetToSample.("sample-0719"); };
~resetToMarker9 = { ~resetToSample.("sample-0834"); };
~resetToMarker10 = { ~resetToSample.("sample-0912"); };
~resetToMarker11 = { ~resetToSample.("sample-0960"); };
~resetToMarker12 = { ~resetToSample.("sample-0983"); };

s.waitForBoot {
    // SynthDef for playback (assumes stereo files)
    SynthDef("sample-player-stereo", {|bufnum, out = 0|
        var sig = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), doneAction: Done.freeSelf);
        Out.ar(out, sig);
    }).add;

    s.sync;

    // init
    ~resetToMarker1.();
};

ServerQuit.add { 0.exit }; // quit if the button is pressed

)

// debug code
// to call on pedal press
// ~playNextSample.();

// ~resetToSample.("sample-0223");
// ~state["nextIndex"]
// ~state["buffers"].keys.asArray.sort
// ~state["voices"]
