#include <stdio.h>

#include "settings.h"
#include "slider.h"

#include "SDL.h"

int Settings_Slider_HandleEvent(SDLKey key){
	if (key == KEY_MENU) {return 0;}
	
	return 1;	
}

void Settings_Slider_OnClick(void){
	SDL_Surface *photo;
	
	photo = Slider_LoadImage(SETTINGS_BG);
	SDL_BlitSurface(photo,NULL,Screen,NULL);
	SDL_FreeSurface(photo);
	SDL_Flip(Screen);

	Slider_PollEvent(Settings_Slider_HandleEvent);

}

void Settings_Slider_Init(){
	Settings_CreateItem("slider",Settings_Slider_OnClick);
}

void Settings_Slider_Quit(){

}
