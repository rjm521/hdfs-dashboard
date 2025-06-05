# HDFS 文件管理平台

这是一个基于 React 和 TypeScript 的 HDFS (Hadoop Distributed File System) 文件管理平台，允许用户通过 Web 界面浏览、上传、下载、重命名、删除 HDFS 中的文件和目录，并提供了文件预览、编辑（文本文件）等功能。

## 🔒 安全更新说明

**最新安全修复 (2024年12月)：**
- ✅ **已修复 CVE-2024-4367 PDF.js 漏洞**：升级 `react-pdf` 从 7.7.0 到 9.2.1
- ✅ **安全配置**：PDF.js 已配置禁用 JavaScript 评估 (`isEvalSupported: false`)
- ✅ **底层依赖更新**：`pdfjs-dist` 已升级到安全版本 (>=4.2.67)
- ⚠️ **注意事项**：升级为主要版本更新，已确认兼容性正常

**安全状态**：所有高危和PDF相关漏洞已修复 ✅

## 特性

*   **目录浏览**: 以树状结构或列表形式清晰展示 HDFS 目录和文件。
*   **文件操作**:
    *   上传文件到 HDFS (通过后端服务代理)。
    *   从 HDFS 下载文件。
    *   创建子目录。
    *   重命名文件和目录。
    *   删除文件和目录 (支持确认提示)。
*   **文件预览**:
    *   文本文件 (如 `.txt`, `.log`, `.json`, `.md`, `.yaml`, `.yml`)。
    *   图片文件 (如 `.jpg`, `.jpeg`, `.png`, `.gif`)。
    *   PDF 文件 (支持分页)。
    *   CSV 文件 (表格预览)。
    *   音频文件 (如 `.mp3`, `.wav`)。
    *   对于不支持直接预览的类型，默认为文本预览或提示下载。
*   **文本文件编辑**: 支持直接在浏览器中编辑文本类文件，并通过重新上传的方式保存更改。
*   **路径导航**:
    *   面包屑导航，方便在目录层级间快速跳转。
*   **文件排序**: 支持按文件名、类型、大小、修改时间对文件列表进行升序或降序排序。
*   **存储信息展示**: 显示 HDFS 的总存储容量、已用空间、剩余空间以及文件总数（部分依赖 HDFS API 能力）。
*   **用户体验**:
    *   采用 Toast 通知替代原生 `alert`，提供更友好的用户反馈。
    *   响应式设计，适应不同屏幕尺寸。
*   **后端代理上传**: 文件上传通过后端 Node.js 服务进行，使用 `curl` 命令与 HDFS WebHDFS API 交互，简化了前端处理复杂性和跨域问题。
*   **配置化**: HDFS 连接参数 (主机、端口、基础路径、用户名、密码) 可在配置文件中进行修改。

## 技术栈

*   **前端**:
    *   React 18
    *   TypeScript
    *   Vite (构建工具)
    *   Tailwind CSS (CSS 框架)
    *   Lucide React (图标库)
    *   `react-pdf` 9.2.1 (PDF 预览 - 已修复安全漏洞)
    *   `papaparse` (CSV 解析)
    *   `react-audio-player` (音频播放)
*   **后端 (用于文件上传代理)**:
    *   Node.js
    *   Express
    *   Multer (文件上传处理中间件)
    *   `child_process` (执行 `curl` 命令)
*   **容器化**:
    *   Docker
    *   Docker Compose

## 项目结构 (部分核心)

