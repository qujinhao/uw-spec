#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

IGNORE_FILES=".DS_Store"

TARGET_DIR="${1:-$(pwd)}"
SWAGGER_URL_PARAM="${2:-}"
GENERATE_TYPES="${3:-api,router,page,i18n}"
FRONTEND_PROJECT_NAME_PARAM="${4:-}"

# Swagger URL 格式验证
if [ -n "$SWAGGER_URL_PARAM" ] && ! echo "$SWAGGER_URL_PARAM" | grep -qE "^https?://"; then
    echo "ERROR: Swagger地址格式不正确，必须以 http:// 或 https:// 开头"
    echo "当前值: $SWAGGER_URL_PARAM"
    exit 1
fi

INFO_FILE="${TARGET_DIR}/project-info.md"
SERVER_CONFIG="${HOME}/.uniweb/uniweb-system.config"

if [ ! -f "$INFO_FILE" ]; then
    echo "ERROR: 未找到项目信息文件: $INFO_FILE"
    echo "用法: $0 [目标目录] [Swagger地址] [生成类型] [前端项目名]"
    echo "  目标目录      项目根目录（包含 project-info.md），默认为当前目录"
    echo "  Swagger地址   Swagger API 文档地址（必填）"
    echo "  生成类型      api,router,page,i18n 的组合，默认 api,router,page,i18n"
    echo "  前端项目名    可选，指定具体的前端项目目录名（如 my-shop-admin-web）"
    echo ""
    echo "示例:"
    echo "  $0 /Users/user/project 'http://192.168.88.21/my-shop-app/v3/api-docs/adminApi'"
    echo "  $0 /Users/user/project 'http://192.168.88.21/my-shop-app/v3/api-docs/adminApi' 'api,router'"
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

AUTH_URL="http://${PROJECT_SERVER}/uw-auth-center/auth/login"
GENCODE_URL="http://${PROJECT_SERVER}/uw-code-center/ops/codegen/swaggerGenCode/downloadCodeForVue3"

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

FRONTEND_DIR="$TARGET_DIR/frontend"

# 如果通过参数指定了前端项目名，直接使用
if [ -n "$FRONTEND_PROJECT_NAME_PARAM" ]; then
    PROJECT_FRONTEND_DIR="$FRONTEND_DIR/$FRONTEND_PROJECT_NAME_PARAM"
    if [ ! -d "$PROJECT_FRONTEND_DIR" ]; then
        echo "ERROR: 指定的前端项目目录不存在: $PROJECT_FRONTEND_DIR"
        exit 1
    fi
    FRONTEND_PROJECT_NAME="$FRONTEND_PROJECT_NAME_PARAM"
    echo "  使用指定的前端项目: $FRONTEND_PROJECT_NAME"
else
    # 查找所有匹配的前端项目目录
    AVAILABLE_FRONTEND_DIRS=$(find "$FRONTEND_DIR" -maxdepth 1 -type d -name "${PROJECT_NAME}-*-web" 2>/dev/null | sort)

    if [ -z "$AVAILABLE_FRONTEND_DIRS" ]; then
        echo "ERROR: 未找到前端项目目录: $FRONTEND_DIR/${PROJECT_NAME}-{role}-web"
        echo "请确保已执行 230-web-vue-init 初始化前端项目"
        exit 1
    fi

    # 统计可用目录数量
    FRONTEND_DIR_COUNT=$(echo "$AVAILABLE_FRONTEND_DIRS" | wc -l | tr -d ' ')

    if [ "$FRONTEND_DIR_COUNT" -eq 1 ]; then
        # 只有一个目录，直接使用
        PROJECT_FRONTEND_DIR="$AVAILABLE_FRONTEND_DIRS"
        FRONTEND_PROJECT_NAME=$(basename "$PROJECT_FRONTEND_DIR")
        echo "  找到前端项目: $FRONTEND_PROJECT_NAME"
    else
        # 多个目录，列出供用户选择
        echo "  发现多个前端项目:"
        echo "$AVAILABLE_FRONTEND_DIRS" | nl -w2 -s'. ' | while read -r line; do
            echo "     $line"
        done
        echo ""
        echo "ERROR: 存在多个前端项目，请通过命令行参数指定目标项目"
        echo "用法: bash scripts/gencode.sh [目标目录] [Swagger地址] [生成类型] [前端项目名]"
        echo "示例: bash scripts/gencode.sh /Users/user/project '' 'api,page' my-shop-admin-web"
        exit 1
    fi
fi

SRC_DIR="$PROJECT_FRONTEND_DIR/src"
if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: 未找到 $SRC_DIR 目录"
    exit 1
fi

GENERATE_API=false
GENERATE_ROUTER=false
GENERATE_PAGE=false
GENERATE_I18N=false

if [[ "$GENERATE_TYPES" == *"api"* ]]; then
    GENERATE_API=true
