#!/usr/bin/env bash
set -euo pipefail

: "${DB_HOST:?DB_HOST is required}"
: "${DB_PORT:?DB_PORT is required}"
: "${DB_PASS:?DB_PASS is required}"
TASK="${TASK:-all}"

run_schema() {
  : "${DB_NAME:?DB_NAME is required for schema}"
  echo ">> Applying schema.sql"
  mysql -h "$DB_HOST" -P "$DB_PORT" -u root -p"$DB_PASS" "$DB_NAME" < /work/sql/schema.sql
}

run_app_user() {
  echo ">> Applying app-user.sql"
  mysql -h "$DB_HOST" -P "$DB_PORT" -u root -p"$DB_PASS" < /work/sql/app-user.sql
}

run_master_data() {
  : "${DB_NAME:?DB_NAME is required for master-data}"
  echo ">> Applying master-data.sql"
  mysql -h "$DB_HOST" -P "$DB_PORT" -u root -p"$DB_PASS" "$DB_NAME" < /work/sql/master-data.sql
}

case "$TASK" in
  all)         run_schema; run_app_user; run_master_data ;;
  schema)      run_schema ;;
  app-user)    run_app_user ;;
  master-data) run_master_data ;;
  *) echo "Unknown TASK: $TASK"; exit 2 ;;
esac

echo ">> Migrations complete."
