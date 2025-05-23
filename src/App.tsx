import React, { useState, useEffect } from 'react';
import { Folder, RefreshCw, ArrowLeft } from 'lucide-react';
import { Buffer } from 'buffer';
import DirectoryView from './components/DirectoryView';
import FileOperations from './components/FileOperations';
import StorageDashboard from './components/StorageDashboard';
import FilePreview from './components/FilePreview';
import HdfsConfigModal from './components/HdfsConfigModal';
import PathBreadcrumbs from './components/PathBreadcrumbs';
import { HDFSFile, StorageInfo } from './types';
import {
  listDirectory,
  uploadFile,
  deleteDirectory,
  getStorageInfo,
  createSubdirectory,
  renameFile,
  deleteFile,
  getFileContent,
  updateFileContent
} from './services/realHdfsApi';
import { useToast } from './components/ToastContext';

const App: React.FC = () => {
  const [currentPath, setCurrentPath] = useState<string>('/');
  const [files, setFiles] = useState<HDFSFile[]>([]);
  const [storageInfo, setStorageInfo] = useState<StorageInfo>({
    totalFiles: 0,
    usedStorage: 0,
    freeStorage: 0,
    totalStorage: 0,
  });
  const [selectedFile, setSelectedFile] = useState<HDFSFile | null>(null);
  const [showConfig, setShowConfig] = useState(false);
  const { addToast } = useToast();

  useEffect(() => {
    fetchDirectoryContents(currentPath);
    fetchStorageInfo();
  }, [currentPath]);

  const fetchDirectoryContents = async (path: string) => {
    try {
      const contents = await listDirectory(path);
      setFiles(contents);
    } catch (error) {
      console.error("Error fetching directory contents:", error);
      addToast('获取目录内容失败', 'error');
    }
  };

  const fetchStorageInfo = async () => {
    try {
      const info = await getStorageInfo();
      setStorageInfo(info);
    } catch (error) {
      console.error("Error fetching storage info:", error);
      addToast('获取存储信息失败', 'error');
    }
  };

  const handleFileClick = async (file: HDFSFile) => {
    if (file.type === 'DIRECTORY') {
      setCurrentPath(file.path);
    } else {
      try {
        console.log('[App.tsx handleFileClick] Clicked file:', JSON.parse(JSON.stringify(file)));
        const contentBuffer = await getFileContent(file.path);
        console.log('[App.tsx handleFileClick] Fetched contentBuffer length:', contentBuffer.byteLength);

        let fileContentString: string;
        let effectiveMimeType = file.mimeType || 'text/plain';
        const fileName = file.name.toLowerCase();

        console.log(`[App.tsx handleFileClick] Initial effectiveMimeType for ${file.name}: ${effectiveMimeType}`);

        if (effectiveMimeType === 'application/octet-stream') {
          if (fileName.endsWith('.log') || fileName.endsWith('.yaml') || fileName.endsWith('.yml') || fileName.endsWith('.md') || fileName.endsWith('.txt')) {
            effectiveMimeType = 'text/plain';
            console.log(`[App.tsx handleFileClick] Inferred text/plain for octet-stream: ${file.name}`);
          } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
            effectiveMimeType = 'image/jpeg';
            console.log(`[App.tsx handleFileClick] Inferred image/jpeg for octet-stream: ${file.name}`);
          } else if (fileName.endsWith('.png')) {
            effectiveMimeType = 'image/png';
            console.log(`[App.tsx handleFileClick] Inferred image/png for octet-stream: ${file.name}`);
          } else if (fileName.endsWith('.gif')) {
            effectiveMimeType = 'image/gif';
            console.log(`[App.tsx handleFileClick] Inferred image/gif for octet-stream: ${file.name}`);
          }
        }
        
        console.log(`[App.tsx handleFileClick] Final effectiveMimeType for ${file.name}: ${effectiveMimeType}`);

        if (effectiveMimeType.startsWith('text/') || effectiveMimeType === 'application/json') {
          fileContentString = contentBuffer.toString('utf-8');
          console.log(`[App.tsx handleFileClick] Content for ${file.name} treated as text.`);
        } else {
          fileContentString = `data:${effectiveMimeType};base64,${contentBuffer.toString('base64')}`;
          console.log(`[App.tsx handleFileClick] Content for ${file.name} converted to base64 data URL with MIME: ${effectiveMimeType}. Preview (first 100 chars): ${fileContentString.substring(0,100)}`);
        }
        
        setSelectedFile({
          ...file,
          content: fileContentString,
          mimeType: effectiveMimeType 
        });
      } catch (error) {
        console.error("[App.tsx handleFileClick] Error fetching/processing file content:", error);
        let errorMessage = "加载文件预览失败，发生未知错误。";
        if (error instanceof Error) {
          errorMessage = `加载文件预览失败: ${error.message}`;
        } else if (typeof error === 'string') {
          errorMessage = `加载文件预览失败: ${error}`;
        }
        addToast(errorMessage, 'error');
      }
    }
  };

  const handleFileOperation = async (operation: string, file: HDFSFile, newName?: string) => {
    try {
      switch (operation) {
        case 'rename':
          if (newName) {
            await renameFile(file.path, newName);
            addToast(`'${file.name}' 已重命名为 '${newName}'`, 'success');
          }
          break;
        case 'delete':
          if (file.type === 'DIRECTORY') {
            await deleteDirectory(file.path);
          } else {
            await deleteFile(file.path);
          }
          addToast(`'${file.name}' 已删除`, 'success');
          break;
        case 'update':
          if (file.content !== undefined) {
            // 处理不同类型的文件内容
            let effectiveMimeType = file.mimeType || 'text/plain';
            const fileName = file.name.toLowerCase();
            // If backend returns octet-stream, try to infer text based on extension for saving
            if (effectiveMimeType === 'application/octet-stream') {
                if (fileName.endsWith('.log') || fileName.endsWith('.yaml') || fileName.endsWith('.yml') || fileName.endsWith('.md') || fileName.endsWith('.txt')) {
                    effectiveMimeType = 'text/plain';
                }
            }

            let contentToSave: Buffer;
            
            if (effectiveMimeType.startsWith('text/') || effectiveMimeType === 'application/json') {
              contentToSave = Buffer.from(file.content, 'utf-8');
            } else {
              // 处理 base64 编码的二进制文件
              const base64Data = file.content.split(',')[1];
              contentToSave = Buffer.from(base64Data, 'base64');
            }
            
            await updateFileContent(file.path, contentToSave);
            addToast(`'${file.name}' 已更新`, 'success');
          }
          break;
      }
      fetchDirectoryContents(currentPath);
      fetchStorageInfo();
    } catch (error) {
      console.error(`Error during file operation ${operation}:`, error);
      addToast(`操作 ${operation} 失败: ${file.name}`, 'error');
    }
  };

  const handleUpload = async (fileToUpload: File) => {
    try {
      const MAX_FILE_SIZE = 100 * 1024 * 1024; // 100MB
      if (fileToUpload.size > MAX_FILE_SIZE) {
        throw new Error(`文件大小超过限制 (最大 ${MAX_FILE_SIZE / 1024 / 1024}MB)`);
      }

      const formData = new FormData();
      formData.append('file', fileToUpload); // 文件本身
      formData.append('hdfsPath', currentPath);    // 目标 HDFS 基础路径

      console.log(`[handleUpload] 向 /api/upload-to-hdfs-via-server 发送文件: ${fileToUpload.name}, 目标HDFS目录: ${currentPath}`);

      // 这个 /api/upload-to-hdfs-via-server 是您需要在后端实现的接口
      const response = await fetch('/api/upload-to-hdfs-via-server', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        let errorMessage = `服务器上传失败: ${response.status}`;
        try {
          const errorResult = await response.json();
          errorMessage = errorResult.message || errorResult.error || errorMessage;
        } catch (e) {
          try {
            const errorText = await response.text();
            errorMessage = errorText || errorMessage;
          } catch (textError) { /* 保留原始状态码错误 */ }
        }
        console.error('[handleUpload] 服务器响应错误:', errorMessage);
        throw new Error(errorMessage);
      }

      const result = await response.json(); 
      console.log('[handleUpload] 服务器响应成功:', result.message);
      addToast(result.message || '文件上传成功！', 'success');

      fetchDirectoryContents(currentPath);
      fetchStorageInfo();

    } catch (error: any) {
      console.error('[handleUpload] 处理上传时出错:', error);
      addToast(`文件上传失败: ${error.message}`, 'error');
    }
  };

  const handleCreateSubdirectory = async (name: string) => {
    try {
      await createSubdirectory(currentPath, name);
      fetchDirectoryContents(currentPath);
      fetchStorageInfo();
      addToast(`子文件夹 '${name}' 创建成功`, 'success');
    } catch (error) {
      console.error('Error creating subdirectory:', error);
      addToast(`创建子文件夹 '${name}' 失败`, 'error');
    }
  };

  const handleFilePreviewClose = () => {
    setSelectedFile(null);
  };

  const handleFileContentSave = async (newContent: string) => {
    console.log('[App.tsx handleFileContentSave] Received new content to save:', newContent);
    if (selectedFile) {
      console.log(`[App.tsx handleFileContentSave] Calling updateFileContent for path: ${selectedFile.path}`);
      try {
        // await updateFileContent(selectedFile.path, newContent); // 旧的调用，直接使用realHdfsApi
        // 使用新的通过服务器上传的逻辑，我们需要调整
        // 对于"编辑保存"，我们也应该通过后端服务器来执行覆盖写操作
        // 这需要后端 /api/upload-to-hdfs-via-server (或一个新接口) 支持覆盖写，
        // 并且能够接收文件内容字符串而不是一个文件对象。

        // 方案 A: 修改后端接口以接受内容字符串 (更复杂一些，因为 curl -T 需要一个文件路径)
        // 方案 B: 在前端将新内容转换为 File 对象，然后复用现有的 handleUpload 流程
        // 方案 B 更简单地复用现有逻辑

        if (!selectedFile.name || !selectedFile.mimeType) {
          console.error('[App.tsx handleFileContentSave] Missing file name or mimeType for creating a File object.');
          addToast('无法保存文件，缺少文件名或类型信息。', 'error');
          return;
        }

        // 将字符串内容转换为 Blob，然后是 File 对象
        const blob = new Blob([newContent], { type: selectedFile.mimeType || 'text/plain' });
        const fileToUpload = new File([blob], selectedFile.name, { type: selectedFile.mimeType || 'text/plain' });

        console.log('[App.tsx handleFileContentSave] Created File object from new content to re-upload:', fileToUpload);
        
        // 复用 handleUpload (它现在通过后端服务器上传)
        // handleUpload 内部会处理 fetchDirectoryContents 和 fetchStorageInfo
        await handleUpload(fileToUpload); 
        setSelectedFile(null); // 关闭预览
        addToast(`'${selectedFile.name}' 已保存并重新上传`, 'success');

      } catch (error) {
        console.error('[App.tsx handleFileContentSave] Error during updateFileContent:', error);
        let errorMessage = "保存文件内容失败。";
        if (error instanceof Error) {
          errorMessage = `保存文件内容失败: ${error.message}`;
        } else if (typeof error === 'string') {
          errorMessage = `保存文件内容失败: ${error}`;
        }
        addToast(errorMessage, 'error');
        //  setSelectedFile(null); // 发生错误时也可以考虑关闭预览，或保留让用户重试
      }
    } else {
      console.warn('[App.tsx handleFileContentSave] No selectedFile to save content for.');
    }
  };

  const handleReturn = () => {
    const parentPath = currentPath.split('/').slice(0, -1).join('/') || '/';
    setCurrentPath(parentPath);
  };

  const handlePathChange = (newPath: string) => {
    setCurrentPath(newPath);
  };

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-3xl font-bold mb-6">HDFS 文件管理平台</h1>
      <div className="flex justify-end mb-2">
        <button
          className="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-600"
          onClick={() => setShowConfig(true)}
        >
          系统配置
        </button>
      </div>
      <StorageDashboard storageInfo={storageInfo} currentPath={currentPath} files={files} />
      <div className="mb-4 flex items-center">
        <PathBreadcrumbs currentPath={currentPath} onPathChange={handlePathChange} />
      </div>
      <div className="mb-4 flex items-center">
        <button
          onClick={() => fetchDirectoryContents(currentPath)}
          className="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 transition-colors flex items-center"
        >
          <RefreshCw size={18} className="mr-1" /> 刷新
        </button>
      </div>
      <FileOperations onUpload={handleUpload} />
      <DirectoryView
        files={files}
        onFileClick={handleFileClick}
        onFileOperation={handleFileOperation}
        onCreateSubdirectory={handleCreateSubdirectory}
      />
      {selectedFile && (
        <FilePreview
          file={selectedFile}
          onClose={handleFilePreviewClose}
          onSave={handleFileContentSave}
        />
      )}
      {showConfig && <HdfsConfigModal onClose={() => setShowConfig(false)} />}
    </div>
  );
};

export default App;