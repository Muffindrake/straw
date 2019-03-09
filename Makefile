PREFIX ?= /usr/local
OPTLEVEL ?= -O3 -release -mcpu=skylake -mattr=+skylake
DC = ldc2

.PHONY: all clean install
.DEFAULT: all

ifeq ($(DIAG), 1)
DFLAGS += -g -w -fsanitize=address
else
DFLAGS += -wi -de 
endif

PROG = straw
DIR_BUILD = build
SRCS = $(wildcard *.d)
OBJS = $(patsubst %.d,$(DIR_BUILD)/%.o,$(SRCS))

$(info $(shell mkdir -p $(DIR_BUILD)))

$(DIR_BUILD)/%.o: %.d
	$(DC) $(OPTLEVEL) $(DFLAGS) -of="$@" -c $<

$(PROG): $(OBJS)
	$(DC) $(OPTLEVEL) $(DFLAGS) -of="$@" $^

all: $(PROG)

clean:
	$(RM) $(PROG) $(OBJS)
