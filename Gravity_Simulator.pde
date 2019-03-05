//Keybinds:
//Scroll: zoom
//Scroll + Shift: enhanced zoom
//N: new mass
//Esc: cancel mass/exit window
//M: Toggle Mass names
//L: Toggle Line
//G: Toggle Grid
//Space: Toggle Pause
//Raise Simulation Speed: Up
//Lower Simulation Speed: Down
//0-9: Access Saves
//  NonExisting Save: new save 
//  Current Save: Save to file
//  Existing Save: Load save

ArrayList<Mass> masses, addedMasses, removedMasses;
double G = 6.67408e-11, scale, xOffset, yOffset, lastMouseX, lastMouseY, flashTimer;
int status, maxLineLength, simulationRate, nameStatus, currentSave, gridStatus;
String inputText;
boolean enhancedZoom, paused, mouseLinked, showLine, quantityVisible, drawLines;
PGraphics lines;

void setup() {
  frameRate(60);
  fullScreen();
  ellipseMode(RADIUS);
  background(0, 0, 0);

  maxLineLength = 10000;
  currentSave = 0;
  ArrayList<String> lines;
  newUniverse();
  if ((lines = readFile("0.txt"))!=null) {
    decompile(lines);
  }
}

void draw() {
  clear();
  fill(color(255, 255, 255));
  adjustOffset();
  drawGrid();
  drawMasses();
  switch(status) {
  case 0:
    if (!paused) {
      for (int i = 0; i < simulationRate; i++) {
        updateMasses();
      }
    }
    drawText("(" + shortenDecimal(unRenderX(mouseX)) + ", " + shortenDecimal(unRenderY(mouseY)) + ")", 18, mouseX, mouseY);
    break;
  case 1:
    if (mouseLinked) inputText = shortenDecimal(newMass().x);
    else {
      try {
        newMass().x = Double.parseDouble(inputText);
      }
      catch(Exception e) {
      }
    }
    if (quantityVisible)drawText("X: " + inputText + "m", 18, mouseX, mouseY);
    break;
  case 2:
    if (mouseLinked) inputText = shortenDecimal(newMass().y);
    else {
      try {
        newMass().y = Double.parseDouble(inputText);
      }
      catch(Exception e) {
      }
    }
    if (quantityVisible)drawText("Y: " + inputText  +"m", 18, mouseX, mouseY);
    break;
  case 3:
    if (quantityVisible)drawText("Mass: " + inputText + "kg", 18, (int)renderX(newMass().x), (int)renderY(newMass().y));
    break;
  case 4:
    if (quantityVisible)drawText("Velocity: " + inputText + "m/s", 18, (int)renderX(newMass().x), (int)renderY(newMass().y));
    break;
  case 5:
    if (mouseLinked) {
      double xDis = unRenderX(mouseX) - newMass().x, 
        yDis = unRenderY(mouseY) - newMass().y, 
        dis = Math.sqrt(xDis * xDis + yDis * yDis), 
        sine = yDis/dis;
      inputText = shortenDecimal(Math.toDegrees(Math.asin(sine)));
    } else {
      try {
        double radians = Math.toRadians(Double.parseDouble(inputText)), 
          sine = Math.sin(radians), 
          cos = Math.cos(radians), 
          velocity = Math.sqrt(newMass().velX * newMass().velX + newMass().velY*newMass().velY);
        newMass().velX = cos*velocity;
        newMass().velY = sine*velocity;
      }
      catch(Exception e) {
      }
    }
    if (quantityVisible)drawText("Direction: " + inputText + "°", 18, (int)renderX(newMass().x), (int)renderY(newMass().y));
    break;
  case 6:
    if (mouseLinked) inputText = shortenDecimal(newMass().radius) + "";
    else {
      try {
        newMass().radius = Double.parseDouble(inputText);
      }
      catch(Exception e) {
      }
    }
    if (quantityVisible)drawText("Radius: " + inputText + "m", 18, mouseX, mouseY);
    break;
  case 7:
    if (quantityVisible)drawText("Name: " + inputText, 18, (int)renderX(newMass().x), (int)renderY(newMass().y));
    break;
  }
  lastMouseX = mouseX;
  lastMouseY = mouseY;
  drawText("Zoom: " + shortenDecimal(scale) + "X", 18, 100, 100);
  drawText("Save: " + currentSave, 18, 100, 50);
  drawText("Simulation Rate: " + simulationRate  + "X", 18, 100, 150);
  if (paused)drawText("(Paused)", 18, 100, 200);
  if (flashTimer>0) {
    flashTimer--;
    quantityVisible = !quantityVisible;
  }
  if (flashTimer<=0)quantityVisible=true;
}

