#!/usr/bin/env bash
#
# Themis Spec 确定性执行器。
# 用途：校验 Agent 权威源、生成 Human 投影，并事务式发布 Spec 配对工件。
# 边界：不进行语义总结，不反向同步 Markdown，不记录生命周期迁移或并发锁。
# 兼容性：保持 Bash 3.2 兼容；要求 mikefarah/yq v4，投影操作额外要求 Git。
#
set -uo pipefail

THEMIS_SPEC_ACTION=
THEMIS_SPEC_SOURCE=
THEMIS_SPEC_PROJECTION=
THEMIS_SPEC_OUTPUT=
THEMIS_SPEC_CANDIDATE=
THEMIS_SPEC_TARGET=
THEMIS_SPEC_REQUIRE_READINESS=0
THEMIS_SPEC_TEMP_ROOT=
THEMIS_SPEC_ERROR_FILE=
THEMIS_SPEC_VALID=1
THEMIS_SPEC_READY=0
THEMIS_SPEC_PROJECTION_CURRENT=0
THEMIS_SPEC_PUBLISH_ACTIVE=0
THEMIS_SPEC_PUBLISH_TARGET=
THEMIS_SPEC_PUBLISH_BACKUP=
THEMIS_SPEC_PUBLISH_STAGE=
THEMIS_SPEC_PUBLISH_HAD_SOURCE=0
THEMIS_SPEC_PUBLISH_HAD_PROJECTION=0
THEMIS_SPEC_PUBLISH_REPLACEMENT_STARTED=0
THEMIS_SPEC_READINESS_FIELDS_CACHE_SOURCE=
THEMIS_SPEC_READINESS_FIELDS_CACHE_SET=0
THEMIS_SPEC_READINESS_FIELDS_CACHE_COMPLETE=0

# 输出稳定帮助，不依赖安装位置。
themis_spec_usage() {
  cat <<'EOF'
Usage:
  themis-spec.sh validate --source <spec.yaml> [--projection <spec.md>] [--readiness]
  themis-spec.sh render --source <spec.yaml> --output <spec.md>
  themis-spec.sh publish --candidate <spec.yaml> --target <spec-directory>

Commands:
  validate  Validate Spec structure, references, readiness, and optional projection drift.
  render    Deterministically rebuild the Human projection from spec.yaml.
  publish   Validate, render, pair-check, and transactionally publish both artifacts.
EOF
}

# 将任意字符串转为 JSON 字符串内容。
themis_spec_json_escape() {
  local themis_spec_json_value=${1-}
  themis_spec_json_value=${themis_spec_json_value//\/\\}
  themis_spec_json_value=${themis_spec_json_value//\"/\\\"}
  themis_spec_json_value=${themis_spec_json_value//$'\r'/\\r}
  themis_spec_json_value=${themis_spec_json_value//$'\n'/\\n}
  themis_spec_json_value=${themis_spec_json_value//$'\t'/\\t}
  printf '%s' "${themis_spec_json_value}"
}

# 记录稳定错误 ID；自然语言诊断留给调用方按 ID 展示。
themis_spec_add_error() {
  THEMIS_SPEC_VALID=0
  printf '%s\n' "$1" >>"${THEMIS_SPEC_ERROR_FILE}"
}

# 校验 mikefarah/yq v4；Spec 结构契约只允许这一实现。
themis_spec_require_yq() {
  local themis_spec_yq_version
  if ! command -v yq >/dev/null 2>&1; then
    printf '%s\n' 'Themis Spec failed: mikefarah/yq v4 is required.' >&2
    return 1
  fi
  themis_spec_yq_version=$(yq --version 2>&1 || true)
  case "${themis_spec_yq_version}" in
    *mikefarah/yq*version\ v4.*) return 0 ;;
  esac
  printf '%s\n' 'Themis Spec failed: unsupported yq implementation.' >&2
  return 1
}

# 投影 OID 使用 Git blob 算法，避免绑定 SHA-1 或自行实现摘要。
themis_spec_require_git() {
  if ! command -v git >/dev/null 2>&1; then
    printf '%s\n' 'Themis Spec failed: Git is required for projection OIDs.' >&2
    return 1
  fi
  return 0
}

# 解析统一的显式选项，拒绝位置参数和重复动作。
themis_spec_parse_arguments() {
  if [ "$#" -eq 0 ]; then
    themis_spec_usage >&2
    return 1
  fi
  THEMIS_SPEC_ACTION=$1
  shift

  case "${THEMIS_SPEC_ACTION}" in
    validate|render|publish) ;;
    --help|-h)
      themis_spec_usage
      exit 0
      ;;
    *)
      printf '%s\n' "Themis Spec failed: unknown command ${THEMIS_SPEC_ACTION}." >&2
      return 1
      ;;
  esac

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --source|--projection|--output|--candidate|--target)
        if [ "$#" -lt 2 ] || [ -z "$2" ]; then
          printf '%s\n' "Themis Spec failed: missing value for $1." >&2
          return 1
        fi
        case "$1" in
          --source) THEMIS_SPEC_SOURCE=$2 ;;
          --projection) THEMIS_SPEC_PROJECTION=$2 ;;
          --output) THEMIS_SPEC_OUTPUT=$2 ;;
          --candidate) THEMIS_SPEC_CANDIDATE=$2 ;;
          --target) THEMIS_SPEC_TARGET=$2 ;;
        esac
        shift
        ;;
      --readiness)
        THEMIS_SPEC_REQUIRE_READINESS=1
        ;;
      --help|-h)
        themis_spec_usage
        exit 0
        ;;
      *)
        printf '%s\n' "Themis Spec failed: unknown option $1." >&2
        return 1
        ;;
    esac
    shift
  done

  case "${THEMIS_SPEC_ACTION}" in
    validate)
      [ -n "${THEMIS_SPEC_SOURCE}" ] && [ -z "${THEMIS_SPEC_OUTPUT}${THEMIS_SPEC_CANDIDATE}${THEMIS_SPEC_TARGET}" ] || return 1
      ;;
    render)
      [ -n "${THEMIS_SPEC_SOURCE}" ] && [ -n "${THEMIS_SPEC_OUTPUT}" ] && [ -z "${THEMIS_SPEC_PROJECTION}${THEMIS_SPEC_CANDIDATE}${THEMIS_SPEC_TARGET}" ] || return 1
      ;;
    publish)
      [ -n "${THEMIS_SPEC_CANDIDATE}" ] && [ -n "${THEMIS_SPEC_TARGET}" ] && [ -z "${THEMIS_SPEC_SOURCE}${THEMIS_SPEC_PROJECTION}${THEMIS_SPEC_OUTPUT}" ] || return 1
      ;;
  esac
  return 0
}

# 安全读取 YAML 标量；调用方已经验证输入可解析。
themis_spec_read() {
  yq eval -r "$1" "$2"
}

# 读取动态 map 字段，避免把对象 ID 拼入 yq 表达式。
themis_spec_read_field() {
  THEMIS_SPEC_COLLECTION=$1 THEMIS_SPEC_OBJECT_ID=$2 THEMIS_SPEC_FIELD=$3 \
    yq eval -r '.[strenv(THEMIS_SPEC_COLLECTION)][strenv(THEMIS_SPEC_OBJECT_ID)][strenv(THEMIS_SPEC_FIELD)]' "$4"
}

# 检查 YAML 路径的节点类型。
themis_spec_expect_type() {
  local themis_spec_type_file=$1
  local themis_spec_type_expression=$2
  local themis_spec_type_expected=$3
  local themis_spec_type_error=$4
  local themis_spec_type_actual
  themis_spec_type_actual=$(yq eval -r "${themis_spec_type_expression} | type" "${themis_spec_type_file}" 2>/dev/null || printf 'unreadable')
  if [ "${themis_spec_type_actual}" != "${themis_spec_type_expected}" ]; then
    themis_spec_add_error "${themis_spec_type_error}"
    return 1
  fi
  return 0
}

# 校验可空字符串字段。
themis_spec_expect_nullable_string() {
  local themis_spec_nullable_type
  themis_spec_nullable_type=$(yq eval -r "$2 | type" "$1" 2>/dev/null || printf 'unreadable')
  case "${themis_spec_nullable_type}" in
    '!!str'|'!!null') return 0 ;;
  esac
  themis_spec_add_error "$3"
  return 1
}

