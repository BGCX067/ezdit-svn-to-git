#ifndef SLIDER_H
#define SLIDER_H

#include "SDL.h"

#define DEBUG 1

#define	SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600
#define SCREEN_BPP 32

#define PHOTO_ROTATE 0

#define TEXT_FONT "resource/font.ttf"
#define TEXT_FONT_SIZE 24

#define MUSIC_FREQ 11050
#define MUSIC_CHANNELS 2
#define MUSIC_FORMAT AUDIO_S16
#define MUSIC_CHUNK_SIZE 4096*2*8

#define KEY_LEFT SDLK_LEFT
#define KEY_RIGHT SDLK_RIGHT
#define KEY_UP SDLK_UP
#define KEY_DOWN SDLK_DOWN
#define KEY_MENU SDLK_0
#define KEY_ENTER SDLK_1

extern SDL_Surface* Screen;

extern int Slider_Init();
extern SDL_Surface *Slider_LoadImage(const char *fpath);
extern void Slider_PollEvent(int (*cb)(SDLKey));
extern void Slider_Quit();


#endif