fi
if [[ "$GENERATE_TYPES" == *"router"* ]]; then
    GENERATE_ROUTER=true
fi
if [[ "$GENERATE_TYPES" == *"page"* ]]; then
    GENERATE_PAGE=true
fi
if [[ "$GENERATE_TYPES" == *"i18n"* ]]; then
    GENERATE_I18N=true
fi

echo "=== Web前端代码生成 ==="
echo "项目目录: $TARGET_DIR"
echo "项目名: $PROJECT_NAME"
echo "服务器: $PROJECT_SERVER"
echo "生成类型: $GENERATE_TYPES"
echo ""

echo "[1/6] 登录获取token..."
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
echo "[2/6] 下载前端代码生成文件..."

# Swagger URL 必填检查
if [ -z "$SWAGGER_URL_PARAM" ]; then
    echo "ERROR: Swagger URL 必须提供"
    echo "用法: bash scripts/gencode.sh [目标目录] [Swagger地址] [生成类型] [前端项目名]"
    echo "示例: bash scripts/gencode.sh /Users/user/project 'http://192.168.88.21/my-shop-app/v3/api-docs/adminApi'"
    exit 1
fi

SWAGGER_URL="$SWAGGER_URL_PARAM"
# URL 编码 swaggerUrl 参数值
SWAGGER_URL_ENCODED=$(printf '%s' "$SWAGGER_URL" | jq -sRr @uri 2>/dev/null || echo "$SWAGGER_URL" | sed 's/:/%3A/g; s/\//%2F/g; s/?/%3F/g; s/&/%26/g; s/=/%3D/g; s/ /%20/g')

DOWNLOAD_URL="${GENCODE_URL}?templateGroupId=3&swaggerUrl=${SWAGGER_URL_ENCODED}"

echo "  Swagger URL: $SWAGGER_URL"

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
echo "[3/6] 解压代码..."
unzip -q "$TEMP_DIR/gencode.zip" -d "$TEMP_DIR/extracted" 2>&1 | grep -v "^warning:" || true
echo "  ✓ 解压完成"

echo ""
echo "[4/6] 处理生成文件..."

if [ "$GENERATE_API" = true ]; then
    SOURCE_DIR=$(find "$TEMP_DIR/extracted" -type d -name "api" 2>/dev/null | head -1)
    if [ -n "$SOURCE_DIR" ] && [ -d "$SOURCE_DIR" ]; then
        STAGING_DIR="$TEMP_DIR/staging/api"
        mkdir -p "$STAGING_DIR"

        while IFS= read -r ts_file; do
            rel_path="${ts_file#$SOURCE_DIR/}"
            target_dir="$STAGING_DIR/$(dirname "$rel_path")"
            mkdir -p "$target_dir"
            cp "$ts_file" "$target_dir/$(basename "$ts_file")"
        done < <(find "$SOURCE_DIR" -name "*.ts" -type f 2>/dev/null)

        echo "  ✓ api 已处理"
    else
        echo "  ⚠ 未找到 api 目录"
    fi
fi

if [ "$GENERATE_ROUTER" = true ]; then
    SOURCE_DIR=$(find "$TEMP_DIR/extracted" -type d -name "router" 2>/dev/null | head -1)
    if [ -n "$SOURCE_DIR" ] && [ -d "$SOURCE_DIR" ]; then
        STAGING_DIR="$TEMP_DIR/staging/router"
        mkdir -p "$STAGING_DIR"

        while IFS= read -r ts_file; do
            rel_path="${ts_file#$SOURCE_DIR/}"
            target_dir="$STAGING_DIR/$(dirname "$rel_path")"
            mkdir -p "$target_dir"
            cp "$ts_file" "$target_dir/$(basename "$ts_file")"
        done < <(find "$SOURCE_DIR" -name "*.ts" -type f 2>/dev/null)

        echo "  ✓ router 已处理"
    else
        echo "  ⚠ 未找到 router 目录"
    fi
fi

if [ "$GENERATE_PAGE" = true ]; then
    SOURCE_DIR=$(find "$TEMP_DIR/extracted" -type d -name "pages" 2>/dev/null | head -1)
    if [ -n "$SOURCE_DIR" ] && [ -d "$SOURCE_DIR" ]; then
        STAGING_DIR="$TEMP_DIR/staging/pages"
        mkdir -p "$STAGING_DIR"

        while IFS= read -r ts_file; do
            rel_path="${ts_file#$SOURCE_DIR/}"
            target_dir="$STAGING_DIR/$(dirname "$rel_path")"
            mkdir -p "$target_dir"
            cp "$ts_file" "$target_dir/$(basename "$ts_file")"
        done < <(find "$SOURCE_DIR" \( -name "*.ts" -o -name "*.vue" \) -type f 2>/dev/null)

        echo "  ✓ page 已处理"
    else
        echo "  ⚠ 未找到 page 目录"
    fi
