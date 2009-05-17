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
//	Open GL View and touch handling
//
//-----------------------------------------------------------------------------


#import <QuartzCore/QuartzCore.h>
#import "iDoomView.h"
#import "iDoomAppDelegate.h"
#import "d_main.h"
#import "d_event.h"
#import "doomdata.h"
#import "doomstat.h"
#import "st_stuff.h"

#define DEVICEWIDTH  480
#define DEVICEHEIGHT 320

@implementation iDoomView

boolean menuWasNotActive;

@synthesize delegate=_delegate, autoresizesSurface=_autoresize, surfaceSize=_size, framebuffer = _framebuffer, pixelFormat = _format, context = _context;

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (BOOL) _createSurface
{
	CAEAGLLayer*			eaglLayer = (CAEAGLLayer*)[self layer];
	CGSize					newSize;
	GLuint					oldRenderbuffer;
	GLuint					oldFramebuffer;
	
	if(![EAGLContext setCurrentContext:_context]) {
		return NO;
	}
	
	newSize = [eaglLayer bounds].size;
	newSize.width = roundf(newSize.width);
	newSize.height = roundf(newSize.height);
	
	glGetIntegerv(GL_RENDERBUFFER_BINDING_OES, (GLint *) &oldRenderbuffer);
	glGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, (GLint *) &oldFramebuffer);
	
	glGenRenderbuffersOES(1, &_renderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderbuffer);
	
	if(![_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:eaglLayer]) {
		glDeleteRenderbuffersOES(1, &_renderbuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_BINDING_OES, oldRenderbuffer);
		return NO;
	}
	
	glGenFramebuffersOES(1, &_framebuffer);
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _renderbuffer);
	
	_size = newSize;
	if(!_hasBeenCurrent) {
		glViewport(0, 0, newSize.width, newSize.height);
		glScissor(0, 0, newSize.width, newSize.height);
		_hasBeenCurrent = YES;
	}
	else {
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, oldFramebuffer);
	}
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, oldRenderbuffer);

	[_delegate didResizeEAGLSurfaceForView:self];
	
	return YES;
}

- (void) _destroySurface
{
	EAGLContext *oldContext = [EAGLContext currentContext];
	
	if (oldContext != _context)
		[EAGLContext setCurrentContext:_context];
	
	glDeleteRenderbuffersOES(1, &_renderbuffer);
	_renderbuffer = 0;
	
	glDeleteFramebuffersOES(1, &_framebuffer);
	_framebuffer = 0;
	
	if (oldContext != _context)
		[EAGLContext setCurrentContext:oldContext];
}

