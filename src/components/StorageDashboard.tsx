import React from 'react';
import { BarChart, HardDrive, FileText, Folder } from 'lucide-react';
import { StorageInfo, HDFSFile } from '../types';

interface StorageDashboardProps {
  storageInfo: StorageInfo;
  currentPath: string;
  files: HDFSFile[];
}

const StorageDashboard: React.FC<StorageDashboardProps> = ({ storageInfo, currentPath, files }) => {
  const formatBytes = (bytes: number) => {
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    if (bytes === 0) return '0 Byte';
    const i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)).toString());
    return Math.round((bytes / Math.pow(1024, i)) * 100) / 100 + ' ' + sizes[i];
  };

  const usedPercentage = (storageInfo.usedStorage / storageInfo.totalStorage) * 100;

  const currentDirectorySize = files.reduce((total, file) => total + (file.size || 0), 0);
  const currentDirectoryFiles = files.filter(file => file.type === 'FILE').length;
  const currentDirectoryFolders = files.filter(file => file.type === 'DIRECTORY').length;

  return (
    <div className="bg-white p-6 rounded-lg shadow-md mb-6">
      <h2 className="text-2xl font-semibold mb-4">Storage Dashboard</h2>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="bg-blue-100 p-4 rounded-md flex items-center">
          <FileText className="text-blue-500 mr-3" size={24} />
          <div>
            <p className="text-sm text-blue-600">Total Files</p>
            <p className="text-2xl font-bold text-blue-800">{storageInfo.totalFiles}</p>
          </div>
        </div>
        <div className="bg-green-100 p-4 rounded-md flex items-center">
          <HardDrive className="text-green-500 mr-3" size={24} />
          <div>
            <p className="text-sm text-green-600">Storage Used</p>
            <p className="text-2xl font-bold text-green-800">{formatBytes(storageInfo.usedStorage)}</p>
          </div>
        </div>
        <div className="bg-yellow-100 p-4 rounded-md flex items-center">
          <HardDrive className="text-yellow-500 mr-3" size={24} />
          <div>
            <p className="text-sm text-yellow-600">Storage Left</p>
            <p className="text-2xl font-bold text-yellow-800">{formatBytes(storageInfo.freeStorage)}</p>
          </div>
        </div>
      </div>
      <div className="mb-6">
        <div className="flex items-center">
          <BarChart className="text-gray-500 mr-2" size={20} />
          <span className="text-sm text-gray-600">Storage Usage</span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-2.5 mt-2">
          <div
            className="bg-blue-600 h-2.5 rounded-full"
            style={{ width: `${usedPercentage}%` }}
          ></div>
        </div>
        <div className="flex justify-between mt-1">
          <span className="text-xs text-gray-500">{formatBytes(storageInfo.usedStorage)}</span>
          <span className="text-xs text-gray-500">{formatBytes(storageInfo.totalStorage)}</span>
        </div>
      </div>
      <div>
        <h3 className="text-lg font-semibold mb-2">Current Directory: {currentPath}</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-indigo-100 p-4 rounded-md flex items-center">
            <Folder className="text-indigo-500 mr-3" size={24} />
            <div>
              <p className="text-sm text-indigo-600">Directory Size</p>
              <p className="text-2xl font-bold text-indigo-800">{formatBytes(currentDirectorySize)}</p>
            </div>
          </div>
          <div className="bg-pink-100 p-4 rounded-md flex items-center">
            <FileText className="text-pink-500 mr-3" size={24} />
            <div>
              <p className="text-sm text-pink-600">Files</p>
              <p className="text-2xl font-bold text-pink-800">{currentDirectoryFiles}</p>
            </div>
          </div>
          <div className="bg-purple-100 p-4 rounded-md flex items-center">
            <Folder className="text-purple-500 mr-3" size={24} />
            <div>
              <p className="text-sm text-purple-600">Folders</p>
              <p className="text-2xl font-bold text-purple-800">{currentDirectoryFolders}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default StorageDashboard;