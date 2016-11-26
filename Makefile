# MC404 p Trabalho 2 - Makefile
# Ruy Castilho Barrichelo - RA 177012

all: image

assemble:
	$(CROSS_COMPILE)gcc uoli_control.c -S -o uoli_control.s
	$(CROSS_COMPILE)as uoli_lib.s -o uoli_lib
	$(CROSS_COMPILE)as uoli_control.s -o uoli_control

link:
	$(CROSS_COMPILE)ld uoli_control.o uoli_lib.o -o robot_ctrl -Ttext =0x77803000 -Tdata=0x77801900

image:
	$(MKSD) --so $(OS) --user robot_ctrl

simulate:
	$(ARMSIM_PLAYER) --rom=$(DUMBOOT) --sd=disk.img

player:
	$(PLAYER) $(PLAYER_WORLDS)/simple.cfg


