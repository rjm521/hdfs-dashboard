import express from 'express';
import multer from 'multer';
import { exec } from 'child_process'; // exec is generally preferred over execSync for non-blocking ops
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import session from 'express-session'; // Added for session management
import FileStore from 'session-file-store'; // 添加文件存储支持

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 创建文件存储 session store
const FileStoreSession = FileStore(session);

// 读取应用配置文件
let appConfig = {};
try {
  const configPath = path.join(__dirname, 'app.config.json');
  const configFile = fs.readFileSync(configPath, 'utf8');
  appConfig = JSON.parse(configFile);
  console.log('后端服务已加载应用配置:', configPath);
} catch (error) {
  console.error('无法加载应用配置文件，使用默认配置:', error);
  // 默认配置
  appConfig = {
    hdfs: {
      namenode: { host: '9.134.167.146', port: '8443', scheme: 'https' },
      auth: { username: 'credit_card_all', password: 'credit_card_all' },
      paths: { gatewayPath: '/gateway/fithdfs/webhdfs/v1/', basePath: 'wx_credit_card_all' }
    },
    server: { backend: { port: 3001 } },
    admin: { username: 'jimmyjmren', password: 'password' },
    session: { secret: 'your-secret-key-change-this-in-production' }
  };
}

const { hdfs, server, admin, session: sessionConfig } = appConfig;

const app = express();
const PORT = server.backend.port; // 从配置读取端口

// Middleware to parse JSON bodies
app.use(express.json());

// 创建 session 存储目录
const sessionDir = path.join(__dirname, 'sessions');
if (!fs.existsSync(sessionDir)) {
  fs.mkdirSync(sessionDir, { recursive: true });
}

// Session configuration - 针对生产环境优化
const sessionConfig_final = {
  secret: sessionConfig.secret,
  resave: false,
  saveUninitialized: false, // 生产环境设为 false
  cookie: {
    secure: false, // 如果使用 HTTPS 则设为 true
    httpOnly: true, // 防止 XSS 攻击
    maxAge: 24 * 60 * 60 * 1000 // 24小时过期
  }
};

// 根据环境选择不同的存储方式
if (process.env.NODE_ENV === 'production') {
  // 生产环境使用文件存储
  sessionConfig_final.store = new FileStoreSession({
    path: sessionDir,
    ttl: 86400, // 24小时 TTL
    retries: 3,
    logFn: () => {} // 禁用文件存储的日志输出
  });
  console.log(`生产环境: 使用文件存储session (${sessionDir})`);
} else {
  // 开发环境可以继续使用内存存储
  console.log('开发环境: 使用内存存储session');
}

app.use(session(sessionConfig_final));

// 使用配置中的管理员账户信息
const adminConfig = {
  adminUsername: admin.username,
  adminPassword: admin.password
};

// Multer 配置：将上传的文件保存到 'uploads_tmp/' 目录
const UPLOAD_DIR = path.join(__dirname, 'uploads_tmp');
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, UPLOAD_DIR);
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + '-' + file.originalname.replace(/\s+/g, '_')); // Replace spaces in filename
  }
});
const upload = multer({ storage: storage });

// Serve static files from 'src' directory (for admin pages)
app.use('/admin/static', express.static(path.join(__dirname, 'src')));

// Route to serve the admin login page
app.get('/admin/login', (req, res) => {
    res.sendFile(path.join(__dirname, 'src', 'admin-login.html'));
});

