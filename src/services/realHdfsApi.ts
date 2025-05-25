// 导入必要的模块和类型
import 'whatwg-fetch';
import { Buffer } from 'buffer'
import path from 'path-browserify';
import { Readable } from 'stream';
import { HDFSFile, StorageInfo } from '../types';
import { getHdfsConfig } from '../config';

// 检测是否在开发环境中
const isDevelopment = import.meta.env.DEV;

// 根据环境选择API前缀
const NAME_NODE_PROXY_PREFIX = isDevelopment ? '/namenode-api' : '/api/hdfs';
// DATA_NODE_PROXY_PREFIX is not strictly needed here as the rewritten Location header will be used directly

function getDefaultHeaders(): HeadersInit {
  // 在生产环境下，认证将由后端处理，所以不需要添加Authorization头
  if (isDevelopment) {
    const { username, password } = getHdfsConfig();
    const auth = Buffer.from(`${username}:${password}`).toString('base64');
    return {
      'Authorization': `Basic ${auth}`,
    };
  }
  return {};
}

interface HDFSFileStatus {
  pathSuffix: string;
  type: 'FILE' | 'DIRECTORY' | string;
  length: number;
  modificationTime: number; // 从 HDFS API 获取的时间戳
  // ... 可根据需要添加其他属性
}

interface HDFSFileStatuses {
  FileStatuses: {
    FileStatus: HDFSFileStatus[];
  };
}

// 定义 MIME 类型映射
const mimeTypes: { [key: string]: string } = {
    '.txt': 'text/plain',
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.json': 'application/json',
    '.xml': 'application/xml',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.bmp': 'image/bmp',
    '.webp': 'image/webp',
    '.svg': 'image/svg+xml',
    '.pdf': 'application/pdf',
    '.doc': 'application/msword',
    '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.xls': 'application/vnd.ms-excel',
    '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    '.ppt': 'application/vnd.ms-powerpoint',
    '.pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    '.zip': 'application/zip',
    '.rar': 'application/x-rar-compressed',
    '.7z': 'application/x-7z-compressed',
    '.mp3': 'audio/mpeg',
    '.wav': 'audio/wav',
    '.mp4': 'video/mp4',
    '.avi': 'video/x-msvideo',
    '.mov': 'video/quicktime',
    '.wmv': 'video/x-ms-wmv',
    // 添加更多文件类型
  };

  // 定义辅助函数
  function getMimeType(fileName: string): string {
    const ext = fileName.slice(fileName.lastIndexOf('.')).toLowerCase();
    return mimeTypes[ext] || 'application/octet-stream'; // 默认返回 'application/octet-stream'
  }

// Helper to construct HDFS paths correctly for API calls
function constructHdfsPath(basePath: string, ...segments: string[]): string {
  let fullPath = basePath;
  for (const segment of segments) {
    if (segment) { // Avoid adding empty segments
      fullPath = path.posix.join(fullPath, segment);
    }
  }
  return fullPath.replace(/\/+/g, '/'); // Normalize slashes
}

// Helper to prepare a path for use with the proxy (remove leading slash)
function prepareProxyPath(hdfsPath: string): string {
  return hdfsPath.startsWith('/') ? hdfsPath.substring(1) : hdfsPath;
}

/**
 * 列出指定目录的内容。
 */
