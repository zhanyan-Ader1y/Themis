#!/usr/bin/env bash
#
# Themis 模板契约检查器。
#
# 用途：校验源模板或已安装 `.themis`、sibling `.claude/skills/Themis-Q` 的结构、YAML 元数据、Schema 兼容性和 Markdown import。
# 作用域：仅用于源仓库和安装支持；不写入模板、Skill、Workspace 或项目状态，也不执行项目命令。
# 兼容性：保持 Bash 3.2 兼容；使用 mikefarah/yq v4，且不加载仅供 Init 的 P0。
#

# 输出稳定、可操作的模板契约诊断。
themis_template_error() {
  printf '%s\n' \
    "Themis template contract failed: ${1-unknown}" \
    "  Expected: ${2-unspecified}" \
    "  Detected: ${3-unspecified}" \
    "  Fix: ${4-Repair the template and run this check again.}" >&2
  return 1
}

THEMIS_TEMPLATE_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
THEMIS_TEMPLATE_REPOSITORY_ROOT=$(CDPATH='' cd -- "${THEMIS_TEMPLATE_SCRIPT_DIR}/.." && pwd)
THEMIS_TEMPLATE_INSTALLED=0
if [ "${1-}" = '--installed' ]; then
  THEMIS_TEMPLATE_INSTALLED=1
  shift
fi
THEMIS_TEMPLATE_ROOT_INPUT=${1:-"${THEMIS_TEMPLATE_REPOSITORY_ROOT}/templates/.themis"}

if [ ! -d "${THEMIS_TEMPLATE_ROOT_INPUT}" ]; then
  themis_template_error \
    'template root missing' \
    'an existing .themis template directory' \
    "${THEMIS_TEMPLATE_ROOT_INPUT}" \
    'Pass an existing template root or restore templates/.themis.'
  exit 1
fi

THEMIS_TEMPLATE_ROOT=$(CDPATH='' cd -- "${THEMIS_TEMPLATE_ROOT_INPUT}" && pwd)
THEMIS_TEMPLATE_PARENT=$(CDPATH='' cd -- "${THEMIS_TEMPLATE_ROOT}/.." && pwd)
THEMIS_TEMPLATE_CORE_ROOT="${THEMIS_TEMPLATE_ROOT}/core"
THEMIS_TEMPLATE_WORKSPACE_ROOT="${THEMIS_TEMPLATE_ROOT}/workspace"
THEMIS_TEMPLATE_SKILL_ROOT="${THEMIS_TEMPLATE_PARENT}/.claude/skills/Themis-Q"
THEMIS_TEMPLATE_SKILL_FILE="${THEMIS_TEMPLATE_SKILL_ROOT}/SKILL.md"
THEMIS_TEMPLATE_SKILL_REFERENCE="${THEMIS_TEMPLATE_SKILL_ROOT}/references/adversarial-checklist.md"
THEMIS_TEMPLATE_YQ=${YQ:-yq}

if ! command -v "${THEMIS_TEMPLATE_YQ}" >/dev/null 2>&1; then
  themis_template_error \
    'yq unavailable' \
    'mikefarah/yq v4 on PATH or supplied through YQ' \
    'not found' \
    'Install mikefarah/yq v4 or set YQ to its executable path.'
  exit 1
fi

THEMIS_TEMPLATE_YQ_VERSION=$("${THEMIS_TEMPLATE_YQ}" --version 2>&1)
THEMIS_TEMPLATE_YQ_STATUS=$?
if [ "${THEMIS_TEMPLATE_YQ_STATUS}" -ne 0 ]; then
  themis_template_error \
    'yq version unreadable' \
    'a working mikefarah/yq v4 executable' \
    'version command failed' \
    'Install mikefarah/yq v4 or set YQ to its executable path.'
  exit 1
fi

case "${THEMIS_TEMPLATE_YQ_VERSION}" in
  *mikefarah/yq*version\ v4.*) ;;
  *)
    themis_template_error \
      'unsupported yq implementation' \
      'mikefarah/yq v4' \
      "${THEMIS_TEMPLATE_YQ_VERSION}" \
      'Install mikefarah/yq v4 or set YQ to its executable path.'
    exit 1
    ;;
esac

# 验证新安装契约要求的路径存在。
themis_template_require_path() {
  if [ ! -e "${1}" ]; then
    themis_template_error \
      'required path missing' \
      "${1#"${THEMIS_TEMPLATE_ROOT}/"}" \
      'not found' \
      'Restore the declared template directory or file.'
    return 1
  fi
  return 0
}

# 验证确定性执行器保留可执行权限。
themis_template_require_executable() {
  if [ ! -f "${1}" ] || [ ! -x "${1}" ]; then
    themis_template_error \
      'required executor is not executable' \
      "an executable ${1#"${THEMIS_TEMPLATE_ROOT}/"}" \
      'missing file or executable mode' \
      'Restore the executor and its executable permission.'
    return 1
  fi
  return 0
}

# 验证 Markdown 包含精确的稳定契约行。
themis_template_require_markdown_line() {
  local themis_template_markdown_path=$1
  local themis_template_markdown_expected=$2
  local themis_template_markdown_subject=$3

  if ! grep -F -x -- "${themis_template_markdown_expected}" "${themis_template_markdown_path}" >/dev/null 2>&1; then
    themis_template_error \
      "${themis_template_markdown_subject}" \
      "${themis_template_markdown_expected}" \
      'required line not found' \
      'Restore the P2 guidance structure and stable boundary statement.'
    return 1
  fi
  return 0
}

