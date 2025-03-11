#!/bin/bash

# Configuration
REPO_URL="https://github.com/gmeuli/caterpillar.git"
INSTALL_PATH="$(pwd)/caterpillar"  # Change this as needed
BUILD_DIR="build"
EXECUTABLE="caterpillar"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}        Caterpillar Clone and Build Tool           ${NC}"
echo -e "${BLUE}===================================================${NC}"

# Check for required tools
check_dependency() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed.${NC}"
        echo "Please install $1 before continuing."
        exit 1
    fi
}

echo -e "${BLUE}Checking for required dependencies...${NC}"
check_dependency git
check_dependency cmake
check_dependency g++
echo -e "${GREEN}All required dependencies found!${NC}"

# Check for --skip-clone flag
SKIP_CLONE=false
for arg in "$@"; do
    if [ "$arg" == "--skip-clone" ]; then
        SKIP_CLONE=true
        break
    fi
done

# Clone the repository if not skipping
if [ "$SKIP_CLONE" = false ]; then
    if [ -d "$INSTALL_PATH" ]; then
        echo -e "${YELLOW}Repository already exists at $INSTALL_PATH${NC}"
        echo -e "${BLUE}Updating repository...${NC}"
        cd "$INSTALL_PATH"
        git pull
        cd - > /dev/null
    else
        echo -e "${BLUE}Cloning Caterpillar repository...${NC}"
        git clone "$REPO_URL" "$INSTALL_PATH"
        
        # Check if clone was successful
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to clone repository${NC}"
            exit 1
        else
            echo -e "${GREEN}Repository cloned successfully!${NC}"
        fi
    fi
else
    echo -e "${BLUE}Skipping repository clone as requested...${NC}"
    
    # Check if the repository exists
    if [ ! -d "$INSTALL_PATH" ]; then
        echo -e "${RED}Error: Caterpillar repository not found at $INSTALL_PATH${NC}"
        echo "Please run without --skip-clone option first"
        exit 1
    fi
fi

# Change to the repository directory
cd "$INSTALL_PATH"

# Initialize and update submodules
echo -e "${BLUE}Initializing and updating git submodules...${NC}"
git submodule update --init --recursive

# Check if submodule update was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to update submodules${NC}"
    exit 1
else
    echo -e "${GREEN}Submodules updated successfully!${NC}"
fi

# Create and enter build directory
echo -e "${BLUE}Creating build directory...${NC}"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Fix the Catch2 header file error
echo -e "${BLUE}Applying fixes to Catch2 header file...${NC}"
CATCH_HEADER_PATH="../test/catch2/catch.hpp"

if [ -f "$CATCH_HEADER_PATH" ]; then
    # Create a backup of the original file
    cp "$CATCH_HEADER_PATH" "${CATCH_HEADER_PATH}.bak"
    
    # Replace the problematic line with a fixed version
    sed -i 's/constexpr static std::size_t sigStackSize = 32768 >= MINSIGSTKSZ ? 32768 : MINSIGSTKSZ;/constexpr static std::size_t sigStackSize = 32768;/g' "$CATCH_HEADER_PATH"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to patch Catch2 header file${NC}"
        echo -e "${YELLOW}Restoring backup...${NC}"
        mv "${CATCH_HEADER_PATH}.bak" "$CATCH_HEADER_PATH"
        exit 1
    else
        echo -e "${GREEN}Successfully patched Catch2 header file!${NC}"
    fi
else
    echo -e "${RED}Warning: Catch2 header file not found at expected location: $CATCH_HEADER_PATH${NC}"
    echo -e "${YELLOW}You may need to manually fix the error after build fails${NC}"
fi

# Configure with CMake
echo -e "${BLUE}Configuring with CMake...${NC}"
cmake ..

# Check if CMake configuration was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}CMake configuration failed${NC}"
    exit 1
else
    echo -e "${GREEN}CMake configuration successful!${NC}"
fi

# Build the project
echo -e "${BLUE}Building Caterpillar...${NC}"
make -j$(nproc)  # Use all available CPU cores

# Check if build was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed${NC}"
    exit 1
else
    echo -e "${GREEN}Build completed successfully!${NC}"
fi

echo -e "$(pwd)"

# Run tests
echo -e "${BLUE}Running tests...${NC}"
TEST_BINARY="$(pwd)/test/run_tests"

if [ -f "$TEST_BINARY" ]; then
    "$TEST_BINARY"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Tests failed!${NC}"
        exit 1
    else
        echo -e "${GREEN}All tests passed successfully!${NC}"
    fi
else
    echo -e "${RED}Test binary not found: $TEST_BINARY${NC}"
    exit 1
fi

echo -e "${BLUE}===================================================${NC}"
echo -e "${GREEN}Caterpillar has been successfully built!${NC}"
echo -e "${BLUE}===================================================${NC}"
echo ""
echo -e "${BLUE}For more information, visit:${NC}"
echo -e "${YELLOW}https://github.com/gmeuli/caterpillar${NC}"