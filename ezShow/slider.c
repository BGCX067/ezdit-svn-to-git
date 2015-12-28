#include <stdio.h>
#include <dirent.h>
#include <unistd.h>
#include <time.h>
#include <sys/types.h>

#include "SDL.h"
#include "SDL_image.h"
#include "SDL_mixer.h"
#include "SDL_ttf.h"
#include "SDL_rotozoom.h"

#include "settings.h"
#include "slider.h"

SDL_Surface* Screen = NULL;
TTF_Font *TextFont = NULL;
SDL_Color TextColor = {0xFF,0xFF,0xFF};

int Slider_Init(){
	if (SDL_Init(
		SDL_INIT_TIMER | SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_EVENTTHREAD
	) == -1) {
		printf("SDL_Init fail!! \n");	
		return -1;
	}

	Screen=SDL_SetVideoMode(
		SCREEN_WIDTH,
		SCREEN_HEIGHT,
		SCREEN_BPP,
		SDL_SWSURFACE
	);

	if (Screen == NULL) {
		printf("Can't get framebuffer surface!!\n");
		return -1;
	}

	SDL_ShowCursor(SDL_DISABLE);
	
	//IMG_Init(IMG_INIT_JPG | IMG_INIT_PNG);
	
	if (TTF_Init() == -1) {
                printf("TTF_Init fail!!\n");
                return -1;
        }
	TextFont = TTF_OpenFont(TEXT_FONT,TEXT_FONT_SIZE);	
	
/*
	if (Mix_OpenAudio(
		MUSIC_FREQ,
		MUSIC_FORMAT,
		MUSIC_CHANNELS,
		MUSIC_CHUNK_SIZE
	)) {printf("OpenAudio fail!!\n");}
*/
	return 0;
}

SDL_Surface *Slider_LoadImage(const char *fpath){
	SDL_Surface *tmp;
	SDL_Surface *photo;
	
	tmp = IMG_Load(fpath);
	photo = SDL_DisplayFormatAlpha(tmp);
	SDL_FreeSurface(tmp);	

	return photo;
}

void Slider_PollEvent(int (*cb)(SDLKey)){
	int keyFlag;
	SDL_Event evt;	
	
	while (1) {
		SDL_PollEvent(&evt);
		
		if (evt.type == SDL_QUIT) {break;}
		
		if (evt.type == SDL_KEYDOWN) {
			keyFlag = 1;
			continue;
		}
	
		if (evt.type == SDL_KEYUP && keyFlag == 1) {
			keyFlag = 0;
			if (cb(evt.key.keysym.sym) == 0) {break;}
		}
	}
}

void Slider_Quit(){
	//Mix_CloseAudio();
	//Mix_Quit();
	
	TTF_CloseFont(TextFont);
	TTF_Quit();

	//IMG_Quit();
	
	SDL_Quit();
}

int main( int argc, char* args[] ){

	Slider_Init();
	
	Settings_Init();
	Settings_Main();
	Settings_Quit();
	
	Slider_Quit();

	return 0;
}
