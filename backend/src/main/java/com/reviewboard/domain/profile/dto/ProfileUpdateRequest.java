package com.reviewboard.domain.profile.dto;

import jakarta.validation.constraints.Size;
import org.hibernate.validator.constraints.URL;

/**
 * F-PROF（S-04）プロフィール編集リクエスト（本人のみ）。bio・avatarKey・portfolioUrl とも任意（null・空可）。
 *
 * @param bio          自己紹介（最大 500・列に合わせる）
 * @param avatarKey    アバターのアップロード済みオブジェクトキー（null は未設定に戻す）
 * @param portfolioUrl 個人ポートフォリオサイトの URL（URL 形式・最大 255・null/空は未設定）
 */
public record ProfileUpdateRequest(
        @Size(max = 500) String bio,
        @Size(max = 512) String avatarKey,
        @Size(max = 255) @URL String portfolioUrl) {
}
