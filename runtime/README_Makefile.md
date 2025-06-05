# Bonsai-Lite Makefile 构建系统

## 概述

本文档介绍了基于原 CMakeLists.txt 构建的 Bonsai-Lite Makefile 构建系统。该系统专为 Linux 环境优化，支持 CUDA 加速的 N-body 重力树代码编译。

## 项目结构

```
runtime/
├── Makefile                    # 主构建文件
├── test_makefile.sh           # 测试验证脚本
├── src/                       # C++源文件
├── CUDAkernels/              # CUDA内核文件
├── include/                  # 头文件
├── profiling/                # 性能分析工具
└── build/                    # 编译输出目录 (自动生成)
    ├── obj/                  # C++目标文件
    └── cuda_obj/             # CUDA目标文件
```

## 快速开始

### 基本编译
```bash
# 标准编译 (推荐)
make

# 或者指定并行编译
make -j8
```

### 常用配置
```bash
# 单节点单线程模式
make SINGLE_NODE=1

# 不使用MPI
make USE_MPI=0

# 调试版本
make DEBUG=1

# 查看帮助
make help
```

## 编译选项详解

### 核心选项

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `USE_MPI` | 1 | 启用MPI支持进行分布式计算 |
| `USE_MPIMT` | 1 | 启用多线程MPI支持 (需要USE_MPI=1) |
| `SINGLE_NODE` | 0 | 完全单线程单节点模式，禁用所有并行化 |

### CUDA算法选项

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `USE_THRUST` | 0 | 使用NVIDIA Thrust库进行排序操作 |
| `USE_CUB` | 1 | 使用CUB库进行排序操作 (推荐，性能更好) |
| `COMPILE_SM35` | 1 | 支持Kepler及以上架构 (SM35+) |

### 调试和开发选项

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `DEBUG` | 0 | 启用调试模式 (O0, -g, -G) |
| `CUDA_VERBOSE_PTXAS` | 0 | 显示PTXAS汇编器详细输出 |
| `CUDA_DEVICE_DEBUGGING` | 0 | 启用CUDA设备端调试 |
| `CUDA_KEEP_INTERMEDIATE` | 0 | 保留CUDA编译中间文件 |

## CUDA架构支持

⚠️ **重要变更**: 从CUDA 11.0开始，SM_20 (Fermi) 架构已被完全废弃，本Makefile不再支持SM_20。

### 支持的现代架构 (COMPILE_SM35=1，默认且推荐)
- **Kepler**: SM35 (GTX 780, Tesla K40) - 最低支持架构
- **Maxwell**: SM50 (GTX 980), SM52 (GTX 1060)  
- **Pascal**: SM60 (GTX 1080), SM61 (GTX 1050)
- **Volta**: SM70 (Tesla V100)
- **Turing**: SM75 (RTX 2080)
- **Ampere**: SM80 (RTX 3080), SM86 (RTX 3060)
- **Ada Lovelace**: SM89 (RTX 4090)
- **Hopper**: SM90 (H100)

### 最小架构支持 (COMPILE_SM35=0，不推荐)
- 即使设为0，仍使用SM35作为最低架构
- SM_20已完全废弃，无法编译

## 编译目标和使用场景

### 1. 标准多节点版本
```bash
make USE_MPI=1 USE_CUB=1 COMPILE_SM35=1
```
**适用场景**: 
- 大规模分布式计算
- 集群环境
- 多GPU多节点系统

**特点**:
- 支持MPI分布式计算
- 支持多线程MPI
- 现代CUDA架构优化
- CUB高性能排序

### 2. 单机多线程版本
```bash
make USE_MPI=0 USE_CUB=1 COMPILE_SM35=1
```
**适用场景**:
- 单机多GPU系统
- 工作站环境
- 无MPI环境

**特点**:
- 无MPI依赖
- OpenMP多线程
- 适合单机高性能计算

### 3. 完全单线程版本
```bash
make SINGLE_NODE=1
```
**适用场景**:
- 调试和开发
- 简单测试
- 资源受限环境
- 确定性计算

**特点**:
- 禁用所有并行化
- 完全单线程执行
- 易于调试和分析
- 结果完全可重现

### 4. 调试版本
```bash
make DEBUG=1 USE_MPI=0
```
**适用场景**:
- 问题诊断
- 性能分析
- 开发调试

**特点**:
- 包含调试符号
- 禁用优化
- CUDA设备调试支持

### 5. 兼容旧硬件版本
```bash
make COMPILE_SM35=0 USE_MPI=0
```
**适用场景**:
- 旧GPU硬件 (Fermi架构)
- 兼容性测试

**特点**:
- 支持SM20架构
- 向后兼容

## 性能优化建议

### 编译优化
1. **并行编译**: 使用 `make -j$(nproc)` 加速编译
2. **现代架构**: 确保 `COMPILE_SM35=1` 以获得最佳性能
3. **CUB排序**: 使用 `USE_CUB=1` 而不是 `USE_THRUST=1`

### 运行时优化
1. **GPU选择**: 通过环境变量指定最佳GPU
   ```bash
   export CUDA_VISIBLE_DEVICES=0,1  # 使用前两个GPU
   ```

2. **OpenMP线程**: 设置合适的线程数
   ```bash
   export OMP_NUM_THREADS=8
   ```

