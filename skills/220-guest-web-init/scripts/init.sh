#!/bin/bash
set -euo pipefail

TARGET_DIR="${1:-}"
OVERWRITE_MODE="${2:-}"

INFO_FILE="${TARGET_DIR}/project-info.md"

if [ -z "$TARGET_DIR" ]; then
    echo "ERROR: 参数不完整"
    echo "用法: $0 [目标目录] [模式] [角色]"
    echo "  目标目录 - 项目根目录（包含 project-info.md）"
    echo "  模式 - force(强制覆盖), skip(跳过已存在文件)"
    echo "  角色 - guest/mch/saas/admin/root (默认: guest)"
    exit 1
fi

if [ ! -f "$INFO_FILE" ]; then
    echo "ERROR: 未找到项目信息文件: $INFO_FILE"
    exit 1
fi

PROJECT_NAME=$(grep -E "^project-name:" "$INFO_FILE" | head -1 | sed 's/project-name:[[:space:]]*//' | tr -d '"' | tr -d "'")
PROJECT_LABEL=$(grep -E "^project-label:" "$INFO_FILE" | head -1 | sed 's/project-label:[[:space:]]*//' | tr -d '"' | tr -d "'")
PROJECT_DESC=$(grep -E "^project-desc:" "$INFO_FILE" | head -1 | sed 's/project-desc:[[:space:]]*//' | tr -d '"' | tr -d "'")

if [ -z "$PROJECT_NAME" ]; then
    echo "ERROR: 项目信息文件中未找到 project-name"
    exit 1
fi

FRONTEND_ROLE="${3:-guest}"
FRONTEND_PROJECT_NAME="${PROJECT_NAME}-${FRONTEND_ROLE}-web"
OUTPUT_DIR="${TARGET_DIR}/frontend/${FRONTEND_PROJECT_NAME}"

echo "=== 初始化Web前端项目 ==="
echo "项目名: ${PROJECT_NAME}"
echo "前端项目名: ${FRONTEND_PROJECT_NAME}"
echo "角色: ${FRONTEND_ROLE}"
echo "项目标签: ${PROJECT_LABEL}"
echo "输出到: ${OUTPUT_DIR}"
echo ""

SKIP_ALL=false
OVERWRITE_ALL=false

case "$OVERWRITE_MODE" in
    force)
        OVERWRITE_ALL=true
        echo "模式: 强制覆盖所有文件"
        ;;
    skip)
        SKIP_ALL=true
        echo "模式: 跳过所有已存在文件"
        ;;
    *)
        if [ -d "$OUTPUT_DIR" ]; then
            echo "ERROR: 目标目录已存在: $OUTPUT_DIR"
            echo "如需覆盖，请使用: $0 [目标目录] force"
            echo "如需跳过已存在文件，请使用: $0 [目标目录] skip"
            exit 1
        fi
        ;;
esac

echo ""
echo "[1/4] 通过Nuxt脚手架初始化项目..."

if [ "$SKIP_ALL" = true ] && [ -d "$OUTPUT_DIR" ]; then
    echo "  跳过: 目标目录已存在"
else
    mkdir -p "$(dirname "$OUTPUT_DIR")"
    npx nuxi@latest init "$OUTPUT_DIR" --packageManager npm --no-gitInit
    echo "  完成: Nuxt项目已创建"
fi

echo "[2/4] 配置项目信息..."
PROJECT_NAME_LOWER=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')

if [ -f "$OUTPUT_DIR/package.json" ]; then
    sed -i '' \
        -e "s/\"name\": \"[^\"]*\"/\"name\": \"${FRONTEND_PROJECT_NAME}\"/" \
        -e "s/\"description\": \"[^\"]*\"/\"description\": \"${PROJECT_DESC}\"/" \
        "$OUTPUT_DIR/package.json"
    echo "  完成: package.json已更新"
else
    echo "  ⚠ 未找到package.json，跳过配置"
fi

echo "[3/4] 安装依赖..."
cd "$OUTPUT_DIR"

# monorepo中husky应在根目录统一管理，子项目跳过prepare钩子
export HUSKY=0

# 优先使用pnpm，回退到npm
if command -v pnpm &> /dev/null; then
    pnpm install 2>&1 | tail -1
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "  ✓ pnpm install 成功"
    else
        echo "  ⚠ pnpm install 失败，请手动执行"
    fi
elif command -v npm &> /dev/null; then
    npm install --silent 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "  ✓ npm install 成功"
    else
        echo "  ⚠ npm install 失败，请手动执行"
    fi
else
    echo "  ⚠ 未找到 npm/pnpm 命令，跳过依赖安装"
fi

echo "[4/4] 验证项目结构..."
ERRORS=0

if [ ! -f "$OUTPUT_DIR/package.json" ]; then
    echo "  ✗ 缺少 package.json"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$OUTPUT_DIR/nuxt.config.ts" ]; then
    echo "  ✗ 缺少 nuxt.config.ts"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f "$OUTPUT_DIR/tsconfig.json" ]; then
    echo "  ✗ 缺少 tsconfig.json"
    ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "ERROR: 验证失败，发现 ${ERRORS} 个问题"
    exit 1
fi
echo "  ✓ 项目结构验证通过"

echo ""
echo "=== 初始化完成 ==="
echo "项目目录: ${OUTPUT_DIR}"
echo "项目标签: ${PROJECT_LABEL}"
echo ""
echo "=== 全部完成 ==="
