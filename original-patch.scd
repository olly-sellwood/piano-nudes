
s = Server.default;

s.options.numAnalogInChannels = 8;
s.options.numAnalogOutChannels = 8;
s.options.numDigitalChannels = 16;

s.options.blockSize = 16;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;
s.options.pgaGainLeft = 1;
s.options.pgaGainRight = 1;

s.options.postln;


(
s.waitForBoot({
	Routine{
		var trigid = 123;
		~numSamples = 10;  // how many samples in the folder
		~path = "/usr/share/SuperCollider/sounds/olly/"; // path of the folder

		0.5.wait;

		~sample = ();
		~numSamples.do{|i|
			var name = (\sample ++ i).asSymbol;
			~sample[i] = Buffer.read(s,~path ++ i ++ ".wav",bufnum: i).postln;
		};

		0.5.wait;


		// samplers
		~sample.size.do{|i|
			SynthDef(\sampler++i,{|amp = 1|
				var sig = PlayBuf.ar(2, i, doneAction:2);
				Out.ar(0, sig * amp)
			}).add
		};

		0.5.wait;

		~play = Routine{{~sample.size.do{|i| Synth(\sampler++i).yield}}.loop};

		0.5.wait;


		OSCdef(\listen, {|msg|

			var event = msg[2], value = msg[3];

			value.postln;

			if( (value > 0.5) && (value < 1.0), {~play.next}); // accelerometer range setting
		}, '/tr');

		0.5.wait;

		SynthDef(\osctrig,{
			// SendTrig.kr(AnalogIn.ar(0), trigid); // this can be used for button
			SendReply.kr(Impulse.kr(2) /*speed of triggering*/ , '/tr', AnalogIn.kr(0).round(0.01));
		}).add;

		0.5.wait;

		Synth(\osctrig);

		// ~play.next; // manual trigger
		// ~play = (Routine{{~sample.size.do{|i| Synth(\sampler++i).(~sample[i].duration.wait)}}.loop}).play;  // this is waiting for the previous sample to finish.

	}.play
})
)

