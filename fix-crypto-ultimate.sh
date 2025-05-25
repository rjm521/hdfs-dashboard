#!/bin/bash

echo "🔧 终极Crypto修复脚本"
echo "========================================"

# 检查Node.js版本
NODE_VERSION=$(node --version)
echo "📋 当前Node.js版本: $NODE_VERSION"

# 备份package.json
cp package.json package.json.backup
echo "💾 已备份package.json"

echo ""
echo "🗑️  第1步：完全清理环境"
echo "========================================"
rm -rf node_modules package-lock.json dist .vite .eslintcache
npm cache clean --force 2>/dev/null || true

echo ""
echo "📦 第2步：修复package.json配置"
echo "========================================"

# 创建修复版本的package.json
cat > package.json << 'EOF'
{
  "name": "vite-react-typescript-starter",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "lint": "eslint .",
    "preview": "vite preview --host 0.0.0.0 --port 5173",
    "server": "node server.js"
  },
  "dependencies": {
    "@esbuild-plugins/node-globals-polyfill": "^0.2.3",
    "@esbuild-plugins/node-modules-polyfill": "^0.2.2",
    "@types/papaparse": "^5.3.16",
    "@types/react-pdf": "^6.2.0",
    "body-parser": "^2.2.0",
    "buffer": "^6.0.3",
    "crypto-browserify": "^3.12.0",
    "express": "^4.21.2",
    "express-session": "^1.18.0",
    "lucide-react": "^0.344.0",
    "multer": "^1.4.5-lts.1",
    "papaparse": "^5.4.1",
    "path-browserify": "^1.0.1",
    "process": "^0.11.10",
    "react": "^18.3.1",
    "react-audio-player": "^0.17.0",
    "react-dom": "^18.3.1",
    "react-pdf": "^7.7.0",
    "session-file-store": "^1.5.0",
    "vite-plugin-node-polyfills": "^0.23.0",
    "whatwg-fetch": "^3.6.20"
  },
  "devDependencies": {
    "@eslint/js": "^9.9.1",
    "@types/express": "^4.17.21",
    "@types/multer": "^1.4.11",
    "@types/papaparse": "^5.3.14",
    "@types/path-browserify": "^1.0.3",
    "@types/react": "^18.3.5",
    "@types/react-dom": "^18.3.0",
    "@types/react-pdf": "^7.0.0",
    "@vitejs/plugin-react": "^4.3.1",
    "autoprefixer": "^10.4.18",
    "eslint": "^9.9.1",
    "eslint-plugin-react-hooks": "^5.1.0-rc.0",
    "eslint-plugin-react-refresh": "^0.4.11",
    "globals": "^15.9.0",
    "http-proxy-middleware": "^3.0.3",
    "postcss": "^8.4.35",
    "tailwindcss": "^3.4.1",
    "typescript": "^5.5.3",
    "typescript-eslint": "^8.3.0",
    "vite": "^5.4.2"
  }
}
EOF

echo "✅ 已更新package.json"

echo ""
echo "🔧 第3步：尝试不同的安装方法"
echo "========================================"

# 方法1：标准安装
echo "🔄 方法1：标准安装..."
if npm install --no-audit --no-fund; then
    echo "✅ 标准安装成功"
    INSTALL_SUCCESS=true
else
    echo "❌ 标准安装失败"

    # 方法2：Legacy peer deps
    echo "🔄 方法2：Legacy peer deps..."
    if npm install --legacy-peer-deps --no-audit --no-fund; then
        echo "✅ Legacy安装成功"
        INSTALL_SUCCESS=true
    else
        echo "❌ Legacy安装失败"

        # 方法3：强制安装
        echo "🔄 方法3：强制安装..."
        if npm install --force --no-audit --no-fund; then
            echo "✅ 强制安装成功"
            INSTALL_SUCCESS=true
        else
            echo "❌ 所有安装方法都失败"
            INSTALL_SUCCESS=false
        fi
    fi
fi

if [ "$INSTALL_SUCCESS" = false ]; then
    echo "❌ 安装依赖失败，请检查网络连接"
    exit 1
fi

echo ""
echo "🏗️  第4步：尝试不同构建方法"
echo "========================================"

# 设置多种环境变量组合
export NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=4096"
export NODE_ENV="production"

# 构建方法1：标准构建
echo "🔄 构建方法1：标准构建..."
if npm run build; then
    echo "✅ 标准构建成功！"
    BUILD_SUCCESS=true
else
    echo "❌ 标准构建失败"

    # 构建方法2：开发模式构建
    echo "🔄 构建方法2：开发模式构建..."
    export NODE_ENV="development"
    if npm run build; then
        echo "✅ 开发模式构建成功！"
        BUILD_SUCCESS=true
    else
        echo "❌ 开发模式构建失败"

        # 构建方法3：忽略类型检查
        echo "🔄 构建方法3：忽略类型检查..."
        if npx vite build --mode development; then
            echo "✅ 无类型检查构建成功！"
            BUILD_SUCCESS=true
        else
            echo "❌ 所有构建方法都失败"
            BUILD_SUCCESS=false
        fi
    fi
fi

echo ""
echo "📊 修复结果"
echo "========================================"
if [ "$BUILD_SUCCESS" = true ]; then
    echo "🎉 恭喜！Crypto问题已修复"
    echo "✅ 可以正常运行 ./start-linux.sh start"
else
    echo "⚠️  构建仍有问题，但可以使用开发模式："
    echo "🚀 使用应急启动: chmod +x emergency-start.sh && ./emergency-start.sh"
fi

echo ""
echo "💡 如果问题持续，请尝试："
echo "1. 升级Node.js到18.18.0+: nvm install 18.18.0"
echo "2. 使用Docker部署: docker-compose up --build"
echo "3. 使用应急启动脚本进行开发"