```
hdfs-dashboard/
├── public/                     # 静态资源
├── src/
│   ├── components/             # React 组件
│   │   ├── DirectoryView.tsx     # 目录和文件列表视图，包含排序
│   │   ├── FileOperations.tsx  # 文件操作按钮 (如上传)
│   │   ├── FilePreview.tsx     # 文件预览组件
│   │   ├── HdfsConfigModal.tsx # HDFS 配置弹窗
│   │   ├── PathBreadcrumbs.tsx # 路径面包屑导航
│   │   ├── StorageDashboard.tsx# 存储信息面板
│   │   └── ToastContext.tsx    # Toast 通知系统
│   ├── services/               # API 服务调用
│   │   └── realHdfsApi.ts      # 封装 HDFS WebHDFS API 调用
│   ├── App.tsx                 # 主应用组件，管理状态和逻辑
│   ├── main.tsx                # 应用入口点
│   ├── types.ts                # TypeScript 类型定义
│   ├── config.ts               # HDFS 连接配置 (前端)
│   └── index.css               # 全局样式 (Tailwind CSS 基础)
├── server.js                   # 后端 Node.js/Express 服务器 (用于代理文件上传)
├── app.config.json             # 应用主配置文件
├── app.config.production.json  # 生产环境配置模板
├── start-linux.sh              # Linux 一键启动脚本
├── quick-start-example.sh      # 快速启动示例脚本
├── fix-crypto-error.sh         # crypto 构建错误修复脚本
├── fix-build-error.sh          # 通用构建错误修复脚本
├── push-changes.sh             # Git 推送脚本
├── debug-docker.sh             # Docker 调试工具脚本
├── package.json                # 项目依赖和脚本
├── vite.config.ts              # Vite 配置文件 (包含代理设置和 polyfill)
├── Dockerfile                  # Docker 镜像构建文件
├── docker-compose.yml          # Docker Compose 编排文件
├── .dockerignore               # Docker 构建忽略文件
└── README.md                   # 本文档
```

## 常见问题解决

### Crypto 构建错误

如果遇到以下错误信息：
```
TypeError: crypto$2.getRandomValues is not a function
```

或者Vite配置警告：
```
[WARNING] Duplicate key "define" in object literal
```

**自动修复方法：**
1. 使用提供的修复脚本：
   ```bash
   chmod +x manual-fix-crypto.sh
   ./manual-fix-crypto.sh
   ```

**手动修复方法：**
1. 清理环境和缓存：
   ```bash
   rm -rf node_modules package-lock.json dist .vite
   ```

2. 重新安装依赖：
   ```bash
   npm install
   ```

3. 安装必要的polyfill依赖：
   ```bash
   npm install crypto-browserify@^3.12.0 process@^0.11.10 buffer@^6.0.3 path-browserify@^1.0.1
   ```

4. 设置环境变量并启动：
   ```bash
   NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=4096" npm run dev
   ```

**如果问题持续：**
- 尝试使用遗留模式：`npm install --legacy-peer-deps`
- 检查Node.js版本：建议使用Node.js 16.x 或 18.x
- 清理全局npm缓存：`npm cache clean --force`

## 安全最佳实践

### 定期安全检查
建议定期执行以下安全检查命令：

```bash
# 检查安全漏洞
npm audit

# 自动修复非破坏性安全问题
npm audit fix

# 检查过时的依赖包
npm outdated
```

### PDF文件处理安全
- ✅ **已配置安全选项**：PDF.js 禁用了 JavaScript 评估以防止 XSS 攻击
- ✅ **版本控制**：使用最新安全版本的 react-pdf (9.2.1+)
- ⚠️ **注意事项**：仅处理来自可信来源的PDF文件

### 上传文件安全
- 文件大小限制：100MB 最大上传限制
- 文件类型检查：基于文件扩展名和MIME类型验证
- 路径安全：防止目录遍历攻击

### 建议的安全更新周期
- **每月**：执行 `npm audit` 检查新的安全漏洞
- **每季度**：更新所有依赖包到最新稳定版本
- **及时**：当发现高危或关键漏洞时立即修复

## 先决条件

### 传统部署
*   Node.js (建议 v16 或更高版本)
*   npm 或 yarn (包管理器)
*   一个可访问的 HDFS 集群，并已启用 WebHDFS API。
*   `curl` 命令 (后端服务器需要使用)。

### Docker 部署
*   Docker (建议 v20.10 或更高版本)
*   Docker Compose (建议 v2.0 或更高版本)
*   一个可访问的 HDFS 集群，并已启用 WebHDFS API。

