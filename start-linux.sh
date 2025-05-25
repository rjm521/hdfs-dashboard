#!/bin/bash

# ===============================================
# HDFS Dashboard Linux 启动脚本
# 功能：环境检查、依赖安装、服务启动、状态监控
# 版本：v2.1.2
# ===============================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="HDFS Dashboard"
CONFIG_FILE="$SCRIPT_DIR/app.config.json"
BACKEND_PORT=3001
FRONTEND_PORT=5173
LOG_DIR="$SCRIPT_DIR/logs"
PID_DIR="$SCRIPT_DIR/pids"

# 创建必要的目录
mkdir -p "$LOG_DIR" "$PID_DIR"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE} $1 ${NC}"
    echo -e "${PURPLE}========================================${NC}"
}

# 显示帮助信息
show_help() {
    cat << EOF
🚀 $PROJECT_NAME Linux 启动脚本

用法: $0 [命令] [选项]

命令:
  start           启动服务 (默认命令)
  stop            停止服务
  restart         重启服务
  status          查看服务状态
  logs            查看日志
  install         安装依赖
  build           构建前端
  check           检查环境
  clean           清理临时文件
  help            显示此帮助信息

选项:
  -p, --port      指定前端端口 (默认: 5173)
  -b, --backend   指定后端端口 (默认: 3001)
  -d, --dev       使用开发模式启动
  -v, --verbose   显示详细日志
  -h, --help      显示帮助信息

示例:
  $0 start                    # 启动服务
  $0 start -p 8080 -b 3002   # 指定端口启动
  $0 start --dev             # 开发模式启动
  $0 stop                     # 停止服务
  $0 status                   # 查看状态
  $0 logs                     # 查看日志

EOF
}

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        return 0  # 端口被占用
    fi
    return 1  # 端口未被占用
}

# 获取端口占用进程
get_port_process() {
    local port=$1
    netstat -tulnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1
}

# 检查环境依赖
check_environment() {
    log_header "环境依赖检查"

    local all_ok=true

    # 检查 Node.js
    if check_command "node"; then
        local node_version=$(node --version)
        log_success "Node.js: $node_version"

        # 检查 Node.js 版本 (建议 v16+)
        local node_major=$(echo $node_version | sed 's/v//' | cut -d'.' -f1)
        if [ "$node_major" -lt 16 ]; then
            log_warning "建议使用 Node.js v16 或更高版本"
        fi
    else
        log_error "Node.js 未安装"
        log_info "安装方法: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs"
        all_ok=false
    fi

    # 检查 npm
    if check_command "npm"; then
        local npm_version=$(npm --version)
        log_success "npm: v$npm_version"
    else
        log_error "npm 未安装"
        all_ok=false
    fi

    # 检查 curl
    if check_command "curl"; then
        log_success "curl: 已安装"
    else
        log_error "curl 未安装"
        log_info "安装方法: sudo apt-get install curl"
        all_ok=false
    fi

    # 检查 netstat
    if check_command "netstat"; then
        log_success "netstat: 已安装"
    else
        log_warning "netstat 未安装，端口检查功能受限"
        log_info "安装方法: sudo apt-get install net-tools"
    fi

    # 检查配置文件
    if [ -f "$CONFIG_FILE" ]; then
        log_success "配置文件: $CONFIG_FILE"

        # 验证 JSON 格式
        if check_command "python3"; then
            if python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
                log_success "配置文件格式正确"
            else
                log_error "配置文件格式错误"
                all_ok=false
            fi
        fi
    else
        log_error "配置文件不存在: $CONFIG_FILE"
        log_info "请创建配置文件或从模板复制：cp app.config.production.json app.config.json"
        all_ok=false
    fi

    # 检查项目文件
    if [ -f "$SCRIPT_DIR/package.json" ]; then
        log_success "项目文件: package.json"
    else
        log_error "package.json 不存在"
        all_ok=false
    fi

    if [ -f "$SCRIPT_DIR/server.js" ]; then
        log_success "后端文件: server.js"
    else
        log_error "server.js 不存在"
        all_ok=false
    fi

    if [ "$all_ok" = true ]; then
        log_success "环境检查通过！"
        return 0
    else
        log_error "环境检查失败，请先解决上述问题"
        return 1
    fi
}

# 安装依赖
install_dependencies() {
    log_header "安装项目依赖"

    cd "$SCRIPT_DIR"

    if [ -f "package-lock.json" ]; then
        log_info "检测到 package-lock.json，使用 npm ci..."
        npm ci
    else
        log_info "使用 npm install..."
        npm install
    fi

    log_success "依赖安装完成"
}

