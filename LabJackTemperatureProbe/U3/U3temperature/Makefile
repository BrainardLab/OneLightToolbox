#
# Makefile for u3TempNew
#
u3TempNew_SRC=u3TempNew.c u3.c
u3TempNew_OBJ=$(u3TempNew_SRC:.c=.o)

SRCS=$(wildcard *.c)
HDRS=$(wildcard *.h)

CFLAGS +=-Wall -g
LIBS=-lm -llabjackusb

all: u3TempNew 

u3TempNew: $(u3TempNew_OBJ) $(HDRS)
	$(CC) -o u3TempNew $(u3TempNew_OBJ) $(LDFLAGS) $(LIBS)

clean:
	rm -f *.o *~ u3TempNew
