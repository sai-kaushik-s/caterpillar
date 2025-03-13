#!/bin/bash

# Configuration
CATERPILLAR_PATH="$(pwd)/caterpillar"  # Change this to your Caterpillar installation path
CPP_FILE="quantum.cpp"
EXECUTABLE="quantum"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}    Verilog to Quantum Circuit Converter Tool      ${NC}"
echo -e "${BLUE}===================================================${NC}"

# Check if Caterpillar path exists
if [ ! -d "$CATERPILLAR_PATH" ]; then
    echo -e "${RED}Error: Caterpillar path not found at $CATERPILLAR_PATH${NC}"
    echo "Please update the CATERPILLAR_PATH variable in this script"
    exit 1
fi

# Check for required include directories
if [ ! -d "$CATERPILLAR_PATH/include" ]; then
    echo -e "${RED}Error: Required include directories not found${NC}"
    echo "Make sure Caterpillar is properly installed with all dependencies"
    exit 1
fi

# Check if source file exists
if [ ! -f "$CPP_FILE" ]; then
    echo -e "${RED}Error: Source file $CPP_FILE not found${NC}"
    echo "Make sure the CPP file is in the current directory"
    exit 1
fi

# Check for --skip-compile flag
SKIP_COMPILE=false
for arg in "$@"; do
    if [ "$arg" == "--skip-compile" ]; then
        SKIP_COMPILE=true
        break
    fi
done

# Create include paths
INCLUDE_PATHS=(
    "-I$CATERPILLAR_PATH/include"
    "-I/usr/include/x86_64-linux-gnu/nauty"
    "-I$CATERPILLAR_PATH/lib/tweedledum"
    "-I$CATERPILLAR_PATH/lib/mockturtle"
    "-I$CATERPILLAR_PATH/lib/lorina"
    "-I$CATERPILLAR_PATH/lib/kitty"
    "-I$CATERPILLAR_PATH/lib/sparsepp"
    "-I$CATERPILLAR_PATH/lib/ez"
    "-I$CATERPILLAR_PATH/lib/percy"
    "-I$CATERPILLAR_PATH/lib/abcsat"
    "-I$CATERPILLAR_PATH/lib/rang"
    "-I$CATERPILLAR_PATH/lib/bill"
    "-I$CATERPILLAR_PATH/lib/easy"
)

# Compile the program if not skipping
if [ "$SKIP_COMPILE" = false ]; then
    echo -e "${BLUE}Compiling $CPP_FILE...${NC}"
    g++ -std=c++17 -D_Thread_local=thread_local ${INCLUDE_PATHS[@]} $CPP_FILE -o $EXECUTABLE -L../lib -lfmt

    # Check if compilation was successful
    if [ $? -ne 0 ]; then
        echo -e "${RED}Compilation failed${NC}"
        exit 1
    else
        echo -e "${GREEN}Compilation successful!${NC}"
    fi
else
    echo -e "${BLUE}Skipping compilation as requested...${NC}"
fi

# Remove --skip-compile from arguments before running the program
ARGS=()
for arg in "$@"; do
    if [ "$arg" != "--skip-compile" ]; then
        ARGS+=("$arg")
    fi
done

# Check if arguments are provided
if [ ${#ARGS[@]} -lt 2 ]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    echo "Usage: $0 input.v [options]"
    echo "Options:"
    echo "  --strategy=<pebbling|bennett|eager>  Synthesis strategy [default: pebbling]"
    echo "  --optimize                           Apply XAG optimization before synthesis"
    echo "  --verbose                            Print detailed statistics"
    echo "  --skip-compile                       Skip compilation step"
    exit 1
fi

# Run the program
echo -e "${BLUE}Running $EXECUTABLE...${NC}"
./$EXECUTABLE "${ARGS[@]}"

# Check if execution was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Execution failed${NC}"
    exit 1
else
    echo -e "${GREEN}Execution completed successfully!${NC}"
fi

base_filename=$(basename "$1")
qpic_directory="output/${base_filename%.*}/"
cd $qpic_directory
qpic_file="quantum_circuit.qpic"

# Check if QPic file exists, if exists convert to pdf
if [ -f "$qpic_file" ]; then
    echo -e "${BLUE}Converting QPic to PDF...${NC}"
    qpic -f pdf $qpic_file -o quantum_circuit.pdf
    echo -e "${GREEN}Conversion completed successfully!${NC}"
else
    echo -e "${RED}Error: QPic file not found at $qpic_file${NC}"
    exit 1
fi