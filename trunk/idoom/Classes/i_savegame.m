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
//	DOOM game saving for the iPhone.
//
//-----------------------------------------------------------------------------

#include <fcntl.h>
#import "i_savegame.h"

int I_OpenFile(char const* name, int flags, int permissions) {
	// Prepend the iPhone app document data root
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString* fileName = [[NSString alloc] initWithUTF8String:name];

    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];

	const char* c = [appFile UTF8String];
	
	int handle = open (c, flags, permissions);
	
	[fileName release];
	
	return handle;
}