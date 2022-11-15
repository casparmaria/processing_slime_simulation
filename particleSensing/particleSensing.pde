import ch.bildspur.postfx.builder.*;
import ch.bildspur.postfx.pass.*;
import ch.bildspur.postfx.*;
import java.util.concurrent.ThreadLocalRandom;
import java.util.Random;
import java.lang.*;
// install library before running:
PostFX fx;

int choice, frameCounter=0;
boolean firstIteration = true;
ArrayList<TailParticle> tailParticles;
ArrayList<Particle> particles;

// simulation
int AMOUNT_PARTICLES = 1000;
int SPEED = 3;
// looks
int TAIL_THICKNESS = 50;
int TAIL_particleNum = 20;
int TAIL_DISTANCE = 4;
// sensor settings
int SENSOR_DISTANCE = 20;
double SENSOR_OFFSET_ANGLE = PI/6;
boolean SHOW_SENSORS = false;
double TURNING_ANGLE = PI/30;

void setup() {
  size(1000, 500, P2D);
  background(0);
  
  //placeParticlesCircle();
  placeParticlesRandom();
  //placeParticlesCenter();

  //fx = new PostFX(this);
}

void draw() {
  background(0);
  
  for (int i = 0; i < particles.size(); i++) {
    Particle tempParticle = (Particle)particles.get(i);
    tempParticle.move();
    tempParticle.displayTail();
    tempParticle.displayHead();
  }
  
  //fx.render()
  //  .blur(10,10)
  //  .compose();
  
  loadPixels();
  firstIteration = false;
  //saveFrame("frames/####.png");
  //frameCounter++;
  //print(frameCounter + "\n");
}

class Particle {
  int tailDistanceCounter;
  long xpos, ypos;
  double angleRadians;
  ArrayList<TailParticle> tailParticles;
  
  Particle(int tempXpos, int tempYpos, double tempAngle){
    xpos = tempXpos;
    ypos = tempYpos;
    angleRadians = tempAngle;
    tailParticles = new ArrayList<TailParticle>();
    tailDistanceCounter = 0;
  }
  
  void displayHead() {
    stroke(255);
    fill(255);
    rectMode(CENTER);
    circle(xpos, ypos, 7);   
    }

  void displayTail() {
    if (tailDistanceCounter > TAIL_DISTANCE) {
      tailParticles.add(new TailParticle(xpos, ypos));
      tailDistanceCounter = 0;
    } else {tailDistanceCounter++;}
      
    if (tailParticles.size() > TAIL_particleNum) {
      tailParticles.remove(0);
    }
    
    // iterate through particles and display them
    for (int i = 0; i < tailParticles.size(); i = i+1) {
      TailParticle tempParticle = (TailParticle)tailParticles.get(i);
      tempParticle.display(i);
    }
  }

  
  void move() {
    double angle1, angle2;
    LongList sensorPositions = sensorPositions(xpos, ypos, angleRadians);
    
    if (firstIteration == false) { //ignore first iteration
      long recommendation = getSensorRecommendation(sensorPositions);
      if (recommendation == 1) {
        angleRadians = angleRadians - TURNING_ANGLE;
      }
      else if (recommendation == 3) {
        angleRadians = angleRadians + TURNING_ANGLE;
      }
      
      // if angle cuts circle cut, adjust
      if (angleRadians < 0) {
        angleRadians += 2 * PI;
      } 
      else if (angleRadians > 2 * PI) {
        angleRadians -= 2 * PI;
      }
    }
    xpos = Math.round(SPEED * Math.cos(angleRadians) + xpos);
    ypos = Math.round(SPEED * Math.sin(angleRadians) + ypos);

    if (xpos < 0) {
      if (ypos==0) {
        angleRadians = random((PI/15),PI/2-(PI/15));
      } else {
        int choice = int(Math.round(Math.random()));
        DoubleList angles = new DoubleList();
        angle1 = randomRadianAngle((PI/15),PI/2-(PI/15));
        angle2 = randomRadianAngle(3/2*PI+(PI/15), 2*PI-(PI/15));
        angles.append(angle1);
        angles.append(angle2);
        angleRadians = angles.get(choice);
      }
    }

    
    else if (ypos < 0) {
      if (xpos == 0) {
        angleRadians = randomRadianAngle((PI/15),PI/2-(PI/15));
      } else {
        angleRadians = randomRadianAngle((PI/15),PI-(PI/15));
      }
    }
    
    else if (height < ypos) {
      if (xpos == 0) {
        angleRadians = randomRadianAngle(3/2*PI+(PI/15), 2*PI-(PI/15));
      } else {
        angleRadians = randomRadianAngle(PI+(PI/15), 2*PI-(PI/15));
      }
    }
    
    else if (width < xpos) {
      if (ypos == 0) {
        angleRadians = randomRadianAngle(PI/2+(PI/15),PI-(PI/15));
      } else{
        angleRadians = randomRadianAngle(PI/2+(PI/15),3*PI/2-(PI/15));
      }
    }
  }
}
  