# 构建前端
build_frontend() {
    log_header "构建前端应用"

    cd "$SCRIPT_DIR"

    log_info "开始构建前端..."

    # 设置 Node.js 环境变量以解决常见的构建问题
    export NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=4096"

    # 尝试构建
    if npm run build; then
        if [ -d "dist" ]; then
            log_success "前端构建完成"
            return 0
        else
            log_error "构建命令执行成功但未生成 dist 目录"
        fi
    else
        log_warning "标准构建失败，尝试其他方案..."

        # 检查是否是 crypto.getRandomValues 错误
        if npm run build 2>&1 | grep -q "crypto.*getRandomValues"; then
            log_info "检测到 crypto.getRandomValues 错误，执行修复..."

            # 方案1: 清理依赖重新安装
            log_info "方案1: 清理依赖重新安装..."
            rm -rf node_modules package-lock.json
            npm install

            # 方案2: 安装必要的依赖
            log_info "方案2: 安装额外依赖..."
            npm install --save-dev @types/node

            # 方案3: 使用开发模式构建
            log_info "方案3: 尝试开发模式构建..."
            if npx vite build --mode development; then
                log_success "开发模式构建成功"
                return 0
            fi

            # 方案4: 降级构建
            log_info "方案4: 尝试降级构建..."
            export NODE_OPTIONS="--openssl-legacy-provider --max-old-space-size=2048"
            if npm run build; then
                log_success "降级构建成功"
                return 0
            fi
        fi

        # 最后尝试: 跳过构建，使用开发模式
        log_warning "所有构建方案都失败了"
        log_info "建议使用开发模式启动: ./start-linux.sh start --dev"
        log_info "或手动修复构建问题后重试"

        return 1
    fi
}

