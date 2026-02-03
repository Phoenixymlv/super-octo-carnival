CC := gcc
CFLAGS := -std=c99 -Wall -Wextra -O2 -g
LDFLAGS := -lglfw -lGL -lm -llua

# Directories
BUILD_DIR := build
SRC_DIR := .
OBJ_DIR := $(BUILD_DIR)/obj

# Files
SOURCES := engine.c
OBJECTS := $(SOURCES:%.c=$(OBJ_DIR)/%.o)
TARGET := $(BUILD_DIR)/game

# Lua header generation
LUA_HEADER := game.lua.h

# Default target
all: $(LUA_HEADER) $(TARGET)

# Create directories
$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

# Convert Lua to header
$(LUA_HEADER): game.lua
	xxd -i $< $@

# Compile object files
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Link executable
$(TARGET): $(OBJECTS)
	mkdir -p $(BUILD_DIR)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

# Run the game
run: $(TARGET)
	./$(TARGET)

# Clean build files
clean:
	rm -rf $(BUILD_DIR) $(LUA_HEADER)

# Emscripten build
emscripten: $(LUA_HEADER)
	emcc engine.c -o build/game.html \
		-s USE_GLFW=3 \
		-s USE_WEBGL2=1 \
		--preload-file game.lua \
		-lm -llua

# Help
help:
	@echo "Game Framework - Build Targets:"
	@echo "  make              - Build native executable"
	@echo "  make run          - Build and run"
	@echo "  make clean        - Remove build files"
	@echo "  make emscripten   - Build for web (requires Emscripten)"
	@echo "  make help         - Show this message"

.PHONY: all run clean emscripten help