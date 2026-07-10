-- ============================================================================
-- Migration 007 — four-eyes approval workflow
-- Adds a Compliance Officer approval step: an admin submits a summarized
-- circular for approval; a Compliance Officer approves (publishes) or rejects.
-- ============================================================================
USE circular_management;

ALTER TABLE circulars
    ADD COLUMN approved_by INT NULL AFTER amends_circular_id,
    ADD COLUMN approved_at DATETIME NULL AFTER approved_by,
    ADD COLUMN distribution_intent JSON NULL AFTER approved_at,
    ADD CONSTRAINT fk_circular_approver
        FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL;
