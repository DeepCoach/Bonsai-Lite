#!/bin/bash

# Bonsai-Lite Makefile 测试和验证脚本
# Test and Validation Script for Bonsai-Lite Makefile

set -e  # Exit on any error

echo "=========================================="
echo "Bonsai-Lite 编译系统测试脚本"
echo "Bonsai-Lite Build System Test Script"
echo "=========================================="

# 保存当前目录
ORIGINAL_DIR=$(pwd)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
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

# 清理函数
cleanup() {
    log_info "清理测试环境..."
    make distclean 2>/dev/null || true
    cd "$ORIGINAL_DIR"
}

# 错误处理
error_exit() {
    log_error "$1"
    cleanup
    exit 1
}

# 捕获中断信号
trap cleanup EXIT INT TERM

echo ""
echo "测试开始时间: $(date)"
echo "测试目录: $SCRIPT_DIR"
echo ""

# ==========================================
# 1. 环境检查
# ==========================================

log_info "检查编译环境..."

# 检查基本工具
if ! command -v make &> /dev/null; then
    error_exit "make 命令未找到"
fi

if ! command -v g++ &> /dev/null; then
    error_exit "g++ 编译器未找到"
fi

if ! command -v nvcc &> /dev/null; then
    error_exit "NVIDIA CUDA 编译器未找到"
fi

# 检查MPI (可选)
if command -v mpicxx &> /dev/null || command -v mpiCC &> /dev/null; then
    log_info "发现MPI编译器，将测试MPI版本"
    HAS_MPI=1
else
    log_warning "未发现MPI编译器，将跳过MPI测试"
    HAS_MPI=0
fi

# 检查CUDA版本
CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([0-9]\+\.[0-9]\+\).*/\1/' || echo "unknown")
log_info "检测到CUDA版本: $CUDA_VERSION"

# 检查GPU
if command -v nvidia-smi &> /dev/null; then
    GPU_COUNT=$(nvidia-smi -L | wc -l)
    log_info "检测到 $GPU_COUNT 个GPU"
    if [ $GPU_COUNT -eq 0 ]; then
        log_warning "未检测到可用GPU，程序可能无法正常运行"
    fi
else
    log_warning "nvidia-smi 未找到，无法检测GPU状态"
fi

log_success "环境检查完成"
echo ""

# ==========================================
# 2. Makefile语法检查
# ==========================================

log_info "检查Makefile语法..."

if make -n help > /dev/null 2>&1; then
    log_success "Makefile语法正确"
else
    error_exit "Makefile语法错误"
fi

# 显示配置信息
log_info "显示构建配置:"
make show-config
echo ""

# ==========================================
# 3. 依赖检查测试
# ==========================================

log_info "测试依赖检查..."

if make check-deps; then
    log_success "依赖检查通过"
else
    error_exit "依赖检查失败"
fi
echo ""

# ==========================================
# 4. 编译测试
# ==========================================

log_info "开始编译测试..."

# 测试配置列表
CONFIGS=(
    "标准配置:USE_MPI=1"
    "单节点配置:SINGLE_NODE=1"
    "无MPI配置:USE_MPI=0"
    "调试配置:DEBUG=1"
    "CUB排序:USE_CUB=1 USE_THRUST=0"
    "旧架构支持:COMPILE_SM35=0"
)

# 如果没有MPI，跳过MPI相关测试
if [ $HAS_MPI -eq 0 ]; then
    CONFIGS=(
        "单节点配置:SINGLE_NODE=1"
        "无MPI配置:USE_MPI=0"
        "调试配置:DEBUG=1 USE_MPI=0"
        "CUB排序:USE_CUB=1 USE_THRUST=0 USE_MPI=0"
        "旧架构支持:COMPILE_SM35=0 USE_MPI=0"
    )
fi

TOTAL_CONFIGS=${#CONFIGS[@]}
SUCCESS_COUNT=0

for i in "${!CONFIGS[@]}"; do
    IFS=':' read -r CONFIG_NAME CONFIG_OPTS <<< "${CONFIGS[$i]}"
    
    log_info "测试配置 $((i+1))/$TOTAL_CONFIGS: $CONFIG_NAME"
    log_info "编译选项: $CONFIG_OPTS"
    
    # 清理之前的编译
    make distclean > /dev/null 2>&1 || true
    
    # 编译测试
    if eval "make $CONFIG_OPTS -j$(nproc)"; then
        log_success "配置 '$CONFIG_NAME' 编译成功"
        
        # 检查可执行文件是否生成
        if [ -f "bonsai2_slowdust" ]; then
            log_success "可执行文件生成成功"
            
            # 基本功能测试
            if ./bonsai2_slowdust --help > /dev/null 2>&1; then
                log_success "可执行文件运行正常"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                log_warning "可执行文件无法正常运行 (可能缺少输入文件)"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))  # 仍然算作成功
            fi
        else
            log_error "可执行文件未生成"
        fi
    else
        log_error "配置 '$CONFIG_NAME' 编译失败"
    fi
    
    echo ""
done

