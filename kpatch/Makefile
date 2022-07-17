
CFLAGS = -Wall -pedantic
LDFLAGS = 
LIBS = -lelf

all: kpatch

kpatch: main.o
	cc $(LDFLAGS) -o $@ $^ $(LIBS)

clean:
	rm -f kpatch *.o
