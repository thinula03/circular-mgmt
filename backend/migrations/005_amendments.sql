-- ============================================================================
-- Migration 005 — circular amendments
-- A circular may amend an earlier one (self-reference). The amended circular is
-- then "superseded" (derived at query time, not stored).
-- ============================================================================
USE circular_management;

ALTER TABLE circulars
    ADD COLUMN amends_circular_id INT NULL AFTER uploaded_by,
    ADD CONSTRAINT fk_circular_amends
        FOREIGN KEY (amends_circular_id) REFERENCES circulars(id) ON DELETE SET NULL;