# 批量校验固定对象的必需键与未知键；字段类型仍由对应专用校验负责。
themis_spec_validate_fixed_map() {
  local themis_spec_fixed_source=$1
  local themis_spec_fixed_contract=$2
  local themis_spec_fixed_expression=$3
  local themis_spec_fixed_type
  local themis_spec_fixed_error

  # 固定表达式来自 executor 调用点；同次 yq 同时读取受信 Schema，避免逐字段重启解析器。
  while IFS= read -r themis_spec_fixed_type; do
    break
  done < <(
    THEMIS_SPEC_FIXED_MAP=${themis_spec_fixed_contract} yq eval -r "
      . as \$source |
      load(strenv(THEMIS_SPEC_SCHEMA)) as \$schema |
      strenv(THEMIS_SPEC_FIXED_MAP) as \$name |
      \$schema.fixed_maps[\$name] as \$contract |
      (\$source | ${themis_spec_fixed_expression} | type) as \$node_type |
      \$node_type,
      select(\$node_type == \"!!map\") |
      ((\$contract.required - (\$source | ${themis_spec_fixed_expression} | keys))[] |
        \"fixed_map.\" + \$name + \".required.\" + .),
      (((\$source | ${themis_spec_fixed_expression} | keys) - \$contract.allowed)[] |
        \"fixed_map.\" + \$name + \".unknown.\" + .)
    " "${themis_spec_fixed_source}"
  )
  [ "${themis_spec_fixed_type}" = '!!map' ] || return 1

  # 第一行是类型 sentinel；其余记录已经按既有 required、unknown 顺序给出稳定 ID。
  while IFS= read -r themis_spec_fixed_error; do
    [ -n "${themis_spec_fixed_error}" ] || continue
    themis_spec_add_error "${themis_spec_fixed_error}"
  done < <(
    THEMIS_SPEC_FIXED_MAP=${themis_spec_fixed_contract} yq eval -r "
      . as \$source |
      load(strenv(THEMIS_SPEC_SCHEMA)) as \$schema |
      strenv(THEMIS_SPEC_FIXED_MAP) as \$name |
      \$schema.fixed_maps[\$name] as \$contract |
      (\$source | ${themis_spec_fixed_expression} | type) as \$node_type |
      \$node_type,
      select(\$node_type == \"!!map\") |
      ((\$contract.required - (\$source | ${themis_spec_fixed_expression} | keys))[] |
        \"fixed_map.\" + \$name + \".required.\" + .),
      (((\$source | ${themis_spec_fixed_expression} | keys) - \$contract.allowed)[] |
        \"fixed_map.\" + \$name + \".unknown.\" + .)
    " "${themis_spec_fixed_source}" | sed '1d'
  )
  return 0
}

# 判断字符串是否属于协议声明的枚举。
themis_spec_protocol_enum_contains() {
  local themis_spec_enum_name=$1
  local themis_spec_enum_value=$2
  THEMIS_SPEC_ENUM_NAME=${themis_spec_enum_name} THEMIS_SPEC_ENUM_VALUE=${themis_spec_enum_value} \
    yq eval -e '.enums[strenv(THEMIS_SPEC_ENUM_NAME)] | contains([strenv(THEMIS_SPEC_ENUM_VALUE)])' "${THEMIS_SPEC_SCHEMA}" >/dev/null 2>&1
}

# 检查集合对象字段引用；resolution_refs 的 * 目标允许引用任意已声明集合。
themis_spec_reference_exists() {
  local themis_spec_reference_target=$1
  local themis_spec_reference_id=$2
  local themis_spec_reference_source=$3
  local themis_spec_reference_collection

  if [ "${themis_spec_reference_target}" = '*' ]; then
    while IFS= read -r themis_spec_reference_collection; do
      if THEMIS_SPEC_COLLECTION=${themis_spec_reference_collection} THEMIS_SPEC_REFERENCE=${themis_spec_reference_id} \
        yq eval -e '.[strenv(THEMIS_SPEC_COLLECTION)] | has(strenv(THEMIS_SPEC_REFERENCE))' "${themis_spec_reference_source}" >/dev/null 2>&1; then
        return 0
      fi
    done < <(yq eval -r '.collections | keys | .[]' "${THEMIS_SPEC_SCHEMA}")
    return 1
  fi

  THEMIS_SPEC_COLLECTION=${themis_spec_reference_target} THEMIS_SPEC_REFERENCE=${themis_spec_reference_id} \
    yq eval -e '.[strenv(THEMIS_SPEC_COLLECTION)] | has(strenv(THEMIS_SPEC_REFERENCE))' "${themis_spec_reference_source}" >/dev/null 2>&1
}

# 校验协议声明的一个对象集合：ID、键、枚举和引用都由 Schema 驱动。
themis_spec_validate_collection() {
  local themis_spec_collection=$1
  local themis_spec_collection_source=$2
  local themis_spec_collection_prefix
  local themis_spec_collection_id
  local themis_spec_collection_key
  local themis_spec_collection_field
  local themis_spec_collection_value
  local themis_spec_collection_target
  local themis_spec_collection_ref
  local themis_spec_collection_suffix
  local themis_spec_collection_type

  themis_spec_collection_prefix=$(THEMIS_SPEC_COLLECTION=${themis_spec_collection} yq eval -r '.collections[strenv(THEMIS_SPEC_COLLECTION)].prefix' "${THEMIS_SPEC_SCHEMA}")

  while IFS= read -r themis_spec_collection_id; do
    case "${themis_spec_collection_id}" in
      "${themis_spec_collection_prefix}"*)
        themis_spec_collection_suffix=${themis_spec_collection_id#"${themis_spec_collection_prefix}"}
        case "${themis_spec_collection_suffix}" in
          ''|*[!0-9]*) themis_spec_add_error "collection.${themis_spec_collection}.id_invalid" ;;
          *)
            if [ "${#themis_spec_collection_suffix}" -lt 3 ]; then
              themis_spec_add_error "collection.${themis_spec_collection}.id_invalid"
            fi
            ;;
        esac
        ;;
      *) themis_spec_add_error "collection.${themis_spec_collection}.id_invalid" ;;
    esac

    if ! THEMIS_SPEC_COLLECTION=${themis_spec_collection} THEMIS_SPEC_OBJECT_ID=${themis_spec_collection_id} \
      yq eval -e '.[strenv(THEMIS_SPEC_COLLECTION)][strenv(THEMIS_SPEC_OBJECT_ID)] | type == "!!map"' "${themis_spec_collection_source}" >/dev/null 2>&1; then
      themis_spec_add_error "collection.${themis_spec_collection}.object_invalid"
      continue
    fi

    while IFS= read -r themis_spec_collection_field; do
      if ! THEMIS_SPEC_COLLECTION=${themis_spec_collection} THEMIS_SPEC_OBJECT_ID=${themis_spec_collection_id} THEMIS_SPEC_FIELD=${themis_spec_collection_field} \
        yq eval -e '.[strenv(THEMIS_SPEC_COLLECTION)][strenv(THEMIS_SPEC_OBJECT_ID)] | has(strenv(THEMIS_SPEC_FIELD))' "${themis_spec_collection_source}" >/dev/null 2>&1; then
        themis_spec_add_error "collection.${themis_spec_collection}.required.${themis_spec_collection_field}"
      fi
    done < <(THEMIS_SPEC_COLLECTION=${themis_spec_collection} yq eval -r '.collections[strenv(THEMIS_SPEC_COLLECTION)].required[]' "${THEMIS_SPEC_SCHEMA}")

    while IFS= read -r themis_spec_collection_key; do
      if ! THEMIS_SPEC_COLLECTION=${themis_spec_collection} THEMIS_SPEC_KEY=${themis_spec_collection_key} \
        yq eval -e '.collections[strenv(THEMIS_SPEC_COLLECTION)].allowed | contains([strenv(THEMIS_SPEC_KEY)])' "${THEMIS_SPEC_SCHEMA}" >/dev/null 2>&1; then
        themis_spec_add_error "collection.${themis_spec_collection}.unknown.${themis_spec_collection_key}"
      fi
    done < <(THEMIS_SPEC_COLLECTION=${themis_spec_collection} THEMIS_SPEC_OBJECT_ID=${themis_spec_collection_id} \
      yq eval -r '.[strenv(THEMIS_SPEC_COLLECTION)][strenv(THEMIS_SPEC_OBJECT_ID)] | keys | .[]' "${themis_spec_collection_source}")

    while IFS= read -r themis_spec_collection_field; do
      themis_spec_collection_type=$(THEMIS_SPEC_COLLECTION=${themis_spec_collection} THEMIS_SPEC_OBJECT_ID=${themis_spec_collection_id} THEMIS_SPEC_FIELD=${themis_spec_collection_field} \
        yq eval -r '.[strenv(THEMIS_SPEC_COLLECTION)][strenv(THEMIS_SPEC_OBJECT_ID)][strenv(THEMIS_SPEC_FIELD)] | type' "${themis_spec_collection_source}" 2>/dev/null || printf 'unreadable')
      if [ "${themis_spec_collection_type}" != '!!str' ]; then
        themis_spec_add_error "collection.${themis_spec_collection}.type.${themis_spec_collection_field}"
      fi
    done < <(THEMIS_SPEC_COLLECTION=${themis_spec_collection} yq eval -r '.collections[strenv(THEMIS_SPEC_COLLECTION)].strings[]?' "${THEMIS_SPEC_SCHEMA}")

    while IFS= read -r themis_spec_collection_field; do
      themis_spec_collection_value=$(themis_spec_read_field "${themis_spec_collection}" "${themis_spec_collection_id}" "${themis_spec_collection_field}" "${themis_spec_collection_source}")
      if ! THEMIS_SPEC_COLLECTION=${themis_spec_collection} THEMIS_SPEC_FIELD=${themis_spec_collection_field} THEMIS_SPEC_VALUE=${themis_spec_collection_value} \
        yq eval -e '.collections[strenv(THEMIS_SPEC_COLLECTION)].enums[strenv(THEMIS_SPEC_FIELD)] | contains([strenv(THEMIS_SPEC_VALUE)])' "${THEMIS_SPEC_SCHEMA}" >/dev/null 2>&1; then
        themis_spec_add_error "collection.${themis_spec_collection}.enum.${themis_spec_collection_field}"
      fi
    done < <(THEMIS_SPEC_COLLECTION=${themis_spec_collection} yq eval -r '.collections[strenv(THEMIS_SPEC_COLLECTION)].enums // {} | keys | .[]' "${THEMIS_SPEC_SCHEMA}")

    while IFS= read -r themis_spec_collection_field; do
      themis_spec_collection_target=$(THEMIS_SPEC_COLLECTION=${themis_spec_collection} THEMIS_SPEC_FIELD=${themis_spec_collection_field} \
        yq eval -r '.collections[strenv(THEMIS_SPEC_COLLECTION)].references[strenv(THEMIS_SPEC_FIELD)]' "${THEMIS_SPEC_SCHEMA}")
      if ! THEMIS_SPEC_COLLECTION=${themis_spec_collection} THEMIS_SPEC_OBJECT_ID=${themis_spec_collection_id} THEMIS_SPEC_FIELD=${themis_spec_collection_field} \
        yq eval -e '.[strenv(THEMIS_SPEC_COLLECTION)][strenv(THEMIS_SPEC_OBJECT_ID)][strenv(THEMIS_SPEC_FIELD)] | type == "!!seq"' "${themis_spec_collection_source}" >/dev/null 2>&1; then
        themis_spec_add_error "collection.${themis_spec_collection}.reference_type.${themis_spec_collection_field}"
        continue
      fi
      while IFS= read -r themis_spec_collection_ref; do
        if ! themis_spec_reference_exists "${themis_spec_collection_target}" "${themis_spec_collection_ref}" "${themis_spec_collection_source}"; then
          themis_spec_add_error "collection.${themis_spec_collection}.dangling.${themis_spec_collection_field}"
        fi
      done < <(THEMIS_SPEC_COLLECTION=${themis_spec_collection} THEMIS_SPEC_OBJECT_ID=${themis_spec_collection_id} THEMIS_SPEC_FIELD=${themis_spec_collection_field} \
        yq eval -r '.[strenv(THEMIS_SPEC_COLLECTION)][strenv(THEMIS_SPEC_OBJECT_ID)][strenv(THEMIS_SPEC_FIELD)][]' "${themis_spec_collection_source}")
    done < <(THEMIS_SPEC_COLLECTION=${themis_spec_collection} yq eval -r '.collections[strenv(THEMIS_SPEC_COLLECTION)].references // {} | keys | .[]' "${THEMIS_SPEC_SCHEMA}")
  done < <(THEMIS_SPEC_COLLECTION=${themis_spec_collection} yq eval -r '.[strenv(THEMIS_SPEC_COLLECTION)] | keys | .[]' "${themis_spec_collection_source}")
}

# 检查 Human 主视图引用及图数量约束。
themis_spec_validate_review_projection_contract() {
  local themis_spec_review_source=$1
  local themis_spec_review_field
  local themis_spec_review_target
  local themis_spec_review_ref
  local themis_spec_review_count
  local themis_spec_review_max
  local themis_spec_review_level
  local themis_spec_review_min_diagrams
  local themis_spec_review_max_diagrams

  for themis_spec_review_field in primary_decisions primary_risks primary_diagrams; do
    case "${themis_spec_review_field}" in
      primary_decisions) themis_spec_review_target=decisions ;;
      primary_risks) themis_spec_review_target=risks ;;
      primary_diagrams) themis_spec_review_target=diagrams ;;
    esac
    if ! yq eval -e ".review.${themis_spec_review_field} | type == \"!!seq\"" "${themis_spec_review_source}" >/dev/null 2>&1; then
      themis_spec_add_error "review.${themis_spec_review_field}.type"
      continue
    fi
    while IFS= read -r themis_spec_review_ref; do
      if ! themis_spec_reference_exists "${themis_spec_review_target}" "${themis_spec_review_ref}" "${themis_spec_review_source}"; then
        themis_spec_add_error "review.${themis_spec_review_field}.dangling"
      fi
    done < <(yq eval -r ".review.${themis_spec_review_field}[]" "${themis_spec_review_source}")
  done

  for themis_spec_review_field in primary_decisions primary_risks; do
    themis_spec_review_count=$(yq eval ".review.${themis_spec_review_field} | length" "${themis_spec_review_source}")
    case "${themis_spec_review_field}" in
      primary_decisions) themis_spec_review_max=$(yq eval '.primary_view.max_decisions' "${THEMIS_SPEC_PROJECTION_PROTOCOL}") ;;
      primary_risks) themis_spec_review_max=$(yq eval '.primary_view.max_risks' "${THEMIS_SPEC_PROJECTION_PROTOCOL}") ;;
    esac
    if [ "${themis_spec_review_count}" -gt "${themis_spec_review_max}" ]; then
      themis_spec_add_error "review.${themis_spec_review_field}.limit"
    fi
  done

  themis_spec_review_level=$(yq eval -r '.complexity.level' "${themis_spec_review_source}")
  case "${themis_spec_review_level}" in
    low|medium|high)
      themis_spec_review_count=$(yq eval '.review.primary_diagrams | length' "${themis_spec_review_source}")
      export THEMIS_SPEC_LEVEL=${themis_spec_review_level}
      themis_spec_review_min_diagrams=$(yq eval '.primary_view.diagrams[strenv(THEMIS_SPEC_LEVEL)].min' "${THEMIS_SPEC_PROJECTION_PROTOCOL}")
      themis_spec_review_max_diagrams=$(yq eval '.primary_view.diagrams[strenv(THEMIS_SPEC_LEVEL)].max' "${THEMIS_SPEC_PROJECTION_PROTOCOL}")
      unset THEMIS_SPEC_LEVEL
      if [ "${themis_spec_review_count}" -gt "${themis_spec_review_max_diagrams}" ]; then
        themis_spec_add_error 'review.primary_diagrams.limit'
      fi
      if [ "${themis_spec_review_count}" -lt "${themis_spec_review_min_diagrams}" ]; then
        themis_spec_add_error 'review.primary_diagrams.minimum'
      fi
      if [ "${themis_spec_review_level}" = low ] && [ "${themis_spec_review_count}" -eq 0 ] && [ -z "$(yq eval -r '.review.no_diagram_reason' "${themis_spec_review_source}")" ]; then
        themis_spec_add_error 'review.no_diagram_reason.required'
      fi
      ;;
  esac
}