class TailParticle {
  long xpos, ypos;
  
  TailParticle(long tempXpos, long tempYpos) {
    xpos = tempXpos;
    ypos = tempYpos;
  }
  
  void display(int size) {
    noStroke();
    fill(size*255/TAIL_particleNum,size*100/TAIL_particleNum);
    rectMode(CENTER);
    circle(xpos, ypos, TAIL_THICKNESS - size*2);
  }
}

/*
   returns list of [lX, lY, cX, cY, rX, rY]
   takes current agent pos&angle
   needs static int SENSOR_OFFSET_ANGLE&SENSOR_DISTANCE
*/
public LongList sensorPositions(
  long agentX, long agentY, double agentRadianAngle) {

  double leftAngle = agentRadianAngle - SENSOR_OFFSET_ANGLE;
  double rightAngle = agentRadianAngle + SENSOR_OFFSET_ANGLE;
  
  if (leftAngle < 0) {
    leftAngle += 2 * PI;
  } 
  else if (rightAngle > 2 * PI) {
    rightAngle -= 2 * PI;
  }
  
  long centerX = Math.round(Math.cos(agentRadianAngle)*SENSOR_DISTANCE)+agentX;
  long centerY = Math.round(Math.sin(agentRadianAngle)*SENSOR_DISTANCE)+agentY;
  long leftX = Math.round(Math.cos(leftAngle)*SENSOR_DISTANCE)+agentX;
  long leftY = Math.round(Math.sin(leftAngle)*SENSOR_DISTANCE)+agentY;
  long rightX = Math.round(Math.cos(rightAngle)*SENSOR_DISTANCE)+agentX;
  long rightY = Math.round(Math.sin(rightAngle)*SENSOR_DISTANCE)+agentY;

  LongList sensorCoordinates = new LongList();
  sensorCoordinates.append(leftX);
  sensorCoordinates.append(leftY);
  sensorCoordinates.append(centerX);
  sensorCoordinates.append(centerY);
  sensorCoordinates.append(rightX);
  sensorCoordinates.append(rightY);
  
  for (int i = 0; i < 6; i += 2) {
    if (sensorCoordinates.get(i) < 0 || sensorCoordinates.get(i) > width) {
      sensorCoordinates.set(i, -1); 
      sensorCoordinates.set(i+1, -1);
    }
  }
  for (int i = 1; i < 6; i += 2) {
    if (sensorCoordinates.get(i) < 0 || sensorCoordinates.get(i) > height) {
      sensorCoordinates.set(i, -1); 
      sensorCoordinates.set(i-1, -1); 
    }
  }
  if (SHOW_SENSORS == true) {
    if (sensorCoordinates.get(0) != -1 && sensorCoordinates.get(1) != -1) {
      noStroke();
      fill(0, 0, 255);
      circle(sensorCoordinates.get(0), sensorCoordinates.get(1), 3);
    }
    
    if (sensorCoordinates.get(2) != -1 && sensorCoordinates.get(3) != -1) {
      noStroke();
      fill(255, 0, 0);
      circle(sensorCoordinates.get(2), sensorCoordinates.get(3), 3);
    }
    
    if (sensorCoordinates.get(4) != -1 && sensorCoordinates.get(5) != -1) {
      noStroke();
      fill(0, 255, 0);
      circle(sensorCoordinates.get(4), sensorCoordinates.get(5), 3);
    }
  }
  return sensorCoordinates; 
}
// returns 1 if left, 2 if center, 3 if right
public long getSensorRecommendation(LongList sensorPositions) {
  
  FloatList brightnesses = new FloatList(); // brightnesses, LCR
  IntList existingSensors = new IntList(); // 1 if exists, 0 if not, LCR
  
  for (int i = 0; i < 3; i++) {
    existingSensors.append(1);
    brightnesses.append(0);
  }

  
  for (int i = 0; i < 3; i++) {
    if (sensorPositions.get(i*2) < 0 || sensorPositions.get(i*2+1) < 0) {
      existingSensors.set(i,0);
      brightnesses.set(i,-1);
    }
  }
  for (int i = 0; i < 3; i++) {
    if (existingSensors.get(i) == 1) {
      long xCoo = sensorPositions.get(2*i);
      long yCoo = sensorPositions.get(2*i+1);
      int location = int(xCoo+yCoo*width);
      if (location < width * height) {
        float r = red(pixels[location]);
        float g = green(pixels[location]);
        float b = blue(pixels[location]);
        float brightness = brightness(color(r, g, b));
        brightnesses.set(i, brightness);
      }
    }
  }

  float leftBrightness = brightnesses.get(0);
  float centerBrightness = brightnesses.get(1);
  float rightBrightness = brightnesses.get(2);
  long recommendation;
  
  if (centerBrightness > rightBrightness && centerBrightness > leftBrightness){
    recommendation = 2;
  }
  else if (centerBrightness < leftBrightness && centerBrightness < rightBrightness){
    recommendation = Math.round(Math.random()*2);
  }
  else if (leftBrightness < rightBrightness){
    recommendation = 3;
  }
  else if (leftBrightness > rightBrightness){
    recommendation = 1;
  }
  else {
    recommendation = 2;
  }
  return recommendation;
}