## 配置说明

项目使用 `app.config.json` 作为主配置文件，所有硬编码的 IP、端口、用户名等都已配置化。

### 配置文件结构
```json
{
  "hdfs": {
    "namenode": {
      "host": "9.134.167.146",       // HDFS NameNode 主机地址
      "port": "8443",                // HDFS NameNode 端口
      "scheme": "https"              // 协议 (http/https)
    },
    "datanode": {
      "host": "9.134.167.146",       // HDFS DataNode 主机地址
      "port": "50075",               // HDFS DataNode 端口
      "scheme": "http"               // 协议 (http/https)
    },
    "auth": {
      "username": "credit_card_all", // HDFS 用户名
      "password": "credit_card_all"  // HDFS 密码
    },
    "paths": {
      "gatewayPath": "/gateway/fithdfs/webhdfs/v1/", // WebHDFS 网关路径
      "basePath": "wx_credit_card_all"                // HDFS 基础路径
    }
  },
  "server": {
    "backend": { "port": 3001 },     // 后端服务端口
    "frontend": { "port": 5173 }     // 前端服务端口
  },
  "admin": {
    "username": "exampleuser",        // 管理员用户名
    "password": "password"           // 管理员密码
  },
  "session": {
    "secret": "your-secret-key"      // Session 密钥
  },
  "environment": "development"       // 环境标识
}
```

## 安装与启动

### 🚀 超快速启动（推荐新手）

如果你想要最简单的启动方式，只需要一个命令：

```bash
# 克隆仓库
git clone <your-repository-url>
cd hdfs-dashboard

# 配置HDFS连接（可选，使用默认配置也可以）
cp app.config.production.json app.config.json
vim app.config.json

# 一键启动（后台运行，不阻塞终端）
./start.sh
```

就这么简单！服务会自动在后台启动，你的终端可以继续做其他事情。

如果需要管理服务：
```bash
./microservice.sh status   # 查看状态
./microservice.sh logs     # 查看日志
./microservice.sh stop     # 停止服务
```

---

### 方式一：微服务后台启动（推荐，不阻塞终端）

我们提供了专门的微服务管理脚本，服务会在后台运行，不会阻塞你的终端，让你可以继续进行其他操作。

1.  **克隆仓库**
    ```bash
    git clone <your-repository-url>
    cd hdfs-dashboard
    ```

2.  **配置 HDFS 连接**
    ```bash
    # 复制生产环境配置模板（可选）
    cp app.config.production.json app.config.json

    # 编辑配置文件
    vim app.config.json
    ```

    请根据你的 HDFS 环境修改以下关键配置：
    - `hdfs.namenode.host`: NameNode 主机地址
    - `hdfs.namenode.port`: NameNode 端口
    - `hdfs.datanode.host`: DataNode 主机地址
    - `hdfs.datanode.port`: DataNode 端口
    - `hdfs.auth.username`: HDFS 用户名
    - `hdfs.auth.password`: HDFS 密码
    - `hdfs.paths.gatewayPath`: WebHDFS 网关路径
    - `hdfs.paths.basePath`: HDFS 基础路径

3.  **微服务启动**
    ```bash
    # 给脚本添加执行权限
    chmod +x microservice.sh

    # 后台启动所有服务（推荐）
    ./microservice.sh start

    # 或者使用开发模式启动
    ./microservice.sh start --dev

    # 指定端口启动
    ./microservice.sh start -p 8080 -b 3002
    ```

4.  **管理微服务**
    ```bash
    # 查看服务状态
    ./microservice.sh status

    # 查看服务日志（最近20行）
    ./microservice.sh logs

    # 实时跟踪日志
    ./microservice.sh tailf

    # 健康检查
    ./microservice.sh health

    # 重启所有服务
    ./microservice.sh restart

    # 停止所有服务
    ./microservice.sh stop

    # 查看帮助信息
    ./microservice.sh help
    ```