# 验证 Markdown 不包含被禁止的稳定文本，防止旧流程或危险能力重新进入 bundle。
themis_template_forbid_markdown_text() {
  local themis_template_markdown_path=$1
  local themis_template_markdown_forbidden=$2
  local themis_template_markdown_subject=$3

  if grep -F -- "${themis_template_markdown_forbidden}" "${themis_template_markdown_path}" >/dev/null 2>&1; then
    themis_template_error \
      "${themis_template_markdown_subject}" \
      "no ${themis_template_markdown_forbidden}" \
      'forbidden text found' \
      'Remove the retired or unsafe Skill contract text.'
    return 1
  fi
  return 0
}

# 限制常驻指引篇幅，防止按需流程进入基础 import 图。
themis_template_require_markdown_line_limit() {
  local themis_template_markdown_path=$1
  local themis_template_markdown_limit=$2
  local themis_template_markdown_subject=$3
  local themis_template_markdown_lines

  themis_template_markdown_lines=$(wc -l < "${themis_template_markdown_path}")
  themis_template_markdown_lines=${themis_template_markdown_lines//[[:space:]]/}
  if [ "${themis_template_markdown_lines}" -gt "${themis_template_markdown_limit}" ]; then
    themis_template_error \
      "${themis_template_markdown_subject}" \
      "at most ${themis_template_markdown_limit} lines" \
      "${themis_template_markdown_lines} lines" \
      'Move detailed workflow procedures to their owning later capability.'
    return 1
  fi
  return 0
}

# 只统计可执行的 @import 行，不把普通文本或示例计入。
themis_template_count_imports() {
  local themis_template_import_count_file=$1
  local themis_template_import_count=0
  local themis_template_import_count_line

  while IFS= read -r themis_template_import_count_line; do
    case "${themis_template_import_count_line}" in
      @import\ *) themis_template_import_count=$((themis_template_import_count + 1)) ;;
    esac
  done < "${themis_template_import_count_file}"
  printf '%s\n' "${themis_template_import_count}"
}

# 验证入口 import 数量，保持 P2 浅层、无重复的加载图。
themis_template_require_import_count() {
  local themis_template_import_file=$1
  local themis_template_import_expected=$2
  local themis_template_import_subject=$3
  local themis_template_import_actual

  themis_template_import_actual=$(themis_template_count_imports "${themis_template_import_file}")
  if [ "${themis_template_import_actual}" -ne "${themis_template_import_expected}" ]; then
    themis_template_error \
      "${themis_template_import_subject}" \
      "${themis_template_import_expected} import statements" \
      "${themis_template_import_actual} import statements" \
      'Restore the approved shallow P2 import graph.'
    return 1
  fi
  return 0
}

# 经由 yq 读取 YAML，并将解析失败转换为稳定诊断。
themis_template_yq_read() {
  local themis_template_yq_file=$1
  local themis_template_yq_expression=$2
  local themis_template_yq_value

  if ! themis_template_yq_value=$("${THEMIS_TEMPLATE_YQ}" eval -r "${themis_template_yq_expression}" "${themis_template_yq_file}" 2>/dev/null); then
    themis_template_error \
      'YAML unreadable' \
      "valid YAML in ${themis_template_yq_file#"${THEMIS_TEMPLATE_ROOT}/"}" \
      'yq could not evaluate the file' \
      'Correct the YAML syntax and required structure.'
    return 1
  fi
  printf '%s\n' "${themis_template_yq_value}"
}

# 校验必填标量与精确契约值一致。
themis_template_require_value() {
  local themis_template_value=$1
  local themis_template_expected=$2
  local themis_template_subject=$3

  if [ "${themis_template_value}" != "${themis_template_expected}" ]; then
    themis_template_error \
      "${themis_template_subject}" \
      "${themis_template_expected}" \
      "${themis_template_value:-empty}" \
      'Restore the declared template contract value.'
    return 1
  fi
  return 0
}

# 校验非空、带命名空间的 Schema 标识符，不要求版本后缀。
themis_template_require_schema_identifier() {
  local themis_template_schema_identifier=$1
  local themis_template_schema_prefix=$2
  local themis_template_schema_subject=$3

  case "${themis_template_schema_identifier}" in
    "${themis_template_schema_prefix}"*) return 0 ;;
    *)
      themis_template_error \
        "${themis_template_schema_subject}" \
        "expected prefix: ${themis_template_schema_prefix}" \
        "${themis_template_schema_identifier:-empty}" \
        'Use the correct namespace prefix for this schema.'
      return 1
      ;;
  esac
}

# 验证 YAML 集合或映射类型，区分空值和缺失字段。
themis_template_require_type() {
  local themis_template_type_file=$1
  local themis_template_type_expression=$2
  local themis_template_type_expected=$3
  local themis_template_type_subject=$4
  local themis_template_type_actual

  themis_template_type_actual=$(themis_template_yq_read "${themis_template_type_file}" "${themis_template_type_expression} | type") || return 1
  if [ "${themis_template_type_actual}" != "${themis_template_type_expected}" ]; then
    themis_template_error \
      "${themis_template_type_subject}" \
      "${themis_template_type_expected}" \
      "${themis_template_type_actual:-empty}" \
      'Restore the required YAML collection or mapping.'
    return 1
  fi
  return 0
}

