import React, { useState } from 'react';
import { Upload } from 'lucide-react';

interface FileOperationsProps {
  onUpload: (file: File) => void;
}

const FileOperations: React.FC<FileOperationsProps> = ({ onUpload }) => {
  const [file, setFile] = useState<File | null>(null);

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (event.target.files && event.target.files[0]) {
      setFile(event.target.files[0]);
    }
  };

  const handleUpload = () => {
    if (file) {
      onUpload(file);
      setFile(null);
    }
  };

  return (
    <div className="mt-6 p-4 bg-gray-50 rounded-lg">
      <h3 className="text-lg font-semibold mb-4">文件操作</h3>
      <div className="flex items-center space-x-4">
        <input
          type="file"
          onChange={handleFileChange}
          className="file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
        />
        <button
          onClick={handleUpload}
          disabled={!file}
          className={`bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600 transition-colors flex items-center ${
            !file && 'opacity-50 cursor-not-allowed'
          }`}
        >
          <Upload className="mr-2" size={18} /> 上传文件
        </button>
      </div>
    </div>
  );
};

export default FileOperations;