// Admin login endpoint
app.post('/admin/login', (req, res) => {
    const { username, password } = req.body;
    if (username === adminConfig.adminUsername && password === adminConfig.adminPassword) {
        req.session.isAdmin = true;
        res.json({ success: true, message: 'Login successful' });
    } else {
        res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
});

// Middleware to protect admin routes
function requireAdminLogin(req, res, next) {
    if (req.session.isAdmin) {
        next();
    } else {
        res.redirect('/admin/login');
    }
}

// Route to serve the admin dashboard page
app.get('/admin/dashboard', requireAdminLogin, (req, res) => {
    res.sendFile(path.join(__dirname, 'src', 'admin-dashboard.html'));
});

// Admin logout endpoint
app.get('/admin/logout', (req, res) => {
    req.session.destroy(err => {
        if (err) {
            return res.status(500).send('Could not log out.');
        }
        res.redirect('/admin/login');
    });
});

app.post('/upload-to-hdfs-via-server', upload.single('file'), (req, res) => {
  const file = req.file;
  const hdfsBasePath = req.body.hdfsPath;

  if (!file) {
    return res.status(400).json({ message: '错误：没有文件被上传。' });
  }
  if (!hdfsBasePath) {
    fs.unlinkSync(file.path); // 删除已上传的临时文件
    return res.status(400).json({ message: '错误：HDFS 目标路径未提供。' });
  }

  const tempFilePath = file.path;
  const originalFileName = req.file.originalname; // 使用 multer 清理过的原始文件名
  const hdfsDestinationPath = path.posix.join(hdfsBasePath, originalFileName.replace(/\s+/g, '_')); // Ensure consistent filename

  // 使用配置的HDFS认证信息
  const hdfsUser = `${hdfs.auth.username}:${hdfs.auth.password}`;
  // 使用配置的HDFS连接信息构建URL
  const nameNodeUrl = `${hdfs.namenode.scheme}://${hdfs.namenode.host}:${hdfs.namenode.port}${hdfs.paths.gatewayPath}${hdfsDestinationPath}?op=CREATE&overwrite=true`;

  // 在 Windows 上，tempFilePath 可能包含反斜杠，需要处理。
  // 对于 curl -T，路径最好是 POSIX 风格的，或者确保引号正确处理了 Windows 路径。
  // Multer 生成的 file.path 通常是适合当前操作系统的，但为了 curl 的健壮性，可以替换反斜杠。
  const normalizedTempFilePath = tempFilePath.replace(/\\/g, "/");

  const curlCmd = `curl -k -u "${hdfsUser}" -L -X PUT "${nameNodeUrl}" -T "${normalizedTempFilePath}"`;

  console.log(`[Server] 准备执行 HDFS 上传命令:`);
  console.log(curlCmd);

  exec(curlCmd, (error, stdout, stderr) => {
    fs.unlink(tempFilePath, (unlinkErr) => {
      if (unlinkErr) {
        console.error(`[Server] 删除临时文件 ${tempFilePath} 失败:`, unlinkErr);
      } else {
        console.log(`[Server] 临时文件 ${tempFilePath} 已删除。`);
      }
    });

    if (error) {
      console.error(`[Server] HDFS 上传执行错误:`, error);
      console.error(`[Server] HDFS 上传 stderr:`, stderr);
      return res.status(500).json({ message: `HDFS 上传失败: ${stderr || error.message}` });
    }

    console.log(`[Server] HDFS 上传 stdout:`, stdout);
    if (stderr){
        console.warn("[Server] HDFS 上传 stderr (可能包含非致命警告或信息):", stderr);
    }

    // 基于您的 curl 命令，它使用 -L，所以会跟随重定向。
    // 成功的标志是最终的 DataNode 返回 201 Created (对于 PUT op=CREATE)。
    // 但是 curl -L 默认不输出最终的 HTTP 状态码，stdout 可能为空，stderr 可能包含进度。
    // 最好的方法是让 curl 通过 -w "%{http_code}" 输出 HTTP 状态码，然后检查它。
    // 临时的简化检查：如果 error 为 null 且 stderr 不包含明确的错误，则认为可能成功。
    // 注意：HDFS 返回的 Location 可能非常长，stderr 也可能包含这些信息，不一定是错误。
    // 例如，HDFS 可能会在 stderr 中打印 "100 Continue" 状态，这不是错误。

    // 让我们假设如果 'error' 对象不存在，并且 stderr 不包含某些关键词，则上传成功。
    // 这部分判断逻辑可能需要根据实际的 curl 输出来细化。
    const probableErrorKeywords = ['Failed', 'failed', 'Error', 'error', 'Could not resolve host', 'Connection refused'];
    let hasProbableErrorInStderr = false;
    if (stderr) {
        for (const keyword of probableErrorKeywords) {
            if (stderr.includes(keyword)) {
                // 排除已知的非错误信息，例如 HDFS 返回的 Location URL 可能很长，包含 error=... 参数，但不是 curl 的错误。
                // 例如，避免将 `&error_param=some_value` 误判为错误。
                if (!(stderr.includes("Location:") && keyword === "error")) { // 简单排除 Location 中的 error
                    hasProbableErrorInStderr = true;
                    break;
                }
            }
        }
    }

    if (hasProbableErrorInStderr) {
        console.error(`[Server] HDFS 上传 stderr 中检测到可能的失败信息:`, stderr);
        return res.status(500).json({ message: `HDFS 上传可能失败: ${stderr}` });
    }

    console.log(`[Server] 文件 ${originalFileName} 成功上传到 ${hdfsDestinationPath}`);
    res.json({ message: `文件 ${originalFileName} 成功上传到 HDFS 路径 ${hdfsDestinationPath}` });
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`后端服务器运行在 http://0.0.0.0:${PORT}`);
  console.log(`外网访问地址: http://YOUR_SERVER_IP:${PORT}`);
  console.log(`临时上传目录: ${UPLOAD_DIR}`);
  console.log(`HDFS配置: ${hdfs.namenode.scheme}://${hdfs.namenode.host}:${hdfs.namenode.port}`);
});