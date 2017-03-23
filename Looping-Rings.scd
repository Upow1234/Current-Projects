// exponential parameters where applicable
// lines where applicable
//fix start-up
//problem was multiplication in delay buffer assignment...why doesn't delay work first time???

//adjust ranges to perfection
//make some actual music

s.reboot;

(

//variables for sending levels to processing
~processing = NetAddr.new("10.42.0.238", 12000);
~urls = ["/test0", "/test1", "/test2", "/test3"];

//declare arc and grid
~a = Arc.new("/monome", 0);
~g = MonoM.new("/monome", 0);


//arc led rings
~rings = [Array.fill(64, 0), Array.fill(64, 0), Array.fill(64, 0), Array.fill(64, 0)] ;

//positions of notes
~pos = [0, 0, 0, 0];

//volume levels of notes
~volume = [0, 0, 0, 0];

//note frequencies
~notes = [146.83, 164.81, 220, 246.94];

//arc left encoders and right encoders selection index
~selectionLeft = 0;
~selectionRight = 1;

//grid led array for left side of grid
~gridLeft = Array.fill(64, 0);

//fm coarse tuning selection
~fmCoarse = 4;

//fm coarse rates
~fmRates = [3, 2.5, 2, 1.5, 1, 0.75, 0.5, 0.25];

//fm direction (increasing or decreasing)
~fmInversionState = 1;

//buffer for delay
~delayBuffer = Buffer.alloc(s, (192000), 2);


//synth def for tones
SynthDef.new("arcSynth", { arg freq = 400, amp = 0.2, detune = 1.001, modCoarse = 1, modFine = 0, fmDepth = 0, cutoff = 1, resonance = 1, modFineInversion = 1, distSend;

	var dry;

	dry = (RLPF.ar(SinOsc.ar(([freq, (freq * detune)] + SinOsc.ar((freq * (modCoarse + (modFine * modFineInversion))), 0, (freq * fmDepth))), 0, amp), freq * cutoff, resonance, 0.1));

	Out.ar(distSend, dry);

	Out.ar(2, Mix.new(dry));

}).add;

//synth for volume LFOs
SynthDef("control", {arg busSine, busSaw, freq = 0.05, amp = 0;

	Out.kr(busSine, SinOsc.kr(freq, 1.5pi, amp, amp));
	Out.kr(busSaw, LFSaw.kr(freq, 0, 32, 32));

}).add;

//distortion mixing synth
SynthDef.new("distortionMixer", {arg balance = 0, input, delaySend;
	var dry, wet;

	dry = (In.ar(input, 2) * ((balance * -1) + 1));

	wet = [SoundIn.ar(0, balance), SoundIn.ar(0, balance)];

	Out.ar(0, dry);

	Out.ar(0, wet);

	Out.ar(delaySend, HPF.ar((dry + wet), ~notes[0], 1));

}).add;

//delay synth
SynthDef.new("delay", {arg effectReceive, speed = 0.1, depth = 0.1, decayTime = 10, level = 1, delayTime = 0.25;
	var lfo;

	lfo = SinOsc.kr(speed, 1.5pi, (delayTime * depth), delayTime);

	Out.ar(0, (BufCombL.ar(~delayBuffer.bufnum, In.ar(effectReceive, 2), [lfo + lfo], decayTime, level)));

	//Out.ar(0, In.ar(effectReceive, 2));

}).add;


s.waitForBoot({


	//assign monome devices to variables
	~a.useDevice(0);
	~g.useDevice(1);


	//arc input
	OSCFunc.newMatching(
		{ arg message, time, addr, recvPort;

			if (message[1] == 0, {
				~pairs[~selectionLeft][0].change(message[2]);
				~pairs[~selectionLeft][0].sendChange;
			});

			if (message[1] == 1, {
				~pairs[~selectionLeft][1].change(message[2]);
				~pairs[~selectionLeft][1].sendChange;
			});

			if (message[1] == 2, {
				~pairs[~selectionRight][0].change(message[2]);
				~pairs[~selectionRight][0].sendChange;
			});

			if (message[1] == 3, {
				~pairs[~selectionRight][1].change(message[2]);
				~pairs[~selectionRight][1].sendChange;
			});

	}, "/monome/enc/delta");


	//routine to update stored volume values when they differ from parameter values
	~getValues = Routine({
		var interval = 0.02;

		loop {


			if(((~pairs[0][0].value * 75) != ~volume[0]), {
				~volume[0] = ((~pairs[0][0].currentValue) * 75);
			});

			if(((~pairs[0][1].value * 75) != ~volume[1]), {
				~volume[1] = ((~pairs[0][1].currentValue) * 75);
			});

			if(((~pairs[1][0].value * 75) != ~volume[2]), {
				~volume[2] = ((~pairs[1][0].currentValue) * 75);
			});

			if(((~pairs[1][1].value * 75) != ~volume[3]), {
				~volume[3] = ((~pairs[1][1].currentValue) * 75);
			});

			for(0, 3, {arg index;
				~bussesSaw[index].get({ arg val;

					if(~pos[index] != val.asInteger, {
						~pos[index] = val.asInteger;
						~ringFunction.value(index, ~pos[index]);
					});
				});
			});


			interval.yield;
		}
	});

	SystemClock.sched(0, ~getValues);


	//updates arc leds
	~ringFunction = { arg enc, pos;

		~rings[enc].fill(0);

		if(~volume[enc] > 0, {

			//leds before pos
			for(0, (~volume[enc] * -1).asInteger, { arg i;

				~rings[enc][(pos + i) % 64] = (i + ~volume[enc]).asInteger;

			});

			//leds after pos
			for(1, ~volume[enc].asInteger, { arg i;

				~rings[enc][(pos + i) % 64] = ((i * -1) + ~volume[enc]).asInteger;

			});

			~a.ringmap(enc, ~rings[enc]);
		});

	};



	//grid input
	OSCFunc.newMatching(
		{ arg message, time, addr, recvPort;

			//pageLeft selection

			if((message[1] == 0) && (message[3] == 1), {
				var x = message[1];
				var y = message[2];

				~selectionLeft = x + (y * 2);
				~leftLed = x + (y * 8);
				~gridLedUpdate.value();

				postln("selectionLeft = " + ~selectionLeft);

			});

			if((message[1] == 2) && (message[3] == 1), {
				var x = (message[1] - 1);
				var y = message[2];

				~selectionLeft = x + (y * 2);
				~leftLed = (x + 1) + (y * 8);
				~gridLedUpdate.value();

				postln("selectionLeft = " + ~selectionLeft);

			});

			//pageRight selection

			if((message[1] == 1) && (message[3] == 1), {
				var x = (message[1] - 1);
				var y = message[2];

				~selectionRight = x + (y * 2);
				~rightLed = (x) + (y * 8);
				~gridLedUpdate.value();

				postln("selectionRight = " + ~selectionRight);

			});

			if((message[1] == 3) && (message[3] == 1), {
				var x = (message[1] - 2);
				var y = message[2];

				~selectionRight = x + (y * 2);
				~rightLed = (x + 1) + (y * 8);
				~gridLedUpdate.value();

				postln("selectionRight = " + ~selectionRight);

			});

			//fm coarse pitch selection
			if((message[1] == 4) && (message[3] ==1), {

				~fmCoarse = message[2];

				~fmCoarseLed = message[2];

				for(0, 3, { arg i;
					~synths[i].set(\modCoarse, ~fmRates[~fmCoarse]);
					postln(message[2]);
				});

				~gridLedUpdate.value();
			});

			//fm fine tuning direction
			if(((message[1] == 5) && (message[2] == 2) && message[3] == 1), {

				~fmInversionState = (~fmInversionState * -1);

				~fmInversionState.postln;

				if ((~fmInversionState == -1), {

					for (0, 3, {arg i;
						~synths[i].set(\modFineInversion, -1);
					});

				});


				if ((~fmInversionState == 1), {

					for (0, 3, {arg i;
						~synths[i].set(\modFineInversion, 1);
					});
				});

				~gridLedUpdate.value();

			});



	}, "/monome/grid/key");

	//function to update grid leds

	~gridLedUpdate = {
		~gridLeft.fill(0);

		//selection leds
		~gridLeft[~leftLed] = 15;
		~gridLeft[~leftLed + 1] = 15;


		~gridLeft[~rightLed] = 5;
		~gridLeft[~rightLed + 1] = 5;

		//fm rates leds
		for(0, 7, {arg i;
			~gridLeft[4 + (i * 8)] = 3;
		});

		~gridLeft[4 + (~fmCoarseLed * 8)] = 15;

		//fm inversion indicator
		if((~fmInversionState == 1), {
			~gridLeft[5 + (2 * 8)] = 15;
		});

		if((~fmInversionState == -1), {
			~gridLeft[5 + (2 * 8)] = 5;
		});


		~g.levmap(0, 0, ~gridLeft);

	};

	//initialize grid leds

	~g.ledall(0);

	~leftLed = 0;
	~rightLed = 2;

	~fmCoarseLed = ~fmCoarse;

	~gridLedUpdate.value;

	//the default delay time
	~currentDelayTime = 0.25;

	~storedDelayTime = ~currentDelayTime;
	~busDelayTime.set(~currentDelayTime);

	~changeDelayTime = {arg newTime;
		~currentDelayTime = newTime;
	};

	//default depth
	~currentDelayDepth = 0.1;

	~storedDelayDepth = ~currentDelayDepth;
	~busDelayDepth.set(~currentDelayDepth);

	~changeDelayDepth = {arg newDepth;
		~currentDelayDepth = newDepth;
	};


	~delayTask = Task({
		var interval = 0.1;

		loop {

			{Out.kr(
				~busDelayTime,
				Line.kr(~storedDelayTime, ~currentDelayTime, (interval * 0.75), 1, 0, 2)
			)}.play;

			~storedDelayTime = ~currentDelayTime;

			{Out.kr(
				~busDelayDepth,
				Line.kr(~storedDelayDepth, ~currentDelayDepth, (interval * 0.75), 1, 0, 2)
			)}.play;

			~storedDelayDepth = ~currentDelayDepth;

			interval.yield;
		}

	}).play;

	~sources = Group.new;
	~effects = Group.after(~sources);


	//creating synths

	~toDist = Bus.audio(s, 2);
	~toDelay = Bus.audio(s, 2);

	~synths = [Synth.new("arcSynth", [\freq, ~notes[0], \distSend, ~toDist], ~sources), Synth.new("arcSynth", [\freq, ~notes[1], \distSend, ~toDist], ~sources), Synth.new("arcSynth", [\freq, ~notes[2], \distSend, ~toDist], ~sources), Synth.new("arcSynth", [\freq, ~notes[3], \distSend, ~toDist], ~sources)];

	~bussesSine = [Bus.control(s, 1), Bus.control(s, 1), Bus.control(s, 1), Bus.control(s, 1)];

	~bussesSaw = [Bus.control(s, 1), Bus.control(s, 1), Bus.control(s, 1), Bus.control(s, 1)];

	~controls = [Synth.new("control", [\busSine, ~bussesSine[0], \busSaw, ~bussesSaw[0]], ~sources), Synth.new("control", [\busSine, ~bussesSine[1], \busSaw, ~bussesSaw[1]], ~sources), Synth.new("control", [\busSine, ~bussesSine[2], \busSaw, ~bussesSaw[2]], ~sources), Synth.new("control", [\busSine, ~bussesSine[3], \busSaw, ~bussesSaw[3]], ~sources)];


	~distortionMixingSynth = Synth.new("distortionMixer", [\input, ~toDist, \delaySend, ~toDelay], ~effects);


	for(0, 3, {arg i;
		~synths[i].map(\amp, ~bussesSine[i]);
	});


	//control busses for smoothing delay time and delay depth
	~busDelayTime = Bus.control(s, 1);
	~busDelayDepth = Bus.control(s, 1);

	~delaySignal = Synth.tail(~effects, "delay", [\effectReceive, ~toDelay]);

	//map ~busDelayTime to ~delaySignal
	~delaySignal.map(\delayTime, ~busDelayTime);

	//map ~busDelayDepth to ~delaySignal
	~delaySignal.map(\depth, ~busDelayDepth);

	// why the fuck on god's green fucking earth do i have to map these ...
	// control rate busses need to be mapped?




	//parameters controlled by the arc

	~pairs = [
		[Parameter.new("volume 0", 0, 0.2, 5000, 0, ~controls[0], \amp, 0 ) ,   Parameter.new("volume 1", 0, 0.2, 5000, 0, ~controls[1], \amp, 0 )], [Parameter.new("volume 2", 0, 0.2, 5000, 0, ~controls[2], \amp, 0 ) , Parameter.new("volume 3", 0, 0.2, 5000, 0, ~controls[3], \amp, 0)],
		[Parameter.new("speed 0", 0, 50, 5000, 0.01, ~controls[0], \freq, 0) , Parameter.new("speed 1", 0, 50, 5000, 0.01, ~controls[1], \freq, 0)],
		[Parameter.new("speed 2", 0, 50, 5000, 0.01, ~controls[2], \freq, 0) , Parameter.new("speed 3", 0, 50, 5000, 0.01, ~controls[3], \freq, 0)], [Parameter.new("FM-mod-fine", 0, 0.5, 1000, 0, ~synths, \modFine, 3), Parameter.new("FM Depth", 0, 50, 100, 0, ~synths, \fmDepth, 3)], [Parameter.new("Cutoff", 1, 10, 100, 1, ~synths, \cutoff, 3), Parameter.new("Resonance", 0.05, 1.05, 100, 1, ~synths, \resonance, 3)], [Parameter.new("Delay Time",  0.001, 2, 1000, ~currentDelayTime, ~changeDelayTime, nil, -1), Parameter.new("Delay Feedback", 0, 20, 100, 5, ~delaySignal, \decayTime, 0)], [Parameter.new("Delay LFO Speed", 0, 1, 1000, 0.1, ~delaySignal, \speed, 0), Parameter.new("Delay LFO Depth", 0, 0.25, 1000, ~currentDelayDepth, ~changeDelayDepth, nil, -1)], [Parameter.new("Distortion Balance", 0, 1, 1000, 0, ~distortionMixingSynth, \balance, 0), Parameter.new("Detune", 0.5, 2, 1000, 1, ~synths, \detune, 3)] ];


	//routine to send amplitude values to processing sketch
	~processingRoutine = Routine({
		var interval = 0.1;
		var value;
		loop{

			for(0, 3, { arg index;
				~bussesSine[index].get({ arg val;
					value = val;
					~processing.sendMsg(~urls[index], value);
				});


			});
			interval.yield;
		};
	});

	AppClock.sched(0, ~processingRoutine);

}); //end of wait for boot


)

s.queryAllNodes;
~toDelay.index

s.sampleRate