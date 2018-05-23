PROJECT_DIR := $(shell pwd)
CC = gcc
PROM = recovery
OBJ = recovery.o \
default_recovery_ui.o \
ui.o \
rktools.o \
roots.o \
bootloader.o \
safe_iop.o \
strlcpy.o \
strlcat.o \
rkupdate.o \
minzip/DirUtil.o \
minzip/Hash.o \
minzip/Inlines.o \
minzip/SysUtil.o \
minzip/Zip.o \
mtdutils/mounts.o \
mtdutils/mtdutils.o \
mtdutils/rk29.o \
minui/events.o \
minui/graphics.o \
minui/resources.o \
minui/graphics_drm.o

CFLAGS ?= -I$(PROJECT_DIR) -I/usr/include/libdrm/ -lz -lc -lpthread -lpng -ldrm
$(PROM): $(OBJ)
	$(CC) -o $(PROM) $(OBJ) $(CFLAGS)

%.o: %.c
	$(CC) -c $< -o $@ $(CFLAGS)

clean:
	rm -rf $(OBJ) $(PROM)

install:
	sudo install -D -m 755 recovery -t /usr/bin/
