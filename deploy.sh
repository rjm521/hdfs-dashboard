#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🚀 Starting HDFS Dashboard deployment process..."

# 0. Configuration
DEPLOY_DIR="deploy"
FRONTEND_DIST_DIR="dist"
BACKEND_DIR_NAME="backend"
FRONTEND_DIR_NAME="frontend"
DEPLOY_PACKAGE_NAME="hdfs-dashboard-deployment.tar.gz"

# 1. Clean up previous build and deployment package
echo "🧹 Cleaning up previous build and deployment artifacts..."
rm -rf ${FRONTEND_DIST_DIR}
rm -rf ${DEPLOY_DIR}
rm -f ${DEPLOY_PACKAGE_NAME}

# 2. Build the frontend application
echo "🏗️ Building frontend application (npm run build)..."
npm run build

# 3. Create deployment directory structure
echo "⚙️ Creating deployment directory structure..."
mkdir -p ${DEPLOY_DIR}/${FRONTEND_DIR_NAME}
mkdir -p ${DEPLOY_DIR}/${BACKEND_DIR_NAME}

# 4. Copy built frontend assets
echo "🖼️ Copying built frontend assets to ${DEPLOY_DIR}/${FRONTEND_DIR_NAME}..."
cp -R ${FRONTEND_DIST_DIR}/* ${DEPLOY_DIR}/${FRONTEND_DIR_NAME}/

# 5. Copy backend server files
echo "📦 Copying backend server files to ${DEPLOY_DIR}/${BACKEND_DIR_NAME}..."
cp server.js ${DEPLOY_DIR}/${BACKEND_DIR_NAME}/
cp package.json ${DEPLOY_DIR}/${BACKEND_DIR_NAME}/ 
cp package-lock.json ${DEPLOY_DIR}/${BACKEND_DIR_NAME}/
# If you have other backend-specific config files, copy them here.
# e.g., cp .env.production ${DEPLOY_DIR}/${BACKEND_DIR_NAME}/

# 6. Create a README for the deployment package
echo "📝 Creating deployment instructions for the package..."
cat << EOF > ${DEPLOY_DIR}/README_DEPLOY.txt
HDFS Dashboard Deployment Package
=================================

This package contains the HDFS Dashboard application, ready for deployment.

Contents:
  - frontend/: Built static frontend assets.
  - backend/: Node.js backend server for file uploads.

Deployment Steps on Server:
---------------------------

1.  **Prerequisites on Server**:
    *   Node.js (version compatible with your server.js, e.g., v16+)
    *   npm
    *   A web server like Nginx or Apache (recommended for serving frontend and proxying).
    *   `curl` command (used by the backend server).
    *   Ensure the server can connect to your HDFS cluster (NameNode & DataNodes).

2.  **Upload and Extract**:
    *   Upload \`hdfs-dashboard-deployment.tar.gz\` to your server.
    *   Extract the package: \`tar -xzf hdfs-dashboard-deployment.tar.gz\`
    *   This will create a \`deploy\` directory. Navigate into it: \`cd deploy\`

3.  **Configure Backend**:
    *   Navigate to the backend directory: \`cd backend\`
    *   **Crucial**: Modify the \`server.js\` file if needed. The \`curl\` command within it for HDFS uploads likely contains hardcoded URLs, usernames, or passwords (e.g., 'https://9.134.167.146:8443/...', 'credit_card_all'). These **MUST** be updated to match your production HDFS environment. Consider using environment variables for these settings in a production setup.
    *   Install production dependencies: \`npm install --production\`
    *   Navigate back to the \`deploy\` directory: \`cd ..\`

4.  **Configure Web Server (Example: Nginx)**:
    Your web server (e.g., Nginx) should be configured to:
    *   Serve the static frontend assets from the \`deploy/frontend\` directory.
    *   Proxy API requests for HDFS operations (e.g., \`/namenode-api\`, \`/datanode-api\`) to your HDFS WebHDFS endpoints.
    *   Proxy API requests for the backend server (e.g., \`/api/upload-to-hdfs-via-server\`) to the Node.js backend server (default: \`http://localhost:3001\`).

    Example Nginx configuration snippet:
    \`\`\`nginx
    server {
        listen 80; # Or 443 for HTTPS
        server_name your_dashboard_domain.com; # Replace with your domain

        root /path/to/your/deploy/frontend; # Path to extracted frontend files
        index index.html;

        location / {
            try_files \$uri \$uri/ /index.html;
        }

        # Proxy for HDFS NameNode operations
        location /namenode-api/ {
            # IMPORTANT: Update target to your actual HDFS NameNode WebHDFS URL
            # This should match the 'target' and 'rewrite' logic from vite.config.ts but for Nginx
            proxy_pass https://YOUR_HDFS_NAMENODE_HOST:PORT/gateway/fithdfs/webhdfs/v1/; 
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            # Add any necessary HDFS authentication headers if required (e.g., if using Knox or another proxy)
        }

        # Proxy for HDFS DataNode operations (if direct or via NameNode proxy)
        # This configuration is more complex as DataNode URLs are dynamic.
        # Often, the NameNode itself handles proxying to DataNodes, or you might need
        # a more sophisticated proxy setup if clients need to reach DataNodes directly.
        # The /datanode-api/ path in vite.config.ts suggests DataNode URLs might be rewritten.
        # You'll need to replicate this logic in Nginx or ensure DataNodes are accessible.
        # A simple proxy_pass for /datanode-api/ might be:
        # location /datanode-api/ {
        #    proxy_pass http://YOUR_DATANODE_OR_NAMENODE_PROXY_TARGET/;
        #    # ... other proxy settings ...
        # }

        # Proxy for the backend Node.js server (for uploads, etc.)
        location /api/ {
            proxy_pass http://localhost:3001; # Assuming backend runs on port 3001
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
    \`\`\`
    **Remember to replace placeholders and adjust paths according to your server setup.**
    Restart/reload Nginx after configuration: \`sudo systemctl reload nginx\`

5.  **Start Backend Server**:
    *   Navigate to the \`deploy/backend\` directory.
    *   Start the server (you might want to use a process manager like PM2 for production):
        \`node server.js\`
    *   For PM2: \`pm2 start server.js --name hdfs-dashboard-backend\`

6.  **Access the Application**:
    Open your browser and navigate to the domain or IP address configured for your web server.

Troubleshooting:
  - Check Nginx error logs (\`/var/log/nginx/error.log\`) and access logs.
  - Check backend server logs (console output, or logs if using PM2).
  - Ensure HDFS WebHDFS is accessible from the server.
  - Verify firewall rules allow traffic on necessary ports (e.g., 80/443 for Nginx, 3001 for backend, HDFS ports).
EOF

# 7. Create the deployment tarball
echo "📦 Creating deployment tarball: ${DEPLOY_PACKAGE_NAME}..."
tar -czf ${DEPLOY_PACKAGE_NAME} -C . ${DEPLOY_DIR}

# 8. Clean up intermediate deployment directory
echo "🧹 Cleaning up intermediate deployment directory (${DEPLOY_DIR})..."
rm -rf ${DEPLOY_DIR}

echo ""
echo "✅ Deployment package created successfully: ${DEPLOY_PACKAGE_NAME}"
echo ""
echo "➡️ Next Steps:"
echo "1. Upload \`${DEPLOY_PACKAGE_NAME}\` to your server."
echo "2. Extract it: \`tar -xzf ${DEPLOY_PACKAGE_NAME}\`"
echo "3. Follow the instructions in \`deploy/README_DEPLOY.txt\` to configure and run the application."
echo ""
echo "Happy deploying! 🎉" 