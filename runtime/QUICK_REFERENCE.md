# Bonsai-Lite Makefile 快速参考

## 快速开始
```bash
make                    # 标准编译
make -j8                # 8线程并行编译
make help               # 显示完整帮助
```

## 常用配置

| 命令 | 说明 |
|------|------|
| `make` | 标准MPI版本 |
| `make SINGLE_NODE=1` | 单线程单节点 |
| `make USE_MPI=0` | 无MPI版本 |
| `make DEBUG=1` | 调试版本 |

## 核心选项

| 选项 | 默认 | 说明 |
|------|------|------|
| `USE_MPI` | 1 | MPI支持 |
| `SINGLE_NODE` | 0 | 单线程模式 |
| `USE_CUB` | 1 | CUB排序 |
| `COMPILE_SM35` | 1 | 现代GPU |
| `DEBUG` | 0 | 调试模式 |

## 实用命令

```bash
make check-deps         # 检查依赖
make show-config        # 显示配置
make clean              # 清理编译
make test               # 运行测试
make install            # 安装到~/bin
./test_makefile.sh      # 完整测试
```

## 推荐配置

- **集群**: `make USE_MPI=1 USE_CUB=1`
- **工作站**: `make USE_MPI=0 USE_CUB=1`
- **调试**: `make DEBUG=1 USE_MPI=0`
- **单线程**: `make SINGLE_NODE=1`
