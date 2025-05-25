#!/bin/bash

# ===============================================
# HDFS Dashboard Docker 调试脚本
# 用于诊断Docker环境中的问题
# ===============================================

echo "🔍 HDFS Dashboard Docker 诊断工具"
echo "=================================="
echo ""

# 检查Docker是否安装
echo "1️⃣ 检查Docker环境..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装Docker Compose"
    exit 1
fi

echo "✅ Docker 版本: $(docker --version)"
echo "✅ Docker Compose 版本: $(docker-compose --version)"
echo ""

# 检查容器状态
echo "2️⃣ 检查容器状态..."
if docker ps -a | grep -q hdfs-dashboard; then
    echo "📋 容器状态:"
    docker ps -a | grep hdfs-dashboard
    echo ""

    # 检查容器是否运行
    if docker ps | grep -q hdfs-dashboard; then
        echo "✅ 容器正在运行"

        # 检查端口映射
        echo ""
        echo "3️⃣ 检查端口映射..."
        docker port hdfs-dashboard
        echo ""

        # 检查容器内服务状态
        echo "4️⃣ 检查容器内服务状态..."
        echo "后端服务状态:"
        docker exec hdfs-dashboard curl -s http://localhost:3001/admin/login > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "✅ 后端服务正常"
        else
            echo "❌ 后端服务异常"
        fi

        echo "前端服务状态:"
        docker exec hdfs-dashboard curl -s http://localhost:5173 > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "✅ 前端服务正常"
        else
            echo "❌ 前端服务异常"
        fi

        echo "HDFS API代理状态:"
        HDFS_API_RESULT=$(docker exec hdfs-dashboard curl -s "http://localhost:3001/api/hdfs?op=LISTSTATUS" 2>/dev/null)
        if echo "$HDFS_API_RESULT" | grep -q "FileStatuses"; then
            echo "✅ HDFS API代理正常"
        else
            echo "❌ HDFS API代理异常"
            echo "响应内容: $HDFS_API_RESULT"
        fi
        echo ""

        # 显示访问地址
        echo "5️⃣ 访问地址..."
        SERVER_IP=$(docker exec hdfs-dashboard hostname -i | awk '{print $1}')
        HOST_IP=$(hostname -I | awk '{print $1}')
        echo "容器内IP: $SERVER_IP"
        echo "主机IP: $HOST_IP"
        echo "前端访问: http://$HOST_IP:5173"
        echo "后端API: http://$HOST_IP:3001"
        echo ""

        # 查看最近日志
        echo "6️⃣ 最近日志 (最后20行)..."
        docker logs hdfs-dashboard --tail=20

    else
        echo "❌ 容器未运行"
        echo ""
        echo "📋 容器日志 (最后50行):"
        docker logs hdfs-dashboard --tail=50
    fi

else
    echo "❌ 未找到 hdfs-dashboard 容器"
    echo "请先运行: docker-compose up --build"
fi

echo ""
echo "==============================================="
echo "🛠️  如果发现问题，可以尝试以下操作:"
echo "1. 重新构建: docker-compose down && docker-compose up --build"
echo "2. 清理重建: docker-compose down -v && docker system prune -f && docker-compose up --build"
echo "3. 查看详细日志: docker-compose logs -f"
echo "4. 进入容器调试: docker exec -it hdfs-dashboard sh"
echo "==============================================="