# Themis Migrations

## Responsibility

Execute explicit Workspace Schema and Artifact format migrations when the user chooses to upgrade to a Core version whose allow-list does not include the currently installed Schema. Migrations owns the migration execution pipeline, not the Upgrade transaction.

## Inputs

- installed `workspace/manifest.yaml` (current workspace_schema, artifact_schema);
- candidate `core/core.yaml` (compatibility.*.migrations[]);
- available migration scripts under `core/migrations/`.

## Outputs

Write migration logs only beneath `workspace/state/migration_log/` and update `workspace/manifest.yaml` version fields. Preserve pre-migration backup at `<target>/.themis-migration-backup.XXXXXX/`.

## Boundaries

- Do not run automatically. Migration requires explicit user confirmation.
- Do not execute migration scripts whose `from` field does not match the currently installed Schema.
- Do not delete migration backups until the user confirms success.
- Roll back all changes if any migration step fails.
- Do not modify Core content or the Upgrade transaction.

## Migration Pipeline

1. Compatibility check — locate a matching migration descriptor.
2. User confirmation — show the migration plan and require approval.
3. Workspace backup — full copy of `workspace/` to a persistent backup.
4. Execute migration scripts — run each in dependency order, collect JSON output.
5. Verification — directory integrity, artifact format, index consistency.
6. Completion — update manifest, write migration log, retain backup.

## Script Convention

Migration scripts must accept the workspace path as their first argument and output a JSON object with `status`, `changed_files`, and `errors` fields. Exit code 0 = success, 1 = failure, 2 = skipped (already applied).

## References

- Migration policy: `core/policies/migration.yaml`
- Migration prompt: `core/templates/migration-execution.md`
