# Bonsai-Lite Makefile
# Based on CMakeLists.txt configuration
# Generated for Linux systems with CUDA support

# ========================================
# 配置文件加载 (Configuration File Loading)
# ========================================

# 如果存在 build.config 文件，则加载配置
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

# 调试选项 (Debug Options)
CUDA_VERBOSE_PTXAS     ?= 0    # PTXAS详细输出
CUDA_DEVICE_DEBUGGING  ?= 0    # CUDA设备调试
CUDA_KEEP_INTERMEDIATE ?= 0    # 保留中间文件
DEBUG                  ?= 0    # 调试模式

# 构建清理选项 (Build cleanup options)
KEEP_BUILD_FILES       ?= 0    # 保留构建中间文件 (默认: 0 - 不保留)

# 单线程单节点选项 (Single-threaded single-node option)
SINGLE_NODE     ?= 0     # 完全单线程单节点模式 (禁用所有并行化)

# ========================================
# 编译器设置 (Compiler Settings)
# ========================================

# 基础编译器
CXX := g++
CC  := gcc
NVCC := nvcc

# 检测MPI编译器
ifeq ($(USE_MPI), 1)
    ifneq ($(SINGLE_NODE), 1)
        # 尝试查找MPI编译器
        MPICXX := $(shell which mpicxx 2>/dev/null || which mpiCC 2>/dev/null || echo "mpicxx")
        ifeq ($(shell which $(MPICXX) 2>/dev/null),)
            $(warning MPI compiler not found, falling back to g++)
            MPICXX := g++
            USE_MPI := 0
        else
            CXX := $(MPICXX)
        endif
    else
        USE_MPI := 0  # 单节点模式下强制禁用MPI
    endif
endif

# ========================================
# 路径设置 (Path Settings)
# ========================================

# CUDA路径
CUDA_PATH := /usr/local/cuda
ifeq ($(wildcard $(CUDA_PATH)),)
    CUDA_PATH := /opt/cuda
    ifeq ($(wildcard $(CUDA_PATH)),)
        CUDA_PATH := $(shell dirname $(shell dirname $(shell which nvcc 2>/dev/null)) 2>/dev/null || echo "/usr/local/cuda")
    endif
endif

# 项目路径
SRC_DIR := src
INCLUDE_DIR := include
CUDA_KERNELS_DIR := CUDAkernels
PROFILING_DIR := profiling

# 支持自定义输出目录 (Custom output directory support)
OUTPUT_DIR ?= .                # 默认输出到当前目录

# 根据OUTPUT_DIR设置构建目录 (Set build directory based on OUTPUT_DIR)
# 当指定OUTPUT_DIR时，构建目录完全独立，不使用默认的build目录
ifeq ($(OUTPUT_DIR), .)
    BUILD_DIR := build
    OBJ_DIR := $(BUILD_DIR)/obj
    CUDA_OBJ_DIR := $(BUILD_DIR)/cuda_obj
else
    # 在指定的输出目录下创建独立的构建结构
    BUILD_DIR := $(OUTPUT_DIR)/.build
    OBJ_DIR := $(BUILD_DIR)/obj
    CUDA_OBJ_DIR := $(BUILD_DIR)/cuda_obj
endif

# ========================================
# 编译标志设置 (Compilation Flags)
# ========================================

# C++标准和优化标志
CXXFLAGS := -std=c++14 -O3 -g -Wall -fPIC
ifeq ($(DEBUG), 1)
    CXXFLAGS := -std=c++14 -O0 -g -Wall -fPIC -DDEBUG
endif

# 包含路径
INCLUDES := -I$(INCLUDE_DIR) -I$(CUDA_PATH)/include -I$(PROFILING_DIR)

# 预处理器定义
DEFINES := -DTIPSYOUTPUT
CUDA_DEFINES := -DTIPSYOUTPUT

# 架构特定优化
ARCH := $(shell uname -m)
ifeq ($(ARCH), x86_64)
    CXXFLAGS += -msse4 -march=native
endif

# MPI相关设置
ifeq ($(USE_MPI), 1)
    DEFINES += -DUSE_MPI
    CUDA_DEFINES += -DUSE_MPI
    CXXFLAGS += -fPIE -Wno-main
    EXTRA_LINK_FLAGS += -pie -rdynamic
    ifeq ($(USE_MPIMT), 1)
        DEFINES += -D_MPIMT
        CUDA_DEFINES += -D_MPIMT
    endif