# 检查HDFS连接
test_hdfs_connection() {
    log_info "测试HDFS连接..."

    if [ ! -f "$CONFIG_FILE" ]; then
        log_warning "配置文件不存在，跳过HDFS连接测试"
        return 0
    fi

    # 从配置文件读取HDFS信息
    if check_command "python3"; then
        local hdfs_host=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    config = json.load(f)
print(config['hdfs']['namenode']['host'])
" 2>/dev/null)

        local hdfs_port=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    config = json.load(f)
print(config['hdfs']['namenode']['port'])
" 2>/dev/null)

        local hdfs_scheme=$(python3 -c "
import json
with open('$CONFIG_FILE') as f:
    config = json.load(f)
print(config['hdfs']['namenode']['scheme'])
" 2>/dev/null)

        if [ -n "$hdfs_host" ] && [ -n "$hdfs_port" ]; then
            local hdfs_url="${hdfs_scheme}://${hdfs_host}:${hdfs_port}"
            log_info "测试HDFS连接: $hdfs_url"

            if curl -k --connect-timeout 5 "$hdfs_url" > /dev/null 2>&1; then
                log_success "HDFS连接正常"
            else
                log_warning "HDFS连接失败，请检查网络和配置"
            fi
        fi
    else
        log_warning "无法解析配置文件，跳过HDFS连接测试"
    fi
}

# 启动后端服务
start_backend() {
    log_info "启动后端服务..."

    # 检查端口占用
    if check_port $BACKEND_PORT; then
        local pid=$(get_port_process $BACKEND_PORT)
        log_warning "后端端口 $BACKEND_PORT 已被占用 (PID: $pid)"
        log_info "是否要停止占用进程？[y/N]"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            kill -9 "$pid" 2>/dev/null || true
            sleep 2
        else
            log_error "无法启动后端服务，端口被占用"
            return 1
        fi
    fi

    cd "$SCRIPT_DIR"

    # 启动后端服务
    nohup npm run server > "$LOG_DIR/backend.log" 2>&1 &
    local backend_pid=$!
    echo $backend_pid > "$PID_DIR/backend.pid"

    log_info "后端服务启动中... (PID: $backend_pid)"

    # 等待后端服务启动
    local count=0
    local max_attempts=30

    while [ $count -lt $max_attempts ]; do
        if curl -s "http://localhost:$BACKEND_PORT/admin/login" > /dev/null 2>&1; then
            log_success "后端服务启动成功 (端口: $BACKEND_PORT)"
            return 0
        fi

        # 检查进程是否还存在
        if ! kill -0 $backend_pid 2>/dev/null; then
            log_error "后端进程意外退出"
            cat "$LOG_DIR/backend.log"
            return 1
        fi

        count=$((count + 1))
        echo -n "."
        sleep 1
    done

    echo ""
    log_error "后端服务启动超时"
    log_info "查看日志: tail -f $LOG_DIR/backend.log"
    return 1
}

# 启动前端服务
start_frontend() {
    log_info "启动前端服务..."

    # 检查端口占用
    if check_port $FRONTEND_PORT; then
        local pid=$(get_port_process $FRONTEND_PORT)
        log_warning "前端端口 $FRONTEND_PORT 已被占用 (PID: $pid)"
        log_info "是否要停止占用进程？[y/N]"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            kill -9 "$pid" 2>/dev/null || true
            sleep 2
        else
            log_error "无法启动前端服务，端口被占用"
            return 1
        fi
    fi

    cd "$SCRIPT_DIR"

    # 根据模式启动前端
    if [ "$DEV_MODE" = "true" ]; then
        log_info "开发模式启动前端..."
        nohup npm run dev > "$LOG_DIR/frontend.log" 2>&1 &
    else
        log_info "生产模式启动前端..."
        nohup npm run preview > "$LOG_DIR/frontend.log" 2>&1 &
    fi

    local frontend_pid=$!
    echo $frontend_pid > "$PID_DIR/frontend.pid"

    log_info "前端服务启动中... (PID: $frontend_pid)"

    # 等待前端服务启动
    local count=0
    local max_attempts=20

    while [ $count -lt $max_attempts ]; do
        if curl -s "http://localhost:$FRONTEND_PORT" > /dev/null 2>&1; then
            log_success "前端服务启动成功 (端口: $FRONTEND_PORT)"
            return 0
        fi

        # 检查进程是否还存在
        if ! kill -0 $frontend_pid 2>/dev/null; then
            log_error "前端进程意外退出"
            cat "$LOG_DIR/frontend.log"
            return 1
        fi

        count=$((count + 1))
        echo -n "."
        sleep 1
    done

    echo ""
    log_error "前端服务启动超时"
    log_info "查看日志: tail -f $LOG_DIR/frontend.log"
    return 1
}

# 显示访问信息
show_access_info() {
    log_header "服务访问信息"

    # 获取本机IP
    local local_ip
    if check_command "hostname"; then
        local_ip=$(hostname -I | awk '{print $1}' 2>/dev/null)
    fi

    if [ -z "$local_ip" ]; then
        local_ip="YOUR_SERVER_IP"
    fi

    echo -e "${CYAN}🌐 访问地址：${NC}"
    echo -e "   前端界面: ${GREEN}http://localhost:$FRONTEND_PORT${NC}"
    echo -e "   后端API:  ${GREEN}http://localhost:$BACKEND_PORT${NC}"
    echo -e "   管理面板: ${GREEN}http://localhost:$BACKEND_PORT/admin/login${NC}"
    echo ""
    echo -e "${CYAN}🌍 外网访问（如果防火墙允许）：${NC}"
    echo -e "   前端界面: ${GREEN}http://$local_ip:$FRONTEND_PORT${NC}"
    echo -e "   后端API:  ${GREEN}http://$local_ip:$BACKEND_PORT${NC}"
    echo -e "   管理面板: ${GREEN}http://$local_ip:$BACKEND_PORT/admin/login${NC}"
    echo ""
    echo -e "${CYAN}📋 日志文件：${NC}"
    echo -e "   后端日志: ${YELLOW}$LOG_DIR/backend.log${NC}"
    echo -e "   前端日志: ${YELLOW}$LOG_DIR/frontend.log${NC}"
    echo ""
    echo -e "${CYAN}🛑 停止服务：${NC}"
    echo -e "   执行命令: ${YELLOW}$0 stop${NC}"
}

# 启动服务
start_services() {
    log_header "启动 $PROJECT_NAME"

    # 环境检查
    if ! check_environment; then
        log_error "环境检查失败，无法启动服务"
        return 1
    fi

    # 检查依赖
    if [ ! -d "node_modules" ]; then
        log_info "未找到 node_modules，开始安装依赖..."
        install_dependencies
    fi

    # 检查构建文件（生产模式需要）
    if [ "$DEV_MODE" != "true" ] && [ ! -d "dist" ]; then
        log_info "未找到构建文件，开始构建前端..."
        build_frontend
    fi

    # 测试HDFS连接
    test_hdfs_connection

    # 启动后端服务
    if ! start_backend; then
        log_error "后端服务启动失败"
        return 1
    fi

    # 启动前端服务
    if ! start_frontend; then
        log_error "前端服务启动失败"
        # 停止后端服务
        stop_services
        return 1
    fi

    # 显示访问信息
    show_access_info

    log_success "所有服务启动完成！"

    # 设置信号处理
    trap 'log_info "收到停止信号，正在停止服务..."; stop_services; exit 0' INT TERM

    # 保持脚本运行
    log_info "按 Ctrl+C 停止所有服务"
    wait
}

# 停止服务
stop_services() {
    log_header "停止 $PROJECT_NAME"

    local stopped_any=false

    # 停止前端服务
    if [ -f "$PID_DIR/frontend.pid" ]; then
        local frontend_pid=$(cat "$PID_DIR/frontend.pid")
        if kill -0 "$frontend_pid" 2>/dev/null; then
            log_info "停止前端服务 (PID: $frontend_pid)"
            kill -TERM "$frontend_pid" 2>/dev/null || true
            # 等待进程结束
            local count=0
            while kill -0 "$frontend_pid" 2>/dev/null && [ $count -lt 10 ]; do
                sleep 1
                count=$((count + 1))
            done
            # 强制杀死
            if kill -0 "$frontend_pid" 2>/dev/null; then
                kill -KILL "$frontend_pid" 2>/dev/null || true
            fi
            stopped_any=true
        fi
        rm -f "$PID_DIR/frontend.pid"
    fi

    # 停止后端服务
    if [ -f "$PID_DIR/backend.pid" ]; then
        local backend_pid=$(cat "$PID_DIR/backend.pid")
        if kill -0 "$backend_pid" 2>/dev/null; then
            log_info "停止后端服务 (PID: $backend_pid)"
            kill -TERM "$backend_pid" 2>/dev/null || true
            # 等待进程结束
            local count=0
            while kill -0 "$backend_pid" 2>/dev/null && [ $count -lt 10 ]; do
                sleep 1
                count=$((count + 1))
            done
            # 强制杀死
            if kill -0 "$backend_pid" 2>/dev/null; then
                kill -KILL "$backend_pid" 2>/dev/null || true
            fi
            stopped_any=true
        fi
        rm -f "$PID_DIR/backend.pid"
    fi

    # 通过端口查找并停止相关进程
    if check_command "netstat"; then
        # 停止占用前端端口的进程
        local frontend_processes=$(netstat -tulnp 2>/dev/null | grep ":$FRONTEND_PORT " | awk '{print $7}' | cut -d'/' -f1)
        for pid in $frontend_processes; do
            if [ -n "$pid" ] && [ "$pid" != "-" ]; then
                log_info "停止前端相关进程 (PID: $pid)"
                kill -TERM "$pid" 2>/dev/null || true
                stopped_any=true
            fi
        done

        # 停止占用后端端口的进程
        local backend_processes=$(netstat -tulnp 2>/dev/null | grep ":$BACKEND_PORT " | awk '{print $7}' | cut -d'/' -f1)
        for pid in $backend_processes; do
            if [ -n "$pid" ] && [ "$pid" != "-" ]; then
                log_info "停止后端相关进程 (PID: $pid)"
                kill -TERM "$pid" 2>/dev/null || true
                stopped_any=true
            fi
        done
    fi

    if [ "$stopped_any" = true ]; then
        log_success "服务已停止"
    else
        log_info "没有运行中的服务"
    fi
}

# 重启服务
restart_services() {
    log_header "重启 $PROJECT_NAME"
    stop_services
    sleep 2
    start_services
}

# 查看服务状态
show_status() {
    log_header "服务状态"

    # 检查后端服务
    if [ -f "$PID_DIR/backend.pid" ]; then
        local backend_pid=$(cat "$PID_DIR/backend.pid")
        if kill -0 "$backend_pid" 2>/dev/null; then
            if curl -s "http://localhost:$BACKEND_PORT/admin/login" > /dev/null 2>&1; then
                log_success "后端服务: 运行中 (PID: $backend_pid, 端口: $BACKEND_PORT) ✅"
            else
                log_warning "后端服务: 进程存在但服务异常 (PID: $backend_pid)"
            fi
        else
            log_error "后端服务: 已停止 (PID文件存在但进程不存在)"
        fi
    else
        log_error "后端服务: 已停止"
    fi

    # 检查前端服务
    if [ -f "$PID_DIR/frontend.pid" ]; then
        local frontend_pid=$(cat "$PID_DIR/frontend.pid")
        if kill -0 "$frontend_pid" 2>/dev/null; then
            if curl -s "http://localhost:$FRONTEND_PORT" > /dev/null 2>&1; then
                log_success "前端服务: 运行中 (PID: $frontend_pid, 端口: $FRONTEND_PORT) ✅"
            else
                log_warning "前端服务: 进程存在但服务异常 (PID: $frontend_pid)"
            fi
        else
            log_error "前端服务: 已停止 (PID文件存在但进程不存在)"
        fi
    else
        log_error "前端服务: 已停止"
    fi

    # 检查端口占用
    if check_command "netstat"; then
        echo ""
        log_info "端口占用情况："
        netstat -tulnp 2>/dev/null | grep -E ":($FRONTEND_PORT|$BACKEND_PORT) " | while read line; do
            echo "  $line"
        done
    fi
}

# 查看日志
show_logs() {
    log_header "服务日志"

    echo -e "${CYAN}选择要查看的日志：${NC}"
    echo "1) 后端日志"
    echo "2) 前端日志"
    echo "3) 同时查看两个日志"
    echo "4) 返回"

    read -p "请选择 [1-4]: " choice

    case $choice in
        1)
            if [ -f "$LOG_DIR/backend.log" ]; then
                log_info "显示后端日志 (按 Ctrl+C 退出):"
                tail -f "$LOG_DIR/backend.log"
            else
                log_error "后端日志文件不存在"
            fi
            ;;
        2)
            if [ -f "$LOG_DIR/frontend.log" ]; then
                log_info "显示前端日志 (按 Ctrl+C 退出):"
                tail -f "$LOG_DIR/frontend.log"
            else
                log_error "前端日志文件不存在"
            fi
            ;;
        3)
            if [ -f "$LOG_DIR/backend.log" ] && [ -f "$LOG_DIR/frontend.log" ]; then
                log_info "同时显示两个日志 (按 Ctrl+C 退出):"
                tail -f "$LOG_DIR/backend.log" "$LOG_DIR/frontend.log"
            else
                log_error "日志文件不存在"
            fi
            ;;
        4)
            return 0
            ;;
        *)
            log_error "无效选择"
            ;;
    esac
}

