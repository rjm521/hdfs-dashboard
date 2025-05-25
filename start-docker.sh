#!/bin/bash

# HDFS 文件管理平台 Docker 启动脚本
# 作者: HDFS Dashboard Team
# 版本: 2.0.0

set -e  # 出错时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="hdfs-dashboard"
IMAGE_NAME="hdfs-dashboard"
CONTAINER_NAME="hdfs-dashboard"
FRONTEND_PORT="5173"
BACKEND_PORT="3001"
CONFIG_FILE="app.config.json"
PRODUCTION_CONFIG="app.config.production.json"

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

print_info() {
    print_message $BLUE "$1"
}

print_success() {
    print_message $GREEN "$1"
}

print_warning() {
    print_message $YELLOW "$1"
}

print_error() {
    print_message $RED "$1"
}

print_header() {
    echo -e "${CYAN}"
    echo "=================================================="
    echo "    HDFS 文件管理平台 Docker 启动脚本"
    echo "=================================================="
    echo -e "${NC}"
}

# 检查Docker是否安装
check_docker() {
    print_info "检查Docker环境..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker未安装！请先安装Docker。"
        print_info "安装指南: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! docker ps &> /dev/null; then
        print_error "Docker服务未启动或权限不足！"
        print_info "请确保Docker服务正在运行，并且当前用户有权限访问Docker。"
        exit 1
    fi

    print_success "Docker环境检查通过 ✓"
}

# 检查配置文件
check_config() {
    print_info "检查配置文件..."

    if [ ! -f "$CONFIG_FILE" ]; then
        print_warning "配置文件 $CONFIG_FILE 不存在！"

        if [ -f "$PRODUCTION_CONFIG" ]; then
            print_info "复制生产环境配置模板..."
            cp "$PRODUCTION_CONFIG" "$CONFIG_FILE"
            print_warning "请编辑 $CONFIG_FILE 文件，配置您的HDFS连接信息！"
            print_info "主要配置项："
            echo "  - hdfs.namenode.host: HDFS NameNode地址"
            echo "  - hdfs.namenode.port: HDFS NameNode端口"
            echo "  - hdfs.auth.username: HDFS用户名"
            echo "  - hdfs.auth.password: HDFS密码"
            echo ""
            read -p "配置完成后按回车继续..." -r
        else
            print_error "配置文件和模板都不存在！请先创建配置文件。"
            exit 1
        fi
    fi

    # 验证配置文件格式
    if ! python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
        if ! node -e "JSON.parse(require('fs').readFileSync('$CONFIG_FILE', 'utf8'))" > /dev/null 2>&1; then
            print_error "配置文件格式错误！请检查JSON语法。"
            exit 1
        fi
    fi

    print_success "配置文件检查通过 ✓"
}

# 检查端口占用
check_ports() {
    print_info "检查端口占用..."

    local ports_in_use=""

    if lsof -Pi :$FRONTEND_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        ports_in_use="$ports_in_use $FRONTEND_PORT"
    fi

    if lsof -Pi :$BACKEND_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        ports_in_use="$ports_in_use $BACKEND_PORT"
    fi

    if [ -n "$ports_in_use" ]; then
        print_warning "以下端口已被占用:$ports_in_use"
        print_info "您可以："
        print_info "1. 停止占用端口的服务"
        print_info "2. 使用 -p 参数指定其他端口"
        read -p "是否继续？可能会导致端口冲突 (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "端口检查通过 ✓"
    fi
}

# 构建Docker镜像
build_image() {
    print_info "构建Docker镜像..."

    # 检查是否有Dockerfile
    if [ ! -f "Dockerfile" ]; then
        print_error "Dockerfile不存在！"
        exit 1
    fi

    # 显示构建进度
    print_info "开始构建镜像 $IMAGE_NAME..."
    if docker build -t $IMAGE_NAME . --progress=plain; then
        print_success "镜像构建成功 ✓"
    else
        print_error "镜像构建失败！"
        exit 1
    fi
}

