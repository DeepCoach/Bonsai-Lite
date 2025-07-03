# Bonsai-Lite Makefile
# Based on CMakeLists.txt configuration
# Optimized for Linux systems with CUDA support

# ========================================
# 配置选项 (Configuration Options)
# ========================================

# 加载用户配置文件
-include build.config

# ========================================
# 编译选项配置 (Compilation Options)
# ========================================

# MPI支持选项 (MPI Support Options)
USE_MPI         ?= 1     # 启用MPI支持
USE_MPIMT       ?= 1     # 启用多线程MPI支持 (需要USE_MPI=1)

# CUDA算法选项 (CUDA Algorithm Options)
USE_THRUST      ?= 0     # 使用Thrust进行排序
USE_CUB         ?= 1     # 使用CUB进行排序 (推荐)

# 渲染和可视化选项 (已移除 - Rendering options removed)
# USE_DUST      - 已移除尘埃渲染功能
# USE_GALACTICS - 已移除Galactics初始条件生成器

# CUDA架构选项 (CUDA Architecture Options)
# 注意：SM_20(Fermi)架构已从CUDA 11.0开始被完全废弃
# 现代GPU(2012年后)都支持SM35+架构
COMPILE_SM35    ?= 1     # 启用现代架构编译 (SM35+，默认开启)

# 调试选项 (Debug Options - 对应 CMakeLists.txt)
CUDA_VERBOSE_PTXAS     ?= 0    # PTXAS详细输出 (-DCUDA_VERBOSE_PTXAS=ON)
CUDA_DEVICE_DEBUGGING  ?= 0    # CUDA设备调试 (-DCUDA_DEVICE_DEBUGGING=ON)
CUDA_KEEP_INTERMEDIATE ?= 0    # 保留中间文件 (-DCUDA_KEEP_INTERMEDIATE_FILES=ON)

# 构建类型 (对应 CMakeLists.txt 的 CMAKE_BUILD_TYPE)
CMAKE_BUILD_TYPE       ?= Release  # Release, Debug, RelWithDebInfo
INTERPROCEDURAL_OPT    ?= 0         # 链接时优化 (LTO)

# 向后兼容 (Legacy compatibility)
DEBUG ?= 0    # 传统DEBUG=1等同于CMAKE_BUILD_TYPE=Debug

# 构建选项
KEEP_BUILD_FILES       ?= 0    # 保留构建中间文件
OUTPUT_DIR             ?=      # 用户指定输出目录

# ========================================
# 编译器和路径设置 (Compiler and Path Settings)
# ========================================

# 编译器配置变量 (类似 CMAKE_CXX_COMPILER)
CMAKE_CXX_COMPILER ?= mpicxx  # 默认使用 MPI 编译器，类似 -DCMAKE_CXX_COMPILER=mpicxx
CMAKE_C_COMPILER   ?= mpicc   # 对应的 C 编译器
NVCC := nvcc

# 编译器选择逻辑 (对应 CMakeLists.txt 的编译器检测)
ifeq ($(USE_MPI), 1)
    # 优先级：用户指定 > 环境变量 > 系统默认
    DETECTED_MPICXX := $(shell which $(CMAKE_CXX_COMPILER) 2>/dev/null || which $$MPICXX 2>/dev/null || which mpicxx 2>/dev/null || which mpiCC 2>/dev/null || which mpic++ 2>/dev/null)
    ifneq ($(DETECTED_MPICXX),)
        CXX := $(DETECTED_MPICXX)
        # 测试MPI编译器是否工作
        MPI_WORKS := $(shell echo 'int main(){return 0;}' | $(CXX) -x c++ - -o /tmp/mpi_$$$$_$(shell date +%s) 2>/dev/null && rm -f /tmp/mpi_$$$$_* && echo 1 || echo 0)
        ifeq ($(MPI_WORKS), 0)
            $(warning MPI compiler $(CXX) failed, falling back to g++)
            CXX := g++
            USE_MPI := 0
        else
            $(info Using MPI compiler: $(CXX))
        endif
    else
        $(warning No MPI compiler found, disabling MPI support)
        CXX := g++
        USE_MPI := 0
    endif
