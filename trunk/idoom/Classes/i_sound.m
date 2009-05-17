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
//	DOOM sound for the iPhone.
//
//-----------------------------------------------------------------------------

#include "doomdef.h"
#include "z_zone.h"
#include "i_system.h"
#import "i_sound.h"
#include "m_argv.h"
#include "m_misc.h"
#include "w_wad.h"

#import <UIKit/UIKit.h>
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#import <AudioToolbox/AudioToolbox.h>

typedef struct sourceEntry sourceEntry_t;

struct sourceEntry {
	ALuint sourceID;
	sourceEntry_t* next;
};

static ALCdevice* _device;
static ALCcontext* _context;
static sourceEntry_t* _sourceEntries;

#define AssertNoOALError(inMessage)					\
if ((result = alGetError()) != AL_NO_ERROR)			\
{													\
printf(inMessage, result);									\
}

typedef ALvoid	AL_APIENTRY	(*alBufferDataStaticProcPtr) (const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq);
ALvoid  alBufferDataStaticProc(const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq)
{
	static	alBufferDataStaticProcPtr	proc = NULL;
    
    if (proc == NULL) {
        proc = (alBufferDataStaticProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alBufferDataStatic");
    }
    
    if (proc)
        proc(bid, format, data, size, freq);
	
    return;
}

static int i = 0;

//
// Starting a sound means adding it
//  to the current list of active sounds
//  in the internal channels.
// As the SFX info struct contains
//  e.g. a pointer to the raw data,
//  it is ignored.
// As our sound handling does not handle
//  priority, it is ignored.
// Pitching (that is, increased speed of playback)
//  is set, but currently not used by mixing.
//
int
I_StartSound
( int		id,
  int		vol,
  int		sep,
  int		pitch,
  int		priority )
{
	// Get the sound effect info
	sfxinfo_t* sfx = &S_sfx[id];
	
	if (sfx->data == 0) {	
		soundLumpHeader_t* sample = (soundLumpHeader_t*)W_CacheLumpNum(sfx->lumpnum, PU_STATIC );

		sfx->data = (short*)malloc((sample->sampleCount) * sizeof(short));

		// Convert the sample into 16 bit (8 bit doesnt quite play properly because of a 'click' sound at the
		// end of samples
		short* d = sfx->data;
		for (int i = 0; i < sample->sampleCount; i++) {
			*d++ = (((short)sample->samples[i]) - 128) * 128;
		}

		// Generate a buffer and copy the data into it
		alGenBuffers(1, &sfx->bufferID);
	
		alBufferDataStaticProc(sfx->bufferID, AL_FORMAT_MONO16, sfx->data, sample->sampleCount * sizeof(short), sample->sampleFrequency);
	}
	
	// Create a source on the buffer and play it
	sourceEntry_t* sourceEntry = (sourceEntry_t*)malloc(sizeof(sourceEntry_t));
	alGenSources(1, &sourceEntry->sourceID);

	
	
	
	// Set Source Position
	float sourcePosAL[] = {0, -70, 25};
	alSourcefv(sourceEntry->sourceID, AL_POSITION, sourcePosAL);
	
	// Set Source Reference Distance
	alSourcef(sourceEntry->sourceID, AL_REFERENCE_DISTANCE, 50.0f);
	
	
	
	alSourcei(sourceEntry->sourceID, AL_BUFFER, sfx->bufferID);
	
	alSourcePlay(sourceEntry->sourceID);
	
	sourceEntry->next = _sourceEntries;
	_sourceEntries = sourceEntry;
	
	return sourceEntry->sourceID;
}

void I_StopSound (int handle)
{
	ALuint sourceId = (ALuint)handle;
	
	alSourceStop(sourceId);
	
	alDeleteSources(1, &sourceId);
	
	// Remove the source from the list of active sources
	sourceEntry_t* sourceEntry = _sourceEntries;
	sourceEntry_t* prevSourceEntry = NULL;
	while (sourceEntry != NULL) {
		if (sourceEntry->sourceID == sourceId) {
			if (prevSourceEntry == NULL)
				_sourceEntries = sourceEntry->next;
			else
				prevSourceEntry->next = sourceEntry->next;
			
			free(sourceEntry);
			
			return;
		} else {
			prevSourceEntry = sourceEntry;
			sourceEntry = sourceEntry->next;
		}
	}
}


int I_SoundIsPlaying(int handle)
{
	ALenum status;
	alGetSourcei(handle, AL_SOURCE_STATE, &status);

	return status == AL_PLAYING;
}

//
// This function loops all active (internal) sound
//  channels, retrieves a given number of samples
//  from the raw sound data, modifies it according
//  to the current (internal) channel parameters,
//  mixes the per channel samples into the global
//  mixbuffer, clamping it to the allowed range,
//  and sets up everything for transferring the
//  contents of the mixbuffer to the (two)
//  hardware channels (left and right, that is).
//
// This function currently supports only 16bit.
//
void I_UpdateSound( void )
{
	i++;
	
	sourceEntry_t* sourceEntry = _sourceEntries;
	sourceEntry_t* prevSourceEntry = NULL;
	while (sourceEntry != NULL) {
		if (!I_SoundIsPlaying(sourceEntry->sourceID)) {
			if (prevSourceEntry == NULL)
				_sourceEntries = sourceEntry->next;
			else
				prevSourceEntry->next = sourceEntry->next;
			
			sourceEntry_t* s = sourceEntry;
			sourceEntry = sourceEntry->next;
			
			alSourceStop(s->sourceID);

			alDeleteSources(1, &s->sourceID);
						
			free(s);
		} else {
			prevSourceEntry = sourceEntry;
			sourceEntry = sourceEntry->next;
		}
	}
}


// 
// This would be used to write out the mixbuffer
//  during each game loop update.
// Updates sound buffer and audio device at runtime. 
// It is called during Timer interrupt with SNDINTR.
// Mixing now done synchronous, and
//  only output be done asynchronous?
//
void
I_SubmitSound(void)
{

}

void I_ShutdownSound(void)
{    
	sourceEntry_t* sourceEntry = _sourceEntries;
	while (sourceEntry != NULL) {
	}
	
	
	alcMakeContextCurrent(NULL);
	
	if (_context)
		alcDestroyContext(_context);
	
	if (_device)
		alcCloseDevice(_device);
}

void
I_InitSound()
{
	_sourceEntries = NULL;
	
	// Setup our audio session
	OSStatus result = AudioSessionInitialize(NULL, NULL, NULL, NULL);
	if (result) printf("Error initializing audio session! %d\n", result);
	else {
		UInt32 category = kAudioSessionCategory_AmbientSound;
		result = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
		if (result) printf("Error setting audio session category! %d\n", result);
		else {
			result = AudioSessionSetActive(true);
			if (result) printf("Error setting audio session active! %d\n", result);
		}
	}
	
	// Create the OpenAL output device
	_device = alcOpenDevice(NULL);
	AssertNoOALError("Error %x opening output device")
	
	if (_device == NULL)
		I_Error("No Sound Engine");
	
	// Create an OpenAL Context and make it current
	_context = alcCreateContext(_device, NULL);
	AssertNoOALError("Error %x creating OpenAL context")
	
	alcMakeContextCurrent(_context);
	AssertNoOALError("Error %x setting current OpenAL context")
	
	for (int id = 1; id < NUMSFX; id++) {
		sfxinfo_t* sfx = &S_sfx[id];
		
		char namebuf[9];
		sprintf(namebuf, "ds%s", sfx->name);
		sfx->lumpnum = W_CheckNumForName(namebuf);

		if (sfx->lumpnum > 0) {
			soundLumpHeader_t* sample = (soundLumpHeader_t*)W_CacheLumpNum(sfx->lumpnum, PU_STATIC );
		
			sfx->data = (short*)malloc((sample->sampleCount) * sizeof(short));
		
			// Convert the sample into 16 bit (8 bit doesnt quite play properly because of a 'click' sound at the
			// end of samples
			short* d = sfx->data;
			for (int i = 0; i < sample->sampleCount; i++) {
				*d++ = (((short)sample->samples[i]) - 128) * 128;
			}
		
			// Generate a buffer and copy the data into it
			alGenBuffers(1, &sfx->bufferID);
			AssertNoOALError("Error %x generating buffer\n");

			alBufferDataStaticProc(sfx->bufferID, AL_FORMAT_MONO16, sfx->data, sample->sampleCount * sizeof(short), sample->sampleFrequency);
			AssertNoOALError("Error %x attaching data to buffer\n");
		}
	}
	
	float listenerPosAL[] = {0, 0, 0.};
	// Move our listener coordinates
	alListenerfv(AL_POSITION, listenerPosAL);
	
	float ori[] = {cos(0 + M_PI_2), sin(0 + M_PI_2), 0., 0., 0., 1.};
	// Set our listener orientation (rotation)
	alListenerfv(AL_ORIENTATION, ori);
}

//
// SFX API
// Note: this was called by S_Init.
// However, whatever they did in the
// old DPMS based DOS version, this
// were simply dummies in the Linux
// version.
// See soundserver initdata().
//
void I_SetChannels()
{
	
}

void I_SetSfxVolume(int volume)
{
	// Identical to DOS.
	// Basically, this should propagate
	//  the menu/config file setting
	//  to the state variable used in
	//  the mixing.
	snd_SfxVolume = volume;
}

// MUSIC API - dummy. Some code from DOS version.
void I_SetMusicVolume(int volume)
{
	// Internal state variable.
	snd_MusicVolume = volume;
	// Now set volume on output device.
	// Whatever( snd_MusciVolume );
}

void
I_UpdateSoundParams
( int	handle,
 int	vol,
 int	sep,
 int	pitch)
{
	// I fail too see that this is used.
	// Would be using the handle to identify
	//  on which channel the sound might be active,
	//  and resetting the channel parameters.
	
	// UNUSED.
	handle = vol = sep = pitch = 0;
}

//
// Retrieve the raw data lump index
//  for a given SFX name.
//
int I_GetSfxLumpNum(sfxinfo_t* sfx)
{
    char namebuf[9];
    sprintf(namebuf, "ds%s", sfx->name);
    return W_GetNumForName(namebuf);
}

//
// MUSIC API.
// Still no music done.
// Remains. Dummies.
//
void I_InitMusic(void)		{ }
void I_ShutdownMusic(void)	{ }

static int	looping=0;
static int	musicdies=-1;

void I_PlaySong(int handle, int looping)
{
  // UNUSED.
  handle = looping = 0;
  musicdies = gametic + TICRATE*30;
}

void I_PauseSong (int handle)
{
  // UNUSED.
  handle = 0;
}

void I_ResumeSong (int handle)
{
  // UNUSED.
  handle = 0;
}

void I_StopSong(int handle)
{
  // UNUSED.
  handle = 0;
  
  looping = 0;
  musicdies = 0;
}

void I_UnRegisterSong(int handle)
{
  // UNUSED.
  handle = 0;
}

int I_RegisterSong(void* data)
{
  // UNUSED.
  data = NULL;
  
  return 1;
}

// Is the song playing?
int I_QrySongPlaying(int handle)
{
  // UNUSED.
  handle = 0;
  return looping || musicdies > gametic;
}
