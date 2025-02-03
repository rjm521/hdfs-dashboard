import React, { useState, useEffect } from 'react';
import { X, Save } from 'lucide-react';
import { HDFSFile } from '../types';

interface FilePreviewProps {
  file: HDFSFile;
  onClose: () => void;
  onSave: (content: string) => void;
}

const FilePreview: React.FC<FilePreviewProps> = ({ file, onClose, onSave }) => {
  const [editableContent, setEditableContent] = useState(file.content || '');
  const [isEditing, setIsEditing] = useState(false);

  useEffect(() => {
    setEditableContent(file.content || '');
  }, [file.content]);

  const handleSave = () => {
    onSave(editableContent);
    setIsEditing(false);
  };

  const renderContent = () => {
    if (!file.mimeType) {
      return <p>Unable to determine file type.</p>;
    }

    if (file.mimeType.startsWith('image/')) {
      return <img src={file.content} alt={file.name} className="max-w-full max-h-[60vh] object-contain" />;
    } else if (file.mimeType.startsWith('video/')) {
      return (
        <video controls className="max-w-full max-h-[60vh]">
          <source src={file.content} type={file.mimeType} />
          Your browser does not support the video tag.
        </video>
      );
    } else if (file.mimeType.startsWith('text/') || file.mimeType === 'application/json') {
      if (isEditing) {
        return (
          <textarea
            value={editableContent}
            onChange={(e) => setEditableContent(e.target.value)}
            className="w-full h-[60vh] p-2 border rounded"
          />
        );
      } else {
        const lines = file.content?.split('\n') || [];
        return (
          <div>
            <p className="mb-2">Number of records: {lines.length}</p>
            <pre className="whitespace-pre-wrap max-h-[60vh] overflow-auto">{file.content}</pre>
          </div>
        );
      }
    } else {
      return <p>Preview not available for this file type: {file.mimeType}</p>;
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-3/4 h-5/6 flex flex-col">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold">File Preview: {file.name}</h2>
          <div>
            {(file.mimeType?.startsWith('text/') || file.mimeType === 'application/json') && (
              <button
                onClick={() => setIsEditing(!isEditing)}
                className="bg-blue-500 text-white px-4 py-2 rounded mr-2 hover:bg-blue-600 transition-colors"
              >
                {isEditing ? 'Cancel' : 'Edit'}
              </button>
            )}
            {isEditing && (
              <button
                onClick={handleSave}
                className="bg-green-500 text-white px-4 py-2 rounded mr-2 hover:bg-green-600 transition-colors"
              >
                <Save size={18} className="inline mr-1" /> Save
              </button>
            )}
            <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
              <X size={24} />
            </button>
          </div>
        </div>
        <div className="flex-grow overflow-auto">
          {renderContent()}
        </div>
      </div>
    </div>
  );
};

export default FilePreview;