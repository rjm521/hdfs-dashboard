# ==========================================
# 构建阶段：安装所有依赖并构建前端
# ==========================================
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装 curl（用于后端服务与 HDFS 通信）
RUN apk add --no-cache curl

# 复制 package.json 和 package-lock.json
COPY package*.json ./

# 安装所有依赖（包括开发依赖，用于构建）
RUN npm ci

# 复制项目源代码
COPY . .

# 复制配置文件
COPY app.config.json ./

# 构建前端应用
RUN npm run build

# ==========================================
# 生产阶段：只保留生产依赖和构建产物
# ==========================================
FROM node:18-alpine AS production

# 设置工作目录
WORKDIR /app

# 安装 curl（用于后端服务与 HDFS 通信）
RUN apk add --no-cache curl

# 复制 package.json 和 package-lock.json
COPY package*.json ./

# 只安装生产依赖
RUN npm ci --only=production && npm cache clean --force

# 从构建阶段复制构建产物
COPY --from=builder /app/dist ./dist

# 复制运行时需要的文件
COPY server.js ./
COPY app.config.json ./

# 创建上传临时目录
RUN mkdir -p uploads_tmp

# 暴露端口
# 前端端口（由 Nginx 或直接访问）
EXPOSE 5173
# 后端 API 端口
EXPOSE 3001

# 创建改进的启动脚本
RUN echo '#!/bin/sh' > start.sh && \
    echo 'echo "🚀 启动 HDFS 文件管理平台..."' >> start.sh && \
    echo 'echo "📋 配置信息："' >> start.sh && \
    echo 'cat app.config.json' >> start.sh && \
    echo 'echo ""' >> start.sh && \
    echo '' >> start.sh && \
    echo '# 启动后端服务' >> start.sh && \
    echo 'echo "🔧 启动后端服务..."' >> start.sh && \
    echo 'node server.js &' >> start.sh && \
    echo 'BACKEND_PID=$!' >> start.sh && \
    echo '' >> start.sh && \
    echo '# 等待后端服务完全启动' >> start.sh && \
    echo 'echo "⏳ 等待后端服务启动..."' >> start.sh && \
    echo 'BACKEND_READY=false' >> start.sh && \
    echo 'for i in {1..30}; do' >> start.sh && \
    echo '  if curl -s http://localhost:3001/admin/login > /dev/null 2>&1; then' >> start.sh && \
    echo '    echo "✅ 后端服务已启动 (尝试 $i/30)"' >> start.sh && \
    echo '    BACKEND_READY=true' >> start.sh && \
    echo '    break' >> start.sh && \
    echo '  fi' >> start.sh && \
    echo '  echo "⏳ 等待后端服务... ($i/30)"' >> start.sh && \
    echo '  sleep 1' >> start.sh && \
    echo 'done' >> start.sh && \
    echo '' >> start.sh && \
    echo 'if [ "$BACKEND_READY" = "false" ]; then' >> start.sh && \
    echo '  echo "❌ 后端服务启动失败，请检查日志"' >> start.sh && \
    echo '  exit 1' >> start.sh && \
    echo 'fi' >> start.sh && \
    echo '' >> start.sh && \
    echo '# 测试HDFS API代理' >> start.sh && \
    echo 'echo "🔍 测试HDFS API代理..."' >> start.sh && \
    echo 'if curl -s "http://localhost:3001/api/hdfs?op=LISTSTATUS" | grep -q "FileStatuses"; then' >> start.sh && \
    echo '  echo "✅ HDFS API代理工作正常"' >> start.sh && \
    echo 'else' >> start.sh && \
    echo '  echo "⚠️  HDFS API代理可能有问题，但继续启动前端..."' >> start.sh && \
    echo 'fi' >> start.sh && \
    echo '' >> start.sh && \
    echo '# 启动前端服务' >> start.sh && \
    echo 'echo "🌐 启动前端服务..."' >> start.sh && \
    echo 'npm run preview &' >> start.sh && \
    echo 'FRONTEND_PID=$!' >> start.sh && \
    echo '' >> start.sh && \
    echo '# 等待前端服务启动' >> start.sh && \
    echo 'echo "⏳ 等待前端服务启动..."' >> start.sh && \
    echo 'FRONTEND_READY=false' >> start.sh && \
    echo 'for i in {1..20}; do' >> start.sh && \
    echo '  if curl -s http://localhost:5173 > /dev/null 2>&1; then' >> start.sh && \
    echo '    echo "✅ 前端服务已启动 (尝试 $i/20)"' >> start.sh && \
    echo '    FRONTEND_READY=true' >> start.sh && \
    echo '    break' >> start.sh && \
    echo '  fi' >> start.sh && \
    echo '  echo "⏳ 等待前端服务... ($i/20)"' >> start.sh && \
    echo '  sleep 1' >> start.sh && \
    echo 'done' >> start.sh && \
    echo '' >> start.sh && \
    echo '# 显示访问信息' >> start.sh && \
    echo 'echo ""' >> start.sh && \
    echo 'echo "🎉 服务启动完成！"' >> start.sh && \
    echo 'SERVER_IP=$(hostname -i | awk "{print \$1}")' >> start.sh && \
    echo 'echo "📱 外网访问地址："' >> start.sh && \
    echo 'echo "   前端界面: http://\$SERVER_IP:5173"' >> start.sh && \
    echo 'echo "   后端API:  http://\$SERVER_IP:3001"' >> start.sh && \
    echo 'echo "   管理面板: http://\$SERVER_IP:3001/admin/login"' >> start.sh && \
    echo 'echo ""' >> start.sh && \
    echo 'echo "📱 本地访问地址："' >> start.sh && \
    echo 'echo "   前端界面: http://localhost:5173"' >> start.sh && \
    echo 'echo "   后端API:  http://localhost:3001"' >> start.sh && \
    echo 'echo "   管理面板: http://localhost:3001/admin/login"' >> start.sh && \
    echo 'echo ""' >> start.sh && \
    echo 'if [ "$FRONTEND_READY" = "true" ]; then' >> start.sh && \
    echo '  echo "✅ 所有服务启动正常"' >> start.sh && \
    echo 'else' >> start.sh && \
    echo '  echo "⚠️  前端服务启动可能有问题"' >> start.sh && \
    echo 'fi' >> start.sh && \
    echo 'echo ""' >> start.sh && \
    echo 'echo "📋 服务状态："' >> start.sh && \
    echo 'echo "   后端进程: $BACKEND_PID"' >> start.sh && \
    echo 'echo "   前端进程: $FRONTEND_PID"' >> start.sh && \
    echo 'echo ""' >> start.sh && \
    echo 'echo "🛑 按 Ctrl+C 停止服务"' >> start.sh && \
    echo '' >> start.sh && \
    echo '# 设置信号处理' >> start.sh && \
    echo 'trap "echo \"🛑 正在停止服务...\"; kill \$BACKEND_PID \$FRONTEND_PID 2>/dev/null; echo \"✅ 服务已停止\"; exit" INT TERM' >> start.sh && \
    echo '' >> start.sh && \
    echo '# 保持容器运行' >> start.sh && \
    echo 'wait' >> start.sh && \
    chmod +x start.sh

# 设置环境变量
ENV NODE_ENV=production

# 启动应用
CMD ["./start.sh"]