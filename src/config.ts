// HDFS 配置模块，支持动态设置和获取
export interface HdfsConfig {
  hdfsHost: string;
  hdfsPort: string;
  baseUrl: string;
  username: string;
  password: string;
}

let hdfsConfig: HdfsConfig = {
  hdfsHost: '9.134.167.146',
  hdfsPort: '8443',
  baseUrl: '/gateway/fithdfs/webhdfs/v1/wx_credit_card_all',
  username: 'credit_card_all',
  password: 'credit_card_all',
};

export function getHdfsConfig(): HdfsConfig {
  return hdfsConfig;
}

export function setHdfsConfig(config: Partial<HdfsConfig>) {
  hdfsConfig = { ...hdfsConfig, ...config };
} 