void drawGrid() {
  switch(gridStatus) {
  case 1:
    double oom = -Math.log(scale)/Math.log(2), 
      offset=oom%1, 
      digits=oom-offset, 
      baseInterval=Math.pow(2, digits+7);
    drawGrid(baseInterval);
    break;
  }
}

void drawGrid(double interval) {
  stroke(128);
  for (double x = xOffset-(xOffset%interval); x < xOffset+width/scale; x+=interval) {
    double renderX = renderX(x);
    line((float)renderX, 0, (float)renderX, height);
  }
  for (double y = yOffset-(yOffset%interval); y < yOffset+height/scale; y += interval) {
    double renderY = renderY(y);
    line(0, (float)renderY, width, (float)renderY);
  }
}

void adjustOffset() {
  if (mousePressed) {
    double oldXOffset = xOffset, oldYOffset = yOffset;
    xOffset += (lastMouseX - mouseX)/scale;
    yOffset += (lastMouseY - mouseY)/scale;
    if (xOffset != oldXOffset || yOffset != oldYOffset) {
      drawLines = true;
    }
  }
}

void drawMasses() {
  lines.beginDraw();
  if (drawLines)lines.clear();
  lines.stroke(200);
  for (Mass mass : masses) {
    mass.drawLine();
  }
  lines.endDraw();
  if (drawLines)drawLines = false;

  if (showLine) {
    image(lines, 0, 0);
  }

  for (Mass mass : masses) {
    mass.drawMass();
  }
}

void updateMasses() {
  for (int i = 0; i < masses.size(); i++) {
    Mass m1 = masses.get(i);
    for (int j = i+1; j < masses.size(); j++) {
      Mass m2 = masses.get(j);
      double xDis = m1.x-m2.x, 
        yDis = m1.y-m2.y, 
        distance = Math.sqrt(xDis*xDis + yDis*yDis);
      double sine = yDis/distance, 
        cosine = xDis/distance, 
        FG = G*m1.mass*m2.mass/distance/distance;
      if (distance < m1.radius + m2.radius) {
        removedMasses.add(m1);
        removedMasses.add(m2);
        if (m1.mass > m2.mass) {
          addedMasses.add(new Mass(m1.x, m1.y, m1.velX, m1.velY, m1.mass + m2.mass, m1.radius, m1.massColor, m1.name));
        } else {
          addedMasses.add(new Mass(m2.x, m2.y, m2.velX, m2.velY, m1.mass + m2.mass, m2.radius, m2.massColor, m2.name));
        }
      } else {
        m1.velX -= FG*cosine/m1.mass;
        m1.velY -= FG*sine/m1.mass;
        m2.velX += FG*cosine/m2.mass;
        m2.velY += FG*sine/m2.mass;
      }
    }
    m1.update();
  }
  masses.addAll(addedMasses);
  masses.removeAll(removedMasses);
  addedMasses.clear();
  if (removedMasses.size()>0) {
    drawLines=true;
  }
  removedMasses.clear();
}

class Mass {
  double x, y, velX, velY, radius, mass;
  int massColor, recordLag;
  String name;
  ArrayList<Double> pastXs, pastYs;

  Mass(double x, double y, double velX, double velY, double mass, double radius, int massColor, String name) {
    this.x=x;
    this.y=y;
    this.velX=velX;
    this.velY=velY;
    this.mass=mass;
    this.radius=radius;
    this.massColor = massColor;
    this.name = name;
    recordLag = 0;

    pastXs = new ArrayList();
    pastYs = new ArrayList();
  }

