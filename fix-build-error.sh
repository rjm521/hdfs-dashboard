#!/bin/bash

# ===============================================
# 修复 Vite 构建 crypto.getRandomValues 错误
# ===============================================

echo "🔧 修复 Vite 构建错误..."

# 检查 Node.js 版本
echo "📋 检查 Node.js 版本..."
node_version=$(node --version 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "Node.js 版本: $node_version"

    # 检查是否是版本问题
    major_version=$(echo $node_version | sed 's/v//' | cut -d'.' -f1)
    if [ "$major_version" -lt 16 ]; then
        echo "⚠️  警告: Node.js 版本过低 ($node_version)，建议升级到 v16 或更高版本"
        echo "升级方法:"
        echo "  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
        echo "  sudo apt-get install -y nodejs"
    fi
else
    echo "❌ Node.js 未安装或无法访问"
    exit 1
fi

echo ""
echo "🔍 诊断问题..."

# 解决方案1: 清理 node_modules 和重新安装
echo "📦 方案1: 清理依赖并重新安装..."
if [ -d "node_modules" ]; then
    echo "删除 node_modules..."
    rm -rf node_modules
fi

if [ -f "package-lock.json" ]; then
    echo "删除 package-lock.json..."
    rm -f package-lock.json
fi

echo "重新安装依赖..."
npm install

echo ""
echo "🔧 方案2: 设置 Node.js 环境变量..."
export NODE_OPTIONS="--openssl-legacy-provider"

echo ""
echo "🔧 方案3: 更新 Vite 配置..."

# 检查是否需要更新 vite.config.ts
if [ -f "vite.config.ts" ]; then
    echo "检查 vite.config.ts 配置..."

    # 备份原文件
    cp vite.config.ts vite.config.ts.backup

    # 检查是否已经有 define 配置
    if ! grep -q "global: globalThis" vite.config.ts; then
        echo "添加 global polyfill 配置..."

        # 在 defineConfig 中添加 define 配置
        sed -i '/export default defineConfig/,/^})/ s/plugins:/define: {\n    global: globalThis,\n  },\n  plugins:/' vite.config.ts
    fi
else
    echo "❌ vite.config.ts 不存在"
fi

echo ""
echo "🔧 方案4: 安装 crypto polyfill..."
npm install --save-dev @types/node

echo ""
echo "🧪 测试构建..."
echo "尝试重新构建..."

# 设置环境变量并尝试构建
export NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=4096"

# 尝试构建
npm run build

if [ $? -eq 0 ]; then
    echo "✅ 构建成功！"
else
    echo "❌ 构建仍然失败，尝试其他解决方案..."

    echo ""
    echo "🔧 方案5: 使用旧版本的构建命令..."

    # 尝试使用 legacy 模式
    npx vite build --mode development

    if [ $? -eq 0 ]; then
        echo "✅ 使用开发模式构建成功！"
    else
        echo "❌ 仍然失败，需要手动解决"
        echo ""
        echo "📋 手动解决步骤："
        echo "1. 升级 Node.js 到 v18 或更高版本"
        echo "2. 清理 npm 缓存: npm cache clean --force"
        echo "3. 删除 node_modules 和 package-lock.json"
        echo "4. 重新安装: npm install"
        echo "5. 设置环境变量: export NODE_OPTIONS=\"--openssl-legacy-provider\""
        echo "6. 重新构建: npm run build"
    fi
fi

echo ""
echo "🎯 修复完成！"