else
    ifeq ($(SINGLE_NODE), 1)
        DEFINES += -DSINGLE_NODE
        CUDA_DEFINES += -DSINGLE_NODE
    endif
endif

# CUDA算法选择
ifeq ($(USE_THRUST), 1)
    DEFINES += -DUSE_THRUST
    CUDA_DEFINES += -DUSE_THRUST
    INCLUDES += -I$(CUDA_PATH)/../../thrust
endif

ifeq ($(USE_CUB), 1)
    DEFINES += -DUSE_CUB
    CUDA_DEFINES += -DUSE_CUB
endif

# OpenMP支持 (单节点模式下可选择禁用)
ifneq ($(SINGLE_NODE), 1)
    CXXFLAGS += -fopenmp
    EXTRA_LINK_FLAGS += -fopenmp
else
    # 单节点模式可选择禁用OpenMP以实现完全单线程
    # CXXFLAGS += -fopenmp  # 注释掉以禁用OpenMP
endif

# ========================================
# CUDA编译设置 (CUDA Compilation Settings)
# ========================================

# CUDA编译标志
NVCCFLAGS := -std=c++14 -O3 -lineinfo -Xcompiler="-fPIC"
ifeq ($(DEBUG), 1)
    NVCCFLAGS := -std=c++14 -O0 -g -G -lineinfo -Xcompiler="-fPIC"
endif

# CUDA架构设置 (支持SM50+现代架构，确保CUDA 12.8兼容性)
# 注意：SM_20-SM35架构在CUDA 12.8中兼容性有限，使用SM50+确保最佳兼容性
DEFINES += -DKEPLER
CUDA_DEFINES += -DKEPLER

# 根据COMPILE_SM35选项设置架构支持 (CUDA 12.8兼容，优化现代架构)
ifeq ($(COMPILE_SM35), 1)
    # 完整现代CUDA架构支持 (SM75+ recommended for CUDA 12.8)
    GENCODE := -gencode arch=compute_70,code=sm_70 \
               -gencode arch=compute_75,code=sm_75 \
               -gencode arch=compute_80,code=sm_80 \
               -gencode arch=compute_86,code=sm_86 \
               -gencode arch=compute_87,code=sm_87 \
               -gencode arch=compute_89,code=sm_89 \
               -gencode arch=compute_90,code=sm_90 \
               -gencode arch=compute_90,code=compute_90
else
    # 保守现代架构支持 (Volta+ SM70 and Ampere+ SM80/86 for best CUDA 12.8 compatibility)
    GENCODE := -gencode arch=compute_70,code=sm_70 \
               -gencode arch=compute_75,code=sm_75 \
               -gencode arch=compute_80,code=sm_80 \
               -gencode arch=compute_86,code=sm_86 \
               -gencode arch=compute_86,code=compute_86
    $(warning 使用优化现代CUDA架构 (SM70+) 以确保CUDA 12.8最佳兼容性)
endif

# CUDA调试选项
ifeq ($(CUDA_VERBOSE_PTXAS), 1)
    NVCCFLAGS += --ptxas-options=-v
endif

ifeq ($(CUDA_DEVICE_DEBUGGING), 1)
    NVCCFLAGS += -G
endif

ifeq ($(CUDA_KEEP_INTERMEDIATE), 1)
    NVCCFLAGS += -keep
endif

NVCCFLAGS += $(GENCODE) $(INCLUDES) $(CUDA_DEFINES)

# ========================================
# 链接设置 (Linking Settings)
# ========================================

# 基础链接库
LIBS := -lcudart -lcuda -lrt -ldl
LDFLAGS := -L$(CUDA_PATH)/lib64

# 链接标志
LDFLAGS += $(EXTRA_LINK_FLAGS)

# ========================================
# 源文件定义 (Source Files Definition)
# ========================================

# C++源文件
CCFILES := build.cpp \
           compute_properties.cpp \
           gpu_iterate.cpp \
           libraryInterface.cpp \
           load_kernels.cpp \
           main.cpp \
           anyoption.cpp \
           octree.cpp \
           parallel.cpp \
           sort_bodies_gpu.cpp \
           log.cpp \
           hostConstruction.cpp \
           tipsyIO.cpp

# 头文件
HFILES := my_cuda_rt.h \
          my_ocl.h \
          node_specs.h \
          octree.h \
          build.h \
          tipsydefs.h \
          vector_math.h \
          depthSort.h