else
    CXX := g++
    $(info Using standard C++ compiler: $(CXX))
endif

# CUDA 和 OpenMP 依赖检测 (对应 FIND_PACKAGE)
CUDA_PATH := $(shell dirname $(shell dirname $(shell which nvcc 2>/dev/null)) 2>/dev/null || echo /usr/local/cuda)
CUDA_FOUND := $(shell test -d $(CUDA_PATH) && which nvcc >/dev/null 2>&1 && test -f $(CUDA_PATH)/include/cuda_runtime.h && echo 1 || echo 0)
OPENMP_FOUND := $(shell echo 'int main(){return 0;}' | $(CXX) -fopenmp -x c++ - -o /tmp/omp_$$$$_$(shell date +%s) 2>/dev/null && rm -f /tmp/omp_$$$$_* && echo 1 || echo 0)

ifeq ($(CUDA_FOUND), 0)
    $(error CUDA toolkit not found. Please install CUDA)
endif

# 设置 OpenMP 标志
OPENMP_FLAGS := $(if $(filter 1,$(OPENMP_FOUND)),-fopenmp)
OPENMP_LIBS := $(if $(filter 1,$(OPENMP_FOUND)),-lgomp)

# 项目目录
SRC_DIR := src
INCLUDE_DIR := include
CUDA_KERNELS_DIR := CUDAkernels
PROFILING_DIR := profiling

# 构建目录设置
ifeq ($(OUTPUT_DIR),)
    # 默认构建在当前目录
    BUILD_DIR := build
    BIN_DIR := .
else
    # 用户指定输出目录
    BUILD_DIR := $(OUTPUT_DIR)/build
    BIN_DIR := $(OUTPUT_DIR)
endif

OBJ_DIR := $(BUILD_DIR)/obj
CUDA_OBJ_DIR := $(BUILD_DIR)/cuda_obj

# ========================================
# 编译标志设置 (Compilation Flags - 对应 add_definitions)
# ========================================

# 基础定义 (对应 CMakeLists.txt 的 add_definitions)
DEFINES := -std=c++14 -DTIPSYOUTPUT
CUDA_DEFINES := $(DEFINES)

# MPI 定义 (对应 CMakeLists.txt 的 MPI 设置)
ifeq ($(USE_MPI), 1)
    DEFINES += -DUSE_MPI -fPIE -Wno-main
    CUDA_DEFINES += -DUSE_MPI
    EXTRA_MPI_LINK_FLAGS := -pie -rdynamic
    ifeq ($(USE_MPIMT), 1)
        DEFINES += -D_MPIMT
        CUDA_DEFINES += -D_MPIMT
    endif
else
    EXTRA_MPI_LINK_FLAGS :=
endif

# CUDA算法定义和Debug安全选项
DEFINES += $(if $(filter 1,$(USE_THRUST)),-DUSE_THRUST)
DEFINES += $(if $(filter 1,$(USE_CUB)),-DUSE_CUB)
CUDA_DEFINES += $(if $(filter 1,$(USE_THRUST)),-DUSE_THRUST)
CUDA_DEFINES += $(if $(filter 1,$(USE_CUB)),-DUSE_CUB)

# Debug模式下的CUDA安全选项 (对应 CMakeLists.txt 的调试配置)
# 向后兼容：DEBUG=1 自动设置 CMAKE_BUILD_TYPE=Debug
ifeq ($(strip $(DEBUG)), 1)
    CMAKE_BUILD_TYPE := Debug
endif

# 根据构建类型设置CUDA安全选项
ifeq ($(CMAKE_BUILD_TYPE), Debug)
    CUDA_DEFINES += -DCUDA_API_PER_THREAD_DEFAULT_STREAM
    CUDA_DEBUG_SAFETY := -DDEBUG_CUDA_MEMORY
else
    CUDA_DEBUG_SAFETY :=
endif

# Kepler 架构支持
ifeq ($(COMPILE_SM35), 1)
    DEFINES += -DKEPLER
    CUDA_DEFINES += -DKEPLER
endif

