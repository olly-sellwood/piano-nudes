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
// number of Bela DigitalIn pins to listen to
~numDigitalInputs = 16;

~triggerSamplePin = 0;

~resetPin1 = 1;
~resetPin2 = 2;
~resetPin3 = 3;
~resetPin4 = 4;
~resetPin5 = 5;
~resetPin6 = 6;
~resetPin7 = 7;
~resetPin8 = 8;
~resetPin9 = 9;
~resetPin10 = 10;
~resetPin11 = 11;
~resetPin12 = 12;

s = Server.default;

if (Platform.hasBelaSupport) {
    s.options.numAnalogInChannels = 8;
    s.options.numAnalogOutChannels = 8;
    s.options.numDigitalChannels = ~numDigitalInputs;

    s.options.blockSize = 16;
    s.options.numInputBusChannels = 2;
    s.options.numOutputBusChannels = 2;
};

s.options.postln;


~synthDefNameMono = "sample-player-mono";
~synthDefNameStereo = "sample-player-stereo";

~samplesDirectory = File.realpath(thisProcess.nowExecutingPath.dirname +/+ "../samples/");

if (~samplesDirectory.isNil) {
    "samples folder does not exist, the folder structure should be:".postln;
    "".postln;
    "piano-nudes/_main.scd".postln;
    "piano-nudes/samples/sample-0001.wav (etc)".postln;
    0.exit;
} {
    "the samples folder was found".postln;
};

// array of sample paths
~samplePaths = PathName(~samplesDirectory).files.collect {|pathName| pathName.fullPath };

// initialize state
~state = Dictionary[];
~state.put(\nextIndex, 0);          // index of the next sample to play
~state.put(\buffers, Dictionary[]); // mapping of index to Buffer
~state.put(\voices, Dictionary[]);  // mapping of Synth.nodeID to Dictionary [\synth -> Synth, \buffer -> Buffer, \index -> sampleIndex]);
// Buffers are moved from state[\buffers] to state[\voices] when playback starts

// state functions
// -----------------------------------------------------------------------------


// set the index of the next sample to play
// @index `Integer` or `nil`
~setIndex = {|index|
    // we always want to load 10 samples ahead of the current position
    var numSamplesToLookahead = 10;

    ~state.put(\nextIndex, index);

    // only load buffers if index is valid
    if (index.notNil and: { index < ~samplePaths.size }) {
        var lastIndex = (index + numSamplesToLookahead).min(~samplePaths.lastIndex);

        // free and remove buffers that are earlier than the index, or after the lookahead index
        ~state[\buffers].keys.do {|key|
            if ((key < index) || (key > lastIndex)) {
                var buffer = ~state[\buffers][key];

                if (buffer.notNil) {
                    var path = buffer.path;

                    buffer.free;
                    ~state[\buffers].removeAt(key);

                    ("freed buffer" + PathName(path).fileName).postln;
                };
            };
        };

        // load buffers from the given index up to the lookahead index
        (index..lastIndex).do {|lookaheadIndex|
            var isAlreadyLoaded = ~state[\buffers].includesKey(lookaheadIndex);
            if (isAlreadyLoaded.not) {
                var path = ~samplePaths[lookaheadIndex];
                var buffer = Buffer.read(s, path);

                ~state[\buffers].put(lookaheadIndex, buffer);

                ("loaded buffer:" + PathName(path).fileName).postln;
            };
        };
    } {
        "piece finished".postln;
    };
};

~playSample = {|buffer|
    var name = if (buffer.numChannels == 1) { ~synthDefNameMono; } { ~synthDefNameStereo; };
    var synth = Synth(name, [\bufnum, buffer]);

    // return the synth
    synth;
};

