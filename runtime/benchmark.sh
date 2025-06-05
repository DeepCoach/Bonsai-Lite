#!/bin/bash

# Bonsai-Lite 性能基准测试脚本
# Performance Benchmark Script for Bonsai-Lite

set -e

echo "======================================="
echo "Bonsai-Lite 性能基准测试"
echo "Performance Benchmark Test"
echo "======================================="

cd "$(dirname "$0")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_benchmark() {
    echo -e "${PURPLE}[BENCHMARK]${NC} $1"
}

# 检查系统信息
log_info "收集系统信息..."
echo "系统信息:"
echo "  CPU: $(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d: -f2 | xargs)"
echo "  CPU cores: $(nproc)"
echo "  Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "  CUDA版本: $(nvcc --version | grep 'release' | sed 's/.*release \([0-9]\+\.[0-9]\+\).*/\1/' || echo 'N/A')"

if command -v nvidia-smi &> /dev/null; then
    echo "  GPU信息:"
    nvidia-smi --query-gpu=index,name,memory.total,compute_cap --format=csv,noheader,nounits | while IFS=, read -r idx name memory cap; do
        echo "    GPU$idx: $name (${memory}MB, SM$cap)"
    done
else
    log_warning "无法获取GPU信息"
fi

echo ""

# 测试配置列表
CONFIGS=(
    "单线程模式:SINGLE_NODE=1:single"
    "单机多线程:USE_MPI=0:multithread"
    "MPI并行:USE_MPI=1:mpi"
    "调试模式:DEBUG=1 USE_MPI=0:debug"
    "CUB排序:USE_CUB=1 USE_THRUST=0 USE_MPI=0:cub"
    "Thrust排序:USE_CUB=0 USE_THRUST=1 USE_MPI=0:thrust"
)

