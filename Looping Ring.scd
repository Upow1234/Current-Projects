//volume leds
//add delay

(
~a = Arc.new("/monome", 0);
~g = MonoM.new("/monome", 0);

~ringTask;

~outputTask;


~rings = [Array.fill(64, 0), Array.fill(64, 0), Array.fill(64, 0), Array.fill(64, 0)] ;

~pos = [15, 15, 15, 15];

~speed = [0.1, 0.1, 0.1, 0.1];
~params = [ 1, 0.5, 1, 1 ]; //detune, pulse width, cutoff, resonance
~paramsScale = [10000, 1000, 100, 1000];
~upperLimits = [10000, 1, 10000, 1];


~notes = [146.83, 164.81, 220, 246.94];

~page = 0;

SynthDef.new("arcSynth", { arg freq = 400, amp = 0, detune = 1, pulseWidth = 0.5, cutoff = 1, resonance = 1;
	Out.ar(0, RLPF.ar(Pulse.ar([freq, (freq * detune)], pulseWidth, amp), freq * cutoff, resonance, 0.1));
}, [5]).add;


s.waitForBoot({

	~a.useDevice(0);
	~g.useDevice(1);


	OSCFunc.newMatching(
		{ arg message, time, addr, recvPort;

			if(~page == 0, {
				for(0, 3, { arg i;
					if (message[1] == i, {
						~speed[i] = ~speed[i] + (message[2] / 1000);
						postln(~speed[i]);

					});
				});
			});

			if(~page == 1, {
				for(0, 3, { arg i;
					if (message[1] == i, {
						~params[i] = ~params[i] + (message[2] / ~paramsScale[i]);

						if(~params[i] <= 0, {
							~params[i] = 0;
						});

						if(~params[i] >= ~upperLimits[i], {
							~params[i] = ~upperLimits[i];
						});


						postln("params[" + i + "] = " + ~params[i]);

					});
				});



				if(message[1] == 0, {
					for(0, 3, { arg i;
						~synths[i].set("detune", ~params[0]);
					});
				});

				if(message[1] == 1, {
					for(0, 3, { arg i;
						~synths[i].set("pulseWidth", ~params[1]);
					});
				});

				if(message[1] == 2, {
					for(0, 3, { arg i;
						~synths[i].set("cutoff", ~params[2]);
					});
				});

				if(message[1] == 3, {
					for(0, 3, { arg i;
						~synths[i].set("resonance", ~params[3]);
					});
				});


			});




	}, "/monome/enc/delta");

	OSCFunc.newMatching(
		{ arg message, time, addr, recvPort;

			if(message[3] == 1, {
				~page = message[1];
				~g.ledall(0);
				~g.ledset(~page, message[2], 1);
				postln("page = " + ~page);
			});

	}, "/monome/grid/key");


	~ringTask = Routine({
		var interval = 0.01;

		loop {

			for(0, 3, { arg index ;
				~pos[index] = (~pos[index] + ~speed[index]) % 64;

				for(0, 15, { arg i ;
					~rings[index][(~pos[index] + i) % 64] = i;
				});

				for(1, 15, { arg i ;
					~rings[index][(~pos[index] + (i + 15)) % 64] = ( i * -1 ) + 15;
				});
			});

			interval.yield;
		}
	});

	~outputTask = Routine({
		var interval = 0.01;

		loop {

			var amplitude;

			amplitude = {arg position;
				position = (position + 15) % 64;

				if(position >= 32, {
					position = ((position - 32) / 32) * 0.2;
					//postln("over" + position);
					},
					{
						position = (((position / 32) * -1) + 1) * 0.2;
						//postln("under" + position)
				}; );

				position;
			};

			for(0, 3, { arg i;
				~a.ringmap(i, ~rings[i]);
			});

			for(0, 3, { arg i;
				~synths[i].set("amp", amplitude.value(~pos[i]));
			});


			interval.yield;

		}
	});

	~g.ledall(0);
	~g.ledset(0, 0, 1);

	AppClock.sched(0, ~outputTask);
	AppClock.sched(0, ~ringTask);


		~synths = [Synth.new("arcSynth", ["freq", ~notes[0]]), Synth.new("arcSynth", ["freq", ~notes[1]]), Synth.new("arcSynth", ["freq", ~notes[2]]), Synth.new("arcSynth", ["freq", ~notes[3]])];


}); //end of wait for boot

)

(
~ringTask0.stop;
~ringTask1.stop;
~ringTask2.stop;
~ringTask3.stop;
~outputTask.stop;
)