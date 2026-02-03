#!/bin/bash
# Game Framework Setup Script
# Installs dependencies and builds the project

set -e

echo "=========================================="
echo "Game Framework Setup"
echo "=========================================="

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected Linux"
    echo "Installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        cmake \
        libglfw3-dev \
        libgl1-mesa-dev \
        liblua5.4-dev \
        xxd
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS"
    echo "Installing dependencies..."
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Please install from https://brew.sh"
        exit 1
    fi
    brew install cmake glfw3 lua xxd
    
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo "Detected Windows (MSYS/Cygwin)"
    echo "Please install dependencies manually or use vcpkg:"
    echo "  vcpkg install glfw3:x64-windows lua:x64-windows"
    
else
    echo "Unknown OS: $OSTYPE"
    exit 1
fi

echo ""
echo "=========================================="
echo "Building Project"
echo "=========================================="

# Create build directory
mkdir -p build
cd build

# Configure with CMake
cmake ..

# Build
cmake --build .

cd ..

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo "Run with: ./build/game"
echo ""