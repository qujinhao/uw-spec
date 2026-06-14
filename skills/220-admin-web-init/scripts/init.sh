#!/bin/bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

TARGET_DIR="${1:-}"
OVERWRITE_MODE="${2:-}"

INFO_FILE="${TARGET_DIR}/project-info.md"

if [ -z "$TARGET_DIR" ]; then
    echo "ERROR: 参数不完整"
    echo "用法: $0 [目标目录] [模式]"
    echo "  目标目录 - 项目根目录（包含 project-info.md）"
    echo "  模式 - force(强制覆盖), skip(跳过已存在文件)"
    exit 1
fi

if [ ! -f "$INFO_FILE" ]; then
    echo "ERROR: 未找到项目信息文件: $INFO_FILE"
    exit 1
fi

PROJECT_NAME=$(grep -E "^project-name:" "$INFO_FILE" | head -1 | sed 's/project-name:[[:space:]]*//' | tr -d '"' | tr -d "'")
PROJECT_LABEL=$(grep -E "^project-label:" "$INFO_FILE" | head -1 | sed 's/project-label:[[:space:]]*//' | tr -d '"' | tr -d "'")
PROJECT_DESC=$(grep -E "^project-desc:" "$INFO_FILE" | head -1 | sed 's/project-desc:[[:space:]]*//' | tr -d '"' | tr -d "'")
PROJECT_MODE=$(grep -E "^project-mode:" "$INFO_FILE" | head -1 | sed 's/project-mode:[[:space:]]*//' | tr -d '"' | tr -d "'")

if [ -z "$PROJECT_NAME" ]; then
    echo "ERROR: 项目信息文件中未找到 project-name"
    exit 1
fi

TEMPLATE_TYPE="${PROJECT_MODE:-uniweb}"

case "$TEMPLATE_TYPE" in
    saas)
        TEMPLATE_ZIP="${SKILL_DIR}/assets/saas-admin-web-template.zip"
        ;;
    uniweb)
        TEMPLATE_ZIP="${SKILL_DIR}/assets/uw-admin-web-template.zip"
        ;;
    *)
        echo "ERROR: 未知项目模式: $TEMPLATE_TYPE (支持: saas, uniweb)"
        exit 1
        ;;
esac

PROJECT_NAME_LOWER=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')
PROJECT_NAME_CAMEL=$(echo "$PROJECT_NAME" | awk -F'[-_]' '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1' OFS='')

# 前端项目名格式: {project-name}-{role}-web
# 角色从命令行参数获取，默认为 admin
FRONTEND_ROLE="${3:-admin}"
FRONTEND_PROJECT_NAME="${PROJECT_NAME}-${FRONTEND_ROLE}-web"
OUTPUT_DIR="${TARGET_DIR}/frontend/${FRONTEND_PROJECT_NAME}"

if [ ! -f "$TEMPLATE_ZIP" ]; then
    echo "ERROR: 模板文件不存在: $TEMPLATE_ZIP"
    exit 1
fi

IGNORE_FILES=".DS_Store"

echo "=== 初始化Web前端项目 ==="
echo "项目名: ${PROJECT_NAME}"
echo "前端项目名: ${FRONTEND_PROJECT_NAME}"
echo "角色: ${FRONTEND_ROLE}"
echo "项目标签: ${PROJECT_LABEL}"
echo "模板类型: ${TEMPLATE_TYPE}"
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
echo "[1/5] 解压模板到临时目录..."
TEMP_DIR=$(mktemp -d)
unzip -q "$TEMPLATE_ZIP" -d "$TEMP_DIR"
WORK_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d ! -path "$TEMP_DIR" | head -1)
if [ -z "$WORK_DIR" ]; then
    WORK_DIR="$TEMP_DIR"
fi
echo "  完成: ${WORK_DIR}"

echo "[2/5] 替换文件内容..."
find "$WORK_DIR" -type f \( \
    -name "*.ts" -o -name "*.vue" -o -name "*.js" -o -name "*.json" \
    -o -name "*.html" -o -name "*.css" -o -name "*.scss" -o -name "*.md" \
    -o -name "*.env*" -o -name "*.yml" -o -name "*.yaml" \
\) | while read -r file; do
    sed -i '' \
        -e "s/uw-app-name/${PROJECT_NAME_LOWER}/g" \
        -e "s/UwApp/${PROJECT_NAME_CAMEL}/g" \
        -e "s/uw-app-label/${PROJECT_LABEL}/g" \
        -e "s/uw-app-desc/${PROJECT_DESC}/g" \
        "$file" 2>/dev/null || true
done
echo "  完成"

echo "[3/5] 验证..."
ERRORS=0

CONTENT_RESIDUAL=$(grep -rl "uw-app-name" "$WORK_DIR" \
    --include="*.ts" --include="*.vue" --include="*.js" --include="*.json" \
    --include="*.html" --include="*.md" --include="*.env*" \
    2>/dev/null | head -5) || true
if [ -n "$CONTENT_RESIDUAL" ]; then
    echo "  ⚠ 文件内容仍有 uw-app-name 残留:"
    echo "$CONTENT_RESIDUAL"
    ERRORS=$((ERRORS + 1))
fi

CONTENT_RESIDUAL=$(grep -rl "UwApp" "$WORK_DIR" \
    --include="*.ts" --include="*.vue" --include="*.js" --include="*.json" \
    --include="*.html" --include="*.md" \
    2>/dev/null | head -5) || true
if [ -n "$CONTENT_RESIDUAL" ]; then
    echo "  ⚠ 文件内容仍有 UwApp 残留:"
    echo "$CONTENT_RESIDUAL"
    ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "ERROR: 验证失败，发现 ${ERRORS} 个问题"
    echo "临时目录: ${WORK_DIR}"
    exit 1
fi
echo "  完成"

echo "[4/5] 复制到目标目录..."
if [ -d "$OUTPUT_DIR" ]; then
    find "$WORK_DIR" -type f ! -name "$IGNORE_FILES" | while read -r source_file; do
        rel_path="${source_file#$WORK_DIR/}"
        target_file="$OUTPUT_DIR/$rel_path"

        if [ -f "$target_file" ]; then
            if [ "$SKIP_ALL" = true ]; then
                echo "    跳过: $rel_path"
                continue
            fi
            if [ "$OVERWRITE_ALL" = true ]; then
                echo "    覆盖: $rel_path"
                cp "$source_file" "$target_file"
                continue
            fi
        else
            target_dir=$(dirname "$target_file")
            mkdir -p "$target_dir"
            cp "$source_file" "$target_file"
        fi
    done
else
    mkdir -p "$(dirname "$OUTPUT_DIR")"
    find "$WORK_DIR" -type f ! -name "$IGNORE_FILES" | while read -r source_file; do
        rel_path="${source_file#$WORK_DIR/}"
        target_file="$OUTPUT_DIR/$rel_path"
        target_dir=$(dirname "$target_file")
        mkdir -p "$target_dir"
        cp "$source_file" "$target_file"
    done
fi

rm -rf "$TEMP_DIR"
echo "  完成"

echo "[5/5] 安装依赖和验证..."
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

echo ""
echo "=== 初始化完成 ==="
echo "项目目录: ${OUTPUT_DIR}"
echo "项目标签: ${PROJECT_LABEL}"
echo "模板类型: ${TEMPLATE_TYPE}"
echo ""
echo "=== 全部完成 ==="
