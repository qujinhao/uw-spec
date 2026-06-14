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

if [ -z "$PROJECT_NAME" ]; then
    echo "ERROR: 项目信息文件中未找到 project-name"
    exit 1
fi

TEMPLATE_ZIP="${SKILL_DIR}/assets/uw-app-template.zip"

# 定义替换参数
PROJECT_NAME_LOWER=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')
PACKAGE_NAME=$(echo "$PROJECT_NAME" | tr '-' '.')
PACKAGE_PATH=$(echo "$PROJECT_NAME" | tr '-' '/')
# 驼峰命名: my-shop → MyShop
PROJECT_NAME_CAMEL=$(echo "$PROJECT_NAME" | awk -F'-' '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1' OFS='')
OUTPUT_DIR="${TARGET_DIR}/backend/${PROJECT_NAME}-app"

if [ ! -f "$TEMPLATE_ZIP" ]; then
    echo "ERROR: 模板文件不存在: $TEMPLATE_ZIP"
    exit 1
fi

# 忽略文件列表
IGNORE_FILES=".DS_Store"

echo "=== 初始化Java后端项目 ==="
echo "项目名: ${PROJECT_NAME}"
echo "项目标签: ${PROJECT_LABEL}"
echo "项目描述: ${PROJECT_DESC}"
echo "驼峰命名: ${PROJECT_NAME_CAMEL}"
echo "包名: ${PACKAGE_NAME}"
echo "包路径: ${PACKAGE_PATH}"
echo "输出到: ${OUTPUT_DIR}"
echo ""

# 检查目标目录是否存在
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
echo "[1/6] 解压模板到临时目录..."
TEMP_DIR=$(mktemp -d)
unzip -q "$TEMPLATE_ZIP" -d "$TEMP_DIR"
WORK_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "*uw-app-template*" | head -1)
if [ -z "$WORK_DIR" ]; then
    WORK_DIR="$TEMP_DIR"
fi
echo "  完成: ${WORK_DIR}"

echo "[2/6] 重构包目录结构..."
for SRC_DIR in "src/main/java" "src/test/java"; do
    if [ -d "$WORK_DIR/$SRC_DIR/uw/app" ]; then
        NEW_PKG_DIR="$WORK_DIR/$SRC_DIR/$PACKAGE_PATH"
        mkdir -p "$NEW_PKG_DIR"
        find "$WORK_DIR/$SRC_DIR/uw/app" -type f | while read -r file; do
            rel_path="${file#$WORK_DIR/$SRC_DIR/uw/app/}"
            target_file="$NEW_PKG_DIR/$rel_path"
            target_dir=$(dirname "$target_file")
            mkdir -p "$target_dir"
            mv "$file" "$target_file" 2>/dev/null || true
        done
        rm -rf "$WORK_DIR/$SRC_DIR/uw"
        echo "  已重构 $SRC_DIR"
    fi
done
echo "  完成"

echo "[3/6] 替换目录名和文件名..."
find "$WORK_DIR" -depth -name "*UwApp*" | while read -r item; do
    new_name=$(echo "$item" | sed "s/UwApp/${PROJECT_NAME_CAMEL}/g")
    mv "$item" "$new_name" 2>/dev/null || true
done
echo "  完成"

echo "[4/6] 替换文件内容..."
find "$WORK_DIR" -type f \( \
    -name "*.java" -o -name "*.xml" -o -name "*.yml" -o -name "*.yaml" \
    -o -name "*.properties" -o -name "*.md" -o -name "*.sql" -o -name "*.json" \
    -o -name "*.txt" -o -name "*.gradle" -o -name "*.kt" \
\) | while read -r file; do
    sed -i '' \
        -e "s/uw\.app/${PACKAGE_NAME}/g" \
        -e "s/uw-app-name/${PROJECT_NAME_LOWER}/g" \
        -e "s/uw-app-label/${PROJECT_LABEL}/g" \
        -e "s/uw-app-desc/${PROJECT_DESC}/g" \
        -e "s/UwApp/${PROJECT_NAME_CAMEL}/g" \
        "$file" 2>/dev/null || true
done
echo "  基础替换完成"

RESOURCES_DIR="${WORK_DIR}/src/main/resources"
CONFIG_FILE="${HOME}/.uniweb/uniweb-system.config"