  void update() {
    if (status==0 && showLine && recordLag >= 3) {
      pastXs.add(x);
      pastYs.add(y);
      recordLag = 0;
    }
    if (pastXs.size() >= maxLineLength) {
      pastXs.remove(0);
      pastYs.remove(0);
    }
    x += velX/frameRate;
    y += velY/frameRate;
    recordLag++;
  }

  void drawMass() {
    fill(massColor);
    ellipse((int)renderX(x), (int)renderY(y), (int)(radius*scale), (int)(radius*scale));
    if (nameStatus!=0)drawName();
  }

  void drawLine() {
    if (pastXs.size() > 0) {
      lines.fill(massColor);
      lines.setModified(true);
      if (drawLines) {
        double lastX = renderX(pastXs.get(0)), lastY = renderY(pastYs.get(0));
        boolean lastInside = lastX >= 0 && lastX <= width && lastY >= 0 && lastY <= height;
        for (int i = 1; i < pastXs.size(); i++) {
          double xPos = renderX(pastXs.get(i)), 
            yPos = renderY(pastYs.get(i));
          boolean inside = xPos >= 0 && xPos <= width && yPos >= 0 && yPos <= width;
          if (lastInside || inside) {
            lines.line((float)lastX, (float)lastY, (float)xPos, (float)yPos);
          }
          lastX = xPos;
          lastY = yPos;
          lastInside = inside;
        }
      } else {
        lines.line((float)renderX(pastXs.get(pastXs.size()-1)), (float)renderY(pastYs.get(pastXs.size()-1)), (float)renderX(x), (float)renderY(y));
      }
    }
  }

  void drawName() {
    double renderX = renderX(x), 
      renderY = renderY(y);
    if (renderX >= 0 && renderX <= width && renderY >= 0 && renderY <= height) {
      drawText(name, (nameStatus==2)?18:(int)(radius*scale), (int)renderX, (int)renderY);
    }
  }
}

