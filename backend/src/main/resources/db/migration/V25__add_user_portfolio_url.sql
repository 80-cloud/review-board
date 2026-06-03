-- F-PROF 拡張：受講生・講師が自分の個人ポートフォリオサイト URL を1つ登録できるようにする。
-- 任意・null 許容・最大 255。成長記録ページに表示する。
ALTER TABLE users ADD COLUMN portfolio_url VARCHAR(255);
