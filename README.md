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
*   **配置化**: HDFS 连接参数 (主机、端口、基础路径、用户名、密码) 可在前端配置模块中进行修改。

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

## 项目结构 (部分核心)

```
.sb1-87shgo/
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
├── package.json                # 项目依赖和脚本
├── vite.config.ts              # Vite 配置文件 (包含代理设置)
└── README.md                   # 本文档
```

## 先决条件

*   Node.js (建议 v16 或更高版本)
*   npm 或 yarn (包管理器)
*   一个可访问的 HDFS 集群，并已启用 WebHDFS API。
*   `curl` 命令 (后端服务器需要使用)。

## 安装与启动

1.  **克隆仓库**

    ```bash
    git clone <your-repository-url>
    cd hdfs-dashboard-project/sb1-87shgo
    ```

2.  **安装前端依赖**

    ```bash
    npm install
    # 或者
    # yarn install
    ```

3.  **安装后端依赖** (如果 `server.js` 中的依赖没有被包含在主 `package.json` 的 `dependencies` 中，理论上它们应该被包含)

    如果 `express` 和 `multer` 未作为项目主依赖，请确保它们已安装，或者在 `package.json` 中添加并重新运行 `npm install`。

4.  **配置 HDFS 连接**

    *   **前端配置**: 
        修改 `src/config.ts` 文件，更新 `hdfsConfig` 对象中的以下字段以匹配您的 HDFS 环境：
        ```typescript
        let hdfsConfig: HdfsConfig = {
          hdfsHost: 'YOUR_HDFS_NAMENODE_HOST',       // 例如 'namenode.example.com' 或 IP 地址
          hdfsPort: 'YOUR_HDFS_WEBHFDS_PORT',    // 例如 '50070' (http) 或 '50470'/ '8443' (https)
          baseUrl: '/webhdfs/v1/YOUR_BASE_PATH', // WebHDFS API 基础路径, 例如 '/webhdfs/v1/' 或针对特定用户/服务的路径 
          username: 'YOUR_HDFS_USERNAME',         // 访问 HDFS 的用户名 (如果需要认证)
          password: 'YOUR_HDFS_PASSWORD',         // 访问 HDFS 的密码 (如果需要认证)
        };
        ```
        当前的默认配置是：
        ```typescript
        let hdfsConfig: HdfsConfig = {
          hdfsHost: '9.134.167.146',
          hdfsPort: '8443',
          baseUrl: '/gateway/fithdfs/webhdfs/v1/wx_credit_card_all',
          username: 'credit_card_all',
          password: 'credit_card_all',
        };
        ```
        **注意**: `baseUrl` 通常以 `/webhdfs/v1/` 开头，后面可以是你希望作为根目录的路径。

    *   **后端 `curl` 命令配置**: 
        打开 `server.js` 文件。定位到 `/api/upload-to-hdfs-via-server` 路由处理器中的 `curl` 命令。您需要根据您的 HDFS 集群配置（特别是认证和 WebHDFS 端点）修改此命令：
        ```javascript
        const curlCommand = `curl -k -u ${username}:${password} -L -X PUT 'https://${hdfsHost}:${hdfsPort}${hdfsBasePathForCurl}${filePathInHdfs}?op=CREATE&overwrite=true&user.name=${username}' -T ${tempFilePath}`;
        // 其中 username, password, hdfsHost, hdfsPort, hdfsBasePathForCurl 来自前端通过请求体传递或硬编码/环境变量配置。
        // 当前 server.js 实现中，这些参数部分硬编码，部分来自 HDFS_PATH 变量的构造，可能需要调整以适应您的环境。
        // 特别注意 -k (允许不安全的 SSL 连接，生产环境慎用), -u (用户认证), 以及 HTTPS/HTTP 和端口。
        // 示例中的命令: `curl -k -u credit_card_all:credit_card_all -L -X PUT 'https://9.134.167.146:8443/gateway/fithdfs/webhdfs/v1/${HDFS_PATH}?op=create&overwrite=true' -T ${TEMP_FILE_PATH}`
        // 需要确保 HDFS_PATH 构造的路径是正确的，并且 WebHDFS API 端点是准确的。
        ```
        请确保 `server.js` 中的 `curl` 命令的目标 URL (`https://9.134.167.146:8443/gateway/fithdfs/webhdfs/v1/`) 和认证信息 (`credit_card_all:credit_card_all`) 与您的 HDFS 集群设置一致。

    *   **Vite 代理配置**: 
        检查 `vite.config.ts` 中的代理设置。这些代理用于将前端 API 请求转发到实际的 HDFS NameNode 和 DataNode，以及后端的 `server.js`。
        ```typescript
        server: {
          port: 5173, // 前端开发服务器端口
          proxy: {
            '/namenode-api': { // 用于浏览、元数据等操作
              target: 'https://YOUR_HDFS_NAMENODE_HOST:PORT', // NameNode WebHDFS 地址
              changeOrigin: true,
              rewrite: (path) => path.replace(/^\/namenode-api/, '/gateway/fithdfs/webhdfs/v1/'), // 根据实际 HDFS 路径调整
            },
            '/datanode-api': { // 用于文件 OPEN, GETFILECHECKSUM 等 DataNode 操作
              target: 'http://YOUR_DATANODE_HOST_OR_NAMENODE_PROXYING_DATANODE_OPS:PORT', // DataNode 或 NameNode (如果它代理 DataNode 操作) 的 HTTP 地址
              changeOrigin: true,
              rewrite: (path) => path.replace(/^\/datanode-api/, ''), // WebHDFS 返回的 DataNode URL 通常是完整的，可能不需要重写路径前缀，或者需要根据情况调整
            },
            '/api': { // 用于后端 Express API (如文件上传)
              target: 'http://localhost:3001', // 后端服务地址
              changeOrigin: true,
              // rewrite: (path) => path.replace(/^\/api/, '') // 如果后端路由没有 /api 前缀
            }
          }
        }
        ```
        您需要将 `target` URL 更新为您的 HDFS NameNode 和 DataNode (或代理) 的实际地址和端口。`rewrite` 规则也可能需要根据 HDFS 集群的 WebHDFS 路径结构进行调整。

