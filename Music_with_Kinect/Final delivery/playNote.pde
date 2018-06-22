import SimpleOpenNI.*;
import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;

import ddf.minim.*;
import ddf.minim.ugens.*;

Minim minim;
AudioOutput out;

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
//Set the counter to 0
int relevatedCount = 0;
//Initialise the lastNote variable
String lastNote = "startNote";
boolean isMovingMan = false;
boolean tracking=false;

// set up kinect window and properties
void setup() {
	//instatiating the objects
	minim = new Minim(this);
	out = minim.getLineOut();
	//setting the tempo and resume the notes
	out.setTempo(60);
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
	//setting the size of the image showed in the screen.
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

    background(0);
    stroke(255);

    // draw the waveforms
    for(int i = 0; i < out.bufferSize() - 1; i++)
    {
      line( i, 50 + out.left.get(i)*50, i+1, 50 + out.left.get(i+1)*50 );
      line( i, 150 + out.right.get(i)*50, i+1, 150 + out.right.get(i+1)*50 );
    }

	kinect.update();

    // draw depthImageMap
	image(kinect.depthImage(), 0, 0);

	userID = kinect.getUsers();
	//looping trough the users
	for ( int ui=0; ui<userID.length; ++ui ) {
		//checking if the user is tracked
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

			//draw the skeleton
			drawSkeleton(userID[ui]);

			if ( confidenceRH>0.5 && confidenceLH>0.5 && confidenceH>0.5 && confidenceLS>0.5 && confidenceRS>0.5 ) {
				tracking = true;
				break;
			}

			else {
				tracking=false;
			}
		}
	}

    if (tracking) {

		//get the note depending on the movement
        String newInput = detect_user_behaviour();
		//if the note is not equal to the previous one
        if(!newInput.equals(lastNote)) {
            relevatedCount = 0;
			//make the last note be the new note
            lastNote = newInput;
            println("count set to 0..");
            isMovingMan = true;
        }
		//if the counter reaches 23 and the user is moving
        else if(relevatedCount == 23 && isMovingMan) {
            relevatedCount = 0;
            println("count set to 0.. added note "+newInput);
            isMovingMan = false;
			//play the note
            playNotes(newInput);
        }
		//if the user is moving
        else if(isMovingMan) {
			//increase the counter
            relevatedCount++;
            println("count++ "+relevatedCount);
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

/*
	Function which checks the movement of the skeleton
	and returns the corrispective note
*/

String detect_user_behaviour() {
	if(confidenceLH > 0.5) {
		if (leftHand.y > leftShoulder.y) {
            return "G5";
		}
        else if (rightHand.y > rightShoulder.y) {
            return "B3";
        }
	}
	return "C4";
}

//Function that reproduces the note passed as argument.
void playNotes(String note) {
	out.playNote(note);
}