# 校验 Markdown marker、源 OID 和正文 OID；任何手改都只报告漂移。
themis_spec_check_projection() {
  local themis_spec_projection_source=$1
  local themis_spec_projection_file=$2
  local themis_spec_projection_marker
  local themis_spec_projection_source_oid
  local themis_spec_projection_body_oid
  local themis_spec_projection_expected_source_oid
  local themis_spec_projection_actual_body_oid
  local themis_spec_projection_expected_body_oid
  local themis_spec_projection_body_file
  local themis_spec_projection_expected_body_file

  THEMIS_SPEC_PROJECTION_CURRENT=0
  [ -f "${themis_spec_projection_file}" ] || return 1
  themis_spec_require_git || return 1
  IFS= read -r themis_spec_projection_marker <"${themis_spec_projection_file}" || return 1
  themis_spec_projection_marker=${themis_spec_projection_marker%$'\r'}
  case "${themis_spec_projection_marker}" in
    '<!-- themis-projection source=spec.yaml source_oid='*' body_oid='*' -->') ;;
    *) return 1 ;;
  esac

  themis_spec_projection_source_oid=${themis_spec_projection_marker#* source_oid=}
  themis_spec_projection_source_oid=${themis_spec_projection_source_oid%% body_oid=*}
  themis_spec_projection_body_oid=${themis_spec_projection_marker#* body_oid=}
  themis_spec_projection_body_oid=${themis_spec_projection_body_oid% -->}
  themis_spec_projection_expected_source_oid=$(git hash-object -- "${themis_spec_projection_source}" 2>/dev/null) || return 1
  if [ "${themis_spec_projection_source_oid}" != "${themis_spec_projection_expected_source_oid}" ]; then
    return 1
  fi
  themis_spec_projection_body_file="${THEMIS_SPEC_TEMP_ROOT}/projection-body-$$"
  themis_spec_projection_expected_body_file="${THEMIS_SPEC_TEMP_ROOT}/projection-expected-body-$$"
  sed '1d' "${themis_spec_projection_file}" >"${themis_spec_projection_body_file}" || return 1
  themis_spec_projection_actual_body_oid=$(git hash-object -- "${themis_spec_projection_body_file}" 2>/dev/null) || {
    rm -f "${themis_spec_projection_body_file}" "${themis_spec_projection_expected_body_file}"
    return 1
  }
  if [ "${themis_spec_projection_body_oid}" != "${themis_spec_projection_actual_body_oid}" ]; then
    rm -f "${themis_spec_projection_body_file}" "${themis_spec_projection_expected_body_file}"
    return 1
  fi
  themis_spec_render_body "${themis_spec_projection_source}" "${themis_spec_projection_expected_body_file}" || {
    rm -f "${themis_spec_projection_body_file}" "${themis_spec_projection_expected_body_file}"
    return 1
  }
  themis_spec_projection_expected_body_oid=$(git hash-object -- "${themis_spec_projection_expected_body_file}" 2>/dev/null) || {
    rm -f "${themis_spec_projection_body_file}" "${themis_spec_projection_expected_body_file}"
    return 1
  }
  rm -f "${themis_spec_projection_body_file}" "${themis_spec_projection_expected_body_file}"

  if [ "${themis_spec_projection_body_oid}" = "${themis_spec_projection_expected_body_oid}" ]; then
    THEMIS_SPEC_PROJECTION_CURRENT=1
    return 0
  fi
  return 1
}

# 检查协议声明为 readiness 必填的集合字符串；同一校验轮次只遍历一次。
themis_spec_readiness_fields_complete() {
  local themis_spec_readiness_field_source=$1
  local themis_spec_readiness_field_collection
  local themis_spec_readiness_field_name
  local themis_spec_readiness_field_id
  local themis_spec_readiness_field_value

  if [ "${THEMIS_SPEC_READINESS_FIELDS_CACHE_SET}" -eq 1 ] && \
     [ "${THEMIS_SPEC_READINESS_FIELDS_CACHE_SOURCE}" = "${themis_spec_readiness_field_source}" ]; then
    [ "${THEMIS_SPEC_READINESS_FIELDS_CACHE_COMPLETE}" -eq 1 ]
    return $?
  fi

  THEMIS_SPEC_READINESS_FIELDS_CACHE_SOURCE=${themis_spec_readiness_field_source}
  THEMIS_SPEC_READINESS_FIELDS_CACHE_SET=1
  THEMIS_SPEC_READINESS_FIELDS_CACHE_COMPLETE=0
  while IFS= read -r themis_spec_readiness_field_collection; do
    while IFS= read -r themis_spec_readiness_field_name; do
      while IFS= read -r themis_spec_readiness_field_id; do
        themis_spec_readiness_field_value=$(themis_spec_read_field "${themis_spec_readiness_field_collection}" "${themis_spec_readiness_field_id}" "${themis_spec_readiness_field_name}" "${themis_spec_readiness_field_source}")
        [ -n "${themis_spec_readiness_field_value}" ] || return 1
      done < <(THEMIS_SPEC_COLLECTION=${themis_spec_readiness_field_collection} yq eval -r '.[strenv(THEMIS_SPEC_COLLECTION)] | keys | .[]' "${themis_spec_readiness_field_source}")
    done < <(THEMIS_SPEC_COLLECTION=${themis_spec_readiness_field_collection} yq eval -r '.collections[strenv(THEMIS_SPEC_COLLECTION)].readiness_non_empty[]?' "${THEMIS_SPEC_SCHEMA}")
  done < <(yq eval -r '.collections | keys | .[]' "${THEMIS_SPEC_SCHEMA}")
  THEMIS_SPEC_READINESS_FIELDS_CACHE_COMPLETE=1
  return 0
}

# 校验最终语义中的 Context 依据；引用只允许指向 evidence、assumptions 与 risks。
themis_spec_validate_context_basis() {
  local themis_spec_context_source=$1
  local themis_spec_context_ref

  themis_spec_expect_type "${themis_spec_context_source}" '.context_basis.disposition' '!!str' 'type.context_basis.disposition' || true
  themis_spec_expect_type "${themis_spec_context_source}" '.context_basis.evidence_refs' '!!seq' 'type.context_basis.evidence_refs' || true
  themis_spec_expect_type "${themis_spec_context_source}" '.context_basis.limitation_refs' '!!seq' 'type.context_basis.limitation_refs' || true
  themis_spec_expect_type "${themis_spec_context_source}" '.context_basis.rationale' '!!str' 'type.context_basis.rationale' || true

  while IFS= read -r themis_spec_context_ref; do
    [ -n "${themis_spec_context_ref}" ] || continue
    if ! themis_spec_reference_exists evidence "${themis_spec_context_ref}" "${themis_spec_context_source}"; then
      themis_spec_add_error 'context_basis.dangling.evidence_refs'
    fi
  done < <(yq eval -r '.context_basis.evidence_refs[]?' "${themis_spec_context_source}")

  while IFS= read -r themis_spec_context_ref; do
    [ -n "${themis_spec_context_ref}" ] || continue
    case "${themis_spec_context_ref}" in
      ASM-*)
        themis_spec_reference_exists assumptions "${themis_spec_context_ref}" "${themis_spec_context_source}" || themis_spec_add_error 'context_basis.dangling.limitation_refs'
        ;;
      RSK-*)
        themis_spec_reference_exists risks "${themis_spec_context_ref}" "${themis_spec_context_source}" || themis_spec_add_error 'context_basis.dangling.limitation_refs'
        ;;
      *) themis_spec_add_error 'context_basis.invalid.limitation_refs' ;;
    esac
  done < <(yq eval -r '.context_basis.limitation_refs[]?' "${themis_spec_context_source}")
}

# 检查最终 Spec 是否包含 policy 声明的占位文本。
themis_spec_has_placeholder() {
  local themis_spec_placeholder_source=$1
  local themis_spec_placeholder_pattern

  while IFS= read -r themis_spec_placeholder_pattern; do
    if THEMIS_SPEC_PATTERN=${themis_spec_placeholder_pattern} yq eval -e '
      .. | select(type == "!!str") | select(test(strenv(THEMIS_SPEC_PATTERN)))
    ' "${themis_spec_placeholder_source}" >/dev/null 2>&1; then
      return 0
    fi
  done < <(yq eval -r '.specification.semantic_consistency.placeholder_patterns[]' "${THEMIS_SPEC_POLICY}")
  return 1
}

# 比较 Review Summary 的 include/exclude 文本与 scope 中同类 statement。
themis_spec_scope_summary_matches() {
  local themis_spec_scope_source=$1
  local themis_spec_scope_kind
  local themis_spec_scope_summary_field
  local themis_spec_scope_count
  local themis_spec_summary_count
  local themis_spec_scope_id
  local themis_spec_scope_statement

  for themis_spec_scope_kind in include exclude; do
    case "${themis_spec_scope_kind}" in
      include) themis_spec_scope_summary_field=included ;;
      exclude) themis_spec_scope_summary_field=excluded ;;
    esac
    themis_spec_scope_count=$(THEMIS_SPEC_SCOPE_KIND=${themis_spec_scope_kind} yq eval '[.scope[] | select(.kind == strenv(THEMIS_SPEC_SCOPE_KIND))] | length' "${themis_spec_scope_source}")
    themis_spec_summary_count=$(THEMIS_SPEC_SUMMARY_FIELD=${themis_spec_scope_summary_field} yq eval '.review.summary[strenv(THEMIS_SPEC_SUMMARY_FIELD)] | length' "${themis_spec_scope_source}")
    [ "${themis_spec_scope_count}" -eq "${themis_spec_summary_count}" ] || return 1

    while IFS= read -r themis_spec_scope_id; do
      themis_spec_scope_statement=$(themis_spec_read_field scope "${themis_spec_scope_id}" statement "${themis_spec_scope_source}")
      if ! THEMIS_SPEC_SUMMARY_FIELD=${themis_spec_scope_summary_field} THEMIS_SPEC_STATEMENT=${themis_spec_scope_statement} \
        yq eval -e '.review.summary[strenv(THEMIS_SPEC_SUMMARY_FIELD)] | contains([strenv(THEMIS_SPEC_STATEMENT)])' "${themis_spec_scope_source}" >/dev/null 2>&1; then
        return 1
      fi
    done < <(THEMIS_SPEC_SCOPE_KIND=${themis_spec_scope_kind} yq eval -r '.scope | to_entries[] | select(.value.kind == strenv(THEMIS_SPEC_SCOPE_KIND)) | .key' "${themis_spec_scope_source}")
  done
  return 0
}

