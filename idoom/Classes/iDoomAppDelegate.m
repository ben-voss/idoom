// Emacs style mode select   -*- C++ -*- 
//-----------------------------------------------------------------------------
//
// Copyright (C) 2009 by Ben Powderhill
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// DESCRIPTION:
//	App delegate & accelerometer handling
//
//-----------------------------------------------------------------------------

#import "iDoomAppDelegate.h"
#import "iDoomViewController.h"
#import "iDoomView.h"
#import "Texture2D.h"
#import "d_main.h"
#import "i_video.h"
#import "d_event.h"
#import "doomdata.h"
#import "doomstat.h"

#define kRenderingFPS				15.0 // Hz

@implementation iDoomAppDelegate

- init {
	if (self = [super init]) {
		// Set the accelerometer to update at the same frequency as the frame rate and to send the updates
		// to this app delegate		
		[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / (kRenderingFPS))];
		[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	}
	return self;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {

	// Turn off the idle timer so the screen is not dimmed or turned off
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
	// Initialise the game
	D_DoomMain();

	// Start the rendering timer
	_timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / kRenderingFPS) target:self selector:@selector(renderScene) userInfo:nil repeats:YES];
}

// Renders one scene of the game
- (void)renderScene {
	D_DoomLoopStep();
}

- (void)dealloc {
	// Unlink the accelerometer delegate
	[[UIAccelerometer sharedAccelerometer] setDelegate:nil];

	// Release the view
    [view release];
	[window release];
	[super dealloc];
}

// UIAccelerometer delegate method, which delivers the latest acceleration data.
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	double newTimestamp = acceleration.timestamp;
	
	if (!menuactive) {
		// Offset the x coordinate to allow the game to be played with the device at an angle
		UIAccelerationValue ax = acceleration.x + 0.6;
		UIAccelerationValue ay = acceleration.y;
	
		// Create a 'dead zone' in the middle so if the device is near the centre point the player will stand still
		double d = 0.05;
	
		if ((ax < d) && (ax > -d))
			ax = 0;
	
		if ((ay < d) && (ay > -d))
			ay = 0;

		// Post a mouse move event
		event_t mouseEvent;
		mouseEvent.type = ev_mouse;
		mouseEvent.data1 = 0;
		mouseEvent.data2 = -ay * ((newTimestamp - lastAccelerometerTimestamp) * 10000);
		mouseEvent.data3 =  ax * ((newTimestamp - lastAccelerometerTimestamp) * 8000);
	
		D_PostEvent(&mouseEvent);
	}
	
	lastAccelerometerTimestamp = newTimestamp;
}

@end