void keyPressed() {
  if (key==CODED) {
    if (keyCode==SHIFT) enhancedZoom = true;
    else {
      switch(status) {
      case 0:
        if (keyCode==UP) simulationRate++;
        else if (keyCode==DOWN) simulationRate = Math.max(1, simulationRate-1);
      }
    }
  } else if (key==ENTER) {
    try {
      switch(status) {
      case 1:
        newMass().x = Double.parseDouble(inputText);
        mouseLinked = false;
        inputText = "";
        status++;
        break;
      case 2:
        newMass().y = Double.parseDouble(inputText);
        mouseLinked = false;
        inputText = "";
        status++;
        break;
      case 3:
        newMass().mass = Double.parseDouble(inputText);
        mouseLinked = false;
        inputText = "";
        status++;
        break;
      case 4:
        newMass().velX = Double.parseDouble(inputText);
        mouseLinked = false;
        inputText = "";
        status += newMass().velX==0?2:1;
        break;
      case 5:
        double radians = Math.toRadians(Double.parseDouble(inputText)), 
          sine = Math.sin(radians), 
          cos = Math.cos(radians), 
          velocity = Math.sqrt(newMass().velX * newMass().velX + newMass().velY*newMass().velY);
        newMass().velX = cos*velocity;
        newMass().velY = sine*velocity;
        mouseLinked = false;
        inputText = "";
        status++;
        break;
      case 6:
        newMass().radius = Double.parseDouble(inputText);
        mouseLinked = false;
        inputText = "";
        status++;
        break;
      case 7:
        newMass().name = inputText;
        mouseLinked = false;
        inputText = "";
        status = 0;
        break;
      }
    }
    catch(Exception e) {
      flashTimer = 60;
    }
  } else if (key==ESC) {
    key = 0;  
    switch(status) {
    case 1:
      masses.remove(masses.size()-1);
      status = 0;
      break;
    case 2:
      status = 1;
      mouseLinked = false;
      inputText = newMass().x + "";
      break;
    case 3:
      status = 2;
      mouseLinked = false;
      inputText = newMass().y + "";
      break;
    case 4:
      status = 3;
      mouseLinked = false;
      inputText = newMass().mass + "";
      break;
    case 5:
      status = 4;
      mouseLinked = false;
      double velocity = Math.sqrt(newMass().velX*newMass().velX+newMass().velY*newMass().velY);
      inputText = velocity + "";
      newMass().velY = 0;
      newMass().velX = velocity;
      break;
    case 6:
      status = 5;
      mouseLinked = false;
      inputText = Math.atan(newMass().velY/newMass().velX) + "";
      break;
    case 7:
      status = 6;
      mouseLinked = false;
      inputText = newMass().radius + "";
    }
  } else if (key==DELETE || key==BACKSPACE) {
    if (status != 0 && !inputText.equals("")) {
      inputText = inputText.substring(0, inputText.length()-1);
      if (status != 3 && status != 4) mouseLinked = false;
    }
  } else if (key=='n' && status==0) {
    createMass();
  } else if (key=='h' && status != 7) {
    drawLines=true;
    if (status==0) {
      scale = 1;
      xOffset = -width/2;
      yOffset = -height/2;
    } else {
      xOffset = newMass().x - width/2/scale;
      yOffset = newMass().y - height/2/scale;
    }
  } else if (key=='c' && status != 7) {
    if (status==0)removedMasses.addAll(masses);
  } else if (status>=1 && status <= 6) {
    inputText += numText(key, status < 3);
    if (status != 3 && status != 4 )mouseLinked = false;
  } else if (status==7) {
    inputText += key;
  } else if (key==' ' && status==0) {
    paused = !paused;
  } else if (key=='l' && status==0) {
    if (showLine) {
      showLine = false;
      for (Mass mass : masses) {
        mass.pastXs.clear();
        mass.pastYs.clear();
      }
    } else {
      showLine = true;
    }
  } else if (key=='m'&&status==0) {
    nameStatus = (nameStatus+1)%3;
  } else if (key=='g'&&status==0) {
    gridStatus = (gridStatus+1)%2;
  } else if ((int)key > 47 && (int)key < 58 && status==0) {
    int newSave = (int)key-48;
    if (currentSave==newSave) {
      saveStrings(key + ".txt", compile().toArray(new String[0]));
    } else {
      currentSave = newSave;
      ArrayList<String> lines;
      if ((lines = readFile(key + ".txt"))==null) {
        newUniverse();
      } else {
        decompile(lines);
      }
    }
  }
}

ArrayList<String> compile() {
  ArrayList<String> compiled = new ArrayList();
  compiled.add(xOffset + "/" + yOffset + "/" + scale + "/" + (paused?"1":"0") + "/" + (showLine?"1":"0") + "/" + (simulationRate));
  for (Mass mass : masses) {
    compiled.add(mass.x + "/" + mass.y + "/" + mass.velX + "/" + mass.velY + "/" + mass.mass + "/" + mass.radius + "/" + mass.massColor + "/(" + mass.name);
  }
  return compiled;
}

void decompile(ArrayList<String> lines) {
  String[] data = lines.get(0).split("/");
  xOffset = Double.parseDouble(data[0]);
  yOffset = Double.parseDouble(data[1]);
  scale = Double.parseDouble(data[2]);
  paused = data[3].equals(1);
  showLine = data[4].equals(1);
  simulationRate = Integer.parseInt(data[5]);
  lines.remove(0);
  for (String compiledMass : lines) {
    String[] massData = compiledMass.split("/");
    Mass mass = new Mass(Double.parseDouble(massData[0]), Double.parseDouble(massData[1]), 
      Double.parseDouble(massData[2]), Double.parseDouble(massData[3]), 
      Double.parseDouble(massData[4]), Double.parseDouble(massData[5]), Integer.parseInt(massData[6]), 
      compiledMass.substring(compiledMass.indexOf('(')+1, compiledMass.length()));
    addedMasses.add(mass);
  }
}

