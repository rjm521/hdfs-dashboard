import React, { useState, useMemo } from 'react';
import { Folder, File, Trash2, Edit2, Plus, ArrowUpDown, ArrowUp, ArrowDown } from 'lucide-react';
import { HDFSFile } from '../types';

interface DirectoryViewProps {
  files: HDFSFile[];
  onFileClick: (file: HDFSFile) => void;
  onFileOperation: (operation: string, file: HDFSFile, newName?: string) => void;
  onCreateSubdirectory: (name: string) => void;
}

type SortKey = 'name' | 'type' | 'size' | 'modificationTime';
type SortOrder = 'asc' | 'desc';

const DirectoryView: React.FC<DirectoryViewProps> = ({ files, onFileClick, onFileOperation, onCreateSubdirectory }) => {
  const [editingFile, setEditingFile] = useState<string | null>(null);
  const [newFileName, setNewFileName] = useState<string>('');
  const [newSubdirName, setNewSubdirName] = useState<string>('');

  const [sortKey, setSortKey] = useState<SortKey>('name');
  const [sortOrder, setSortOrder] = useState<SortOrder>('asc');

  const handleRename = (file: HDFSFile) => {
    if (newFileName.trim()) {
      onFileOperation('rename', file, newFileName.trim());
      setEditingFile(null);
      setNewFileName('');
    }
  };

  const handleCreateSubdir = () => {
    if (newSubdirName.trim()) {
      onCreateSubdirectory(newSubdirName.trim());
      setNewSubdirName('');
    }
  };

  const sortedFiles = useMemo(() => {
    return [...files].sort((a, b) => {
      let valA = a[sortKey];
      let valB = b[sortKey];

      if (sortKey === 'type') {
        valA = a.type === 'DIRECTORY' ? 0 : 1;
        valB = b.type === 'DIRECTORY' ? 0 : 1;
      } else if (sortKey === 'size') {
        valA = a.type === 'DIRECTORY' ? -1 : a.size;
        valB = b.type === 'DIRECTORY' ? -1 : b.size;
      } else if (sortKey === 'modificationTime') {
        valA = a.modificationTime || 0;
        valB = b.modificationTime || 0;
      }

      if (valA === undefined || valA === null) valA = '';
      if (valB === undefined || valB === null) valB = '';

      let comparison = 0;
      if (valA < valB) {
        comparison = -1;
      } else if (valA > valB) {
        comparison = 1;
      }
      return sortOrder === 'asc' ? comparison : -comparison;
    });
  }, [files, sortKey, sortOrder]);

  const requestSort = (key: SortKey) => {
    if (sortKey === key && sortOrder === 'asc') {
      setSortOrder('desc');
    } else {
      setSortKey(key);
      setSortOrder('asc');
    }
  };

  const getSortIcon = (key: SortKey) => {
    if (sortKey !== key) {
      return <ArrowUpDown size={14} className="ml-1 text-gray-400" />;
    }
    return sortOrder === 'asc' ? <ArrowUp size={14} className="ml-1" /> : <ArrowDown size={14} className="ml-1" />;
  };

  const formatTimestamp = (timestamp?: number) => {
    if (!timestamp) return '-';
    return new Date(timestamp).toLocaleString();
  };
  
  const formatBytes = (bytes?: number, decimals = 2) => {
    if (bytes === undefined || bytes === null || bytes < 0 ) return '-';
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  };

  return (
    <>
      <div className="overflow-x-auto">
        <div className="mb-4">
          <input
            type="text"
            value={newSubdirName}
            onChange={(e) => setNewSubdirName(e.target.value)}
            placeholder="新建子文件夹名称"
            className="mr-2 p-2 border rounded"
          />
          <button
            onClick={handleCreateSubdir}
            className="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 transition-colors"
          >
            <Plus size={18} className="inline mr-1" /> 新建子文件夹
          </button>
        </div>
        <table className="min-w-full bg-white">
          <thead className="bg-gray-100">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-200" onClick={() => requestSort('name')}>
                名称 {getSortIcon('name')}
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-200" onClick={() => requestSort('type')}>
                类型 {getSortIcon('type')}
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-200" onClick={() => requestSort('size')}>
                大小 {getSortIcon('size')}
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-200" onClick={() => requestSort('modificationTime')}>
                修改时间 {getSortIcon('modificationTime')}
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">操作</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {sortedFiles.map((file) => (
              <tr key={file.path} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex items-center">
                    {file.type === 'DIRECTORY' ? (
                      <Folder className="mr-2 text-yellow-500" size={20} />
                    ) : (
                      <File className="mr-2 text-blue-500" size={20} />
                    )}
                    {editingFile === file.path ? (
                      <input
                        type="text"
                        value={newFileName}
                        onChange={(e) => setNewFileName(e.target.value)}
                        onBlur={() => handleRename(file)}
                        onKeyPress={(e) => e.key === 'Enter' && handleRename(file)}
                        className="border rounded px-2 py-1"
                        autoFocus
                      />
                    ) : (
                      <span
                        className="text-sm font-medium text-gray-900 cursor-pointer hover:text-blue-600"
                        onClick={() => onFileClick(file)}
                      >
                        {file.name}
                      </span>
                    )}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{file.type === 'DIRECTORY' ? '文件夹' : '文件'}</td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {formatBytes(file.size)}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {formatTimestamp(file.modificationTime)}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <button
                    onClick={() => {
                      setEditingFile(file.path);
                      setNewFileName(file.name);
                    }}
                    className="text-indigo-600 hover:text-indigo-900 mr-2"
                    title="重命名"
                  >
                    <Edit2 size={18} />
                  </button>
                  <button
                    onClick={() => {
                      if (window.confirm(`您确定要删除 "${file.name}" 吗？此操作无法撤销。`)) {
                        onFileOperation('delete', file);
                      }
                    }}
                    className="text-red-600 hover:text-red-900"
                    title="删除"
                  >
                    <Trash2 size={18} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
};

export default DirectoryView;