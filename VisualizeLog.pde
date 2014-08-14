import shapes3d.utils.*;
import saito.objloader.*;

float rotX, rotY, rotZ, transX, transY, transZ = 0f;

Rot[] r = {new Rot(new PVector(1,0,0), 0), new Rot(new PVector(1,0,0), 0),new Rot(new PVector(1,0,0), 0)};
PVector[] axis = {new PVector(),new PVector(),new PVector()};
float[] angle = {0,0,0};
OBJModel upperarm;
OBJModel extraarm;
OBJModel lowerarm;
BoundingBox upBox;
BoundingBox loBox;
BoundingBox exBox;

Table data;
int dataCount = 0;
int totalRows;
boolean pause = false;
int speed = 1;
int manualFrameRate = 50; // Processing's default is 60 (quite fast). Min: 10, max: 90
long timestamp = 0L;
boolean third = false;
boolean invert = true;
boolean perspective = false;
float rotateThird = 0f;

void setup() {
  //rotY = 3.0f/2*(float)(Math.PI);
  //rotZ = 1.0f/8*(float)Math.PI;
  rotY = (float)Math.PI;
  size(1000, 800, P3D);
  frameRate(manualFrameRate);
  noStroke();
  upperarm = new OBJModel(this, "upperarm.obj", TRIANGLE);
  lowerarm = new OBJModel(this, "lowerarm.obj", TRIANGLE);
  extraarm = new OBJModel(this, "upperarm.obj", TRIANGLE);
  
  upperarm.disableMaterial();
  lowerarm.disableMaterial();
  extraarm.disableMaterial();
  
  upperarm.scale(20);
  lowerarm.scale(20);
  extraarm.scale(40);
  
  upperarm.translateToCenter();
  lowerarm.translateToCenter();
  extraarm.translateToCenter();
  
  upBox = new BoundingBox(this, upperarm);
  loBox = new BoundingBox(this, lowerarm);
  exBox = new BoundingBox(this, extraarm);
  
  if(data == null) selectInput("Choose a log file to visualize", "readFile");
}

void draw() {
  if(data == null) return; //Do not draw until a file has been loaded to visualize
  
  // Read the next row from the data file and process the quaternions
  if(dataCount>=totalRows){
    //pause = true;
   frameRate(5); 
    return;
  }
  
  dataCount = dataCount % totalRows;
  processRow(data.getRow(dataCount));
  
  background(0);
  fill(255);
  camera();
  text("FPS: "+frameRate, 5, 15);
  lights();
  
  // Change the camera position and up-axis so that up is in the negative z-axis
  // and it is in a plane perpendicular to the positive x-axis pointing into the center of the scene
  camera(width+width/2.0f, height/2.0f, 0, width/2.0f, height/2.0f, 0, 0, 0, -1);
  
  pushMatrix();
  translate(0, height*.5f, 200);
  //rotX = 1.57f;
  //rotZ = 3.14f;
  // Mouse control
  if(third && perspective){
    double mag = Math.sqrt(axis[2].x*axis[2].x+axis[2].y*axis[2].y+axis[2].z*axis[2].z);
    rotX = (float)(Math.acos(axis[2].x/mag));
    rotY = (float)(Math.acos(axis[2].y/mag));
    rotZ = (float)(Math.acos(axis[2].z/mag));
  }
  rotateX(-rotX);
  rotateY(-rotY);
  rotateZ(-rotZ);
  //}
  stroke(255,0,0);
  
  line(0, 0,0,100,0,0);
  line(100, 0,0,100,100,0);
  line(100, 100,0,0,100,0);
  line(0, 100,0,0,0,0);
  line(-width/2, 0,0,width, 0, 0);
  stroke(0,255,0);
  line(0, -width/2,0,0, width, 0);
  stroke(0,0,255);
  line(0, 0,-width/2,0,0, width);
  
  stroke(255);
  
  if(third) {
    PVector ewhd = exBox.getWHD();
    PVector ecenter = exBox.getCenter();
    PVector eoffset = PVector.sub(ewhd, ecenter);
  
    translate(0, 0,-eoffset.y/2.0);
    //if(invert) rotate(angle[2]+1.0f*(float)(Math.PI), axis[2].x, -axis[2].y, axis[2].z);
    //else rotate(angle[2], axis[2].x, -axis[2].y, axis[2].z);
    rotate(angle[2]+rotateThird, axis[2].x, -axis[2].y, axis[2].z);
  
    translate(0, eoffset.y/2.0, 0);
    extraarm.draw();  
  }
  //float exoffset = eoffset.y; 
  PVector whd = upBox.getWHD();
  PVector center = upBox.getCenter();
  PVector offset = PVector.sub(whd, center);

  if(third)
    translate(0, -100,0);
  
  // Shift center of rotation to the shoulder joint    
  translate(0, -offset.y/2.0, 0);
  rotateX(0.1); // slightly rotated as if coming off a shoulder
  translate(0, offset.y/2.0, 0);
  if(third){
    //if(invert)
      //rotate(-(angle[2]+1.0f*(float)(Math.PI)), axis[2].x, -axis[2].y, axis[2].z);
    //else rotate(-angle[2], axis[2].x, -axis[2].y, axis[2].z);
    rotate(-(angle[2]+rotateThird), axis[2].x, -axis[2].y, axis[2].z);
  }
  rotate(angle[0], axis[0].x, -axis[0].y, axis[0].z);
  translate(0, offset.y/2.0, 0);  
  
  upperarm.draw();
      
  pushMatrix();
  rotateX(-0.1); //rotate back to vertical (for natural 'hanging')
  
  float upOffset = offset.y;
  whd = loBox.getWHD();
  center = upBox.getCenter();
  offset = PVector.sub(whd, center);
  
  // Trying to get the bone+socket to align correctly (visually)
  translate(7, loBox.getMax().y - upBox.getMax().y + upOffset - 25, 10);
  
  translate(0, -offset.y/2.0, 0);
  // Since both sensors are returning world-frame orientations, 
  // 'undo' the effects from the first sensor before applying the change from the second
  rotate(-angle[0], axis[0].x, -axis[0].y, axis[0].z);
  //if(third)
    //rotate(-angle[2], axis[2].x, -axis[2].y, axis[2].z);
  rotate(angle[1], axis[1].x, -axis[1].y, axis[1].z);
  translate(0, offset.y/2.0, 0);
  
  lowerarm.draw();

  popMatrix();
  popMatrix();
  
}

