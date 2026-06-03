-- F-PROF 拡張：GitHub アカウントの URL を登録できるようにする（ポートフォリオ URL と別フィールド）。
-- 任意・null 許容・最大 255。成長記録ページに GitHub アイコン付きで表示する。
ALTER TABLE users ADD COLUMN github_url VARCHAR(255);