5.  **访问应用**
    启动成功后，服务在后台运行，可直接访问：
    - 前端界面: http://localhost:5173
    - 后端 API: http://localhost:3001
    - 管理员登录: http://localhost:3001/admin/login

#### 微服务启动脚本特性

- 🎯 **后台运行**: 服务在后台运行，终端不被阻塞
- 🚀 **快速启动**: 自动处理依赖安装和构建过程
- 📊 **状态监控**: 实时查看服务运行状态和健康检查
- 📋 **日志管理**: 分离的日志文件和实时日志跟踪
- 🔄 **进程管理**: 自动处理端口冲突和进程重启
- 💡 **用户友好**: 清晰的状态提示和错误处理
- 🛑 **优雅停止**: 正确清理后台进程和资源

### 方式二：Linux 一键启动（交互模式，阻塞终端）

我们还提供了传统的启动脚本，功能完整但会阻塞终端。如果你需要在前台监控服务，可以使用这种方式。

1.  **克隆仓库**
    ```bash
    git clone <your-repository-url>
    cd hdfs-dashboard
    ```

2.  **配置 HDFS 连接**
    ```bash
    # 复制生产环境配置模板（可选）
    cp app.config.production.json app.config.json

    # 编辑配置文件
    vim app.config.json
    ```

    请根据你的 HDFS 环境修改以下关键配置：
    - `hdfs.namenode.host`: NameNode 主机地址
    - `hdfs.namenode.port`: NameNode 端口
    - `hdfs.datanode.host`: DataNode 主机地址
    - `hdfs.datanode.port`: DataNode 端口
    - `hdfs.auth.username`: HDFS 用户名
    - `hdfs.auth.password`: HDFS 密码
    - `hdfs.paths.gatewayPath`: WebHDFS 网关路径
    - `hdfs.paths.basePath`: HDFS 基础路径

3.  **启动服务**
    ```bash
    # 给脚本添加执行权限
    chmod +x start-linux.sh

    # 后台启动服务（守护进程模式，推荐）
    ./start-linux.sh daemon

    # 或者交互模式启动（阻塞终端）
    ./start-linux.sh start

    # 开发模式启动
    ./start-linux.sh daemon --dev
    ```

4.  **使用其他命令**
    ```bash
    # 查看帮助信息
    ./start-linux.sh help

    # 检查环境
    ./start-linux.sh check

    # 查看服务状态
    ./start-linux.sh status

    # 查看日志
    ./start-linux.sh logs

    # 重启服务
    ./start-linux.sh restart

    # 停止服务
    ./start-linux.sh stop

    # 清理临时文件
    ./start-linux.sh clean

    # 仅安装依赖
    ./start-linux.sh install

    # 仅构建前端
    ./start-linux.sh build
    ```

5.  **访问应用**
    启动成功后，脚本会显示访问地址：
    - 前端界面: http://localhost:5173
    - 后端 API: http://localhost:3001
    - 管理员登录: http://localhost:3001/admin/login

6.  **停止服务**
    ```bash
    # 停止所有服务
    ./start-linux.sh stop

    # 或者按 Ctrl+C（如果在前台运行）
    ```

#### Linux 启动脚本特性

- 🔍 **智能环境检查**: 自动检查 Node.js、npm、curl 等依赖
- 📦 **自动依赖管理**: 检测并安装项目依赖
- 🚀 **一键启动**: 同时启动前端和后端服务
- 📊 **实时状态监控**: 检查服务健康状态和端口占用
- 🔧 **灵活配置**: 支持自定义端口和开发/生产模式
- 📋 **完整日志**: 分离的前端和后端日志文件
- 🛑 **优雅停止**: 正确处理进程信号和资源清理
- 🌐 **网络信息**: 自动显示本地和外网访问地址
- 🔄 **进程管理**: PID 文件管理，避免重复启动
- 🧹 **清理工具**: 临时文件和日志清理功能

### 方式三：Docker 部署