void readFile(File selection) {
  if(selection == null) {
    println("No file chosen.");
  } else {
    data = loadTable(selection.getAbsolutePath(), "header, csv");
    totalRows = data.getRowCount();
  }
}

void processRow(TableRow row) {
  r[0] = new Rot(row.getFloat(1), row.getFloat(2), row.getFloat(3), row.getFloat(4), true);
  axis[0] = r[0].getAxis();
  angle[0] = r[0].getAngle();
  r[1] = new Rot(row.getFloat(5), row.getFloat(6), row.getFloat(7), row.getFloat(8), true);
  axis[1] = r[1].getAxis();
  angle[1] = r[1].getAngle();
  if(third) {
    r[2] = new Rot(row.getFloat(9), row.getFloat(10), row.getFloat(11), row.getFloat(12), true);
    axis[2] = r[2].getAxis();
    angle[2] = r[2].getAngle();
  }
  timestamp = row.getLong(0);
  if(!pause){
    dataCount = dataCount+speed;
  }
}

void keyPressed() {
  if(key == CODED) {
    if(keyCode == LEFT) {
      //go back 20 samples. It's like a reverse button
      dataCount = dataCount-20;
      if(dataCount<0) dataCount = 0;
    }
    if(keyCode == RIGHT) {
      //move 20 sample forward in the visualization
      dataCount = dataCount+20;
      if(dataCount>=totalRows) dataCount = totalRows-1;
    }
  }
  if(key == '+' || key == '=') {
    //manualFrameRate += 5;
    //Increase visualization speed
    speed++;
    if(speed>10) speed = 10;
    if(manualFrameRate > 90) manualFrameRate = 90;
    frameRate(manualFrameRate);
  }
  if(key == '-' || key == '_') {
    //manualFrameRate -= 5;
    //Decrease visualization speed
    speed--;
    if(speed<0) speed = 1;
    if(manualFrameRate < 10) manualFrameRate = 10;
    frameRate(manualFrameRate);
  }
  if(key == 'x') {
    //Rotate around X axis
    rotX += (Math.PI/8);
  }
  if(key == 'X') {
    //Rotate around X axis in the other direction
    rotX -= (Math.PI/8);
  }
  if(key == 'y') {
    //Rotate around Y axis
    rotY += (Math.PI/8);
  }
  if(key == 'Y') {
    //Rotate around Y axis in the other direction
    rotY -= (Math.PI/8);
  }
  if(key == 'z') {
    //Rotate around Z axis
    rotZ += (Math.PI/8);
  }
  if(key == 'Z') {
    //Rotate around Z axis in the other direction
    rotZ -= (Math.PI/8);
  }
  if(key == 'r') {
    //Reset axis rotations
    rotZ = 0; rotX =0; rotY=(float)(Math.PI);
  }
  if(key == '<' || key == ',') {
    //Go back to the start of the log file
    dataCount = 0;
  }
  if(key == 'S' || key == 's') {
    //Mark start of the gesture S
    print(timestamp+",S\n");
  }
  if(key == 'E' || key == 'e') {
    //Mark end of the gesture E
    print(timestamp+",E\n");
  }
  if(key == 'P' || key == 'p') {
    //Toggle automatic rotation of axis.
    //This tries to find the best view automatically.
    perspective = !perspective;
  }
  if(key == 'I' || key == 'i') {
    rotateThird = rotateThird+(float)(Math.PI/2);
  }
  if(key == 'T' || key == 't') {
    //Toggle the chest sensor in view. If there is data from the third sensor on the chest,
    //it can be used in the visualization
    third = !third;
  }
  if(key == ' ') {
    //Pause/Unpause
    pause = !pause;
    if(pause)
      frameRate(5);
    else
      frameRate(manualFrameRate);
  }
}

void mouseDragged() {
  float x = (mouseX-pmouseX);
  float y = (mouseY-pmouseY);
  if(mouseButton == LEFT) {
      rotX += x * 0.01;
  }
}
