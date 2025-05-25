#!/bin/bash

# ===============================================
# 修复 Vite 构建 crypto.getRandomValues 错误
# 一键解决方案
# ===============================================

set -e  # 遇到错误立即退出

echo "🔧 修复 Vite 构建 crypto.getRandomValues 错误..."
echo ""

# 检查 Node.js 版本
echo "📋 检查 Node.js 版本..."
node_version=$(node --version 2>/dev/null || echo "未安装")
echo "Node.js 版本: $node_version"

if [[ "$node_version" != "未安装" ]]; then
    major_version=$(echo $node_version | sed 's/v//' | cut -d'.' -f1)
    if [ "$major_version" -lt 16 ]; then
        echo "⚠️  警告: Node.js 版本过低 ($node_version)，建议升级到 v16 或更高版本"
        echo "升级方法:"
        echo "  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
        echo "  sudo apt-get install -y nodejs"
        echo ""
    fi
fi

# 第一步：清理环境
echo "🧹 步骤1: 清理构建环境..."
rm -rf node_modules package-lock.json dist
echo "✅ 清理完成"
echo ""

# 第二步：安装必要的 polyfill 依赖
echo "📦 步骤2: 安装必要的 polyfill 依赖..."

# 安装 crypto 和其他 polyfill
npm install --save-dev \
  @types/node \
  crypto-browserify \
  buffer \
  path-browserify \
  @esbuild-plugins/node-globals-polyfill \
  @esbuild-plugins/node-modules-polyfill

echo "✅ polyfill 依赖安装完成"
echo ""

# 第三步：重新安装项目依赖
echo "📦 步骤3: 重新安装项目依赖..."
npm install
echo "✅ 项目依赖安装完成"
echo ""

# 第四步：设置环境变量
echo "⚙️  步骤4: 设置构建环境变量..."
export NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=4096"
echo "NODE_OPTIONS设置为: $NODE_OPTIONS"
echo ""

# 第五步：验证 Vite 配置
echo "🔍 步骤5: 验证 Vite 配置..."
if grep -q "crypto: 'crypto-browserify'" vite.config.ts; then
    echo "✅ Vite 配置中已包含 crypto polyfill"
else
    echo "⚠️  Vite 配置可能需要手动更新"
fi

if grep -q "global: 'globalThis'" vite.config.ts; then
    echo "✅ Vite 配置中已包含 global 定义"
else
    echo "⚠️  Vite 配置可能需要手动更新"
fi
echo ""

# 第六步：测试构建
echo "🧪 步骤6: 测试构建..."

echo "尝试方案1: 标准构建..."
if npm run build; then
    echo "✅ 标准构建成功！"
    exit 0
fi

echo ""
echo "方案1失败，尝试方案2: 开发模式构建..."
if npx vite build --mode development; then
    echo "✅ 开发模式构建成功！"
    exit 0
fi

echo ""
echo "方案2失败，尝试方案3: 设置额外环境变量..."
export NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=2048 --no-experimental-fetch"
if npm run build; then
    echo "✅ 额外环境变量构建成功！"
    exit 0
fi

echo ""
echo "方案3失败，尝试方案4: 使用 node 16 兼容模式..."
export NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=2048 --experimental-global-webcrypto"
if npm run build; then
    echo "✅ Node 16 兼容模式构建成功！"
    exit 0
fi

echo ""
echo "❌ 所有构建方案都失败了"
echo ""
echo "📋 手动解决建议："
echo "1. 检查 Node.js 版本是否 >= 16"
echo "2. 确保网络连接正常（某些依赖可能需要从 npm 下载）"
echo "3. 尝试使用开发模式启动: ./start-linux.sh start --dev"
echo "4. 查看详细错误日志: npm run build --verbose"
echo ""
echo "🔗 相关文件:"
echo "- Vite 配置: vite.config.ts"
echo "- 项目依赖: package.json"
echo "- 构建输出: dist/"
echo ""
echo "💡 如果问题仍然存在，可以考虑:"
echo "- 使用 Docker 部署"
echo "- 或直接使用开发模式运行项目"

exit 1