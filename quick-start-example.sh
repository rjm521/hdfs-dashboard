#!/bin/bash

# ===============================================
# HDFS Dashboard 快速启动示例
# 功能：演示如何使用 Linux 启动脚本
# 版本：v2.1.2
# ===============================================

echo "🚀 HDFS Dashboard 快速启动示例"
echo "=================================="

echo ""
echo "📋 步骤1: 检查环境依赖"
echo "./start-linux.sh check"
echo ""

echo "📋 步骤2: 配置 HDFS 连接"
echo "cp app.config.production.json app.config.json"
echo "vim app.config.json  # 修改 HDFS 连接信息"
echo ""

echo "📋 步骤3: 一键启动服务"
echo "./start-linux.sh start"
echo ""

echo "📋 步骤4: 查看服务状态"
echo "./start-linux.sh status"
echo ""

echo "📋 步骤5: 查看日志（可选）"
echo "./start-linux.sh logs"
echo ""

echo "📋 步骤6: 停止服务"
echo "./start-linux.sh stop"
echo ""

echo "🔧 其他常用命令："
echo "  ./start-linux.sh help           # 查看帮助"
echo "  ./start-linux.sh start --dev    # 开发模式启动"
echo "  ./start-linux.sh restart        # 重启服务"
echo "  ./start-linux.sh clean          # 清理临时文件"
echo ""

echo "🌐 默认访问地址："
echo "  前端界面: http://localhost:5173"
echo "  后端API:  http://localhost:3001"
echo "  管理面板: http://localhost:3001/admin/login"
echo ""

echo "💡 提示："
echo "1. 脚本会自动检查并安装 Node.js、npm 等依赖"
echo "2. 首次启动会自动安装项目依赖"
echo "3. 生产模式需要先构建前端（自动完成）"
echo "4. 开发模式支持热重载，适合开发调试"
echo "5. 所有日志保存在 logs/ 目录下"
echo "6. PID 文件保存在 pids/ 目录下"
echo ""

# 检查是否存在启动脚本
if [ -f "start-linux.sh" ]; then
    echo "✅ 启动脚本已就绪！"
    echo ""
    echo "是否现在执行环境检查？[y/N]"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        chmod +x start-linux.sh
        ./start-linux.sh check
    fi
else
    echo "❌ 启动脚本 start-linux.sh 不存在！"
    echo "请确保您在项目根目录下运行此脚本。"
fi