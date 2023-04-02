// you could do something like the following to use MIDI input
// see MIDIdef help for more options, like using Control Change instead of Note On
MIDIIn.connectAll;

MIDIdef.noteOn(\noteListener, {|velocity, note|

    switch (note)
    { 60 } { ~playNextSample.() }

    { 36 } { ~resetToSample.("sample-0001") }
    { 37 } { ~resetToSample.("sample-0074") }
    { 38 } { ~resetToSample.("sample-0239") }
    { 39 } { ~resetToSample.("sample-0269") }
    { 40 } { ~resetToSample.("sample-0486") }
    { 41 } { ~resetToSample.("sample-0579") }
    { 42 } { ~resetToSample.("sample-0646") }
    { 43 } { ~resetToSample.("sample-0719") }
    { 44 } { ~resetToSample.("sample-0834") }
    { 45 } { ~resetToSample.("sample-0912") }
    { 46 } { ~resetToSample.("sample-0960") }
    { 47 } { ~resetToSample.("sample-0983") }
    { "note is not mapped".postln; }

});

