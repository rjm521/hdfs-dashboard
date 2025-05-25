@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: HDFS 文件管理平台 Docker 启动脚本 (Windows版)
:: 版本: 2.0.0

set IMAGE_NAME=hdfs-dashboard
set CONTAINER_NAME=hdfs-dashboard
set FRONTEND_PORT=5173
set BACKEND_PORT=3001
set CONFIG_FILE=app.config.json
set PRODUCTION_CONFIG=app.config.production.json

echo.
echo ================================================
echo     HDFS 文件管理平台 Docker 启动脚本
echo ================================================
echo.

:: 检查Docker
docker --version >nul 2>&1
if errorlevel 1 (
    echo [错误] Docker未安装或未启动！
    echo 请先安装Docker Desktop: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo [信息] Docker环境检查通过 ✓

:: 检查配置文件
if not exist "%CONFIG_FILE%" (
    echo [警告] 配置文件 %CONFIG_FILE% 不存在！

    if exist "%PRODUCTION_CONFIG%" (
        echo [信息] 复制生产环境配置模板...
        copy "%PRODUCTION_CONFIG%" "%CONFIG_FILE%" >nul
        echo [警告] 请编辑 %CONFIG_FILE% 文件，配置您的HDFS连接信息！
        echo.
        echo 主要配置项：
        echo   - hdfs.namenode.host: HDFS NameNode地址
        echo   - hdfs.namenode.port: HDFS NameNode端口
        echo   - hdfs.auth.username: HDFS用户名
        echo   - hdfs.auth.password: HDFS密码
        echo.
        pause
    ) else (
        echo [错误] 配置文件和模板都不存在！请先创建配置文件。
        pause
        exit /b 1
    )
)

echo [信息] 配置文件检查通过 ✓

:: 解析命令行参数
set COMMAND=start
if "%~1"=="build" set COMMAND=build
if "%~1"=="stop" set COMMAND=stop
if "%~1"=="restart" set COMMAND=restart
if "%~1"=="logs" set COMMAND=logs
if "%~1"=="status" set COMMAND=status
if "%~1"=="cleanup" set COMMAND=cleanup
if "%~1"=="help" set COMMAND=help

if "%COMMAND%"=="help" goto :show_help

:: 执行命令
if "%COMMAND%"=="start" goto :start_container
if "%COMMAND%"=="build" goto :build_image
if "%COMMAND%"=="stop" goto :stop_container
if "%COMMAND%"=="restart" goto :restart_container
if "%COMMAND%"=="logs" goto :show_logs
if "%COMMAND%"=="status" goto :show_status
if "%COMMAND%"=="cleanup" goto :cleanup
goto :start_container

:start_container
echo [信息] 清理现有容器...
docker stop %CONTAINER_NAME% >nul 2>&1
docker rm %CONTAINER_NAME% >nul 2>&1

echo [信息] 构建Docker镜像...
docker build -t %IMAGE_NAME% .
if errorlevel 1 (
    echo [错误] 镜像构建失败！
    pause
    exit /b 1
)

echo [信息] 启动Docker容器...
docker run -d --name %CONTAINER_NAME% -p %FRONTEND_PORT%:5173 -p %BACKEND_PORT%:3001 -v "%cd%\%CONFIG_FILE%":/app/app.config.json:ro -v hdfs-dashboard-uploads:/app/uploads_tmp --restart unless-stopped %IMAGE_NAME%

if errorlevel 1 (
    echo [错误] 容器启动失败！
    pause
    exit /b 1
)

echo [成功] 容器启动成功 ✓
echo.

:: 获取服务器IP地址
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4" ^| findstr /v "127.0.0.1" ^| findstr /v "169.254"') do (
    for /f "tokens=1" %%b in ("%%a") do set SERVER_IP=%%b
)

:: 如果没有找到IP，使用localhost
if not defined SERVER_IP set SERVER_IP=localhost

echo 外网访问地址：
echo   前端界面: http://%SERVER_IP%:%FRONTEND_PORT%
echo   后端API:  http://%SERVER_IP%:%BACKEND_PORT%

if not "%SERVER_IP%"=="localhost" (
    echo.
    echo 本地访问地址：
    echo   前端界面: http://localhost:%FRONTEND_PORT%
    echo   后端API:  http://localhost:%BACKEND_PORT%
)

echo.
echo 管理命令：
echo   查看日志: %~nx0 logs
echo   停止服务: %~nx0 stop
echo   查看状态: %~nx0 status
goto :end

:build_image
echo [信息] 构建Docker镜像...
docker build -t %IMAGE_NAME% .
if errorlevel 1 (
    echo [错误] 镜像构建失败！
) else (
    echo [成功] 镜像构建成功 ✓
)
goto :end

:stop_container
echo [信息] 停止Docker容器...
docker stop %CONTAINER_NAME%
if errorlevel 1 (
    echo [警告] 容器未运行或停止失败
) else (
    echo [成功] 容器已停止 ✓
)
goto :end

:restart_container
echo [信息] 重启容器...
call :stop_container
timeout /t 2 /nobreak >nul
call :start_container
goto :end

:show_logs
echo [信息] 查看容器日志 (按Ctrl+C退出)...
docker logs -f %CONTAINER_NAME%
goto :end

:show_status
echo [信息] 容器状态：
docker ps -f name=%CONTAINER_NAME%
echo.
echo [信息] 资源使用情况：
docker stats %CONTAINER_NAME% --no-stream
goto :end

:cleanup
echo [警告] 这将删除容器、镜像和数据卷！
set /p confirm=确认清理所有资源？(y/N):
if /i "!confirm!"=="y" (
    echo [信息] 清理容器...
    docker rm -f %CONTAINER_NAME% >nul 2>&1
    echo [信息] 清理镜像...
    docker rmi %IMAGE_NAME% >nul 2>&1
    echo [信息] 清理数据卷...
    docker volume rm hdfs-dashboard-uploads >nul 2>&1
    echo [成功] 清理完成 ✓
) else (
    echo [信息] 已取消清理操作
)
goto :end

:show_help
echo 用法: %~nx0 [命令]
echo.
echo 命令:
echo   start          启动服务 (默认命令)
echo   build          构建Docker镜像
echo   stop           停止服务
echo   restart        重启服务
echo   logs           查看日志
echo   status         查看状态
echo   cleanup        清理容器和镜像
echo   help           显示帮助信息
echo.
echo 示例:
echo   %~nx0                # 启动服务
echo   %~nx0 build          # 构建镜像
echo   %~nx0 logs           # 查看日志
echo   %~nx0 stop           # 停止服务
goto :end

:end
echo.
pause