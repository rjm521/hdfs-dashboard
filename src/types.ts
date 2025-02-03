export interface HDFSFile {
  name: string;
  path: string;
  type: 'FILE' | 'DIRECTORY';
  size?: number;
  content?: string;
  mimeType?: string;
}

export interface StorageInfo {
  totalFiles: number;
  usedStorage: number;
  freeStorage: number;
  totalStorage: number;
}