#!/bin/bash

echo "🚨 应急启动模式 - 跳过构建问题"
echo "========================================"

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装"
    exit 1
fi

echo "📋 当前Node.js版本: $(node --version)"

# 设置环境变量
export NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=4096"
export NODE_ENV="development"

echo "🧹 清理缓存..."
rm -rf .vite dist 2>/dev/null || true

echo "📦 检查依赖..."
if [ ! -d "node_modules" ]; then
    echo "🔄 安装依赖中..."
    npm install --no-audit --no-fund
fi

echo "🔧 启动后端服务..."
# 后台启动后端
NODE_OPTIONS="--openssl-legacy-provider" node server.js &
BACKEND_PID=$!
echo "📌 后端PID: $BACKEND_PID"

# 等待后端启动
sleep 3

echo "🌐 启动前端开发服务器（跳过构建）..."
# 使用开发模式，避免构建
NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=4096" npm run dev &
FRONTEND_PID=$!
echo "📌 前端PID: $FRONTEND_PID"

# 保存PID
echo $BACKEND_PID > .backend.pid
echo $FRONTEND_PID > .frontend.pid

echo ""
echo "🎉 应急启动完成！"
echo "========================================"
echo "🌐 前端地址: http://localhost:5173"
echo "🔧 后端地址: http://localhost:3001"
echo "========================================"
echo "⏹️  停止服务: ./emergency-stop.sh"
echo "📊 查看状态: ps -ef | grep -E 'node|vite'"

# 等待用户停止
wait