// returns random angle in radians between upper and lower bound
public static double randomRadianAngle(double lower_bound, double upper_bound) {
  double randomNum = lower_bound + ThreadLocalRandom.current().nextDouble()
  * (upper_bound - lower_bound);
  return randomNum;
}

void placeParticlesRandom() {
  particles = new ArrayList<Particle>();
  for (int i = 0; i < AMOUNT_PARTICLES; i++) {
    particles.add(new Particle(
      int(Math.round((Math.random()*width))), 
      int(Math.round((Math.random()*height))),
      randomRadianAngle(0,2*PI))
      );
  }
}

void placeParticlesCenter() {
  particles = new ArrayList<Particle>();
  for (int i = 0; i < AMOUNT_PARTICLES; i++) {
    particles.add(new Particle(
      int(width/2), int(height/2),
      randomRadianAngle(0,2*PI))
      );
  }
}

void placeParticlesCircle() {
  particles = new ArrayList<Particle>();
  for (int i = 0; i < AMOUNT_PARTICLES; i++) {
    double rand = Math.random()*2*PI;
    double xCo = width/2 + Math.sqrt(250) * Math.cos(rand);
    double yCo = height/2 + Math.sqrt(250) * Math.sin(rand);
    particles.add(new Particle(
      int(Math.round(xCo)), int(Math.round(yCo)), 
      randomRadianAngle(0,2*PI))
      );
  }
}
