#!/bin/bash

echo "🔧 修复版启动脚本"
echo "========================================"

# 设置环境变量
export NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=4096"
export NODE_ENV="development"

echo "📋 当前Node.js版本: $(node --version)"

echo "🧹 清理缓存..."
rm -rf .vite dist node_modules/.vite

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

echo "🏗️  尝试构建前端..."
if npm run build; then
    echo "✅ 构建成功，启动生产服务器..."
    npm run preview &
    FRONTEND_PID=$!
    echo "📌 前端PID: $FRONTEND_PID (生产模式)"
else
    echo "⚠️  构建失败，使用开发模式..."
    NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=4096" npm run dev &
    FRONTEND_PID=$!
    echo "📌 前端PID: $FRONTEND_PID (开发模式)"
fi

# 保存PID
echo $BACKEND_PID > .backend.pid
echo $FRONTEND_PID > .frontend.pid

echo ""
echo "🎉 服务启动完成！"
echo "========================================"
echo "🌐 前端地址: http://localhost:5173"
echo "🔧 后端地址: http://localhost:3001"
echo "========================================"
echo "⏹️  停止服务: ./emergency-stop.sh"

# 等待服务完全启动
sleep 5

# 检查服务状态
echo "📊 检查服务状态..."
if curl -s http://localhost:3001 > /dev/null; then
    echo "✅ 后端服务正常运行"
else
    echo "❌ 后端服务可能未启动"
fi

if curl -s http://localhost:5173 > /dev/null; then
    echo "✅ 前端服务正常运行"
else
    echo "❌ 前端服务可能未启动"
fi

echo ""
echo "🚀 如果一切正常，请访问: http://localhost:5173"

# 等待用户停止
wait