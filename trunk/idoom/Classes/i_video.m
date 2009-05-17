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
//	DOOM graphics stuff for the iPhone.
//
//-----------------------------------------------------------------------------

#import "iDoomAppDelegate.h"
#import "Texture2D.h"
#import "iDoomView.h"

#include "doomstat.h"
#include "i_system.h"
#include "v_video.h"
#include "m_argv.h"
#include "d_main.h"

#include "doomdef.h"

short* currentPalette;
int* screenBuffer;
int screenBufferWidth;
int screenBufferHeight;
CGRect _viewRect;
GLfloat	_coordinates[8];
GLfloat	_vertices[12];
GLuint _name;

iDoomView* _view;
Texture2D* gameControlsTexture = nil;
Texture2D* menuControlsTexture = nil;

void I_ShutdownGraphics(void)
{
	// Delete the game texture
	if(_name) {
		glDeleteTextures(1, &_name);
		_name = 0;
	}
	
	if (gameControlsTexture) {
		[gameControlsTexture release];
		gameControlsTexture = nil;
	}
	
	if (menuControlsTexture) {
		[menuControlsTexture release];
		menuControlsTexture = nil;
	}
	
	free(screens[0]);
}

//
// I_StartFrame
//
void I_StartFrame (void)
{

}

void I_GetEvent(void)
{

}

//
// I_StartTic
//
void I_StartTic (void)
{

}

//
// I_UpdateNoBlit
//
void I_UpdateNoBlit (void)
{

}

//
// I_FinishUpdate
//
void I_FinishUpdate (void)
{
	// Copy and convert the video screen into the texture buffer
	int scanLineLen = screenBufferWidth - SCREENWIDTH;
	
	short* dest = (short*)screenBuffer;	
	byte* source = screens[0];
	
	for (int row = 0; row < SCREENHEIGHT; row++) {
		for (int col = 0; col < SCREENWIDTH; col++) {
			*dest++ = currentPalette[*source++];
		}
		dest += scanLineLen;
	}

	// Regenerate the game texture
	glBindTexture(GL_TEXTURE_2D, _name);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, screenBufferWidth, screenBufferHeight, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, screenBuffer);
	
	// Draw the game texture
	glVertexPointer(3, GL_FLOAT, 0, _vertices);
	glTexCoordPointer(2, GL_FLOAT, 0, _coordinates);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Draw the alpha blended game controls overlay
	if ((gamestate == GS_LEVEL) && (!demoplayback) && (!menuactive)) {
		glEnable(GL_BLEND);
		[gameControlsTexture drawInRect:_viewRect];
		glDisable(GL_BLEND);
	} else if (menuactive) {
		glEnable(GL_BLEND);
		[menuControlsTexture drawInRect:_viewRect];
		glDisable(GL_BLEND);
	}
	
	// Present to the screen
	[_view swapBuffers];
}

//
// I_ReadScreen
//
void I_ReadScreen (byte* scr)
{
    memcpy (scr, screens[0], SCREENWIDTH * SCREENHEIGHT);
}

//
// I_SetPalette
//
void I_SetPalette (byte* palette)
{
	short* p = (short*)currentPalette;
	for (int i = 0; i < 256; ++i )
	{
		// Convert "RRRRRRRRRGGGGGGGGBBBBBBBBAAAAAAAA" to "RRRRRGGGGGGBBBBB"
		// This halves the memory bandwidth needed to generate the textures and
		// provides some performance speedup.  The lower quality of the colors
		// is unnoticable on the iPhone display.
		int red = gammatable[usegamma][*(palette++)];
		int green = gammatable[usegamma][*(palette++)];
		int blue = gammatable[usegamma][*(palette++)];
		
		*p++ =  (((((red) & 0xFF) >> 3) << 11) |
				 ((((green) & 0xFF) >> 2) << 5) |
				 ((((blue) & 0xFF) >> 3) << 0));
	}
}

void I_InitGraphics()
{
	_view = ((iDoomAppDelegate*)  [UIApplication sharedApplication].delegate)->view;
	
	CGRect rect = [[UIScreen mainScreen] bounds];	
	
	// Set up OpenGL projection matrix
	glMatrixMode(GL_PROJECTION);
	glRotatef(-90, 0, 0, 1);
	glOrthof(0, rect.size.width, 0, rect.size.height, -1, 1);
	glMatrixMode(GL_MODELVIEW);
	
	// Initialize OpenGL states
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_TEXTURE_2D);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisable(GL_BLEND);
	
	// Pre-calc everything we need for the game texture
	glGenTextures(1, &_name);

	// The width and height of the screen buffer texture image must be a power of 2
	// so find the next largest power of 2 we can use to draw the image in
	NSUInteger i;
	BOOL sizeToFit = NO;
	
	screenBufferWidth = SCREENWIDTH;
	if((screenBufferWidth != 1) && (screenBufferWidth & (screenBufferWidth - 1))) {
		i = 1;
		while((sizeToFit ? 2 * i : i) < screenBufferWidth)
			i *= 2;
		screenBufferWidth = i;
	}
	
	screenBufferHeight = SCREENHEIGHT;
	if((screenBufferHeight != 1) && (screenBufferHeight & (screenBufferHeight - 1))) {
		i = 1;
		while((sizeToFit ? 2 * i : i) < screenBufferHeight)
			i *= 2;
		screenBufferHeight = i;
	}
	
	float maxS = SCREENWIDTH / (float)screenBufferWidth;
	float maxT = SCREENHEIGHT / (float)screenBufferHeight;
	
	_viewRect = [_view bounds];
	
	_coordinates[0] = 0;
	_coordinates[1] = maxT;
	_coordinates[2] = maxS;
	_coordinates[3] = maxT;
	_coordinates[4] = 0;
	_coordinates[5] = 0;
	_coordinates[6] = maxS;
	_coordinates[7] = 0;
	
	_vertices[0] = _viewRect.origin.x;
	_vertices[1] = _viewRect.origin.y;
	_vertices[2] = 0.0;
	_vertices[3] = _viewRect.origin.x + _viewRect.size.width;
	_vertices[4] = _viewRect.origin.y;
	_vertices[5] = 0.0;
	
	_vertices[6] = _viewRect.origin.x;
	_vertices[7] = _viewRect.origin.y + _viewRect.size.height;
	_vertices[8] = 0.0;
	
	_vertices[9] = _viewRect.origin.x + _viewRect.size.width;
	_vertices[10] = _viewRect.origin.y + _viewRect.size.height;
	_vertices[11] = 0.0;
	
	// Allocate memory for the RGB 565 version of the image data
	screenBuffer = malloc(screenBufferWidth * screenBufferHeight * sizeof(short));
	
	// Load the controls overlay
	UIImage* image = [UIImage imageNamed:@"GameControls.png"];
	gameControlsTexture = [[Texture2D alloc]initWithImage:image];
	[image release];

	image = [UIImage imageNamed:@"MenuControls.png"];
	menuControlsTexture = [[Texture2D alloc]initWithImage:image];
	[image release];

	// This is the screen memory
	currentPalette = malloc(265 * 4);
	screens[0] = (unsigned char *) malloc (SCREENWIDTH * SCREENHEIGHT);
}

