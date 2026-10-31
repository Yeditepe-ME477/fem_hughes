# ============================================================
# Makefile for DLEARN — Linux and macOS
#
# Windows users: build inside WSL2 — it reports `uname -s` = Linux
# and this Makefile handles it as a native Linux build.
#
# Usage:
#   make                 release build   → bin/dlearn
#   make debug           bounds-checked build
#   make clean
#   make distclean
#   make FC=ifx          override compiler
# ============================================================

# ---- OS detection ---------------------------------------------
UNAME_S := $(shell uname -s)

ifneq (,$(findstring Linux,$(UNAME_S)))
  PLATFORM := linux
else ifneq (,$(findstring Darwin,$(UNAME_S)))
  PLATFORM := darwin
else
  $(error Unsupported platform '$(UNAME_S)'. Use Linux, macOS, or WSL.)
endif

$(info [dlearn] platform = $(PLATFORM))

# ---- Toolchain ------------------------------------------------
# FC must be set with `=` (not `?=`) to defeat make's built-in FC=f77.
FC      = gfortran
LD      = $(FC)
RM      = rm -f
MKDIR   = mkdir -p

# ---- Directories ----------------------------------------------
SRCDIR  := SOURCE
OBJDIR  := obj
BINDIR  := bin
TARGET  := $(BINDIR)/dlearn

# ---- Sources --------------------------------------------------
# All fixed-form .FOR files, plus the portability shim for GETTIM.
SRCS    := \
    $(SRCDIR)/BR1.FOR \
    $(SRCDIR)/BR2.FOR \
    $(SRCDIR)/DL0.FOR \
    $(SRCDIR)/DL1.FOR \
    $(SRCDIR)/DL2.FOR \
    $(SRCDIR)/DL.FOR  \
    $(SRCDIR)/EL2.FOR \
    $(SRCDIR)/QD1.FOR \
    $(SRCDIR)/QD2.FOR \
    $(SRCDIR)/QD3.FOR \
    $(SRCDIR)/SYSR.FOR \
    $(SRCDIR)/TR0.FOR \
    $(SRCDIR)/TR1.FOR \
    $(SRCDIR)/GETTIM_COMPAT.FOR

OBJS    := $(patsubst $(SRCDIR)/%.FOR,$(OBJDIR)/%.o,$(SRCS))
INC     := $(SRCDIR)/memory_size.inc

# ---- Common flags --------------------------------------------
# -ffixed-form       : .FOR uppercase is fixed-form F77
# -ISOURCE           : resolve INCLUDE 'memory_size.inc'
# -Jobj              : keep .mod files out of SOURCE/ (harmless if none)
# -ffree-line-length-none : tolerate long comment lines
# -std=legacy        : accept F77 quirks (PAUSE, computed GOTO, …)
FFLAGS_COMMON := -ffixed-form -ISOURCE -Jobj -ffree-line-length-none \
                 -std=legacy

# Platform-specific extras (currently none required; kept for clarity).
ifeq ($(PLATFORM),darwin)
  # Homebrew gfortran (`brew install gcc`) is on PATH as `gfortran`.
  FFLAGS_COMMON +=
  LDFLAGS_PLATFORM :=
else
  # linux (also WSL2)
  FFLAGS_COMMON +=
  LDFLAGS_PLATFORM :=
endif

# ---- Build type ----------------------------------------------
BUILD ?= release
ifeq ($(BUILD),debug)
  FFLAGS := $(FFLAGS_COMMON) -O0 -g -fcheck=bounds -fbacktrace -Wall -Wextra \
            -Wno-unused-parameter -Wno-unused-variable
else
  FFLAGS := $(FFLAGS_COMMON) -O2 -g0
endif

LDFLAGS ?=
LDFLAGS += $(LDFLAGS_PLATFORM)
LIBS    ?=

# ---- Phony targets -------------------------------------------
.PHONY: all release debug clean distclean help

all: release

release:
	$(MAKE) BUILD=release $(TARGET)

debug:
	$(MAKE) BUILD=debug $(TARGET)

help:
	@echo "Targets:"
	@echo "  make            release build   → $(TARGET)"
	@echo "  make debug      debug build"
	@echo "  make clean      remove obj/"
	@echo "  make distclean  remove obj/ and bin/"
	@echo "  make FC=ifx     use Intel Fortran"
	@echo "Detected platform: $(PLATFORM)"

# ---- Build rules ---------------------------------------------
$(TARGET): $(OBJS) | $(BINDIR)
	$(LD) $(FFLAGS) $(LDFLAGS) -o $@ $(OBJS) $(LIBS)

$(OBJDIR)/%.o: $(SRCDIR)/%.FOR $(INC) | $(OBJDIR)
	$(FC) $(FFLAGS) -c $< -o $@

# ---- Directory creation --------------------------------------
$(OBJDIR) $(BINDIR):
	$(MKDIR) $@

# ---- Cleaning ------------------------------------------------
clean:
	$(RM) -r $(OBJDIR)

distclean: clean
	$(RM) -r $(BINDIR)