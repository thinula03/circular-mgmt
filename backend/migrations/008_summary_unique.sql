-- ============================================================================
-- Migration 008 — one summary per circular
-- Enforce a single summary per circular at the database level so overlapping
-- (re)summarize requests can never create duplicate summary rows.
-- Run the duplicate-cleanup first (keep newest per circular) if any exist.
-- ============================================================================
USE circular_management;

-- Safety: remove any existing duplicates, keeping the most recent summary.
DELETE s1 FROM summaries s1
JOIN summaries s2
  ON s1.circular_id = s2.circular_id
 AND s1.id < s2.id;

ALTER TABLE summaries
    ADD CONSTRAINT uq_summary_circular UNIQUE (circular_id);
