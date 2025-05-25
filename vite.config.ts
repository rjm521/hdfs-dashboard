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
  plugins: [
    react(),
    NodeGlobalsPolyfillPlugin({
      process: true,
      buffer: true,
    }),
    NodeModulesPolyfillPlugin(),
  ],
  server: {
    port: server.frontend.port,
    proxy: {
      // Proxy for NameNode/Gateway operations
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
            // Forward all original headers from the client that might be important
            Object.keys(req.headers).forEach(key => {
              if (key.toLowerCase() !== 'host' && key.toLowerCase() !== 'authorization') { // Don't overwrite host or our auth
                if (req.headers[key]) { // Check if header value is defined
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

            const originalLocation = proxyRes.headers['location']; // Headers might be lowercased by node-http-proxy

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
            if (res && !res.headersSent) { // Check if res is defined and headers are not sent
              res.writeHead(500, { 'Content-Type': 'text/plain' });
              res.end('NameNode Proxy Error: ' + err.message);
            } else if (res) {
              res.end(); // If headers sent, just end the response
            }
          });
        },
      },
      // Proxy for DataNode operations
      // Note: The target for this will be set dynamically based on the redirect from NameNode,
      // but we need a placeholder here. The actual target is the DataNode.
      '/datanode-api': {
        // This target might be different for different datanodes,
        // but the important part is the path rewrite and configure logic.
        target: `${hdfs.datanode.scheme}://${hdfs.datanode.host}:${hdfs.datanode.port}`, // 配置化的DataNode地址
        changeOrigin: true,
        secure: false, // Assuming datanodes might also use HTTP or self-signed certs
        rewrite: (path: string) => path.replace(/^\/datanode-api/, ''),
        configure: (proxy: any, options: any) => {
          // Handle OPTIONS requests explicitly for DataNode proxy
          proxy.on('proxyReq', (proxyReq: any, req: any, res: any) => {
            console.log(`[DataNode PROXY REQ] ${req.method} ${proxyReq.path} (Original URL: ${req.url})`);
            if (req.method === 'OPTIONS') {
              console.log('[DataNode PROXY REQ] Responding to OPTIONS request');
              res.setHeader('Access-Control-Allow-Origin', '*');
              res.setHeader('Access-Control-Allow-Credentials', 'true');
              res.setHeader('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS');
              res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Cache-Control, Pragma, Expires, Content-Length');
              res.setHeader('Access-Control-Max-Age', '86400'); // Cache preflight for 1 day
              res.writeHead(204); // No Content for OPTIONS success
              res.end();
              return; // Stop further processing for OPTIONS
            }
            // Forward all original headers from the client
            Object.keys(req.headers).forEach(key => {
              if (key.toLowerCase() !== 'host') { // Don't overwrite host
                if (req.headers[key]) { // Check if header value is defined
                  proxyReq.setHeader(key, req.headers[key] as string | string[]);
                }
              }
            });
            // DataNode requests often don't need separate auth if WebHDFS handles it via tokens/redirects
          });
          proxy.on('proxyRes', (proxyRes: any, req: any, res: any) => {
            console.log(`[DataNode PROXY RES] ${proxyRes.statusCode} for ${req.url}`);
            // Ensure these are always set, even if target doesn't send them (though it should for data requests)
            res.setHeader('Access-Control-Allow-Origin', '*');
            res.setHeader('Access-Control-Allow-Credentials', 'true');
            // Methods and Headers here are more for the actual PUT, not the preflight (which is handled above)
            res.setHeader('Access-Control-Allow-Methods', 'PUT, OPTIONS');
            res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Content-Length, Authorization');
            // Expose any headers client might need, like ETag or custom HDFS headers
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
      // Proxy for backend server API (new)
      '/api': {
        target: `http://localhost:${server.backend.port}`, // 配置化的后端端口
        changeOrigin: true,
        rewrite: (path: string) => path.replace(/^\/api/, ''), // Remove /api prefix before forwarding
      },
    },
  },
  resolve: {
    alias: {
      buffer: 'buffer',
      path: 'path-browserify',
    },
  },
});