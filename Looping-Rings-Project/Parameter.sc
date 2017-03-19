//getter variables may not ever be necessary and
//if they are not being used they should be taken out

Parameter {
	var <name, <minimum, <maximum, <scale, <value, <destination, <argument, <iterations;

	*new { arg nameTemp, minimumTemp, maximumTemp, scaleTemp, valueTemp, destinationTemp, argumentTemp, iterationsTemp;
		^super.new.init(nameTemp, minimumTemp, maximumTemp, scaleTemp, valueTemp, destinationTemp, argumentTemp, iterationsTemp)
	}

	init { arg nameTemp, minimumTemp, maximumTemp, scaleTemp, valueTemp, destinationTemp, argumentTemp, iterationsTemp;
		name = nameTemp;
		minimum = minimumTemp;
		maximum = maximumTemp;
		scale = scaleTemp;
		value = valueTemp;
		destination = destinationTemp;
		argument = argumentTemp;
		iterations = iterationsTemp;
	}


	currentValue {
		(name + " = " + value).postln;

		^value;
	}

	change { arg input;

		value = value + (input / scale);

		if((value <= minimum), {
			value = minimum;
		});

		if((value >= maximum), {
			value = maximum;
		});

		(name + " = " + value).postln;

		^(name + " = " + value);
	}


	sendChange {

		if(iterations == 0, {
		destination.set(argument, value);
		});

		if(iterations > 0, {
			for(0, iterations, { arg i;
				destination[i].set(argument, value);
			});
		});

	}


}

