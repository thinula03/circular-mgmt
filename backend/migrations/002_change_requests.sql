-- ============================================================================
-- Migration 002 — change_requests table
-- Managers flag a problem on a circular; administrators resolve (Solved/Not Solved).
-- ============================================================================
USE circular_management;

CREATE TABLE IF NOT EXISTS change_requests (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    circular_id   INT NOT NULL,
    requester_id  INT NOT NULL,
    message       TEXT NOT NULL,
    status        VARCHAR(20) NOT NULL DEFAULT 'Open',
    admin_reply   TEXT,
    resolved_by   INT,
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved_at   DATETIME,
    CONSTRAINT fk_req_circular FOREIGN KEY (circular_id) REFERENCES circulars(id) ON DELETE CASCADE,
    CONSTRAINT fk_req_requester FOREIGN KEY (requester_id) REFERENCES users(id),
    CONSTRAINT fk_req_resolver FOREIGN KEY (resolved_by) REFERENCES users(id)
) ENGINE=InnoDB;