1.  **克隆仓库**
    ```bash
    git clone <your-repository-url>
    cd hdfs-dashboard
    ```

2.  **配置 HDFS 连接**

    修改 `app.config.json` 文件，更新其中的 HDFS 连接信息：
    ```bash
    # 复制生产环境配置模板（可选）
    cp app.config.production.json app.config.json

    # 编辑配置文件
    vim app.config.json
    ```

    请根据你的 HDFS 环境修改以下关键配置：
    - `hdfs.namenode.host`: NameNode 主机地址
    - `hdfs.namenode.port`: NameNode 端口
    - `hdfs.datanode.host`: DataNode 主机地址
    - `hdfs.datanode.port`: DataNode 端口
    - `hdfs.auth.username`: HDFS 用户名
    - `hdfs.auth.password`: HDFS 密码
    - `hdfs.paths.gatewayPath`: WebHDFS 网关路径
    - `hdfs.paths.basePath`: HDFS 基础路径
    - `admin.username` 和 `admin.password`: 管理员账户信息
    - `session.secret`: 会话密钥（生产环境请使用强密钥）

3.  **启动服务**
    ```bash
    # 使用 Docker Compose 构建并启动
    docker-compose up -d --build

    # 查看服务状态
    docker-compose ps

    # 查看日志
    docker-compose logs -f
    ```

4.  **访问应用**
    - 前端界面: http://localhost:5173
    - 后端 API: http://localhost:3001
    - 管理员登录: http://localhost:3001/admin/login

5.  **停止服务**
    ```bash
    # 停止服务
    docker-compose down

    # 停止服务并删除数据卷
    docker-compose down -v
    ```

## Docker 部署高级配置

### 环境变量覆盖
可以通过环境变量覆盖配置文件中的设置：

```yaml
# docker-compose.yml
services:
  hdfs-dashboard:
    # ... 其他配置
    environment:
      - NODE_ENV=production
      - HDFS_NAMENODE_HOST=your-namenode-host
      - HDFS_NAMENODE_PORT=8443
      # 更多环境变量...
```

### 外部配置文件
建议在生产环境中将配置文件挂载为外部卷：

```yaml
volumes:
  - ./config/app.config.production.json:/app/app.config.json:ro
```

### 网络配置
如果需要连接到外部 HDFS 集群，确保容器网络配置正确：

```yaml
networks:
  hdfs-network:
    driver: bridge
    external: true  # 使用外部网络
```

### 数据持久化
上传临时目录会自动挂载为卷，确保数据持久化：

```bash
# 查看卷信息
docker volume ls
docker volume inspect hdfs-dashboard_uploads_tmp
```

## 网络配置说明

### 外网访问配置

本项目已配置为支持外网访问：

- **前端服务**: Vite开发服务器绑定到 `0.0.0.0:5173`，允许外网访问
- **后端服务**: Node.js服务器绑定到 `0.0.0.0:3001`，允许外网访问
- **Docker端口映射**: 容器端口映射到主机的所有网络接口

### 访问地址

启动脚本会自动检测并显示：
- **外网访问地址**: `http://YOUR_SERVER_IP:PORT` (其他机器可以访问)
- **本地访问地址**: `http://localhost:PORT` (仅本机访问)

### 防火墙配置

如果无法从外网访问，请检查防火墙设置：

```bash
# Ubuntu/Debian
sudo ufw allow 5173
sudo ufw allow 3001

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=5173/tcp
sudo firewall-cmd --permanent --add-port=3001/tcp
sudo firewall-cmd --reload

# 检查端口监听状态
netstat -tlnp | grep :5173
netstat -tlnp | grep :3001
```

### 安全注意事项

⚠️ **生产环境安全建议**:
- 建议在生产环境中配置反向代理（如Nginx）
- 使用HTTPS保护数据传输
- 配置适当的防火墙规则，限制访问源IP
- 定期更新管理员密码和session密钥

## 使用说明

