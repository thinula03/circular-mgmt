-- ============================================================================
-- Migration 003 — notification click-through link
-- Stores the in-app destination for each notification (e.g. "/requests" or
-- "/circulars/5") so the notification bell can navigate on click.
-- ============================================================================
USE circular_management;

ALTER TABLE notifications
    ADD COLUMN link VARCHAR(255) NULL AFTER message;

-- Backfill existing rows: change-request notes point to the Requests page,
-- everything else with a circular points to that circular.
UPDATE notifications
    SET link = '/requests'
    WHERE message LIKE '%request%';

UPDATE notifications
    SET link = CONCAT('/circulars/', circular_id)
    WHERE link IS NULL AND circular_id IS NOT NULL;
