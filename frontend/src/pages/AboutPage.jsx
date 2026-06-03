import LegalLayout, { Section } from './LegalLayout';
import { APP_NAME } from '../constants';

// /about：受講生・講師向けのアプリ紹介（公開ページ・LegalLayout 流用）。
// 内部の品質管理用語は使わず、平易な日本語で目的・考え方・機能・工夫・技術を伝える。
export default function AboutPage() {
  return (
    <LegalLayout title={`${APP_NAME} について`}>
      <Section heading="このアプリについて">
        <p>
          {APP_NAME} は、学習中の成果物をお互いにレビューし合い、その積み重ねを
          一人ひとりの「成長の記録」として残していくための、クラス内のコミュニティです。
          作ったものを見せ、フィードバックをもらい、人のコードを読んでレビューする——
          その往復が自然と学びになるように作っています。
        </p>
      </Section>

      <Section heading="大事にしている考え方">
        <ul className="list-disc space-y-1 pl-5">
          <li><strong>取り返せる：</strong>削除には確認と取り消し（Undo）を用意し、操作はできるだけやり直せるようにしています。</li>
          <li><strong>読みやすい言葉：</strong>エラーや案内は、できるだけやさしい日本語で表示します。</li>
          <li><strong>「分からない」を許す：</strong>初心者でもすべての観点を埋める必要はなく、気軽に書ける設計です。</li>
        </ul>
      </Section>

      <Section heading="主な機能">
        <ul className="list-disc space-y-1 pl-5">
          <li>成果物の投稿（URL・スクリーンショット・説明）</li>
          <li>観点別のレビューと「ありがとう」</li>
          <li>講師による評価と合格バッジ</li>
          <li>成長の記録（投稿・もらった / したレビュー・連続記録）</li>
          <li>プロフィールにポートフォリオ / GitHub のリンク、代表作のピン留め</li>
        </ul>
      </Section>

      <Section heading="安心して使うための工夫">
        <ul className="list-disc space-y-1 pl-5">
          <li>クラス（期）の中だけで見える、招待制のクローズドな場です。</li>
          <li>ログインは安全な方式で扱い、二要素認証にも対応しています。</li>
          <li>自分のデータはいつでも書き出せ、退会もできます。</li>
        </ul>
      </Section>

      <Section heading="技術構成">
        <ul className="list-disc space-y-1 pl-5">
          <li>バックエンド：Java + Spring Boot</li>
          <li>フロントエンド：React + Vite</li>
          <li>データベース：PostgreSQL</li>
          <li>インフラ / 配信：AWS（HTTPS で配信）</li>
          <li>自動テスト・自動デプロイ（CI/CD）で品質を保っています。</li>
        </ul>
      </Section>
    </LegalLayout>
  );
}