*   打开浏览器并访问应用运行的地址。
*   如果配置正确，您应该能看到 HDFS 根目录（或 `app.config.json` 中 `basePath` 指定的路径）下的文件和文件夹。
*   **系统配置**: 点击右上角的"系统配置"按钮，可以动态修改 HDFS 连接参数（注意：这些是在前端应用的内存中修改，刷新页面会恢复到配置文件的默认值）。
*   **导航**:
    *   点击文件夹名称进入该文件夹。
    *   使用顶部的面包屑导航返回上级目录或根目录。
*   **文件操作**:
    *   **上传**: 点击"选择文件"并"上传文件"按钮。
    *   **创建文件夹**: 输入文件夹名称，点击"新建子文件夹"。
    *   **重命名/删除**: 鼠标悬停在文件/文件夹行上，会出现相应操作图标（编辑图标为重命名，垃圾桶图标为删除）。
    *   **排序**: 点击列表头部的"名称"、"类型"、"大小"、"修改时间"进行排序。
*   **文件预览与编辑**:
    *   点击文件名进行预览。
    *   对于可编辑的文件类型，预览界面会显示"编辑"按钮，点击后可修改内容，然后点击"保存"按钮重新上传文件。

## 故障排除

### Docker 相关问题

1. **构建失败**
   ```bash
   # 清除 Docker 缓存重新构建
   docker-compose build --no-cache
   ```

2. **端口冲突**
   ```bash
   # 检查端口占用
   netstat -tlnp | grep :5173
   netstat -tlnp | grep :3001

   # 修改 docker-compose.yml 中的端口映射
   ports:
     - "5174:5173"  # 前端端口
     - "3002:3001"  # 后端API端口
   ```

3. **配置文件问题**
   ```bash
   # 检查配置文件格式
   cat app.config.json | python -m json.tool

   # 查看容器内配置
   docker exec hdfs-dashboard cat /app/app.config.json
   ```

4. **网络连接问题**
   ```bash
   # 检查容器网络
   docker network ls
   docker network inspect hdfs-dashboard_hdfs-network

   # 测试容器内网络连接
   docker exec hdfs-dashboard ping your-hdfs-host
   docker exec hdfs-dashboard curl -k https://your-hdfs-host:8443
   ```

### HDFS 连接问题

1. **检查 HDFS 连接**
   - 确保 HDFS 集群正常运行
   - 验证 WebHDFS 已启用
   - 检查网络连通性和防火墙设置
   - 验证用户名和密码正确性

2. **查看日志**
   ```bash
   # 查看容器日志
   docker-compose logs hdfs-dashboard

   # 实时查看日志
   docker-compose logs -f hdfs-dashboard
   ```

## 安全注意事项

1. **生产环境配置**
   - 修改默认的管理员密码
   - 使用强随机字符串作为 session 密钥
   - 考虑使用 HTTPS
   - 限制网络访问权限

2. **HDFS 安全**
   - 使用最小权限原则配置 HDFS 用户
   - 定期更新 HDFS 密码
   - 启用 HDFS 安全认证（Kerberos）

## 开发指南

### 本地开发
```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 启动后端服务
npm run server
```

### 添加新功能
1. 修改前端代码后，重新构建镜像
2. 如果修改了配置结构，同步更新配置文件模板
3. 更新文档说明

### 贡献指南
1. Fork 项目
2. 创建特性分支
3. 提交变更
4. 创建 Pull Request

## 许可证

[添加你的许可证信息]

## 更新日志

### v2.1.1 (最新)
- 🐛 **修复生产环境HDFS API 404错误**: 前端在生产环境下通过后端API代理访问HDFS，解决Vite preview模式不支持代理的问题
- ✅ **后端HDFS API代理**: 添加完整的HDFS API代理端点（GET、PUT、POST、DELETE）
- ✅ **环境适配**: 前端根据开发/生产环境自动选择API调用方式
- ✅ **统一认证**: 生产环境下HDFS认证统一由后端处理，提高安全性

