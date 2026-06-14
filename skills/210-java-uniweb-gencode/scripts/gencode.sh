#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 忽略文件列表
IGNORE_FILES=".DS_Store"

# 参数解析
TARGET_DIR="${1:-$(pwd)}"
FILTER_TABLES="${2:-}"      # 表名过滤，多个表用逗号分隔，空表示全部
GENERATE_TYPES="${3:-entity,dto,controller}"  # 生成类型，默认全部
BACKEND_PROJECT_NAME_PARAM="${4:-}"  # 后端项目名，可选

INFO_FILE="${TARGET_DIR}/project-info.md"
SERVER_CONFIG="${HOME}/.uniweb/uniweb-system.config"

if [ ! -f "$INFO_FILE" ]; then
    echo "ERROR: 未找到项目信息文件: $INFO_FILE"
    echo "用法: $0 [目标目录] [表名列表] [生成类型] [后端项目名]"
    echo "  目标目录      项目根目录（包含 project-info.md），默认为当前目录"
    echo "  表名列表      要生成的表名，多个用逗号分隔，空表示全部"
    echo "  生成类型      entity,dto,controller 的组合，默认全部"
    echo "  后端项目名    可选，指定具体的后端项目目录名（如 my-shop-app）"
    echo ""
    echo "示例:"
    echo "  $0 /Users/user/project                    # 生成全部表的全部类型"
    echo "  $0 /Users/user/project 'user,order'       # 只生成 user 和 order 表"
    echo "  $0 /Users/user/project '' 'entity,dto'    # 全部表，只生成 entity 和 dto"
    echo "  $0 /Users/user/project '' 'entity' 'my-shop-app'  # 指定后端项目"
    exit 1
fi

PROJECT_NAME=$(grep -E "^project-name:" "$INFO_FILE" | head -1 | sed 's/project-name:[[:space:]]*//' | tr -d '"' | tr -d "'")

if [ -z "$PROJECT_NAME" ]; then
    echo "ERROR: 项目信息文件中未找到 project-name"
    exit 1
fi

