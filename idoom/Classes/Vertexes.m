//
//  Vertexes.m
//  iDoom
//
//  Created by Ben on 2/11/2008.
//  Copyright 2008 RBS. All rights reserved.
//

#import "Vertexes.h"

@implementation Vertexes

-(id)initWithLump:(int)lumpNum wadFile:(WadFile*)wadFile {
	if((self = [super init])) {

		// Determine number of lumps:
		//  total lump length / vertex record length.
		int numVertexes = [wadFile getLumpLength:lumpNum] / sizeof(mapvertex_t);
		
		// Allocate zone memory for buffer.
		vertexes = malloc (numVertexes * sizeof(vertex_t));	
		
		// Load data into cache.
		mapvertex_t* mapVertex = (mapvertex_t*)[wadFile getLump:lumpNum];
		
		vertex_t* li = vertexes;
		
		// Copy and convert vertex coordinates,
		// internal representation as fixed.
		for (int i = 0; i < numVertexes ; i++, li++, mapVertex++)
		{
			li->x = mapVertex->x << FRACBITS;
			li->y = mapVertex->y << FRACBITS;
		}
	}
	
	return self;
}

-(void)dealloc {
	free(vertexes);
	vertexes = nil;
	
	[super dealloc];
}

@end
