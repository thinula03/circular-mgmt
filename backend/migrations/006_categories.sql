-- ============================================================================
-- Migration 006 — managed category taxonomy
-- Admin-editable compliance categories, seeded with the original fixed set.
-- ============================================================================
USE circular_management;

CREATE TABLE IF NOT EXISTS categories (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(120) NOT NULL UNIQUE,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT IGNORE INTO categories (name) VALUES
    ('Technology Risk'),
    ('Anti-Money Laundering'),
    ('Capital Adequacy'),
    ('Consumer Protection'),
    ('General');