ArrayList<String> readFile(String name) {
  try {
    BufferedReader reader = createReader(name);
    ArrayList<String> lines = new ArrayList();
    String line;
    while ((line = reader.readLine()) != null) {
      lines.add(line);
    }
    return lines;
  }
  catch(Exception e) {
    return null;
  }
}

void keyReleased() {
  if (key==CODED) {
    if (keyCode==SHIFT) enhancedZoom = false;
  } else {
  }
}

void createMass() {
  status = 1;
  masses.add(new Mass(0, 0, 0, 0, 0, 20*scale, color(random(0, 255), random(0, 255), random(0, 255)), ""));
  inputText = "";
}

void mouseMoved() {
  switch(status) {
  case 0:
    break;
  case 1:
    newMass().x = unRenderX(mouseX);
    mouseLinked = true;
    break;
  case 2:
    newMass().y = unRenderY(mouseY);
    mouseLinked = true;
    break;
  case 5:
    double xDis = unRenderX(mouseX) - newMass().x, 
      yDis = unRenderY(mouseY) - newMass().y, 
      dis = Math.sqrt(xDis * xDis + yDis * yDis), 
      velocity = Math.sqrt(newMass().velX*newMass().velX + newMass().velY * newMass().velY), 
      sine = yDis/dis, 
      cos = xDis/dis;
    newMass().velX = cos*velocity;
    newMass().velY = sine*velocity;
    mouseLinked = true;
    break;
  case 6:
    newMass().radius = Math.sqrt(Math.pow(newMass().x - unRenderX(mouseX), 2) + Math.pow(newMass().y - unRenderY(mouseY), 2));
    mouseLinked = true;
    break;
  }
}

void mouseClicked() {
  if ((status!= 0 && status < 3) || status == 5 || status==6) {
    status = (status+1)%8;
    inputText = "";
  }
}

void mouseWheel(MouseEvent e) {
  double count = e.getCount();
  double x, y;
  x = xOffset + width/scale/2;
  y = yOffset + height/scale/2;
  scale *= Math.pow(enhancedZoom ? 2 : 1.01, count);
  xOffset = x - width/2/scale;
  yOffset = y - height/2/scale;
  drawLines = true;
}

Mass newMass() {
  return masses.get(masses.size()-1);
}

double renderX(double x) {
  return (x - xOffset)*scale;
}

double renderY(double y) {
  return (y - yOffset)*scale;
}

double unRenderX(double x) {
  return x/scale + xOffset;
}

double unRenderY(double y) {
  return y/scale + yOffset;
}

void drawText(String text, int size, int x, int y) {
  if (size > 0) {
    textSize(size);
    fill(color(0, 0, 0));
    text(text, x, y);
    fill(color(255, 255, 255));
    text(text, x + 2, y);
  }
}

String numText(char keyChar, boolean negative) {
  int askiiCode = (int)keyChar;
  if ((askiiCode > 47 && askiiCode < 58) || askiiCode==46 || askiiCode==101 || (negative && askiiCode==45)) {
    return keyChar + "";
  }
  return "";
}

String shortenDecimal(double num) {
  String numString = num + "";
  if (numString.contains("E")) {
    String[] split = numString.split("E");
    int index = split[0].indexOf("."), 
      end = index + 4;
    if (split[0].length() < end) end = split[0].length();
    return split[0].substring(0, end) + "E" + 
      split[1];
  } else {
    int index = numString.indexOf("."), 
      end = index + 4;
    if (numString.length() <= end) end = numString.length();
    return numString.substring(0, end);
  }
}

void newUniverse() {
  masses = new ArrayList();
  addedMasses = new ArrayList();
  removedMasses = new ArrayList();
  xOffset = 0;
  yOffset = 0;
  scale = 1;
  xOffset = -width/2;
  yOffset = -height/2;
  showLine = true;
  drawLines = true;
  quantityVisible=true;
  flashTimer = 0;

  lines = createGraphics(width, height);
  simulationRate = 1;
  nameStatus = 2;
  gridStatus = 0;
  paused = false;
}
