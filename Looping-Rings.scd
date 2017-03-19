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


//synth def for tones
SynthDef.new("arcSynth", { arg freq = 400, amp = 0.2, detune = 1.001, modCoarse = 1, modFine = 0, fmDepth = 0, cutoff = 1, resonance = 1, modFineInversion = 1;

	var dry;

	dry = (RLPF.ar(SinOsc.ar(([freq, (freq * detune)] + SinOsc.ar((freq * (modCoarse + (modFine * modFineInversion))), 0, (freq * fmDepth))), 0, amp), freq * cutoff, resonance, 0.1));

	Out.ar(0, dry);

}).add;

//synth for volume LFOs
SynthDef("control", {arg busSine, busSaw, freq = 0.05, amp = 0;
	Out.kr(busSine, SinOsc.kr(freq, 1.5pi, amp, amp));
	Out.kr(busSaw, LFSaw.kr(freq, 0, 32, 32));
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

	//creating synths

	~synths = [Synth.before(~delaySignal, "arcSynth", [\freq, ~notes[0], \effectSend, ~delayBus]), Synth.before(~delaySignal, "arcSynth", [\freq, ~notes[1], \effectSend, ~delayBus]), Synth.before(~delaySignal, "arcSynth", [\freq, ~notes[2], \effectSend, ~delayBus]), Synth.before(~delaySignal, "arcSynth", [\freq, ~notes[3], \effectSend, ~delayBus])];

	~bussesSine = [Bus.control(s, 1), Bus.control(s, 1), Bus.control(s, 1), Bus.control(s, 1)];
	~bussesSaw = [Bus.control(s, 1), Bus.control(s, 1), Bus.control(s, 1), Bus.control(s, 1)];

	~controls = [Synth.before(~synths[0], "control", [\busSine, ~bussesSine[0], \busSaw, ~bussesSaw[0]]), Synth.before(~synths[1], "control", [\busSine, ~bussesSine[1], \busSaw, ~bussesSaw[1]]), Synth.before(~synths[2], "control", [\busSine, ~bussesSine[2], \busSaw, ~bussesSaw[2]]), Synth.before(~synths[3], "control", [\busSine, ~bussesSine[3], \busSaw, ~bussesSaw[3]])];


	for(0, 3, {arg i;
		~synths[i].map(\amp, ~bussesSine[i]);
	});


	//parameters controled by the arc

	~pairs = [
		[Parameter.new("volume 0", 0, 0.2, 5000, 0, ~controls[0], \amp, 0 ) ,   Parameter.new("volume 1", 0, 0.2, 5000, 0, ~controls[1], \amp, 0 )], [Parameter.new("volume 2", 0, 0.2, 5000, 0, ~controls[2], \amp, 0 ) , Parameter.new("volume 3", 0, 0.2, 5000, 0, ~controls[3], \amp, 0)],
		[Parameter.new("speed 0", 0, 50, 5000, 0.01, ~controls[0], \freq, 0) , Parameter.new("speed 1", 0, 50, 5000, 0.01, ~controls[1], \freq, 0)],
		[Parameter.new("speed 2", 0, 50, 5000, 0.01, ~controls[2], \freq, 0) , Parameter.new("speed 3", 0, 50, 5000, 0.01, ~controls[3], \freq, 0)], [Parameter.new("FM-mod-fine", 0, 0.5, 1000, 0, ~synths, \modFine, 3), Parameter.new("FM Depth", 0, 50, 100, 0, ~synths, \fmDepth, 3)], [Parameter.new("Cutoff", 1, 10, 100, 1, ~synths, \cutoff, 3), Parameter.new("Resonance", 0.05, 1.05, 100, 1, ~synths, \resonance, 3)] ];


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


