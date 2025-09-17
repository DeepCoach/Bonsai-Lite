Bonsai-Nano -- Lightweight GPU Gravitational N-body Tree Algorithm Code
=============================================

Bonsai-Nano is a lightweight version of the Bonsai GPU gravitational N-body tree algorithm, focusing on core computational functionality while removing legacy, visualization components and redundant features.It facilitates integration with
other project developments.

## Project Simplification Description

Compared to the original Bonsai project, Bonsai-Nano removes the following components:

### Completely Removed Directories and Files
- **Rendering System** (`renderer/` directory): Removed all OpenGL visualization components
- **OpenGL Libraries** (`lib/` directory): Removed precompiled OpenGL/GLEW library files  
- **OpenGL Headers** (`include/GL/` directory): Removed OpenGL related header files
- **B40C Library** (`include/b40c/` directory): Removed third-party CUDA radix sort library (66 files)
- **Visualization Scripts**: `vizscript.sh`, `Makefile_ogl`
- **Parameter Configuration Files**: `paramsDDASYNC.txt`, `paramsMW.txt`, `paramsNew.txt`, `params_movie4k.txt`

### Simplified CUDA Kernels
Removed redundant versions of the following gravity calculation kernels:
- `dev_approximate_gravity.cu` (basic version)
- `dev_approximate_gravity_fermi.cu` (Fermi architecture version)  
- `dev_approximate_gravity_kepler.cu` (Kepler architecture version)
- `dev_approximate_gravity_let.cu` (LET algorithm version)
- `dev_approximate_gravity_warp.cu` (Warp level version)

Retained core kernels:
- `dev_approximate_gravity_warp_fermi.cu` (Fermi Warp optimized version)
- `dev_approximate_gravity_warp_new.cu` (New architecture Warp optimized version)

### Removed Source Files
- `src/renderloop.cpp`, `src/render_particles.cpp` (rendering related)
- `src/tr.c` (utility functions)

## Core Functionality

Bonsai-Nano retains the complete N-body gravity calculation core functionality:
- CUDA-accelerated octree construction
- GPU parallel gravity computation
- MPI parallel support
- Multiple sorting algorithms (Thrust/CUB)
- Performance analysis tools

## Compilation Instructions

### Basic Compilation
```bash
cd runtime
mkdir build && cd build
cmake ..
make
```

### Compilation Options
- **MPI Support**: `cmake -DUSE_MPI=ON ..`
- **CUB Sorting**: `cmake -DUSE_CUB=ON ..` 
- **New Architecture**: `cmake -DCOMPILE_SM35=ON ..`
- **Debug Build**: `cmake -DCMAKE_BUILD_TYPE=Debug ..`

### MPI Compilation
```bash
cmake -DCMAKE_CXX_COMPILER=mpicxx ..
```

## Program Parameters

### Core Parameters
- `-h`    Show help information
- `-i`    Input snapshot filename
- `--dev` GPU device ID
- `-t`    Simulation timestep
- `-T`    Simulation end time
- `-e`    Softening parameter value
- `-o`    Opening angle (theta)
- `-r`    Tree rebuild frequency

### Output Control
- `--snapname` Snapshot base name
- `--snapiter` Snapshot iteration count
- `--log`      Enable log output
- `--logfile`  Kernel timing information file

### Example Usage
```bash
# Single GPU execution
./bonsai2_slowdust -i input.tipsy -t 0.01 -T 1.0 -e 0.05 -o 0.8

# MPI parallel execution
mpiexec -n 4 ./bonsai2_slowdust -i input.tipsy -t 0.01 -T 1.0
```

## License

Copyright [2010-2017] 
  Jeroen Bédorf <jeroen@bedorf.net>
  Evghenii Gaburov <egaburov@dds.nl>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this code except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