# 从 uniweb-system.config 读取开发服务器地址
if [ -f "$SERVER_CONFIG" ]; then
    PROJECT_SERVER=$(grep -E "^SYSTEM_SERVER=" "$SERVER_CONFIG" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" || true)
else
    PROJECT_SERVER=""
fi

if [ -z "$PROJECT_SERVER" ]; then
    echo "ERROR: 未找到开发服务器地址"
    echo "请在 ~/.uniweb/uniweb-system.config 中添加: SYSTEM_SERVER=192.168.88.21"
    exit 1
fi

OPS_USERNAME=""
OPS_PASSWORD=""

if [ -f "$SERVER_CONFIG" ]; then
    OPS_USERNAME=$(grep -E "^MSC_OPS_USERNAME=" "$SERVER_CONFIG" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" || true)
    OPS_PASSWORD=$(grep -E "^MSC_OPS_PASSWORD=" "$SERVER_CONFIG" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'" || true)
fi

if [ -z "$OPS_USERNAME" ]; then
    echo "ERROR: 未找到 ops 用户名"
    echo "请在 ~/.uniweb/uniweb-system.config 中添加: MSC_OPS_USERNAME=your_username"
    exit 1
fi

if [ -z "$OPS_PASSWORD" ]; then
    echo "ERROR: 未找到 ops 密码"
    echo "请在 ~/.uniweb/uniweb-system.config 中添加: MSC_OPS_PASSWORD=your_password"
    exit 1
fi

SCHEMA_NAME=$(echo "$PROJECT_NAME" | tr '-' '_')
AUTH_URL="http://${PROJECT_SERVER}/uw-auth-center/auth/login"
GENCODE_URL="http://${PROJECT_SERVER}/uw-code-center/ops/codegen/databaseGenCode/downloadCode"

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

PROJECT_PACKAGE=$(echo "$PROJECT_NAME" | tr '-' '.')
PROJECT_PATH=$(echo "$PROJECT_NAME" | tr '-' '/')

BACKEND_DIR="$TARGET_DIR/backend"

# 如果通过参数指定了后端项目名，直接使用
if [ -n "$BACKEND_PROJECT_NAME_PARAM" ]; then
    PROJECT_BACKEND_DIR="$BACKEND_DIR/$BACKEND_PROJECT_NAME_PARAM"
    if [ ! -d "$PROJECT_BACKEND_DIR" ]; then
        echo "ERROR: 指定的后端项目目录不存在: $PROJECT_BACKEND_DIR"
        exit 1
    fi
    echo "  使用指定的后端项目: $BACKEND_PROJECT_NAME_PARAM"
else
    # 查找所有匹配的后端项目目录
    AVAILABLE_BACKEND_DIRS=$(find "$BACKEND_DIR" -maxdepth 1 -type d -name "${PROJECT_NAME}-app" 2>/dev/null | sort)

    if [ -z "$AVAILABLE_BACKEND_DIRS" ]; then
        echo "ERROR: 未找到后端项目目录: $BACKEND_DIR/${PROJECT_NAME}-app"
        echo "请确保已执行 210-java-uniweb-init 初始化后端项目"
        exit 1
    fi

    # 统计可用目录数量
    BACKEND_DIR_COUNT=$(echo "$AVAILABLE_BACKEND_DIRS" | wc -l | tr -d ' ')

    if [ "$BACKEND_DIR_COUNT" -eq 1 ]; then
        # 只有一个目录，直接使用
        PROJECT_BACKEND_DIR="$AVAILABLE_BACKEND_DIRS"
        echo "  找到后端项目: $(basename "$PROJECT_BACKEND_DIR")"
    else
        # 多个目录，列出供用户选择
        echo "  发现多个后端项目:"
        echo "$AVAILABLE_BACKEND_DIRS" | nl -w2 -s'. ' | while read -r line; do
            echo "     $line"
        done
        echo ""
        echo "ERROR: 存在多个后端项目，请通过命令行参数指定目标项目"
        echo "用法: bash scripts/gencode.sh [目标目录] [表名列表] [生成类型] [后端项目名]"
        echo "示例: bash scripts/gencode.sh /Users/user/project '' 'entity,dto' my-shop-app"
        exit 1
    fi
fi

SRC_JAVA_DIR="$PROJECT_BACKEND_DIR/src/main/java"
if [ ! -d "$SRC_JAVA_DIR" ]; then
    echo "ERROR: 未找到 $SRC_JAVA_DIR 目录"
    exit 1
fi

# 解析生成类型
GENERATE_ENTITY=false
GENERATE_DTO=false
GENERATE_CONTROLLER=false

if [[ "$GENERATE_TYPES" == *"entity"* ]]; then
    GENERATE_ENTITY=true
fi
if [[ "$GENERATE_TYPES" == *"dto"* ]]; then
    GENERATE_DTO=true
fi
if [[ "$GENERATE_TYPES" == *"controller"* ]]; then
    GENERATE_CONTROLLER=true
fi

echo "=== Java代码生成 ==="
echo "项目目录: $TARGET_DIR"
echo "项目名: $PROJECT_NAME"
echo "包名: $PROJECT_PACKAGE"
echo "Schema: $SCHEMA_NAME"
echo "服务器: $PROJECT_SERVER"
echo "生成表: ${FILTER_TABLES:-全部}"
echo "生成类型: $GENERATE_TYPES"
echo ""

echo "[1/5] 登录获取token..."
echo "  登录URL: $AUTH_URL"
echo "  用户名: $OPS_USERNAME"

LOGIN_PAYLOAD=$(cat <<EOF
{"loginId":"${OPS_USERNAME}","loginPass":"${OPS_PASSWORD}","loginType":1,"userType":110,"captchaSign":"","loginAgent":"ops-pc-ui:1.2.93","forceLogin":true}
EOF
)

echo "  正在请求..."
LOGIN_RESP=$(curl -s -X POST "$AUTH_URL" \
    -H 'Content-Type: application/json; charset=UTF-8' \
    -d "$LOGIN_PAYLOAD" \
    --connect-timeout 10 \
    --max-time 30 2>&1) || {
    echo "  ✗ 登录请求失败: $LOGIN_RESP"
    exit 1
}

echo "  响应: $LOGIN_RESP"

TOKEN=$(echo "$LOGIN_RESP" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "  ✗ 登录失败，无法获取token"
    echo "  请检查:"
    echo "    1. 服务器地址是否正确: $PROJECT_SERVER"
    echo "    2. ops密码是否正确配置在 ~/.uniweb/uniweb-system.config"
    echo "    3. 服务器是否可访问"
    exit 1
fi

echo "  ✓ 登录成功"

echo ""
echo "[2/5] 下载代码生成文件..."
DOWNLOAD_URL="${GENCODE_URL}?connName=\$ROOT_CONN\$&schemaName=${SCHEMA_NAME}&templateGroupId=1&filterTableNames=${FILTER_TABLES}"

HTTP_CODE=$(curl -s -w "%{http_code}" -o "$TEMP_DIR/gencode.zip" \
    -H "Authorization: Bearer $TOKEN" \
    "$DOWNLOAD_URL")

if [ "$HTTP_CODE" != "200" ]; then
    echo "  ✗ 下载失败，HTTP状态码: $HTTP_CODE"
    exit 1
fi

if [ ! -f "$TEMP_DIR/gencode.zip" ] || [ ! -s "$TEMP_DIR/gencode.zip" ]; then
    echo "  ✗ 下载文件为空或不存在"
    exit 1
fi

echo "  ✓ 下载完成"

echo ""
echo "[3/5] 解压代码..."
unzip -q "$TEMP_DIR/gencode.zip" -d "$TEMP_DIR/extracted" 2>&1 | grep -v "^warning:" || true
echo "  ✓ 解压完成"

echo ""
echo "[4/5] 替换包名并组织到临时目录..."

if [ "$GENERATE_ENTITY" = true ]; then
    SOURCE_DIR=$(find "$TEMP_DIR/extracted" -type d -name "entity" 2>/dev/null | head -1)
    if [ -n "$SOURCE_DIR" ] && [ -d "$SOURCE_DIR" ]; then
        PKG_DIR="$TEMP_DIR/staging/entity"
        mkdir -p "$PKG_DIR"

        find "$SOURCE_DIR" -name "*.java" | while read -r java_file; do
            filename=$(basename "$java_file")
            target_file="$PKG_DIR/$filename"

            sed -e "s#^package #package ${PROJECT_PACKAGE}.#" \
                "$java_file" > "$target_file"
        done

        echo "  ✓ entity 已替换包名"
    else
        echo "  ⚠ 未找到 entity 目录"
    fi
fi

if [ "$GENERATE_DTO" = true ]; then
    SOURCE_DIR=$(find "$TEMP_DIR/extracted" -type d -name "dto" 2>/dev/null | head -1)
    if [ -n "$SOURCE_DIR" ] && [ -d "$SOURCE_DIR" ]; then
        PKG_DIR="$TEMP_DIR/staging/dto"
        mkdir -p "$PKG_DIR"

        find "$SOURCE_DIR" -name "*.java" | while read -r java_file; do
            filename=$(basename "$java_file")
            target_file="$PKG_DIR/$filename"

            sed -e "s#^package #package ${PROJECT_PACKAGE}.#" \
                "$java_file" > "$target_file"
        done

        echo "  ✓ dto 已替换包名"
    else
        echo "  ⚠ 未找到 dto 目录"
    fi
fi

if [ "$GENERATE_CONTROLLER" = true ]; then
    CONTROLLER_SOURCE=$(find "$TEMP_DIR/extracted" -type d -name "controller" 2>/dev/null | head -1)
    if [ -n "$CONTROLLER_SOURCE" ] && [ -d "$CONTROLLER_SOURCE" ]; then
        STAGING_CTRL="$TEMP_DIR/staging/controller/admin"
        mkdir -p "$STAGING_CTRL"

        while IFS= read -r java_file; do
            rel_path="${java_file#$CONTROLLER_SOURCE/}"
            module_dir=$(dirname "$rel_path")
            target_dir="$STAGING_CTRL/$module_dir"
            mkdir -p "$target_dir"

            sed -e "s#^package #package ${PROJECT_PACKAGE}.#" \
                -e "s#import entity\.\*;#import ${PROJECT_PACKAGE}.entity.*;#" \
                -e "s#import dto\.\*;#import ${PROJECT_PACKAGE}.dto.*;#" \
                "$java_file" > "$target_dir/$(basename "$java_file")"
        done < <(find "$CONTROLLER_SOURCE" -name "*.java" -type f 2>/dev/null)

        echo "  ✓ controller 已按模块分包到 admin/"
    else
        echo "  ⚠ 未找到 controller 目录"
    fi
fi

echo ""
echo "[5/5] 移动文件到项目目录..."

if [ "$GENERATE_ENTITY" = true ]; then
    STAGING_DIR="$TEMP_DIR/staging/entity"
    if [ -d "$STAGING_DIR" ]; then
        TARGET_PKG_DIR="$SRC_JAVA_DIR/$PROJECT_PATH/entity"
        mkdir -p "$TARGET_PKG_DIR"

        find "$STAGING_DIR" -name "*.java" | while read -r java_file; do
            filename=$(basename "$java_file")
            cp "$java_file" "$TARGET_PKG_DIR/$filename"
        done

        echo "  ✓ entity → $PROJECT_PACKAGE.entity"
    fi
fi

if [ "$GENERATE_DTO" = true ]; then
    STAGING_DIR="$TEMP_DIR/staging/dto"
    if [ -d "$STAGING_DIR" ]; then
        TARGET_PKG_DIR="$SRC_JAVA_DIR/$PROJECT_PATH/dto"
        mkdir -p "$TARGET_PKG_DIR"

        find "$STAGING_DIR" -name "*.java" | while read -r java_file; do
            filename=$(basename "$java_file")
            cp "$java_file" "$TARGET_PKG_DIR/$filename"
        done

        echo "  ✓ dto → $PROJECT_PACKAGE.dto"
    fi
fi

if [ "$GENERATE_CONTROLLER" = true ]; then
    STAGING_CTRL="$TEMP_DIR/staging/controller"
    if [ -d "$STAGING_CTRL" ]; then
        TARGET_CTRL_DIR="$SRC_JAVA_DIR/$PROJECT_PATH/controller"
        mkdir -p "$TARGET_CTRL_DIR"

        while IFS= read -r java_file; do
            rel_path="${java_file#$STAGING_CTRL/}"
            target_file="$TARGET_CTRL_DIR/$rel_path"
            mkdir -p "$(dirname "$target_file")"
            cp "$java_file" "$target_file"
        done < <(find "$STAGING_CTRL" -name "*.java" -type f 2>/dev/null)

        echo "  ✓ controller → $PROJECT_PACKAGE.controller.admin.{module}/"
    fi
fi

echo ""
echo "[6/6] Maven编译验证..."
cd "$PROJECT_BACKEND_DIR"
if command -v mvn &> /dev/null; then
    mvn clean compile -q
    if [ $? -eq 0 ]; then
        echo "  ✓ Maven编译成功"
    else
        echo "  ⚠ Maven编译失败，请检查代码"
        exit 1
    fi
else
    echo "  ⚠ 未找到mvn命令，跳过编译验证"
fi

echo ""
echo "=== 代码生成完成 ==="
echo "代码位置: $SRC_JAVA_DIR/$PROJECT_PATH/"
echo "包名前缀: $PROJECT_PACKAGE"

find "$SRC_JAVA_DIR/$PROJECT_PATH" -name "*.java" 2>/dev/null | wc -l | xargs echo "文件总数:"
