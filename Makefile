CC ?= clang
CFLAGS ?= -std=c17 -O3 -Wall -Wextra -Werror -fPIC -Iinclude
LDFLAGS ?= -shared

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    DYLIB_EXT := dylib
    SHARED_FLAG := -dynamiclib
else
    DYLIB_EXT := so
    SHARED_FLAG := -shared
endif

LIB_DIR := lib
BUILD_DIR := build
BIN_DIR := bin
TARGET_LIB := $(LIB_DIR)/libreticle_fastpath.$(DYLIB_EXT)

SOURCES := src/fastpath.c
OBJECTS := $(patsubst src/%.c,$(BUILD_DIR)/%.o,$(SOURCES))

.PHONY: all clean test-c test lint help

all: $(TARGET_LIB)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(LIB_DIR):
	mkdir -p $(LIB_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(BUILD_DIR)/%.o: src/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET_LIB): $(OBJECTS) | $(LIB_DIR)
	$(CC) $(SHARED_FLAG) $(OBJECTS) -o $@

test-c: $(TARGET_LIB) | $(BIN_DIR)
	$(CC) $(CFLAGS) tests/test_fastpath.c $(TARGET_LIB) -o $(BIN_DIR)/test_fastpath
	./$(BIN_DIR)/test_fastpath

test: test-c
	python3 -m unittest discover -s tests

lint:
	python3 tools/lint_no_em_dash.py

clean:
	rm -rf $(BUILD_DIR) $(LIB_DIR) $(BIN_DIR)

help:
	@echo "Reticle Build System Targets:"
	@echo "  all      - Build C17 fastpath shared library"
	@echo "  test-c   - Compile and execute C17 unit tests"
	@echo "  test     - Run complete multi-language test suite"
	@echo "  lint     - Enforce zero em dash typography invariant"
	@echo "  clean    - Remove build artifacts and binary trees"
