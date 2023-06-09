
// you could do something like the following to use MIDI input
// see MIDIdef help for more options, like using Control Change instead of Note On
MIDIIn.connectAll;


~previousValue=0;
~threshold=64;
MIDIdef.cc(\pedal,{|value, channel|

	if ((~previousValue < ~threshold) && (value >= ~threshold) ){
		~playNextSample.();
	};

	~previousValue=value;
}, 7);

MIDIdef.noteOn(\noteListener, {|velocity, note|

    switch (note)
    { 60 } { ~playNextSample.() }

    { 31 } { ~resetToSample.("sample-0001") }
    { 32 } { ~resetToSample.("sample-0058") }
    { 33 } { ~resetToSample.("sample-0074") }
    { 34 } { ~resetToSample.("sample-0187") }
    { 35 } { ~resetToSample.("sample-0223") }
    { 36 } { ~resetToSample.("sample-0239") }
    { 37 } { ~resetToSample.("sample-0269") }
    { 38 } { ~resetToSample.("sample-0486") }
    { 39 } { ~resetToSample.("sample-0530") }
    { 40 } { ~resetToSample.("sample-0546") }
    { 41 } { ~resetToSample.("sample-0551") }
    { 42 } { ~resetToSample.("sample-0569") }
    { 43 } { ~resetToSample.("sample-0574") }
    { 44 } { ~resetToSample.("sample-0579") }
    { 45 } { ~resetToSample.("sample-0587") }
    { 46 } { ~resetToSample.("sample-0598") }
    { 47 } { ~resetToSample.("sample-0613") }
    { 48 } { ~resetToSample.("sample-0628") }
    { 49 } { ~resetToSample.("sample-0646") }
    { 50 } { ~resetToSample.("sample-0665") }
    { 51 } { ~resetToSample.("sample-0689") }
    { 52 } { ~resetToSample.("sample-0701") }
    { 53 } { ~resetToSample.("sample-0719") }
    { 54 } { ~resetToSample.("sample-0834") }
    { 55 } { ~resetToSample.("sample-0846") }
    { 56 } { ~resetToSample.("sample-0868") }
    { 57 } { ~resetToSample.("sample-0912") }
    { 58 } { ~resetToSample.("sample-0960") }
    { 59 } { ~resetToSample.("sample-0983") }

    { 24 } {
    	var newIndex = (~state[\nextIndex] - 10).max(0);
    	var sampleName = PathName(~samplePaths[newIndex]).fileNameWithoutExtension;
    	~resetToSample.(sampleName);
    	~state[\nextIndex] = newIndex;
    }
    { 26 } {
    	var newIndex = (~state[\nextIndex] + 10).min(~samplePaths.lastIndex);
    	var sampleName = PathName(~samplePaths[newIndex]).fileNameWithoutExtension;
    	~resetToSample.(sampleName);
    	~state[\nextIndex] = newIndex;
    }

    { ("note is not mapped:" + note).postln; }

});

/*
Piano Nudes, by Olly Sellwood (https://www.ollysellwood.info)

SuperCollider patch for Bela (https://bela.io), by Arthur Carabott (https://www.arthurcarabott.com)
*/
(

// modify this to map pins to actions
// the number corresponds to the Bela hardware pin (see https://learn.bela.io/pin-diagram/)
// "trigger" will play the current sample and move to the next one
// "sample-XXXX" will move to the sample with that name

~pinMapping = Dictionary.with(*[
    0 -> "trigger",
    1 -> "sample-0001",
    2 -> "sample-0074",
    3 -> "sample-0239",
    4 -> "sample-0269",
    5 -> "sample-0486",
    6 -> "sample-0579",
    7 -> "sample-0646",
    8 -> "sample-0719",
    9 -> "sample-0834",
    10 -> "sample-0912",
    11 -> "sample-0960",
    12 -> "sample-0983",
]);

~isLoggingEnabled = false;

~isBeepingEnabled = false;

// number of Bela DigitalIn pins to listen to
~numDigitalInputs = 16;

s = Server.default;

if (Platform.hasBelaSupport) {
    s.options.numAnalogInChannels = 8;
    s.options.numAnalogOutChannels = 8;
    s.options.numDigitalChannels = ~numDigitalInputs;

    s.options.blockSize = 16;
    s.options.numInputBusChannels = 2;
    s.options.numOutputBusChannels = 2;
};

~samplesDirectory = File.realpath(thisProcess.nowExecutingPath.dirname +/+ "samples");

if (~samplesDirectory.isNil) {
    "Error: samples folder does not exist, the folder structure should be:".postln;
    "".postln;
    "piano-nudes/_main.scd".postln;
    "piano-nudes/samples/sample-0001.wav (etc)".postln;
    0.exit;
} {
    "- samples folder found".postln;
};

// array of sample paths
~samplePaths = PathName(~samplesDirectory).files.collect {|pathName| pathName.fullPath };

// cache indices of samples that are mapping to buttons
~cachedResetIndices = Dictionary[];
~samplePaths.do {|path, index|
    if (~pinMapping.values.any {|mapping| path.contains(mapping); }) {
        ~cachedResetIndices.add(PathName(path).fileNameWithoutExtension -> index);
    };
};

~logPathAction = {|path, action|
    var column, prefix, marker;

    if (~isLoggingEnabled) {

        column = switch(action)
        { "reset" } { 0 }
        { "load"  } { 0 }
        { "play"  } { 1 }
        { "clean" } { 2 }
        { "free"  } { 3 }

        { 0 };

        prefix = Array.fill(column * 18, " ").join;
        marker = if (action == "reset") { "=====================" } { "" };

        (prefix + marker + action + PathName(path).fileNameWithoutExtension).postln;
    };
};


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

                    ~logPathAction.(path, "free");
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

                ~logPathAction.(path, "load");
            };
        };
    } {
        "piece finished".postln;
    };
};

