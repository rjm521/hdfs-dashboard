#!/bin/bash

# ===============================================
# HDFS Dashboard 微服务管理脚本
# 功能：微服务启动、停止、状态监控
# 版本：v1.0.0
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
🚀 $PROJECT_NAME 微服务管理脚本

用法: $0 [命令] [选项]

命令:
  start           启动所有服务（后台运行）
  stop            停止所有服务
  restart         重启所有服务
  status          查看服务状态
  logs            查看服务日志
  tailf           实时跟踪日志
  health          健康检查
  help            显示此帮助信息

选项:
  -p, --port      指定前端端口 (默认: 5173)
  -b, --backend   指定后端端口 (默认: 3001)
  -d, --dev       使用开发模式启动
  -h, --help      显示帮助信息

示例:
  $0 start                    # 后台启动所有服务
  $0 start -p 8080 -b 3002   # 指定端口启动
  $0 start --dev             # 开发模式启动
  $0 stop                     # 停止所有服务
  $0 restart                  # 重启所有服务
  $0 status                   # 查看服务状态
  $0 logs                     # 查看所有日志
  $0 tailf                    # 实时跟踪日志
  $0 health                   # 服务健康检查

✅ 这个脚本启动的服务会在后台运行，不会阻塞你的终端！

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

# 启动后端服务
start_backend() {
    log_info "启动后端服务..."

    # 检查端口占用
    if check_port $BACKEND_PORT; then
        local pid=$(get_port_process $BACKEND_PORT)
        log_warning "后端端口 $BACKEND_PORT 已被占用 (PID: $pid)"
        log_info "自动停止占用进程..."
        kill -9 "$pid" 2>/dev/null || true
        sleep 2
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
        log_info "自动停止占用进程..."
        kill -9 "$pid" 2>/dev/null || true
        sleep 2
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

# 启动所有服务
start_services() {
    log_header "启动 $PROJECT_NAME 微服务"

    # 检查基本依赖
    if ! check_command "node"; then
        log_error "Node.js 未安装，请先安装 Node.js"
        return 1
    fi

    if ! check_command "npm"; then
        log_error "npm 未安装，请先安装 npm"
        return 1
    fi

    # 检查项目文件
    if [ ! -f "$SCRIPT_DIR/package.json" ]; then
        log_error "package.json 不存在，请确保在正确的项目目录中运行"
        return 1
    fi

    if [ ! -f "$SCRIPT_DIR/server.js" ]; then
        log_error "server.js 不存在，请确保后端文件存在"
        return 1
    fi

    # 检查依赖
    if [ ! -d "node_modules" ]; then
        log_info "未找到 node_modules，开始安装依赖..."
        npm install
    fi

    # 检查构建文件（生产模式需要）
    if [ "$DEV_MODE" != "true" ] && [ ! -d "dist" ]; then
        log_info "未找到构建文件，开始构建前端..."
        npm run build
    fi

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

    log_success "✅ 所有微服务已成功启动并在后台运行！"
    log_info "💡 使用 '$0 status' 查看服务状态"
    log_info "💡 使用 '$0 logs' 查看服务日志"
    log_info "💡 使用 '$0 stop' 停止所有服务"
    echo ""
    echo -e "${GREEN}🎉 服务已启动，终端已释放，你可以继续其他操作！${NC}"
}

# 停止所有服务
stop_services() {
    log_header "停止 $PROJECT_NAME 微服务"

    local stopped_any=false

    # 停止前端服务
    if [ -f "$PID_DIR/frontend.pid" ]; then
        local frontend_pid=$(cat "$PID_DIR/frontend.pid")
        if kill -0 "$frontend_pid" 2>/dev/null; then
            log_info "停止前端服务 (PID: $frontend_pid)"
            kill -TERM "$frontend_pid" 2>/dev/null || true
            sleep 2
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
            sleep 2
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
        log_success "✅ 所有服务已停止"
    else
        log_info "ℹ️  没有运行中的服务"
    fi
}

# 重启所有服务
restart_services() {
    log_header "重启 $PROJECT_NAME 微服务"
    stop_services
    sleep 3
    start_services
}

# 查看服务状态
show_status() {
    log_header "微服务状态"

    local all_running=true

    # 检查后端服务
    if [ -f "$PID_DIR/backend.pid" ]; then
        local backend_pid=$(cat "$PID_DIR/backend.pid")
        if kill -0 "$backend_pid" 2>/dev/null; then
            if curl -s "http://localhost:$BACKEND_PORT/admin/login" > /dev/null 2>&1; then
                log_success "后端服务: 运行中 ✅ (PID: $backend_pid, 端口: $BACKEND_PORT)"
            else
                log_warning "后端服务: 进程存在但服务异常 ⚠️  (PID: $backend_pid)"
                all_running=false
            fi
        else
            log_error "后端服务: 已停止 ❌ (PID文件存在但进程不存在)"
            all_running=false
        fi
    else
        log_error "后端服务: 已停止 ❌"
        all_running=false
    fi

    # 检查前端服务
    if [ -f "$PID_DIR/frontend.pid" ]; then
        local frontend_pid=$(cat "$PID_DIR/frontend.pid")
        if kill -0 "$frontend_pid" 2>/dev/null; then
            if curl -s "http://localhost:$FRONTEND_PORT" > /dev/null 2>&1; then
                log_success "前端服务: 运行中 ✅ (PID: $frontend_pid, 端口: $FRONTEND_PORT)"
            else
                log_warning "前端服务: 进程存在但服务异常 ⚠️  (PID: $frontend_pid)"
                all_running=false
            fi
        else
            log_error "前端服务: 已停止 ❌ (PID文件存在但进程不存在)"
            all_running=false
        fi
    else
        log_error "前端服务: 已停止 ❌"
        all_running=false
    fi

    echo ""
    if [ "$all_running" = true ]; then
        log_success "🎉 所有微服务运行正常！"
    else
        log_warning "⚠️  部分服务异常，请检查日志或重启服务"
    fi

    # 显示访问信息
    if [ "$all_running" = true ]; then
        echo ""
        show_access_info
    fi
}

# 显示访问信息
show_access_info() {
    echo -e "${CYAN}🌐 服务访问地址：${NC}"
    echo -e "   前端界面: ${GREEN}http://localhost:$FRONTEND_PORT${NC}"
    echo -e "   后端API:  ${GREEN}http://localhost:$BACKEND_PORT${NC}"
    echo -e "   管理面板: ${GREEN}http://localhost:$BACKEND_PORT/admin/login${NC}"
    echo ""
    echo -e "${CYAN}📋 日志文件：${NC}"
    echo -e "   后端日志: ${YELLOW}$LOG_DIR/backend.log${NC}"
    echo -e "   前端日志: ${YELLOW}$LOG_DIR/frontend.log${NC}"
}

# 查看日志
show_logs() {
    log_header "服务日志"

    echo ""
    log_info "=== 后端日志 ==="
    if [ -f "$LOG_DIR/backend.log" ]; then
        tail -20 "$LOG_DIR/backend.log"
    else
        log_warning "后端日志文件不存在"
    fi

    echo ""
    log_info "=== 前端日志 ==="
    if [ -f "$LOG_DIR/frontend.log" ]; then
        tail -20 "$LOG_DIR/frontend.log"
    else
        log_warning "前端日志文件不存在"
    fi

    echo ""
    log_info "💡 使用 '$0 tailf' 实时跟踪日志"
}

# 实时跟踪日志
tail_logs() {
    log_header "实时跟踪服务日志"
    log_info "按 Ctrl+C 退出日志跟踪"
    echo ""

    if [ -f "$LOG_DIR/backend.log" ] && [ -f "$LOG_DIR/frontend.log" ]; then
        tail -f "$LOG_DIR/backend.log" "$LOG_DIR/frontend.log"
    elif [ -f "$LOG_DIR/backend.log" ]; then
        tail -f "$LOG_DIR/backend.log"
    elif [ -f "$LOG_DIR/frontend.log" ]; then
        tail -f "$LOG_DIR/frontend.log"
    else
        log_error "没有找到日志文件"
    fi
}

# 健康检查
health_check() {
    log_header "微服务健康检查"

    local backend_ok=false
    local frontend_ok=false

    # 检查后端健康状态
    log_info "检查后端服务健康状态..."
    if curl -s -f "http://localhost:$BACKEND_PORT/admin/login" > /dev/null 2>&1; then
        log_success "后端服务健康检查通过 ✅"
        backend_ok=true
    else
        log_error "后端服务健康检查失败 ❌"
    fi

    # 检查前端健康状态
    log_info "检查前端服务健康状态..."
    if curl -s -f "http://localhost:$FRONTEND_PORT" > /dev/null 2>&1; then
        log_success "前端服务健康检查通过 ✅"
        frontend_ok=true
    else
        log_error "前端服务健康检查失败 ❌"
    fi

    echo ""
    if [ "$backend_ok" = true ] && [ "$frontend_ok" = true ]; then
        log_success "🎉 所有微服务健康检查通过！"
        return 0
    else
        log_error "❌ 健康检查失败，建议重启服务"
        return 1
    fi
}

# 主函数
main() {
    # 默认值
    COMMAND="start"
    DEV_MODE="false"

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            start|stop|restart|status|logs|tailf|health|help)
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
    log_header "$PROJECT_NAME 微服务管理器 v1.0.0"

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
        tailf)
            tail_logs
            ;;
        health)
            health_check
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