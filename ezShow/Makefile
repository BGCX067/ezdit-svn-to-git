
#CC = arm-linux-gcc
CC = gcc
LD = ld
CFLAGS = 
#-mtune=arm920t -march=armv4t -mabi=aapcs-linux -msoft-float
LDFLAGS = -lSDL -lSDL_mixer -lSDL_image -lSDL_gfx -lSDL_ttf
LIB = 
INCLUDE = -I./ -I./include -I/home/board/buildroot/output/build/SDL-1.2.13/include -I/home/board/buildroot/output/build/SDL_mixer-1.2.8 -I/home/board/buildroot/output/build/sdl_image-1.2.6 -I/home/board/buildroot/output/build/sdl_gfx-2.0.19 -I/home/board/buildroot/output/build/sdl_sound-1.0.3 -I/home/board/buildroot/output/build/SDL_ttf-2.0.9

OUTPUT = ezShow
SRCS = slider.c settings.c settings_slider.c
OBJECTS = slider.o settings.o settings_slider.o

all:
	$(CC) $(INCLUDE) $(CFLAGS) $(LIB) -c $(SRCS)
	$(CC) $(LIB) $(LDFLAGS) $(OBJECTS) -o $(OUTPUT)

clean:
	rm *.o
