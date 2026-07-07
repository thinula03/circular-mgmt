-- ============================================================================
-- Migration 004 — chat conversations (ChatGPT-style history)
-- Groups RAG chat messages into conversations. circular_id NULL = a global
-- conversation; a value = a conversation scoped to that single circular.
-- ============================================================================
USE circular_management;

CREATE TABLE IF NOT EXISTS chat_conversations (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    circular_id  INT NULL,
    title        VARCHAR(200) NOT NULL DEFAULT 'New chat',
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_conv_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_conv_circular FOREIGN KEY (circular_id) REFERENCES circulars(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Link existing chat_log rows to a conversation.
ALTER TABLE chat_log
    ADD COLUMN conversation_id INT NULL AFTER user_id,
    ADD CONSTRAINT fk_chatlog_conversation
        FOREIGN KEY (conversation_id) REFERENCES chat_conversations(id) ON DELETE CASCADE;
