-- ============================================================================
-- review-board 本番 § 8-2 深掘りテストデータ クリーンアップ SQL
-- 生成日時: 2026-05-29 / 対象: 再デプロイ後 EIP=18.181.128.60
-- ----------------------------------------------------------------------------
-- 削除対象（認可マトリクス試験で生成・他は触らない）:
--   cohorts:     id=2 (疎通テストA-1780049062), id=3 (疎通テストB-1780049062)
--   users:       id=2 (受講生A), 3 (講師A), 4 (受講生B), 5 (講師B)
--   posts:       id=2 (認可マトリクスTEST投稿)
--   evaluations: 1件 (講師A による APPROVED)
--   ※ 管理者 user(id=1)・「管理」cohort(id=1) は温存
--
-- 実行方法（前回 2026-05-25 と同手順）:
--   1) このファイルを EC2 にコピー:
--        scp -i ~/.ssh/aws-review-board \
--            infra/deploy/cleanup_authmatrix_test_data.sql \
--            ec2-user@18.181.128.60:/tmp/
--   2) EC2 で SSM から DB 接続情報を取得し psql で実行:
--        ssh -i ~/.ssh/aws-review-board ec2-user@18.181.128.60
--        DB_URL=$(aws ssm get-parameter --region ap-northeast-1 \
--                 --name /review-board/prod/DATABASE_URL \
--                 --query 'Parameter.Value' --output text)
--        DB_PW=$(aws ssm get-parameter --region ap-northeast-1 \
--                 --name /review-board/prod/DATABASE_PASSWORD \
--                 --with-decryption --query 'Parameter.Value' --output text)
--        # DB_URL=jdbc:postgresql://host:5432/db を libpq URI に変換
--        URI=$(echo "$DB_URL" | sed -E 's|jdbc:postgresql://([^/]+)/(.+)|postgresql://reviewboard:'"$DB_PW"'@\1/\2|')
--        psql "$URI" -f /tmp/cleanup_authmatrix_test_data.sql
--   3) 末尾の検証クエリ結果を確認し、想定通りなら `COMMIT` を入力（または下の COMMIT を有効化）。
--      ※ デフォルトは安全のため最後で停止（COMMIT/ROLLBACK は人間判断）。
-- ============================================================================

\echo '=== クリーンアップ開始（ON_ERROR_STOP=on・エラー時は自動 ROLLBACK） ==='
\set ON_ERROR_STOP on
BEGIN;

-- 1. 通知（actor/recipient が対象 or post_id=2）
DELETE FROM notifications
 WHERE recipient_user_id IN (2,3,4,5)
    OR actor_user_id     IN (2,3,4,5)
    OR post_id = 2;

-- 2. 監査ログ（actor が対象ユーザー）
DELETE FROM audit_logs
 WHERE actor_user_id IN (2,3,4,5);

-- 3. リフレッシュトークン
DELETE FROM refresh_tokens
 WHERE user_id IN (2,3,4,5);

-- 4. cohort_invites（cohort 2/3 を ON DELETE CASCADE で消すため事前削除しなくてもOKだが明示）
DELETE FROM cohort_invites
 WHERE cohort_id IN (2,3);

-- 5. post 2 のサブテーブル
DELETE FROM post_review_aspects WHERE post_id = 2;
DELETE FROM post_review_tones   WHERE post_id = 2;
DELETE FROM post_likes          WHERE post_id = 2 OR user_id IN (2,3,4,5);
DELETE FROM post_tags           WHERE post_id = 2;
DELETE FROM post_meta           WHERE post_id = 2;

-- 6. evaluations（post 2 由来 or teacher が対象）
DELETE FROM evaluations
 WHERE post_id = 2
    OR teacher_user_id IN (2,3,4,5);

-- 7. reviews 連鎖（今回テストでは reviews 0 件のはずだが念のため）
DELETE FROM review_axis_comments
 WHERE review_id IN (SELECT id FROM reviews WHERE post_id = 2 OR reviewer_user_id IN (2,3,4,5));
DELETE FROM review_replies
 WHERE review_id IN (SELECT id FROM reviews WHERE post_id = 2 OR reviewer_user_id IN (2,3,4,5))
    OR replier_user_id IN (2,3,4,5);
DELETE FROM thanks
 WHERE review_id IN (SELECT id FROM reviews WHERE post_id = 2 OR reviewer_user_id IN (2,3,4,5))
    OR from_user_id IN (2,3,4,5);
DELETE FROM reviews
 WHERE post_id = 2
    OR reviewer_user_id IN (2,3,4,5);

-- 8. posts
DELETE FROM posts
 WHERE id = 2
    OR author_user_id IN (2,3,4,5)
    OR cohort_id IN (2,3);

-- 9. users
--    （password_reset_tokens / mfa_recovery_codes / user_notification_prefs は
--     ON DELETE CASCADE で連動削除されるため明示不要）
DELETE FROM users WHERE id IN (2,3,4,5);

-- 10. cohorts
DELETE FROM cohorts WHERE id IN (2,3);

-- ============================================================================
-- 検証クエリ（COMMIT 前に必ず確認）
-- 期待値: cohorts=1 / users=1 / posts=0 / evaluations=0 / reviews=0 / notifications=0
-- ============================================================================
\echo '=== 検証クエリ（期待: cohorts=1 users=1 posts=0 evaluations=0 reviews=0 notifications=0） ==='
SELECT 'cohorts'       AS t, count(*) FROM cohorts
UNION ALL SELECT 'users',         count(*) FROM users
UNION ALL SELECT 'posts',         count(*) FROM posts
UNION ALL SELECT 'evaluations',   count(*) FROM evaluations
UNION ALL SELECT 'reviews',       count(*) FROM reviews
UNION ALL SELECT 'notifications', count(*) FROM notifications
UNION ALL SELECT 'refresh_tokens',count(*) FROM refresh_tokens
ORDER BY t;

\echo '--- 残った管理者の確認（id=1 hidek.y1998@gmail.com / role=ADMIN / cohort_id=1） ---'
SELECT id, email, role, cohort_id, status FROM users WHERE id = 1;

\echo '--- 残った cohort の確認（id=1 「管理」） ---'
SELECT id, name FROM cohorts WHERE id = 1;

\echo ''
\echo '=== COMMIT 実行（ここまでにエラーが無ければ確定） ==='
COMMIT;
\echo '=== クリーンアップ完了 ==='