# 编译器标志 (对应 CMakeLists.txt 的构建类型)
CXXFLAGS := -Wall -fPIC $(OPENMP_FLAGS)
CXXFLAGS += $(if $(filter Debug,$(CMAKE_BUILD_TYPE)),-O0 -g -DDEBUG)
CXXFLAGS += $(if $(filter RelWithDebInfo,$(CMAKE_BUILD_TYPE)),-O2 -g -DNDEBUG)
CXXFLAGS += $(if $(filter Release,$(CMAKE_BUILD_TYPE)),-O3 -g -DNDEBUG)
CXXFLAGS += $(if $(filter 1,$(INTERPROCEDURAL_OPT)),-flto)
CXXFLAGS += $(if $(filter x86_64,$(shell uname -m)),-msse4 -march=native)

# 包含路径
INCLUDES := -I$(INCLUDE_DIR) -I$(CUDA_PATH)/include -I$(PROFILING_DIR)

# 链接设置
LDFLAGS := -L$(CUDA_PATH)/lib64 $(OPENMP_FLAGS) $(EXTRA_MPI_LINK_FLAGS)
LDFLAGS += $(if $(filter 1,$(INTERPROCEDURAL_OPT)),-flto)
LIBS := -lcudart -lcuda -lrt $(OPENMP_LIBS) -ldl

# ========================================
# CUDA 版本检测和架构自动选择 (CUDA Version Detection & Architecture Auto-Selection)
# ========================================

# 检测CUDA版本
CUDA_VERSION := $(shell $(NVCC) --version 2>/dev/null | grep "release" | sed 's/.*release \([0-9]\+\.[0-9]\+\).*/\1/' | head -1)
CUDA_MAJOR := $(shell echo $(CUDA_VERSION) | cut -d. -f1)
CUDA_MINOR := $(shell echo $(CUDA_VERSION) | cut -d. -f2)

# 检测当前GPU架构（如果可用）
GPU_COMPUTE_CAP := $(shell nvidia-smi --query-gpu=compute_cap --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d '.')

# 定义架构映射
define CUDA_ARCH_MAPPING
  # CUDA 12.8+ 优化架构选择
  ifeq ($(shell [ "$(CUDA_MAJOR)" -gt "12" -o \( "$(CUDA_MAJOR)" -eq "12" -a "$(CUDA_MINOR)" -ge "8" \) ] && echo 1), 1)
    CUDA_ARCH_LEVEL := MODERN_PLUS
  # CUDA 12.0-12.7
  else ifeq ($(shell [ "$(CUDA_MAJOR)" -eq "12" ] && echo 1), 1)
    CUDA_ARCH_LEVEL := MODERN
  # CUDA 11.x
  else ifeq ($(shell [ "$(CUDA_MAJOR)" -eq "11" ] && echo 1), 1)
    CUDA_ARCH_LEVEL := LEGACY
  # CUDA 10.x 及更早
  else
    CUDA_ARCH_LEVEL := VERY_LEGACY
  endif
endef

$(eval $(CUDA_ARCH_MAPPING))