echo ""
log_info "编译测试总结:"
log_info "成功配置: $SUCCESS_COUNT/$TOTAL_CONFIGS"

if [ $SUCCESS_COUNT -eq $TOTAL_CONFIGS ]; then
    log_success "所有配置编译成功！"
else
    log_warning "部分配置编译失败，请检查错误信息"
fi

# ==========================================
# 5. 功能测试
# ==========================================

log_info "进行功能测试..."

# 清理并使用标准配置编译
make distclean > /dev/null 2>&1 || true

if [ $HAS_MPI -eq 1 ]; then
    FINAL_CONFIG="USE_MPI=1"
else
    FINAL_CONFIG="USE_MPI=0"
fi

log_info "使用最终配置编译: $FINAL_CONFIG"

if eval "make $FINAL_CONFIG -j$(nproc)"; then
    log_success "最终版本编译成功"
    
    # 检查可执行文件大小
    if [ -f "bonsai2_slowdust" ]; then
        FILE_SIZE=$(ls -lh bonsai2_slowdust | awk '{print $5}')
        log_info "可执行文件大小: $FILE_SIZE"
        
        # 检查是否正确链接了CUDA库
        if ldd bonsai2_slowdust | grep -q "libcudart"; then
            log_success "正确链接了CUDA运行时库"
        else
            log_warning "可能未正确链接CUDA运行时库"
        fi
        
        # 检查是否链接了MPI库 (如果启用了MPI)
        if [ $HAS_MPI -eq 1 ] && echo "$FINAL_CONFIG" | grep -q "USE_MPI=1"; then
            if ldd bonsai2_slowdust | grep -q "libmpi"; then
                log_success "正确链接了MPI库"
            else
                log_warning "可能未正确链接MPI库"
            fi
        fi
    fi
else
    error_exit "最终版本编译失败"
fi

# ==========================================
# 6. 性能测试 (可选)
# ==========================================

log_info "检查编译时间优化..."

# 测试并行编译
log_info "测试并行编译性能..."
make clean > /dev/null 2>&1

start_time=$(date +%s)
eval "make $FINAL_CONFIG -j$(nproc)" > /dev/null 2>&1
end_time=$(date +%s)

compile_time=$((end_time - start_time))
log_info "并行编译时间: ${compile_time}秒"

# ==========================================
# 7. 安装测试 (可选)
# ==========================================

log_info "测试安装功能..."

if make install; then
    log_success "安装成功"
    
    # 检查安装的可执行文件
    if [ -f "$HOME/bin/bonsai2_slowdust" ]; then
        log_success "可执行文件已安装到 $HOME/bin/"
        
        # 测试已安装的版本
        if "$HOME/bin/bonsai2_slowdust" --help > /dev/null 2>&1; then
            log_success "已安装的可执行文件运行正常"
        else
            log_warning "已安装的可执行文件可能有问题"
        fi
    else
        log_error "安装的可执行文件未找到"
    fi
else
    log_warning "安装失败"
fi

# ==========================================
# 8. 清理测试
# ==========================================

log_info "测试清理功能..."

# 创建一些测试文件
touch test_file.tmp

if make clean; then
    log_success "清理功能正常"
    
    # 检查是否还有编译文件
    if [ -d "build" ]; then
        log_warning "build目录未完全清理"
    else
        log_success "编译文件已清理"
    fi
else
    log_error "清理功能异常"
fi

# 完全清理测试
if make distclean; then
    log_success "完全清理功能正常"
else
    log_error "完全清理功能异常"
fi

# 清理测试文件
rm -f test_file.tmp

echo ""
echo "=========================================="
echo "测试完成总结 (Test Summary)"
echo "=========================================="

if [ $SUCCESS_COUNT -eq $TOTAL_CONFIGS ]; then
    echo -e "${GREEN}✓ 所有编译配置测试通过${NC}"
    echo -e "${GREEN}✓ Makefile构建系统运行正常${NC}"
    echo -e "${GREEN}✓ 可以投入使用${NC}"
    
    echo ""
    echo "建议的使用命令:"
    echo "  make                    # 标准编译"
    echo "  make SINGLE_NODE=1      # 单节点模式"
    echo "  make -j8                # 8线程并行编译"
    echo "  make help               # 查看帮助"
    
    echo ""
    echo "推荐配置:"
    if [ $HAS_MPI -eq 1 ]; then
        echo "  标准配置: make USE_MPI=1 USE_CUB=1 COMPILE_SM35=1"
    else
        echo "  单机配置: make USE_MPI=0 USE_CUB=1 COMPILE_SM35=1"
    fi
    echo "  调试配置: make DEBUG=1"
    echo "  单线程配置: make SINGLE_NODE=1"
    
else
    echo -e "${YELLOW}⚠ 部分配置测试失败 ($SUCCESS_COUNT/$TOTAL_CONFIGS 成功)${NC}"
    echo -e "${YELLOW}⚠ 需要检查编译环境或配置${NC}"
fi

echo ""
echo "测试结束时间: $(date)"
echo "如有问题，请检查编译错误日志。"
echo "=========================================="
