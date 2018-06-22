import SimpleOpenNI.*;
import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;

import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;

SimpleOpenNI  kinect;
AudioPlayer player;

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

boolean tracking=false;

// set up kinect window and properties
void setup() {
    minim = new Minim(this);
    player = minim.loadFile("marcus_kellis_theme.mp3");
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

            drawSkeleton(userID[ui]);
            println(tracking);

            background(0);
            stroke(255);
            strokeWeight(1);

            // draw the waveform of the file
            stroke( 128, 0, 0 );
            strokeWeight(4);
            for(int i = 0; i < player.bufferSize() - 1; i++) {
                float x1 = map( i, 0, player.bufferSize(), 0, width );
                float x2 = map( i+1, 0, player.bufferSize(), 0, width );
                line( x1, 50 + player.left.get(i)*50, x2, 50 + player.left.get(i+1)*50 );
                line( x1, 150 + player.right.get(i)*50, x2, 150 + player.right.get(i+1)*50 );
            }

            if ( confidenceRH>0.5 && confidenceLH>0.5 && confidenceH>0.5 && confidenceLS>0.5 && confidenceRS>0.5 ) {
                tracking = true;
                break;
            }

            else {
                tracking=false;
            }
        }
    }
    //if tracking is true
    if (tracking) {
        //if the rightHand is higher then right shoulder
        if (rightHand.y > rightShoulder.y) {
            //play the file
            player.play();
        }
        //if the leftHand is higher then the left shoulder
        if (leftHand.y > leftShoulder.y) {
            //pause the file
            player.pause();
        }
        //if the right hand is close to the sensor, exit the application.
        if (rightHand.z < 500) {
            exit();
        }
    }
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