# CUDA架构设置 (Architecture Selection)
ifeq ($(strip $(COMPILE_SM35)), 1)
    # 根据CUDA版本和GPU能力自动选择架构
    ifeq ($(CUDA_ARCH_LEVEL), MODERN_PLUS)
        # CUDA 12.8+ 完整现代架构支持 (SM70+ recommended)
        GENCODE := -gencode arch=compute_70,code=sm_70 \
                   -gencode arch=compute_75,code=sm_75 \
                   -gencode arch=compute_80,code=sm_80 \
                   -gencode arch=compute_86,code=sm_86 \
                   -gencode arch=compute_87,code=sm_87 \
                   -gencode arch=compute_89,code=sm_89 \
                   -gencode arch=compute_90,code=sm_90 \
                   -gencode arch=compute_90,code=compute_90
        ARCH_INFO := "CUDA $(CUDA_VERSION) - 完整现代架构 SM70-SM90"
    else ifeq ($(CUDA_ARCH_LEVEL), MODERN)
        # CUDA 12.0-12.7 现代架构支持
        GENCODE := -gencode arch=compute_70,code=sm_70 \
                   -gencode arch=compute_75,code=sm_75 \
                   -gencode arch=compute_80,code=sm_80 \
                   -gencode arch=compute_86,code=sm_86 \
                   -gencode arch=compute_87,code=sm_87 \
                   -gencode arch=compute_86,code=compute_86
        ARCH_INFO := "CUDA $(CUDA_VERSION) - 现代架构 SM70-SM87"
    else ifeq ($(CUDA_ARCH_LEVEL), LEGACY)
        # CUDA 11.x 兼容架构
        GENCODE := -gencode arch=compute_50,code=sm_50 \
                   -gencode arch=compute_60,code=sm_60 \
                   -gencode arch=compute_70,code=sm_70 \
                   -gencode arch=compute_75,code=sm_75 \
                   -gencode arch=compute_80,code=sm_80 \
                   -gencode arch=compute_86,code=sm_86 \
                   -gencode arch=compute_86,code=compute_86
        ARCH_INFO := "CUDA $(CUDA_VERSION) - 兼容架构 SM50-SM86"
    else
        # CUDA 10.x 及更早版本
        GENCODE := -gencode arch=compute_35,code=sm_35 \
                   -gencode arch=compute_50,code=sm_50 \
                   -gencode arch=compute_60,code=sm_60 \
                   -gencode arch=compute_70,code=sm_70
        ARCH_INFO := "CUDA $(CUDA_VERSION) - 传统架构 SM35-SM70"
    endif
    DEFINES += -DKEPLER
    CUDA_DEFINES += -DKEPLER
else
    # 保守现代架构支持 (COMPILE_SM35=0)
    ifeq ($(CUDA_ARCH_LEVEL), MODERN_PLUS)
        GENCODE := -gencode arch=compute_70,code=sm_70 \
                   -gencode arch=compute_75,code=sm_75 \
                   -gencode arch=compute_80,code=sm_80 \
                   -gencode arch=compute_86,code=sm_86 \
                   -gencode arch=compute_86,code=compute_86
        ARCH_INFO := "CUDA $(CUDA_VERSION) - 保守现代架构 SM70-SM86"
        $(warning 使用保守现代CUDA架构 (SM70+) 以确保CUDA $(CUDA_VERSION)最佳兼容性)
    else
        GENCODE := -gencode arch=compute_50,code=sm_50 \
                   -gencode arch=compute_60,code=sm_60 \
                   -gencode arch=compute_70,code=sm_70
        ARCH_INFO := "CUDA $(CUDA_VERSION) - 基础现代架构 SM50-SM70"
    endif
endif

# GPU特定优化（如果检测到特定GPU）
ifneq ($(GPU_COMPUTE_CAP),)
    # RTX 4090/A100/H100 (SM89/90)
    ifeq ($(shell [ "$(GPU_COMPUTE_CAP)" -ge "89" ] && echo 1), 1)
        GPU_INFO := "检测到现代GPU SM$(GPU_COMPUTE_CAP) - 使用最新架构优化"
    # RTX 30/40系列 (SM86/87)
    else ifeq ($(shell [ "$(GPU_COMPUTE_CAP)" -ge "86" ] && echo 1), 1)
        GPU_INFO := "检测到Ampere/Ada GPU SM$(GPU_COMPUTE_CAP) - 使用现代架构优化"
    # GTX 16/RTX 20系列 (SM75)
    else ifeq ($(shell [ "$(GPU_COMPUTE_CAP)" -ge "75" ] && echo 1), 1)
        GPU_INFO := "检测到Turing GPU SM$(GPU_COMPUTE_CAP) - 使用Turing优化"
    # GTX 10系列/Tesla V100 (SM70)
    else ifeq ($(shell [ "$(GPU_COMPUTE_CAP)" -ge "70" ] && echo 1), 1)
        GPU_INFO := "检测到Volta GPU SM$(GPU_COMPUTE_CAP) - 使用Volta优化"
    else
        GPU_INFO := "检测到传统GPU SM$(GPU_COMPUTE_CAP) - 使用基础优化"
    endif
