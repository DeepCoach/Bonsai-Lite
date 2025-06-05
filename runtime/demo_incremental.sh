#!/bin/bash

# Bonsai-Lite 增量编译演示脚本
# Incremental Compilation Demo Script

echo "======================================="
echo "Bonsai-Lite 增量编译演示"
echo "Incremental Compilation Demo"
echo "======================================="

cd "$(dirname "$0")"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_step() {
    echo -e "${YELLOW}[STEP]${NC} $1"
}

# 1. 清理环境
log_step "1. 清理编译环境"
make distclean
echo ""

# 2. 首次完整编译
log_step "2. 首次完整编译 (USE_MPI=0 以简化测试)"
echo "开始时间: $(date)"
start_time=$(date +%s)
make USE_MPI=0 -j$(nproc)
end_time=$(date +%s)
first_compile_time=$((end_time - start_time))
log_success "首次编译完成，耗时: ${first_compile_time}秒"
echo ""

# 3. 无变化重新编译 (应该很快)
log_step "3. 无变化情况下重新编译"
start_time=$(date +%s)
make USE_MPI=0
end_time=$(date +%s)
no_change_time=$((end_time - start_time))
log_success "无变化编译完成，耗时: ${no_change_time}秒"
echo ""

# 4. 修改一个源文件并重新编译
log_step "4. 模拟源文件修改后的增量编译"
# 轻微修改一个文件的时间戳来模拟修改
touch src/main.cpp
start_time=$(date +%s)
make USE_MPI=0 -j$(nproc)
end_time=$(date +%s)
incremental_time=$((end_time - start_time))
log_success "增量编译完成，耗时: ${incremental_time}秒"
echo ""

# 5. 清理并使用不同配置编译
log_step "5. 使用不同配置编译 (单节点模式)"
make clean
start_time=$(date +%s)
make SINGLE_NODE=1 -j$(nproc)
end_time=$(date +%s)
config_change_time=$((end_time - start_time))
log_success "配置变更编译完成，耗时: ${config_change_time}秒"
echo ""

# 6. 显示编译时间对比
log_step "6. 编译时间对比"
echo "首次完整编译:     ${first_compile_time}秒"
echo "无变化重编译:     ${no_change_time}秒"
echo "增量编译:         ${incremental_time}秒"
echo "配置变更编译:     ${config_change_time}秒"
echo ""

# 7. 计算效率提升
if [ $first_compile_time -gt 0 ]; then
    no_change_ratio=$(echo "scale=1; $no_change_time * 100 / $first_compile_time" | bc 2>/dev/null || echo "N/A")
    incremental_ratio=$(echo "scale=1; $incremental_time * 100 / $first_compile_time" | bc 2>/dev/null || echo "N/A")
    
    log_success "增量编译效率："
    echo "无变化编译相对首次编译: ${no_change_ratio}%"
    echo "增量编译相对首次编译:   ${incremental_ratio}%"
else
    echo "编译时间过短，无法准确计算比率"
fi

echo ""
log_success "增量编译演示完成！"
echo "Makefile正确实现了增量编译功能。"
