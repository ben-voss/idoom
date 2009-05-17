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
//	Open GL View
//
//-----------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
 #import <OpenGLES/EAGLDrawable.h>
 #import <OpenGLES/ES1/gl.h>
 #import <OpenGLES/ES1/glext.h>
#import "d_event.h"

@class iDoomView;

@protocol MyEAGLViewDelegate <NSObject>
 - (void) didResizeEAGLSurfaceForView:(iDoomView*)view; //Called whenever the EAGL surface has been resized
 @end

@interface iDoomView : UIView {
	
	 @private
	 NSString*				_format;
	 BOOL					_autoresize;
	 EAGLContext				*_context;
	 GLuint					_framebuffer;
	 GLuint					_renderbuffer;
	 CGSize					_size;
	 BOOL					_hasBeenCurrent;
	 id<MyEAGLViewDelegate>	_delegate;
	
	CGPoint startTouchPosition;
	CGPoint lastTouchPosition;
}
- (id)initWithCoder:(NSCoder*)coder; 

 @property(readonly) GLuint framebuffer;
 @property(readonly) NSString* pixelFormat;
 @property(readonly) EAGLContext *context;
 
 @property BOOL autoresizesSurface; //NO by default - Set to YES to have the EAGL surface automatically resized when the view bounds change, otherwise the EAGL surface contents is rendered scaled
 @property(readonly, nonatomic) CGSize surfaceSize;
 
 @property(assign) id<MyEAGLViewDelegate> delegate;
 
 - (void) setCurrentContext;
 - (BOOL) isCurrentContext;
 - (void) clearCurrentContext;
 
 - (void) swapBuffers; //This also checks the current OpenGL error and logs an error if needed
 
 - (CGPoint) convertPointFromViewToSurface:(CGPoint)point;
 - (CGRect) convertRectFromViewToSurface:(CGRect)rect;
-(void) ProcessTouch:(event_t*)event:(CGPoint)endTouchPosition;
@end