# 清理临时文件
clean_temp() {
    log_header "清理临时文件"

    # 清理日志文件
    if [ -d "$LOG_DIR" ]; then
        log_info "清理日志文件..."
        rm -rf "$LOG_DIR"/*
    fi

    # 清理PID文件
    if [ -d "$PID_DIR" ]; then
        log_info "清理PID文件..."
        rm -rf "$PID_DIR"/*
    fi

    # 清理上传临时目录
    if [ -d "$SCRIPT_DIR/uploads_tmp" ]; then
        log_info "清理上传临时目录..."
        rm -rf "$SCRIPT_DIR/uploads_tmp"/*
    fi

    # 清理构建文件
    if [ -d "$SCRIPT_DIR/dist" ]; then
        log_info "是否要删除构建文件 dist/ ？[y/N]"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf "$SCRIPT_DIR/dist"
            log_success "构建文件已清理"
        fi
    fi

    log_success "临时文件清理完成"
}

# 主函数
main() {
    # 默认值
    COMMAND="start"
    DEV_MODE="false"
    VERBOSE="false"

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            start|stop|restart|status|logs|install|build|check|clean|help)
                COMMAND="$1"
                shift
                ;;
            -p|--port)
                FRONTEND_PORT="$2"
                shift 2
                ;;
            -b|--backend)
                BACKEND_PORT="$2"
                shift 2
                ;;
            -d|--dev)
                DEV_MODE="true"
                shift
                ;;
            -v|--verbose)
                VERBOSE="true"
                set -x
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 显示脚本信息
    log_header "$PROJECT_NAME Linux 启动脚本 v2.1.2"

    # 执行命令
    case $COMMAND in
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        install)
            install_dependencies
            ;;
        build)
            build_frontend
            ;;
        check)
            check_environment
            ;;
        clean)
            clean_temp
            ;;
        help)
            show_help
            ;;
        *)
            log_error "未知命令: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}

# 检查是否以root用户运行
if [ "$EUID" -eq 0 ]; then
    log_warning "不建议以 root 用户运行此脚本"
fi

# 执行主函数
main "$@"