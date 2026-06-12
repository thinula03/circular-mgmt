-- ============================================================================
-- Smart Circular Summarization & Management System for Banking
-- Migration 001 — initial schema (11 tables, 3NF, thesis Figure 4.2 ERD)
-- Target: MySQL 8.0 / MariaDB 10.4+  (InnoDB, utf8mb4, FK constraints)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS circular_management
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE circular_management;

SET FOREIGN_KEY_CHECKS = 0;

-- ---- 1. DEPARTMENTS ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS departments (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(120) NOT NULL UNIQUE,
    code         VARCHAR(20)  NOT NULL UNIQUE,
    description  VARCHAR(255),
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---- 2. USERS (soft-delete via is_active; bcrypt hash, NFR-06) --------------
CREATE TABLE IF NOT EXISTS users (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    username       VARCHAR(80)  NOT NULL UNIQUE,
    email          VARCHAR(120) NOT NULL UNIQUE,
    full_name      VARCHAR(120) NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,
    role           VARCHAR(20)  NOT NULL DEFAULT 'Employee',
    department_id  INT,
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login     DATETIME,
    CONSTRAINT fk_users_department
        FOREIGN KEY (department_id) REFERENCES departments(id)
) ENGINE=InnoDB;

-- ---- 3. CIRCULARS (PDF metadata, extracted text, status) -------------------
CREATE TABLE IF NOT EXISTS circulars (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    circular_number VARCHAR(80)  NOT NULL,
    title           VARCHAR(255) NOT NULL,
    issue_date      DATE,
    file_path       VARCHAR(512),
    file_size_kb    INT,
    extracted_text  TEXT,
    priority        VARCHAR(10) DEFAULT 'Medium',
    status          VARCHAR(20) DEFAULT 'uploaded',
    ack_deadline    DATETIME,
    uploaded_by     INT,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    published_at    DATETIME,
    INDEX idx_circular_number (circular_number),
    CONSTRAINT fk_circulars_uploader
        FOREIGN KEY (uploaded_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- ---- 4. SUMMARIES (AI output; entities as JSON to avoid over-normalising) ---
CREATE TABLE IF NOT EXISTS summaries (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    circular_id         INT NOT NULL,
    summary_text        TEXT NOT NULL,
    entities            JSON,
    word_count          INT,
    bert_model          VARCHAR(120),
    bart_model          VARCHAR(120),
    processing_seconds  FLOAT,
    rouge_score         FLOAT,
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_summaries_circular
        FOREIGN KEY (circular_id) REFERENCES circulars(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---- 5. CIRCULAR_DEPARTMENTS (many-to-many routing junction) ---------------
CREATE TABLE IF NOT EXISTS circular_departments (
    circular_id    INT NOT NULL,
    department_id  INT NOT NULL,
    routed_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (circular_id, department_id),
    CONSTRAINT fk_cd_circular
        FOREIGN KEY (circular_id) REFERENCES circulars(id) ON DELETE CASCADE,
    CONSTRAINT fk_cd_department
        FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---- 6. ACKNOWLEDGEMENTS (per-employee reading/ack; red/amber/green) -------
CREATE TABLE IF NOT EXISTS acknowledgements (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    circular_id      INT NOT NULL,
    user_id          INT NOT NULL,
    status           VARCHAR(20) NOT NULL DEFAULT 'Unread',
    read_at          DATETIME,
    acknowledged_at  DATETIME,
    is_late          BOOLEAN DEFAULT FALSE,
    CONSTRAINT uq_ack_user_circular UNIQUE (circular_id, user_id),
    CONSTRAINT fk_ack_circular
        FOREIGN KEY (circular_id) REFERENCES circulars(id) ON DELETE CASCADE,
    CONSTRAINT fk_ack_user
        FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- ---- 7. CLASSIFICATIONS (AI + manual compliance categories) ----------------
CREATE TABLE IF NOT EXISTS classifications (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    circular_id  INT NOT NULL,
    category     VARCHAR(80) NOT NULL,
    confidence   FLOAT,
    is_manual    BOOLEAN DEFAULT FALSE,
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_class_circular
        FOREIGN KEY (circular_id) REFERENCES circulars(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---- 8. NOTIFICATIONS (in-app notification records) ------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    circular_id  INT,
    message      VARCHAR(512) NOT NULL,
    is_read      BOOLEAN DEFAULT FALSE,
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_user
        FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_notif_circular
        FOREIGN KEY (circular_id) REFERENCES circulars(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---- 9. AUDIT_LOG (write-once; application enforces immutability) -----------
CREATE TABLE IF NOT EXISTS audit_log (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT,
    action       VARCHAR(120) NOT NULL,
    entity_type  VARCHAR(80),
    entity_id    INT,
    detail       VARCHAR(512),
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_user
        FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- ---- 10. CHAT_LOG (RAG chatbot Q/A pairs with citations) -------------------
CREATE TABLE IF NOT EXISTS chat_log (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    question     TEXT NOT NULL,
    answer       TEXT NOT NULL,
    citations    JSON,
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_chat_user
        FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- ---- 11. VECTOR_INDEX_METADATA (FAISS index state + rebuild history) -------
CREATE TABLE IF NOT EXISTS vector_index_metadata (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    total_vectors    INT DEFAULT 0,
    total_circulars  INT DEFAULT 0,
    embedding_model  VARCHAR(120),
    dimension        INT,
    index_path       VARCHAR(512),
    last_rebuilt_at  DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- End of migration 001
-- ============================================================================
