PREFIX:=$$HOME

bindir = $(PREFIX)/bin

all: avg

avg:
	gcc -lm -o avg avg.c

clean:
	rm -f *.o

install: all
	./install.sh $(bindir) \
	install -m 0755 avg $(bindir)
