#ifndef SETTINGS_H
#define SETTINGS_H

#include "SDL.h"

#define SETTINGS_BG "images/bg.png"
#define SETTINGS_MAX_ITEMS 5
#define SETTINGS_ITEMS_PER_ROW 3
#define SETTINGS_ITEM_X_OFT 115
#define SETTINGS_ITEM_X_GAP 280
#define SETTINGS_ITEM_Y_OFT 70
#define SETTINGS_ITEM_Y_GAP 200

#define TYPE_NORMAL_ICON 0x00
#define TYPE_ACTIVE_ICON 0x01

struct Settings_Item {
	char icon[15];
	void (*onClick)(void);
};

// private function
extern  void Settings_ChangeItem();
extern  int Settings_HandleEvent(SDLKey);
extern  void Settings_Init();
extern  void Settings_Quit();
extern  void Settings_SetItem(int itemId, int type);
#define Settings_Main() Slider_PollEvent(Settings_HandleEvent)
#define Settings_SetNormal(itemId)  Settings_SetItem(itemId, TYPE_NORMAL_ICON)
#define Settings_SetActive(itemId)  Settings_SetItem(itemId, TYPE_ACTIVE_ICON)

//public function
extern int Settings_CreateItem(char *icon, void (*onClick)(void));


#endif
