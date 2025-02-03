import { HDFSFile, StorageInfo } from '../types';

let mockFileSystem: { [key: string]: HDFSFile[] } = {
  '/': [
    { name: 'Documents', path: '/Documents', type: 'DIRECTORY' },
    { name: 'Images', path: '/Images', type: 'DIRECTORY' },
    { name: 'Videos', path: '/Videos', type: 'DIRECTORY' },
    { name: 'readme.txt', path: '/readme.txt', type: 'FILE', size: 1024, content: 'Welcome to the HDFS Web Dashboard!', mimeType: 'text/plain' },
  ],
  '/Documents': [
    { name: 'report.pdf', path: '/Documents/report.pdf', type: 'FILE', size: 2048576, content: 'Sample PDF content', mimeType: 'application/pdf' },
    { name: 'data.csv', path: '/Documents/data.csv', type: 'FILE', size: 512000, content: 'id,name,value\n1,John,100\n2,Jane,200', mimeType: 'text/csv' },
  ],
  '/Images': [
    { name: 'photo1.jpg', path: '/Images/photo1.jpg', type: 'FILE', size: 3145728, content: 'https://source.unsplash.com/random/800x600?nature', mimeType: 'image/jpeg' },
    { name: 'photo2.png', path: '/Images/photo2.png', type: 'FILE', size: 2097152, content: 'https://source.unsplash.com/random/800x600?city', mimeType: 'image/png' },
  ],
  '/Videos': [
    { name: 'video1.mp4', path: '/Videos/video1.mp4', type: 'FILE', size: 10485760, content: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4', mimeType: 'video/mp4' },
    { name: 'video2.webm', path: '/Videos/video2.webm', type: 'FILE', size: 8388608, content: 'https://test-videos.co.uk/vids/bigbuckbunny/webm/vp8/360/Big_Buck_Bunny_360_10s_1MB.webm', mimeType: 'video/webm' },
  ],
};

const totalStorage = 1024 * 1024 * 1024 * 10; // 10 GB

export const listDirectory = async (path: string): Promise<HDFSFile[]> => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(mockFileSystem[path] || []);
    }, 500);
  });
};

export const getStorageInfo = async (): Promise<StorageInfo> => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const totalFiles = Object.values(mockFileSystem).flat().length;
      const usedStorage = Object.values(mockFileSystem)
        .flat()
        .reduce((total, file) => total + (file.size || 0), 0);
      resolve({
        totalFiles,
        usedStorage,
        freeStorage: totalStorage - usedStorage,
        totalStorage,
      });
    }, 500);
  });
};

export const uploadFile = async (path: string, file: File): Promise<void> => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const newFile: HDFSFile = {
        name: file.name,
        path: `${path}/${file.name}`,
        type: 'FILE',
        size: file.size,
        mimeType: file.type,
        content: 'Uploaded file content',
      };
      if (!mockFileSystem[path]) {
        mockFileSystem[path] = [];
      }
      mockFileSystem[path].push(newFile);
      resolve();
    }, 500);
  });
};

export const deleteDirectory = async (path: string): Promise<void> => {
  return new Promise((resolve) => {
    setTimeout(() => {
      delete mockFileSystem[path];
      resolve();
    }, 500);
  });
};

export const deleteFile = async (path: string): Promise<void> => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const parentPath = path.substring(0, path.lastIndexOf('/'));
      mockFileSystem[parentPath] = mockFileSystem[parentPath].filter(
        (file) => file.path !== path
      );
      resolve();
    }, 500);
  });
};

export const createSubdirectory = async (parentPath: string, name: string): Promise<void> => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const newPath = `${parentPath}/${name}`;
      mockFileSystem[newPath] = [];
      if (!mockFileSystem[parentPath]) {
        mockFileSystem[parentPath] = [];
      }
      mockFileSystem[parentPath].push({
        name,
        path: newPath,
        type: 'DIRECTORY',
      });
      resolve();
    }, 500);
  });
};

export const renameFile = async (oldPath: string, newName: string): Promise<void> => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const parentPath = oldPath.substring(0, oldPath.lastIndexOf('/'));
      const file = mockFileSystem[parentPath].find((f) => f.path === oldPath);
      if (file) {
        file.name = newName;
        file.path = `${parentPath}/${newName}`;
      }
      resolve();
    }, 500);
  });
};

export const getFileContent = async (filePath: string): Promise<HDFSFile> => {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      const parentPath = filePath.substring(0, filePath.lastIndexOf('/')) || '/';
      const file = mockFileSystem[parentPath]?.find(f => f.path === filePath);
      if (file) {
        resolve({ ...file });
      } else {
        reject(new Error('File not found'));
      }
    }, 500);
  });
};

export const updateFileContent = async (filePath: string, newContent: string): Promise<void> => {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      const parentPath = filePath.substring(0, filePath.lastIndexOf('/')) || '/';
      const file = mockFileSystem[parentPath]?.find(f => f.path === filePath);
      if (file && file.type === 'FILE') {
        file.content = newContent;
        file.size = newContent.length;
        resolve();
      } else {
        reject(new Error('File not found or is not editable'));
      }
    }, 500);
  });
};