# 检查 selected option 必须被 decision 引用，且 assumption/option 无 pending。
themis_spec_decisions_consistent() {
  local themis_spec_decision_source=$1
  local themis_spec_selected_option

  # shellcheck disable=SC2016 # `$root` 与 `$ref` 属于 yq 表达式，不由 shell 展开。
  if yq eval -e '.assumptions[] | select(.status == "pending")' "${themis_spec_decision_source}" >/dev/null 2>&1 || \
     yq eval -e '.options[] | select(.disposition == "pending")' "${themis_spec_decision_source}" >/dev/null 2>&1 || \
     yq eval -e '. as $root | .decisions[] | select((.option_refs | length == 0) or ([.option_refs[] as $ref | $root.options[$ref].disposition == "selected"] | any | not))' "${themis_spec_decision_source}" >/dev/null 2>&1; then
    return 1
  fi

  while IFS= read -r themis_spec_selected_option; do
    if ! THEMIS_SPEC_OPTION_ID=${themis_spec_selected_option} yq eval -e '.decisions[] | select(.option_refs | contains([strenv(THEMIS_SPEC_OPTION_ID)]))' "${themis_spec_decision_source}" >/dev/null 2>&1; then
      return 1
    fi
  done < <(yq eval -r '.options | to_entries[] | select(.value.disposition == "selected") | .key' "${themis_spec_decision_source}")
  return 0
}

# 计算可由 executor 证明的最终语义一致性，不接受 Agent 自报布尔值。
themis_spec_semantic_consistency_complete() {
  local themis_spec_consistency_source=$1

  themis_spec_readiness_fields_complete "${themis_spec_consistency_source}" || return 1
  themis_spec_has_placeholder "${themis_spec_consistency_source}" && return 1
  [ "$(yq eval -r '.review.summary.request' "${themis_spec_consistency_source}")" = "$(yq eval -r '.intent.request' "${themis_spec_consistency_source}")" ] || return 1
  [ "$(yq eval -r '.review.summary.intent' "${themis_spec_consistency_source}")" = "$(yq eval -r '.intent.outcome' "${themis_spec_consistency_source}")" ] || return 1
  [ "$(yq eval -r '.review.summary.root_cause' "${themis_spec_consistency_source}")" = "$(yq eval -r '.intent.root_cause' "${themis_spec_consistency_source}")" ] || return 1
  themis_spec_scope_summary_matches "${themis_spec_consistency_source}" || return 1
  themis_spec_decisions_consistent "${themis_spec_consistency_source}" || return 1
  ! yq eval -e '.requirements[] | select((.scope_refs | length == 0) or (.evidence_refs | length == 0))' "${themis_spec_consistency_source}" >/dev/null 2>&1 || return 1
  ! yq eval -e '.acceptance_criteria[] | select(.requirement_refs | length == 0)' "${themis_spec_consistency_source}" >/dev/null 2>&1 || return 1
  [ "$(yq eval '.rollback.triggers | length' "${themis_spec_consistency_source}")" -gt 0 ] || return 1
  [ "$(yq eval '.rollback.steps | length' "${themis_spec_consistency_source}")" -gt 0 ] || return 1
  [ -n "$(yq eval -r '.rollback.impact' "${themis_spec_consistency_source}")" ] || return 1
  return 0
}

# 计算八个稳定 readiness check；只做可确定判断，不替代用户语义决策。
themis_spec_compute_readiness() {
  local themis_spec_readiness_source=$1
  local themis_spec_readiness_projection=${2-}
  local themis_spec_readiness_level
  local themis_spec_readiness_context_disposition
  local themis_spec_readiness_context=0
  local themis_spec_readiness_adversarial=1
  local themis_spec_readiness_finding
  local themis_spec_readiness_disposition
  local themis_spec_readiness_dimension
  local themis_spec_readiness_severity
  local themis_spec_readiness_count
  local themis_spec_readiness_limit

  THEMIS_SPEC_CHECK_INTENT=0
  THEMIS_SPEC_CHECK_SCOPE=0
  THEMIS_SPEC_CHECK_CONTEXT=0
  THEMIS_SPEC_CHECK_DESIGN=0
  THEMIS_SPEC_CHECK_ADVERSARIAL=0
  THEMIS_SPEC_CHECK_SELF=0
  THEMIS_SPEC_CHECK_APPROVAL=0
  THEMIS_SPEC_CHECK_PROJECTION=0

  if [ -n "$(yq eval -r '.intent.request' "${themis_spec_readiness_source}")" ] && \
     [ -n "$(yq eval -r '.intent.outcome' "${themis_spec_readiness_source}")" ] && \
     [ -n "$(yq eval -r '.intent.root_cause' "${themis_spec_readiness_source}")" ]; then
    THEMIS_SPEC_CHECK_INTENT=1
  fi

  themis_spec_readiness_level=$(yq eval -r '.complexity.level' "${themis_spec_readiness_source}")
  if case "${themis_spec_readiness_level}" in low|medium|high) true ;; *) false ;; esac && \
     [ "$(yq eval -r '.complexity.confirmed' "${themis_spec_readiness_source}")" = true ] && \
     [ "$(yq eval '.scope | length' "${themis_spec_readiness_source}")" -gt 0 ]; then
    THEMIS_SPEC_CHECK_SCOPE=1
  fi

  themis_spec_readiness_context_disposition=$(yq eval -r '.context_basis.disposition' "${themis_spec_readiness_source}")
  case "${themis_spec_readiness_context_disposition}" in
    grounded)
      # shellcheck disable=SC2016 # `$ref` 属于 yq 表达式，不由 shell 展开。
      if [ "$(yq eval '.context_basis.evidence_refs | length' "${themis_spec_readiness_source}")" -gt 0 ] && \
         yq eval -e '
           .context_basis.evidence_refs[] as $ref |
           .evidence[$ref] | select(.kind == "context" or .kind == "code" or .kind == "external")
         ' "${themis_spec_readiness_source}" >/dev/null 2>&1; then
        themis_spec_readiness_context=1
      fi
      ;;
    not_required)
      if [ "${themis_spec_readiness_level}" = low ] && \
         [ "$(yq eval -r '.complexity.confirmed' "${themis_spec_readiness_source}")" = true ] && \
         [ -n "$(yq eval -r '.context_basis.rationale' "${themis_spec_readiness_source}")" ]; then
        themis_spec_readiness_context=1
      fi
      ;;
    limited)
      # shellcheck disable=SC2016 # `$ref` 属于 yq 表达式，不由 shell 展开。
      if [ -n "$(yq eval -r '.context_basis.rationale' "${themis_spec_readiness_source}")" ] && \
         [ "$(yq eval '.context_basis.evidence_refs | length' "${themis_spec_readiness_source}")" -gt 0 ] && \
         [ "$(yq eval '.context_basis.limitation_refs | length' "${themis_spec_readiness_source}")" -gt 0 ] && \
         ! yq eval -e '
           .context_basis.limitation_refs[] as $ref |
           if ($ref | startswith("ASM-")) then .assumptions[$ref] | select(.status == "pending")
           elif ($ref | startswith("RSK-")) then .risks[$ref] | select(.status == "open")
           else true end
         ' "${themis_spec_readiness_source}" >/dev/null 2>&1; then
        themis_spec_readiness_context=1
      fi
      ;;
  esac
  THEMIS_SPEC_CHECK_CONTEXT=${themis_spec_readiness_context}

  if [ "$(yq eval '.decisions | length' "${themis_spec_readiness_source}")" -gt 0 ] && \
     [ "$(yq eval '.requirements | length' "${themis_spec_readiness_source}")" -gt 0 ] && \
     [ "$(yq eval '.acceptance_criteria | length' "${themis_spec_readiness_source}")" -gt 0 ] && \
     ! yq eval -e '.acceptance_criteria[] | select(.requirement_refs | length == 0)' "${themis_spec_readiness_source}" >/dev/null 2>&1 && \
     themis_spec_readiness_fields_complete "${themis_spec_readiness_source}"; then
    THEMIS_SPEC_CHECK_DESIGN=1
  fi

  themis_spec_readiness_count=0
  while IFS= read -r themis_spec_readiness_finding; do
    themis_spec_readiness_disposition=$(themis_spec_read_field adversarial_findings "${themis_spec_readiness_finding}" disposition "${themis_spec_readiness_source}")
    themis_spec_readiness_dimension=$(themis_spec_read_field adversarial_findings "${themis_spec_readiness_finding}" dimension "${themis_spec_readiness_source}")
    themis_spec_readiness_severity=$(themis_spec_read_field adversarial_findings "${themis_spec_readiness_finding}" severity "${themis_spec_readiness_source}")
    case "${themis_spec_readiness_disposition}" in
      cover)
        if [ "$(THEMIS_SPEC_OBJECT_ID=${themis_spec_readiness_finding} yq eval '.adversarial_findings[strenv(THEMIS_SPEC_OBJECT_ID)].resolution_refs | length' "${themis_spec_readiness_source}")" -eq 0 ]; then
          themis_spec_readiness_adversarial=0
        fi
        ;;
      accept)
        if [ "$(THEMIS_SPEC_OBJECT_ID=${themis_spec_readiness_finding} yq eval '.adversarial_findings[strenv(THEMIS_SPEC_OBJECT_ID)].risk_refs | length' "${themis_spec_readiness_source}")" -eq 0 ]; then
          themis_spec_readiness_adversarial=0
        fi
        ;;
      defer)
        themis_spec_readiness_count=$((themis_spec_readiness_count + 1))
        if [ "$(THEMIS_SPEC_OBJECT_ID=${themis_spec_readiness_finding} yq eval '.adversarial_findings[strenv(THEMIS_SPEC_OBJECT_ID)].risk_refs | length' "${themis_spec_readiness_source}")" -eq 0 ]; then
          themis_spec_readiness_adversarial=0
        fi
        if [ "${themis_spec_readiness_severity}" = critical ]; then
          case "${themis_spec_readiness_dimension}" in security_and_permissions|data_integrity) themis_spec_readiness_adversarial=0 ;; esac
        fi
        ;;
      *) themis_spec_readiness_adversarial=0 ;;
    esac
  done < <(yq eval -r '.adversarial_findings | keys | .[]' "${themis_spec_readiness_source}")
  themis_spec_readiness_limit=$(yq eval '.specification.adversarial_validation.deferral.max_per_spec' "${THEMIS_SPEC_POLICY}")
  if [ "${themis_spec_readiness_count}" -gt "${themis_spec_readiness_limit}" ]; then
    themis_spec_readiness_adversarial=0
  fi
  THEMIS_SPEC_CHECK_ADVERSARIAL=${themis_spec_readiness_adversarial}

  if themis_spec_semantic_consistency_complete "${themis_spec_readiness_source}"; then
    THEMIS_SPEC_CHECK_SELF=1
  fi

  if [ "$(yq eval -r '.approval.decision' "${themis_spec_readiness_source}")" = approved ] && \
     [ "$(yq eval -r '.approval.approved_by // ""' "${themis_spec_readiness_source}")" != '' ] && \
     [ "$(yq eval -r '.approval.approved_at // ""' "${themis_spec_readiness_source}")" != '' ] && \
     [ "$(yq eval -r '.approval.record' "${themis_spec_readiness_source}")" != '' ]; then
    THEMIS_SPEC_CHECK_APPROVAL=1
  fi

  if [ -n "${themis_spec_readiness_projection}" ] && themis_spec_check_projection "${themis_spec_readiness_source}" "${themis_spec_readiness_projection}"; then
    THEMIS_SPEC_CHECK_PROJECTION=1
  fi

  if [ "${THEMIS_SPEC_VALID}" -eq 1 ] && \
     [ "${THEMIS_SPEC_CHECK_INTENT}" -eq 1 ] && [ "${THEMIS_SPEC_CHECK_SCOPE}" -eq 1 ] && \
     [ "${THEMIS_SPEC_CHECK_CONTEXT}" -eq 1 ] && [ "${THEMIS_SPEC_CHECK_DESIGN}" -eq 1 ] && \
     [ "${THEMIS_SPEC_CHECK_ADVERSARIAL}" -eq 1 ] && [ "${THEMIS_SPEC_CHECK_SELF}" -eq 1 ] && \
     [ "${THEMIS_SPEC_CHECK_APPROVAL}" -eq 1 ] && [ "${THEMIS_SPEC_CHECK_PROJECTION}" -eq 1 ]; then
    THEMIS_SPEC_READY=1
  else
    THEMIS_SPEC_READY=0
  fi
}