### v2.1.0
- ✅ **修复网络配置问题**: 前端和后端服务正确绑定到 `0.0.0.0`，支持外网访问
- ✅ **生产环境Session优化**: 使用文件存储替代内存存储，消除MemoryStore警告
- ✅ **Vite Preview配置优化**: 修复Docker容器中preview命令的网络绑定问题
- ✅ **安全性增强**: 生产环境session配置更安全，支持cookie安全选项
- ✅ **启动脚本改进**: 自动检测服务器IP，显示正确的外网访问地址

### v2.0.0
- ✅ 项目完全 Docker 化
- ✅ 配置完全外部化，支持环境变量覆盖
- ✅ 移除所有硬编码的 IP、端口配置
- ✅ 添加 Docker Compose 编排支持
- ✅ 添加健康检查和自动重启
- ✅ 优化构建流程和镜像大小
- ✅ 完善部署文档和故障排除指南

## 项目反思与改进建议

### 已完成的重要改进

本项目已成功完成以下重要升级：

#### 1. 配置完全外部化
- **问题**: 原有代码中硬编码了大量IP地址、端口、用户名密码等敏感信息
- **解决方案**: 创建统一的`app.config.json`配置文件，所有配置项可通过外部文件动态修改
- **效果**: 提高了安全性，便于不同环境部署，降低了运维成本

#### 2. Docker容器化部署
- **问题**: 传统部署需要手动安装依赖、配置环境，容易出错
- **解决方案**: 提供完整的Docker解决方案，包括构建、运行、健康检查
- **效果**: 一键部署，环境隔离，便于扩展和维护

### 潜在改进方向

#### 1. 安全性增强
```bash
# 建议为生产环境设置更强的密钥
openssl rand -base64 32  # 生成强session密钥
```

#### 2. 监控和日志
```yaml
# docker-compose.yml 中可添加日志配置
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

#### 3. 环境变量支持
可考虑支持通过环境变量覆盖配置文件设置：
```javascript
// server.js 中可添加环境变量读取
const port = process.env.BACKEND_PORT || appConfig.server.backend.port;
```

#### 4. 健康检查增强
当前健康检查可以更精确地检测HDFS连接状态：
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:3001/health || exit 1
```

#### 5. CI/CD集成
建议添加GitHub Actions或类似的CI/CD配置：
```yaml
# .github/workflows/docker-build.yml
name: Build and Push Docker Image
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
```

### 最佳实践建议

#### 1. 配置管理
- 🔐 **安全配置**: 生产环境必须修改默认密码和密钥
- 📁 **配置分离**: 不同环境使用不同的配置文件
- 🔄 **版本控制**: 配置模板纳入版本控制，实际配置文件排除

#### 2. 运维部署
- 📊 **监控指标**: 建议添加业务指标监控（文件操作成功率、响应时间等）
- 🚨 **告警机制**: HDFS连接失败时的自动告警
- 💾 **数据备份**: 重要配置和日志的定期备份

#### 3. 开发维护
- 🧪 **测试覆盖**: 建议添加单元测试和集成测试
- 📝 **代码规范**: 保持现有的良好代码注释习惯
- 🔄 **版本管理**: 建议使用语义化版本控制

### 故障处理经验

#### 1. Node.js版本兼容性
当前服务器Node.js版本(v18.12.0)可能与某些ESLint包不完全兼容，但不影响核心功能。建议：
```bash
# 开发环境可使用 nvm 管理多版本
nvm install 18.18.0
nvm use 18.18.0
```

#### 2. 依赖安全漏洞
npm audit显示6个安全漏洞，建议定期更新：
```bash
npm audit fix
npm audit fix --force  # 谨慎使用，可能包含破坏性更改
```

#### 3. HDFS连接调试
如遇HDFS连接问题，可通过以下方式调试：
```bash
# 检查网络连通性
curl -k "https://9.134.167.146:8443/gateway/fithdfs/webhdfs/v1/?op=LISTSTATUS"

# 检查认证
curl -k -u "username:password" "https://9.134.167.146:8443/gateway/fithdfs/webhdfs/v1/?op=LISTSTATUS"
```

