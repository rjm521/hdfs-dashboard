// vite.config.ts

import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { NodeGlobalsPolyfillPlugin } from '@esbuild-plugins/node-globals-polyfill';
import { NodeModulesPolyfillPlugin } from '@esbuild-plugins/node-modules-polyfill';
import fs from 'fs';
import path from 'path';

// 读取配置文件
let appConfig: any = {};
try {
  const configPath = path.resolve(__dirname, 'app.config.json');
  const configFile = fs.readFileSync(configPath, 'utf8');
  appConfig = JSON.parse(configFile);
  console.log('已加载应用配置:', configPath);
} catch (error) {
  console.error('无法加载应用配置文件，使用默认配置:', error);
  // 默认配置
  appConfig = {
    hdfs: {
      namenode: { host: '9.134.167.146', port: '8443', scheme: 'https' },
      datanode: { host: '9.134.167.146', port: '50075', scheme: 'http' },
      auth: { username: 'credit_card_all', password: 'credit_card_all' },
      paths: { gatewayPath: '/gateway/fithdfs/webhdfs/v1/', basePath: 'wx_credit_card_all' }
    },
    server: { backend: { port: 3001 }, frontend: { port: 5173 } }
  };
}

const { hdfs, server } = appConfig;

export default defineConfig({
  define: {
    global: 'globalThis',
    'process.env': process.env,
  },
  plugins: [
    react(),
    NodeGlobalsPolyfillPlugin({
      process: true,
      buffer: true,
    }),
    NodeModulesPolyfillPlugin(),
  ],
  optimizeDeps: {
    include: ['buffer', 'crypto-browserify', 'process'],
  },
  server: {
    host: '0.0.0.0',
    port: server.frontend.port,
    proxy: {
      '/namenode-api': {
        target: `${hdfs.namenode.scheme}://${hdfs.namenode.host}:${hdfs.namenode.port}`,
        changeOrigin: true,
        secure: false,
        rewrite: (path: string) => path.replace(/^\/namenode-api/, hdfs.paths.gatewayPath),
        configure: (proxy: any, options: any) => {
          proxy.on('proxyReq', (proxyReq: any, req: any, res: any) => {
            console.log(`[NameNode PROXY REQ] ${req.method} ${proxyReq.path} (Original URL: ${req.url})`);
            const auth = Buffer.from(`${hdfs.auth.username}:${hdfs.auth.password}`).toString('base64');
            proxyReq.setHeader('Authorization', `Basic ${auth}`);
            Object.keys(req.headers).forEach(key => {
              if (key.toLowerCase() !== 'host' && key.toLowerCase() !== 'authorization') {
                if (req.headers[key]) {
                  proxyReq.setHeader(key, req.headers[key] as string | string[]);
                }
              }
            });
          });
          proxy.on('proxyRes', (proxyRes: any, req: any, res: any) => {
            console.log(`[NameNode PROXY RES] ${proxyRes.statusCode} for ${req.url}. Original headers:`, JSON.stringify(proxyRes.headers));
            res.setHeader('Access-Control-Allow-Origin', '*');
            res.setHeader('Access-Control-Allow-Credentials', 'true');
            res.setHeader('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS');
            res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Cache-Control, Pragma, Expires, Content-Length');
            res.setHeader('Access-Control-Expose-Headers', 'Location, Content-Type, Content-Length, Date, Server, Cache-Control, Pragma, Expires');

            const originalLocation = proxyRes.headers['location'];

            if (proxyRes.statusCode === 307 && originalLocation) {
              console.log('[NameNode PROXY RES] Original redirect Location header found:', originalLocation);
              try {
                const dataNodeUrl = new URL(originalLocation as string);
                const newLocation = `/datanode-api${dataNodeUrl.pathname}${dataNodeUrl.search}`;
                console.log('[NameNode PROXY RES] Rewriting Location header to:', newLocation);
                res.setHeader('Location', newLocation);
                proxyRes.headers['location'] = newLocation;
              } catch (e) {
                console.error('[NameNode PROXY RES] Error parsing original location:', e, originalLocation);
              }
            } else if (proxyRes.statusCode === 307) {
              console.warn('[NameNode PROXY RES] Received 307 but no Location header was found!');
            }
          });
          proxy.on('error', (err: any, req: any, res: any) => {
            console.error(`[NameNode PROXY ERROR] for ${req.url}:`, err);
            if (res && !res.headersSent) {
              res.writeHead(500, { 'Content-Type': 'text/plain' });
              res.end('NameNode Proxy Error: ' + err.message);
            } else if (res) {
              res.end();
            }
          });
        },
      },
      '/datanode-api': {
        target: `${hdfs.datanode.scheme}://${hdfs.datanode.host}:${hdfs.datanode.port}`,
        changeOrigin: true,
        secure: false,
        rewrite: (path: string) => path.replace(/^\/datanode-api/, ''),
        configure: (proxy: any, options: any) => {
          proxy.on('proxyReq', (proxyReq: any, req: any, res: any) => {
            console.log(`[DataNode PROXY REQ] ${req.method} ${proxyReq.path} (Original URL: ${req.url})`);
            if (req.method === 'OPTIONS') {
              console.log('[DataNode PROXY REQ] Responding to OPTIONS request');
              res.setHeader('Access-Control-Allow-Origin', '*');
              res.setHeader('Access-Control-Allow-Credentials', 'true');
              res.setHeader('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS');
              res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Cache-Control, Pragma, Expires, Content-Length');
              res.setHeader('Access-Control-Max-Age', '86400');
              res.writeHead(204);
              res.end();
              return;
            }
            Object.keys(req.headers).forEach(key => {
              if (key.toLowerCase() !== 'host') {
                if (req.headers[key]) {
                  proxyReq.setHeader(key, req.headers[key] as string | string[]);
                }
              }
            });
          });
          proxy.on('proxyRes', (proxyRes: any, req: any, res: any) => {
            console.log(`[DataNode PROXY RES] ${proxyRes.statusCode} for ${req.url}`);
            res.setHeader('Access-Control-Allow-Origin', '*');
            res.setHeader('Access-Control-Allow-Credentials', 'true');
            res.setHeader('Access-Control-Allow-Methods', 'PUT, OPTIONS');
            res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Content-Length, Authorization');
            res.setHeader('Access-Control-Expose-Headers', 'Location, Content-Type, Content-Length, Date, Server, ETag');
          });
          proxy.on('error', (err: any, req: any, res: any) => {
            console.error(`[DataNode PROXY ERROR] for ${req.url}:`, err);
            if (res && !res.headersSent) {
              res.writeHead(500, { 'Content-Type': 'text/plain' });
              res.end('DataNode Proxy Error: ' + err.message);
            } else if (res) {
              res.end();
            }
          });
        },
      },
      '/api': {
        target: `http://localhost:${server.backend.port}`,
        changeOrigin: true,
        rewrite: (path: string) => path.replace(/^\/api/, ''),
      },
    },
  },
  resolve: {
    alias: {
      buffer: 'buffer',
      path: 'path-browserify',
      crypto: 'crypto-browserify',
      process: 'process/browser',
    },
  },
  build: {
    rollupOptions: {
      external: [],
    },
  },
});