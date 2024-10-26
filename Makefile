PROGRAM=cloader

CURRENT_TARGET = pmd85
PROGRAM_TGT := $(PROGRAM).$(CURRENT_TARGET)

SRCDIR := src
BUILD_DIR := build
OBJDIR := obj
DIST_DIR := dist

ifeq ($(shell echo),)
  MKDIR = mkdir -p $1
  RMDIR = rmdir $1
  RMFILES = $(RM) $1
else
  MKDIR = mkdir $(subst /,\,$1)
  RMDIR = rmdir $(subst /,\,$1)
  RMFILES = $(if $1,del /f $(subst /,\,$1))
endif

SOURCES := $(wildcard $(SRCDIR)/*.asm)

# remove trailing and leading spaces.
SOURCES := $(strip $(SOURCES))
OBJECTS := $(SOURCES:.asm=.o)
OBJECTS := $(OBJECTS:$(SRCDIR)/%=$(OBJDIR)/$(CURRENT_TARGET)/%)

AS = z80asm
LD = z80asm

ASFLAGS := 
LDFLAGS :=

all: $(PROGRAM_TGT)

dist: $(PROGRAM_TGT)
	cp $(BUILD_DIR)/$(PROGRAM_TGT) dist/autorun.rmm

clean:
	rm -rf ./$(BUILD_DIR)/*
	rm -rf ./$(OBJDIR)/*
	rm -rf ./$(DIST_DIR)/*

$(PROGRAM_TGT): $(BUILD_DIR)/$(PROGRAM_TGT)

$(OBJDIR)/$(CURRENT_TARGET)/%.o: src/%.asm
	@$(call MKDIR,$(dir $@))
	$(AS) $(ASFLAGS) -o=$@ $<

$(BUILD_DIR)/$(PROGRAM_TGT): $(OBJECTS)
	$(LD) -b $(LDFLAGS) -o=$@ $^
