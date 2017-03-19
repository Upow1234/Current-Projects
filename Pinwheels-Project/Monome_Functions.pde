//arc input
public void delta(int n, int d) {

  if (n == 0) {
    pairs[controlSelection[0]][0].change(d);
  }

  if (n == 1) {
   pairs[controlSelection[0]][1].change(d);
  }

  if (n == 2) {
    pairs[controlSelection[1]][0].change(d);
  }

  if (n == 3) {
    pairs[controlSelection[1]][1].change(d);
  }
}

//grid input
public void key(int x, int y, int n) {
  //x is horizontal y is vertical


  //left side pinwheel selection input
  if ((x <= 3 ) && (n ==1)) {
    pinwheelSelection = x;
  }

  //right side pinwheel center selection input
  if ((x >= 8) && (n == 1)) {
    centerXdestination[pinwheelSelection] = map(x, 8, 15, (0 + ((width - height) / 2 )), width - ((width - height) / 2));
    centerYdestination[pinwheelSelection] = map(y, 0, 7, 0, height);
    
  }

  //arc control selection
  if (((x >= 4) && (x <=7)) && (n == 1)) {

    if (x == 4) {
      int scaleX = 0;
      controlSelection[0] = scaleX + (y * 2);

      println("controlSelection[0] = " + controlSelection[0]);
    }

    if (x == 6) {
      int scaleX = 1;
      controlSelection[0] = scaleX + (y * 2);

      //println("scaleX = " + scaleX);
      println("controlSelection[0] = " + controlSelection[0]);
    }

    if (x == 5) {
      int scaleX = 0;
      controlSelection[1] = scaleX + (y * 2);

      println("controlSelection[1] = " + controlSelection[1]);
    }

    if (x == 7) {
      int scaleX = 1;
      controlSelection[1] = scaleX + (y * 2);

      //println("scaleX = " + scaleX);
      println("controlSelection[1] = " + controlSelection[1]);
    }
  }
}