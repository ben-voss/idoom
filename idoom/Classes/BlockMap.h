//
//  BlockMap.h
//  iDoom
//
//  Created by Ben on 2/11/2008.
//  Copyright 2008 RBS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DoomType.h"
#import "WadFile.h"
#import "FixedPointMath.h"

@interface BlockMap : NSObject {
	fixed_t x;
	fixed_t y;
	int width;
	int height;
	
	short* blockMapLump;
	short* blockMap;
	byte** blockLinks;
}

-(id)initWithLump:(int)lumpNum wadFile:(WadFile*)wadFile;

@end
