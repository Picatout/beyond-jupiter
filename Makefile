NAME=stm32eforth
# tools
PREFIX=arm-none-eabi-
CC=$(PREFIX)gcc
AS=$(PREFIX)as 
LD=$(PREFIX)ld
DBG=gdb-multiarch
OBJDUMP=$(PREFIX)objdump
OBJCOPY=$(PREFIX)objcopy

#build directory
BUILD_DIR=build/
#Link file
LD_FILE=stm32f411ce.ld 
LD_FLAGS=-mmcu=stm32f411re
#sources
SRC=init.s environment.s ser-term.s tvout.s ps2_kbd.s spi-flash.s fpu.s strtof.s ftoa.s forth.s 
 
# programmer
VERSION=STLINKV2
STM_PROG=553f6a06663f56493953103f
SMALL_DUNGLE=48FF6E066772574857351967 
STV2_DUNGLE=$(SMALL_DUNGLE)
STV3_PROG_SN=
SERIAL=$(STV2_DUNGLE)
# MCU 
CPU=-march=armv7m -mfpu=vfpv4 -mfloat-abi=hard 

.PHONY: all 

all: clean build dasm

build:  *.s Makefile *.inc $(LD_FILE)
	$(AS) $(CPU) -a=$(BUILD_DIR)$(NAME).lst $(SRC) -g -o$(BUILD_DIR)$(NAME).o
	$(LD) -T $(LD_FILE) -g $(BUILD_DIR)$(NAME).o -o $(BUILD_DIR)$(NAME).elf
	$(OBJCOPY) -O binary $(BUILD_DIR)$(NAME).elf $(BUILD_DIR)$(NAME).bin 
#	$(OBJCOPY) -O ihex $(BUILD_DIR)$(NAME).elf $(BUILD_DIR)$(NAME).hex  
	$(OBJDUMP) -D $(BUILD_DIR)$(NAME).elf > $(BUILD_DIR)$(NAME).dasm

flash: $(BUILD_DIR)$(NAME).bin 
	@echo "************************"
	@echo "	 FLASHING DEVICE       "
	@echo "************************"
#	st-flash --serial=$(SERIAL) erase 
	st-flash  --serial=$(SERIAL)  write $(BUILD_DIR)$(NAME).bin 0x8000000

dasm:
	$(OBJDUMP) -D $(BUILD_DIR)$(NAME).elf > $(BUILD_DIR)$(NAME).dasm

debug: 
	cd $(BUILD_DIR) &&\
	$(DBG) -tui --eval-command="target remote localhost:4242" $(NAME).elf

erase:
	st-flash --serial=$(SERIAL) erase

.PHONY: clean 

clean:
	$(RM) build/*


	