# 执行 Draft 结构、对象和引用校验，并计算 readiness。
themis_spec_validate_internal() {
  local themis_spec_validate_source=$1
  local themis_spec_validate_projection=${2-}
  local themis_spec_validate_key
  local themis_spec_validate_collection
  local themis_spec_validate_value

  : >"${THEMIS_SPEC_ERROR_FILE}"
  THEMIS_SPEC_VALID=1
  THEMIS_SPEC_READY=0
  THEMIS_SPEC_PROJECTION_CURRENT=0
  THEMIS_SPEC_READINESS_FIELDS_CACHE_SOURCE=
  THEMIS_SPEC_READINESS_FIELDS_CACHE_SET=0
  THEMIS_SPEC_READINESS_FIELDS_CACHE_COMPLETE=0

  if [ ! -f "${themis_spec_validate_source}" ]; then
    themis_spec_add_error 'source.missing'
    themis_spec_compute_readiness "${THEMIS_SPEC_TEMPLATE}" ""
    return 1
  fi
  if ! yq eval '.' "${themis_spec_validate_source}" >/dev/null 2>&1; then
    themis_spec_add_error 'source.yaml_unreadable'
    return 1
  fi

  while IFS= read -r themis_spec_validate_key; do
    if ! THEMIS_SPEC_KEY=${themis_spec_validate_key} yq eval -e 'has(strenv(THEMIS_SPEC_KEY))' "${themis_spec_validate_source}" >/dev/null 2>&1; then
      themis_spec_add_error "top_level.required.${themis_spec_validate_key}"
    fi
  done < <(yq eval -r '.top_level.required[]' "${THEMIS_SPEC_SCHEMA}")

  while IFS= read -r themis_spec_validate_key; do
    if ! THEMIS_SPEC_KEY=${themis_spec_validate_key} yq eval -e '.top_level.allowed | contains([strenv(THEMIS_SPEC_KEY)])' "${THEMIS_SPEC_SCHEMA}" >/dev/null 2>&1; then
      themis_spec_add_error "top_level.unknown.${themis_spec_validate_key}"
    fi
  done < <(yq eval -r 'keys | .[]' "${themis_spec_validate_source}")

  themis_spec_expect_type "${themis_spec_validate_source}" '.id' '!!str' 'type.id' || true
  themis_spec_expect_type "${themis_spec_validate_source}" '.title' '!!str' 'type.title' || true
  themis_spec_expect_type "${themis_spec_validate_source}" '.status' '!!str' 'type.status' || true
  themis_spec_expect_type "${themis_spec_validate_source}" '.revision' '!!int' 'type.revision' || true
  for themis_spec_validate_key in created_at updated_at author; do
    themis_spec_expect_type "${themis_spec_validate_source}" ".${themis_spec_validate_key}" '!!str' "type.${themis_spec_validate_key}" || true
  done
  for themis_spec_validate_key in complexity review context_basis intent scope evidence assumptions options decisions requirements interfaces contracts invariants acceptance_criteria adversarial_findings risks diagrams rollback approval; do
    themis_spec_expect_type "${themis_spec_validate_source}" ".${themis_spec_validate_key}" '!!map' "type.${themis_spec_validate_key}" || true
  done
  themis_spec_validate_fixed_map "${themis_spec_validate_source}" complexity '.complexity' || true
  themis_spec_validate_fixed_map "${themis_spec_validate_source}" review '.review' || true
  themis_spec_validate_fixed_map "${themis_spec_validate_source}" review_summary '.review.summary' || true
  themis_spec_validate_fixed_map "${themis_spec_validate_source}" context_basis '.context_basis' || true
  themis_spec_validate_fixed_map "${themis_spec_validate_source}" intent '.intent' || true
  themis_spec_validate_fixed_map "${themis_spec_validate_source}" rollback '.rollback' || true
  themis_spec_validate_fixed_map "${themis_spec_validate_source}" approval '.approval' || true

  themis_spec_validate_value=$(yq eval -r '.id // ""' "${themis_spec_validate_source}")
  case "${themis_spec_validate_value}" in
    ''|*[!a-z0-9._-]*|[!a-z0-9]*) themis_spec_add_error 'value.id' ;;
  esac
  [ -n "$(yq eval -r '.title // ""' "${themis_spec_validate_source}")" ] || themis_spec_add_error 'value.title'
  themis_spec_validate_value=$(yq eval -r '.status // ""' "${themis_spec_validate_source}")
  themis_spec_protocol_enum_contains status "${themis_spec_validate_value}" || themis_spec_add_error 'value.status'
  [ "$(yq eval '.revision // 0' "${themis_spec_validate_source}")" -ge 1 ] 2>/dev/null || themis_spec_add_error 'value.revision'
  themis_spec_validate_value=$(yq eval -r '.complexity.level // ""' "${themis_spec_validate_source}")
  themis_spec_protocol_enum_contains complexity_level "${themis_spec_validate_value}" || themis_spec_add_error 'value.complexity.level'

  themis_spec_expect_type "${themis_spec_validate_source}" '.complexity.confirmed' '!!bool' 'type.complexity.confirmed' || true
  themis_spec_expect_type "${themis_spec_validate_source}" '.complexity.rationale' '!!str' 'type.complexity.rationale' || true
  themis_spec_expect_nullable_string "${themis_spec_validate_source}" '.complexity.override_reason' 'type.complexity.override_reason' || true
  themis_spec_expect_type "${themis_spec_validate_source}" '.review.summary' '!!map' 'type.review.summary' || true
  for themis_spec_validate_key in included excluded blockers; do
    themis_spec_expect_type "${themis_spec_validate_source}" ".review.summary.${themis_spec_validate_key}" '!!seq' "type.review.summary.${themis_spec_validate_key}" || true
  done
  for themis_spec_validate_key in request intent root_cause success; do
    themis_spec_expect_type "${themis_spec_validate_source}" ".review.summary.${themis_spec_validate_key}" '!!str' "type.review.summary.${themis_spec_validate_key}" || true
  done
  themis_spec_expect_type "${themis_spec_validate_source}" '.review.no_diagram_reason' '!!str' 'type.review.no_diagram_reason' || true
  themis_spec_validate_value=$(yq eval -r '.context_basis.disposition // ""' "${themis_spec_validate_source}")
  themis_spec_protocol_enum_contains context_disposition "${themis_spec_validate_value}" || themis_spec_add_error 'value.context_basis.disposition'
  themis_spec_validate_context_basis "${themis_spec_validate_source}"
  for themis_spec_validate_key in request outcome root_cause; do
    themis_spec_expect_type "${themis_spec_validate_source}" ".intent.${themis_spec_validate_key}" '!!str' "type.intent.${themis_spec_validate_key}" || true
  done
  themis_spec_expect_type "${themis_spec_validate_source}" '.rollback.triggers' '!!seq' 'type.rollback.triggers' || true
  themis_spec_expect_type "${themis_spec_validate_source}" '.rollback.steps' '!!seq' 'type.rollback.steps' || true
  themis_spec_expect_type "${themis_spec_validate_source}" '.rollback.impact' '!!str' 'type.rollback.impact' || true
  themis_spec_validate_value=$(yq eval -r '.approval.decision // ""' "${themis_spec_validate_source}")
  themis_spec_protocol_enum_contains approval_decision "${themis_spec_validate_value}" || themis_spec_add_error 'value.approval.decision'
  themis_spec_expect_nullable_string "${themis_spec_validate_source}" '.approval.approved_by' 'type.approval.approved_by' || true
  themis_spec_expect_nullable_string "${themis_spec_validate_source}" '.approval.approved_at' 'type.approval.approved_at' || true
  themis_spec_expect_type "${themis_spec_validate_source}" '.approval.record' '!!str' 'type.approval.record' || true

  while IFS= read -r themis_spec_validate_collection; do
    if yq eval -e ".${themis_spec_validate_collection} | type == \"!!map\"" "${themis_spec_validate_source}" >/dev/null 2>&1; then
      themis_spec_validate_collection "${themis_spec_validate_collection}" "${themis_spec_validate_source}"
    fi
  done < <(yq eval -r '.collections | keys | .[]' "${THEMIS_SPEC_SCHEMA}")

  themis_spec_validate_review_projection_contract "${themis_spec_validate_source}"
  themis_spec_compute_readiness "${themis_spec_validate_source}" "${themis_spec_validate_projection}"
  [ "${THEMIS_SPEC_VALID}" -eq 1 ]
}

# 输出单个稳定 check 项。
themis_spec_print_check() {
  local themis_spec_check_id=$1
  local themis_spec_check_value=$2
  local themis_spec_check_status=fail
  [ "${themis_spec_check_value}" -eq 1 ] && themis_spec_check_status=pass
  printf '{"id":"%s","status":"%s"}' "${themis_spec_check_id}" "${themis_spec_check_status}"
}

