##### Available defines for CJSON_CFLAGS #####
##
## USE_INTERNAL_ISINF:      Workaround for Solaris platforms missing isinf().
## DISABLE_INVALID_NUMBERS: Permanently disable invalid JSON numbers:
##                          NaN, Infinity, hex.
##
## Optional built-in number conversion uses the following defines:
## USE_INTERNAL_FPCONV:     Use builtin strtod/dtoa for numeric conversions.
## IEEE_BIG_ENDIAN:         Required on big endian architectures.
## MULTIPLE_THREADS:        Must be set when Lua CJSON may be used in a
##                          multi-threaded application. Requries _pthreads_.

##### Build defaults #####
LUA_VERSION =       5.2
TARGET =            cjson.so
PREFIX =            /usr/local
#CFLAGS =            -g -Wall -pedantic -fno-inline
CFLAGS =            -O3 -Wall -pedantic -DNDEBUG
CJSON_CFLAGS =      -fpic
CJSON_LDFLAGS =     -shared
LUA_INCLUDE_DIR =   $(PREFIX)/include
LUA_CMODULE_DIR =   $(PREFIX)/lib/lua/$(LUA_VERSION)
LUA_MODULE_DIR =    $(PREFIX)/share/lua/$(LUA_VERSION)
LUA_BIN_DIR =       $(PREFIX)/bin
RM = rm -f

##### Platform overrides #####
##
## Tweak one of the platform sections below to suit your situation.
##
## See http://lua-users.org/wiki/BuildingModules for further platform
## specific details.

ifeq ($(OS),Windows_NT)
    OS_VERSION = MINGW

    CCFLAGS += -D WIN32
    ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
        OSARCH = _amd64
    endif
    ifeq ($(PROCESSOR_ARCHITECTURE),x86)
         OSARCH = _386
    endif
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        OS_VERSION = LINUX
    endif
    ifeq ($(UNAME_S),Darwin)
        OS_VERSION = OSX
    endif

    UNAME_P := $(shell uname -p)
    ifeq ($(UNAME_P),x86_64)
        OSARCH = _amd64
    endif
    ifneq ($(filter %86,$(UNAME_P)),)
        OSARCH = _386
    endif
    ifneq ($(filter arm%,$(UNAME_P)),)
        OSARCH = _arm
    endif
endif



## Linux

ifeq ($(OS_VERSION),FREEBSD)

## FreeBSD
LUA_INCLUDE_DIR =   $(PREFIX)/include/lua52

else ifeq ($(OS_VERSION),OSX)

## MacOSX (Macports)
PREFIX =            /opt/local
CJSON_LDFLAGS =     -bundle -undefined dynamic_lookup

else ifeq ($(OS_VERSION),SOLARIS)

## Solaris
PREFIX =            /home/user/opt
CC =                gcc
CJSON_CFLAGS =      -fpic -DUSE_INTERNAL_ISINF

else ifeq ($(OS_VERSION),MINGW)

## Windows (MinGW)
CC =                gcc
TARGET =            cjson$(OSARCH).dll
PREFIX =            ../lua
CJSON_CFLAGS =      -DDISABLE_INVALID_NUMBERS
CJSON_LDFLAGS =     -shared -L$(PREFIX)/src -llua52$(OSARCH)
LUA_BIN_SUFFIX =    .lua

LUA_INCLUDE_DIR =   $(PREFIX)/src
RM = del /F /Q 

endif

##### Number conversion configuration #####

## Use Libc support for number conversion (default)
FPCONV_OBJS =       fpconv.o

## Use built in number conversion
#FPCONV_OBJS =       g_fmt.o dtoa.o
#CJSON_CFLAGS +=     -DUSE_INTERNAL_FPCONV

## Compile built in number conversion for big endian architectures
#CJSON_CFLAGS +=     -DIEEE_BIG_ENDIAN

## Compile built in number conversion to support multi-threaded
## applications (recommended)
#CJSON_CFLAGS +=     -pthread -DMULTIPLE_THREADS
#CJSON_LDFLAGS +=    -pthread

##### End customisable sections #####

TEST_FILES =        README bench.lua genutf8.pl test.lua octets-escaped.dat \
                    example1.json example2.json example3.json example4.json \
                    example5.json numbers.json rfc-example1.json \
                    rfc-example2.json types.json
DATAPERM =          644
EXECPERM =          755

ASCIIDOC =          asciidoc

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) $(CJSON_CFLAGS)
OBJS =              lua_cjson.o strbuf.o $(FPCONV_OBJS)

.PHONY: all clean install install-extra doc

.SUFFIXES: .html .txt

.c.o:
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $(BUILD_CFLAGS) -o $@ $<

.txt.html:
	$(ASCIIDOC) -n -a toc $<

all: $(TARGET)

doc: manual.html performance.html

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) $(CJSON_LDFLAGS) -o $@ $(OBJS)

install: $(TARGET)
	mkdir -p $(DESTDIR)/$(LUA_CMODULE_DIR)
	cp $(TARGET) $(DESTDIR)/$(LUA_CMODULE_DIR)
	chmod $(EXECPERM) $(DESTDIR)/$(LUA_CMODULE_DIR)/$(TARGET)

install-extra:
	mkdir -p $(DESTDIR)/$(LUA_MODULE_DIR)/cjson/tests \
		$(DESTDIR)/$(LUA_BIN_DIR)
	cp lua/cjson/util.lua $(DESTDIR)/$(LUA_MODULE_DIR)/cjson
	chmod $(DATAPERM) $(DESTDIR)/$(LUA_MODULE_DIR)/cjson/util.lua
	cp lua/lua2json.lua $(DESTDIR)/$(LUA_BIN_DIR)/lua2json$(LUA_BIN_SUFFIX)
	chmod $(EXECPERM) $(DESTDIR)/$(LUA_BIN_DIR)/lua2json$(LUA_BIN_SUFFIX)
	cp lua/json2lua.lua $(DESTDIR)/$(LUA_BIN_DIR)/json2lua$(LUA_BIN_SUFFIX)
	chmod $(EXECPERM) $(DESTDIR)/$(LUA_BIN_DIR)/json2lua$(LUA_BIN_SUFFIX)
	cd tests; cp $(TEST_FILES) $(DESTDIR)/$(LUA_MODULE_DIR)/cjson/tests
	cd tests; chmod $(DATAPERM) $(TEST_FILES); chmod $(EXECPERM) *.lua *.pl

clean:
	$(RM) *.o
	$(RM) $(TARGET)
