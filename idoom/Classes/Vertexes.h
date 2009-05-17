//
//  Vertexes.h
//  iDoom
//
//  Created by Ben on 2/11/2008.
//  Copyright 2008 RBS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WadFile.h"
#import "FixedPointMath.h"

//
// Your plain vanilla vertex.
// Note: transformed values not buffered locally,
//  like some DOOM-alikes ("wt", "WebView") did.
//
typedef struct {
	fixed_t	x;
	fixed_t	y;
} vertex_t;

@interface Vertexes : NSObject {
	vertex_t* vertexes;
}

-(id)initWithLump:(int)lumpNum wadFile:(WadFile*)wadFile;

@end