# 停止并删除现有容器
cleanup_container() {
    print_info "清理现有容器..."

    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        print_info "停止运行中的容器..."
        docker stop $CONTAINER_NAME
    fi

    if docker ps -aq -f name=$CONTAINER_NAME | grep -q .; then
        print_info "删除现有容器..."
        docker rm $CONTAINER_NAME
    fi

    print_success "容器清理完成 ✓"
}

# 获取服务器IP地址
get_server_ip() {
    # 尝试多种方法获取外网IP
    local server_ip=""

    # 方法1: 获取主要网络接口IP
    if command -v hostname &> /dev/null; then
        server_ip=$(hostname -I | awk '{print $1}' 2>/dev/null)
    fi

    # 方法2: 如果上面失败，尝试ip命令
    if [ -z "$server_ip" ] && command -v ip &> /dev/null; then
        server_ip=$(ip route get 8.8.8.8 | awk '{print $7; exit}' 2>/dev/null)
    fi

    # 方法3: 如果都失败，尝试ifconfig
    if [ -z "$server_ip" ] && command -v ifconfig &> /dev/null; then
        server_ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' | sed 's/addr://')
    fi

    # 如果还是没有找到，使用localhost作为后备
    if [ -z "$server_ip" ]; then
        server_ip="localhost"
    fi

    echo "$server_ip"
}

# 启动容器
start_container() {
    local frontend_port=${1:-$FRONTEND_PORT}
    local backend_port=${2:-$BACKEND_PORT}
    local mode=${3:-"detached"}

    print_info "启动Docker容器..."

    local docker_cmd="docker run --name $CONTAINER_NAME"

    # 端口映射
    docker_cmd="$docker_cmd -p $frontend_port:5173 -p $backend_port:3001"

    # 挂载配置文件
    docker_cmd="$docker_cmd -v $(pwd)/$CONFIG_FILE:/app/app.config.json:ro"

    # 挂载上传目录（持久化）
    docker_cmd="$docker_cmd -v hdfs-dashboard-uploads:/app/uploads_tmp"

    # 环境变量
    docker_cmd="$docker_cmd -e NODE_ENV=production"

    # 运行模式
    if [ "$mode" = "interactive" ]; then
        docker_cmd="$docker_cmd -it"
    else
        docker_cmd="$docker_cmd -d"
    fi

    # 重启策略
    docker_cmd="$docker_cmd --restart unless-stopped"

    # 镜像名称
    docker_cmd="$docker_cmd $IMAGE_NAME"

    print_info "执行命令: $docker_cmd"

    if eval $docker_cmd; then
        print_success "容器启动成功 ✓"

        if [ "$mode" = "detached" ]; then
            # 获取服务器IP
            local server_ip=$(get_server_ip)

            print_info "服务访问地址："
            print_success "  前端界面: http://$server_ip:$frontend_port"
            print_success "  后端API:  http://$server_ip:$backend_port"

            if [ "$server_ip" != "localhost" ]; then
                print_info ""
                print_info "本地访问地址："
                print_info "  前端界面: http://localhost:$frontend_port"
                print_info "  后端API:  http://localhost:$backend_port"
            fi

            print_info ""
            print_info "管理命令："
            print_info "  查看日志: $0 logs"
            print_info "  停止服务: $0 stop"
            print_info "  查看状态: $0 status"
        fi
    else
        print_error "容器启动失败！"
        exit 1
    fi
}

# 使用Docker Compose启动
start_with_compose() {
    print_info "使用Docker Compose启动服务..."

    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml文件不存在！"
        exit 1
    fi

    if docker-compose up -d --build; then
        print_success "Docker Compose服务启动成功 ✓"
        print_info "查看服务状态: docker-compose ps"
        print_info "查看日志: docker-compose logs -f"
        print_info "停止服务: docker-compose down"
    else
        print_error "Docker Compose启动失败！"
        exit 1
    fi
}

# 查看日志
show_logs() {
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        print_info "查看容器日志 (按Ctrl+C退出)..."
        docker logs -f $CONTAINER_NAME
    else
        print_error "容器未运行！"
        exit 1
    fi
}

# 停止容器
stop_container() {
    print_info "停止Docker容器..."

    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        docker stop $CONTAINER_NAME
        print_success "容器已停止 ✓"
    else
        print_warning "容器未运行"
    fi
}

