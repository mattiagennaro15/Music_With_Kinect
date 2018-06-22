import SimpleOpenNI.*;
import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;

import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;
Oscil wave;
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

boolean tracking=false;

// set up kinect window and properties
void setup() {

    minim = new Minim(this);
    out = minim.getLineOut();
    // create a sine wave Oscil, set to 440 Hz, at 0.5 amplitude
    wave = new Oscil( 440, 0.5f, Waves.SINE );
    // patch the Oscil to the output
    wave.patch( out );

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
    println("Visible user " + userId);
}

// draw the current kinect view
void draw() {
    kinect.update();
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

            // draw the waveform of the output
            for(int i = 0; i < out.bufferSize() - 1; i++) {
                line( i, 50  - out.left.get(i)*50,  i+1, 50  - out.left.get(i+1)*50 );
                line( i, 150 - out.right.get(i)*50, i+1, 150 - out.right.get(i+1)*50 );
            }

            stroke( 128, 0, 0 );
            strokeWeight(4);

            //draw the shape of the wave
            for( int i = 0; i < width-1; ++i ) {
                point( i, height/2 - (height*0.49) * wave.getWaveform().value( (float)i / width ) );
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

    //if tracking
    if (tracking) {
        //set the amplitude to be the result of the sigmoid function
        wave.setAmplitude(sigmoid(leftHand.y));
        //assign the value of the left hand vector x to the frequency
        float frequency = leftHand.x;
        //if the number gets below 110, set it to 110
        if (frequency < 110) {
            frequency = 110;
        }
        //if the number gets higher then 880, set it to 880
        else if (frequency > 880) {
            frequency = 880;
        }
        //set the frequency of the wave
        wave.setFrequency(frequency);

        //if the rightHand is higher then the right shoulder
        if (rightHand.y > rightShoulder.y) {
            //change the form of the wave
            wave.setWaveform(Waves.SQUARE);
        }
        //if the right hand is higher then the right shoulder
        if (rightHand.y < rightShoulder.y) {
            //change the form of the wave
            wave.setWaveform(Waves.SINE);
        }
        //if the hand is close to the sensor, exit the application.
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

//Function that takes an input and returns a value between 0.1 and 1.0
float sigmoid(float number) {
    return (1 / ( 1 + exp(- number)));
}
