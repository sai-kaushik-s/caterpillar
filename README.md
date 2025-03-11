# Caterpillar Library for Quantum Compilation

## Overview

The **Caterpillar** library is used for quantum compilation, specifically for converting classical circuits (in Verilog) into quantum circuits. This repository provides setup scripts to clone, build, and test the library.

## Pre-requisites

Ensure that the following dependencies are installed before proceeding with the setup:

- **C++ Compiler** (GCC 9+ or Clang 10+ recommended)
- **CMake** (Version 3.16 or later)
- **Python 3** (For additional scripting support, if needed)
- **Git** (For cloning the repository)
- **Boost Library** (Required for some of the library functionalities)
- **Make** (For building the library)

### Installing Dependencies (Ubuntu/Debian)

Run the following command to install the necessary dependencies:

```sh
sudo apt update && sudo apt install -y build-essential cmake python3 git libboost-all-dev libfmt-dev libnauty-dev
```

## Setup

To install and build the Caterpillar library, execute the `setup.sh` script:

```sh
chmod +x setup.sh
./setup.sh
```

This will:

1. Clone the Caterpillar repository.
2. Build the library using CMake and Make.
3. Install the necessary dependencies for the library.

## Testing the Setup

After successfully setting up the library, you can test its functionality using the provided `test.sh` script. This script compiles a C++ file that utilizes the library functions to convert a Verilog file into a quantum circuit.

Run the test script using:

```sh
chmod +x test.sh
./test.sh
```

### Expected Outcome

If the test is successful, it should generate a quantum circuit representation of the given Verilog file.

## Troubleshooting

- If the setup script fails, check for missing dependencies and ensure all required libraries are installed.
- If the test script does not work, verify that the Caterpillar library was built correctly and is accessible from your project.
- For additional debugging, refer to the logs generated in the build directory.

## References

For more details, visit the official Caterpillar documentation: [Caterpillar Library GitHub](https://github.com/quantumlib/caterpillar)

## License

This repository follows the licensing terms of the Caterpillar library. Refer to the original license for more details.
