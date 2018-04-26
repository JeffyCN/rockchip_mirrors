
ROOTDIR=$(pwd)
cc = gcc
prom = recovery
obj = recovery.o \
default_recovery_ui.o \
ui.o \
roots.o \
bootloader.o \
safe_iop.o \
strlcpy.o \
strlcat.o \
minzip/DirUtil.o \
minzip/Hash.o \
minzip/Inlines.o \
minzip/SysUtil.o \
minzip/Zip.o \
mtdutils/mounts.o \
mtdutils/mtdutils.o \
minui/events.o \
minui/graphics.o \
minui/resources.o \
minui/graphics_drm.o

lib = -lz -lc -lpthread -lpng -ldrm
INC = -I./ -I/usr/include/libdrm/
CFLAG = 
$(prom): $(obj)
	$(cc) -o $(prom) $(obj) $(lib)

%.o: %.c
	$(cc) -c $< -o $@ $(INC) $(CFLAG)

clean:
	rm -rf $(obj) $(prom)
