#!/bin/bash

# ===============================================
# Git 推送脚本
# 功能：自动执行git add、commit、push操作
# ===============================================

echo "🚀 开始推送代码到远端仓库..."

# 检查git状态
echo "📋 检查git状态..."
git status

echo ""
echo "📦 添加所有修改的文件..."
git add .

echo ""
echo "📝 提交更改..."
git commit -m "feat: 添加Linux一键启动脚本和快速启动示例 v2.1.2

主要更新:
- 新增 start-linux.sh: 功能完整的Linux启动脚本(795行)
  * 智能环境检查(Node.js、npm、curl等)
  * 自动依赖安装和前端构建
  * 开发/生产模式支持
  * 端口冲突检测和解决
  * 实时服务状态监控
  * 完整的日志管理系统
  * 优雅的服务启停控制
  * 临时文件清理功能

- 新增 quick-start-example.sh: 快速启动示例和使用指导(73行)
  * 详细的操作步骤演示
  * 常用命令使用示例
  * 最佳实践建议

- 更新 README.md: 重构文档结构(1041行)
  * Linux一键启动作为首选部署方式
  * 完整的三种部署方案对比
  * 详细的故障排除指南
  * Docker vs Linux部署优缺点分析
  * 网络配置和安全建议

技术特性:
✅ 智能环境依赖检查
✅ 自动化服务管理
✅ 实时健康状态监控
✅ 分离式日志管理
✅ 灵活的配置选项
✅ 优雅的错误处理
✅ 完整的清理工具
✅ 外网访问支持"

echo ""
echo "🌐 推送到远端仓库..."
git push origin main

echo ""
echo "✅ 推送完成！"
echo ""
echo "📊 查看最近提交记录:"
git log --oneline -3

echo ""
echo "🎯 推送内容总结:"
echo "- 新增文件: start-linux.sh, quick-start-example.sh"
echo "- 修改文件: README.md"
echo "- 总代码行数: 1900+ 行"
echo "- 版本: v2.1.2"