# CUDA内核文件
CUFILES := build_tree.cu \
           compute_propertiesD.cu \
           parallel.cu \
           sortKernels.cu \
           scanKernels.cu \
           timestep.cu \
           depthSort.cu \
           dev_direct_gravity.cu

# 架构相关的CUDA文件 (使用现代CUDA版本)
# 注意：总是使用新版本以避免老旧texture API兼容性问题
CUFILES += dev_approximate_gravity_warp_new.cu

# 性能分析文件
PROFFILES := cuxTimer.h \
             cuxTimer_private.h \
             warp_functions.h \
             derived_atomic_functions.h \
             bonsai_timing.h

# ========================================
# 目标文件定义 (Object Files Definition)
# ========================================

# 确定可执行文件名和路径
BINARY_NAME := bonsai2_slowdust
BINARY_PATH := $(OUTPUT_DIR)/$(BINARY_NAME)

# C++目标文件
CXX_OBJECTS := $(CCFILES:%.cpp=$(OBJ_DIR)/%.o)

# CUDA目标文件
CUDA_OBJECTS := $(CUFILES:%.cu=$(CUDA_OBJ_DIR)/%.o)

# 所有目标文件
ALL_OBJECTS := $(CXX_OBJECTS) $(CUDA_OBJECTS)

# ========================================
# 编译规则 (Build Rules)
# ========================================

.PHONY: all clean distclean help test install check-deps

# 默认目标
all: check-deps $(BINARY_PATH)
ifneq ($(KEEP_BUILD_FILES), 1)
	@echo "Cleaning intermediate build files..."
	@rm -rf $(BUILD_DIR)
endif

# 主可执行文件
$(BINARY_PATH): $(ALL_OBJECTS)
	@echo "Linking $@..."
	@mkdir -p $(OUTPUT_DIR)
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
	@which $(CXX) > /dev/null || (echo "Error: C++ compiler $(CXX) not found"; exit 1)
	@which $(NVCC) > /dev/null || (echo "Error: NVIDIA CUDA compiler not found"; exit 1)
	@test -d $(CUDA_PATH) || (echo "Error: CUDA path $(CUDA_PATH) not found"; exit 1)
ifeq ($(USE_MPI), 1)
	@which $(MPICXX) > /dev/null || (echo "Error: MPI compiler $(MPICXX) not found"; exit 1)
endif
	@echo "All dependencies satisfied."

# 清理编译文件
clean:
	@echo "Cleaning build files..."
ifeq ($(OUTPUT_DIR), .)
	@echo "Cleaning default build directory..."
	rm -rf build
	rm -f $(BINARY_NAME)
else
	@echo "Cleaning output directory: $(OUTPUT_DIR)"
	rm -rf $(BUILD_DIR)
	rm -f $(BINARY_PATH)
endif

# 完全清理
distclean: clean
	@echo "Complete cleanup..."
	rm -f *.log *.out core core.*

# 测试编译
test: $(BINARY_PATH)
	@echo "Running basic test..."
	@if [ -f ../inputExamples/model3_child_compact.tipsy ]; then \
		echo "Test input file found"; \
		$(BINARY_PATH) --help > /dev/null 2>&1 && echo "Binary runs successfully" || echo "Binary execution failed"; \
	else \
		echo "Test input file not found, only checking binary execution"; \
		$(BINARY_PATH) --help > /dev/null 2>&1 && echo "Binary runs successfully" || echo "Binary execution failed"; \
	fi

# 安装 (可选)
install: $(BINARY_PATH)
	@echo "Installing $(BINARY_NAME)..."
	@mkdir -p $(HOME)/bin
	cp $(BINARY_PATH) $(HOME)/bin/
	@echo "Installed to $(HOME)/bin/$(BINARY_NAME)"