fi

if [ "$GENERATE_I18N" = true ]; then
    SOURCE_DIR=$(find "$TEMP_DIR/extracted" -type d -name "i18n" 2>/dev/null | head -1)
    if [ -n "$SOURCE_DIR" ] && [ -d "$SOURCE_DIR" ]; then
        STAGING_DIR="$TEMP_DIR/staging/i18n"
        mkdir -p "$STAGING_DIR"

        while IFS= read -r json_file; do
            rel_path="${json_file#$SOURCE_DIR/}"
            target_dir="$STAGING_DIR/$(dirname "$rel_path")"
            mkdir -p "$target_dir"
            cp "$json_file" "$target_dir/$(basename "$json_file")"
        done < <(find "$SOURCE_DIR" -name "*.json" -type f 2>/dev/null)

        echo "  ✓ i18n 已处理"
    else
        echo "  ⚠ 未找到 i18n 目录"
    fi
fi

echo ""
echo "[5/6] 移动文件到项目目录..."

if [ "$GENERATE_API" = true ]; then
    STAGING_DIR="$TEMP_DIR/staging/api"
    if [ -d "$STAGING_DIR" ]; then
        TARGET_API_DIR="$SRC_DIR/api"
        mkdir -p "$TARGET_API_DIR"

        while IFS= read -r ts_file; do
            rel_path="${ts_file#$STAGING_DIR/}"
            target_file="$TARGET_API_DIR/$rel_path"
            mkdir -p "$(dirname "$target_file")"
            cp "$ts_file" "$target_file"
        done < <(find "$STAGING_DIR" -name "*.ts" -type f 2>/dev/null)

        echo "  ✓ api → src/api/"
    fi
fi

if [ "$GENERATE_ROUTER" = true ]; then
    STAGING_DIR="$TEMP_DIR/staging/router"
    if [ -d "$STAGING_DIR" ]; then
        TARGET_ROUTER_DIR="$SRC_DIR/router"
        mkdir -p "$TARGET_ROUTER_DIR"

        while IFS= read -r ts_file; do
            rel_path="${ts_file#$STAGING_DIR/}"
            target_file="$TARGET_ROUTER_DIR/$rel_path"
            mkdir -p "$(dirname "$target_file")"
            cp "$ts_file" "$target_file"
        done < <(find "$STAGING_DIR" -name "*.ts" -type f 2>/dev/null)

        echo "  ✓ router → src/router/"
    fi
fi

if [ "$GENERATE_PAGE" = true ]; then
    STAGING_DIR="$TEMP_DIR/staging/pages"
    if [ -d "$STAGING_DIR" ]; then
        TARGET_PAGE_DIR="$SRC_DIR/pages"
        mkdir -p "$TARGET_PAGE_DIR"

        while IFS= read -r file; do
            rel_path="${file#$STAGING_DIR/}"
            target_file="$TARGET_PAGE_DIR/$rel_path"
            mkdir -p "$(dirname "$target_file")"
            cp "$file" "$target_file"
        done < <(find "$STAGING_DIR" \( -name "*.ts" -o -name "*.vue" \) -type f 2>/dev/null)

        echo "  ✓ page → src/pages/"
    fi
fi

if [ "$GENERATE_I18N" = true ]; then
    STAGING_DIR="$TEMP_DIR/staging/i18n"
    if [ -d "$STAGING_DIR" ]; then
        TARGET_I18N_DIR="$SRC_DIR/i18n"
        mkdir -p "$TARGET_I18N_DIR"

        while IFS= read -r json_file; do
            rel_path="${json_file#$STAGING_DIR/}"
            target_file="$TARGET_I18N_DIR/$rel_path"
            mkdir -p "$(dirname "$target_file")"
            cp "$json_file" "$target_file"
        done < <(find "$STAGING_DIR" -name "*.json" -type f 2>/dev/null)

        echo "  ✓ i18n → src/i18n/"
    fi
fi

echo ""
echo "[6/6] TypeScript编译验证..."
cd "$PROJECT_FRONTEND_DIR"
if [ -f "tsconfig.json" ]; then
    if command -v pnpm &> /dev/null; then
        pnpm vue-tsc --noEmit 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "  ✓ TypeScript编译成功"
        else
            echo "  ⚠ TypeScript编译有警告，请检查类型定义"
        fi
    else
        echo "  ⚠ 未找到 pnpm 命令，跳过编译验证"
    fi
else
    echo "  ⚠ 未找到 tsconfig.json，跳过编译验证"
fi

echo ""
echo "=== Web前端代码生成完成 ==="
echo "代码位置: $SRC_DIR/"
echo ""

find "$SRC_DIR/api" "$SRC_DIR/types" -name "*.ts" 2>/dev/null | wc -l | xargs echo "文件总数:"