else
    GPU_INFO := "未检测到GPU信息 - 使用通用架构设置"
endif

# CUDA 编译标志设置 (对应 CMakeLists.txt 的 CUDA 选项)
# 基础标志
NVCCFLAGS_BASE := -std=c++14 -Xcompiler="-fPIC"

# CUDA 调试标志设置 (完全对应 CMakeLists.txt 逻辑)
ifeq ($(strip $(CUDA_DEVICE_DEBUGGING)), 1)
    # CUDA_DEVICE_DEBUGGING=ON 对应 CMakeLists.txt 的 DEVICE_DEBUGGING = -G
    CUDA_DEBUG_FLAG := -G
else
    # 默认使用 lineinfo (对应 CMakeLists.txt GENCODE 中的 -lineinfo)
    CUDA_DEBUG_FLAG := -lineinfo
endif

# 构建最终的NVCCFLAGS
NVCCFLAGS := $(NVCCFLAGS_BASE) $(CUDA_DEBUG_FLAG)
NVCCFLAGS += $(if $(filter 1,$(CUDA_VERBOSE_PTXAS)),--ptxas-options=-v)
NVCCFLAGS += $(if $(filter 1,$(CUDA_KEEP_INTERMEDIATE)),-keep)
NVCCFLAGS += $(GENCODE) $(INCLUDES) $(CUDA_DEFINES) $(CUDA_DEBUG_SAFETY)

# ========================================
# 源文件定义 (Source Files Definition)
# ========================================

# C++源文件
CCFILES := build.cpp compute_properties.cpp gpu_iterate.cpp libraryInterface.cpp \
           load_kernels.cpp main.cpp anyoption.cpp octree.cpp parallel.cpp \
           sort_bodies_gpu.cpp log.cpp hostConstruction.cpp tipsyIO.cpp

# CUDA内核文件 (基础内核)
CUFILES_BASE := build_tree.cu compute_propertiesD.cu parallel.cu sortKernels.cu \
                scanKernels.cu timestep.cu depthSort.cu dev_direct_gravity.cu

# 根据架构选择特定的重力计算内核
ifeq ($(strip $(COMPILE_SM35)), 1)
    # SM35+ 现代架构使用 warp_new 内核
    CUFILES := $(CUFILES_BASE) dev_approximate_gravity_warp_new.cu
else
    # SM20 旧架构使用 fermi 内核
    CUFILES := $(CUFILES_BASE) dev_approximate_gravity_warp_fermi.cu
endif

# ========================================
# 目标文件定义 (Object Files Definition)
# ========================================

BINARY_NAME := bonsai2_slowdust
BINARY_PATH := $(BIN_DIR)/$(BINARY_NAME)

CXX_OBJECTS := $(CCFILES:%.cpp=$(OBJ_DIR)/%.o)
CUDA_OBJECTS := $(CUFILES:%.cu=$(CUDA_OBJ_DIR)/%.o)
ALL_OBJECTS := $(CXX_OBJECTS) $(CUDA_OBJECTS)

# ========================================
# 编译规则 (Build Rules)
# ========================================

.PHONY: all clean distclean help test install check-deps show-config debug debug-device copy-test-data test-arch test-debug-modes

# 默认目标
all: check-deps copy-test-data $(BINARY_PATH)
	$(if $(filter 0,$(KEEP_BUILD_FILES)),@rm -rf $(BUILD_DIR) && echo "Cleaned intermediate files")

# 主可执行文件
$(BINARY_PATH): $(ALL_OBJECTS)
	@echo "Linking $@..."
	@mkdir -p $(dir $@)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS)
	@echo "Build complete: $@"

# C++编译规则
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(dir $@)
	@echo "Compiling C++: $<"
	$(CXX) $(CXXFLAGS) $(INCLUDES) $(DEFINES) -c $< -o $@

# CUDA编译规则
$(CUDA_OBJ_DIR)/%.o: $(CUDA_KERNELS_DIR)/%.cu
	@mkdir -p $(dir $@)
	@echo "Compiling CUDA: $<"
	$(NVCC) $(NVCCFLAGS) -c $< -o $@

