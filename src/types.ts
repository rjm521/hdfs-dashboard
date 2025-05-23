export interface HDFSFile {
  name: string;
  path: string;
  type: 'FILE' | 'DIRECTORY' | string;
  size?: number;
  content?: string;
  mimeType?: string;
  modificationTime?: number;
}

export interface StorageInfo {
  totalFiles: number;
  usedStorage: number;
  freeStorage: number;
  totalStorage: number;
}