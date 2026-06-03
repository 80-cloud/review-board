-- ============================================================================
-- 招待URL 検証用テストユーザー（user id=15）削除 SQL
-- 2026-05-29 / 対象: 本番 review-board-prod-db
-- ----------------------------------------------------------------------------
-- 削除対象（招待 URL 検証で生成した 1 ユーザーのみ・他は触らない）:
--   users:  id=15  email=invite-test-2026-05-29@example.com  display_name=招待検証ユーザー
--   refresh_tokens: user_id=15 由来
--   audit_logs:     actor_user_id=15 由来
--   ※ password_reset_tokens / mfa_recovery_codes / user_notification_prefs は
--      ON DELETE CASCADE で自動連動削除
-- ============================================================================

\echo '=== 削除前の確認 ==='
SELECT id, email, display_name, role, cohort_id FROM users WHERE id = 15;

\set ON_ERROR_STOP on
BEGIN;
DELETE FROM refresh_tokens WHERE user_id = 15;
DELETE FROM audit_logs     WHERE actor_user_id = 15;
DELETE FROM users          WHERE id = 15;

\echo '=== 削除後の確認（0 行を期待） ==='
SELECT id, email FROM users WHERE id = 15;

\echo '=== members 全件（期待: 9 名 = admin+学生6+講師2、招待検証ユーザーなし） ==='
SELECT id, display_name, role FROM users WHERE cohort_id = 1 ORDER BY id;

COMMIT;
\echo '=== 完了 ==='
