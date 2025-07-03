# Bonsai-Lite Debug 模式说明

## 概述

Bonsai-Lite Makefile 现在完全对应原版 CMakeLists.txt 的调试配置，支持两种独立的调试模式：

## 调试模式类型

### 1. 构建调试配置 (Build Debug Configuration)
对应 CMakeLists.txt 的 `CMAKE_BUILD_TYPE=Debug`

**用法:**
```bash
make CMAKE_BUILD_TYPE=Debug
# 或快捷方式
make debug
```

**特点:**
- C++ 编译使用 `-O0 -g -DDEBUG` 标志
- CUDA 编译使用 `-lineinfo` 标志
- 启用 CUDA 内存安全选项: `-DCUDA_API_PER_THREAD_DEFAULT_STREAM` 和 `-DDEBUG_CUDA_MEMORY`
- 适用于一般的程序调试

### 2. CUDA 设备调试 (CUDA Device Debugging)
对应 CMakeLists.txt 的 `CUDA_DEVICE_DEBUGGING=ON`

**用法:**
```bash
make CUDA_DEVICE_DEBUGGING=1
```

**特点:**
- CUDA 编译使用 `-G` 标志（设备调试）
- 允许在 GPU 代码中设置断点和单步调试
- 适用于 CUDA kernel 级别的调试

### 3. 完整调试模式 (Full Debug Mode)
结合两种调试模式

**用法:**
```bash
make CMAKE_BUILD_TYPE=Debug CUDA_DEVICE_DEBUGGING=1
# 或快捷方式
make debug-device
```

**特点:**
- 同时启用构建调试和 CUDA 设备调试
- 最全面的调试支持

## 编译标志对比

| 模式 | 构建类型 | CUDA 标志 | 内存安全 | 用途 |
|------|----------|-----------|----------|------|
| Release | Release | `-lineinfo` | 无 | 生产环境 |
| Debug | Debug | `-lineinfo` | 启用 | 程序调试 |
| Device Debug | Release | `-G` | 无 | CUDA 调试 |
| Full Debug | Debug | `-G` | 启用 | 完整调试 |

## 修复的问题

1. **CUDA 编译器标志冲突**: 修复了 "ptxas warning : Conflicting options --device-debug and --generate-line-info specified" 警告
2. **内存访问错误预防**: 在 debug 模式下添加了 CUDA 内存安全选项
3. **简化的接口**: 提供了清晰的 debug 目标，匹配 CMakeLists.txt 的逻辑

## 使用示例

```bash
# 标准发布版本
make

# 程序调试版本
make debug

# CUDA kernel 调试版本
make CUDA_DEVICE_DEBUGGING=1

# 完整调试版本
make debug-device

# 使用编译脚本进行 debug 编译
./compile_debug.sh
```

## 向后兼容性

- `DEBUG=1` 仍然支持，自动映射到 `CMAKE_BUILD_TYPE=Debug`
- 保持了所有原有的编译选项和功能