3. **MPI配置**: 在集群环境中合理配置MPI进程
   ```bash
   mpirun -np 4 ./bonsai2_slowdust [参数]
   ```

## 依赖要求

### 必需依赖
- **GCC**: 7.0+ (支持C++14)
- **NVCC**: CUDA 9.0+ (推荐CUDA 11.0+)
- **Make**: GNU Make 4.0+

### 可选依赖
- **MPI**: OpenMPI 3.0+ 或 MPICH 3.0+ (用于分布式计算)
- **OpenMP**: 包含在GCC中 (用于多线程)

### 系统要求
- **操作系统**: Linux (Ubuntu 18.04+, CentOS 7+, RHEL 7+)
- **GPU**: NVIDIA GPU with Compute Capability 3.5+ (推荐)
- **内存**: 最小4GB，推荐16GB+

## 构建和安装

### 标准构建流程
```bash
# 1. 检查依赖
make check-deps

# 2. 查看配置
make show-config

# 3. 编译
make -j$(nproc)

# 4. 测试
make test

# 5. 安装 (可选)
make install
```

### 清理
```bash
# 清理编译文件
make clean

# 完全清理
make distclean
```

## 故障排除

### 常见问题

1. **CUDA编译器未找到**
   ```bash
   export PATH=/usr/local/cuda/bin:$PATH
   export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
   ```

2. **MPI编译器未找到**
   ```bash
   # 安装MPI (Ubuntu/Debian)
   sudo apt-get install libopenmpi-dev openmpi-bin
   
   # 安装MPI (CentOS/RHEL)
   sudo yum install openmpi-devel
   ```

3. **内存不足**
   ```bash
   # 减少并行编译线程
   make -j2  # 而不是 make -j$(nproc)
   ```

4. **GPU架构不匹配**
   ```bash
   # 检查GPU架构
   nvidia-smi --query-gpu=compute_cap --format=csv
   
   # 使用合适的编译选项
   make COMPILE_SM35=0  # 对于旧GPU
   ```

### 编译错误诊断

1. **启用详细输出**
   ```bash
   make CUDA_VERBOSE_PTXAS=1
   ```

2. **保留中间文件**
   ```bash
   make CUDA_KEEP_INTERMEDIATE=1
   ```

3. **调试编译**
   ```bash
   make DEBUG=1
   ```

## 与原CMakeLists.txt的对比

### 保留的功能
- ✅ 所有核心编译选项
- ✅ CUDA架构支持
- ✅ MPI分布式计算支持
- ✅ OpenMP多线程支持
- ✅ 条件编译和预处理器定义
- ✅ 架构特定优化 (SSE4, AVX)

### 移除的功能
- ❌ OpenGL渲染和可视化 (`USE_DUST`)
- ❌ Galactics初始条件生成器 (`USE_GALACTICS`)
- ❌ Windows平台支持
- ❌ 额外的可执行文件 (bonsai_clrshm, bonsai_io, bonsai_driver)

### 新增的功能
- ✨ 完全单线程模式 (`SINGLE_NODE=1`)
- ✨ 现代CUDA架构支持 (SM80+)
- ✨ 智能MPI检测和回退
- ✨ 并行编译优化
- ✨ 详细的配置显示和帮助
- ✨ 自动化测试脚本

### 优化改进
- 🔧 更清晰的选项组织
- 🔧 更好的错误处理
- 🔧 增量编译支持
- 🔧 更灵活的路径检测
- 🔧 优化的编译标志

## 高级用法

### 交叉编译
```bash
# 为特定架构编译
make ARCH=aarch64 CXX=aarch64-linux-gnu-g++
```

### 自定义CUDA路径
```bash
make CUDA_PATH=/opt/cuda-12.0
```

### 环境变量配置
```bash
# 设置编译环境
export CC=gcc-9
export CXX=g++-9
export NVCC=/usr/local/cuda-11.8/bin/nvcc
export CUDA_PATH=/usr/local/cuda-11.8

make
```

### 持续集成配置
```bash
#!/bin/bash
# CI脚本示例
set -e

# 检查环境
make check-deps

# 测试多种配置
for config in "USE_MPI=1" "USE_MPI=0" "SINGLE_NODE=1" "DEBUG=1"; do
    echo "Testing configuration: $config"
    make clean
    eval "make $config -j$(nproc)"
    make test
done

echo "All tests passed!"
```

## 开发和贡献

### 开发环境设置
```bash
# 开发模式编译
make DEBUG=1 CUDA_DEVICE_DEBUGGING=1 CUDA_VERBOSE_PTXAS=1

# 运行测试套件
./test_makefile.sh
```

### 添加新的编译选项
1. 在Makefile中添加选项定义
2. 在适当的位置添加条件逻辑
3. 更新帮助文档
4. 添加测试用例

### 提交指南
1. 确保所有测试通过
2. 更新相关文档
3. 遵循现有代码风格
4. 提供清晰的提交信息

## 许可证

本构建系统遵循 Bonsai-Lite 项目的原始许可证条款。

## 更新日志

### v1.0.0 (2025-06-05)
- 基于CMakeLists.txt创建初始Makefile
- 支持所有核心编译选项
- 移除渲染和Galactics功能
- 添加单线程模式
- 现代CUDA架构支持
- 完整的测试套件

---

*最后更新: 2025年6月5日*
