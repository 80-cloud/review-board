#!/usr/bin/env bash
# ============================================================================
# review-board §8-2 深掘りテストデータ クリーンアップ ランナー
# 2026-05-29 作成 / 対象: 再デプロイ後 EIP=18.181.128.60
# ----------------------------------------------------------------------------
# やること:
#   (1) SQL ファイルを EC2 に scp で送る
#   (2) SSH 越しに SSM から DB 接続情報を取得し psql で実行
#       （psql の最後で BEGIN のまま停止し、人間が COMMIT/ROLLBACK を判断）
#   (3) S3 オブジェクト削除コマンドを画面に表示（aws s3 rm は削除系ポリシーで deny → 人間実行）
#
# 削除系の禁止ポリシー上、本スクリプトを直接 AI が実行することは想定しない。
# 人間が手元の Mac で実行する想定。手順は README 末尾。
# ============================================================================
set -euo pipefail

EIP="18.181.128.60"
SSH_KEY="$HOME/.ssh/aws-review-board"
SQL_LOCAL="$(cd "$(dirname "$0")" && pwd)/cleanup_authmatrix_test_data.sql"
SQL_REMOTE="/tmp/cleanup_authmatrix_test_data.sql"
S3_BUCKET="review-board-prod-screenshots-383158157670"
S3_KEY="screenshots/2/8870a948-c09b-4958-8232-2862e086777e.png"

c(){ printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
log(){ c "0;36" "==> $*"; }
ok(){ c "0;32" "OK  $*"; }
warn(){ c "1;33" "!!  $*"; }

[ -f "$SQL_LOCAL" ] || { echo "ERR: $SQL_LOCAL が見つかりません"; exit 1; }
[ -f "$SSH_KEY"   ] || { echo "ERR: SSH 鍵 $SSH_KEY が見つかりません"; exit 1; }

log "(1) SQL を EC2 に転送  →  $EIP:$SQL_REMOTE"
scp -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "$SQL_LOCAL" "ec2-user@$EIP:$SQL_REMOTE"
ok  "scp 完了"

log "(2) SSH 接続 → SSM から DB 接続情報取得 → psql 実行（ON_ERROR_STOP・成功時 COMMIT 内蔵）"

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "ec2-user@$EIP" <<REMOTE_EOF
set -euo pipefail
DB_URL=\$(aws ssm get-parameter --region ap-northeast-1 \
          --name /review-board/prod/DATABASE_URL \
          --query 'Parameter.Value' --output text)
DB_PW=\$(aws ssm get-parameter --region ap-northeast-1 \
          --name /review-board/prod/DATABASE_PASSWORD \
          --with-decryption --query 'Parameter.Value' --output text)
# JDBC URL → libpq URI
URI=\$(echo "\$DB_URL" | sed -E "s|jdbc:postgresql://([^/]+)/(.+)|postgresql://reviewboard:\$DB_PW@\1/\2|")
# ON_ERROR_STOP と COMMIT は SQL ファイル内蔵。エラー時は自動 ROLLBACK で終了コード非0。
psql "\$URI" -v ON_ERROR_STOP=1 -f $SQL_REMOTE
REMOTE_EOF

ok  "psql セッション終了"

log "(3) S3 オブジェクト削除（aws s3 rm は AI 不可 = 人間が手元で実行してください）"
cat <<S3CMD
  # 手元の Mac で（削除系 deny の対象なので AI からは叩けない）:
  aws s3 rm "s3://$S3_BUCKET/$S3_KEY" --region ap-northeast-1

  # バケットが空になったことを確認:
  aws s3 ls "s3://$S3_BUCKET/" --recursive | head -20
  # 期待: 0 件
S3CMD

ok  "全手順表示完了。"
