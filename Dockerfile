# 使用官方 Node.js 运行时作为基础镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 安装 curl（用于后端服务与 HDFS 通信）
RUN apk add --no-cache curl

# 复制 package.json 和 package-lock.json
COPY package*.json ./

# 安装项目依赖
RUN npm ci --only=production

# 复制项目源代码
COPY . .

# 复制配置文件
COPY app.config.json ./

# 构建前端应用
RUN npm run build

# 创建上传临时目录
RUN mkdir -p uploads_tmp

# 暴露端口
# 前端端口（由 Nginx 或直接访问）
EXPOSE 5173
# 后端 API 端口
EXPOSE 3001

# 创建启动脚本
RUN echo '#!/bin/sh' > start.sh && \
    echo 'echo "启动 HDFS 文件管理平台..."' >> start.sh && \
    echo 'echo "配置信息："' >> start.sh && \
    echo 'cat app.config.json' >> start.sh && \
    echo 'echo ""' >> start.sh && \
    echo 'echo "启动后端服务..."' >> start.sh && \
    echo 'node server.js &' >> start.sh && \
    echo 'BACKEND_PID=$!' >> start.sh && \
    echo 'sleep 2' >> start.sh && \
    echo 'echo "启动前端服务..."' >> start.sh && \
    echo 'npm run preview --host 0.0.0.0 &' >> start.sh && \
    echo 'FRONTEND_PID=$!' >> start.sh && \
    echo 'echo "服务启动完成"' >> start.sh && \
    echo 'echo "前端访问地址: http://localhost:5173"' >> start.sh && \
    echo 'echo "后端 API 地址: http://localhost:3001"' >> start.sh && \
    echo 'echo "按 Ctrl+C 停止服务"' >> start.sh && \
    echo 'trap "echo \"正在停止服务...\"; kill $BACKEND_PID $FRONTEND_PID; exit" INT TERM' >> start.sh && \
    echo 'wait' >> start.sh && \
    chmod +x start.sh

# 设置环境变量
ENV NODE_ENV=production

# 启动应用
CMD ["./start.sh"]