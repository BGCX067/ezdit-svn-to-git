#include <stdio.h>

#include "settings.h"
#include "slider.h"

#include "SDL.h"

static int CurrItem = 0;
static int NextItem = 0;
static int TotalItems = 0;
static SDL_Surface *Background = NULL;
static struct Settings_Item Items[SETTINGS_MAX_ITEMS];

void Settings_ChangeItem(){	
	
	Settings_SetNormal(CurrItem);
	CurrItem = NextItem;
	Settings_SetActive(CurrItem);
}

int Settings_CreateItem(char *icon,void (*onClick)(void)){
	
	strcpy(Items[TotalItems].icon,icon);
	Items[TotalItems].onClick = onClick;
	
	Settings_SetNormal(TotalItems);
	
	TotalItems++;

	return (TotalItems - 1);
}

int Settings_HandleEvent(SDLKey key){	
	SDL_Surface *backup;
	
	if (key == KEY_MENU) {return 0;}
	
	if (key == KEY_ENTER) {
		if (Items[CurrItem].onClick != 0) {
			backup=SDL_DisplayFormatAlpha(Screen);
			Items[CurrItem].onClick();
			SDL_BlitSurface(backup,NULL,Screen,NULL);
			SDL_Flip(Screen);
			SDL_FreeSurface(backup);
		} else {
			printf("Not implement yet!! \n");
		}
		
	}	
	if (key == KEY_RIGHT) {NextItem++;}
	if (key == KEY_LEFT) {NextItem--;}
	if (NextItem < 0) {NextItem = TotalItems - 1;}
	if (NextItem >= TotalItems) {NextItem = 0;}
	if (NextItem != CurrItem) {Settings_ChangeItem();}
	
	return 1;
}

void Settings_SetItem(int itemId, int type){
	int x = 0,y = 0, i = 0;
	
	char icon[50];
	SDL_Surface *img;
	SDL_Rect oft;
	
	if (type == TYPE_NORMAL_ICON) 	
		sprintf(icon,"images/%s.png",Items[itemId].icon);
	else
		sprintf(icon,"images/%s_active.png",Items[itemId].icon);
		
#if DEBUG
	printf("Curr:%d\tPos:%d\t%s\n",CurrItem,itemId,icon);
#endif	

	img = Slider_LoadImage(icon);
	
	x = itemId % SETTINGS_ITEMS_PER_ROW;
	y = itemId / SETTINGS_ITEMS_PER_ROW;
	oft.x =  SETTINGS_ITEM_X_OFT + SETTINGS_ITEM_X_GAP*x - img->clip_rect.w/2 ;
	oft.y = SETTINGS_ITEM_Y_OFT + SETTINGS_ITEM_Y_GAP * y;
	oft.w=img->clip_rect.w;
	oft.h=img->clip_rect.h;
	
	SDL_BlitSurface(Background,&oft,Screen,&oft);
	SDL_BlitSurface(img,NULL,Screen,&oft);	
	SDL_UpdateRect(Screen,oft.x,oft.y,img->clip_rect.w,img->clip_rect.h);

	SDL_FreeSurface(img);		
}

void Settings_Init(){

	NextItem = 0;
	CurrItem = 0;
	TotalItems = 0;

	Background = Slider_LoadImage(SETTINGS_BG);
	SDL_BlitSurface(Background,NULL,Screen,NULL);

	Settings_Slider_Init();

	// for test 
	Settings_CreateItem("music",0);
	Settings_CreateItem("clock",0);
	Settings_CreateItem("clock",0);
	Settings_CreateItem("slider",0);

	// active first item
	Settings_SetActive(0);

	SDL_Flip(Screen);
}

void Settings_Quit(){
	
	Settings_Slider_Quit();
	
	SDL_FreeSurface(Background);
}