# 查看容器状态
show_status() {
    print_info "容器状态："

    if docker ps -f name=$CONTAINER_NAME --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q $CONTAINER_NAME; then
        docker ps -f name=$CONTAINER_NAME --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        print_success "容器正在运行 ✓"

        # 显示资源使用情况
        print_info ""
        print_info "资源使用情况："
        docker stats $CONTAINER_NAME --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    else
        print_warning "容器未运行"
    fi
}

# 进入容器Shell
enter_container() {
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        print_info "进入容器Shell..."
        docker exec -it $CONTAINER_NAME /bin/sh
    else
        print_error "容器未运行！"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    print_header
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  start          启动服务 (默认命令)"
    echo "  build          构建Docker镜像"
    echo "  stop           停止服务"
    echo "  restart        重启服务"
    echo "  logs           查看日志"
    echo "  status         查看状态"
    echo "  shell          进入容器Shell"
    echo "  compose        使用Docker Compose启动"
    echo "  cleanup        清理容器和镜像"
    echo "  help           显示帮助信息"
    echo ""
    echo "启动选项:"
    echo "  -p, --ports    指定端口 (格式: 前端端口:后端端口)"
    echo "  -i, --interactive  交互模式启动"
    echo "  -b, --build    启动前重新构建镜像"
    echo "  -c, --compose  使用Docker Compose"
    echo ""
    echo "示例:"
    echo "  $0                     # 启动服务"
    echo "  $0 start -p 8080:8081  # 使用自定义端口启动"
    echo "  $0 start -b            # 重新构建并启动"
    echo "  $0 start -i            # 交互模式启动"
    echo "  $0 compose             # 使用Docker Compose启动"
    echo "  $0 logs                # 查看日志"
    echo "  $0 stop                # 停止服务"
}

# 清理资源
cleanup() {
    print_warning "这将删除容器、镜像和数据卷！"
    read -p "确认清理所有资源？(y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "清理容器..."
        docker rm -f $CONTAINER_NAME 2>/dev/null || true

        print_info "清理镜像..."
        docker rmi $IMAGE_NAME 2>/dev/null || true

        print_info "清理数据卷..."
        docker volume rm hdfs-dashboard-uploads 2>/dev/null || true

        print_success "清理完成 ✓"
    else
        print_info "已取消清理操作"
    fi
}

# 主函数
main() {
    # 解析命令行参数
    local command="start"
    local frontend_port=$FRONTEND_PORT
    local backend_port=$BACKEND_PORT
    local interactive_mode="detached"
    local build_before_start=false
    local use_compose=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            start|build|stop|restart|logs|status|shell|compose|cleanup|help)
                command=$1
                shift
                ;;
            -p|--ports)
                if [[ $2 =~ ^[0-9]+:[0-9]+$ ]]; then
                    frontend_port=$(echo $2 | cut -d: -f1)
                    backend_port=$(echo $2 | cut -d: -f2)
                else
                    print_error "端口格式错误！请使用格式: 前端端口:后端端口"
                    exit 1
                fi
                shift 2
                ;;
            -i|--interactive)
                interactive_mode="interactive"
                shift
                ;;
            -b|--build)
                build_before_start=true
                shift
                ;;
            -c|--compose)
                use_compose=true
                shift
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done

    print_header

    # 执行命令
    case $command in
        start)
            check_docker
            check_config

            if [ "$use_compose" = true ]; then
                start_with_compose
            else
                check_ports

                if [ "$build_before_start" = true ]; then
                    build_image
                fi

                cleanup_container
                start_container $frontend_port $backend_port $interactive_mode
            fi
            ;;
        build)
            check_docker
            build_image
            ;;
        stop)
            check_docker
            stop_container
            ;;
        restart)
            check_docker
            stop_container
            sleep 2
            start_container $frontend_port $backend_port
            ;;
        logs)
            check_docker
            show_logs
            ;;
        status)
            check_docker
            show_status
            ;;
        shell)
            check_docker
            enter_container
            ;;
        compose)
            check_docker
            check_config
            start_with_compose
            ;;
        cleanup)
            check_docker
            cleanup
            ;;
        help)
            show_help
            ;;
        *)
            print_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 脚本入口
main "$@"