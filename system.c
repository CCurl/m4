// A Tachyon inspired system, MIT license, (c) 2026 Chris Curl

#include "m4-vm.h"

#ifdef IS_WINDOWS
	#include <windows.h>
	#include <conio.h>
	int qKey() { return _kbhit() ? -1 : 0; }
	int key() { return _getch(); }
	void ttyMode(int isRaw) {}
	cell timer() { return (cell)clock(); }
#endif

// Support for Linux, OpenBSD, FreeBSD
#if defined(__linux__) || defined(__OpenBSD__) || defined(__FreeBSD__)
	#include <termios.h>
	#include <unistd.h>
	#include <sys/time.h>
	#include <time.h>

	void ttyMode(int isRaw) {
		static struct termios origt, rawt;
		static int curMode = -1;
		if (curMode == -1) {
			curMode = 0;
			tcgetattr( STDIN_FILENO, &origt);
			cfmakeraw(&rawt);
		}
		if (isRaw != curMode) {
			if (isRaw) {
				tcsetattr( STDIN_FILENO, TCSANOW, &rawt);
			} else {
				tcsetattr( STDIN_FILENO, TCSANOW, &origt);
			}
			curMode = isRaw;
		}
	}
	int qKey() {
		struct timeval tv;
		fd_set rdfs;
		ttyMode(1);
		tv.tv_sec = 0;
		tv.tv_usec = 0;
		FD_ZERO(&rdfs);
		FD_SET(STDIN_FILENO, &rdfs);
		select(STDIN_FILENO+1, &rdfs, NULL, NULL, &tv);
		int x = FD_ISSET(STDIN_FILENO, &rdfs);
		return x ? -1 : 0;
	}
	int key() {
		ttyMode(1);
		int x = fgetc(stdin);
		return x;
	}
	cell timer() {
		struct timespec ts;
		clock_gettime(CLOCK_REALTIME, &ts);
		return (cell)(ts.tv_sec * 1000 + ts.tv_nsec / 1000000);
	}
#endif // Linux, OpenBSD, FreeBSD

char fn[32];
void zType(const char *str) { fputs(str, outputFp ? (FILE*)outputFp : stdout); }
void emit(const char ch) { fputc(ch, outputFp ? (FILE*)outputFp : stdout); }

cell fOpen(cell name, cell mode) { return (cell)fopen((char*)name, (char*)mode); }
void fClose(cell fh) { fclose((FILE*)fh); }
cell fRead(cell buf, cell sz, cell fh) { return (cell)fread((char*)buf, 1, sz, (FILE*)fh); }
cell fWrite(cell buf, cell sz, cell fh) { return (cell)fwrite((char*)buf, 1, sz, (FILE*)fh); }
cell bootFn(char *f) { sprintf(fn, "%sm4-boot.fth", f); return (cell)fn; }

void repl() {
	char *tib = (char*)(last-1024);
	ttyMode(0);
	if (state != COMPILE) { state = INTERPRET; }
	zType((state == COMPILE) ? " ... "  : " ok\n");
	if (fgets(tib, 128, stdin) == tib) { outer(tib); }
	else { state = BYE; }
}

void boot(const char *fn) {
	cell fp = fOpen(fn ? (cell)fn : bootFn(""), (cell)"rb");
	if (!fp) { fp = fOpen(bootFn(""), (cell)"rb"); }
	if (!fp) { fp = fOpen(bootFn(BIN_DIR), (cell)"rb"); }
	if (fp) {
		char *tib = (char*)&mem[100000];
		fRead((cell)tib, 99999, fp);
		fClose(fp);
		outer(tib);
	} else {
		zType("WARNING: unable to open source file!\n");
		zType("If no filename is provided, the default is 'm4-boot.fth'\n");
	}
}

int main(int argc, char *argv[]) {
	m4Init();
	char *tib = (char*)(last-1024);
	addLit("argc", (cell)argc);
	strcpy(tib, "argX");
	for (int i=0; (i<argc) && (i<10); i++) {
		tib[3] = '0' + i;
		addLit(tib, (cell)argv[i]);
	}
	boot((1<argc) ? argv[1] : 0);
	while (state != BYE) { repl(); }
	ttyMode(0);
	return 0;
}
