package com.reviewboard.domain.post;

import com.reviewboard.domain.user.UserRole;
import com.reviewboard.support.AbstractIntegrationTest;
import jakarta.servlet.http.Cookie;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * F-PROF 拡張：代表作ピン留めの認可テスト（所有者のみ＋最大3件＋拒否系）。
 */
class PostPinIntegrationTest extends AbstractIntegrationTest {

    private String authorEmail;
    private String otherEmail;
    private long postId;

    @BeforeEach
    void seed() throws Exception {
        var cohort = newCohort("A");
        authorEmail = newUser("author@example.com", UserRole.STUDENT, cohort.getId()).getEmail();
        otherEmail = newUser("other@example.com", UserRole.STUDENT, cohort.getId()).getEmail();
        postId = createPost(login(authorEmail));
    }

    @Test
    void author_can_pin_and_unpin() throws Exception {
        mockMvc.perform(post("/api/posts/" + postId + "/pin").cookie(login(authorEmail)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.pinned").value(true));
        mockMvc.perform(delete("/api/posts/" + postId + "/pin").cookie(login(authorEmail)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.pinned").value(false));
    }

    /** ★投稿者以外はピンできない（存在を漏らさず 404）。 */
    @Test
    void non_author_cannot_pin_returns404() throws Exception {
        mockMvc.perform(post("/api/posts/" + postId + "/pin").cookie(login(otherEmail)))
                .andExpect(status().isNotFound());
    }

    /** 代表作は最大3件。4件目のピンは 400（上限超過）。 */
    @Test
    void pinning_more_than_three_returns400() throws Exception {
        Cookie author = login(authorEmail);
        long p2 = createPost(author);
        long p3 = createPost(author);
        long p4 = createPost(author);
        for (long id : new long[]{postId, p2, p3}) {
            mockMvc.perform(post("/api/posts/" + id + "/pin").cookie(author)).andExpect(status().isOk());
        }
        mockMvc.perform(post("/api/posts/" + p4 + "/pin").cookie(author))
                .andExpect(status().isBadRequest());
    }

    @Test
    void unauthenticated_is_rejected_returns401() throws Exception {
        mockMvc.perform(post("/api/posts/" + postId + "/pin"))
                .andExpect(status().isUnauthorized());
    }

    private long createPost(Cookie cookie) throws Exception {
        MvcResult res = mockMvc.perform(post("/api/posts").cookie(cookie)
                        .contentType("application/json")
                        .content("{\"title\":\"作品\",\"description\":\"説明\"}"))
                .andExpect(status().isCreated()).andReturn();
        return readId(res);
    }
}
