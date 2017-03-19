Pinwheel[] pinwheel = new Pinwheel[4]; //<>//

//below are all the parameters accessible by the arc
Parameter triangleSize = new Parameter("triangle size", 0, 360, 10.0, 1, 20);
Parameter triangleRadius = new Parameter("triangle radius", 0, 1000, 1.0, 0, 200);
Parameter strokeWeight = new Parameter("stroke weight", 1, 30, 10.0, 0, 2);
Parameter speed = new Parameter("speed", -20, 20, 100.0, 0, 1);

Parameter fillHue = new Parameter("fill hue", 0, 255, 3.0, 1, 180);
Parameter fillSaturation = new Parameter("fill saturation", 0, 255, 3.0, 0, 255);
Parameter fillBrightness = new Parameter("fill brightness", 0, 255, 3.0, 0, 255);
Parameter fillAlpha = new Parameter("fill alpha", 0, 255, 3.0, 0, 200);

Parameter strokeHue = new Parameter("stroke hue", 0, 255, 3.0, 1, 0);
Parameter strokeSaturation = new Parameter("stroke saturation", 0, 255, 3.0, 0, 255);
Parameter strokeBrightness = new Parameter("stroke brightness", 0, 255, 3.0, 0, 255);
Parameter strokeAlpha = new Parameter("stroke alpha", 0, 255, 3.0, 0, 200);

Parameter feedback = new Parameter("feedback", 0, 255, 1.0, 0, 255);
Parameter slewRate = new Parameter("slewRate", 0, 1, 1000.0, 0, 1);

Parameter[][] pairs = {{triangleSize, triangleRadius}, {strokeWeight, speed}, {fillHue, fillSaturation}, {fillBrightness, fillAlpha}, 
  {strokeHue, strokeSaturation}, {strokeBrightness, strokeAlpha}, {feedback, slewRate}};


import org.monome.Monome;
import oscP5.*;

Monome grid;
Monome arc;

int[][] gridLed;
int[][] arcLed;

float point = 0;

float[] centerXdestination = { 100, 200, 300, 400 };
float[] centerYdestination = { 100, 200, 300, 400 };

float[] centerX = {100, 200, 300, 400};
float[] centerY = {100, 200, 300, 400};

int pinwheelSelection = 0;

//0 controls arc encoders 0 and 1, 1 controls encoders 2 and 3
int[] controlSelection = {0, 1};

int[][] controlLeds = {{0, 4}, {0, 6}, {1, 4}, {1, 6}, {2, 4}, {2, 6}, {3, 4}, {3, 6}, {4, 4}, {4, 6}, {5, 4}, {5, 6}, {6, 4}, {6, 6}, {7, 4}, {7, 6}, };

void setup() {

  //size(400, 400);
  fullScreen();

  arc = new Monome(this, "m1100144");
  grid = new Monome(this, "m1000370");

  pinwheel[0] = new Pinwheel(width/2, height/2);
  pinwheel[1] = new Pinwheel((width * 0.25), height/2);
  pinwheel[2] = new Pinwheel((width * 0.75), height/2);
  pinwheel[3] = new Pinwheel((width / 2), (height * 0.25));

  colorMode(HSB);
  
}

void draw() {

  noStroke();
  fill(0, feedback.value());
  rect(0, 0, width, height);

  //this is currently set to y first then x
  gridLed = new int[8][16];
  arcLed = new int[4][64];

  //creates faint leds for pinwheel center position on the grid
  for (int i = 0; i <= 7; i = i + 1) {
    for (int j = 8; j <= 15; j = j + 1) {
      gridLed[i][j] = 3;
    }
  }

  //lights lefts side pinwheel selection led
  gridLed[0][pinwheelSelection] = 15;

  //slews changes in pinwheel centers
  for (int i = 0; i <= 3; i++) {
    centerX[i] = slew(centerXdestination[i], centerX[i]);
    centerY[i] = slew(centerYdestination[i], centerY[i]);
  }

  // lights right side center of pinwheel leds
  for (int i = 0; i <= 3; i = i + 1) {
    gridLed[round(map(centerY[i], 0, height, 0, 7))][round(map(centerX[i], (0 + ((width - height) / 2 )), width - ((width - height) / 2), 8, 15))] = 15;
  }

  //selection for arc control

  gridLed[controlLeds[controlSelection[0]][0]][controlLeds[controlSelection[0]][1]] = 15;
  gridLed[controlLeds[controlSelection[0]][0]][controlLeds[controlSelection[0]][1] + 1] = 15;
  gridLed[controlLeds[controlSelection[1]][0]][controlLeds[controlSelection[1]][1]] = 7;
  gridLed[controlLeds[controlSelection[1]][0]][controlLeds[controlSelection[1]][1] + 1] = 7;

  grid.refresh(gridLed);

  //arc led values
  for (int i = 0; i <= pairs[controlSelection[0]][0].arcLeds(); i++ ) {
    arcLed[0][i] = 15;
  }
  arc.refresh(0, arcLed[0]);

  for (int i = 0; i <= pairs[controlSelection[0]][1].arcLeds(); i++ ) {
    arcLed[1][i] = 15;
  }
  arc.refresh(1, arcLed[1]);

  for (int i = 0; i <= pairs[controlSelection[1]][0].arcLeds(); i++ ) {
    arcLed[2][i] = 15;
  }
  arc.refresh(2, arcLed[2]);

  for (int i = 0; i <= pairs[controlSelection[1]][1].arcLeds(); i++ ) {
    arcLed[3][i] = 15;
  }
  arc.refresh(3, arcLed[3]);

  //increments point
  point = ((point + speed.value()) % 360);



  strokeWeight(constrain(strokeWeight.value(), 0, 200));
  stroke(strokeHue.value(), strokeSaturation.value(), strokeBrightness.value(), strokeAlpha.value());

  pinwheel[0].create(point, centerX[0], centerY[0]);
  pinwheel[1].create(point, centerX[1], centerY[1]);
  pinwheel[2].create(point, centerX[2], centerY[2]);
  pinwheel[3].create(point, centerX[3], centerY[3]);
}

float slew (float destination, float displayed) {

  if (destination > displayed) {

    displayed = displayed + slewRate.value();
  }

  if (destination < displayed) {

    displayed = displayed + (slewRate.value() * -1);
  } 

  return displayed;
}