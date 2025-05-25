#!/bin/bash

# ===============================================
# HDFS Dashboard 快速启动脚本
# 功能：快速启动微服务，后台运行
# 版本：v1.0.0
# ===============================================

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 HDFS Dashboard 快速启动脚本${NC}"
echo ""

# 检查微服务脚本是否存在
if [ ! -f "microservice.sh" ]; then
    echo -e "${YELLOW}⚠️  微服务脚本不存在，使用传统启动方式...${NC}"
    if [ -f "start-linux.sh" ]; then
        chmod +x start-linux.sh
        exec ./start-linux.sh daemon "$@"
    else
        echo "❌ 启动脚本不存在！"
        exit 1
    fi
fi

# 给微服务脚本添加执行权限
chmod +x microservice.sh

echo -e "${GREEN}✨ 使用微服务模式启动（后台运行，不阻塞终端）${NC}"
echo ""

# 执行微服务启动脚本
exec ./microservice.sh start "$@"