# 显示帮助
help:
	@echo "Bonsai-Lite Makefile - Available targets:"
	@echo ""
	@echo "  all           - Build the main executable (default)"
	@echo "  clean         - Remove build files"
	@echo "  distclean     - Complete cleanup"
	@echo "  test          - Build and run basic test"
	@echo "  install       - Install binary to ~/bin"
	@echo "  check-deps    - Check build dependencies"
	@echo "  help          - Show this help"
	@echo ""
	@echo "Configuration options (set as environment variables or make arguments):"
	@echo ""
	@echo "  OUTPUT_DIR=<path>        - Output directory for binary (default: current directory)"
	@echo "  KEEP_BUILD_FILES=1/0     - Keep intermediate build files (default: 0)"
	@echo "  USE_MPI=1/0              - Enable/disable MPI support (default: 1)"
	@echo "  USE_MPIMT=1/0            - Enable/disable multi-threaded MPI (default: 1)"
	@echo "  USE_THRUST=1/0           - Use Thrust for sorting (default: 0)"
	@echo "  USE_CUB=1/0              - Use CUB for sorting (default: 1)"
	@echo "  COMPILE_SM35=1/0         - Modern CUDA architectures SM35+ (default: 1, SM20已废弃)"
	@echo "  SINGLE_NODE=1/0          - Single-threaded single-node mode (default: 0)"
	@echo "  DEBUG=1/0                - Debug build (default: 0)"
	@echo "  CUDA_VERBOSE_PTXAS=1/0   - Verbose PTXAS output (default: 0)"
	@echo "  CUDA_DEVICE_DEBUGGING=1/0 - CUDA device debugging (default: 0)"
	@echo "  CUDA_KEEP_INTERMEDIATE=1/0 - Keep intermediate files (default: 0)"
	@echo ""
	@echo "Examples:"
	@echo "  make                              # Standard build with MPI"
	@echo "  make OUTPUT_DIR=./build_production # Build to specific directory"
	@echo "  make KEEP_BUILD_FILES=1           # Keep intermediate build files"
	@echo "  make SINGLE_NODE=1                # Single-threaded build"
	@echo "  make USE_MPI=0                    # Build without MPI"
	@echo "  make DEBUG=1                      # Debug build"
	@echo "  make COMPILE_SM35=0               # Build for older GPUs"
	@echo "  make USE_CUB=0 USE_THRUST=1       # Use Thrust instead of CUB"
	@echo "  make OUTPUT_DIR=./dist clean      # Clean specific output directory"
	@echo "  make -j8                          # Parallel build with 8 jobs"

# 显示当前配置
show-config:
	@echo "Current build configuration:"
	@echo "  Binary name:           $(BINARY_NAME)"
	@echo "  Binary path:           $(BINARY_PATH)"
	@echo "  Output directory:      $(OUTPUT_DIR)"
	@echo "  Build directory:       $(BUILD_DIR)"
	@echo "  Keep build files:      $(KEEP_BUILD_FILES)"
	@echo "  C++ Compiler:          $(CXX)"
	@echo "  CUDA Compiler:         $(NVCC)"
	@echo "  CUDA Path:             $(CUDA_PATH)"
	@echo "  USE_MPI:               $(USE_MPI)"
	@echo "  USE_MPIMT:             $(USE_MPIMT)"
	@echo "  USE_THRUST:            $(USE_THRUST)"
	@echo "  USE_CUB:               $(USE_CUB)"
	@echo "  COMPILE_SM35:          $(COMPILE_SM35)"
	@echo "  SINGLE_NODE:           $(SINGLE_NODE)"
	@echo "  DEBUG:                 $(DEBUG)"
	@echo "  Architecture:          $(ARCH)"
	@echo "  CUDA Arch Support:     SM35+ (Fermi SM20已废弃)"
	@echo "  C++ Flags:             $(CXXFLAGS)"
	@echo "  CUDA Flags:            $(NVCCFLAGS)"
	@echo "  Defines:               $(DEFINES)"
	@echo "  Libraries:             $(LIBS)"

# ========================================
# 特殊目标 (Special Targets)
# ========================================

# 快速单线程编译 (用于测试)
single: SINGLE_NODE=1
single: USE_MPI=0
single: all

# 调试版本
debug: DEBUG=1
debug: all

# 并行编译优化
.NOTPARALLEL: check-deps

# 确保目录存在
$(OBJ_DIR) $(CUDA_OBJ_DIR):
	@mkdir -p $@

# 头文件依赖 (简化版)
$(CXX_OBJECTS): | $(OBJ_DIR)
$(CUDA_OBJECTS): | $(CUDA_OBJ_DIR)

# ========================================
# 构建信息 (Build Information)
# ========================================

# 显示构建开始信息
$(info )
$(info ==========================================)
$(info Bonsai-Lite Makefile Build System)
$(info ==========================================)
$(info Configuration:)
$(info   Target: $(BINARY_NAME))
$(info   Output: $(BINARY_PATH))
$(info   MPI Support: $(USE_MPI))
$(info   Single Node: $(SINGLE_NODE))
$(info   CUDA SM35+: $(COMPILE_SM35))
$(info   Debug Mode: $(DEBUG))
$(info ==========================================)
$(info )