// trigger function to be called on pedal press
~playNextSample = {
    var index = ~state[\nextIndex];

    if (index.notNil) {
        var buffer = ~state[\buffers][index];

        if (buffer.notNil) {
            // play the buffer, move it from state[\buffers] to state[\voices]
            // then increment the index

            var synth = ~playSample.(buffer);
            var nextIndex = if (index < ~samplePaths.lastIndex) { index + 1 } { nil };

            ~state[\voices][synth.nodeID] = Dictionary.with(*[\synth -> synth, \buffer -> buffer, \index -> index]);
            ~state[\buffers].removeAt(index);

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
    var index = ~samplePaths.detectIndex {|path|
        PathName(path).fileNameWithoutExtension == filenameWithoutExtension;
    };

    // free any playing voices
    ~state[\voices].values.do {|voice| voice[\synth].free; };
    ~state[\voices].clear;

    // free any buffers
    ~state[\buffers].values.do {|buffer| buffer.free; };
    ~state[\buffers].clear;

    // move to the new sample to play
    if (index.notNil) {
        ~setIndex.(index);
        ("reset to" + filenameWithoutExtension).postln;
    } {
        "that file doesn't exist!".postln;
    };
};

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
    // SynthDefs for playback (handles mono or stereo)
    [[~synthDefNameMono, 1], [~synthDefNameStereo, 2]].do {|model|
        var name = model[0];
        var numChannels = model[1];

        SynthDef(name, {|bufnum, out = 0|
            var sig = PlayBuf.ar(numChannels, bufnum, BufRateScale.kr(bufnum), doneAction: Done.freeSelf);
            Out.ar(out, sig);
        }).add;
    };

    // listen for synth end messages from the server, free and remove the buffer when finished.
    OSCdef(\synthListener, {|msg|
        var nodeID = msg[1];
        var voice = ~state[\voices][nodeID];

        if (voice.notNil) {
            var bufferIndex = voice[\index];
            var samplePath = ~samplePaths[bufferIndex];

            voice[\buffer].free;
            ~state[\voices].removeAt(nodeID);

            ("cleaned up:" + PathName(samplePath).fileName).postln;

        };
    }, "/n_end");


    // synth def for listening to Bela button input
    ~buttonListenerSynthDefName = "button-listener";
    ~buttonListenerCmdName = "/button-pressed";

    if (Platform.hasBelaSupport) {

        SynthDef(~buttonListenerSynthDefName, {
            var ins = DigitalIn.ar((0..(~numDigitalInputs - 1)));
            var triggers = Trig.kr(ins);

            SendReply.kr(triggers, ~buttonListenerCmdName, triggers);
        }).add;

    } {

        // simulation for desktop testing
        SynthDef(~buttonListenerSynthDefName, {|t_values=#[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]|
            var triggers = Trig.kr(t_values);
            SendReply.kr(triggers, ~buttonListenerCmdName, triggers);
        }).add;

    };

    // listener
    OSCdef(\buttonListener, {|msg|
        var values = msg[3..].asInteger;

        values.postln;
        values.do { |value, pinIndex|
            var didTrigger = value == 1;
            if (didTrigger) {

                switch (pinIndex)

                {~triggerSamplePin} { ~playNextSample.(); }

                {~resetPin1} { ~resetToMarker1.(); }
                {~resetPin2} { ~resetToMarker2.(); }
                {~resetPin3} { ~resetToMarker3.(); }
                {~resetPin4} { ~resetToMarker4.(); }
                {~resetPin5} { ~resetToMarker5.(); }
                {~resetPin6} { ~resetToMarker6.(); }
                {~resetPin7} { ~resetToMarker7.(); }
                {~resetPin8} { ~resetToMarker8.(); }
                {~resetPin9} { ~resetToMarker9.(); }
                {~resetPin10} { ~resetToMarker10.(); }
                {~resetPin11} { ~resetToMarker11.(); }
                {~resetPin12} { ~resetToMarker12.(); }
                {};

            };
        };
    }, ~buttonListenerCmdName);

    s.sync;

    if (~buttonListenerSynth.notNil) {
        ~buttonListenerSynth.free;
    };
    ~buttonListenerSynth = Synth(~buttonListenerSynthDefName);

    // init
    ~resetToMarker1.();
};

ServerQuit.add { 0.exit }; // quit if the button is pressed

)

// debug code
// ~state[\nextIndex]
// ~state[\buffers].keys.asArray.sort
// ~state[\voices]

// ~debugClickButton = {|index|
//     var values = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
//     values[index] = 1.0;
//     ~buttonListenerSynth.set(\t_values, values);
// };
//
// ~debugClickButton.(~triggerSamplePin);
// ~debugClickButton.(~resetPin1);
// ~debugClickButton.(~resetPin2);
// ~debugClickButton.(~resetPin3);
// ~debugClickButton.(~resetPin4);
// ~debugClickButton.(~resetPin5);
// ~debugClickButton.(~resetPin6);
// ~debugClickButton.(~resetPin7);
// ~debugClickButton.(~resetPin8);
// ~debugClickButton.(~resetPin9);
// ~debugClickButton.(~resetPin10);
// ~debugClickButton.(~resetPin11);
// ~debugClickButton.(~resetPin12);
// ~debugClickButton.(~resetPin13);
// ~debugClickButton.(~resetPin14);
// ~debugClickButton.(~resetPin15);
