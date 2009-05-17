//
//  Sectors.h
//  iDoom
//
//  Created by Ben on 2/11/2008.
//  Copyright 2008 RBS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WadFile.h"
#import "FixedPointMath.h"

//
// The SECTORS record, at runtime.
// Stores things/mobjs.
//
typedef	struct {
	fixed_t	floorHeight;
	fixed_t	ceilingHeight;
	short	floorPic;
	short	ceilingPic;
	short	lightLevel;
	short	special;
	short	tag;
	
	// 0 = untraversed, 1,2 = sndlines -1
	int		soundTraversed;
		
	// thing that made a sound (or null)
	int*	soundTarget;
		
	// mapblock bounding box for height changes
	int		blockBox[4];
		
	// origin for any sounds played by the sector
	int	soundOrg;
		
	// if == validcount, already checked
	int		validCount;
		
	// list of mobjs in sector
	int*	thingList;
		
	// thinker_t for reversable actions
	void*	specialData;
		
	int			lineCount;
	//struct int**	lines;	// [linecount] size
} sector_t;


@interface Sectors : NSObject {
	sector_t* sectors;
}

- (id) initWithLump:(int)lumpNum wadFile:(WadFile*)wadFile;

@end
