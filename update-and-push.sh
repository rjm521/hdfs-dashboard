#!/bin/bash

# ===============================================
# 更新项目并推送到远端仓库
# ===============================================

echo "🚀 开始更新项目并推送到远端..."
echo ""

# 第一步：为所有脚本添加执行权限
echo "🔧 步骤1: 为脚本文件添加执行权限..."
chmod +x *.sh
echo "✅ 执行权限添加完成"
echo ""

# 第二步：检查git状态
echo "📋 步骤2: 检查git状态..."
git status
echo ""

# 第三步：添加所有修改的文件
echo "📦 步骤3: 添加所有修改的文件..."
git add .
echo "✅ 文件添加完成"
echo ""

# 第四步：提交更改
echo "📝 步骤4: 提交更改..."
git commit -m "feat: 完善构建错误修复和推送工具链 v2.1.3

主要更新:
- 🔧 新增 fix-crypto-error.sh: crypto.getRandomValues 错误一键修复 (111行)
  * 智能环境检查和版本验证
  * 自动清理和重新安装依赖
  * 多种构建策略（标准/开发/兼容模式）
  * 完整的 polyfill 依赖安装
  * 详细的故障排除建议

- 🔧 新增 fix-build-error.sh: 通用构建错误修复 (95行)
  * 系统性构建问题诊断
  * 多方案自动修复策略
  * 构建环境变量优化

- 🚀 新增 push-changes.sh: Git 推送自动化 (70行)
  * 完整的 git 操作流程
  * 详细的提交信息模板

- 🔧 新增 update-and-push.sh: 项目更新推送一体化
  * 自动权限设置
  * 完整的 git 工作流

- ⚙️  更新 start-linux.sh: 增强构建错误处理
  * 集成 crypto 错误自动修复
  * 多种构建方案回退策略
  * 更智能的错误检测和处理

- ⚙️  更新 vite.config.ts: 完善 polyfill 配置
  * 添加 crypto-browserify polyfill
  * 优化全局变量定义
  * 增强构建兼容性

- 📚 更新 README.md: 完善故障排除文档
  * 新增 crypto 错误专门章节
  * 详细的修复步骤说明
  * 项目结构更新

技术改进:
✅ 智能构建错误检测和修复
✅ 完整的环境兼容性处理
✅ 自动化工作流优化
✅ 详细的错误诊断工具
✅ 多方案构建回退策略
✅ 完善的依赖管理
✅ 增强的开发体验"

echo "✅ 提交完成"
echo ""

# 第五步：推送到远端
echo "🌐 步骤5: 推送到远端仓库..."
git push origin main

if [ $? -eq 0 ]; then
    echo "✅ 推送成功！"
    echo ""
    echo "📊 查看最近提交记录:"
    git log --oneline -3
    echo ""
    echo "🎯 本次更新总结:"
    echo "- 新增文件: fix-crypto-error.sh, fix-build-error.sh, update-and-push.sh"
    echo "- 更新文件: start-linux.sh, vite.config.ts, README.md"
    echo "- 功能改进: 构建错误自动修复、工作流自动化"
    echo "- 版本: v2.1.3"
    echo ""
    echo "🔗 新增脚本说明:"
    echo "  • fix-crypto-error.sh - 专门修复 crypto.getRandomValues 错误"
    echo "  • fix-build-error.sh - 通用构建错误修复工具"
    echo "  • update-and-push.sh - 项目更新和推送一体化脚本"
    echo ""
    echo "💡 使用建议:"
    echo "  • 遇到构建错误时先运行: ./fix-crypto-error.sh"
    echo "  • 开发时推荐使用: ./start-linux.sh start --dev"
    echo "  • 项目更新推送: ./update-and-push.sh"
else
    echo "❌ 推送失败，请检查网络连接和权限"
    echo ""
    echo "🔧 故障排除建议:"
    echo "1. 检查网络连接"
    echo "2. 验证 git 远程仓库配置: git remote -v"
    echo "3. 检查 SSH 密钥或账户权限"
    echo "4. 尝试手动推送: git push origin main"
fi

echo ""
echo "🏁 脚本执行完成！"