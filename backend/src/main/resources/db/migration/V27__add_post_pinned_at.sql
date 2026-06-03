-- F-PROF 拡張：投稿の「代表作」ピン留め。pinned_at が非 null の投稿をプロフィール上部に最大3件表示する。
-- 任意・null 許容（null=未ピン）。最大3件の制約はアプリ側（PostService）で担保する。
ALTER TABLE posts ADD COLUMN pinned_at TIMESTAMPTZ;