// trigger function to be called on pedal press
~playNextSample = {
    var index = ~state[\nextIndex];

    if (index.notNil) {
        var buffer = ~state[\buffers][index];

        if (buffer.notNil) {
            // play the buffer, move it from state[\buffers] to state[\voices]
            // then increment the index

            var synth = Synth("sample-player-mono", [\bufnum, buffer]);
            var nextIndex = if (index < ~samplePaths.lastIndex) { index + 1 } { nil };

            if (~isBeepingEnabled) {
                Synth("beep", [\freq, 2000]);
            };

            ~state[\voices][synth.nodeID] = Dictionary.with(*[\synth -> synth, \buffer -> buffer, \index -> index]);
            ~state[\buffers].removeAt(index);
            ~setIndex.(nextIndex);

            ~logPathAction.(buffer.path, "play");

        } {
            "- piece finished".postln;
        };
    } {
        "- piece finished".postln;
    };

};

// helper for the reset buttons
// @filenameWithoutExtension `String` name of the sample to reset to
~resetToSample = {|fileNameWithoutExtension|

    // find the index of the sample to jump to
    var cachedIndex = ~cachedResetIndices[fileNameWithoutExtension];

    var index;
    if (cachedIndex.isNil.not) {
        index = cachedIndex;
    } {
        var detectedIndex;
        detectedIndex = ~samplePaths.detectIndex {|path|
            PathName(path).fileNameWithoutExtension == fileNameWithoutExtension;
        };
        if (detectedIndex.notNil) {
            ~cachedResetIndices[fileNameWithoutExtension] = detectedIndex;
            ~logPathAction.(fileNameWithoutExtension, "cache index");
        };

        index = detectedIndex;
    };

    // free any playing voices
    ~state[\voices].values.do {|voice| voice[\synth].free; voice[\buffer].free; };
    ~state[\voices].clear;

    // free any buffers
    ~state[\buffers].values.do {|buffer| buffer.free; };
    ~state[\buffers].clear;

    // move to the new sample to play
    if (index.notNil) {
        ~logPathAction.(fileNameWithoutExtension, "reset");
        ~setIndex.(index);
    } {
        ("Error: tried to reset to a sample that doesn't exist:" + fileNameWithoutExtension).postln;
    };

    if (~isBeepingEnabled) {
        Synth("beep", [\freq, 3000]);
    };
};

ServerQuit.add { 0.exit }; // quit if the button is pressed

s.waitForBoot {

    SynthDef("sample-player-mono", {|bufnum, out = 0|
        var sig = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), doneAction: Done.freeSelf);
        Out.ar(out, sig);
    }).add;

    if (~isBeepingEnabled) {
        SynthDef("beep", {|freq|
            var sig = SinOsc.ar(freq) * EnvGen.ar(Env.perc, doneAction: Done.freeSelf) * 0.1;
            Out.ar(0, sig);
        }).add;
    };

    "- added playback SynthDef".postln;

    // listen for synth end messages from the server, free and remove the buffer when finished.
    OSCdef(\synthListener, {|msg|
        var nodeID = msg[1];
        var voice = ~state[\voices][nodeID];

        if (voice.notNil) {
            var bufferIndex = voice[\index];
            var samplePath = ~samplePaths[bufferIndex];

            voice[\buffer].free;
            ~state[\voices].removeAt(nodeID);

            ~logPathAction.(samplePath, "clean");

        };
    }, "/n_end");
    "- created synth listener".postln;


    // synth def for listening to Bela button input
    ~buttonListenerSynthDefName = "button-listener";
    ~buttonListenerCmdName = "/button-pressed";

    if (Platform.hasBelaSupport) {
        var lastPin = ~numDigitalInputs - 1;
        SynthDef(~buttonListenerSynthDefName, {
            var ins = DigitalIn.ar((0..lastPin));
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
    "- added button listener synthdef".postln;

    // listener
    OSCdef(\buttonListener, {|msg|
        var values = msg[3..].asInteger;

        values.do { |value, pinIndex|
            var didTrigger = value == 1;
            if (didTrigger) {
                var mapping = ~pinMapping[pinIndex];
                var sampleExists = ~samplePaths.any {|path| PathName(path).fileNameWithoutExtension == mapping; } ;

                case
                // trigger sample
                { mapping == "trigger"; } { ~playNextSample.(); }

                // reset
                { sampleExists } { ~resetToSample.(mapping); }

                // no mapping
                { mapping.isNil; } { ("no action mapped to pin:" + pinIndex).postln; }

                // no sample exists with that name
                { sampleExists.not } { ("no sample exists with the name:" + mapping).postln; };

            };
        };
    }, ~buttonListenerCmdName);
    "- created button listener".postln;

    s.sync;

    if (~buttonListenerSynth.notNil) {
        ~buttonListenerSynth.free;
    };
    ~buttonListenerSynth = Synth(~buttonListenerSynthDefName);
    "- created button listener synth".postln;

    // init
    ~resetToSample.(PathName(~samplePaths[0]).fileNameWithoutExtension);
};
)
