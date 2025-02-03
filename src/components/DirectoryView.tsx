import React, { useState } from 'react';
import { Folder, File, Trash2, Edit2, Plus } from 'lucide-react';
import { HDFSFile } from '../types';

interface DirectoryViewProps {
  files: HDFSFile[];
  onFileClick: (file: HDFSFile) => void;
  onFileOperation: (operation: string, file: HDFSFile, newName?: string) => void;
  onCreateSubdirectory: (name: string) => void;
}

const DirectoryView: React.FC<DirectoryViewProps> = ({ files, onFileClick, onFileOperation, onCreateSubdirectory }) => {
  const [editingFile, setEditingFile] = useState<string | null>(null);
  const [newFileName, setNewFileName] = useState<string>('');
  const [newSubdirName, setNewSubdirName] = useState<string>('');

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

  return (
    <div className="overflow-x-auto">
      <div className="mb-4">
        <input
          type="text"
          value={newSubdirName}
          onChange={(e) => setNewSubdirName(e.target.value)}
          placeholder="New subdirectory name"
          className="mr-2 p-2 border rounded"
        />
        <button
          onClick={handleCreateSubdir}
          className="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 transition-colors"
        >
          <Plus size={18} className="inline mr-1" /> Create Subdirectory
        </button>
      </div>
      <table className="min-w-full bg-white">
        <thead className="bg-gray-100">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Size</th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200">
          {files.map((file) => (
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
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{file.type}</td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {file.type === 'FILE' ? `${file.size} bytes` : '-'}
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                <button
                  onClick={() => {
                    setEditingFile(file.path);
                    setNewFileName(file.name);
                  }}
                  className="text-indigo-600 hover:text-indigo-900 mr-2"
                >
                  <Edit2 size={18} />
                </button>
                <button
                  onClick={() => onFileOperation('delete', file)}
                  className="text-red-600 hover:text-red-900"
                >
                  <Trash2 size={18} />
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default DirectoryView;