### 总结

这个项目展现了从传统部署向现代化容器部署的成功转型，通过配置外部化和Docker化，显著提高了项目的可维护性、安全性和部署便利性。建议继续关注安全更新、性能优化和监控完善。

## 🔧 Docker 问题排查指南

### 常见问题与解决方案

#### 1. crypto.getRandomValues 构建错误 🆕

**问题现象**: 运行 `start-linux.sh` 时出现类似错误：
```
TypeError: crypto$2.getRandomValues is not a function
```

**原因分析**:
- Node.js 版本兼容性问题
- 缺少必要的 crypto polyfill
- Vite 配置不完整

**🚀 一键修复方案**:
```bash
# 使用专门的修复脚本
chmod +x fix-crypto-error.sh
./fix-crypto-error.sh
```

**📋 手动修复步骤**:
```bash
# 1. 检查 Node.js 版本
node --version  # 建议 >= v16

# 2. 清理环境
rm -rf node_modules package-lock.json dist

# 3. 安装 polyfill 依赖
npm install --save-dev @types/node crypto-browserify buffer path-browserify

# 4. 设置环境变量
export NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=4096"

# 5. 重新构建
npm run build

# 6. 如果仍然失败，尝试开发模式
npx vite build --mode development
```

**⚡ 绕过方案**:
如果构建仍然失败，可以直接使用开发模式启动：
```bash
./start-linux.sh start --dev  # 跳过构建，直接开发模式
```

#### 2. Docker环境vs本机环境差异

**问题现象**: 项目在本机可以正常运行（`npm run dev`），但在Docker中启动失败或功能异常。

**根本原因**:
- **本机环境**: 使用 `npm run dev`（开发模式），Vite代理配置生效
- **Docker环境**: 使用 `npm run preview`（生产模式），Vite代理配置失效

**环境差异对比**:
| 环境 | 启动方式 | 前端模式 | API路由 | Vite代理状态 |
|------|----------|----------|---------|-------------|
| 本机 | `npm run dev` | 开发模式 | `/namenode-api` | ✅ 生效 |
| Docker | `npm run preview` | 生产模式 | `/api/hdfs` | ❌ 不生效 |

#### 2. 使用Docker诊断工具

我们提供了专门的Docker诊断脚本 `debug-docker.sh`:

```bash
# 给脚本执行权限
chmod +x debug-docker.sh

# 运行诊断工具
./debug-docker.sh
```

**诊断工具功能**:
- ✅ 检查Docker环境和版本
- ✅ 检查容器运行状态
- ✅ 验证端口映射配置
- ✅ 测试容器内服务状态
- ✅ 检查HDFS API代理是否正常
- ✅ 显示访问地址信息
- ✅ 查看容器日志输出

#### 3. Docker启动改进 (v2.1.2)

**问题**: 原Dockerfile启动脚本存在时序问题，后端服务启动不完全就启动前端。

**解决方案**: 已改进Dockerfile启动脚本：

**原启动脚本问题**:
```bash
node server.js &
sleep 2  # ⚠️ 固定等待可能不够
npm run preview &
```

**改进后启动脚本**:
```bash
# 启动后端服务
node server.js &

# 健康检查等待后端完全启动
for i in {1..30}; do
  if curl -s http://localhost:3001/admin/login > /dev/null 2>&1; then
    echo "✅ 后端服务已启动"
    break
  fi
  sleep 1
done

# 测试HDFS API代理是否工作
if curl -s "http://localhost:3001/api/hdfs?op=LISTSTATUS" | grep -q "FileStatuses"; then
  echo "✅ HDFS API代理工作正常"
fi

# 启动前端服务
npm run preview &

# 等待前端服务启动完成
for i in {1..20}; do
  if curl -s http://localhost:5173 > /dev/null 2>&1; then
    echo "✅ 前端服务已启动"
    break
  fi
  sleep 1
done
```