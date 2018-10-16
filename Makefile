PROJECT_DIR := $(shell pwd)
CC = gcc
PROM = recovery
OBJ = recovery.o \
	default_recovery_ui.o \
	rktools.o \
	roots.o \
	bootloader.o \
	safe_iop.o \
	strlcpy.o \
	strlcat.o \
	rkupdate.o \
	sdboot.o \
	mtdutils/mounts.o \
	mtdutils/mtdutils.o \
	mtdutils/rk29.o \
	minzip/DirUtil.o

ifdef RecoveryNoUi
OBJ += noui.o
else
OBJ += ui.o\
	minzip/Hash.o \
	minzip/Inlines.o \
	minzip/SysUtil.o \
	minzip/Zip.o \
	minui/events.o \
	minui/graphics.o \
	minui/resources.o \
	minui/graphics_drm.o
endif

CFLAGS ?= -I$(PROJECT_DIR) -I/usr/include/libdrm/ -lc

ifdef RecoveryNoUi
CFLAGS += -lpthread
else
CFLAGS += -lz -lpng -ldrm
endif

$(PROM): $(OBJ)
	$(CC) -o $(PROM) $(OBJ) $(CFLAGS)

%.o: %.c
	$(CC) -c $< -o $@ $(CFLAGS)

clean:
	rm -rf $(OBJ) $(PROM)

install:
	sudo install -D -m 755 recovery -t /usr/bin/
