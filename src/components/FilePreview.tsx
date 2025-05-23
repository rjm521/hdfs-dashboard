import React, { useState, useEffect, useCallback } from 'react';
import { X, Save, Info, Download } from 'lucide-react';
import { HDFSFile } from '../types';
import { Document, Page, pdfjs } from 'react-pdf';
import ReactAudioPlayer from 'react-audio-player';
import { parse } from 'papaparse';

// Set up PDF worker
pdfjs.GlobalWorkerOptions.workerSrc = `//cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjs.version}/pdf.worker.min.js`;

interface FilePreviewProps {
  file: HDFSFile;
  onClose: () => void;
  onSave: (content: string) => void;
}

// Helper function to format bytes
const formatBytes = (bytes?: number, decimals = 2) => {
  if (bytes === undefined || bytes === 0) return '0 Bytes';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
};

// Helper function to format timestamp
const formatTimestamp = (timestamp?: number) => {
  if (!timestamp) return 'N/A';
  return new Date(timestamp).toLocaleString();
};

const FilePreview: React.FC<FilePreviewProps> = ({ file, onClose, onSave }) => {
  const [editableContent, setEditableContent] = useState(file.content || '');
  const [isEditing, setIsEditing] = useState(false);
  const [numPages, setNumPages] = useState<number | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [csvData, setCsvData] = useState<any[]>([]);

  // 推断文件类型
  const getMimeType = useCallback(() => {
    if (!file.mimeType) {
      // 根据文件扩展名推断类型
      const ext = file.name.split('.').pop()?.toLowerCase();
      switch (ext) {
        case 'txt': return 'text/plain';
        case 'json': return 'application/json';
        case 'pdf': return 'application/pdf';
        case 'csv': return 'text/csv';
        case 'jpg':
        case 'jpeg': return 'image/jpeg';
        case 'png': return 'image/png';
        case 'gif': return 'image/gif';
        case 'mp3': return 'audio/mpeg';
        case 'wav': return 'audio/wav';
        default: return 'text/plain';
      }
    }
    return file.mimeType;
  }, [file.name, file.mimeType]);

  useEffect(() => {
    setEditableContent(file.content || '');
    
    const mimeType = getMimeType();
    if (mimeType === 'text/csv' && file.content && !file.content.startsWith('data:')) {
      try {
        const results = parse(file.content, { header: true });
        setCsvData(results.data);
      } catch (error) {
        console.error('CSV parsing error:', error);
        setCsvData([]);
      }
    } else {
      setCsvData([]); // Clear CSV data if not a CSV file or no content
    }
  }, [file.content, getMimeType]); // Dependencies: file.content and memoized getMimeType

  const handleSave = () => {
    console.log('[FilePreview.tsx handleSave] Saving content:', editableContent);
    onSave(editableContent);
    setIsEditing(false);
  };

  const handleDownload = () => {
    if (!file.content) {
      console.error('No content to download.');
      alert('文件内容为空，无法下载。');
      return;
    }

    let blob;
    const effectiveMimeType = getMimeType() || 'application/octet-stream';

    if (file.content.startsWith('data:')) {
      // Handle base64 data URL
      const [header, base64Data] = file.content.split(',');
      if (!base64Data) {
        alert('无效的文件内容格式，无法下载。');
        return;
      }
      try {
        const byteCharacters = atob(base64Data);
        const byteNumbers = new Array(byteCharacters.length);
        for (let i = 0; i < byteCharacters.length; i++) {
          byteNumbers[i] = byteCharacters.charCodeAt(i);
        }
        const byteArray = new Uint8Array(byteNumbers);
        blob = new Blob([byteArray], { type: effectiveMimeType });
      } catch (e) {
        console.error('Error decoding base64 content:', e);
        alert('解码文件内容失败，无法下载。');
        return;
      }
    } else {
      // Handle plain text content
      blob = new Blob([file.content], { type: effectiveMimeType });
    }

    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', file.name || 'download');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  const renderCSVPreview = () => {
    if (!csvData.length) return <p>没有可用的数据</p>;
    
    const headers = Object.keys(csvData[0]);
    return (
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              {headers.map((header, index) => (
                <th key={index} className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {csvData.slice(0, 100).map((row, rowIndex) => (
              <tr key={rowIndex}>
                {headers.map((header, colIndex) => (
                  <td key={colIndex} className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {row[header]}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
        {csvData.length > 100 && (
          <p className="text-gray-500 mt-4">显示前100行，共 {csvData.length} 行</p>
        )}
      </div>
    );
  };

  const renderContent = () => {
    const mimeType = getMimeType();
    
    // Image preview
    if (mimeType.startsWith('image/')) {
      return (
        <div className="flex justify-center">
          <img 
            src={file.content} 
            alt={file.name} 
            className="max-w-full max-h-[calc(100vh - 250px)] object-contain"
            loading="lazy"
          />
        </div>
      );
    }
    
    // Audio preview
    if (mimeType.startsWith('audio/')) {
      return (
        <div className="flex justify-center items-center h-[200px]">
          <ReactAudioPlayer
            src={file.content}
            controls
            className="w-full max-w-[500px]"
          />
        </div>
      );
    }
    
    // PDF preview
    if (mimeType === 'application/pdf') {
      return (
        <div className="flex flex-col items-center">
          <Document
            file={file.content}
            onLoadSuccess={({ numPages }) => setNumPages(numPages)}
            error="PDF加载失败"
            loading="正在加载PDF..."
            className="max-h-[calc(100vh - 300px)] overflow-auto"
          >
            <Page 
              pageNumber={currentPage} 
              width={Math.min(window.innerWidth * 0.6, 800)}
              error="页面加载失败"
              loading="正在加载页面..."
            />
          </Document>
          {numPages && (
            <div className="flex items-center gap-4 mt-4">
              <button
                onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                disabled={currentPage <= 1}
                className="px-4 py-2 bg-blue-500 text-white rounded disabled:bg-gray-300"
              >
                上一页
              </button>
              <span>
                第 {currentPage} 页，共 {numPages} 页
              </span>
              <button
                onClick={() => setCurrentPage(p => Math.min(numPages!, p + 1))}
                disabled={currentPage >= numPages!}
                className="px-4 py-2 bg-blue-500 text-white rounded disabled:bg-gray-300"
              >
                下一页
              </button>
            </div>
          )}
        </div>
      );
    }

    // CSV preview
    if (mimeType === 'text/csv') {
      return renderCSVPreview();
    }
    
    // Default to Text preview for text-based types or any unhandled type
    if (mimeType.startsWith('text/') || 
        mimeType === 'application/json' ||
        mimeType === 'application/javascript' ||
        mimeType === 'application/typescript' ||
        mimeType === 'application/xml' ||
        (mimeType === 'application/octet-stream' && (file.name.endsWith('.log') || file.name.endsWith('.yaml')|| file.name.endsWith('.yml') || file.name.endsWith('.md') || file.name.endsWith('.txt'))) ||
        !mimeType.startsWith('image/') && !mimeType.startsWith('audio/') && mimeType !== 'application/pdf' && mimeType !== 'text/csv'
      ) {
      if (isEditing && (mimeType.startsWith('text/') || mimeType === 'application/json' || (mimeType === 'application/octet-stream' && (file.name.endsWith('.log') || file.name.endsWith('.yaml')|| file.name.endsWith('.yml') || file.name.endsWith('.md') || file.name.endsWith('.txt'))))) {
        return (
          <textarea
            value={editableContent}
            onChange={(e) => setEditableContent(e.target.value)}
            className="w-full h-[calc(100vh - 280px)] p-2 border rounded font-mono"
          />
        );
      } else {
        if (typeof file.content === 'string' && file.content.startsWith('data:')) {
          return <p className="text-center p-4">此文件内容为二进制格式，无法直接作为文本预览。</p>;
        }
        const lines = file.content?.split('\n') || [];
        return (
          <div>
            <p className="mb-2 text-sm text-gray-600">共 {lines.length} 行</p>
            <pre className="whitespace-pre-wrap max-h-[calc(100vh - 300px)] overflow-auto p-4 bg-gray-50 rounded font-mono text-sm">
              {file.content || '文件内容为空或无法加载。'}
            </pre>
          </div>
        );
      }
    }
    return <p className="text-center p-4">此文件类型 ({mimeType}) 无法预览。请尝试下载查看。</p>;
  };

  const canBeEdited = getMimeType().startsWith('text/') || 
                      getMimeType() === 'application/json' ||
                      (getMimeType() === 'application/octet-stream' && (file.name.endsWith('.log') || file.name.endsWith('.yaml')|| file.name.endsWith('.yml') || file.name.endsWith('.md') || file.name.endsWith('.txt')));

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl h-[90vh] flex flex-col">
        <div className="flex justify-between items-center p-4 border-b">
          <h2 className="text-xl font-semibold truncate" title={file.name}>
            <Info size={20} className="inline mr-2 text-blue-500" />
            文件预览: {file.name}
          </h2>
          <div className="flex items-center gap-2">
            <button
              onClick={handleDownload}
              className="bg-purple-500 text-white px-3 py-1.5 rounded hover:bg-purple-600 transition-colors text-sm flex items-center"
              title="下载文件"
            >
              <Download size={16} className="inline mr-1" /> 下载
            </button>
            {canBeEdited && (
              <button
                onClick={() => setIsEditing(!isEditing)}
                className="bg-blue-500 text-white px-3 py-1.5 rounded hover:bg-blue-600 transition-colors text-sm"
              >
                {isEditing ? '取消编辑' : '编辑'}
              </button>
            )}
            {isEditing && (
              <button
                onClick={handleSave}
                className="bg-green-500 text-white px-3 py-1.5 rounded hover:bg-green-600 transition-colors text-sm flex items-center"
              >
                <Save size={16} className="inline mr-1" /> 保存
              </button>
            )}
            <button 
              onClick={onClose} 
              className="text-gray-500 hover:text-gray-700 p-1.5 rounded-full hover:bg-gray-100"
              title="关闭"
            >
              <X size={20} />
            </button>
          </div>
        </div>

        <div className="p-3 bg-gray-50 border-b text-sm">
          <div className="grid grid-cols-3 gap-x-4 gap-y-1">
            <div><strong>文件名:</strong> <span className="truncate" title={file.name}>{file.name}</span></div>
            <div><strong>大小:</strong> {formatBytes(file.size)}</div>
            <div><strong>修改时间:</strong> {formatTimestamp(file.modificationTime)}</div>
            <div><strong>MIME类型:</strong> {getMimeType() || '未知'}</div>
            { numPages && getMimeType() === 'application/pdf' && (
              <div><strong>PDF页数:</strong> {numPages}</div>
            )}
          </div>
        </div>

        <div className="flex-grow overflow-auto p-4">
          {renderContent()}
        </div>
      </div>
    </div>
  );
};

export default FilePreview;