# 校验 YAML 集合的固定数量，避免将声明式 Gate 悄然降级为不完整配置。
themis_template_require_count() {
  local themis_template_count=$1
  local themis_template_expected=$2
  local themis_template_subject=$3

  if [ "${themis_template_count}" != "${themis_template_expected}" ]; then
    themis_template_error \
      "${themis_template_subject}" \
      "${themis_template_expected} entries" \
      "${themis_template_count:-empty}" \
      'Restore every declared P5 policy entry.'
    return 1
  fi
  return 0
}

# 校验 YAML 集合包含指定稳定标识，防止结构正确但协议标识被替换。
themis_template_require_sequence_item() {
  local themis_template_sequence_file=$1
  local themis_template_sequence_expression=$2
  local themis_template_sequence_expected=$3
  local themis_template_sequence_subject=$4
  local themis_template_sequence_items
  local themis_template_sequence_item

  themis_template_sequence_items=$(themis_template_yq_read "${themis_template_sequence_file}" "${themis_template_sequence_expression}") || return 1
  while IFS= read -r themis_template_sequence_item; do
    if [ "${themis_template_sequence_item}" = "${themis_template_sequence_expected}" ]; then
      return 0
    fi
  done <<EOF
${themis_template_sequence_items}
EOF

  themis_template_error \
    "${themis_template_sequence_subject}" \
    "the stable value ${themis_template_sequence_expected}" \
    'required value not found' \
    'Restore the declared P5 policy identifier.'
  return 1
}

# 判断 Core allow-list 是否明确支持指定 Schema。
themis_template_schema_is_supported() {
  local themis_template_schema_file=$1
  local themis_template_schema_dimension=$2
  local themis_template_schema_value=$3
  local themis_template_schema_candidate

  while IFS= read -r themis_template_schema_candidate; do
    if [ "${themis_template_schema_candidate}" = "${themis_template_schema_value}" ]; then
      return 0
    fi
  done <<EOF
$(themis_template_yq_read "${themis_template_schema_file}" ".compatibility.${themis_template_schema_dimension}.supported[]?")
EOF
  return 1
}

# 根据 Core 的固定 allow-list 校验 manifest Schema；不提供隐式或显式转换路径。
themis_template_check_schema_compatibility() {
  local themis_template_compatibility_dimension=$1
  local themis_template_compatibility_schema=$2
  local themis_template_compatibility_label=$3

  if themis_template_schema_is_supported \
    "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" \
    "${themis_template_compatibility_dimension}" \
    "${themis_template_compatibility_schema}"; then
    return 0
  fi

  themis_template_error \
    "unsupported ${themis_template_compatibility_label} schema" \
    "a value in compatibility.${themis_template_compatibility_dimension}.supported" \
    "${themis_template_compatibility_schema}" \
    'Use a supported schema; this release has no schema conversion capability.'
  return 1
}