//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder {
	
	if ((self = [super initWithCoder:coder])) {
		CAEAGLLayer *eaglLayer = (CAEAGLLayer*)[self layer];
		
		[eaglLayer setDrawableProperties:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGB565, kEAGLDrawablePropertyColorFormat, nil]];
		_format = kEAGLColorFormatRGB565;
		
		_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		if(_context == nil) {
			[self release];
			return nil;
		}
		
		if(![self _createSurface]) {
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (void)dealloc {
	[self _destroySurface];
	
	[_context release];
	_context = nil;
	
	[super dealloc];
}

- (void) layoutSubviews
{
	CGRect				bounds = [self bounds];
	
	if(_autoresize && ((roundf(bounds.size.width) != _size.width) || (roundf(bounds.size.height) != _size.height))) {
		[self _destroySurface];
#if __DEBUG__
		REPORT_ERROR(@"Resizing surface from %fx%f to %fx%f", _size.width, _size.height, roundf(bounds.size.width), roundf(bounds.size.height));
#endif
		[self _createSurface];
	}
}

- (void) setAutoresizesEAGLSurface:(BOOL)autoresizesEAGLSurface;
{
	_autoresize = autoresizesEAGLSurface;
	if(_autoresize)
		[self layoutSubviews];
}

- (void) setCurrentContext
{
	if(![EAGLContext setCurrentContext:_context]) {
		printf("Failed to set current context %p in %s\n", _context, __FUNCTION__);
	}
}

- (BOOL) isCurrentContext
{
	return ([EAGLContext currentContext] == _context ? YES : NO);
}

- (void) clearCurrentContext
{
	if(![EAGLContext setCurrentContext:nil])
		printf("Failed to clear current context in %s\n", __FUNCTION__);
}

- (void) swapBuffers
{
	EAGLContext *oldContext = [EAGLContext currentContext];
	GLuint oldRenderbuffer;
	
	if(oldContext != _context)
		[EAGLContext setCurrentContext:_context];
	
	glGetIntegerv(GL_RENDERBUFFER_BINDING_OES, (GLint *) &oldRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderbuffer);
	
	if(![_context presentRenderbuffer:GL_RENDERBUFFER_OES])
		printf("Failed to swap renderbuffer in %s\n", __FUNCTION__);
	
	if(oldContext != _context)
		[EAGLContext setCurrentContext:oldContext];
}

- (CGPoint) convertPointFromViewToSurface:(CGPoint)point
{
	CGRect				bounds = [self bounds];
	
	return CGPointMake((point.x - bounds.origin.x) / bounds.size.width * _size.width, (point.y - bounds.origin.y) / bounds.size.height * _size.height);
}

- (CGRect) convertRectFromViewToSurface:(CGRect)rect
{
	CGRect				bounds = [self bounds];
	
	return CGRectMake((rect.origin.x - bounds.origin.x) / bounds.size.width * _size.width, (rect.origin.y - bounds.origin.y) / bounds.size.height * _size.height, rect.size.width / bounds.size.width * _size.width, rect.size.height / bounds.size.height * _size.height);
}

- (void) ProcessTouch:(event_t*) event3:(CGPoint)endTouchPosition {
	if ((gamestate == GS_LEVEL) && (!demoplayback) && (!menuactive)) {
		// controls:
		// Map					Menu
		// Speed				
		// Use 					Fire
		// Strafe Right			Strafe Left
		if (startTouchPosition.y < 50) {
			// Left side
			if (startTouchPosition.x > DEVICEHEIGHT - 50) {
				event3->data1 = KEY_TAB;
				D_PostEvent(event3);		
			} else if (startTouchPosition.x > DEVICEHEIGHT - 100) {
				player_t *plyr = ST_GetPlayer();
				
				for (int i = plyr->readyweapon - 1; i >= 0; i--)
				{
					if (plyr->weaponowned[i]) {
						event3->data1 = '1' + i;
						D_PostEvent(event3);
						break;
					}
				}
			} else if (startTouchPosition.x > DEVICEHEIGHT - 150) {
				event3->data1 = ' ';
				D_PostEvent(event3);		
			} else if (startTouchPosition.x > DEVICEHEIGHT - 200) {
				event3->data1 = ',';
				D_PostEvent(event3);		
			}
		} else if (startTouchPosition.y > DEVICEWIDTH - 50) {
			// Right Side
			if (startTouchPosition.x > DEVICEHEIGHT -  50) {
				menuWasNotActive = true;
				event3->data1 = KEY_ESCAPE;
				D_PostEvent(event3);		
			} else if (startTouchPosition.x > DEVICEHEIGHT -  100) {
				player_t *plyr = ST_GetPlayer();

				for (int i = plyr->readyweapon + 1; i < NUMWEAPONS; i++)
				{
					if (plyr->weaponowned[i]) {
						event3->data1 = '1' + i;
						D_PostEvent(event3);
						break;
					}
				}
			} else if (startTouchPosition.x > DEVICEHEIGHT -  150) {
				event3->data1 = KEY_RCTRL;
				D_PostEvent(event3);		
			} else if (startTouchPosition.x > DEVICEHEIGHT -  200) {
				event3->data1 = '.';
				D_PostEvent(event3);		
			}			
		}
	} else if ((gamestate == GS_INTERMISSION) || (gamestate == GS_FINALE)) {
		// Allow any tap to cause the intermission screen to advance to start the next level
		event3->data1 = KEY_RCTRL;
		D_PostEvent(event3);
	} else if (!menuactive) {
		// Menu activation
		menuWasNotActive = true;
		event3->data1 = KEY_ENTER;
		D_PostEvent(event3);
	} else if ((menuactive) && (event3->type == ev_keyup)) {
		// Dont handle the first key up event after we swiched the menu on or it will
		// cause us to choose the first menu option
		if (menuWasNotActive)
		{
			menuWasNotActive = false;
			return;
		}		
		
		if ((abs(startTouchPosition.x - endTouchPosition.x) <= 10) &&
			(abs(startTouchPosition.y - endTouchPosition.y) <= 10)) {
			event3->type = ev_keydown;

			if ((startTouchPosition.y > DEVICEWIDTH - 50) && (startTouchPosition.x > DEVICEHEIGHT -  50)) {
				event3->data1 = KEY_ESCAPE;
			} else {
				// Menu selection
				event3->data1 = KEY_ENTER;
			}
		
			D_PostEvent(event3);
		}
	}
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {	
	UITouch *touch = [touches anyObject];
	CGPoint endTouchPosition = [touch locationInView:self];

	event_t keyEvent;
	keyEvent.type = ev_keyup;
	
	[self ProcessTouch:&keyEvent:endTouchPosition];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	startTouchPosition = [touch locationInView:self];
	lastTouchPosition = startTouchPosition;
	
	event_t keyEvent;	
	keyEvent.type = ev_keydown;

	[self ProcessTouch:&keyEvent:startTouchPosition];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (menuactive) {
		UITouch *touch = touches.anyObject;
		CGPoint currentTouchPosition = [touch locationInView:self];
		
		event_t mouseEvent;
		mouseEvent.type = ev_mouse;
		mouseEvent.data1 = 0;
		mouseEvent.data2 = (currentTouchPosition.y - lastTouchPosition.y) / 2;
		mouseEvent.data3 = (currentTouchPosition.x - lastTouchPosition.x) / 2;
		
		D_PostEvent(&mouseEvent);
		
		lastTouchPosition = currentTouchPosition;
	}
}

@end
