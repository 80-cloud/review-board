#!/usr/bin/env bash
# =====================================================================
# db-backup.sh — EC2 ローカル PostgreSQL の日次論理バックアップ
# =====================================================================
# pg_dump → gzip → ローカル保存 → S3 退避。local/S3 とも直近 KEEP 世代を保持し
# 以前は自動 prune する。systemd timer（review-board-db-backup.timer）から日次実行。
# バケット/リージョンは EnvironmentFile（/opt/review-board/env）から取得し、
# アカウント固有値をスクリプトに直書きしない。
# =====================================================================
set -euo pipefail

ENV=/opt/review-board/env
PREFIX=db-backups
OUT=/var/lib/pgsql/backups
KEEP=14

BUCKET=$(grep '^S3_BUCKET=' "$ENV" | cut -d= -f2-)
REGION=$(grep '^S3_REGION=' "$ENV" | cut -d= -f2-)
REGION=${REGION:-ap-northeast-1}
if [ -z "$BUCKET" ]; then
  echo "ERROR: S3_BUCKET not found in $ENV" >&2
  exit 1
fi

TS=$(date +%Y%m%d-%H%M%S)
FILE="$OUT/reviewboard-$TS.sql.gz"
mkdir -p "$OUT"
chown postgres:postgres "$OUT"

# ダンプ（所有者/権限は付けない＝新規 DB へ移植しやすく）
sudo -u postgres pg_dump -d reviewboard --no-owner --no-privileges | gzip > "$FILE"
gzip -t "$FILE"

aws s3 cp "$FILE" "s3://$BUCKET/$PREFIX/reviewboard-$TS.sql.gz" --region "$REGION"

# prune local: 直近 KEEP 世代を残す（ファイル名はタイムスタンプ固定で安全＝ls で可）
# shellcheck disable=SC2012
ls -1t "$OUT"/reviewboard-*.sql.gz 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f

# prune S3: 直近 KEEP 世代を残す
KEYS=$(aws s3 ls "s3://$BUCKET/$PREFIX/" --region "$REGION" | awk '{print $4}' | grep -E '^reviewboard-.*\.sql\.gz$' | sort || true)
COUNT=$(printf '%s\n' "$KEYS" | grep -c . || true)
if [ "$COUNT" -gt "$KEEP" ]; then
  printf '%s\n' "$KEYS" | head -n "$((COUNT - KEEP))" | while read -r k; do
    [ -n "$k" ] && aws s3 rm "s3://$BUCKET/$PREFIX/$k" --region "$REGION"
  done
fi

echo "backup ok: $TS (local+S3, keep=$KEEP)"
