//
//  Sectors.m
//  iDoom
//
//  Created by Ben on 2/11/2008.
//  Copyright 2008 RBS. All rights reserved.
//

#import "Sectors.h"


@implementation Sectors

- (id) initWithLump:(int)lumpNum wadFile:(WadFile*)wadFile {
	
	if((self = [super init])) {		
		int numSectors = [wadFile getLumpLength:lumpNum] / sizeof(mapsector_t);
		sectors = malloc (numSectors * sizeof(sector_t));	
		memset (sectors, 0, numSectors * sizeof(sector_t));
		mapsector_t* mapSectors = (mapsector_t*)[wadFile getLump:lumpNum];
		
		sector_t* ss = sectors;
		for (int i = 0; i < numSectors; i++, ss++, mapSectors++)
		{
			ss->floorHeight = mapSectors->floorHeight << FRACBITS;
			ss->ceilingHeight = mapSectors->ceilingHeight << FRACBITS;
			ss->floorPic = R_FlatNumForName(mapSectors->floorPic);
			ss->ceilingPic = R_FlatNumForName(mapSectors->ceilingPic);
			ss->lightLevel = mapSectors->lightLevel;
			ss->special = mapSectors->special;
			ss->tag = mapSectors->tag;
			ss->thingList = NULL;
		}
	}
	
	return self;
}

-(void)dealloc {
	//free(vertexes);
	//vertexes = nil;
	
	[super dealloc];
}

@end