# 输出 validator 的唯一机器接口。
themis_spec_print_validation_json() {
  local themis_spec_json_first=1
  local themis_spec_json_error
  local themis_spec_json_valid=false
  local themis_spec_json_ready=false
  local themis_spec_json_projection=false
  [ "${THEMIS_SPEC_VALID}" -eq 1 ] && themis_spec_json_valid=true
  [ "${THEMIS_SPEC_READY}" -eq 1 ] && themis_spec_json_ready=true
  [ "${THEMIS_SPEC_PROJECTION_CURRENT}" -eq 1 ] && themis_spec_json_projection=true

  printf '{"valid":%s,"ready":%s,"projection_current":%s,"checks":[' "${themis_spec_json_valid}" "${themis_spec_json_ready}" "${themis_spec_json_projection}"
  themis_spec_print_check spec_intent_complete "${THEMIS_SPEC_CHECK_INTENT:-0}"
  printf ','
  themis_spec_print_check spec_scope_complexity_confirmed "${THEMIS_SPEC_CHECK_SCOPE:-0}"
  printf ','
  themis_spec_print_check spec_context_complete "${THEMIS_SPEC_CHECK_CONTEXT:-0}"
  printf ','
  themis_spec_print_check spec_design_acceptance_complete "${THEMIS_SPEC_CHECK_DESIGN:-0}"
  printf ','
  themis_spec_print_check spec_adversarial_resolved "${THEMIS_SPEC_CHECK_ADVERSARIAL:-0}"
  printf ','
  themis_spec_print_check spec_self_check_passed "${THEMIS_SPEC_CHECK_SELF:-0}"
  printf ','
  themis_spec_print_check spec_user_approval_recorded "${THEMIS_SPEC_CHECK_APPROVAL:-0}"
  printf ','
  themis_spec_print_check spec_projection_current "${THEMIS_SPEC_CHECK_PROJECTION:-0}"
  printf '],"errors":['
  while IFS= read -r themis_spec_json_error; do
    [ -n "${themis_spec_json_error}" ] || continue
    if [ "${themis_spec_json_first}" -eq 0 ]; then printf ','; fi
    themis_spec_json_first=0
    printf '"%s"' "$(themis_spec_json_escape "${themis_spec_json_error}")"
  done <"${THEMIS_SPEC_ERROR_FILE}"
  printf ']}\n'
}

# 将 YAML 序列压缩成只用于展示的单行文本。
themis_spec_join_sequence() {
  yq eval -r "$1 | map(tostring) | join(\"; \")" "$2"
}

