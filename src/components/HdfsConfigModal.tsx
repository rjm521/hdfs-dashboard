import React, { useState } from 'react';
import { getHdfsConfig, setHdfsConfig } from '../config';

interface HdfsConfigModalProps {
  onClose: () => void;
}

const HdfsConfigModal: React.FC<HdfsConfigModalProps> = ({ onClose }) => {
  const current = getHdfsConfig();
  const [hdfsHost, setHdfsHost] = useState(current.hdfsHost);
  const [hdfsPort, setHdfsPort] = useState(current.hdfsPort);
  const [baseUrl, setBaseUrl] = useState(current.baseUrl);
  const [username, setUsername] = useState(current.username);
  const [password, setPassword] = useState(current.password);

  const handleSave = () => {
    setHdfsConfig({ hdfsHost, hdfsPort, baseUrl, username, password });
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md shadow-lg">
        <h2 className="text-xl font-bold mb-4">HDFS 连接配置</h2>
        <div className="mb-4">
          <label className="block mb-1 font-medium">HDFS IP</label>
          <input
            className="w-full border rounded px-3 py-2"
            value={hdfsHost}
            onChange={e => setHdfsHost(e.target.value)}
            placeholder="HDFS 服务器 IP"
          />
        </div>
        <div className="mb-4">
          <label className="block mb-1 font-medium">HDFS 端口</label>
          <input
            className="w-full border rounded px-3 py-2"
            value={hdfsPort}
            onChange={e => setHdfsPort(e.target.value)}
            placeholder="HDFS 端口"
          />
        </div>
        <div className="mb-4">
          <label className="block mb-1 font-medium">Base URL</label>
          <input
            className="w-full border rounded px-3 py-2"
            value={baseUrl}
            onChange={e => setBaseUrl(e.target.value)}
            placeholder="HDFS API Base URL"
          />
        </div>
        <div className="mb-4">
          <label className="block mb-1 font-medium">用户名</label>
          <input
            className="w-full border rounded px-3 py-2"
            value={username}
            onChange={e => setUsername(e.target.value)}
            placeholder="用户名"
          />
        </div>
        <div className="mb-6">
          <label className="block mb-1 font-medium">密码</label>
          <input
            className="w-full border rounded px-3 py-2"
            type="password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            placeholder="密码"
          />
        </div>
        <div className="flex justify-end space-x-2">
          <button
            className="px-4 py-2 rounded bg-gray-300 hover:bg-gray-400"
            onClick={onClose}
          >
            取消
          </button>
          <button
            className="px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700"
            onClick={handleSave}
          >
            保存
          </button>
        </div>
      </div>
    </div>
  );
};

export default HdfsConfigModal; 