if [ -d "$RESOURCES_DIR" ] && [ -f "$CONFIG_FILE" ]; then
    echo "  处理 resources 目录系统配置替换..."

    find "$RESOURCES_DIR" -type f | while read -r res_file; do
        sed -i '' \
            -e "s|#{PROJECT_NAME}|${PROJECT_NAME}|g" \
            -e "s|#{PROJECT_LABEL}|${PROJECT_LABEL}|g" \
            "$res_file"

        while IFS='=' read -r key value; do
            [[ "$key" =~ ^[[:space:]]*# || -z "$key" ]] && continue
            [[ "$key" == "PROJECT_NAME" || "$key" == "PROJECT_LABEL" ]] && continue
            sed -i '' "s|#{${key}}|${value}|g" "$res_file"
        done < "$CONFIG_FILE"
    done

    echo "  resources 目录配置替换完成"
elif [ -d "$RESOURCES_DIR" ]; then
    echo "  ⚠ 未找到系统配置文件: ${CONFIG_FILE}，跳过 resources 配置替换"
else
    echo "  未找到 resources 目录，跳过系统配置替换"
fi

echo "[5/6] 验证..."
ERRORS=0

# 检查 uw.app 残留
CONTENT_RESIDUAL=$(grep -rl "uw\.app" "$WORK_DIR" \
    --include="*.java" --include="*.xml" --include="*.yml" --include="*.yaml" \
    --include="*.properties" --include="*.json" --include="*.sql" \
    --include="*.md" --include="*.gradle" --include="*.kt" \
    2>/dev/null | head -5) || true
if [ -n "$CONTENT_RESIDUAL" ]; then
    echo "  ⚠ 文件内容仍有 uw.app 残留:"
    echo "$CONTENT_RESIDUAL"
    ERRORS=$((ERRORS + 1))
fi

# 检查 uw-app-name 残留
CONTENT_RESIDUAL=$(grep -rl "uw-app-name" "$WORK_DIR" \
    --include="*.java" --include="*.xml" --include="*.yml" --include="*.yaml" \
    --include="*.properties" --include="*.json" --include="*.sql" \
    --include="*.md" --include="*.gradle" --include="*.kt" \
    2>/dev/null | head -5) || true
if [ -n "$CONTENT_RESIDUAL" ]; then
    echo "  ⚠ 文件内容仍有 uw-app-name 残留:"
    echo "$CONTENT_RESIDUAL"
    ERRORS=$((ERRORS + 1))
fi

# 检查 UwApp 残留
CONTENT_RESIDUAL=$(grep -rl "UwApp" "$WORK_DIR" \
    --include="*.java" --include="*.xml" --include="*.yml" --include="*.yaml" \
    --include="*.properties" --include="*.json" --include="*.sql" \
    --include="*.md" --include="*.gradle" --include="*.kt" \
    2>/dev/null | head -5) || true
if [ -n "$CONTENT_RESIDUAL" ]; then
    echo "  ⚠ 文件内容仍有 UwApp 残留:"
    echo "$CONTENT_RESIDUAL"
    ERRORS=$((ERRORS + 1))
fi

# 检查 resources 目录占位符残留
if [ -d "$RESOURCES_DIR" ]; then
    RESIDUAL_PLACEHOLDERS=$(grep -ro '#{[A-Z_][A-Z0-9_]*}' "$RESOURCES_DIR" | sort -u | head -5) || true
    if [ -n "$RESIDUAL_PLACEHOLDERS" ]; then
        echo "  ⚠ resources 目录仍有未替换的占位符:"
        echo "$RESIDUAL_PLACEHOLDERS"
        ERRORS=$((ERRORS + 1))
    fi
fi

# 检查 uw/app 目录是否还存在
if [ -d "$WORK_DIR/src/main/java/uw/app" ] || [ -d "$WORK_DIR/src/test/java/uw/app" ]; then
    echo "  ⚠ uw/app 目录仍然存在"
    ERRORS=$((ERRORS + 1))
fi

APP_FILE=$(find "$WORK_DIR" -name "*Application.java" 2>/dev/null | head -1)
if [ -n "$APP_FILE" ]; then
    echo "  ✓ 入口类: $(basename "$APP_FILE")"
else
    echo "  ⚠ 未找到Application入口类"
    ERRORS=$((ERRORS + 1))
fi

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "ERROR: 验证失败，发现 ${ERRORS} 个问题"
    echo "临时目录: ${WORK_DIR}"
    echo "请检查问题后手动处理，或删除临时目录重试"
    exit 1
fi
echo "  完成"

echo "[6/6] 复制到目标目录..."
if [ -d "$OUTPUT_DIR" ]; then
    echo "  目标目录已存在，按模式处理..."
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
    echo "  创建新目录: ${OUTPUT_DIR}"
    mkdir -p "$(dirname "$OUTPUT_DIR")"
    find "$WORK_DIR" -type f ! -name "$IGNORE_FILES" | while read -r source_file; do
        rel_path="${source_file#$WORK_DIR/}"
        target_file="$OUTPUT_DIR/$rel_path"
        target_dir=$(dirname "$target_file")
        mkdir -p "$target_dir"
        cp "$source_file" "$target_file"
    done
fi

# 清理临时目录
rm -rf "$TEMP_DIR"
echo "  完成"

echo ""
echo "=== 初始化完成 ==="
echo "项目目录: ${OUTPUT_DIR}"
echo "项目标签: ${PROJECT_LABEL}"
echo "项目描述: ${PROJECT_DESC}"
echo "驼峰命名: ${PROJECT_NAME_CAMEL}"
echo "包名: ${PACKAGE_NAME}"
echo "包路径: ${PACKAGE_PATH}"
echo ""
echo "Git 初始化和 Maven 编译验证..."
cd "$OUTPUT_DIR"

# Maven 编译
if command -v mvn &> /dev/null; then
    mvn clean compile -q
    if [ $? -eq 0 ]; then
        echo "  ✓ Maven 编译成功"
    else
        echo "  ⚠ Maven 编译失败，请检查依赖配置"
    fi
else
    echo "  ⚠ 未找到 mvn 命令，跳过编译验证"
fi

echo ""
echo "=== 全部完成 ==="
