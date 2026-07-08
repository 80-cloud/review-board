package com.reviewboard.common;

/**
 * リソースが存在しない・所有者/cohort が一致しない・論理削除済みのときに投げる（404）。
 *
 * <p>セキュリティ：他人/他 cohort の資源は「存在しない」と同じ 404 に倒し、存在を漏らさず IDOR を遮断する。
 * 権限がない場合（403）と区別せず 404 を返し、リソースの存在を隠す（要件定義書 §3-2・SEC-3）。
 * リソース ID の有無を列挙させないため。
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }
}
