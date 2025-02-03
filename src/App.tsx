import React, { useState, useEffect } from 'react';
import { Folder, RefreshCw, ArrowLeft } from 'lucide-react';
import DirectoryView from './components/DirectoryView';
import FileOperations from './components/FileOperations';
import StorageDashboard from './components/StorageDashboard';
import FilePreview from './components/FilePreview';
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
} from './services/mockHdfsApi';

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
    }
  };

  const fetchStorageInfo = async () => {
    try {
      const info = await getStorageInfo();
      setStorageInfo(info);
    } catch (error) {
      console.error("Error fetching storage info:", error);
    }
  };

  const handleFileClick = async (file: HDFSFile) => {
    if (file.type === 'DIRECTORY') {
      setCurrentPath(file.path);
    } else {
      try {
        const fileWithContent = await getFileContent(file.path);
        setSelectedFile(fileWithContent);
      } catch (error) {
        console.error("Error fetching file content:", error);
      }
    }
  };

  const handleFileOperation = async (operation: string, file: HDFSFile, newName?: string) => {
    switch (operation) {
      case 'rename':
        if (newName) {
          await renameFile(file.path, newName);
        }
        break;
      case 'delete':
        if (file.type === 'DIRECTORY') {
          await deleteDirectory(file.path);
        } else {
          await deleteFile(file.path);
        }
        break;
    }
    fetchDirectoryContents(currentPath);
    fetchStorageInfo();
  };

  const handleUpload = async (file: File) => {
    await uploadFile(currentPath, file);
    fetchDirectoryContents(currentPath);
    fetchStorageInfo();
  };

  const handleCreateSubdirectory = async (name: string) => {
    await createSubdirectory(currentPath, name);
    fetchDirectoryContents(currentPath);
    fetchStorageInfo();
  };

  const handleFilePreviewClose = () => {
    setSelectedFile(null);
  };

  const handleFileContentSave = async (content: string) => {
    if (selectedFile) {
      await updateFileContent(selectedFile.path, content);
      fetchDirectoryContents(currentPath);
      setSelectedFile(null);
    }
  };

  const handleReturn = () => {
    const parentPath = currentPath.split('/').slice(0, -1).join('/') || '/';
    setCurrentPath(parentPath);
  };

  return (
    <div className="container mx-auto p-4">
      <h1 className="text-3xl font-bold mb-6">HDFS Web Dashboard</h1>
      <StorageDashboard storageInfo={storageInfo} currentPath={currentPath} files={files} />
      <div className="mb-4 flex items-center">
        <button
          onClick={handleReturn}
          className="bg-blue-500 text-white px-4 py-2 rounded mr-2 hover:bg-blue-600 transition-colors flex items-center"
        >
          <ArrowLeft size={18} className="mr-1" /> Return
        </button>
        <button
          onClick={() => fetchDirectoryContents(currentPath)}
          className="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 transition-colors flex items-center"
        >
          <RefreshCw size={18} className="mr-1" /> Refresh
        </button>
        <span className="ml-4 text-gray-600">
          <Folder size={18} className="inline mr-1" />
          Current Path: {currentPath}
        </span>
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
    </div>
  );
};

export default App;