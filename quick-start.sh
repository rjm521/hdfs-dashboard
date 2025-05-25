#!/bin/bash

# HDFS 文件管理平台快速启动脚本
# 简化版本，适合快速部署

set -e

IMAGE_NAME="hdfs-dashboard"
CONTAINER_NAME="hdfs-dashboard"

echo "🚀 HDFS 文件管理平台快速启动"
echo "================================"

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装！请先安装Docker"
    exit 1
fi

# 检查配置文件
if [ ! -f "app.config.json" ]; then
    if [ -f "app.config.production.json" ]; then
        echo "📝 复制配置模板..."
        cp app.config.production.json app.config.json
        echo "⚠️  请编辑 app.config.json 配置文件后重新运行此脚本"
        exit 1
    else
        echo "❌ 配置文件不存在！"
        exit 1
    fi
fi

# 停止现有容器
echo "🔄 清理现有容器..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# 构建镜像
echo "🏗️  构建Docker镜像..."
docker build -t $IMAGE_NAME .

# 启动容器
echo "🚀 启动容器..."
docker run -d \
    --name $CONTAINER_NAME \
    -p 5173:5173 \
    -p 3001:3001 \
    -v $(pwd)/app.config.json:/app/app.config.json:ro \
    -v hdfs-dashboard-uploads:/app/uploads_tmp \
    --restart unless-stopped \
    $IMAGE_NAME

echo "✅ 启动完成！"
echo ""
echo "📱 访问地址："
echo "   前端界面: http://localhost:5173"
echo "   后端API:  http://localhost:3001"
echo ""
echo "🔧 管理命令："
echo "   查看日志: docker logs -f $CONTAINER_NAME"
echo "   停止服务: docker stop $CONTAINER_NAME"
echo "   删除容器: docker rm $CONTAINER_NAME"