# 解析并验证 Core Markdown import；先移除 Windows CRLF 行尾，再确保规范化目标仍受限于 Core。
themis_template_check_import() {
  local themis_template_import_source=$1
  local themis_template_import_path=$2
  local themis_template_import_carriage_return
  local themis_template_import_target
  local themis_template_import_directory
  local themis_template_import_resolved

  themis_template_import_carriage_return=$(printf '\r')
  themis_template_import_path=${themis_template_import_path%"${themis_template_import_carriage_return}"}

  case "${themis_template_import_path}" in
    /*)
      themis_template_error \
        'unsafe import path' \
        'a relative import path' \
        "${themis_template_import_path}" \
        'Keep imports relative to their declared template location.'
      return 1
      ;;
  esac

  themis_template_import_target="$(dirname -- "${themis_template_import_source}")/${themis_template_import_path}"

  case "${themis_template_import_source}" in
    "${THEMIS_TEMPLATE_CORE_ROOT}"/*)
      themis_template_import_directory=$(CDPATH='' cd -- "$(dirname -- "${themis_template_import_target}")" 2>/dev/null && pwd)
      if [ -n "${themis_template_import_directory}" ]; then
        themis_template_import_resolved="${themis_template_import_directory}/$(basename -- "${themis_template_import_target}")"
        case "${themis_template_import_resolved}" in
          "${THEMIS_TEMPLATE_CORE_ROOT}"/*) ;;
          *)
            themis_template_error \
              'Core import escapes Core' \
              "a target beneath ${THEMIS_TEMPLATE_CORE_ROOT}" \
              "${themis_template_import_path}" \
              'Keep Core rule imports within core/.'
            return 1
            ;;
        esac
      fi
      ;;
  esac

  if [ ! -f "${themis_template_import_target}" ]; then
    themis_template_error \
      'import target missing' \
      "an existing file for ${themis_template_import_path}" \
      'not found' \
      'Create the target file or correct the import path.'
    return 1
  fi

  themis_template_import_directory=$(CDPATH='' cd -- "$(dirname -- "${themis_template_import_target}")" && pwd)
  themis_template_import_resolved="${themis_template_import_directory}/$(basename -- "${themis_template_import_target}")"

  case "${themis_template_import_source}" in
    "${THEMIS_TEMPLATE_CORE_ROOT}"/*)
      case "${themis_template_import_resolved}" in
        "${THEMIS_TEMPLATE_CORE_ROOT}"/*) ;;
        *)
          themis_template_error \
            'Core import escapes Core' \
            "a target beneath ${THEMIS_TEMPLATE_CORE_ROOT}" \
            "${themis_template_import_path}" \
            'Keep Core rule imports within core/.'
          return 1
          ;;
      esac
      ;;
  esac
  return 0
}

themis_template_require_path "${THEMIS_TEMPLATE_ROOT}/VERSION" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/manifest.yaml" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/policies/transitions.yaml" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/artifact/spec-schema.yaml" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/artifact/spec-projection.yaml" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/templates/spec.yaml" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/specification/themis-spec.sh" || exit 1
for themis_template_context_protocol in common-schema context-item-schema catalog-schema bundle-schema signal-schema; do
  themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/context/${themis_template_context_protocol}.yaml" || exit 1
done
for themis_template_context_prompt in context-resolution context-summary; do
  themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/templates/${themis_template_context_prompt}.md" || exit 1
done
for themis_template_context_executor in lint catalog search assemble freshness navigation; do
  themis_template_require_executable "${THEMIS_TEMPLATE_CORE_ROOT}/bin/themis-context-${themis_template_context_executor}.sh" || exit 1
done
themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/bin/_themis-context-common.sh" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_SKILL_FILE}" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_SKILL_REFERENCE}" || exit 1

for themis_template_workspace_directory in policies context specs state runs evidence outcomes knowledge cache; do
  themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/${themis_template_workspace_directory}/.gitkeep" || exit 1
done

themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/catalog.yaml" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/.abstract.md" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/.overview.md" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/state/context-signals/.gitkeep" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/state/locks/.gitkeep" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/state/transactions/context/.gitkeep" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/cache/context-index/.gitkeep" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/cache/resolved-context/.gitkeep" || exit 1

# Themis 模块不设功能版本；任何 themis-*/vN 模式一律拒绝。
THEMIS_TEMPLATE_VERSIONED_IDENTIFIERS=$(
  LC_ALL=C grep -R -h -E -o 'themis-[a-z0-9-]+/v[0-9]+' "${THEMIS_TEMPLATE_ROOT}" 2>/dev/null || true
)
while IFS= read -r themis_template_versioned_identifier; do
  [ -n "${themis_template_versioned_identifier}" ] || continue
  themis_template_error \
    'module version identifier forbidden' \
    'Themis modules do not carry functional version suffixes' \
    "${themis_template_versioned_identifier}" \
    'Remove the /vN suffix and keep one current contract.'
  exit 1
done <<EOF
${THEMIS_TEMPLATE_VERSIONED_IDENTIFIERS}
EOF

for themis_template_protocol_module in "${THEMIS_TEMPLATE_CORE_ROOT}"/protocols/*; do
  [ -d "${themis_template_protocol_module}" ] || continue
  [ "$(basename -- "${themis_template_protocol_module}")" = artifact ] && continue
  for themis_template_version_directory in "${themis_template_protocol_module}"/v[0-9]*; do
    [ -e "${themis_template_version_directory}" ] || continue
    themis_template_error \
      'module version directory forbidden' \
      'an unversioned module protocol directory' \
      "${themis_template_version_directory#"${THEMIS_TEMPLATE_ROOT}/"}" \
      'Move the current protocol files directly under their module directory.'
    exit 1
  done
done

for themis_template_kernel_module in orchestrator specification planning context verification review attribution knowledge; do
  themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/${themis_template_kernel_module}/rules.md" || exit 1
done

for themis_template_context_subdir in architecture domain engineering decisions pitfalls glossary external; do
  themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/${themis_template_context_subdir}/.gitkeep" || exit 1
  themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/${themis_template_context_subdir}/.overview.md" || exit 1
done

if [ -e "${THEMIS_TEMPLATE_CORE_ROOT}/migrations" ] || \
   [ -e "${THEMIS_TEMPLATE_CORE_ROOT}/policies/migration.yaml" ] || \
   [ -e "${THEMIS_TEMPLATE_CORE_ROOT}/templates/migration-execution.md" ] || \
   [ -e "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/migrations.md" ] || \
   [ -e "${THEMIS_TEMPLATE_CORE_ROOT}/adapters/schema/behavior-extractor" ] || \
   [ -e "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/architecture/behavior-map" ]; then
  themis_template_error \
    'retired capability asset present' \
    'no Upgrade, Migration, Behavior Extractor, or Behavior Map assets' \
    'retired template path found' \
    'Remove retired capability assets from the current template.'
  exit 1
fi

if [ -e "${THEMIS_TEMPLATE_CORE_ROOT}/migations" ] || \
   [ -e "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/konwledge" ]; then
  themis_template_error \
    'legacy template path present' \
    'no migations or konwledge path' \
    'legacy misspelling found' \
    'Remove the misspelled legacy template path.'
  exit 1
fi

if [ -e "${THEMIS_TEMPLATE_CORE_ROOT}/templates/spec.md" ]; then
  themis_template_error \
    'legacy Spec compatibility asset present' \
    'no legacy Spec Markdown template' \
    'obsolete Spec compatibility asset found' \
    'Remove the pre-release Spec template; the Artifact Spec is the native contract.'
  exit 1
fi

if [ -e "${THEMIS_TEMPLATE_CORE_ROOT}/templates/spec-questioning.md" ] || \
   [ -e "${THEMIS_TEMPLATE_CORE_ROOT}/templates/spec-adversarial-checklist.md" ]; then
  themis_template_error \
    'retired Specification questioning asset present' \
    'Themis-Q as the only Requirement Questioning workflow' \
    'legacy Core Prompt or checklist found' \
    'Remove the retired Core templates and keep the workflow in .claude/skills/Themis-Q/.'
  exit 1
fi

THEMIS_TEMPLATE_BUNDLE_VERSION=$(sed -n '1p' "${THEMIS_TEMPLATE_ROOT}/VERSION")
if [ -z "${THEMIS_TEMPLATE_BUNDLE_VERSION}" ] || [ "$(sed -n '2p' "${THEMIS_TEMPLATE_ROOT}/VERSION")" != "" ]; then
  themis_template_error \
    'bundle version invalid' \
    'one non-empty version line in VERSION' \
    'empty or multi-line value' \
    'Set VERSION to the current Core release version.'
  exit 1
fi

THEMIS_TEMPLATE_CORE_SCHEMA=$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" '.core_schema // ""') || exit 1
THEMIS_TEMPLATE_CORE_VERSION=$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" '.core_version // ""') || exit 1
THEMIS_TEMPLATE_WORKSPACE_SCHEMA=$(themis_template_yq_read "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/manifest.yaml" '.workspace_schema // ""') || exit 1
THEMIS_TEMPLATE_ARTIFACT_SCHEMA=$(themis_template_yq_read "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/manifest.yaml" '.artifact_schema // ""') || exit 1

themis_template_require_value "${THEMIS_TEMPLATE_CORE_SCHEMA}" 'themis-core' 'Core schema invalid' || exit 1
themis_template_require_value "${THEMIS_TEMPLATE_CORE_VERSION}" "${THEMIS_TEMPLATE_BUNDLE_VERSION}" 'Bundle/Core version mismatch' || exit 1
themis_template_require_schema_identifier "${THEMIS_TEMPLATE_WORKSPACE_SCHEMA}" 'themis-workspace' 'Workspace schema invalid' || exit 1
themis_template_require_value "${THEMIS_TEMPLATE_ARTIFACT_SCHEMA}" 'themis-artifact' 'Artifact schema invalid' || exit 1

for themis_template_dimension in workspace artifact; do
  themis_template_require_type "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" ".compatibility.${themis_template_dimension}.supported" '!!seq' "${themis_template_dimension} support list invalid" || exit 1
  themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" ".compatibility.${themis_template_dimension}.migrations // \"absent\"")" 'absent' "${themis_template_dimension} migration metadata present" || exit 1
done

themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" '.migration_roots // "absent"')" 'absent' 'Migration roots metadata present' || exit 1

themis_template_require_count "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" '.compatibility.artifact.supported | length')" 1 'Artifact support list invalid' || exit 1
themis_template_require_sequence_item "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" '.compatibility.artifact.supported[]?' 'themis-artifact' 'Artifact support missing' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" '.compatibility.artifact.writable // ""')" 'themis-artifact' 'Artifact writable schema invalid' || exit 1

themis_template_require_count "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" '.compatibility.workspace.supported | length')" 1 'Workspace support list invalid' || exit 1
themis_template_require_sequence_item "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" '.compatibility.workspace.supported[]?' 'themis-workspace' 'Workspace support missing' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" '.compatibility.workspace.writable // ""')" 'themis-workspace' 'Workspace writable schema invalid' || exit 1

for themis_template_manifest_map in project commands context adapters policy_overrides paths; do
  themis_template_require_type "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/manifest.yaml" ".${themis_template_manifest_map}" '!!map' "Manifest ${themis_template_manifest_map} invalid" || exit 1
done
for themis_template_manifest_list in '.context.entry_points' '.context.external_sources' '.gates'; do
  themis_template_require_type "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/manifest.yaml" "${themis_template_manifest_list}" '!!seq' "Manifest ${themis_template_manifest_list} invalid" || exit 1
done

if [ "${THEMIS_TEMPLATE_INSTALLED}" -eq 0 ]; then
  themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/manifest.yaml" '.project.name // ""')" '' 'Manifest project name invalid' || exit 1
fi
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/manifest.yaml" '.project.root // ""')" '.' 'Manifest project root invalid' || exit 1

for themis_template_path_name in policies context specs state runs evidence outcomes knowledge cache; do
  themis_template_require_value \
    "$(themis_template_yq_read "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/manifest.yaml" ".paths.${themis_template_path_name} // \"\"")" \
    "workspace/${themis_template_path_name}" \
    "Manifest path ${themis_template_path_name} invalid" || exit 1
done

themis_template_check_schema_compatibility workspace "${THEMIS_TEMPLATE_WORKSPACE_SCHEMA}" Workspace || exit 1
themis_template_check_schema_compatibility artifact "${THEMIS_TEMPLATE_ARTIFACT_SCHEMA}" Artifact || exit 1

# 验证 P5.4 Context Protocol、bootstrap Catalog、导航投影和按需 Prompt 合同。
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/context/common-schema.yaml" '.result_schema // ""')" 'themis-context-result' 'Context result protocol invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/context/context-item-schema.yaml" '.context_item_schema // ""')" 'themis-context-item' 'Context Item protocol invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/context/catalog-schema.yaml" '.catalog_schema // ""')" 'themis-context-catalog' 'Context Catalog protocol invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/context/bundle-schema.yaml" '.bundle_schema // ""')" 'themis-context-bundle' 'Context Bundle protocol invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/context/signal-schema.yaml" '.signal_schema // ""')" 'themis-context-signal' 'Context Signal protocol invalid' || exit 1
for themis_template_context_protocol in common-schema context-item-schema catalog-schema bundle-schema signal-schema; do
  "${THEMIS_TEMPLATE_YQ}" eval -e '.' "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/context/${themis_template_context_protocol}.yaml" >/dev/null 2>&1 || {
    themis_template_error 'Context Protocol unreadable' 'valid YAML' "protocols/context/${themis_template_context_protocol}.yaml" 'Correct the Context Protocol YAML.'
    exit 1
  }
done

themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/catalog.yaml" '.catalog_schema // ""')" 'themis-context-catalog' 'Bootstrap Context Catalog schema invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/catalog.yaml" '.binding // ""')" unbound 'Bootstrap Context Catalog binding invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/catalog.yaml" '.project.name // "null"')" null 'Bootstrap Context Catalog project invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/catalog.yaml" '.workspace_identity_digest // "null"')" null 'Bootstrap Workspace identity invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/catalog.yaml" '.revision.kind // ""')" unavailable 'Bootstrap Context revision invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/catalog.yaml" '.items | length')" 0 'Bootstrap Context Catalog items invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/catalog.yaml" '.catalog_digest // ""')" 'sha256:f6042b7d830e0aadfd689311f55051bc7dccdce3d2aaad24d384473fe72a6222' 'Bootstrap Context Catalog digest invalid' || exit 1

for themis_template_projection in \
  "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/.abstract.md" \
  "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/.overview.md" \
  "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/architecture/.overview.md" \
  "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/domain/.overview.md" \
  "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/engineering/.overview.md" \
  "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/decisions/.overview.md" \
  "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/pitfalls/.overview.md" \
  "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/glossary/.overview.md" \
  "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/external/.overview.md"; do
  themis_template_require_markdown_line "${themis_template_projection}" 'projection_schema: themis-context-navigation' 'Bootstrap Context projection schema missing' || exit 1
  themis_template_require_markdown_line "${themis_template_projection}" 'catalog_digest: sha256:f6042b7d830e0aadfd689311f55051bc7dccdce3d2aaad24d384473fe72a6222' 'Bootstrap Context projection Catalog digest invalid' || exit 1
  themis_template_require_markdown_line "${themis_template_projection}" 'source_items: []' 'Bootstrap Context projection sources invalid' || exit 1
  themis_template_require_markdown_line "${themis_template_projection}" 'generated_at: null' 'Bootstrap Context projection timestamp invalid' || exit 1
done

themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/templates/context-resolution.md" '## Fail-Closed Rules' 'Context resolution fail-closed contract missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/templates/context-summary.md" '## Boundaries' 'Context summary governance boundary missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/context/rules.md" '- Governed Context describes what the project should be; current code, configuration, and Schema describe what it currently is. Neither globally overrides the other.' 'Context dual-axis authority missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/context/rules.md" "- Before semantic selection, MUST Read \`core/templates/context-resolution.md\` and the Context Protocols, then use the installed deterministic Search and Assemble executors." 'Context resolution routing missing' || exit 1

# 验证 P5.2 策略、协议、模板与稳定 readiness IDs 对齐。
themis_template_require_type "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification' '!!map' 'Specification policy root invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.schema // ""')" 'themis-specification-policy' 'Specification policy schema invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.artifact.authoritative_source // ""')" 'spec.yaml' 'Specification authority invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.artifact.human_projection // ""')" 'spec.md' 'Specification projection invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.artifact.reverse_sync // ""')" forbidden 'Specification reverse sync invalid' || exit 1
themis_template_require_type "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.questioning.complexity' '!!map' 'Specification complexity policy invalid' || exit 1
themis_template_require_count "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.questioning.complexity.precedence | length')" 3 'Specification complexity precedence invalid' || exit 1
for themis_template_complexity_level in low medium high; do
  themis_template_require_sequence_item "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.questioning.complexity.precedence[]?' "${themis_template_complexity_level}" 'Specification complexity level missing' || exit 1
  themis_template_require_type "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" ".specification.questioning.flow.${themis_template_complexity_level}" '!!map' "Specification ${themis_template_complexity_level} flow invalid" || exit 1
done
themis_template_require_count "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.adversarial_validation.dimensions | length')" 6 'Specification adversarial dimensions invalid' || exit 1
themis_template_require_count "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.adversarial_validation.quick_checklist | length')" 5 'Specification quick checklist invalid' || exit 1
themis_template_require_count "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.adversarial_validation.dispositions | length')" 3 'Specification adversarial dispositions invalid' || exit 1
themis_template_require_count "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.semantic_consistency.placeholder_patterns | length')" 4 'Specification placeholder policy invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.semantic_consistency.require_summary_intent_match // false')" true 'Specification summary consistency invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.semantic_consistency.require_scope_summary_match // false')" true 'Specification scope consistency invalid' || exit 1
for themis_template_dimension in boundary_conditions concurrency_and_race state_transitions security_and_permissions dependency_failures data_integrity; do
  themis_template_require_sequence_item "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.adversarial_validation.dimensions[]?' "${themis_template_dimension}" 'Specification adversarial dimension missing' || exit 1
done
for themis_template_quick_check in empty_input failure_state concurrency backward_compatibility rollback; do
  themis_template_require_sequence_item "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.adversarial_validation.quick_checklist[]?' "${themis_template_quick_check}" 'Specification quick-check item missing' || exit 1
done

themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/artifact/spec-schema.yaml" '.schema // ""')" 'themis-spec-schema' 'Spec schema protocol invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/artifact/spec-schema.yaml" '.artifact_schema // ""')" 'themis-artifact' 'Spec Artifact schema invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/artifact/spec-projection.yaml" '.schema // ""')" 'themis-spec-projection' 'Spec projection protocol invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/artifact/spec-projection.yaml" '.drift.reverse_sync // ""')" forbidden 'Spec projection reverse sync invalid' || exit 1
themis_template_require_count "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/artifact/spec-schema.yaml" '.readiness_checks | length')" 8 'Spec readiness check count invalid' || exit 1
themis_template_require_count "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/artifact/spec-projection.yaml" '.sections | length')" 8 'Spec projection section count invalid' || exit 1

themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/templates/spec.yaml" '.status // ""')" draft 'Spec template status invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/templates/spec.yaml" '.context_basis.disposition // ""')" pending 'Spec template Context disposition invalid' || exit 1
for themis_template_retired_spec_field in spec_schema template_version questioning; do
  if THEMIS_TEMPLATE_SPEC_FIELD=${themis_template_retired_spec_field} yq eval -e 'has(strenv(THEMIS_TEMPLATE_SPEC_FIELD))' "${THEMIS_TEMPLATE_CORE_ROOT}/templates/spec.yaml" >/dev/null 2>&1; then
    themis_template_error 'retired Spec field present' "${themis_template_retired_spec_field} absent" "${THEMIS_TEMPLATE_CORE_ROOT}/templates/spec.yaml" 'Remove Spec version and questioning process state.'
    exit 1
  fi
done

themis_template_require_type "${THEMIS_TEMPLATE_CORE_ROOT}/policies/transitions.yaml" '.transitions' '!!map' 'Transition policy root invalid' || exit 1
themis_template_require_type "${THEMIS_TEMPLATE_CORE_ROOT}/policies/transitions.yaml" '.transitions.draft_to_specified' '!!map' 'Draft-to-specified transition missing' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/transitions.yaml" '.transitions.draft_to_specified.from // ""')" draft 'Draft transition source invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/transitions.yaml" '.transitions.draft_to_specified.to // ""')" specified 'Specified transition target invalid' || exit 1
themis_template_require_count "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/policies/transitions.yaml" '.transitions.draft_to_specified.conditions | length')" 8 'Draft-to-specified condition count invalid' || exit 1
for themis_template_transition_condition in spec_intent_complete spec_scope_complexity_confirmed spec_context_complete spec_design_acceptance_complete spec_adversarial_resolved spec_self_check_passed spec_user_approval_recorded spec_projection_current; do
  themis_template_require_sequence_item "${THEMIS_TEMPLATE_CORE_ROOT}/protocols/artifact/spec-schema.yaml" '.readiness_checks[]?' "${themis_template_transition_condition}" 'Spec readiness check missing' || exit 1
  themis_template_require_sequence_item "${THEMIS_TEMPLATE_CORE_ROOT}/policies/specification.yaml" '.specification.readiness.specified[]?' "${themis_template_transition_condition}" 'Specification readiness policy missing check' || exit 1
  themis_template_require_sequence_item "${THEMIS_TEMPLATE_CORE_ROOT}/policies/transitions.yaml" '.transitions.draft_to_specified.conditions[].id' "${themis_template_transition_condition}" 'Draft-to-specified condition missing' || exit 1
done

themis_template_require_markdown_line "${THEMIS_TEMPLATE_SKILL_FILE}" 'name: Themis-Q' 'Themis-Q name missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_SKILL_FILE}" 'user-invocable: true' 'Themis-Q user invocation missing' || exit 1
for themis_template_skill_heading in '## Questioning style' '## Questioning coverage' '### Intent' '### Scope' '### Context and assumptions' '### Options and trade-offs' '### Requirements and acceptance' '### Risks and edge cases' '## Convergence'; do
  themis_template_require_markdown_line "${THEMIS_TEMPLATE_SKILL_FILE}" "${themis_template_skill_heading}" 'Themis-Q questioning coverage missing' || exit 1
done
themis_template_require_markdown_line "${THEMIS_TEMPLATE_SKILL_FILE}" '- Ask one focused question at a time.' 'Themis-Q focused questioning rule missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_SKILL_FILE}" '- Present no more than three acceptance criteria at a time for review.' 'Themis-Q acceptance review rule missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_SKILL_FILE}" 'Read [references/adversarial-checklist.md](references/adversarial-checklist.md) when the change warrants adversarial questioning.' 'Themis-Q adversarial reference missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_SKILL_FILE}" 'Ask the user to correct anything inaccurate or incomplete. Return the clarified requirement in the surrounding conversation'"'"'s requested format; this Skill does not define lifecycle steps, artifact creation, persistence, or a handoff schema.' 'Themis-Q convergence guidance missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_SKILL_REFERENCE}" '## Quick checks' 'Themis-Q quick checklist missing' || exit 1
for themis_template_attack_heading in '## Boundary conditions' '## Concurrency and race conditions' '## State transitions' '## Security and permissions' '## Dependency failures' '## Data integrity'; do
  themis_template_require_markdown_line "${THEMIS_TEMPLATE_SKILL_REFERENCE}" "${themis_template_attack_heading}" 'Themis-Q attack dimension missing' || exit 1
done

themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/specification/rules.md" "Before creating or modifying a Spec candidate, invoke the \`Themis-Q\` Skill with the Skill tool unless it has already clarified the current request in this conversation." 'Specification Themis-Q invocation missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/specification/rules.md" "- \`Themis-Q\` supplies questioning methods and coverage only. It does not own lifecycle routing, persistence, confirmation gates, candidate creation, or a handoff format." 'Specification Themis-Q boundary missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/specification/rules.md" '- If the Skill is missing or invocation fails, remain in Specification and report the blocker. Do not read a legacy questioning Prompt or create a candidate as fallback.' 'Specification Themis-Q fail-closed rule missing' || exit 1
themis_template_forbid_markdown_text "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/specification/rules.md" 'core/templates/spec-questioning.md' 'Specification legacy questioning fallback present' || exit 1

themis_template_require_path "${THEMIS_TEMPLATE_ROOT}/CLAUDE.themis.md" || exit 1
if [ "${THEMIS_TEMPLATE_INSTALLED}" -eq 0 ] && [ -e "${THEMIS_TEMPLATE_PARENT}/CLAUDE.themis.md" ]; then
  themis_template_error \
    'obsolete root guidance present' \
    'no CLAUDE.themis.md beside .themis' \
    "${THEMIS_TEMPLATE_PARENT}/CLAUDE.themis.md" \
    'Keep Themis guidance inside .themis/.'
  exit 1
fi

themis_template_require_markdown_line_limit "${THEMIS_TEMPLATE_ROOT}/CLAUDE.themis.md" 120 'top-level guidance too large' || exit 1
themis_template_require_markdown_line_limit "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/orchestrator/rules.md" 220 'Orchestrator guidance too large' || exit 1
themis_template_require_import_count "${THEMIS_TEMPLATE_ROOT}/CLAUDE.themis.md" 0 'contained guidance import count invalid' || exit 1
themis_template_require_import_count "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/orchestrator/rules.md" 7 'Orchestrator import count invalid' || exit 1

themis_template_require_markdown_line "${THEMIS_TEMPLATE_ROOT}/CLAUDE.themis.md" '# Themis Project Guidance' 'top-level guidance heading missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_ROOT}/CLAUDE.themis.md" '## Installation Boundary' 'installation boundary missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_ROOT}/CLAUDE.themis.md" '## Source of Truth' 'source-of-truth guidance missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_ROOT}/CLAUDE.themis.md" '## Lifecycle Routing' 'lifecycle routing missing' || exit 1

themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/orchestrator/rules.md" '## Managed Change Detection' 'managed-change routing missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/orchestrator/rules.md" '## Artifact-First Routing' 'artifact-first routing missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/orchestrator/rules.md" '## Safe Degradation' 'safe-degradation routing missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/orchestrator/rules.md" '## Non-Bypass Rules' 'non-bypass guidance missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/specification/rules.md" '## Requirement Questioning' 'Specification questioning routing missing' || exit 1

for themis_template_domain_rule in specification planning context verification review attribution knowledge; do
  themis_template_require_markdown_line_limit "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/${themis_template_domain_rule}/rules.md" 50 "${themis_template_domain_rule} guidance too large" || exit 1
  themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/${themis_template_domain_rule}/rules.md" '## Responsibility' "${themis_template_domain_rule} responsibility missing" || exit 1
  themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/${themis_template_domain_rule}/rules.md" '## Inputs' "${themis_template_domain_rule} inputs missing" || exit 1
  themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/${themis_template_domain_rule}/rules.md" '## Outputs' "${themis_template_domain_rule} outputs missing" || exit 1
  themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/${themis_template_domain_rule}/rules.md" '## Boundaries' "${themis_template_domain_rule} boundaries missing" || exit 1
done

# shellcheck disable=SC2094
for themis_template_markdown_file in \
  "${THEMIS_TEMPLATE_ROOT}/CLAUDE.themis.md" \
  "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/orchestrator/rules.md"; do
  while IFS= read -r themis_template_import_line; do
    case "${themis_template_import_line}" in
      @import\ *)
        themis_template_import_path=${themis_template_import_line#@import }
        themis_template_import_path=${themis_template_import_path%$'\r'}
        themis_template_check_import "${themis_template_markdown_file}" "${themis_template_import_path}" || exit 1
        ;;
    esac
  done < "${themis_template_markdown_file}"
done

exit 0
