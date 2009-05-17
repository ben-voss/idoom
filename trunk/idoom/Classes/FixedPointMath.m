/*
 *  FixedPointMath.c
 *  iDoom
 *
 *  Created by Ben on 2/11/2008.
 *  Copyright 2008 RBS. All rights reserved.
 *
 */

#include "FixedPointMath.h"

#include "stdlib.h"

#include "DoomType.h"

fixed_t FixedMul (fixed_t a, fixed_t	b)
{
    return ((long long) a * (long long) b) >> FRACBITS;
}

//
// FixedDiv, C version.
//
fixed_t FixedDiv (fixed_t a, fixed_t b) {
	if ((abs(a) >> 14) >= abs(b))
		return (a ^ b) < 0 ? MININT : MAXINT;
	
    return FixedDiv2 (a, b);
}

fixed_t FixedDiv2 (fixed_t a, fixed_t b) {
	double c;
	
    c = ((double)a) / ((double)b) * FRACUNIT;
	
    if (c >= 2147483648.0 || c < -2147483648.0)
		@throw [NSException exceptionWithName:NSGenericException
									   reason:@"Attempt to divide by zero"
									 userInfo:nil];	

	return (fixed_t) c;
}