#!/usr/bin/env bash
#
# Themis 模板契约检查器。
#
# 用途：校验源模板或已安装 `.themis` 的结构、YAML 元数据、Schema 兼容性和 Markdown import。
# 作用域：仅用于源仓库和安装支持；不写入模板、Workspace 或项目状态，也不执行项目命令。
# 兼容性：保持 Bash 3.2 兼容；使用 mikefarah/yq v4，且不加载仅供 Init 的 P0。
#

# è¾åºç¨³å®ãå¯æä½çæ¨¡æ¿å¥çº¦è¯æ­ã
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

# éªè¯æ°å®è£å¥çº¦è¦æ±çè·¯å¾å­å¨ã
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

# éªè¯ Markdown åå«ç²¾ç¡®çç¨³å®å¥çº¦è¡ã
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

# éå¶å¸¸é©»æå¼ç¯å¹ï¼é²æ­¢æéæµç¨è¿å¥åºç¡ import å¾ã
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

# åªç»è®¡å¯æ§è¡ç  è¡ï¼ä¸ææ®éææ¬æç¤ºä¾è®¡å¥ã
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

# éªè¯å¥å£ import æ°éï¼ä¿æ P2 æµå±ãæ éå¤çå è½½å¾ã
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

# ç»ç± yq è¯»å YAMLï¼å¹¶å°è§£æå¤±è´¥è½¬æ¢ä¸ºç¨³å®è¯æ­ã
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

# æ ¡éªå¿å¡«æ éä¸ç²¾ç¡®å¥çº¦å¼ä¸è´ã
themis_template_require_value() {
  local themis_template_value=$1
  local themis_template_expected=$2
  local themis_template_subject=$3

  if [ "${themis_template_value}" != "${themis_template_expected}" ]; then
    themis_template_error \
      "${themis_template_subject}" \
      "${themis_template_expected}" \
      "${themis_template_value:-empty}" \
      'Restore the declared v1 template contract value.'
    return 1
  fi
  return 0
}

# æ ¡éªéç©ºãå¸¦å½åç©ºé´ç Schema æ è¯ç¬¦ã
themis_template_require_schema_identifier() {
  local themis_template_schema_identifier=$1
  local themis_template_schema_prefix=$2
  local themis_template_schema_subject=$3

  case "${themis_template_schema_identifier}" in
    "${themis_template_schema_prefix}"v[0-9]*) return 0 ;;
    *)
      themis_template_error \
        "${themis_template_schema_subject}" \
        "${themis_template_schema_prefix}v<number>" \
        "${themis_template_schema_identifier:-empty}" \
        'Use a namespaced schema identifier before declaring compatibility.'
      return 1
      ;;
  esac
}

# éªè¯ YAML éåææ å°ç±»åï¼åºåç©ºå¼åç¼ºå¤±å­æ®µã
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

# å¤æ­ Core allow-list æ¯å¦æç¡®æ¯ææå® Schemaã
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

