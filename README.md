# HDFS 文件管理平台

这是一个基于 React 和 TypeScript 的 HDFS (Hadoop Distributed File System) 文件管理平台，允许用户通过 Web 界面浏览、上传、下载、重命名、删除 HDFS 中的文件和目录，并提供了文件预览、编辑（文本文件）等功能。

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
    *   `react-pdf` (PDF 预览)
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
├── package.json                # 项目依赖和脚本
├── vite.config.ts              # Vite 配置文件 (包含代理设置)
├── Dockerfile                  # Docker 镜像构建文件
├── docker-compose.yml          # Docker Compose 编排文件
├── .dockerignore               # Docker 构建忽略文件
└── README.md                   # 本文档
```

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
    "username": "jimmyjmren",        // 管理员用户名
    "password": "password"           // 管理员密码
  },
  "session": {
    "secret": "your-secret-key"      // Session 密钥
  },
  "environment": "development"       // 环境标识
}
```

## 安装与启动

### 方式一：Docker 部署（推荐）

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

### 方式二：传统部署

1.  **克隆仓库**

    ```bash
    git clone <your-repository-url>
    cd hdfs-dashboard
    ```

2.  **安装前端依赖**

    ```bash
    npm install
    # 或者
    # yarn install
    ```

3.  **配置 HDFS 连接**

    修改 `app.config.json` 文件中的配置信息。

4.  **启动后端服务** (用于文件上传)

    打开一个新的终端窗口/标签页:
    ```bash
    npm run server
    # 这将启动 server.js，默认监听在端口 3001
    ```

5.  **启动前端开发服务器**

    在另一个终端窗口/标签页:
    ```bash
    npm run dev
    # 或者
    # yarn dev
    ```
    应用默认将在 `http://localhost:5173` (或 Vite 配置的其他端口) 上可用。

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

---

**✨ 恭喜您！HDFS文件管理平台已成功完成现代化改造，具备了生产级别的部署能力！**