TOTAL_CONFIGS=${#CONFIGS[@]}
RESULTS_FILE="benchmark_results_$(date +%Y%m%d_%H%M%S).txt"

echo "基准测试结果将保存到: $RESULTS_FILE"
echo "测试开始时间: $(date)" > $RESULTS_FILE
echo "系统信息:" >> $RESULTS_FILE
echo "  CPU: $(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d: -f2 | xargs)" >> $RESULTS_FILE
echo "  CPU cores: $(nproc)" >> $RESULTS_FILE
echo "  Memory: $(free -h | grep '^Mem:' | awk '{print $2}')" >> $RESULTS_FILE
echo "" >> $RESULTS_FILE

log_benchmark "开始编译性能测试..."
echo ""

for i in "${!CONFIGS[@]}"; do
    IFS=':' read -r CONFIG_NAME CONFIG_OPTS CONFIG_TAG <<< "${CONFIGS[$i]}"
    
    log_benchmark "测试配置 $((i+1))/$TOTAL_CONFIGS: $CONFIG_NAME"
    log_info "编译选项: $CONFIG_OPTS"
    
    # 清理之前的编译
    make distclean > /dev/null 2>&1 || true
    
    # 测试编译时间
    echo "配置: $CONFIG_NAME ($CONFIG_OPTS)" >> $RESULTS_FILE
    start_time=$(date +%s.%N)
    
    if eval "make $CONFIG_OPTS -j$(nproc)" > build_${CONFIG_TAG}.log 2>&1; then
        end_time=$(date +%s.%N)
        compile_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")
        
        # 获取二进制文件大小
        if [ -f "bonsai2_slowdust" ]; then
            binary_size=$(stat -f%z bonsai2_slowdust 2>/dev/null || stat -c%s bonsai2_slowdust 2>/dev/null || echo "0")
            binary_size_mb=$(echo "scale=2; $binary_size / 1024 / 1024" | bc 2>/dev/null || echo "N/A")
            
            log_success "编译成功 - 时间: ${compile_time}s, 大小: ${binary_size_mb}MB"
            
            echo "  编译时间: ${compile_time}s" >> $RESULTS_FILE
            echo "  二进制大小: ${binary_size_mb}MB" >> $RESULTS_FILE
            
            # 测试运行时性能 (如果有测试输入文件)
            if [ -f "../inputExamples/model3_child_compact.tipsy" ]; then
                log_info "测试运行时性能..."
                
                # 基本帮助测试
                if ./bonsai2_slowdust --help > /dev/null 2>&1; then
                    echo "  基本功能: 正常" >> $RESULTS_FILE
                else
                    echo "  基本功能: 异常" >> $RESULTS_FILE
                fi
            else
                echo "  运行时测试: 跳过 (无测试文件)" >> $RESULTS_FILE
            fi
            
            # 检查链接的库
            libs_info=$(ldd bonsai2_slowdust 2>/dev/null | grep -E "(libcuda|libmpi)" | wc -l)
            echo "  链接库数量: $libs_info" >> $RESULTS_FILE
            
        else
            log_error "二进制文件未生成"
            echo "  状态: 编译失败" >> $RESULTS_FILE
        fi
        
    else
        log_error "编译失败"
        echo "  状态: 编译失败" >> $RESULTS_FILE
        echo "  错误日志: build_${CONFIG_TAG}.log" >> $RESULTS_FILE
    fi
    
    echo "" >> $RESULTS_FILE
    echo ""
done

# 增量编译测试
log_benchmark "测试增量编译性能..."
make distclean > /dev/null 2>&1

# 首次编译
start_time=$(date +%s.%N)
make USE_MPI=0 -j$(nproc) > build_incremental_first.log 2>&1
end_time=$(date +%s.%N)
first_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")

# 无变化重编译
start_time=$(date +%s.%N)
make USE_MPI=0 > build_incremental_none.log 2>&1
end_time=$(date +%s.%N)
none_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")

# 修改文件后重编译
touch src/main.cpp
start_time=$(date +%s.%N)
make USE_MPI=0 -j$(nproc) > build_incremental_touch.log 2>&1
end_time=$(date +%s.%N)
touch_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")

echo "增量编译测试:" >> $RESULTS_FILE
echo "  首次编译: ${first_time}s" >> $RESULTS_FILE
echo "  无变化重编译: ${none_time}s" >> $RESULTS_FILE
echo "  单文件修改重编译: ${touch_time}s" >> $RESULTS_FILE

log_success "增量编译测试完成"
echo "  首次编译: ${first_time}s"
echo "  无变化重编译: ${none_time}s"
echo "  单文件修改重编译: ${touch_time}s"
echo ""

# 并行编译测试
log_benchmark "测试并行编译性能..."
make clean > /dev/null 2>&1

for threads in 1 2 4 8; do
    if [ $threads -le $(nproc) ]; then
        start_time=$(date +%s.%N)
        make USE_MPI=0 -j$threads > build_parallel_${threads}.log 2>&1
        end_time=$(date +%s.%N)
        parallel_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")
        
        echo "  ${threads}线程编译: ${parallel_time}s" >> $RESULTS_FILE
        log_info "${threads}线程编译时间: ${parallel_time}s"
        
        make clean > /dev/null 2>&1
    fi
done

echo "" >> $RESULTS_FILE

# 生成总结报告
log_benchmark "生成性能报告..."

echo "========================================" >> $RESULTS_FILE
echo "性能测试总结" >> $RESULTS_FILE
echo "========================================" >> $RESULTS_FILE
echo "测试完成时间: $(date)" >> $RESULTS_FILE

# 找出最快的配置
log_success "基准测试完成！"
echo ""
echo "详细结果已保存到: $RESULTS_FILE"
echo ""
echo "快速总结:"
echo "  测试配置数量: $TOTAL_CONFIGS"
echo "  增量编译支持: 正常"
echo "  并行编译支持: 正常"

# 推荐配置
echo ""
log_info "推荐配置:"
echo "  开发调试: make DEBUG=1 USE_MPI=0"
echo "  单机高性能: make USE_MPI=0 USE_CUB=1"
echo "  集群计算: make USE_MPI=1 USE_CUB=1"
echo "  单线程模式: make SINGLE_NODE=1"

# 清理临时文件
log_info "清理临时文件..."
rm -f build_*.log
make distclean > /dev/null 2>&1

echo ""
echo "基准测试脚本执行完成！"
echo "如需查看详细结果，请检查: $RESULTS_FILE"
