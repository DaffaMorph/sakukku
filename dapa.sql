-- =====================================================================
-- Database Schema: SakuKu (Pencatatan Keuangan Anda)
-- Engine: MySQL 8.0+ / MariaDB 10.5+
-- Charset: utf8mb4 / Collation: utf8mb4_unicode_ci
-- =====================================================================

CREATE DATABASE IF NOT EXISTS `sakuku_db` 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `sakuku_db`;

-- ---------------------------------------------------------------------
-- 1. Table: users
-- Menyimpan informasi akun pengguna dan konfigurasi multi-perangkat
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
    `id` VARCHAR(36) NOT NULL PRIMARY KEY,
    `email` VARCHAR(191) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `password_hash` VARCHAR(255) NULL COMMENT 'Bcrypt hash, null jika login via OAuth',
    `auth_provider` ENUM('local', 'google', 'apple') NOT NULL DEFAULT 'local',
    `avatar_url` VARCHAR(255) NULL,
    `currency` VARCHAR(10) NOT NULL DEFAULT 'IDR',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 2. Table: categories
-- Kategori transaksi dinamis (Pemasukan / Pengeluaran)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `categories` (
    `id` VARCHAR(36) NOT NULL PRIMARY KEY,
    `user_id` VARCHAR(36) NULL COMMENT 'NULL berarti kategori bawaan sistem (default)',
    `name` VARCHAR(60) NOT NULL,
    `type` ENUM('income', 'expense') NOT NULL,
    `icon` VARCHAR(50) NOT NULL DEFAULT 'tag',
    `color` VARCHAR(20) NOT NULL DEFAULT '#10B981',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_categories_user` (`user_id`, `type`),
    CONSTRAINT `fk_categories_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3. Table: transactions
-- Data transaksi harian: pemasukan & pengeluaran
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `transactions` (
    `id` VARCHAR(36) NOT NULL PRIMARY KEY,
    `user_id` VARCHAR(36) NOT NULL,
    `category_id` VARCHAR(36) NOT NULL,
    `type` ENUM('income', 'expense') NOT NULL,
    `amount` DECIMAL(15, 2) NOT NULL,
    `transaction_date` DATE NOT NULL,
    `description` VARCHAR(255) NULL,
    `device_source` VARCHAR(100) NULL DEFAULT 'Web App',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_transactions_user_date` (`user_id`, `transaction_date`),
    INDEX `idx_transactions_type` (`type`),
    CONSTRAINT `fk_transactions_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_transactions_category` FOREIGN KEY (`category_id`) 
        REFERENCES `categories` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 4. Table: category_budgets
-- Anggaran batas pengeluaran per kategori per bulan
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `category_budgets` (
    `id` VARCHAR(36) NOT NULL PRIMARY KEY,
    `user_id` VARCHAR(36) NOT NULL,
    `category_id` VARCHAR(36) NOT NULL,
    `month_year` CHAR(7) NOT NULL COMMENT 'Format YYYY-MM, contoh: 2026-10',
    `budget_limit` DECIMAL(15, 2) NOT NULL,
    `alert_threshold_percent` TINYINT UNSIGNED NOT NULL DEFAULT 80 COMMENT 'Ambang batas peringatan (80%)',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_user_category_month` (`user_id`, `category_id`, `month_year`),
    CONSTRAINT `fk_budgets_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_budgets_category` FOREIGN KEY (`category_id`) 
        REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 5. Table: savings_goals
-- Target keuangan (Financial Goals / Tabungan)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `savings_goals` (
    `id` VARCHAR(36) NOT NULL PRIMARY KEY,
    `user_id` VARCHAR(36) NOT NULL,
    `name` VARCHAR(120) NOT NULL,
    `target_amount` DECIMAL(15, 2) NOT NULL,
    `current_amount` DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    `deadline_date` DATE NULL,
    `status` ENUM('in_progress', 'achieved', 'cancelled') NOT NULL DEFAULT 'in_progress',
    `notes` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_goals_user` (`user_id`, `status`),
    CONSTRAINT `fk_goals_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 6. Table: sync_logs
-- Catatan audit dan sinkronisasi multi-perangkat (Cloud Sync)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sync_logs` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` VARCHAR(36) NOT NULL,
    `device_id` VARCHAR(100) NOT NULL,
    `device_name` VARCHAR(100) NOT NULL,
    `sync_action` ENUM('pull', 'push', 'full_sync') NOT NULL,
    `records_count` INT NOT NULL DEFAULT 0,
    `synced_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_sync_user` (`user_id`, `synced_at`),
    CONSTRAINT `fk_sync_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- SEED DATA AWAL (Initial Sample Data untuk demonstrasi)
-- =====================================================================

-- Default User
INSERT INTO `users` (`id`, `email`, `name`, `auth_provider`, `currency`) 
VALUES ('u-sakuku-01', 'demo@sakuku.app', 'Pengguna Demo SakuKu', 'local', 'IDR')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- Default Categories
INSERT INTO `categories` (`id`, `user_id`, `name`, `type`, `icon`, `color`) VALUES
('c-01', NULL, 'Gaji Pokok', 'income', 'briefcase', '#10B981'),
('c-02', NULL, 'Bonus & Freelance', 'income', 'award', '#38BDF8'),
('c-03', NULL, 'Investasi', 'income', 'trending-up', '#059669'),
('c-04', NULL, 'Makanan & Minuman', 'expense', 'coffee', '#F43F5E'),
('c-05', NULL, 'Transportasi', 'expense', 'car', '#FB923C'),
('c-06', NULL, 'Belanja & Keperluan', 'expense', 'shopping-bag', '#A855F7'),
('c-07', NULL, 'Tagihan & Utilitas', 'expense', 'zap', '#EAB308'),
('c-08', NULL, 'Hiburan & Liburan', 'expense', 'film', '#EC4899'),
('c-09', NULL, 'Kesehatan & Olahraga', 'expense', 'heart', '#06B6D4'),
('c-10', NULL, 'Edukasi & Buku', 'expense', 'book-open', '#6366F1')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

-- Sample Budgets
INSERT INTO `category_budgets` (`id`, `user_id`, `category_id`, `month_year`, `budget_limit`, `alert_threshold_percent`) VALUES
('b-01', 'u-sakuku-01', 'c-04', '2026-10', 2500000.00, 80),
('b-02', 'u-sakuku-01', 'c-05', '2026-10', 800000.00, 80),
('b-03', 'u-sakuku-01', 'c-06', '2026-10', 1200000.00, 80),
('b-04', 'u-sakuku-01', 'c-07', '2026-10', 1000000.00, 80)
ON DUPLICATE KEY UPDATE `budget_limit` = VALUES(`budget_limit`);

-- Sample Savings Goals
INSERT INTO `savings_goals` (`id`, `user_id`, `name`, `target_amount`, `current_amount`, `deadline_date`, `status`, `notes`) VALUES
('g-01', 'u-sakuku-01', 'Dana Darurat (6 Bulan)', 20000000.00, 14500000.00, '2026-12-31', 'in_progress', 'Simpanan di reksadana pasar uang'),
('g-02', 'u-sakuku-01', 'Laptop Kerja Baru', 15000000.00, 9500000.00, '2027-03-31', 'in_progress', 'Upgrade workstation untuk coding & productivity'),
('g-03', 'u-sakuku-01', 'Liburan Akhir Tahun', 5000000.00, 5000000.00, '2026-11-30', 'achieved', 'Tiket dan akomodasi telah diamankan')
ON DUPLICATE KEY UPDATE `current_amount` = VALUES(`current_amount`);