export const listDirectory = async (dirPath: string): Promise<HDFSFile[]> => {
  const cleanDirPath = dirPath.replace(/\/+/g, '/');

  let url: string;
  if (isDevelopment) {
    // 开发环境：使用Vite代理
    const proxyReadyPath = prepareProxyPath(cleanDirPath);
    url = `${NAME_NODE_PROXY_PREFIX}/${proxyReadyPath}?op=LISTSTATUS`;
  } else {
    // 生产环境：使用后端API代理
    const apiPath = cleanDirPath === '/' ? '' : cleanDirPath.replace(/^\//, '');
    url = `${NAME_NODE_PROXY_PREFIX}/${apiPath}?op=LISTSTATUS`;
  }

  console.log('[listDirectory] Requesting:', url);
  const response = await fetch(url, {
    headers: {
      ...getDefaultHeaders(),
      'Accept': 'application/json'
    }
  });
  if (!response.ok) {
    const errorText = await response.text();
    console.error('[listDirectory] Error:', response.status, errorText);
    throw new Error(`无法列出目录：${response.status} ${response.statusText} - ${errorText}`);
  }
  const data = (await response.json()) as HDFSFileStatuses;
  if (!data.FileStatuses || !data.FileStatuses.FileStatus) return [];
  return data.FileStatuses.FileStatus.map((fileStatus): HDFSFile => ({
    name: fileStatus.pathSuffix,
    // Construct the full HDFS path for the item
    path: constructHdfsPath(cleanDirPath, fileStatus.pathSuffix),
    type: fileStatus.type.toUpperCase(),
    size: fileStatus.length,
    mimeType: getMimeType(fileStatus.pathSuffix),
    modificationTime: fileStatus.modificationTime, // 传递 modificationTime
  }));
};

/**
 * 递归计算目录中所有文件的总大小。
 */
const calculateDirectorySize = async (dirPath: string): Promise<number> => {
  const files = await listDirectory(dirPath);
  let totalSize = 0;

  for (const file of files) {
    if (file.type === 'FILE') {
      totalSize += file.size || 0;
    } else if (file.type === 'DIRECTORY') {
      totalSize += await calculateDirectorySize(file.path);
    }
  }

  return totalSize;
};

/**
 * 获取 HDFS 的存储信息。
 */
export const getStorageInfo = async (): Promise<StorageInfo> => {
  const usedStorage = await calculateDirectorySize('/');
  const totalStorage = 1024 * 1024 * 1024 * 1024; // 1TB (placeholder)
  return {
    totalFiles: 0, // 可以通过遍历目录计算，这里简化处理
    usedStorage,
    freeStorage: totalStorage - usedStorage,
    totalStorage,
  };
};

/**
 * 上传文件到 HDFS。
 */
export const uploadFile = async (
  dirPath: string,
  fileName: string,
  content: Buffer,
  fileSize: number
): Promise<void> => {
  const hdfsPath = constructHdfsPath(dirPath, fileName);
  const proxyReadyPath = prepareProxyPath(hdfsPath);
  const initialUrl = `${NAME_NODE_PROXY_PREFIX}/${encodeURI(proxyReadyPath)}?op=CREATE&overwrite=true`;
  const mimeType = getMimeType(fileName);

  console.log('[uploadFile] Attempting NameNode request:', initialUrl);
  let initResponse;
  try {
    initResponse = await fetch(initialUrl, {
      method: 'PUT',
      headers: { ...getDefaultHeaders(), 'Content-Type': mimeType, 'Accept': '*/*' },
      redirect: 'manual',
    });
  } catch (networkError: any) {
    console.error('[uploadFile] Network error during initial NameNode request:', networkError);
    console.error('[uploadFile] Network error name:', networkError.name);
    console.error('[uploadFile] Network error message:', networkError.message);
    console.error('[uploadFile] Network error stack:', networkError.stack);
    throw new Error(`Network error during initial NameNode request: ${networkError.message}`);
  }

  console.log('[uploadFile] Initial NameNode Response Status:', initResponse.status);
  console.log('[uploadFile] Initial NameNode Response Headers:', Object.fromEntries(initResponse.headers.entries()));

  // Try to get the Location header even if status is 0, as the browser might have processed the redirect
  const dataNodeRedirectUrlFromHeader = initResponse.headers.get('Location');

  if (initResponse.status === 0) {
    if (dataNodeRedirectUrlFromHeader) {
      console.warn('[uploadFile] NameNode request resulted in status 0, but a Location header was found. Proceeding with DataNode request. Location:', dataNodeRedirectUrlFromHeader);
    } else {
      console.error('[uploadFile] NameNode request resulted in status 0 and no Location header was found. This often indicates a CORS, network, or browser-blocked request before a proper HTTP status could be obtained.');
      throw new Error('NameNode request failed with status 0 and no Location header. Check browser console & network tab for CORS or other errors.');
    }
  } else if (initResponse.status !== 307) {
    let errorText = 'Unknown error';
    try { errorText = await initResponse.text(); } catch (e) { console.warn('[uploadFile] Could not read error text for non-redirect response', e); }
    console.error('[uploadFile] NameNode non-redirect error. Status:', initResponse.status, 'Body:', errorText);
    throw new Error(`NameNode did not redirect as expected. Status: ${initResponse.status} ${initResponse.statusText} - ${errorText}`);
  }

  // Use the location from header if available (especially if status was 0), otherwise expect it from a 307.
  const dataNodeRedirectUrl = dataNodeRedirectUrlFromHeader || initResponse.headers.get('Location');

  if (!dataNodeRedirectUrl) {
    console.error('[uploadFile] No Location header in NameNode 307 redirect response (or after status 0)');
    throw new Error('No Location header in NameNode redirect response');
  }
  console.log('[uploadFile] DataNode Redirect URL (from NameNode proxy, should be rewritten to /datanode-api/...):', dataNodeRedirectUrl);

  console.log('[uploadFile] Attempting DataNode request to (rewritten) Location:', dataNodeRedirectUrl);
  let uploadResponse;
  try {
    uploadResponse = await fetch(dataNodeRedirectUrl, {
      method: 'PUT',
      headers: { ...getDefaultHeaders(), 'Content-Type': mimeType, 'Content-Length': fileSize.toString(), 'Accept': '*/*' },
      body: content,
    });
  } catch (networkError: any) {
    console.error('[uploadFile] Network error during DataNode request:', networkError);
    console.error('[uploadFile] Network error name:', networkError.name);
    console.error('[uploadFile] Network error message:', networkError.message);
    console.error('[uploadFile] Network error stack:', networkError.stack);
    throw new Error(`Network error during DataNode request: ${networkError.message}`);
  }

  console.log('[uploadFile] DataNode Upload Response Status:', uploadResponse.status);

  if (uploadResponse.status === 0) {
    console.error('[uploadFile] DataNode request resulted in status 0.');
    throw new Error('DataNode request failed with status 0. Check browser console & network tab.');
  }

  if (!uploadResponse.ok) {
    let errorText = 'Unknown error';
    try { errorText = await uploadResponse.text(); } catch (e) { console.warn('[uploadFile] Could not read error text for DataNode failed response', e); }
    console.error('[uploadFile] DataNode upload error. Status:', uploadResponse.status, 'Body:', errorText);
    throw new Error(`DataNode upload failed: ${uploadResponse.status} ${uploadResponse.statusText} - ${errorText}`);
  }
  console.log('[uploadFile] File uploaded successfully to DataNode via proxy');
};

/**
 * 递归删除 HDFS 中的目录。
 */
export const deleteDirectory = async (dirPath: string): Promise<void> => {
  const proxyReadyPath = prepareProxyPath(dirPath);
  const url = `${NAME_NODE_PROXY_PREFIX}/${proxyReadyPath}?op=DELETE&recursive=true`;
  console.log('[deleteDirectory] Requesting:', url);
  const response = await fetch(url, { method: 'DELETE', headers: getDefaultHeaders() });
  if (!response.ok) {
    const errorText = await response.text();
    console.error('[deleteDirectory] Error:', response.status, errorText);
    throw new Error(`无法删除目录：${response.status} ${response.statusText} - ${errorText}`);
  }
};

/**
 * 删除 HDFS 中的文件。
 */
export const deleteFile = async (filePath: string): Promise<void> => {
  const proxyReadyPath = prepareProxyPath(filePath);
  const url = `${NAME_NODE_PROXY_PREFIX}/${proxyReadyPath}?op=DELETE`;
  console.log('[deleteFile] Requesting:', url);
  const response = await fetch(url, { method: 'DELETE', headers: getDefaultHeaders() });
  if (!response.ok) {
    const errorText = await response.text();
    console.error('[deleteFile] Error:', response.status, errorText);
    throw new Error(`无法删除文件：${response.status} ${response.statusText} - ${errorText}`);
  }
};

/**
 * 创建 HDFS 中的子目录。
 */
export const createSubdirectory = async (parentDirPath: string, dirName: string): Promise<void> => {
  const fullHdfsPath = constructHdfsPath(parentDirPath, dirName);
  const proxyReadyPath = prepareProxyPath(fullHdfsPath);
  const url = `${NAME_NODE_PROXY_PREFIX}/${encodeURI(proxyReadyPath)}?op=MKDIRS`;
  console.log('[createSubdirectory] Requesting:', url);
  const response = await fetch(url, { method: 'PUT', headers: getDefaultHeaders() });
  if (!response.ok) {
    const errorText = await response.text();
    console.error('[createSubdirectory] Error:', response.status, errorText);
    throw new Error(`无法创建子目录：${response.status} ${response.statusText} - ${errorText}`);
  }
};

/**
 * 重命名 HDFS 中的文件或目录。
 */
export const renameFileOrDirectory = async (srcPath: string, dstPath: string): Promise<void> => {
  const proxyReadySrcPath = prepareProxyPath(srcPath);
  // Ensure dstPath is an absolute HDFS path for the destination parameter
  const absoluteDstPath = dstPath.startsWith('/') ? dstPath : constructHdfsPath('/', dstPath);
  const url = `${NAME_NODE_PROXY_PREFIX}/${encodeURI(proxyReadySrcPath)}?op=RENAME&destination=${encodeURIComponent(absoluteDstPath)}`;
  console.log('[renameFileOrDirectory] Requesting:', url);
  const response = await fetch(url, { method: 'PUT', headers: getDefaultHeaders() });
  if (!response.ok) {
    const errorText = await response.text();
    console.error('[renameFileOrDirectory] Error:', response.status, errorText);
    throw new Error(`无法重命名：${response.status} ${response.statusText} - ${errorText}`);
  }
};

/**
 * 获取 HDFS 中文件的内容。
 */
export const getFileContent = async (filePath: string): Promise<Buffer> => {
  const proxyReadyPath = prepareProxyPath(filePath);
  const url = `${NAME_NODE_PROXY_PREFIX}/${encodeURI(proxyReadyPath)}?op=OPEN`;
  console.log('[getFileContent] Requesting:', url);
  const response = await fetch(url, { headers: getDefaultHeaders(), redirect: 'follow' }); // OPEN can often redirect
  if (!response.ok) {
    const errorText = await response.text();
    console.error('[getFileContent] Error:', response.status, errorText);
    throw new Error(`无法获取文件内容：${response.status} ${response.statusText} - ${errorText}`);
  }
  const content = await response.arrayBuffer();
  return Buffer.from(content);
};

export const updateFileContent = async (filePath: string, content: Buffer | string): Promise<void> => {
  const hdfsPath = filePath.startsWith('/') ? filePath : constructHdfsPath('/', filePath);
  const proxyReadyPath = prepareProxyPath(hdfsPath);
  const initialUrl = `${NAME_NODE_PROXY_PREFIX}${encodeURI(proxyReadyPath)}?op=CREATE&overwrite=true`;
  const contentBuffer = Buffer.isBuffer(content) ? content : Buffer.from(content, 'utf-8');
  const mimeType = getMimeType(path.basename(hdfsPath));

  console.log('[updateFileContent] Initial NameNode URL:', initialUrl);
  const initResponse = await fetch(initialUrl, {
    method: 'PUT',
    headers: { ...getDefaultHeaders(), 'Content-Type': mimeType, 'Accept': '*/*' },
    redirect: 'manual',
  });
  console.log('[updateFileContent] Initial NameNode Response Status:', initResponse.status);

  if (initResponse.status !== 307) {
    let errorText = 'Unknown error';
    try { errorText = await initResponse.text(); } catch (e) { console.error('Error reading error text', e); }
    console.error('[updateFileContent] NameNode non-redirect error:', initResponse.status, errorText);
    throw new Error(`NameNode did not redirect: ${initResponse.status} ${initResponse.statusText} - ${errorText}`);
  }

  const dataNodeRedirectUrl = initResponse.headers.get('Location');
  if (!dataNodeRedirectUrl) {
    console.error('[updateFileContent] No Location header in NameNode redirect response');
    throw new Error('No Location header in NameNode redirect response');
  }
  console.log('[updateFileContent] DataNode Redirect URL (from NameNode proxy, should be rewritten):', dataNodeRedirectUrl);

  const uploadResponse = await fetch(dataNodeRedirectUrl, {
    method: 'PUT',
    headers: { ...getDefaultHeaders(), 'Content-Type': mimeType, 'Content-Length': contentBuffer.length.toString(), 'Accept': '*/*' },
    body: contentBuffer,
  });
  console.log('[updateFileContent] DataNode Upload Response Status:', uploadResponse.status);

  if (!uploadResponse.ok) {
    let errorText = 'Unknown error';
    try { errorText = await uploadResponse.text(); } catch (e) { console.error('Error reading error text', e); }
    console.error('[updateFileContent] DataNode upload error:', uploadResponse.status, errorText);
    throw new Error(`DataNode upload failed: ${uploadResponse.status} ${uploadResponse.statusText} - ${errorText}`);
  }
  console.log('[updateFileContent] File updated successfully via proxy');
};

export const renameFile = async (oldPath: string, newName: string): Promise<void> => {
  const parentDir = path.posix.dirname(oldPath);
  const newHdfsPath = constructHdfsPath(parentDir, newName);
  await renameFileOrDirectory(oldPath, newHdfsPath);
};