# ========================================
# 实用工具目标 (Utility Targets)
# ========================================

# 依赖检查
check-deps:
	@echo "Checking dependencies..."
	@which $(CXX) >/dev/null || (echo "Error: C++ compiler $(CXX) not found"; exit 1)
	@which $(NVCC) >/dev/null || (echo "Error: CUDA compiler not found"; exit 1)
	@test -d $(CUDA_PATH) || (echo "Error: CUDA path $(CUDA_PATH) not found"; exit 1)
	@echo "Dependencies OK"
	@echo "===========================================" 
	@echo "Build Configuration:"
	@echo "  Target: $(BINARY_NAME)"
	@echo "  Output: $(BINARY_PATH)"
	@echo "  MPI: $(USE_MPI), CUDA SM35+: $(COMPILE_SM35), Build Type: $(CMAKE_BUILD_TYPE)"
	@echo "  $(ARCH_INFO)"
	@echo "  $(GPU_INFO)"
	@echo "==========================================="

# 复制测试数据 (对应 CMakeLists.txt 的 file(COPY) 命令)
copy-test-data:
	@echo "Copying test data files..."
	@if [ -f "../inputExamples/model3_child_compact.tipsy" ]; then \
		cp "../inputExamples/model3_child_compact.tipsy" "$(BIN_DIR)/" && \
		echo "✓ Copied model3_child_compact.tipsy to $(BIN_DIR)/"; \
	else \
		echo "⚠ Warning: Test data file ../inputExamples/model3_child_compact.tipsy not found"; \
	fi
	@if [ -d "../inputExamples" ]; then \
		for file in ../inputExamples/*.txt ../inputExamples/galactics_*; do \
			if [ -f "$$file" ]; then \
				cp "$$file" "$(BIN_DIR)/" 2>/dev/null && \
				echo "✓ Copied $$(basename $$file) to $(BIN_DIR)/"; \
			fi; \
		done; \
	fi

# 清理编译文件
clean:
	@echo "Cleaning build files..."
	@rm -rf $(BUILD_DIR) $(if $(filter .,$(BIN_DIR)),,$(BINARY_PATH))
	@echo "Clean complete"

# 完全清理
distclean: clean
	@rm -f *.log *.out core core.*

# 调试版本 (对应 CMakeLists.txt 的 DEBUG 构建)
debug:
	@echo "Building with CMAKE_BUILD_TYPE=Debug..."
	@$(MAKE) CMAKE_BUILD_TYPE=Debug all

# 设备调试版本 (对应 CMakeLists.txt 的 CUDA_DEVICE_DEBUGGING)
debug-device:
	@echo "Building with CMAKE_BUILD_TYPE=Debug and CUDA_DEVICE_DEBUGGING=1..."
	@$(MAKE) CMAKE_BUILD_TYPE=Debug CUDA_DEVICE_DEBUGGING=1 all

# 测试编译和基本功能
test: $(BINARY_PATH)
	@echo "=== Testing Binary ==="
	@echo "Binary location: $(BINARY_PATH)"
	@ls -lh $(BINARY_PATH) || (echo "Error: Binary not found"; exit 1)
	@echo "Testing help output..."
	@$(BINARY_PATH) --help >/dev/null 2>&1 && echo "✓ Help test passed" || echo "✗ Help test failed"
	@echo "Testing version info..."
	@$(BINARY_PATH) --version >/dev/null 2>&1 && echo "✓ Version test passed" || echo "✓ Version test skipped (no --version flag)"
	@echo "Testing CUDA initialization..."
	@$(BINARY_PATH) --listDevice >/dev/null 2>&1 && echo "✓ CUDA device test passed" || echo "✗ CUDA device test failed (check GPU)"
	@echo "=== All tests completed ==="

# 安装
install: $(BINARY_PATH)
	@mkdir -p $(HOME)/bin
	@cp $(BINARY_PATH) $(HOME)/bin/
	@echo "Installed to $(HOME)/bin/$(BINARY_NAME)"

# 显示配置
show-config:
	@echo "Current build configuration:"
	@echo "  Binary: $(BINARY_PATH)"
	@echo "  Build dir: $(BUILD_DIR)"
	@echo "  Build type: $(CMAKE_BUILD_TYPE)"
	@echo "  CMAKE_CXX_COMPILER: $(CMAKE_CXX_COMPILER)"
	@echo "  Active compiler: $(CXX)"
	@echo "  CUDA: $(CUDA_PATH) (v$(CUDA_VERSION))"
	@echo "  OpenMP: $(if $(filter 1,$(OPENMP_FOUND)),Enabled,Disabled)"
	@echo "  MPI: $(USE_MPI), MPIMT: $(USE_MPIMT)"
	@echo "  Algorithms: CUB=$(USE_CUB), Thrust=$(USE_THRUST)"
	@echo "  CUDA Device Debug: $(CUDA_DEVICE_DEBUGGING), Keep files: $(KEEP_BUILD_FILES)"
	@echo "  LTO: $(INTERPROCEDURAL_OPT)"
	@echo "  Architecture: $(ARCH_INFO)"
	@echo "  GPU Info: $(GPU_INFO)"
	@echo "  CUDA kernels: $(CUFILES)"
	@echo "  Generated architectures: $(GENCODE)"
	@echo "  CUDA debug flag: $(CUDA_DEBUG_FLAG)"
	@echo "  CUDA safety options: $(CUDA_DEBUG_SAFETY)"
	@echo "  Full NVCCFLAGS: $(NVCCFLAGS)"

# 帮助信息
help:
	@echo "Bonsai-Lite Makefile - Simplified version of the Bonsai project's Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  all           - Build the main executable (default)"
	@echo "  copy-test-data - Copy test data files to build directory"
	@echo "  clean         - Remove build files"
	@echo "  distclean     - Complete cleanup"
	@echo "  test          - Build and test binary"
	@echo "  test-arch     - Test CUDA architecture detection"
	@echo "  test-debug-modes - Test different debug compilation modes"
	@echo "  install       - Install binary to ~/bin"
	@echo "  debug         - Debug build (CMAKE_BUILD_TYPE=Debug)"
	@echo "  debug-device  - Debug with CUDA device debugging"
	@echo "  show-config   - Show current configuration"
	@echo "  help          - Show this help"
	@echo ""
	@echo "Configuration options:"
	@echo "  CMAKE_CXX_COMPILER=<compiler> - C++ compiler (default: mpicxx)"
	@echo "  CMAKE_C_COMPILER=<compiler>   - C compiler (default: mpicc)"
	@echo "  CMAKE_BUILD_TYPE=<type>       - Build type: Release, Debug, RelWithDebInfo"
	@echo "  CUDA_DEVICE_DEBUGGING=1      - Enable CUDA device debugging (-G flag)"
	@echo "  CUDA_VERBOSE_PTXAS=1          - Enable verbose PTXAS output"
	@echo "  CUDA_KEEP_INTERMEDIATE=1      - Keep intermediate CUDA files"
	@echo "  OUTPUT_DIR=<path>             - Output directory (default: current)"
	@echo "  INTERPROCEDURAL_OPT=1         - Enable link-time optimization (LTO)"
	@echo "  KEEP_BUILD_FILES=1            - Keep intermediate files"
	@echo "  USE_MPI=0                     - Disable MPI"
	@echo "  COMPILE_SM35=1                - Full modern GPU support (auto-detected)"
	@echo "  DEBUG=1                       - Legacy mode (same as CMAKE_BUILD_TYPE=Debug)"
	@echo ""
	@echo "Debug Modes (matching CMakeLists.txt):"
	@echo "  1. Build debug configuration:"
	@echo "     make CMAKE_BUILD_TYPE=Debug           # Debug build with symbols"
	@echo "     make debug                            # Shortcut for above"
	@echo "  2. CUDA device debugging:"
	@echo "     make CUDA_DEVICE_DEBUGGING=1         # Enable -G flag"
	@echo "     make debug-device                     # Debug + device debugging"
	@echo "  3. Combined:"
	@echo "     make CMAKE_BUILD_TYPE=Debug CUDA_DEVICE_DEBUGGING=1"
	@echo ""
	@echo "Dependency detection:"
	@echo "  • Automatic CUDA toolkit detection and validation"
	@echo "  • OpenMP support detection and configuration"
	@echo "  • MPI compiler detection and testing"
	@echo ""
	@echo "CUDA Architecture Auto-Detection:"
	@echo "  • CUDA 12.8+: SM70-SM90 full support"
	@echo "  • CUDA 12.0-12.7: SM70-SM87 support"
	@echo "  • CUDA 11.x: SM50-SM86 compatibility"
	@echo "  • Auto-detects RTX 3090 (SM86) for optimal performance"
	@echo ""
	@echo "Examples:"
	@echo "  make                                      # Auto-detect optimal build"
	@echo "  make CMAKE_CXX_COMPILER=g++               # Use g++ instead of MPI compiler"
	@echo "  make CMAKE_CXX_COMPILER=mpicxx USE_MPI=1  # Explicit MPI compiler"
	@echo "  make CMAKE_BUILD_TYPE=Debug               # Debug build with symbols"
	@echo "  make CMAKE_BUILD_TYPE=RelWithDebInfo      # Optimized with debug info"
	@echo "  make debug                                # Quick debug build"
	@echo "  make debug-device                         # Debug with CUDA device debugging"
	@echo "  make INTERPROCEDURAL_OPT=1                # Link-time optimization"
	@echo "  make OUTPUT_DIR=./dist                    # Build to dist directory"
	@echo "  make -j8                                  # Parallel build"
	@echo "  make test-arch                            # Test architecture detection"

# 测试智能架构检测
test-arch:
	@echo "=== 智能CUDA架构检测测试 ==="
	@echo "CUDA版本: $(CUDA_VERSION) (主版本: $(CUDA_MAJOR).$(CUDA_MINOR))"
	@echo "检测到的GPU: SM$(GPU_COMPUTE_CAP)"
	@echo "架构等级: $(CUDA_ARCH_LEVEL)"
	@echo "COMPILE_SM35: $(COMPILE_SM35)"
	@echo "选择的内核: $(CUFILES)"
	@echo "生成的架构: $(GENCODE)"
	@echo "=================================="

# 测试不同的debug编译模式
test-debug-modes:
	@echo "=== Debug编译模式测试 (对应 CMakeLists.txt) ==="
	@echo ""
	@echo "1. 标准构建 (CMAKE_BUILD_TYPE=Release):"
	@$(MAKE) CMAKE_BUILD_TYPE=Release show-config | grep -E "(Build type|CUDA device flags|CUDA build flags)"
	@echo ""
	@echo "2. Debug构建 (CMAKE_BUILD_TYPE=Debug):"
	@$(MAKE) CMAKE_BUILD_TYPE=Debug show-config | grep -E "(Build type|CUDA device flags|CUDA build flags)"
	@echo ""
	@echo "3. CUDA设备调试 (CUDA_DEVICE_DEBUGGING=1):"
	@$(MAKE) CUDA_DEVICE_DEBUGGING=1 show-config | grep -E "(Build type|CUDA device flags|CUDA build flags)"
	@echo ""
	@echo "4. 完整调试 (CMAKE_BUILD_TYPE=Debug + CUDA_DEVICE_DEBUGGING=1):"
	@$(MAKE) CMAKE_BUILD_TYPE=Debug CUDA_DEVICE_DEBUGGING=1 show-config | grep -E "(Build type|CUDA device flags|CUDA build flags)"
	@echo ""
	@echo "5. RelWithDebInfo (CMAKE_BUILD_TYPE=RelWithDebInfo):"
	@$(MAKE) CMAKE_BUILD_TYPE=RelWithDebInfo show-config | grep -E "(Build type|CUDA device flags|CUDA build flags)"
	@echo "=================================================="

# 并行编译优化
.NOTPARALLEL: check-deps

# 确保目录依赖
$(CXX_OBJECTS): | $(OBJ_DIR)
$(CUDA_OBJECTS): | $(CUDA_OBJ_DIR)
$(OBJ_DIR) $(CUDA_OBJ_DIR):
	@mkdir -p $@
