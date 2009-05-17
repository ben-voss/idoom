/*
 *  FixedPointMath.h
 *  iDoom
 *
 *  Created by Ben on 2/11/2008.
 *  Copyright 2008 RBS. All rights reserved.
 *
 */

#ifndef __M_FIXED__
#define __M_FIXED__

//
// Fixed point, 32bit as 16.16.
//
#define FRACBITS		16
#define FRACUNIT		(1<<FRACBITS)

typedef int fixed_t;

fixed_t FixedMul	(fixed_t a, fixed_t b);
fixed_t FixedDiv	(fixed_t a, fixed_t b);
fixed_t FixedDiv2	(fixed_t a, fixed_t b);

#endif