5.  **启动后端服务** (用于文件上传)

    打开一个新的终端窗口/标签页:
    ```bash
    npm run server
    # 这将使用 nodemon (如果配置了) 或直接 node 启动 server.js，默认监听在端口 3001
    ```

6.  **启动前端开发服务器**

    在另一个终端窗口/标签页:
    ```bash
    npm run dev
    # 或者
    # yarn dev
    ```
    应用默认将在 `http://localhost:5173` (或 Vite 配置的其他端口) 上可用。

## 使用说明

*   打开浏览器并访问应用运行的地址。
*   如果配置正确，您应该能看到 HDFS 根目录（或 `src/config.ts` 中 `baseUrl` 指定的路径）下的文件和文件夹。
*   **系统配置**: 点击右上角的"系统配置"按钮，可以动态修改 HDFS 连接参数（注意：这些是在前端应用的内存中修改，刷新页面会恢复到 `config.ts` 的默认值，如果需要持久化，需要其他机制）。
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
    *   可以下载文件。

## 注意事项与潜在问题

*   **CORS**: WebHDFS API 可能有跨域资源共享 (CORS) 限制。本项目通过 Vite 的代理功能来规避前端直接请求 HDFS 时的 CORS 问题。确保 Vite 代理配置正确。
*   **HTTPS/HTTP**: HDFS WebHDFS API 可能通过 HTTP 或 HTTPS 提供服务。确保 `config.ts` 和 `vite.config.ts` 以及 `server.js` 中的 `curl` 命令使用了正确的协议和端口。
*   **WebHDFS 路径**: HDFS WebHDFS 的路径结构（特别是对于需要重定向到 DataNode 的操作，如 OPEN 和 CREATE 的第二步）可能因 HDFS 版本和配置而异。`realHdfsApi.ts` 中的路径构造和 Vite 代理的 `rewrite` 规则需要与您的环境匹配。
*   **认证**: 如果 HDFS 启用了认证（如 Kerberos 或简单的用户名/密码），确保 `config.ts` 和 `server.js` 中的 `curl` 命令正确配置了认证信息。
*   **DataNode 访问**: 客户端浏览器或运行 Vite/Node.js 的服务器可能需要直接访问 HDFS DataNode 的 IP 地址和端口。确保网络策略允许这种访问。
*   **大文件上传**: `server.js` 使用 `multer` 将文件暂存到服务器本地，然后再通过 `curl` 上传。对于非常大的文件，这可能会消耗较多服务器资源和时间。考虑流式上传或分块上传作为未来优化。
*   **错误处理**: 当前错误处理主要通过 Toast 通知。更详细的日志和错误排查可能需要在浏览器开发者工具和后端服务器日志中查看。

## 未来可考虑的增强功能

*   **多选操作**: 支持同时选择多个文件/文件夹进行批量删除、移动等。
*   **文件移动/复制**: 实现文件和文件夹的移动、复制功能。
*   **权限管理预览**: （如果 API 支持）显示文件/文件夹的权限信息。
*   **搜索功能**: 在当前目录或全局搜索文件/文件夹。
*   **更高级的预览**: 支持更多文件类型，如视频、代码高亮等。
*   **配置持久化**: 将"系统配置"中的更改持久化到浏览器 localStorage 或后端。
*   **国际化 (i18n)**: 支持多种语言界面。

## 贡献

欢迎提交 Pull Requests 或报告 Issues。

---

_本文档由 AI 辅助生成，请根据实际项目情况进行调整和完善。_ 