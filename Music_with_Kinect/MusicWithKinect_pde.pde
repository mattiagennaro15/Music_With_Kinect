
import SimpleOpenNI.*;
import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;

import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
  

Robot robot;
SimpleOpenNI  kinect;

// vectors for joints
PVector rightHand = new PVector();
PVector rightElbow = new PVector();
PVector rightShoulder = new PVector();
PVector rightHip = new PVector();
PVector leftHand = new PVector();
PVector leftElbow = new PVector();
PVector leftShoulder = new PVector();
PVector leftHip = new PVector();
PVector neck = new PVector();
PVector head = new PVector();
PVector torso = new PVector();

//confidence values for skeleton positions
float confidenceRH = 0;
float confidenceRE = 0;
float confidenceRS = 0;
float confidenceRHip = 0;
float confidenceH = 0;
float confidenceT = 0;
float confidenceLH = 0;
float confidenceLE = 0;
float confidenceLS = 0;
float confidenceLHip = 0; 

int[] userID;

// start assuming nothing is clicked

int clicked  = 0;

// set up kinect window and properties

void setup() {

  minim = new Minim(this);
  out = minim.getLineOut();
  out.setTempo( 80 );
  out.pauseNotes();
  out.resumeNotes();
  print("Enabling Kinect.... ");
  kinect = new SimpleOpenNI(this);
  while ( kinect.enableDepth () == false ) {
    println("getting depth image");
  };
  while ( kinect.enableRGB () == false ) {
    println("getting rgb image");
  };

  println("Done.");

  background(200, 0, 0);
  kinect.alternativeViewPointDepthToImage();
  
  size(kinect.depthWidth()+kinect.rgbWidth()+10, kinect.rgbHeight());

  //flip image
  kinect.setMirror(true);

  // enable skeleton tracking
  kinect.enableUser();

  /* stroke for draing lines in skeleton */
  stroke(0, 0, 255);
  strokeWeight(3);
  smooth();

  // create object to control 
  try { 
    robot = new Robot();
  } 
  catch (AWTException e) {
    e.printStackTrace();
  }
}

// user-tracking callbacks!
void onNewUser( SimpleOpenNI context, int userId ) {
  println("User " + userId +  " detected, starting tracking....");
  kinect.startTrackingSkeleton(userId);
}
void OnLostUser( SimpleOpenNI context, int userId ) {
  println("Lost user " + userId);
}
void onVisibleUser( SimpleOpenNI context, int userId ) {
  //println("Visible user " + userId);
} 

// draw the current kinect view

void draw() {

  kinect.update();

  // draw depthImageMap
  image(kinect.depthImage(), 0, 0);
  // draw irImageMap
  image(kinect.rgbImage(), kinect.depthWidth() + 10, 0);

  boolean tracking=false;

  userID = kinect.getUsers();

  for ( int ui=0; ui<userID.length; ++ui ) {

    if (kinect.isTrackingSkeleton(userID[ui])) {

      // get joint positions and confidence for each
      confidenceRH = kinect.getJointPositionSkeleton(userID[ui], SimpleOpenNI.SKEL_LEFT_HAND, rightHand);
      confidenceRE = kinect.getJointPositionSkeleton(userID[ui], SimpleOpenNI.SKEL_LEFT_ELBOW, rightElbow);
      confidenceRS = kinect.getJointPositionSkeleton(userID[ui], SimpleOpenNI.SKEL_LEFT_SHOULDER, rightShoulder);
      confidenceRHip = kinect.getJointPositionSkeleton(userID[ui], SimpleOpenNI.SKEL_LEFT_HIP, rightHip);
      confidenceH = kinect.getJointPositionSkeleton(userID[ui], SimpleOpenNI.SKEL_HEAD, head);
      confidenceT = kinect.getJointPositionSkeleton(userID[ui], SimpleOpenNI.SKEL_TORSO, torso);
      confidenceLH = kinect.getJointPositionSkeleton(userID[ui], SimpleOpenNI.SKEL_RIGHT_HAND, leftHand);
      confidenceLE = kinect.getJointPositionSkeleton(userID[ui], SimpleOpenNI.SKEL_RIGHT_ELBOW, leftElbow);
      confidenceLS = kinect.getJointPositionSkeleton(userID[ui], SimpleOpenNI.SKEL_RIGHT_SHOULDER, leftShoulder);
      confidenceLHip = kinect.getJointPositionSkeleton(userID[ui], SimpleOpenNI.SKEL_RIGHT_HIP, leftHip);
      
      println("ConfidenceRH: " + confidenceRH);
      println("ConfidenceLH: " + confidenceLH);
      println("ConfidenceH: " + confidenceH);
      println("ConfidenceLS: " + confidenceLS);
      println("ConfidenceRS: " + confidenceRS);

      drawSkeleton(userID[ui]);
      println(tracking);
      println("Sto per entrare nell'if");
      if ( confidenceRH>0.5 && confidenceLH>0.5 && confidenceH>0.5 && confidenceLS>0.5 && confidenceRS>0.5 ) {
        println("Sono entrato nell'if");
        tracking = true;
        break;
      } else {
        tracking=false;
      }
    }
  } 
  println("Tracking dopo il tutto" + tracking);
  if ( tracking )
    detect_user_behaviour();
}

// draw the skeleton

void drawSkeleton(final int userId) {
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  kinect.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  kinect.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);
}

// the user model
// left hand moves mouusse
// right hand clicks mouse


//void detect_user_behaviour ()
//{
//  println(confidenceLH);
//  if (confidenceLH > 0.5) {
//    println("Entro nell'if del condifence");
//
//    if ((leftHand.z - torso.z) < -500)
//    {
//      println("Entro nell'if della mano e del torace");
//      if (leftHand.y > leftShoulder.y && clicked == 0) {
//        println("Entro nell'if importante");
//        robot.mousePress(InputEvent.BUTTON1_MASK);
//        robot.mouseRelease(InputEvent.BUTTON1_MASK);
//      } else
//      {
//        robot.mousePress(InputEvent.BUTTON1_MASK);
//        clicked = 1;
//      }
//    } else if (clicked == 1) {
//      robot.mouseRelease(InputEvent.BUTTON1_MASK);
//      clicked = 0;
//    }
//
//    if (confidenceRH > 0.5) {
//      PVector convertedRightHand = new PVector();
//      kinect.convertRealWorldToProjective(rightHand, convertedRightHand);
//      robot.mouseMove(int(convertedRightHand.x*3), int(convertedRightHand.y*2.5));
//    }
//  }
//
//  // Commands to control mouse
//
//  // mouse clicks 
//  // robot.mousePress(InputEvent.BUTTON1_MASK);
//  // robot.mouseRelease(InputEvent.BUTTON1_MASK);
//
//  // To move mouse
//  // First we need to map 3D coordinates onto 2D screen   
//  // PVector convertedRightHand = new PVector();
//  // kinect.convertRealWorldToProjective(rightHand, convertedRightHand);
//  // robot.mouseMove(int(convertedRightHand.x), int(convertedRightHand.y));
//
//  // robot.mouseWheel(-100);
//}

void detect_user_behaviour() {
   println("Entro nella funzione");
    if (confidenceLH > 0.5) {
      println("ENTRO NELL'IF IMPORTANTE");
      println("CONFIDENCE"+confidenceLH);
      
     if (leftHand.z > rightHand.z) {
       
       println("LA MANO SINISTRA E' PIU' IN ALTO DELLA DESTRA");
       out.playNote(3.0,"G5");
     }
     
     
    }
   
}