# Markdown 表格单元格只做排版转义，不改变语义。
themis_spec_markdown_cell() {
  local themis_spec_cell=${1-}
  themis_spec_cell=${themis_spec_cell//|/\\|}
  themis_spec_cell=${themis_spec_cell//$'\r'/}
  themis_spec_cell=${themis_spec_cell//$'\n'/<br>}
  printf '%s' "${themis_spec_cell}"
}

# 从已通过结构校验的 YAML 生成确定性正文。
themis_spec_render_body() {
  local themis_spec_render_source=$1
  local themis_spec_render_body=$2
  local themis_spec_render_id
  local themis_spec_render_refs
  local themis_spec_render_value

  : >"${themis_spec_render_body}"
  {
    printf '%s\n\n' '<!-- DO NOT EDIT: regenerate from spec.yaml -->'
    printf '# Spec: %s\n\n' "$(yq eval -r '.title' "${themis_spec_render_source}")"
    printf '## Review Summary\n\n'
    printf -- '- **Request:** %s\n' "$(yq eval -r '.review.summary.request' "${themis_spec_render_source}")"
    printf -- '- **Intent:** %s\n' "$(yq eval -r '.review.summary.intent' "${themis_spec_render_source}")"
    printf -- '- **Root cause:** %s\n' "$(yq eval -r '.review.summary.root_cause' "${themis_spec_render_source}")"
    printf -- '- **Included:** %s\n' "$(themis_spec_join_sequence '.review.summary.included' "${themis_spec_render_source}")"
    printf -- '- **Excluded:** %s\n' "$(themis_spec_join_sequence '.review.summary.excluded' "${themis_spec_render_source}")"
    printf -- '- **Success:** %s\n' "$(yq eval -r '.review.summary.success' "${themis_spec_render_source}")"
    printf -- '- **Complexity:** %s\n' "$(yq eval -r '.complexity.level' "${themis_spec_render_source}")"
    printf -- '- **Blockers:** %s\n\n' "$(themis_spec_join_sequence '.review.summary.blockers' "${themis_spec_render_source}")"

    printf '## Architecture at a Glance\n\n'
    if [ "$(yq eval '.review.primary_diagrams | length' "${themis_spec_render_source}")" -eq 0 ]; then
      printf '%s\n\n' "$(yq eval -r '.review.no_diagram_reason' "${themis_spec_render_source}")"
    else
      while IFS= read -r themis_spec_render_id; do
        printf '### %s — %s\n\n' "${themis_spec_render_id}" "$(themis_spec_read_field diagrams "${themis_spec_render_id}" title "${themis_spec_render_source}")"
        printf '%s\n\n' "$(themis_spec_read_field diagrams "${themis_spec_render_id}" purpose "${themis_spec_render_source}")"
        printf '%s\n' '```mermaid'
        themis_spec_read_field diagrams "${themis_spec_render_id}" content "${themis_spec_render_source}"
        printf '%s\n\n' '```'
      done < <(yq eval -r '.review.primary_diagrams[]' "${themis_spec_render_source}")
    fi

    printf '## Key Decisions\n\n'
    printf '| ID | Decision | Rationale | Tradeoffs |\n|---|---|---|---|\n'
    while IFS= read -r themis_spec_render_id; do
      printf '| %s | %s | %s | %s |\n' \
        "${themis_spec_render_id}" \
        "$(themis_spec_markdown_cell "$(themis_spec_read_field decisions "${themis_spec_render_id}" summary "${themis_spec_render_source}")")" \
        "$(themis_spec_markdown_cell "$(themis_spec_read_field decisions "${themis_spec_render_id}" rationale "${themis_spec_render_source}")")" \
        "$(themis_spec_markdown_cell "$(themis_spec_read_field decisions "${themis_spec_render_id}" tradeoffs "${themis_spec_render_source}")")"
    done < <(yq eval -r '.review.primary_decisions[]' "${themis_spec_render_source}")
    printf '\n'

    printf '## Contracts and Invariants\n\n'
    printf '### Contracts\n\n| ID | Contract | Applies to | Requirements |\n|---|---|---|---|\n'
    while IFS= read -r themis_spec_render_id; do
      themis_spec_render_refs=$(THEMIS_SPEC_OBJECT_ID=${themis_spec_render_id} yq eval -r '.contracts[strenv(THEMIS_SPEC_OBJECT_ID)].applies_to | join(", ")' "${themis_spec_render_source}")
      themis_spec_render_value=$(THEMIS_SPEC_OBJECT_ID=${themis_spec_render_id} yq eval -r '.contracts[strenv(THEMIS_SPEC_OBJECT_ID)].requirement_refs | join(", ")' "${themis_spec_render_source}")
      printf '| %s | %s | %s | %s |\n' "${themis_spec_render_id}" "$(themis_spec_markdown_cell "$(themis_spec_read_field contracts "${themis_spec_render_id}" statement "${themis_spec_render_source}")")" "${themis_spec_render_refs}" "${themis_spec_render_value}"
    done < <(yq eval -r '.contracts | keys | .[]' "${themis_spec_render_source}")
    printf '\n### Invariants\n\n| ID | Invariant | Scope | Requirements |\n|---|---|---|---|\n'
    while IFS= read -r themis_spec_render_id; do
      themis_spec_render_refs=$(THEMIS_SPEC_OBJECT_ID=${themis_spec_render_id} yq eval -r '.invariants[strenv(THEMIS_SPEC_OBJECT_ID)].scope_refs | join(", ")' "${themis_spec_render_source}")
      themis_spec_render_value=$(THEMIS_SPEC_OBJECT_ID=${themis_spec_render_id} yq eval -r '.invariants[strenv(THEMIS_SPEC_OBJECT_ID)].requirement_refs | join(", ")' "${themis_spec_render_source}")
      printf '| %s | %s | %s | %s |\n' "${themis_spec_render_id}" "$(themis_spec_markdown_cell "$(themis_spec_read_field invariants "${themis_spec_render_id}" statement "${themis_spec_render_source}")")" "${themis_spec_render_refs}" "${themis_spec_render_value}"
    done < <(yq eval -r '.invariants | keys | .[]' "${themis_spec_render_source}")
    printf '\n'

    printf '## Acceptance Criteria\n\n'
    while IFS= read -r themis_spec_render_id; do
      themis_spec_render_refs=$(THEMIS_SPEC_OBJECT_ID=${themis_spec_render_id} yq eval -r '.acceptance_criteria[strenv(THEMIS_SPEC_OBJECT_ID)].requirement_refs | join(", ")' "${themis_spec_render_source}")
      printf '### %s\n\n' "${themis_spec_render_id}"
      printf -- '- **Requirements:** %s\n' "${themis_spec_render_refs}"
      printf -- '- **Given:** %s\n' "$(themis_spec_read_field acceptance_criteria "${themis_spec_render_id}" given "${themis_spec_render_source}")"
      printf -- '- **When:** %s\n' "$(themis_spec_read_field acceptance_criteria "${themis_spec_render_id}" when "${themis_spec_render_source}")"
      printf -- '- **Then:** %s\n' "$(themis_spec_read_field acceptance_criteria "${themis_spec_render_id}" 'then' "${themis_spec_render_source}")"
      printf -- '- **Verification:** %s\n\n' "$(themis_spec_read_field acceptance_criteria "${themis_spec_render_id}" verification "${themis_spec_render_source}")"
    done < <(yq eval -r '.acceptance_criteria | keys | .[]' "${themis_spec_render_source}")

    printf '## Risks, Limitations, and Rollback\n\n'
    printf '| ID | Severity | Risk | Mitigation | Status | Owner |\n|---|---|---|---|---|---|\n'
    while IFS= read -r themis_spec_render_id; do
      printf '| %s | %s | %s | %s | %s | %s |\n' \
        "${themis_spec_render_id}" \
        "$(themis_spec_read_field risks "${themis_spec_render_id}" severity "${themis_spec_render_source}")" \
        "$(themis_spec_markdown_cell "$(themis_spec_read_field risks "${themis_spec_render_id}" statement "${themis_spec_render_source}")")" \
        "$(themis_spec_markdown_cell "$(themis_spec_read_field risks "${themis_spec_render_id}" mitigation "${themis_spec_render_source}")")" \
        "$(themis_spec_read_field risks "${themis_spec_render_id}" status "${themis_spec_render_source}")" \
        "$(themis_spec_markdown_cell "$(themis_spec_read_field risks "${themis_spec_render_id}" owner "${themis_spec_render_source}")")"
    done < <(yq eval -r '.review.primary_risks[]' "${themis_spec_render_source}")
    printf '\n### Rollback\n\n'
    printf -- '- **Triggers:** %s\n' "$(themis_spec_join_sequence '.rollback.triggers' "${themis_spec_render_source}")"
    printf -- '- **Steps:** %s\n' "$(themis_spec_join_sequence '.rollback.steps' "${themis_spec_render_source}")"
    printf -- '- **Impact:** %s\n\n' "$(yq eval -r '.rollback.impact' "${themis_spec_render_source}")"

    printf '## Approval\n\n'
    printf -- '- **Decision:** %s\n' "$(yq eval -r '.approval.decision' "${themis_spec_render_source}")"
    printf -- '- **Approved by:** %s\n' "$(yq eval -r '.approval.approved_by // ""' "${themis_spec_render_source}")"
    printf -- '- **Approved at:** %s\n' "$(yq eval -r '.approval.approved_at // ""' "${themis_spec_render_source}")"
    printf -- '- **Record:** %s\n\n' "$(yq eval -r '.approval.record' "${themis_spec_render_source}")"

    printf '## Appendix\n\n'
    printf '### Evidence\n\n| ID | Kind | Source | Summary |\n|---|---|---|---|\n'
    while IFS= read -r themis_spec_render_id; do
      printf '| %s | %s | %s | %s |\n' "${themis_spec_render_id}" "$(themis_spec_read_field evidence "${themis_spec_render_id}" kind "${themis_spec_render_source}")" "$(themis_spec_markdown_cell "$(themis_spec_read_field evidence "${themis_spec_render_id}" source "${themis_spec_render_source}")")" "$(themis_spec_markdown_cell "$(themis_spec_read_field evidence "${themis_spec_render_id}" summary "${themis_spec_render_source}")")"
    done < <(yq eval -r '.evidence | keys | .[]' "${themis_spec_render_source}")
    printf '\n### Assumptions\n\n| ID | Assumption | Validation | Status |\n|---|---|---|---|\n'
    while IFS= read -r themis_spec_render_id; do
      printf '| %s | %s | %s | %s |\n' "${themis_spec_render_id}" "$(themis_spec_markdown_cell "$(themis_spec_read_field assumptions "${themis_spec_render_id}" statement "${themis_spec_render_source}")")" "$(themis_spec_markdown_cell "$(themis_spec_read_field assumptions "${themis_spec_render_id}" validation "${themis_spec_render_source}")")" "$(themis_spec_read_field assumptions "${themis_spec_render_id}" status "${themis_spec_render_source}")"
    done < <(yq eval -r '.assumptions | keys | .[]' "${themis_spec_render_source}")
    printf '\n### Adversarial Trace\n\n| ID | Dimension | Severity | ACs | Disposition | Risks |\n|---|---|---|---|---|---|\n'
    while IFS= read -r themis_spec_render_id; do
      themis_spec_render_refs=$(THEMIS_SPEC_OBJECT_ID=${themis_spec_render_id} yq eval -r '.adversarial_findings[strenv(THEMIS_SPEC_OBJECT_ID)].ac_refs | join(", ")' "${themis_spec_render_source}")
      themis_spec_render_value=$(THEMIS_SPEC_OBJECT_ID=${themis_spec_render_id} yq eval -r '.adversarial_findings[strenv(THEMIS_SPEC_OBJECT_ID)].risk_refs | join(", ")' "${themis_spec_render_source}")
      printf '| %s | %s | %s | %s | %s | %s |\n' "${themis_spec_render_id}" "$(themis_spec_read_field adversarial_findings "${themis_spec_render_id}" dimension "${themis_spec_render_source}")" "$(themis_spec_read_field adversarial_findings "${themis_spec_render_id}" severity "${themis_spec_render_source}")" "${themis_spec_render_refs}" "$(themis_spec_read_field adversarial_findings "${themis_spec_render_id}" disposition "${themis_spec_render_source}")" "${themis_spec_render_value}"
    done < <(yq eval -r '.adversarial_findings | keys | .[]' "${themis_spec_render_source}")
    printf '\n### Object Index\n\n'
    for themis_spec_render_value in scope evidence assumptions options decisions requirements interfaces contracts invariants acceptance_criteria adversarial_findings risks diagrams; do
      printf -- '- **%s:** %s\n' "${themis_spec_render_value}" "$(yq eval -r ".${themis_spec_render_value} | keys | join(\", \")" "${themis_spec_render_source}")"
    done
  } >>"${themis_spec_render_body}"
}

# 写出带 OID marker 的完整 Human 投影，已验证的 staging 可跳过重复结构校验。
themis_spec_render_internal() {
  local themis_spec_render_source=$1
  local themis_spec_render_output=$2
  local themis_spec_render_validated=${3:-0}
  local themis_spec_render_output_directory
  local themis_spec_render_temp
  local themis_spec_render_body
  local themis_spec_render_source_oid
  local themis_spec_render_body_oid
  local themis_spec_render_source_directory
  local themis_spec_render_source_path
  local themis_spec_render_output_path

  themis_spec_render_output_directory=$(dirname -- "${themis_spec_render_output}")
  [ -d "${themis_spec_render_output_directory}" ] || return 1
  themis_spec_render_source_directory=$(CDPATH='' cd -- "$(dirname -- "${themis_spec_render_source}")" && pwd) || return 1
  themis_spec_render_output_directory=$(CDPATH='' cd -- "${themis_spec_render_output_directory}" && pwd) || return 1
  themis_spec_render_source_path="${themis_spec_render_source_directory}/$(basename -- "${themis_spec_render_source}")"
  themis_spec_render_output_path="${themis_spec_render_output_directory}/$(basename -- "${themis_spec_render_output}")"
  if [ "${themis_spec_render_source_path}" = "${themis_spec_render_output_path}" ] || \
     { [ -e "${themis_spec_render_output_path}" ] && [ "${themis_spec_render_source_path}" -ef "${themis_spec_render_output_path}" ]; }; then
    return 1
  fi

  themis_spec_require_git || return 1
  if [ "${themis_spec_render_validated}" -ne 1 ]; then
    themis_spec_validate_internal "${themis_spec_render_source_path}" "" || return 1
  fi
  themis_spec_render_body="${THEMIS_SPEC_TEMP_ROOT}/render-body-$$"
  themis_spec_render_temp=$(mktemp "${themis_spec_render_output_directory}/.themis-spec-render.XXXXXX") || return 1
  themis_spec_render_body "${themis_spec_render_source}" "${themis_spec_render_body}" || {
    rm -f "${themis_spec_render_temp}" "${themis_spec_render_body}"
    return 1
  }
  themis_spec_render_source_oid=$(git hash-object -- "${themis_spec_render_source}") || return 1
  themis_spec_render_body_oid=$(git hash-object -- "${themis_spec_render_body}") || return 1
  {
    printf '<!-- themis-projection source=spec.yaml source_oid=%s body_oid=%s -->\n' "${themis_spec_render_source_oid}" "${themis_spec_render_body_oid}"
    cat "${themis_spec_render_body}"
  } >"${themis_spec_render_temp}" || {
    rm -f "${themis_spec_render_temp}" "${themis_spec_render_body}"
    return 1
  }
  rm -f "${themis_spec_render_body}"
  mv -f "${themis_spec_render_temp}" "${themis_spec_render_output}"
}

# 从 backup 复制恢复 canonical pair；复制失败时 backup 仍完整可恢复。
themis_spec_restore_pair() {
  local themis_spec_restore_target=$1
  local themis_spec_restore_backup=$2
  local themis_spec_restore_had_source=$3
  local themis_spec_restore_had_projection=$4
  local themis_spec_restore_source_temp="${themis_spec_restore_target}/.themis-spec-restore-yaml-$$"
  local themis_spec_restore_projection_temp="${themis_spec_restore_target}/.themis-spec-restore-md-$$"

  rm -f "${themis_spec_restore_source_temp}" "${themis_spec_restore_projection_temp}"
  if [ "${themis_spec_restore_had_source}" -eq 1 ]; then
    cp "${themis_spec_restore_backup}/spec.yaml" "${themis_spec_restore_source_temp}" || return 1
  fi
  if [ "${themis_spec_restore_had_projection}" -eq 1 ]; then
    if [ "${THEMIS_SPEC_TEST_FAIL_RESTORE_PROJECTION:-0}" -eq 1 ] || \
       ! cp "${themis_spec_restore_backup}/spec.md" "${themis_spec_restore_projection_temp}"; then
      rm -f "${themis_spec_restore_source_temp}" "${themis_spec_restore_projection_temp}"
      return 1
    fi
  fi

  rm -f "${themis_spec_restore_target}/spec.yaml" "${themis_spec_restore_target}/spec.md"
  if [ "${themis_spec_restore_had_source}" -eq 1 ]; then
    mv "${themis_spec_restore_source_temp}" "${themis_spec_restore_target}/spec.yaml" || return 1
  fi
  if [ "${themis_spec_restore_had_projection}" -eq 1 ]; then
    mv "${themis_spec_restore_projection_temp}" "${themis_spec_restore_target}/spec.md" || return 1
  fi
  return 0
}

# 恢复成功后清理 staging；恢复失败则保留完整 backup 并报告路径。
themis_spec_publish_recover() {
  local themis_spec_recover_target=$1
  local themis_spec_recover_backup=$2
  local themis_spec_recover_had_source=$3
  local themis_spec_recover_had_projection=$4
  local themis_spec_recover_stage=$5

  if themis_spec_restore_pair "${themis_spec_recover_target}" "${themis_spec_recover_backup}" "${themis_spec_recover_had_source}" "${themis_spec_recover_had_projection}"; then
    rm -rf "${themis_spec_recover_stage}"
    return 0
  fi
  printf '{"status":"failure","error":"pair_restore_failed","recovery_path":"%s"}\n' "${themis_spec_recover_stage}" >&2
  return 1
}

# 替换前失败只清理 staging，并恢复顶层信号处理。
themis_spec_publish_abort_before_replace() {
  local themis_spec_abort_stage=$1
  trap '' HUP INT TERM
  THEMIS_SPEC_PUBLISH_ACTIVE=0
  rm -rf "${themis_spec_abort_stage}"
  trap 'themis_spec_exit_on_signal' HUP INT TERM
  return 1
}

# 发布窗口收到信号时，仅在替换已开始后恢复；否则保持 canonical pair 原样。
# shellcheck disable=SC2329
themis_spec_publish_signal() {
  trap '' HUP INT TERM
  if [ "${THEMIS_SPEC_PUBLISH_ACTIVE}" -eq 1 ]; then
    if [ "${THEMIS_SPEC_PUBLISH_REPLACEMENT_STARTED}" -eq 1 ] && \
       [ ! -f "${THEMIS_SPEC_PUBLISH_STAGE}/spec.yaml" ]; then
      themis_spec_publish_recover \
        "${THEMIS_SPEC_PUBLISH_TARGET}" \
        "${THEMIS_SPEC_PUBLISH_BACKUP}" \
        "${THEMIS_SPEC_PUBLISH_HAD_SOURCE}" \
        "${THEMIS_SPEC_PUBLISH_HAD_PROJECTION}" \
        "${THEMIS_SPEC_PUBLISH_STAGE}" || true
    else
      rm -rf "${THEMIS_SPEC_PUBLISH_STAGE}"
    fi
  fi
  exit 1
}

# staging、配对校验和恢复共同保证失败时不留下半套活动工件。
themis_spec_publish() {
  local themis_spec_publish_candidate=$1
  local themis_spec_publish_target=$2
  local themis_spec_publish_parent
  local themis_spec_publish_stage
  local themis_spec_publish_backup
  local themis_spec_publish_had_source=0
  local themis_spec_publish_had_projection=0
  local themis_spec_publish_id
  local themis_spec_publish_target_id

  [ -f "${themis_spec_publish_candidate}" ] || return 1
  themis_spec_publish_parent=$(dirname -- "${themis_spec_publish_target}")
  [ -d "${themis_spec_publish_parent}" ] || return 1
  if [ -e "${themis_spec_publish_target}" ] && [ ! -d "${themis_spec_publish_target}" ]; then return 1; fi
  mkdir -p "${themis_spec_publish_target}" || return 1
  themis_spec_publish_target=$(CDPATH='' cd -- "${themis_spec_publish_target}" && pwd) || return 1

  if { [ -f "${themis_spec_publish_target}/spec.yaml" ] && [ ! -f "${themis_spec_publish_target}/spec.md" ]; } || \
     { [ ! -f "${themis_spec_publish_target}/spec.yaml" ] && [ -f "${themis_spec_publish_target}/spec.md" ]; }; then
    return 1
  fi

  trap '' HUP INT TERM
  themis_spec_publish_stage=$(mktemp -d "${themis_spec_publish_parent}/.themis-spec-publish.XXXXXX") || {
    trap 'themis_spec_exit_on_signal' HUP INT TERM
    return 1
  }
  themis_spec_publish_backup="${themis_spec_publish_stage}/backup"

  THEMIS_SPEC_PUBLISH_ACTIVE=1
  THEMIS_SPEC_PUBLISH_TARGET=${themis_spec_publish_target}
  THEMIS_SPEC_PUBLISH_BACKUP=${themis_spec_publish_backup}
  THEMIS_SPEC_PUBLISH_STAGE=${themis_spec_publish_stage}
  THEMIS_SPEC_PUBLISH_HAD_SOURCE=0
  THEMIS_SPEC_PUBLISH_HAD_PROJECTION=0
  THEMIS_SPEC_PUBLISH_REPLACEMENT_STARTED=0
  trap 'themis_spec_publish_signal' HUP INT TERM

  mkdir "${themis_spec_publish_backup}" || themis_spec_publish_abort_before_replace "${themis_spec_publish_stage}" || return 1

  cp "${themis_spec_publish_candidate}" "${themis_spec_publish_stage}/spec.yaml" || themis_spec_publish_abort_before_replace "${themis_spec_publish_stage}" || return 1

  themis_spec_validate_internal "${themis_spec_publish_stage}/spec.yaml" "" || themis_spec_publish_abort_before_replace "${themis_spec_publish_stage}" || return 1
  themis_spec_publish_id=$(yq eval -r '.id' "${themis_spec_publish_stage}/spec.yaml")
  themis_spec_publish_target_id=$(basename -- "${themis_spec_publish_target}")
  if [ "${themis_spec_publish_id}" != "${themis_spec_publish_target_id}" ]; then
    themis_spec_publish_abort_before_replace "${themis_spec_publish_stage}"
    return 1
  fi
  if [ "${THEMIS_SPEC_TEST_FAIL_RENDER:-0}" -eq 1 ]; then
    themis_spec_publish_abort_before_replace "${themis_spec_publish_stage}"
    return 1
  fi
  themis_spec_render_internal "${themis_spec_publish_stage}/spec.yaml" "${themis_spec_publish_stage}/spec.md" 1 || themis_spec_publish_abort_before_replace "${themis_spec_publish_stage}" || return 1
  themis_spec_validate_internal "${themis_spec_publish_stage}/spec.yaml" "${themis_spec_publish_stage}/spec.md" || themis_spec_publish_abort_before_replace "${themis_spec_publish_stage}" || return 1
  [ "${THEMIS_SPEC_PROJECTION_CURRENT}" -eq 1 ] || themis_spec_publish_abort_before_replace "${themis_spec_publish_stage}" || return 1

  if [ -f "${themis_spec_publish_target}/spec.yaml" ]; then
    themis_spec_publish_had_source=1
    cp "${themis_spec_publish_target}/spec.yaml" "${themis_spec_publish_backup}/spec.yaml" || themis_spec_publish_abort_before_replace "${themis_spec_publish_stage}" || return 1
    THEMIS_SPEC_PUBLISH_HAD_SOURCE=1
  fi
  if [ -f "${themis_spec_publish_target}/spec.md" ]; then
    themis_spec_publish_had_projection=1
    if [ "${THEMIS_SPEC_TEST_FAIL_PROJECTION_BACKUP:-0}" -eq 1 ] || \
       ! cp "${themis_spec_publish_target}/spec.md" "${themis_spec_publish_backup}/spec.md"; then
      themis_spec_publish_abort_before_replace "${themis_spec_publish_stage}"
      return 1
    fi
    THEMIS_SPEC_PUBLISH_HAD_PROJECTION=1
  fi

  if [ "${THEMIS_SPEC_TEST_FAIL_AFTER_BACKUP:-0}" -eq 1 ]; then
    themis_spec_publish_abort_before_replace "${themis_spec_publish_stage}"
    return 1
  fi

  THEMIS_SPEC_PUBLISH_ACTIVE=1
  THEMIS_SPEC_PUBLISH_TARGET=${themis_spec_publish_target}
  THEMIS_SPEC_PUBLISH_BACKUP=${themis_spec_publish_backup}
  THEMIS_SPEC_PUBLISH_STAGE=${themis_spec_publish_stage}
  THEMIS_SPEC_PUBLISH_HAD_SOURCE=${themis_spec_publish_had_source}
  THEMIS_SPEC_PUBLISH_HAD_PROJECTION=${themis_spec_publish_had_projection}
  THEMIS_SPEC_PUBLISH_REPLACEMENT_STARTED=1
  trap 'themis_spec_publish_signal' HUP INT TERM
  if [ "${THEMIS_SPEC_TEST_INTERRUPT_BEFORE_SOURCE:-0}" -eq 1 ]; then
    themis_spec_publish_signal
  fi

  if ! mv "${themis_spec_publish_stage}/spec.yaml" "${themis_spec_publish_target}/spec.yaml"; then
    trap '' HUP INT TERM
    THEMIS_SPEC_PUBLISH_ACTIVE=0
    themis_spec_publish_recover "${themis_spec_publish_target}" "${themis_spec_publish_backup}" "${themis_spec_publish_had_source}" "${themis_spec_publish_had_projection}" "${themis_spec_publish_stage}" || true
    trap 'themis_spec_exit_on_signal' HUP INT TERM
    return 1
  fi
  if [ "${THEMIS_SPEC_TEST_INTERRUPT_AFTER_SOURCE:-0}" -eq 1 ]; then
    themis_spec_publish_signal
  fi
  if [ "${THEMIS_SPEC_TEST_FAIL_AFTER_SOURCE:-0}" -eq 1 ] || ! mv "${themis_spec_publish_stage}/spec.md" "${themis_spec_publish_target}/spec.md"; then
    trap '' HUP INT TERM
    THEMIS_SPEC_PUBLISH_ACTIVE=0
    themis_spec_publish_recover "${themis_spec_publish_target}" "${themis_spec_publish_backup}" "${themis_spec_publish_had_source}" "${themis_spec_publish_had_projection}" "${themis_spec_publish_stage}" || true
    trap 'themis_spec_exit_on_signal' HUP INT TERM
    return 1
  fi

  if ! themis_spec_validate_internal "${themis_spec_publish_target}/spec.yaml" "${themis_spec_publish_target}/spec.md" || [ "${THEMIS_SPEC_PROJECTION_CURRENT}" -ne 1 ]; then
    trap '' HUP INT TERM
    THEMIS_SPEC_PUBLISH_ACTIVE=0
    themis_spec_publish_recover "${themis_spec_publish_target}" "${themis_spec_publish_backup}" "${themis_spec_publish_had_source}" "${themis_spec_publish_had_projection}" "${themis_spec_publish_stage}" || true
    trap 'themis_spec_exit_on_signal' HUP INT TERM
    return 1
  fi

  trap '' HUP INT TERM
  THEMIS_SPEC_PUBLISH_ACTIVE=0
  rm -rf "${themis_spec_publish_stage}"
  trap 'themis_spec_exit_on_signal' HUP INT TERM
  printf '{"status":"published","spec_id":"%s","valid":true,"ready":%s,"projection_current":true}\n' \
    "$(themis_spec_json_escape "${themis_spec_publish_id}")" "$([ "${THEMIS_SPEC_READY}" -eq 1 ] && printf true || printf false)"
  return 0
}

# 从脚本位置定位只读 Core 协议与策略。
THEMIS_SPEC_SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd) || exit 1
THEMIS_SPEC_CORE_ROOT=$(CDPATH='' cd -- "${THEMIS_SPEC_SCRIPT_DIR}/../.." && pwd) || exit 1
THEMIS_SPEC_SCHEMA="${THEMIS_SPEC_CORE_ROOT}/protocols/artifact/spec-schema.yaml"
THEMIS_SPEC_PROJECTION_PROTOCOL="${THEMIS_SPEC_CORE_ROOT}/protocols/artifact/spec-projection.yaml"
THEMIS_SPEC_POLICY="${THEMIS_SPEC_CORE_ROOT}/policies/specification.yaml"
THEMIS_SPEC_TEMPLATE="${THEMIS_SPEC_CORE_ROOT}/templates/spec.yaml"

for THEMIS_SPEC_REQUIRED_FILE in "${THEMIS_SPEC_SCHEMA}" "${THEMIS_SPEC_PROJECTION_PROTOCOL}" "${THEMIS_SPEC_POLICY}" "${THEMIS_SPEC_TEMPLATE}"; do
  if [ ! -f "${THEMIS_SPEC_REQUIRED_FILE}" ]; then
    printf '%s\n' "Themis Spec failed: required Core asset missing: ${THEMIS_SPEC_REQUIRED_FILE}." >&2
    exit 1
  fi
done

themis_spec_parse_arguments "$@" || {
  themis_spec_usage >&2
  exit 1
}
themis_spec_require_yq || exit 1
THEMIS_SPEC_TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/themis-spec.XXXXXX") || exit 1
THEMIS_SPEC_ERROR_FILE="${THEMIS_SPEC_TEMP_ROOT}/errors"
# 清理临时校验目录；信号必须终止进程，不能只执行清理后继续。
themis_spec_cleanup() {
  rm -rf "${THEMIS_SPEC_TEMP_ROOT}"
}

# shellcheck disable=SC2329
themis_spec_exit_on_signal() {
  trap '' HUP INT TERM
  themis_spec_cleanup
  exit 1
}

trap 'themis_spec_cleanup' EXIT
trap 'themis_spec_exit_on_signal' HUP INT TERM

case "${THEMIS_SPEC_ACTION}" in
  validate)
    themis_spec_validate_internal "${THEMIS_SPEC_SOURCE}" "${THEMIS_SPEC_PROJECTION}" || true
    themis_spec_print_validation_json
    if [ "${THEMIS_SPEC_VALID}" -ne 1 ]; then exit 1; fi
    if [ -n "${THEMIS_SPEC_PROJECTION}" ] && [ "${THEMIS_SPEC_PROJECTION_CURRENT}" -ne 1 ]; then exit 1; fi
    if [ "${THEMIS_SPEC_REQUIRE_READINESS}" -eq 1 ] && [ "${THEMIS_SPEC_READY}" -ne 1 ]; then exit 1; fi
    ;;
  render)
    if ! themis_spec_render_internal "${THEMIS_SPEC_SOURCE}" "${THEMIS_SPEC_OUTPUT}"; then
      printf '%s\n' '{"status":"failure","reason":"render_failed"}'
      exit 1
    fi
    printf '{"status":"rendered","source_oid":"%s","body_oid":"%s"}\n' \
      "$(git hash-object -- "${THEMIS_SPEC_SOURCE}")" \
      "$(sed -n '1s/.* body_oid=\([^ ]*\) -->/\1/p' "${THEMIS_SPEC_OUTPUT}")"
    ;;
  publish)
    if ! themis_spec_publish "${THEMIS_SPEC_CANDIDATE}" "${THEMIS_SPEC_TARGET}"; then
      printf '%s\n' '{"status":"failure","reason":"publish_failed"}'
      exit 1
    fi
    ;;
esac
