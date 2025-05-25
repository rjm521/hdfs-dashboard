#!/bin/bash

echo "==============================================="
echo "        手动修复 Crypto 错误脚本"
echo "==============================================="

echo "[1/5] 清理环境和缓存..."
rm -rf node_modules
rm -f package-lock.json
rm -rf dist
rm -rf .vite

echo "[2/5] 安装依赖包..."
npm install

echo "[3/5] 安装 crypto polyfill 依赖..."
npm install crypto-browserify@^3.12.0 process@^0.11.10 buffer@^6.0.3 path-browserify@^1.0.1

echo "[4/5] 设置环境变量..."
export NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=4096"

echo "[5/5] 尝试启动开发服务器..."
echo "如果还有问题，请尝试以下方法："
echo "方法1 - 开发模式启动："
echo "  npm run dev"
echo ""
echo "方法2 - 使用Legacy OpenSSL："
echo "  NODE_OPTIONS=\"--openssl-legacy-provider --max-old-space-size=4096\" npm run dev"
echo ""
echo "方法3 - 如果crypto错误持续，尝试："
echo "  rm -rf node_modules package-lock.json"
echo "  npm install --legacy-peer-deps"
echo "  npm run dev"

echo "==============================================="
echo "               修复完成！"
echo "==============================================="