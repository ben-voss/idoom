//
//  BlockMap.m
//  iDoom
//
//  Created by Ben on 2/11/2008.
//  Copyright 2008 RBS. All rights reserved.
//

#import "BlockMap.h"
#import "FixedPointMath.h"

@implementation BlockMap

-(id)initWithLump:(int)lumpNum wadFile:(WadFile*)wadFile {
	
	if((self = [super init])) {
		blockMapLump = (short*) [wadFile getLump:lumpNum];
	
		blockMap = blockMapLump + 4;

		// Read the header
		x = blockMapLump[0] << FRACBITS;
		y = blockMapLump[1] << FRACBITS;
		width = blockMapLump[2];
		height = blockMapLump[3];
	
		// clear out mobj chains
		int count = sizeof(*blockLinks) * width * height;
		blockLinks = malloc (count);
		memset (blockLinks, 0, count);
	}
	
	return self;
}

-(void)dealloc {
	free(blockLinks);
	blockLinks = nil;
	
	[super dealloc];
}

@end
