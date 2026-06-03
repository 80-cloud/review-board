#!/usr/bin/env bash
# ============================================================================
# 自己署名 TLS → Let's Encrypt 正規証明書へ昇格するヘルパー
# 想定: provision.sh で TLS_SELFSIGNED=1 起動中の本番に対し、後日ドメイン取得後に実行。
# ----------------------------------------------------------------------------
# 前提:
#   - 取得したドメインの A レコードが現 EIP を指している（dig +short で要事前確認）
#   - 80/443 ポートが開放済み（既存 SG はそのまま）
#   - hidek.y1998@gmail.com 宛に Let's Encrypt の更新通知が届いてよい
#
# 使い方（手元の Mac から）:
#   infra/deploy/promote_to_letsencrypt.sh review-board.example.com
# ============================================================================
set -euo pipefail

DOMAIN="${1:-}"
EIP="18.181.128.60"
SSH_KEY="$HOME/.ssh/aws-review-board"
EMAIL="${CERTBOT_EMAIL:-hidek.y1998@gmail.com}"

if [ -z "$DOMAIN" ]; then
  echo "使い方: $0 <domain>" >&2
  echo "  例:  $0 review-board.example.com" >&2
  exit 2
fi

c(){ printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
log(){ c "0;36" "==> $*"; }
ok(){ c "0;32" "OK  $*"; }
err(){ c "0;31" "ERR $*" >&2; }

log "(0) DNS 確認: $DOMAIN → ? (期待: $EIP)"
RESOLVED="$(dig +short "$DOMAIN" | tail -1)"
echo "  resolved=$RESOLVED"
if [ "$RESOLVED" != "$EIP" ]; then
  err "$DOMAIN が $EIP を指していません。A レコードを設定してから再実行してください。"
  exit 1
fi
ok "DNS OK"

log "(1) EC2 で certbot --nginx で証明書発行＋HTTP→HTTPS リダイレクト追加"
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "ec2-user@$EIP" <<REMOTE_EOF
set -euo pipefail
# 自己署名 vhost を退避し、ドメインベースの vhost に切替
sudo rm -f /etc/nginx/conf.d/review-board-tls.conf
sudo install -m 644 /home/ec2-user/review-board/infra/deploy/nginx-review-board.conf /etc/nginx/conf.d/review-board.conf
sudo sed -i "s/server_name _;/server_name $DOMAIN;/" /etc/nginx/conf.d/review-board.conf
sudo nginx -t && sudo systemctl reload nginx
sudo dnf install -y certbot python3-certbot-nginx
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect
sudo nginx -t && sudo systemctl reload nginx
REMOTE_EOF
ok "certbot 発行＋nginx リロード完了"

log "(2) 疎通確認"
echo "  https://$DOMAIN/actuator/health:"
curl -s -o /dev/null -w '    http=%{http_code} ssl_verify=%{ssl_verify_result}\n' --max-time 10 "https://$DOMAIN/actuator/health"
echo "  http→https リダイレクト:"
curl -s -o /dev/null -w '    http=%{http_code} location=%{redirect_url}\n' --max-time 10 "http://$DOMAIN/"

ok "Let's Encrypt 昇格完了。今後 PUBLIC_ORIGIN/CORS を https://$DOMAIN に揃える tfvars 更新を検討。"