# æ ¡éªæªæ¥è¿ç§»æè¿°ç¬¦ï¼æ£æ¥å¨åªè¯å«è¿ç§»ï¼ç»ä¸æ§è¡è¿ç§»ã
themis_template_schema_has_migration() {
  local themis_template_migration_file=$1
  local themis_template_migration_dimension=$2
  local themis_template_migration_schema=$3
  local themis_template_migration_root=$4
  local themis_template_migration_count
  local themis_template_migration_index=0
  local themis_template_migration_from
  local themis_template_migration_to
  local themis_template_migration_script

  themis_template_migration_count=$(themis_template_yq_read "${themis_template_migration_file}" ".compatibility.${themis_template_migration_dimension}.migrations | length") || return 1
  case "${themis_template_migration_count}" in
    *[!0-9]*|'')
      themis_template_error \
        'migration list invalid' \
        "a list for compatibility.${themis_template_migration_dimension}.migrations" \
        "${themis_template_migration_count:-empty}" \
        'Use a YAML list of explicit migration descriptors.'
      return 1
      ;;
  esac

  while [ "${themis_template_migration_index}" -lt "${themis_template_migration_count}" ]; do
    themis_template_migration_from=$(themis_template_yq_read "${themis_template_migration_file}" ".compatibility.${themis_template_migration_dimension}.migrations[${themis_template_migration_index}].from_schema // \"\"") || return 1
    themis_template_migration_to=$(themis_template_yq_read "${themis_template_migration_file}" ".compatibility.${themis_template_migration_dimension}.migrations[${themis_template_migration_index}].to_schema // \"\"") || return 1
    themis_template_migration_script=$(themis_template_yq_read "${themis_template_migration_file}" ".compatibility.${themis_template_migration_dimension}.migrations[${themis_template_migration_index}].script // \"\"") || return 1

    if [ -z "${themis_template_migration_from}" ] || [ -z "${themis_template_migration_to}" ] || [ -z "${themis_template_migration_script}" ]; then
      themis_template_error \
        'migration descriptor invalid' \
        'from_schema, to_schema, and script' \
        "descriptor ${themis_template_migration_index} is incomplete" \
        'Declare a complete explicit migration descriptor.'
      return 1
    fi

    case "${themis_template_migration_script}" in
      "${themis_template_migration_root}"/*) ;;
      *)
        themis_template_error \
          'migration script path invalid' \
          "a path beneath ${themis_template_migration_root}" \
          "${themis_template_migration_script}" \
          'Keep each migration script in its matching migration root.'
        return 1
        ;;
    esac

    case "${themis_template_migration_script}" in
      *'..'*)
        themis_template_error \
          'migration script path unsafe' \
          "a relative path beneath ${themis_template_migration_root}" \
          "${themis_template_migration_script}" \
          'Use a relative script path without parent-directory traversal.'
        return 1
        ;;
    esac

    if [ ! -f "${THEMIS_TEMPLATE_CORE_ROOT}/${themis_template_migration_script}" ]; then
      themis_template_error \
        'migration script missing' \
        "${themis_template_migration_script}" \
        'not found' \
        'Add the declared migration script beneath core/migrations.'
      return 1
    fi

    if [ "${themis_template_migration_from}" = "${themis_template_migration_schema}" ]; then
      return 0
    fi
    themis_template_migration_index=$((themis_template_migration_index + 1))
  done
  return 1
}

# æ ¹æ®ç¬ç«ç Core å¼å®¹æ§åè¡¨å½ç±» manifest Schemaã
themis_template_check_schema_compatibility() {
  local themis_template_compatibility_dimension=$1
  local themis_template_compatibility_schema=$2
  local themis_template_compatibility_label=$3
  local themis_template_compatibility_root=$4

  if themis_template_schema_is_supported \
    "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" \
    "${themis_template_compatibility_dimension}" \
    "${themis_template_compatibility_schema}"; then
    return 0
  fi

  if themis_template_schema_has_migration \
    "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" \
    "${themis_template_compatibility_dimension}" \
    "${themis_template_compatibility_schema}" \
    "${themis_template_compatibility_root}"; then
    themis_template_error \
      "${themis_template_compatibility_label} schema requires explicit migration" \
      "a supported ${themis_template_compatibility_label} schema" \
      "${themis_template_compatibility_schema}" \
      'Run the appropriate future Upgrade migration; this checker never migrates data.'
    return 1
  fi

  themis_template_error \
    "unsupported ${themis_template_compatibility_label} schema" \
    "a value in compatibility.${themis_template_compatibility_dimension}.supported" \
    "${themis_template_compatibility_schema}" \
    'Declare supported compatibility or an explicit migration descriptor.'
  return 1
}

# è§£æå¹¶éªè¯ Core Markdown importï¼ç¡®ä¿å¶è§èååä»åéäº Coreã
themis_template_check_import() {
  local themis_template_import_source=$1
  local themis_template_import_path=$2
  local themis_template_import_target
  local themis_template_import_directory
  local themis_template_import_resolved

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
themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/migrations/workspace/.gitkeep" || exit 1
themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/migrations/artifacts/.gitkeep" || exit 1

for themis_template_workspace_directory in policies context specs state runs evidence outcomes knowledge cache; do
  themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/${themis_template_workspace_directory}/.gitkeep" || exit 1
done

for themis_template_kernel_module in orchestrator specification planning context verification review attribution knowledge; do
  themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/${themis_template_kernel_module}/rules.md" || exit 1
done

themis_template_require_path "${THEMIS_TEMPLATE_CORE_ROOT}/adapters/schema/behavior-extractor/.gitkeep" || exit 1

for themis_template_context_subdir in architecture/behavior-map architecture domain engineering decisions pitfalls glossary external; do
  themis_template_require_path "${THEMIS_TEMPLATE_WORKSPACE_ROOT}/context/${themis_template_context_subdir}/.gitkeep" || exit 1
done

if [ -e "${THEMIS_TEMPLATE_CORE_ROOT}/migations" ] || [ -e "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/konwledge" ]; then
  themis_template_error \
    'legacy template path present' \
    'no migations or konwledge path' \
    'legacy misspelling found' \
    'Rename the source-template path to migrations or knowledge.'
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

themis_template_require_value "${THEMIS_TEMPLATE_CORE_SCHEMA}" 'themis-core/v1' 'Core schema invalid' || exit 1
themis_template_require_value "${THEMIS_TEMPLATE_CORE_VERSION}" "${THEMIS_TEMPLATE_BUNDLE_VERSION}" 'Bundle/Core version mismatch' || exit 1
themis_template_require_schema_identifier "${THEMIS_TEMPLATE_WORKSPACE_SCHEMA}" 'themis-workspace/' 'Workspace schema invalid' || exit 1
themis_template_require_schema_identifier "${THEMIS_TEMPLATE_ARTIFACT_SCHEMA}" 'themis-artifact/' 'Artifact schema invalid' || exit 1

for themis_template_dimension in workspace artifact; do
  themis_template_require_type "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" ".compatibility.${themis_template_dimension}.supported" '!!seq' "${themis_template_dimension} support list invalid" || exit 1
  themis_template_require_type "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" ".compatibility.${themis_template_dimension}.migrations" '!!seq' "${themis_template_dimension} migration list invalid" || exit 1
done

themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" '.migration_roots.workspace // ""')" 'migrations/workspace' 'Workspace migration root invalid' || exit 1
themis_template_require_value "$(themis_template_yq_read "${THEMIS_TEMPLATE_CORE_ROOT}/core.yaml" '.migration_roots.artifacts // ""')" 'migrations/artifacts' 'Artifact migration root invalid' || exit 1

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

themis_template_check_schema_compatibility workspace "${THEMIS_TEMPLATE_WORKSPACE_SCHEMA}" Workspace migrations/workspace || exit 1
themis_template_check_schema_compatibility artifact "${THEMIS_TEMPLATE_ARTIFACT_SCHEMA}" Artifact migrations/artifacts || exit 1

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
themis_template_require_import_count "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/orchestrator/rules.md" 6 'Orchestrator import count invalid' || exit 1

themis_template_require_markdown_line "${THEMIS_TEMPLATE_ROOT}/CLAUDE.themis.md" '# Themis Project Guidance' 'top-level guidance heading missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_ROOT}/CLAUDE.themis.md" '## Installation Boundary' 'installation boundary missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_ROOT}/CLAUDE.themis.md" '## Source of Truth' 'source-of-truth guidance missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_ROOT}/CLAUDE.themis.md" '## Lifecycle Routing' 'lifecycle routing missing' || exit 1

themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/orchestrator/rules.md" '## Managed Change Detection' 'managed-change routing missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/orchestrator/rules.md" '## Artifact-First Routing' 'artifact-first routing missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/orchestrator/rules.md" '## Safe Degradation' 'safe-degradation routing missing' || exit 1
themis_template_require_markdown_line "${THEMIS_TEMPLATE_CORE_ROOT}/kernel/orchestrator/rules.md" '## Non-Bypass Rules' 'non-bypass guidance missing' || exit 1

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
        themis_template_check_import "${themis_template_markdown_file}" "${themis_template_import_path}" || exit 1
        ;;
    esac
  done < "${themis_template_markdown_file}"
done

exit 0
