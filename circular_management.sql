-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Sep 29, 2026 at 11:38 PM
-- Server version: 10.11.10-MariaDB-log
-- PHP Version: 8.3.31

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `circular_management`
--

-- --------------------------------------------------------

--
-- Table structure for table `acknowledgements`
--

CREATE TABLE `acknowledgements` (
  `id` int(11) NOT NULL,
  `circular_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Unread',
  `read_at` datetime DEFAULT NULL,
  `acknowledged_at` datetime DEFAULT NULL,
  `is_late` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `acknowledgements`
--

INSERT INTO `acknowledgements` (`id`, `circular_id`, `user_id`, `status`, `read_at`, `acknowledged_at`, `is_late`) VALUES
(338, 48, 2, 'Unread', NULL, NULL, 0),
(339, 48, 11, 'Unread', NULL, NULL, 0),
(340, 48, 12, 'Unread', NULL, NULL, 0),
(341, 48, 17, 'Unread', NULL, NULL, 0),
(342, 48, 18, 'Unread', NULL, NULL, 0),
(343, 48, 21, 'Unread', NULL, NULL, 0),
(344, 48, 22, 'Unread', NULL, NULL, 0),
(345, 48, 23, 'Unread', NULL, NULL, 0),
(346, 48, 24, 'Unread', NULL, NULL, 0),
(347, 48, 27, 'Unread', NULL, NULL, 0),
(348, 48, 28, 'Unread', NULL, NULL, 0);

-- --------------------------------------------------------

--
-- Table structure for table `audit_log`
--

CREATE TABLE `audit_log` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `action` varchar(120) NOT NULL,
  `entity_type` varchar(80) DEFAULT NULL,
  `entity_id` int(11) DEFAULT NULL,
  `detail` varchar(512) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `audit_log`
--

INSERT INTO `audit_log` (`id`, `user_id`, `action`, `entity_type`, `entity_id`, `detail`, `created_at`) VALUES
(484, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-14 15:56:28'),
(485, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-14 17:05:34'),
(486, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-14 17:06:54'),
(487, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-15 11:54:41'),
(488, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-16 06:53:40'),
(489, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-16 16:53:06'),
(490, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-17 05:48:33'),
(491, 5, 'USER_LOGIN', 'User', 5, NULL, '2026-07-17 05:50:42'),
(492, 1, 'CIRCULAR_UPLOADED', 'Circular', 42, '04/2024 (752 KB, 3 pages)', '2026-07-17 05:55:06'),
(493, 1, 'CIRCULAR_SUMMARIZED', 'Circular', 42, 'llama3.2:3b in 131.25s', '2026-07-17 05:58:12'),
(494, 1, 'CIRCULAR_SUMMARIZED', 'Circular', 42, 'llama3.2:3b in 188.8s', '2026-07-17 05:58:21'),
(495, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-17 06:08:45'),
(496, 1, 'CIRCULAR_SUBMITTED', 'Circular', 42, NULL, '2026-07-17 06:10:14'),
(497, 1, 'CIRCULAR_UPLOADED', 'Circular', 43, '01/2025 (326 KB, 3 pages)', '2026-07-17 06:11:04'),
(498, 1, 'CIRCULAR_SUMMARIZED', 'Circular', 43, 'llama3.2:3b in 90.4s', '2026-07-17 06:12:40'),
(499, 1, 'CIRCULAR_SUBMITTED', 'Circular', 43, NULL, '2026-07-17 06:13:34'),
(500, 1, 'CIRCULAR_EDITED', 'Circular', 43, NULL, '2026-07-17 06:14:30'),
(501, 1, 'CIRCULAR_UPLOADED', 'Circular', 44, '01/2021 (756 KB, 1 pages)', '2026-07-17 06:15:35'),
(502, 1, 'CIRCULAR_SUMMARIZED', 'Circular', 44, 'llama3.2:3b in 101.02s', '2026-07-17 06:18:08'),
(503, 1, 'CIRCULAR_SUBMITTED', 'Circular', 44, NULL, '2026-07-17 06:20:08'),
(504, 1, 'CIRCULAR_UPLOADED', 'Circular', 45, '01/22 (1378 KB, 5 pages)', '2026-07-17 06:58:08'),
(505, 1, 'CIRCULAR_SUMMARIZED', 'Circular', 45, 'llama3.2:3b in 124.08s', '2026-07-17 07:00:22'),
(506, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-17 07:02:52'),
(507, 1, 'CIRCULAR_SUBMITTED', 'Circular', 45, NULL, '2026-07-17 07:03:46'),
(508, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-17 07:08:50'),
(509, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-17 07:28:48'),
(510, 1, 'CIRCULAR_UPLOADED', 'Circular', 46, '02/2022 (2859 KB, 9 pages)', '2026-07-17 07:30:35'),
(511, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-17 07:33:13'),
(512, 1, 'CIRCULAR_PREVIEWED', 'Circular', 46, NULL, '2026-07-17 07:33:40'),
(513, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-17 07:34:54'),
(514, 1, 'CIRCULAR_RESUMMARIZED', 'Circular', 46, 'llama3.2:3b in 119.05s', '2026-07-17 07:37:10'),
(515, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-17 07:41:19'),
(516, 1, 'CIRCULAR_SUBMITTED', 'Circular', 46, NULL, '2026-07-17 07:42:23'),
(517, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-17 07:45:53'),
(518, 1, 'CIRCULAR_UPLOADED', 'Circular', 47, '04/2018 (1164 KB, 17 pages)', '2026-07-17 07:48:48'),
(519, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-17 07:52:53'),
(520, 1, 'CIRCULAR_SUMMARIZED', 'Circular', 47, 'llama3.2:3b in 559.64s', '2026-07-17 07:58:19'),
(521, 1, 'CIRCULAR_RESUMMARIZED', 'Circular', 47, 'llama3.2:3b in 336.29s', '2026-07-17 07:58:30'),
(522, 1, 'CIRCULAR_SUMMARIZED', 'Circular', 47, 'llama3.2:3b in 419.14s', '2026-07-17 07:58:39'),
(523, 1, 'CIRCULAR_RESUMMARIZED', 'Circular', 47, 'llama3.2:3b in 341.43s', '2026-07-17 07:58:48'),
(524, 1, 'CIRCULAR_SUBMITTED', 'Circular', 47, NULL, '2026-07-17 08:05:54'),
(525, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-17 08:20:46'),
(526, 1, 'CIRCULAR_UPLOADED', 'Circular', 48, '02/2021 (261 KB, 1 pages)', '2026-07-17 08:22:48'),
(527, 1, 'CIRCULAR_SUMMARIZED', 'Circular', 48, 'llama3.2:3b in 79.77s', '2026-07-17 08:24:13'),
(528, 1, 'CIRCULAR_SUBMITTED', 'Circular', 48, NULL, '2026-07-17 08:26:55'),
(529, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-18 17:29:00'),
(530, NULL, 'USER_LOGIN_FAILED', 'User', NULL, 'username=officer', '2026-07-18 17:44:05'),
(531, NULL, 'USER_LOGIN_FAILED', 'User', NULL, 'username=officer', '2026-07-18 17:44:10'),
(532, 5, 'USER_LOGIN', 'User', 5, NULL, '2026-07-18 17:44:14'),
(533, 1, 'USER_LOGIN_FAILED', 'User', 1, 'username=admin', '2026-07-28 03:13:48'),
(534, 1, 'USER_LOGIN_FAILED', 'User', 1, 'username=admin', '2026-07-28 03:13:54'),
(535, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-07-28 03:13:58'),
(536, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-08-02 10:21:54'),
(537, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-08-24 09:18:04'),
(538, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-09-26 04:54:49'),
(539, NULL, 'USER_LOGIN_FAILED', 'User', NULL, 'username=', '2026-09-26 13:28:33'),
(540, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-09-26 13:28:43'),
(541, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-09-27 05:52:48'),
(542, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-09-27 09:04:46'),
(543, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-09-28 08:02:04'),
(544, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-09-28 10:14:26'),
(545, 1, 'CIRCULAR_UPLOADED', 'Circular', 49, '02/2025 (2040 KB, 8 pages)', '2026-09-28 10:21:29'),
(546, 1, 'CIRCULAR_SUMMARIZED', 'Circular', 49, 'llama3.2:3b in 508.34s', '2026-09-28 10:36:21'),
(547, 1, 'CIRCULAR_SUMMARIZED', 'Circular', 49, 'llama3.2:3b in 281.61s', '2026-09-28 10:36:30'),
(548, 1, 'CIRCULAR_SUMMARIZED', 'Circular', 49, 'llama3.2:3b in 213.24s', '2026-09-28 10:39:40'),
(549, 1, 'CIRCULAR_SUMMARIZED', 'Circular', 49, 'llama3.2:3b in 186.55s', '2026-09-28 10:45:38'),
(550, 1, 'CIRCULAR_UPLOADED', 'Circular', 50, '03/2024 (2169 KB, 4 pages)', '2026-09-28 10:54:20'),
(551, 1, 'CIRCULAR_SUMMARIZED', 'Circular', 50, 'llama3.2:3b in 132.03s', '2026-09-28 10:56:52'),
(552, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-09-28 12:25:09'),
(553, 1, 'USER_LOGIN_FAILED', 'User', 1, 'username=admin', '2026-09-28 12:30:21'),
(554, 1, 'USER_LOGIN_FAILED', 'User', 1, 'username=admin', '2026-09-28 12:30:34'),
(555, 6, 'USER_LOGIN', 'User', 6, NULL, '2026-09-28 12:31:32'),
(556, NULL, 'CIRCULAR_DISTRIBUTED', 'Circular', 48, '6 dept(s), 11 recipient(s)', '2026-09-28 12:38:12'),
(557, 6, 'CIRCULAR_APPROVED', 'Circular', 48, '11 recipients', '2026-09-28 12:38:31'),
(558, 6, 'CIRCULAR_REJECTED', 'Circular', 42, 'Duplicate informations', '2026-09-28 12:40:40'),
(559, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-09-28 12:41:32'),
(560, 1, 'CIRCULAR_RESUMMARIZED', 'Circular', 48, 'llama3.2:3b in 147.11s', '2026-09-28 13:01:15'),
(561, 1, 'USER_CREATED', 'User', 29, 'chamudika (Employee)', '2026-09-28 13:39:54'),
(562, 1, 'DEPARTMENT_CREATED', 'Department', 17, 'compliance (CO)', '2026-09-28 13:40:29'),
(563, 1, 'DEPARTMENT_DELETED', 'Department', 17, 'compliance', '2026-09-28 13:40:40'),
(564, 1, 'CATEGORY_ADDED', 'Category', 26, 'hi', '2026-09-28 13:40:55'),
(565, 1, 'CATEGORY_DELETED', 'Category', 26, 'hi', '2026-09-28 13:41:05'),
(566, 1, 'USER_LOGIN', 'User', 1, NULL, '2026-09-28 13:44:20'),
(567, 1, 'CIRCULAR_EDITED', 'Circular', 50, NULL, '2026-09-28 13:44:39'),
(568, 28, 'USER_LOGIN', 'User', 28, NULL, '2026-09-29 05:49:04'),
(569, 7, 'USER_LOGIN', 'User', 7, NULL, '2026-09-29 06:01:40');

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` int(11) NOT NULL,
  `name` varchar(120) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`, `created_at`) VALUES
(1, 'Technology Risk', '2026-07-08 15:00:02'),
(2, 'Anti-Money Laundering', '2026-07-08 15:00:02'),
(3, 'Capital Adequacy', '2026-07-08 15:00:02'),
(4, 'Consumer Protection', '2026-07-08 15:00:02'),
(5, 'General', '2026-07-08 15:00:02'),
(6, 'remote working', '2026-07-08 09:30:08'),
(7, 'SME Relief Measures', '2026-07-12 08:52:57'),
(8, 'Regulatory Compliance', '2026-07-12 08:53:07'),
(10, 'Loan Recovery', '2026-07-12 12:47:03'),
(11, 'COVID-19 Recovery', '2026-07-12 12:56:08'),
(12, 'Banking Operations', '2026-07-12 12:56:56'),
(13, 'Financial Reporting', '2026-07-12 16:16:23'),
(14, 'SLFRS9', '2026-07-12 16:17:20'),
(15, 'Audit Department', '2026-07-12 16:18:46'),
(16, 'Cybersecurity', '2026-07-12 17:09:02'),
(17, 'Mobile Banking Units', '2026-07-12 18:59:18'),
(18, 'Credit', '2026-07-12 19:31:30'),
(19, 'Security Management', '2026-07-12 20:05:25'),
(20, 'Information technology', '2026-07-12 20:16:13'),
(21, 'Project Management', '2026-07-12 20:16:31'),
(22, 'Project risk management', '2026-07-12 20:26:06'),
(23, 'Management governance', '2026-07-12 20:30:11'),
(24, 'Document control', '2026-07-12 20:41:02'),
(25, 'Foreign Exchange Operations', '2026-07-12 20:49:04');

-- --------------------------------------------------------

--
-- Table structure for table `change_requests`
--

CREATE TABLE `change_requests` (
  `id` int(11) NOT NULL,
  `circular_id` int(11) NOT NULL,
  `requester_id` int(11) NOT NULL,
  `message` text NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Open',
  `admin_reply` text DEFAULT NULL,
  `resolved_by` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `resolved_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `chat_conversations`
--

CREATE TABLE `chat_conversations` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `circular_id` int(11) DEFAULT NULL,
  `title` varchar(200) NOT NULL DEFAULT 'New chat',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `chat_conversations`
--

INSERT INTO `chat_conversations` (`id`, `user_id`, `circular_id`, `title`, `created_at`, `updated_at`) VALUES
(21, 1, NULL, 'heyy', '2026-07-14 16:01:05', '2026-07-14 16:01:05');

-- --------------------------------------------------------

--
-- Table structure for table `chat_log`
--

CREATE TABLE `chat_log` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `conversation_id` int(11) DEFAULT NULL,
  `question` text NOT NULL,
  `answer` text NOT NULL,
  `citations` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`citations`)),
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `chat_log`
--

INSERT INTO `chat_log` (`id`, `user_id`, `conversation_id`, `question`, `answer`, `citations`, `created_at`) VALUES
(52, 1, 21, 'heyy', 'I couldn\'t find a relevant circular for that question. Make sure circulars have been published and try rephrasing.', '[]', '2026-07-14 16:01:25');

-- --------------------------------------------------------

--
-- Table structure for table `circulars`
--

CREATE TABLE `circulars` (
  `id` int(11) NOT NULL,
  `circular_number` varchar(80) NOT NULL,
  `title` varchar(255) NOT NULL,
  `issue_date` date DEFAULT NULL,
  `file_path` varchar(512) DEFAULT NULL,
  `file_size_kb` int(11) DEFAULT NULL,
  `extracted_text` text DEFAULT NULL,
  `priority` varchar(10) DEFAULT 'Medium',
  `status` varchar(20) DEFAULT 'uploaded',
  `ack_deadline` datetime DEFAULT NULL,
  `uploaded_by` int(11) DEFAULT NULL,
  `amends_circular_id` int(11) DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `distribution_intent` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`distribution_intent`)),
  `created_at` datetime DEFAULT current_timestamp(),
  `published_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `circulars`
--

INSERT INTO `circulars` (`id`, `circular_number`, `title`, `issue_date`, `file_path`, `file_size_kb`, `extracted_text`, `priority`, `status`, `ack_deadline`, `uploaded_by`, `amends_circular_id`, `approved_by`, `approved_at`, `distribution_intent`, `created_at`, `published_at`) VALUES
(42, '04/2024', 'RELIEF MEASURES TO ASSIST THE AFFECTED SMALL AND MEDIUM ENTERPRISES', '2024-12-19', '/www/wwwroot/circular/backend/uploads/3bb8d77c994c48ecad7603dff1617fe6_bsd_circular_no_4_of_2024_RELIEF_MEASURES_TO_ASSIST_THE_AFFECTED_SMALL_AND_MEDIUM.pdf', 752, 'RELIEF MEASURES TO ASSIST THE AFFECTED SMALL AND MEDIUM\nENTERPRISES\nAs discussed at the meetings of the Working Committee on Recovery of Loans by Banks (Special\nProvisions) (Amendment) Act, No. 26 of 2024, it is noted that the Sri Lanka Banks’ Association\n(Guarantee) Ltd. (SLBA), has agreed that the relief measures in paragraph 1 below will be\nprovided by the licensed commercial banks and licensed specialised banks (hereinafter referred to\nas licensed banks), to the Small and Medium Enterprises (SMEs) affected due to the Easter Sunday\nattack, Covid-19 pandemic and the extraordinary macroeconomic conditions that prevailed during\nthe recent past.\nIt is further noted that SLBA, in formulating the relief measures, was of the view that any\nsuspension to Parate execution will not be beyond 31.03.2025.\nFeatures of the Relief Measures\nLl\nRelief measures will apply only to the credit facilities of SME borrowers of licensed banks\nthat meet the following criteria and, in this regard, licensed banks will engage with the\neligible borrowers.\n(a)\nCredit facilities of SMEs that have been classified as Stage 3 on or after 01.04.2019,\nand,\n(b)\nSMEs that commenced discussions on business revival with the Business Revival\nUnits of the respective banks by 31.03.2025, subject to submission of all necessary\ndocuments.\nReschedulement of impaired loans with eligible SME borrowers identified in paragraph\n1.1 above, considering the repayment capacity of the borrower and submission of an\nacceptable business revival plan, as given below.\n(a)\nEntering into reschedulement agreements with eligible SME borrowers not later\nthan 15.06.2025.\nCommencing of repayment of the rescheduled loans by eligible SME borrowers\nwhere an aggregate capital outstanding of credit facilities as at 15.12.2024 is below\nRs. 25 Mn, not later than 31.12.2025.\n(c)\nCommencing of repayment of the rescheduled loans by SME borrowers where an\naggregate capital outstanding of credit facilities as at 15.12.2024 is between\nRs. 25 Mn - Rs.50 Mn, not later than 30.09.2025.\n(d)\nCommencing of repayment of the rescheduled loans by SME borrowers where an\naggregate capital outstanding of credit facilities as at 15.12.2024, is above\nRs. 50 Mn, not later than 30.06.2025.\nWaiving off the unpaid interest (excluding capitalised interest) applicable to the period\nbetween 01.04.2019 and 15.12.2024 on the credit facilities of eligible SME borrowers,\nbased on the reschedulement agreements, considering the financial position of the bank, as\ngiven in Table 1.\nTable 1: Interest Waivers\nFacility Amount as at\nInterest waiver granted for settlement of unpaid\noutstanding: above Rs.\n10 Mn up to Rs. 25 Mn\n15.12.2024\ninterest between 01.04.2019 and 15.12.2024\nIf settled within\nIf settled\nIf settled in more\n6 Months\nwithin 12\nthan 12 Months but\nMonths\nless than 60 Months\nAggregate Capital\n65%\n50%\n40%\noutstanding: above Rs. 5\nMn up to Rs. 10 Mn\nAggregate Capital\n35%\n25%\n20%\nLicensed banks may consider further reliefs, including granting of working capital facilities\nto eligible borrowers subject to repayment capacity and submission of credible business\nrevival plans, on a case-by-case basis.\n2,\nReporting to the Credit Information Bureau of Sri Lanka\nLicensed banks in consultation with the Credit Information Bureau of Sri Lanka (CRIB),\nmay develop an appropriate reporting modality to report credit facilities that are\nrestructured under paragraph 1 above.\nLicensed banks shall not decline loan applications from eligible borrowers under this\nCircular solely based on an adverse CRIB record.\nTransparency of provision of Relief Measures\nIn the case of a rejection/dispute on providing above reliefs, licensed banks are requested\nto inform the borrower the reasons for such rejection/dispute and requested to advise the\nborrower that there is an opportunity for the borrower to appeal against such\nrejection/dispute to the Director, Financial Consumer Relations Department of the Central\nBank of Sri Lanka.\nLicensed banks to make available the breakdown of capital, interest and other charges of\ncredit facilities, on request of the eligible borrowers.\nnN.\nFF\nWane tt\n/\nenna\nDr. P Nandalal Weerasinghe\nChairman of the Governing Board and\nGovernor of the Central Bank of Sri Lanka', 'Medium', 'review', NULL, 1, NULL, NULL, NULL, '{\"department_ids\": [], \"broadcast\": true, \"ack_days\": 7}', '2026-07-17 05:55:06', NULL),
(43, '01/2025', 'ADDENDUM TO THE CIRCULAR NO. 04 OF 2024 ON RELIEF MEASURES TO ASSIST THE AFFECTED SMALL AND MEDIUM ENTERPRISES', '2025-01-01', '/www/wwwroot/circular/backend/uploads/8582f3b174924bd68105f8ba2091f79d_bsd_circular_no_4_addendum_ano_1_of_2025_e.pdf', 326, 'CENTRAL BANK OF SRI LANKA\n01 January 2025\nCIRCULAR\nNo. 01 of 2025\nADDENDUM TO THE CIRCULAR NO. 04 OF  2024 ON RELIEF MEASURES TO\nASSIST THE AFFECTED SMALL AND MEDIUM ENTERPRISES\nThe Central Bank of Sri Lanka hereby issues the following Addendum to further clarify Circular\nNo. 04 of 2024 on Relief Measures to Assist the Affected Small and Medium Enterprises (SMEs)\nwith a view to ensuring effective implementation of the relief measures specified in the cited Circular\nin a consistent manner across all licensed banks.\nLicensed banks shall establish a Relief Banking Unit for the purpose of extending and monitoring\nthe relief measures under the cited Circular for the effective implementation of such relief measures\nwhile the existing Business Revival Units established under Circular No. 02 of 2024 on Guidelines\nfor the Establishment of Business Revival Units in Licensed Banks, will continue for the intended\npurpose thereof.\nThe following will be inserted as Paragraph No. 1.4 and existing Paragraph No. 1.4 is renumbered\nas 1.5.\nFeatures of the Relief\nMeasures\n1.4 Licensed banks may reschedule the credit facilities of eligible\nborrowers for a maximum period up to ten years, unless the\noriginal agreement has provided a period longer than ten years,\non a case-by-case basis, considering the repayment capacity of\nthe borrower and an acceptable revival plan. In this regard,\nlicensed bank and the eligible borrower shall agree on the\nterms and conditions including the interest rates considering\nthe prevailing benchmark interest rates.\nThe following will be inserted as Paragraphs No. 3.3\nTransparency of\nprovision of relief\nmeasures\n3.3 Licensed banks are requested to establish a transparent\ngrievance-handling mechanism with respect to any dispute that\nmay arise between the bank and the borrower on the valuation\nof auctioned properties.\n[Limited Sharing]#\nBank Name\nAnnexure A\nReporting as at\nTotal Amount\nConsidered for\nRescheduling\n(Rs. 000s)\nTenor of the\nRescheduled\nLoan\nApplicable\nInterest Rate\non\nRescheduled\nLoan (%)\nAgreed Date of\nCommencement of\nRepayment\n(DD/MM/YYYY)\nHas the\nRepayment\nCommenced\n(Yes/No)\nTotal Amount\nConsidered for\nRescheduling\n(Rs. 000s)\nTenor of the\nRescheduled\nLoan\nApplicable\nInterest\nRate on\nReschedul\ned Loan\n(%)\nInterest\nWaived off\nby the banks\non\nrescheduling\n(Rs. \'000s)\nAgreed Date of\nCommencement of\nRepayment\n(DD/MM/YYYY)\nHas the\nRepayment\nCommenced\n(Yes/No)\nOutstanding\nInterest as at\nthe Date of\nRescheduling\n(Rs. \'000s)\nOutstanding\nCharges or\nFees as at the\nDate of\nRescheduling\n(Rs. \'000s)\nCharges or\nFees Waived\noff as at the\nDate of\nRescheduling\n(Rs. \'000s)\nRescheduled Loan for the Capital\nRescheduled Loan for the Interest\nIf Rescheduled\nSerial\nNo.\nMonthly Reporting of Details of the Borrowers who Approached Banks to Avail the Relief Measures Provided Under Circular No. 04 of 2024 from 15.12.2024 to the Reporting Date\nDate of\nClassifying to\nStage 3\n(DD/MM/YY\nYY)\nFacility\nNumber\nBorrower\nName\nAmount Outstanding as\nat 15.12.2024\nDate of\nCommencement of\nDiscussion\n(DD/MM/YYYY)\nStatus of the\nDiscussion\n(Rescheduled/\nRejected/ Under\nDiscussion)\nIf\nRejected,\nReasons\nfor\nRejection\nInterest\n(Rs. 000\'s)\nCapital\n(Rs. 000\'s)\nDate of\nRescheduling\n(DD/MM/YY\nYY)\nOutstanding\nCapital as at the\nDate of\nRescheduling\n(Rs. \'000s)', 'Medium', 'pending_approval', NULL, 1, 42, NULL, NULL, '{\"department_ids\": [], \"broadcast\": true, \"ack_days\": 7}', '2026-07-17 06:11:04', NULL),
(44, '01/2021', 'SUSPENSION OF RECOVERY ACTIONS AGAINST SMALL AND MEDIUM ENTERPRISE (SME) PADDY MILLERS', '2021-01-13', '/www/wwwroot/circular/backend/uploads/cdf63f55aad0470d9db2f2205bc3043b_bsd_circular_no_1_of_2021_e.pdf', 756, 'a\n\\\nSe\nMONETARY BOARD\nCENTRAL BANK OF SRI LANKA\n/3 January 2021\nCIRCULAR\nNo. 01 of 2021\nSUSPENSION OF RECOVERY ACTIONS AGAINST\nSMALL AND MEDIUM ENTERPRISE (SME) PADDY MILLERS\nConsidering the Government initiatives to support the SME Paddy Millers amidst COVID 19\npandemic for the upcoming harvesting seasons, licensed commercial banks and licensed\nspecialised banks (hereinafter referred to as licensed banks), are required to suspend recovery\nactions against SME Paddy Millers for a period of six months commencing from 1 January\n2021 as specified below.\n(1) In the case where a licensed bank has commenced or given notice of recovery action\nunder the provisions of the Recovery of Loans by Banks (Special Provisions) Act, No.\n4 of 1990 or Mortgage Act No. 06 of 1949 as amended or Finance Leasing Act No. 56\nof 2000 or any other relevant Act in this regard, such recovery actions shall be\nsuspended on condition that the concerned licensed bank and the borrower reach a debt\nre-payment agreement.\nLicensed banks shall defer passing new resolutions under the above Acts, for recovery\nof loans and advances. In instances where resolutions for recovery have already been\npassed, auctioning of assets will be suspended until 30.06.2021.\nIn instances where there are on-going litigations in courts relating to recovery,\nborrowers will be permitted to enter into an agreement by submission of affidavit to\nCourts agreeing to comply with the requirements set out in (1) above.\nLicensed banks shall suspend any other legal or recovery action until 30.06.2021.\nWwW”)\n=\nProf. WD Lakshman\nChairman of the Monetary Board and\nGovernor of the Central Bank of Sri Lanka', 'Medium', 'pending_approval', NULL, 1, NULL, NULL, NULL, '{\"department_ids\": [5, 8, 10, 6, 9], \"broadcast\": false, \"ack_days\": 7}', '2026-07-17 06:15:35', NULL),
(45, '01/22', 'GUIDELINES ON ESTABLISHMENT OF POST COVID-19 REVIVAL UNITS IN LICENSED BANKS', '2022-03-24', '/www/wwwroot/circular/backend/uploads/541244b7b397491dbdac1c01fc44e557_bsd_circular_no_1_of_2022_e.pdf', 1378, 'af March 2022\nGUIDELINES ON ESTABLISHMENT OF POST COVID-19 REVIVAL UNITS IN\nLICENSED BANKS\nThe prolonged nature of the COVID-19 pandemic has led to disruption in income generating\nactivities of businesses adversely impacting their ability to duly repay their loans and thereby\nimpairing the recovery process of licensed commercial banks and licensed specialised banks\n(hereinafter referred to as licensed banks). Therefore, with a view to facilitating the sustainable\neconomic revival of businesses affected by the COVID-19 pandemic and to mitigate the increase\nin impaired assets of licensed banks, the Central Bank of Sri Lanka (CBSL) in its “Six-Month\nRoad Map for Ensuring Macroeconomic and Financial System Stability” announced the need for\nestablishment of Post COVID-19 Revival Units in licensed banks. Accordingly, CBSL hereby\nissues broad guidelines to give effect to the establishment of Post COVID-19 Revival Units in\nlicensed banks.\n1. Objective\nGovernance\nFramework and\nResources\nThe purpose of establishment of the Post COVID-19 Revival Unit\n(hereinafter referred to as the Unit) is to identify and assist under\nperforming and non-performing borrowers of licensed banks who\nare affected by COVID-19 and are facing financial difficulties due\nto reduction of income or sales, reduction or impairment of\nbusiness operations or the closure of business etc., with the aim of\nreviving viable businesses which will provide benefits to such\nborrowers, leading to enhancement of economic activities and\ncontributing to the development of the national economy.\nLicensed\nbanks\nrequired\nformulate\na\nand\nrehabilitation policy approved by the Board of Directors for a\nlocally incorporated licensed bank and the regional/global head\noffice for a licensed bank incorporated outside Sri Lanka.\n3. Duties and\nFunctions of the\nRevival Unit\n22,\n23:\nThe revival and rehabilitation policy should inter alia include the\nfollowing at a minimum:\n(i) the mandate for establishment of the Unit;\nits scope of activities including deliverables;\n(iii) the revival mechanism for borrowers including financial and\nnon-financial strategies which may include but not limited to\nrescheduling/restructuring of existing credit facilities;\n(iv) granting other additional credit facilities on needs basis and;\n(v)\nprovide any other appropriate measures for the revival of\naffected borrowers, post COVID-19.\nThe Unit shall be headed by a Key Management Personnel of the\nlicensed bank with sufficient authority and seniority to ensure\neffective and efficient oversight of the Unit and expeditious\nimplementation of revival and rehabilitation activities.\nLicensed banks to ensure that the Unit shall be adequately staffed\nand possess sufficient expertise and authority for credit appraisal\nand monitoring and be provided with all other resources on needs\nbasis.\nIn the case of banks with more than 50 bank branches, such\nlicensed banks may consider establishment of Units at large\nbranches / regional offices of banks as appropriate. Other licensed\nbanks shall have the Post COVID-19 Revival Unit centrally.\nThe Unit shall actively liaise with branches and other business\nunits of the bank to;\n(i)\nidentify borrowers who require rehabilitation assistance,\nincluding borrowers considered for liquidity support to\nunwind moratorium\ndevelop rehabilitation proposals after completing a thorough\nanalysis and coordination with all stakeholders\n3a4March 2022\n4. Accounting\nConsiderations\nSie)\n(iii) obtain necessary approvals and review the performance\nIn the case of 3.1(i) above, licensed banks shall not consider the\nfollowing borrowers for revival.\n(a)\nBorrowers that have been identified as willful defaulters\n(b) Borrowers that have defaulted due to diversion of funds\n(i.e., funds borrowed from licensed banks have been\nutilised for purposes un-related to the operations of the\nbusiness of the borrower)\n(c) Borrowers that have defaulted due to mismanagement\nand/or frauds in the business\n(d) Borrowers engaged in unviable projects\nIn the case of 3.1(i) above, licensed banks may consider the\nfollowing borrowers for revival at the discretion of the banks.\n(i) Borrowers that have been classified as non-performing prior\nto 01 April 2020.\nBorrowers that are under litigation.\nThe Unit shall conduct awareness programs on rehabilitation,\ninitiatives, procedures and methodologies to relevant stakeholders\nviz., branches and business units of the bank, borrowers etc.\nThe Unit shall provide credit counselling and business advisory\nservices and assist businesses in reaching out to potential\ninvestors, obtain seed capital, equity etc., if necessary.\nLicensed banks shall adopt accounting treatment for facilities\nconsidered under the Unit as per the Sri Lanka Accounting\nStandards and related Circulars/guidelines issued by CBSL. In the\ncase of risk elevated borrowers or sectors, licensed banks are\nrequired to make adequate impairment charges. Licensed banks\nmay seek advice from the Institute of Chartered Accountants of Sri\n5. Reporting to the\nInformation\nBureau (CRIB)\nof Sri Lanka\n6. Re-finance or\nInterest Subsidy\nSchemes\n7. Recovery Action\nfor Default after\n8. Implementation\n9. Reporting\nRequirement\nLanka and Auditors for additional guidance and clarification in\nthis regard.\nLicensed banks, in consultation with CRIB, shall develop a\nreporting modality to report credit facilities transferred to this\nUnit, so that participation in revival and rehabilitation schemes of\nthis Unit will not have an impact on the credit score of borrowers\nin the future, or be negatively reflected in future CRIB reports.\nThe restructuring of facilities granted under refinance or interest\nsubsidy schemes shall be considered in accordance with the related\nguidelines issued by the Regional Development Department of\nCBSL or the Ministry of Finance in this regard.\nLicensed banks may adopt suitable recovery actions against\nborrowers that have failed to adhere to the terms and conditions\nagreed for revival and rehabilitation under this Unit as per the\nbank’s internal guidelines and policies.\nLicensed banks are required to make necessary arrangements to\nestablish Post COVID-19 Revival Units by 30 April 2022. In the\ncase of licensed banks that have already established Revival Units\nsuch banks may expand the scope of activities of these Units to be\nin line with the requirements of this Circular.\nLicensed banks shall report the details on progress of rehabilitation\nproposals availed to the bank’s borrowers as at the end of each\nquarter, within 15 working days, commencing 30 June 2022 as per\nthe reporting format given in Annex I.\nbre ceo a\nNivard Ajith Leslie Cabraal\nChairman of the Monetary Board and\nGovernor of the Central Bank of Sri Lanka\nReport\non\nEligible\nBorrowers\nAvailing\nConcessions\nunder\nPost\nCOVID\nUnits\nAnnex\n“\njeans\nse\noN\nd\ni\nPost\nMonitoring\nBorrower\nCategory\nDetails\nof\nExisting\nFacility/\nFacilities\nMechanism\nMechanism\nSerial\nDate\nStatus\nof\nthe\nDetails\nof\nStatus\nof\nthe\nNo.\nType\nof\nBusiness\ntransferred\nTotal\nfinancial/non-\nMechanism\nRescheduled/\nAny\nadditional\nOther\nRescheduled/Restructured\nIndividual/Business\n(Micro/Small/Me\nSector\nthe\nPost\n(performing/\nAmount\nfianancial\n(Rescheduled/\nRestructure/New\nfacilities)\nmeasures\n/\nNew\nLoan\nGranted\ndium/Corporate)\nCOVID\nnon-\noutstanding\nstrategies\nfor\nRestructured/ loan\ngranted\ndate\ngranted\ntaken,\nif\nany\n(Performing/Non-\nUnit\nperforming)\nNew\nLoan)\nPefroming)\nColumn\nSectors\nbe\nmentioned\nas\nper\nthe\nSectorwise\nReturn,\nspecify\nsub-sectors\nif\napplicable\nColumn\nOutstanding\nbalance/s\nof\nfa\nity/faci\ns\nthat\nconsidered\nfor\nPlease\nemail\nthe\nposition\nas\nat\nthe\nend\nof\neach\nquarter,\nwithin\nworking\ndays\ncommencing\nfrom\n31.03.2022\nbsddb@cbsl. k', 'High', 'pending_approval', NULL, 1, NULL, NULL, NULL, '{\"department_ids\": [], \"broadcast\": true, \"ack_days\": 7}', '2026-07-17 06:58:08', NULL),
(46, '02/2022', 'CONCESSIONS TO AFFECTED BORROWERS AMIDST THE PREVAILING EXTRAORDINARY MACROECONOMIC CIRCUMSTANCES', '2021-07-07', '/www/wwwroot/circular/backend/uploads/fe97838de92141a6810411c4c593acdc_bsd_circular_no_2_of_2022_e.pdf', 2859, 'O7 July 2022\nCONCESSIONS TO AFFECTED BORROWERS AMIDST THE PREVAILING\nEXTRAORDINARY MACROECONOMIC CIRCUMSTANCES\nWith a view to meeting the challenges faced by businesses and individuals engaged in various\neconomic sectors due to the prevailing extraordinary macroeconomic circumstances, the Central\nBank of Sri Lanka (CBSL), requests licensed commercial banks and licensed specialised banks\n(hereinafter referred to as licensed banks) to provide the following concessions, to affected\nborrowers, on a need basis.\nThese concessions are granted to devise suitable repayment arrangements based on the new\nrepayment capacities of the borrower, on a case-by-case basis, while preserving banking sector\nstability by preventing any elevated strain on the financial system. Accordingly, this Circular is\nissued to provide broad guidelines with prudential requirements for consistent implementation\nacross all licensed banks. Licensed banks may consider implementing these concessions through\nthe Post COVID-19 Revival Units which have already been established in terms of the Circular\nNo. 01 of 2022 issued on 24 March 2022.\nConcessions for performing credit facilities\nLad\nLicensed banks are required to provide appropriate concessions (i.¢., grace period for\ncapital or interest or both capital and interest or part of the capital or interest, re-structuring\nof credit facilities, or any other concession) for performing credit facilities of individuals\nor businesses (hereinafter referred to as borrowers) whose income or business has been\nadversely affected by the current macroeconomic conditions including those borrowers\nwho were already subject to COVID-19 moratoriums. These concessions are expected to\nbe provided to affected borrowers in all economic sectors, including but not limited to\ntourism, transportation, and Micro, Small and Medium scale Enterprises (MSME) engaged\nin business sectors such as manufacturing, services, agriculture, and construction on a case-\no7 July 2022\n3,1\nby-case basis, for a period of six months from the date of this Circular, based on the new\nrepayment capacity/ viability of the borrower.\nIn the case of regular installment loans, the licensed banks shall devise a mechanism to\nstructure the repayment plan not exceeding the contracted instalment value of the existing\ncredit facility or facilities, with an extended tenure, to match with the repayment\ncapabilities of the borrowers. In the case of other credit facilities, the licensed banks shall\ndevise a suitable mechanism to structure the repayment plan.\nIn the case of Rupee facilities considered for the concessions, the interest rate applicable\nfor the concessionary period (including the recovery period) shall not exceed the latest\ncontracted rate of interest or the Standard Lending Facility Rate applicable on the date of\nthis Circular (15.5%), whichever is higher, and shall be charged only on the amount\nconsidered for the concession. In the case of foreign currency facilities, licensed banks may\ncharge a concessionary rate of interest rate as mutually agreed with the customer.\nApplicability of Concessions for Credit Facilities Granted under Refinance/Interest\nSubsidy Schemes\nLicensed banks shall seek necessary guidelines from the relevant agencies, and government\nauthorities with regard to extending these concessions for credit facilities granted under\nvarious refinance or interest subsidy schemes, introduced by the government or other\nagencies.\nFacilitating Early Settlements\nIn the case where any borrower wishes to fully settle any of the existing credit facilities,\nsuch borrower shall be given the opportunity to do so, without charging any additional fee,\nsuch as early settlement charges. In the case of lease facilities, recovery of future interest\nshall also be waived off.\nOT July 2022\n3.2:\nLicensed banks may also consider providing rebates for such early settlements, on a case-\nby-case-basis.\nAny borrower who is willing for an early settlement of credit facilities shall make a request\nto the respective licensed bank on or before 30.09.2022.\nConcessions for Non-performing Credit Facilities\nLicensed banks may consider providing appropriate concessions, including reschedulment\nfor existing non-performing credit facilities over a longer period, on a case-by-case basis,\nconsidering the future repayment capacity/viability of such individuals and businesses/\nprojects.\nLicensed banks shall devise a suitable mechanism to structure the repayment plan.\nIn the case of Rupee facilities, interest rate applicable for concessions granted to non-\nperforming credit facilities, shall not exceed the latest contracted rate of interest or the\ncurrent Standard Lending Facility Rate applicable as at the Circular date (15.5%),\nwhichever is higher!. In the case of foreign currency facilities, licensed banks may charge\na concessionary rate of interest rate as mutually agreed with the customer.\nLicensed banks shall suspend recovery actions including parate execution and forced\nrepossession of leased assets against all credit facilities that have been classified as non-\nperforming on or after 01.01.2020, until 31.12.2022 in order to enable the borrowers to\narrange timely repayments.\nIn the case of recovery actions against SME paddy millers, banks may suspend recovery\nactions including parate execution against any non-performing credit facilities, until\n31.12.2022, provided that an agreement is reached between the borrower and the licensed\nbank on diverting sales proceeds of the upcoming harvesting season directly to the banks\n\' The explanation on non-performing loans provided in the attached Guidelines of CASL states that “the revised\ninterest rate cannot exceed 14.5%”. However, licensed banks should adhere with Section 4.3 of this Circular.\nOT July 2022\nvia a suitable mechanism to settle the existing pledge loans in full and/ or existing non-\nperforming credit facilities (part or full settlement).\nIn case where a licensed bank has commenced or given notice of recovery action under the\nprovisions of the Recovery of Loans by Banks (Special Provisions) Act, No. 04 of 1990 or\nMortgage Act. No. 06 of 1949, as amended, or Finance Leasing Act, No. 56 of 2000, or\nany other relevant Act, in this regard, such recovery actions shall be suspended until\n31.12.2022, on condition that the concerned licensed bank and the borrower reach a debt\nrepayment agreement.\nLicensed banks shall defer passing new resolutions under the above Acts, for recovery of\nsuch loans and advances until 31.12.2022, on condition that the concerned licensed bank\nand the borrower reach a debt repayment agreement. In instances where resolutions for\nrecovery actions have already been passed, auctioning of assets shall be suspended until\n31.12.2022.\nIn instances where there are on-going litigations in Courts relating to recovery, the\nborrower shall enter into an agreement in the Courts to avail these concessions.\nHowever, willful defaulters, defaults due to diversion of funds, defaults due to\nmismanagement and/ or frauds in the business and unviable projects shall not be considered\nfor any of the above concessions.\nLicenced banks may continue the routine collection procedure/ recovery follow up without\nexcessively contacting, visiting, or forcing the borrower.\nReporting to the Credit Information Bureau\nLicensed banks shall not decline new loan applications from borrowers solely based on\nadverse CRIB records.\nLicensed banks shall develop a reporting modality, in consultation with CRIB, to report\nconcessions granted to affected borrowers, if necessary.\no7 July 2022\nAccounting Treatment and Impairment\nLicensed banks shall adhere to Sri Lanka Accounting Standards and the attached\nGuidelines read with the Addendum issued by the Institute of Chartered Accountants of\nSri Lanka (CASL) with regard to accounting for the facilities considered for concessions.\nLicensed banks may seek advice from CASL and Auditors for additional guidance/\nclarifications in this regard.\nTransparency of the Concessions\n7A\nEligible borrowers may request for the above concessions on or before 31 July 2022 in\nwriting or through electronic means.\nLicensed banks shall make the decision on whether to accept or decline the request made\nby the borrower within one month of the receipt of the request and duly inform the borrower\nof such decision.\nIn the case of a rejection of request, licensed banks shall inform the borrower the reasons\nfor such rejection and shall advise the borrower by and through the same letter that there\nis an opportunity for the borrower to appeal against such rejection to the Director, Financial\nConsumer Relations Department of the Central Bank of Sri Lanka.\nLicensed banks shall ensure that the borrowers are made aware of the structure of the\ndeferment or restructuring of credit facilities and the applicable interest rate prior to\napproval and the consent of the borrower shall be obtained in writing or through electronic\nmeans.\noT July 2022\nReporting Requirement\nLicensed banks shall report the details of concessions availed by their borrowers to the\nBank Supervision Department, as at each month end, within 15 working days, commencing\nfrom 31 July 2022. A reporting format will be issued in due course.\nr. P Nandalal Weerasinglyve\nChairman of the Monetary Board and\nGovernor of the Central Bank of Sri Lanka\nLetter 01 - CASL\nCA\nTHE INSTITUTE OF\nCHARTERED ACCOUNTANTS OF SRI LANKA\n28! June 2022\nMrs. V. A. A. N. De Silva,\nDirector Bank Supervision,\nCentral Bank of Sri Lanka,\nPO Box 590,\nColombo 01.\nDear Ms. De Silva,\nRe: Clarifications on Accounting Treatments\nWe refer to your letter dated 13\'\"\" June 2022 on the above heading. At the outset,\nwish to extend my\nappreciation to the Central Bank of Sri Lanka (CBSL) for referring the “Draft Guidelines to the licensed banks\non providing concessions to affected borrowers” and requesting to clarify the accounting treatment as per\nSLFRS 9 - Financial Instruments.\nPlease find below the clarification you sought as per the recommendation made by the Institute of Chartered\nAccountants of Sri Lanka (CA Sri Lanka).\nIssue 1: Interest Recognition\nCA Sri Lanka does not provide any specific additional guidance on interest recognition and modification since\nspecific provisions are available in SLFRS 9 - Financial Instruments.\nPlease refer\nto SLFRS 9.5.4.1, SLFRS 9.5.4.2, SLFRS 9.5.4.3, SLFRS 9.3.3.2 and SLFRS 9.B3.3.6.\nAccordingly, Interest income can be recognised by the banks by using the Effective Interest Rate (EIR) applied\nto the gross carrying amount or the net carrying amount considering the stage into which that loan belongs at\nthe time of the modification. In the event of modification (after the test of 10% assessment), the interest will be\nrecognised based on the initial contractual rate while in the case of derecognition (due to substantial\nmodification), interest will be recognized based on the new contractual rate. Thus, modification gain or loss has\nto be charged to profit or loss.\nIssue 2: Assessment of impairment and staging for performing facilities and non-performing\nAs per the draft guideline, Banks would do their own assessment of granting concessions to affected borrowers’\nconsidering the prevailing extraordinary macroeconomic conditions. Accordingly, CA Sri Lanka recommends\nthe banks to carryout assessment of Significant Increase of Credit Risk (SICR) within Banks\' own\nassessment (the internal risk management, policies, and methodologies) taking into the consideration of the\nnumber of restructurers/ re-shedulements, number of counts for the assessment of SICR, staging the loans into\nstages 1 to 2 and 2 to 3 in line with the standard as well as the CBSL Directive 13 and 14 and relevant sections\nof SLFRS 9. The proposed restructure/ reschedulement should not be excluded from the count.\nThe relevant sections of SLFRS 9 - Financial Instruments are provided in SLFRS 9.5.5.9 - SLFRS 9.5.11.\nFurther, CA Sri Lanka recommends the banks to revise their existing risk management considerations to assess\nSICR considering the prevailing economic conditions and potential deterioration without continuing to use the\nexisting policies which were built on pre COVID trends and factors when economic factors had not deteriorated\nsignificantly.\nIn addition to that, the following considerations are to be placed on performing loans and non-performing loans\nby banks.\nThe Institute of Chartered Accountants of Sri Lanka 30A, Malalasekera Mawatha, Colombo 7, Sri Lanka.\nTel: +94 (0) 11 2352000 Fax: +94 (0) 11 2588783 E-mail: technical@casrilanka.org\nhttps://casrilanka.com\nCAl\nTHE INSTITUTE OF\nCHARTERED ACCOUNTANTS OF SRI LANKA\nFor Performing Loans:\ne\nItis a rebuttable presumption that the current economic condition together with the requirement of further\nmoratorium would indicate the Significant Increase in Credit Risk (SICR).\ne — Itis necessary to consider the financial strength of the borrower.\n¢\nIt is necessary to consider number of restructures including previous moratoriums into the account of the\nproposed restructure.\n¢\nThe increased economic uncertainty about potential future economic scenarios and their impact on credit\nlosses may require banks to explicitly consider additional economic scenarios when measuring ECLs\n[SLFRS 9.B5.5.42].\ne\nExisting ECL models use historical experience to derive links between changes in economic conditions and\ncustomer behaviour, and ECL parameters such as loss rates, probabilities of default and loss given default.\nThese historical relationships are unlikely to remain stable in times of increased economic uncertainty.\nFor Non-Performing Loans:\nA staging issue would not arise since the category of loans is already in stage 3. However, if the bank is\nextending the repayment plan based on its own assessment, that could result in additional impairment, given\nthat the revised interest rate cannot exceed 14.5% and recovery action cannot be taken until 31st December\nIssue 3: Recommendation on section 6. 2\nAs per CBSL draft guideline, section 6.2 has been drafted as “Licensed banks are required to provide a\nminimum impairment charge of 2.0% on top of existing Stage 1 or 2 impairments for credit facilities that are\nconsidered as modifications”. Due to the ambiguity of the wording, CA Sri Lanka is to seek clarification from\nCBSL on the wording relating to this requirement. Nevertheless, CA Sri Lanka commented section 6.2 of the\nproposed guideline under two scenarios as below:\nScenario 01:\nBased on assessment of SICR/default if the loans to be restructured/ rescheduled are moved to stage 2 from\n1 or Stage 3 from stage 2 the impairment against such loans will increase compared to existing impairment\nagainst the respective loans.\nIf such increase is 2% higher than existing impairment such increase to be\nconsidered as normal change in impairment and recognized in the Profit or Loss statement.\nScenario 02:\nIf the banks are required to record additional 2% over and above the increase recorded as per scenario 1 even\nafter stage shifting, Accounting Standards does not permit recording such impairment.\nThis explanation is provided purely based on the limited facts and information provided by you and as such the Institute of\nChartered Accountants of Sri Lanka takes no responsibility if the explanation would have been different had more\ninformation been available. Further, the application of the Sri Lanka Accounting Standards requires exercise of judgement,\ntherefore, the ultimate responsibility for the recognition, measurement, presentation and disclosures of any transaction rests\nwith the preparers of the financial statements. In providing this clarification. We have exercised due care and diligence and\ntherefore we believe that the clarification given herewith is appropriate.\nThank you,\nYours sincerely,\nTHE INSTITUTE OF CHARTERED ACCOUNTANTS\nOF SRI LANKA\nBach\nManil Jayesinghe\nCHAIRMAN - ACCOUNTING STANDARDS COMMITTEE\nThe Institute of Chartered Accountants of Sri Lanka 30A, Malalasekera Mawatha, Colombo 7, Sri Lanka.\nTel: +94 (0) 11 2352000 Fax: +94 (0) 11 2588783 E-mail: technical@casrilanka.org\nhttps://casrilanka.com\nLetter 02 - CASL\nCA\nTHE INSTITUTE OF\nCHARTERED ACCOUNTANTS OF SRI LANKA.\n6\" July 2022\nMrs. V. A. A. N. De Silva,\nDirector Bank Supervision,\nCentral Bank of Sri Lanka,\nP O Box 590,\nColombo 01.\nDear Ms. De Silva,\nRe: Clarifications on Accounting Treatments\nThis is in reference to the letter that CA Sri Lanka sent to Bank Supervision at the Central Bank of Sri Lanka on\n28th June 2022 about the aforementioned subject.\nHereby we need to clarify that re-profiling of performing loans where the quantum of the loan repayment is not\nless than what was there before the re-profiling would not generally cause a Significant Increase of Credit Risk.\nHowever, it is necessary to evaluate the condition of the underlying business if these loans have been under\nmoratorium.\nThis explanation is provided purely based on the limited facts and information provided by you and as such the\nInstitute of Chartered Accountants of Sri Lanka takes no responsibility if the explanation would have been\ndifferent had more information been available. Further, the application of the Sri Lanka Accounting Standards\nrequires exercise of judgement, therefore, the ultimate responsibility for the recognition, measurement,\npresentation and disclosures of any transaction rests with the preparers of the financial statements. In providing\nthis clarification. We have exercised due care and diligence and therefore we believe that the clarification given\nherewith is appropriate.\nThank you,\nYours sincerely,\nTHE INSTITUTE OF CHARTERED ACCOUNTANTS\nOF SRI LANKA\nBuf A_\nManil Jayesinghe\nCHAIRMAN - ACCOUNTING STANDARDS COMMITTEE\nThe Institute of Chartered Accountants of Sri Lanka 30A, Malalasekera Mawatha, Colombo 7, Sri Lanka.\nTel: +94 (0) 11 2352000 Fax: +94 (0) 11 2588783 E-mail: technical@casrilanka.org\nhttps://casrilanka.com', 'High', 'pending_approval', NULL, 1, NULL, NULL, NULL, '{\"department_ids\": [], \"broadcast\": true, \"ack_days\": 7}', '2026-07-17 07:30:35', NULL);
INSERT INTO `circulars` (`id`, `circular_number`, `title`, `issue_date`, `file_path`, `file_size_kb`, `extracted_text`, `priority`, `status`, `ack_deadline`, `uploaded_by`, `amends_circular_id`, `approved_by`, `approved_at`, `distribution_intent`, `created_at`, `published_at`) VALUES
(47, '04/2018', 'Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard – SLFRS 9: Financial Instruments', '2018-12-31', '/www/wwwroot/circular/backend/uploads/486a3be0f25c443294f2128296162cc0_Circular_04_2018_Searchable_OCR.pdf', 1164, 'CENTRAL BANK OF SRI LANKA\nBANK SUPERVISION DEPARTMENT\n31 December 2018 CIRCULAR No. 04 of 2018\nGuidelines to Licensed Banks on the Adoption of Sri Lanka Accounting\nStandard - SLFRS 9: Financial Instruments\nThe Central Bank of Sri Lanka with a view to establishing consistent and prudent practices\non the adoption of Sri Lanka Accounting Standard - SLFRS 9: Financial Instruments by\nlicensed banks in Sri Lanka, encloses the Guidelines to licensed banks on the above for\nimmediate implementation.\nA AM Thassim\nDirector of Bank Supervision\nBank Supervision Department\nCentral Bank of Sri Lanka\n31 December 2018\nGuidelines to Licensed Banks on the Adoption of\nSri Lanka Accounting Standard – SLFRS 9:\nFinancial Instruments\nThis page has been left blank intentionally\nTable of Contents\n1. Introduction ...................................................................................................................................2\n2 Objectives of Issuing Guidelines on Adoption of SLFRS 9 .........................................................2\n3. Classification and Measurement of Financial Assets and Financial Liabilities ...........................3\n4. Principles for Sound Credit Risk Management ............................................................................5\n5. Impairment of Financial Assets ....................................................................................................6\n6. Collateral Valuation ......................................................................................................................9\n7. Role of Internal Audit ...................................................................................................................9\n8. Regulatory Requirements............................................................................................................10\n9. Regulatory Reporting and Disclosures .......................................................................................10\nAnnex I - Additional Guidance on Impairment of Financial Instruments………………………... 12\nGuidelines to Licensed Banks on the Adoption of Sri Lanka Accounting\nStandard - SLFRS 9: Financial Instruments\nIntroduction\n1.1 The new Sri Lanka Accounting Standard, ‘SLFRS 9: Financial Instruments’ shall be\napplicable for financial reporting periods beginning on or after 01.01.2018 and the adoption of\nSLFRS 9 has a significant impact towards banks and other financial institutions.\n1.2 While the responsibility of preparation, presentation and disclosure of financial statements in\nline with the applicable Sri Lanka Accounting Standards is vested with the Board of Directors\n(BoD) and the senior management of licensed banks, the Central Bank of Sri Lanka (CBSL)\npromotes consistent and prudent application of SLFRS 9 in the banking sector.\n1.3 In this respect, discussions were held with the Institute of Chartered Accountants of Sri Lanka,\nthe Panel of Auditors and the banking sector to understand the concerns of licensed banks in\nthe adoption of SLFRS 9.\n1.4 These guidelines are prepared based on the ‘Guidance on Credit Risk and Accounting for\nExpected Credit Losses’ issued by the Basel Committee on Banking Supervision in December\n2015, the best practices and guidelines issued by the monetary authorities/regulators on\nimplementation of International Financial Reporting Standards 9: Financial Instruments and\ntaking into consideration the comments received from CA Sri Lanka, Panel of Auditors and\nlicensed banks in this regard.\n1.5 These Guidelines should be adopted within the requirements of SLFRS 9.\nObjectives of Issuing Guidelines on Adoption of SLFRS 9\n2.1 CBSL expects to establish consistent and prudent practices on adoption of SLFRS 9 by\nlicensed banks in Sri Lanka.\n2.2 Accordingly, licensed banks are required to adhere to the following Guidelines (in addition to\nthe existing applicable regulations) as a minimum; on classification and measurement of\nfinancial assets and financial liabilities, management of credit risk, impairment of financial\nassets, valuation of collaterals, role of the internal audit, regulatory and reporting requirements;\nwhen preparing, presenting and publishing financial statements.\nClassification and Measurement of Financial Assets and Financial Liabilities\n3.1 Classification and measurement of Financial Assets\n(a) Business models approved by BoD (overseeing authority in respect of banks incorporated\noutside Sri Lanka) shall be in place to facilitate classification of financial assets. For this\npurpose, sufficient documentation on objectives, definitions, characteristics, criteria and\noperating policies along with adequate procedures and systems for assessing the business\nmodels on an on-going basis shall be in place.\n(b) Such operating policies shall include, at a minimum, the decision-making authorities for\nbusiness model decisions, level of sales to be considered as infrequent and insignificant,\ntime period for near term selling to be considered for trading purposes, election of fair\nvalue option for instruments through profit or loss and through other comprehensive\nincome.\n(c) In terms of SLFRS 9, debt instruments shall pass the SPPI test (contractual cash flows to\nmeet Solely Payments of Principal and Interest) and if so such instruments shall be\nclassified as ‘financial assets at amortised cost (AC)’ or ‘financial assets at fair value\nthrough other comprehensive income (FVOCI)’ based on the outcome of the business\nmodel test.\n(d) Licensed banks are required to maintain standardised processes, detailed checklists and\ndecision trees in order to assess and identify SPPI features of their products and contracts.\n(e) Accordingly, broad classification and subsequent measurement of financial assets are\ngiven in Table 1 below.\nTable 1 - Classification and Measurement of Financial Assets\nBusiness Model\nKey Characteristics\nClassification &\nSubsequent Measurement\nDebt Instruments1\nHeld-to-collect\n- Hold assets to collect contractual\ncash flows\n- Meet SPPI test\n- Infrequent and insignificant sales\nAmortised Cost\n1 In addition to these key characteristics other features of the product, management compensation, risk management\naspects, frequency and significance of sales, etc. must also be considered.\nBoth held to collect and\nfor sale\n- Both collecting contractual cash\nflows and sales\n- More frequent and significant\nsales\nFair value through other\ncomprehensive income\nOther business models,\nincluding;\nTrading\nManaging assets on a\nfair value basis\nMaximising\ncash\nflows through sale\n- Neither ‘held-to-collect’ nor ‘held\nto collect and for sale’\n- Collection of contractual cash\nflows is incidental\nFair value through profit or\nloss\nEquity and Derivative Instruments\nEquity Instruments\n- Held for trading\nFair value through profit or\nloss\n- Not for trading and not elected\nthe irrevocable OCI option\nFair value through profit or\nloss\n- Not for trading and elected the\nirrevocable OCI option\nFair value through other\ncomprehensive income\nDerivative Instruments\nFair value through profit or\nloss\n3.2 Classification and measurement of Financial Liabilities\n(a) Broad classification and measurement of financial liabilities are given in Table 2 below.\nTable 2 - Classification and Subsequent Measurement of Financial Liabilities\nClassification of Financial\nLiabilities\nSubsequent\nMeasurement\nAccounting for Fair Value Gain\nFinancial liabilities held for\ntrading\nFair value\nThrough profit or loss\nFinancial liabilities\ndesignated at fair value\nFair value\nThe amount of change in fair value\nattributable to changes in credit risk in\nliability presented in other comprehensive\nincome 2 and remaining amount shall be\npresented in income statement.\nOther financial liabilities at\namortised cost\nAmortised Cost\n(b) If a licensed bank is accounting for its financial liabilities as designated through profit or\nloss, changes in value of such liabilities due to changes in own credit risk are required to\nbe assessed and accounted through other comprehensive income as stated above. Licensed\nbanks are requested to formulate internal guidelines and criteria for this purpose\n3.3 Reclassification\n(a) If the objective of the business model of the licensed bank for its financial assets changes\nand its previous model assessment would no longer apply, reclassification is required\nbetween financial assets under the provisions of SLFRS 9.\n(b) In line with the requirements of SLFRS 9, such changes in business models and\nreclassifications shall be approved by the BoD and shall be notified to the Director of Bank\nSupervision within 7 working days of the date of such approval.\n3.4 Measurement at Fair Value\nWhen financial instruments are subsequently measured at fair value, licensed banks shall\ncomply with the requirements given in ‘Sri Lanka Accounting Standard - SLFRS 13: Fair\nValue Measurement’ and are required to:\n(a) Use an appropriate valuation technique for which sufficient data is available;\n(b) Apply the selected valuation technique consistently;\n(c) Maximise the use of relevant observable inputs. In exceptional circumstances,\nunobservable inputs may be used; and\n(d) If inputs under level 3 hierarchy are used in the respective valuation technique, the Chief\nRisk Officer or most senior officer overseeing the risk management function shall confirm\nthe appropriateness and reliability of such inputs.\nPrinciples for Sound Credit Risk Management\n4.1 BoD and the senior management are responsible for ensuring that the licensed banks have\nappropriate credit risk practices, including an effective system of internal control, to\nconsistently determine adequate impairment allowances in accordance with the policies and\n2 If that treatment creates or enlarges an accounting mismatch in profit or loss, an entity shall present all gains or losses\non that liability (including the effects of changes in the credit risk of that liability) in profit or loss.\nprocedures of licensed banks, the applicable Sri Lanka Accounting Standards and relevant\nsupervisory guidance.\n4.2 Licensed banks shall document and adhere to sound methodologies that address policies,\nprocedures and controls for assessing and measuring credit risk on all financial assets. The\nmeasurement of impairment allowances should build upon those robust methodologies and\nresult in the appropriate and timely recognition of expected credit losses in accordance with\nthe applicable Sri Lanka Accounting Standards.\n4.3 The aggregate amount of impairment allowances of licensed banks, regardless of whether\nallowance components are determined on a collective or an individual basis, should be\nadequate and consistent with the objectives of the applicable Sri Lanka Accounting Standards.\n4.4 Licensed banks shall have policies and procedures in place to validate models used to assess\nand measure expected credit losses.\n4.5 Licensed banks shall use experienced credit judgment, especially in the robust consideration\nof reasonable and supportable forward-looking information, including macro-economic\nfactors, to measure the expected credit losses.\n4.6 Licensed banks should have a sound credit risk assessment and measurement process with the\nsupport of adequate systems, tools and data to assess credit risk and to account for expected\ncredit losses.\n4.7 Licensed bank’s public disclosures should promote transparency and comparability by\nproviding timely, relevant and useful information.\nImpairment of Financial Assets\n5.1 Calculation of Expected Credit Losses\nLicensed banks are required to calculate expected credit losses for the following:\n(a) Financial assets measured at AC\n(b) Financial assets mandatorily measured at FVOCI\n(c) Loan commitments when there is an obligation to extend credit (except those measured at\nFair Value through Profit or Loss)\n(d) Financial guarantee contracts (except those measured at Fair Value through Profit or Loss)\n(e) Lease receivables within the scope of LKAS 17: Leases\n(f) Contract assets within the scope of SLFRS 15: Revenue from Contracts with Customers\n5.2 Life-time Expected Credit Losses and 12 Month Expected Credit Losses\n(a) At each reporting date, licensed banks shall measure the loss allowance for financial\ninstruments at an amount equal to life-time expected losses, if the credit risk of a financial\ninstrument has increased significantly since initial recognition (except for the purchased\nor originated credit-impaired financial assets).\n(b) For purchased or originated credit impaired financial assets, lifetime expected credit\nlosses shall be measured.\n(c) In principle, life time expected credit losses and credit impaired loans are provided on an\nindividual basis. However, due to lack of borrower-specific information, licensed banks\nmay perform the assessment on appropriate groups or portfolios on a collective basis.\n(d) At the reporting date, if the credit risk of a financial instrument has not increased\nsignificantly since the initial recognition, licensed banks shall measure the loss allowance\nfor that financial instrument at an amount equal to 12 month expected credit loss.\n5.3 Economic Factor Adjustment\n(a) Licensed banks shall use the forecasts and projections published by CBSL, International\nMonetary Fund and/or World Bank in all instances where such projections are available\nwhen adjusting credit provisioning models to reflect the economic conditions and\nforecasts.\n(b) If the required information is not available through above sources, licensed banks shall\nuse credible alternative sources and shall maintain documentary evidence.\n(c) BoD approved policies shall be available to specify the sources to be used and licensed\nbanks shall not cherry pick sources in their favour.\n5.4 Significant Increase in Credit Risk\nFor the purpose of calculating life-time expected losses, as a minimum, if one or more of the\nfollowing factors/conditions are met, it shall be considered as a significant increase in credit\nrisk:\n(a) When contractual payments of a customer are more than 30 days past due 3 (subject to\nthe rebuttable presumption in the SLFRS 9);\n(b) When the risk rating of a customer or an instrument has been downgraded to B+ by an\nexternal credit rating agency and/or when there is a two-notch downgrade in the banks\ninternal rating system. In the event no external credit rating is available, licensed banks\nare required to map their internal credit risk ratings with the ratings issued by the External\nCredit Assessment Institutions (ECAI). For this purpose, licensed banks are required to\nrefer the mapping of external credit ratings given in Direction No. 1 of 2016 on Capital\n3 Days past due shall be calculated from contractual due date of the payment.\nRequirements under Basel III for Licensed Commercial Banks and Licensed Specialised\nBanks;\n(c) When reasonable and supportable forecasts of future economic conditions directly affect\nthe performance of a customer/group of customers, portfolios or instruments;\n(d) When there is a significant change in the geographical locations or natural catastrophes\nthat directly impact the performance of a customer/group of customers or an instrument;\n(e) When the value of collateral is significantly reduced and/or realisibility of collateral is\ndoubtful. Limits shall be set and documented by licensed banks;\n(f) When a customer is subject to litigation, that significantly affects the performance of the\ncredit facility;\n(g) Frequent changes in the senior management of an institutional customer;\n(h) Delay in the commencement of business operations/projects by more than two years from\nthe originally agreed date;\n(i) Modification of terms resulting in concessions, including extensions, deferment of\npayments, waiver of covenants etc.;\n(j) When the customer is deceased/insolvent;\n(k) When the bank is unable to contact or find the customer;\n(l) A fall of 50% or more in the turnover and/or profit before tax of the customer when\ncompared to the previous year; and\n(m) Erosion in net-worth by more than 25% when compared to the previous year.\n5.5 Models for Calculation of Expected Credit Losses\n(a) Licensed banks shall consider all available and relevant internal and external data when\nestimating expected credit losses, ensuring that the estimates are robust, unbiased and\nreflective of current exposures.\n(b) Licensed banks shall develop robust models to determine expected credit losses under\nSLFRS 9. Such models shall be tailored to reflect the bank’s risk profile.\n(c) Licensed banks shall ensure that the relevant officers are well trained and competent on\nunderstanding the models adopted by them for this purpose.\n(d) When obtaining support from external vendors/consultants in respect of model\ndevelopment, rigorous governance and internal control processes shall be adhered.\n(e) If different models are used for different portfolios and instruments, licensed banks are\nrequired to document the reasons why the selected model is appropriate and all credit\nmodels must be reviewed at least annually.\n(f) An effective model validation process shall be established to ensure that the credit risk\nassessment and measurement methods are able to generate accurate, consistent and\nunbiased predictive estimates on an ongoing basis.\n(g) Licensed banks are required to desist from making changes in the parameters, inputs and\nassumptions used for the purpose of profit smoothening. The rationale and justification\nfor any changes in the expected loss models shall be documented and justified by the\nChief Risk Officer and approved by the BoD.\n(h) Assumptions concerning the impact of changes in general economic developments on\nborrower’s repayment capacity, shall be made with sufficient prudence.\n(i) In cases where banks incorporated outside Sri Lanka use models developed by head\noffice or regional offices, to ensure appropriateness of the credit models to the Sri Lankan\ncontext, the local implementation team should carry out appropriate validation\nprocedures.\n5.6 Further, in respect of impairment of financial instruments, licensed banks shall follow the\nguidance given in Annex I.\n5.7 These guidelines are expected to be reviewed in future, looking at the market developments,\ndata quality, model development and capacity within the banking sector.\nCollateral Valuation\n6.1 Expected cash flows from collateral realization shall be based on latest observed reliable\nmarket valuations and shall appropriately reflect the inherent uncertainty associated with\ndistressed property liquidation (including the time taken for such realisation).\n6.2 Any increase in valuations shall be substantiated by solid evidence that such increases are\nsustainable.\nRole of Internal Audit\n7.1 The Internal Audit function shall independently evaluate the effectiveness of the credit risk\nassessment, measurement systems and processes of licensed banks and shall ensure the\nacceptability of credit judgments.\n7.2 Internal Audit function shall validate and evaluate all credit risk assessment models, inputs and\nassumptions used along with data smoothening, if any.\n7.3 Internal audit function shall provide assurance over the adequacy and effectiveness of back\ntesting, in order to ensure that the key drivers have been captured and calibrated accurately.\nRegulatory Requirements\n8.1 In line with the international best practices, CBSL is of the view that the existing prudential\nregulations pertaining to assets classification, measurement and provisioning should be in\nforce.\n8.2 Accordingly, licensed banks shall submit all periodical information including web based\nstatutory returns to CBSL in accordance with the existing Orders, Determinations, Directions,\nGuidelines, Circulars and Instructions issued.\n8.3 Licensed banks shall maintain adequate data/records and systems separately to identify,\nreconcile and report requirements under the Sri Lanka Accounting Standards and under the\nexisting regulatory framework.\n8.4 Impact on expected credit loss provisioning is required to be captured when preparing capital\nplanning and stress testing processes of licensed banks.\n8.5 In order to avoid stress on capital and in line with the guidance given by the Basel Committee\non Banking Supervision, licensed banks shall stagger audited additional credit loss provisions\narising from SLFRS 09 when compared with credit loss provisions under LKAS 39 as at first\nday of adoption of SLFRS 9, net of any other adjustment on first day impact to retained earnings\nand net of tax effects, throughout a transitional period of four years as given below for the\npurpose of calculating the Capital Adequacy Ratio (CAR) under Banking Act Directions No.\n01 of 2016 on Capital Requirements under Basel III.\nTable 3 - Staggering of First Day Impact for Capital Adequacy Ratio Computation\nRegulatory Reporting and Disclosures\n9.1 Licensed banks shall disclose the total amount of first day impact arising from the adoption of\nSLFRS 9 and its impact to CAR as specified in 8.5 above throughout the transitional period in\nthe financial statements.\n9.2 However, the first day impact shall be fully adjusted in the financial statements on the first day\nof adoption of SLFRS 9.\n9.3 Licensed banks are required to report the information set out in Tables 4 and 5 below to the\nBank Supervision Department through bsddb@cbsl.lk within 30 days after the end of each\nquarter, commencing 31.12.2018.\nCumulative Percentage of Absorption of First Day Impact\n01.01.2018\n31.12.2018\n31.12.2019\n31.12.2020\n31.12.2021\nTable 4 – Probability of Defaults (PD) and Loss Given Defaults (LGD)\non Collective Impairment as at …..….\nBusiness Segment/Product/\nCategory or any Other\nBasis\nPD\nLGD\nStage 1\nStage 2\nStage 3\nStage 1 Stage 2\nStage 3\nTable 5 - Upgrading of Credit Facilities/Exposures for the Computation of\nExpected Credit Losses for the Quarter Ended as at ……….\nNumber of Facilities upgraded\nFrom stage 2 to stage 1\nFrom stage 3 to stage 1\nFrom stage 3 to stage 2\nValue of Total Facilities Upgraded\nFrom stage 2 to stage 1 (Rs.mn)\nFrom stage 3 to stage 1 (Rs.mn)\nFrom stage 3 to stage 2 (Rs.mn)\nTotal of interest income re-recognised to the income\nstatement on upgrading to Stages 2 and 1. (Rs.mn)\nAnnex I\nAdditional Guidance on Impairment of Financial Instruments\nThe following guidance is provided with a view to improving and maintaining the\nconsistent application and comparability within the banking sector when calculating expected\ncredit losses under SLFRS 9.\nGuidance on Minimum Criteria to be met by all licensed banks for categorisation\nof credit facilities/exposures into stages for computation of expected credit losses is\nas follows:\n1.1 Stage 1\nAll credit facilities, which are not categorised under Stages 2 or 3 below.\n1.2 Stage 2\n(a) Credit facilities, where contractual payments of a customer are more than 30 days\npast due, other than the credit facilities categorised under Stage 3 below, subject to\nthe rebuttable presumption as stated in SLFRS 9.\n(b) All restructured1 loans, which are restructured up to two times, other than credit\nfacilities/exposures mentioned in 3.2 below.\n(c) Under-performing credit facilities/exposures as identified in paragraph 5.4 of the\n“Guidelines to Licensed Banks on the Adoption of SLFRS 9: Financial\nInstruments”.\n1.3 Stage 3\n(a) Credit facilities where contractual payments of a customer are more than 90 days\npast due, subject to the rebuttable presumption as stated in SLFRS 9.\n(b) All restructured loans, which are restructured more than twice, other than credit\nfacilities/exposures mentioned in 3.2 below.\n(c) All rescheduled2 loans, other than credit facilities/exposures mentioned in 3.2\nbelow.\n(d) All credit facilities/customers classified as non-performing as per CBSL Directions.\n(e) Non-performing credit facilities/customers as identified in the paragraph 5.4 of the\n“Guidelines to Licensed Banks on the Adoption of SLFRS 9: Financial\nInstruments”.\n1 Restructured facilities are where the original repayment terms have been amended due to a deterioration in\ncredit quality, while the respective credit facility remained as Performing loans and advances as per CBSL\nDirections.\n2 Rescheduled facilities are where the original repayment terms have been amended, while the respective credit\nfacility remained as Non-performing loans and advances as per CBSL Directions.\nGuidance for computation of the Probability of Default (PD) and Loss Given\nDefault (LGD) to be used as a minimum for the calculation of expected credit\nlosses is as follows.\n2.1 Licensed banks shall use at least five-year data when calculating PDs and any\nsmoothing of data or inputs must be validated by the Risk Management Department.\n2.2 Licensed banks shall not use proxies to compute PDs and LGDs, unless the bank is a\nnewly incorporated bank with inadequate credit history of less than 5 years.\n2.3 When the licensed bank is unable to compute LGDs due to lack of data or inputs, such\nbank is required to use a minimum LGD of 45 per cent for such exposures.\n2.4 Licensed banks shall use of an LGD of 0 per cent for same currency denominated cash\nbacked loans with a haircut of over 10 per cent and subject to meeting the conditions in\nsection 4(2) of Banking Act Direction No.3 and 4 of 2008 Classification of Loans and\nAdvances, Income Recognition and Provisioning.\n2.5 With respect to exposures denominated in foreign currencies issued by the sovereigns,\nfollowing shall be considered:\n(a) Licensed banks shall compute PDs by using a sovereign PD which is linked to the\nexternal credit rating scale.\n(b) A 20 per cent LGD shall be applied as a minimum when computing expected\nlosses.\n2.6 When calculating LGD for exposures guaranteed by the Government of Sri Lanka:\n(a) An LGD of zero can be applied to exposures with the guarantee of the Government\nprovided that the guarantee is fully covered with the interest and reported as\nliabilities of the Government.\n(b) LGD for any other form of assurance other than in item 2.6 (a) above shall be\ncomputed instead of using a zero LGD.\n(c) A minimum LGD of 20 per cent shall be applied for Government guarantees\ndenominated in foreign currency.\nOther Guidance\n3.1 Off-balance sheet exposures: when converting off-balance sheet exposures for\nexpected credit loss calculations, licensed banks may use the values as per the credit\nconversion factors specified in the Banking Act Direction No. 01 of 2016 on Capital\nRequirements under Basel III, if historical data is not available.\n3.2 Upgrading of credit facilities: when upgrading credit facilities from a higher stage to a\nlower stage (e.g., from stage 3 to stage 2)\n(a)\nThe upgrading of credit facilities shall only be carried out by Risk Management\nDepartment and be independent from the loan review mechanism.\n(b)\nSuch upgrading shall be supported with a BoD approved policy, rationale and\nwith adequate documentation.\n(c)\nWhen upgrading restructured facilities, satisfactory performing period of a\nminimum 90 days must be considered subsequent to the due date of the 1st\ncapital and/or interest installment post-restructure. With respect to upgrading\nrescheduled facilities, licensed banks must comply with Banking Act Directions\nNo.3/4 of 2008 on Classification of Loans and Advances, Income Recognition and\nProvisioning.\n3.3 Internal Rating Based (IRB) credit rating: A licensed bank shall not use IRB credit\ninformation for expected credit loss calculations without complying with the following:\n(a)\nPricing mechanism shall be mapped with IRB information;\n(b)\nShall have at least five-year IRB based historical data subject to 3.3 (a); and\n(c)\nBoD approved policies shall be in place and IRB inputs and models needs to be\nreviewed independently by the Risk Management Department.', 'Medium', 'pending_approval', NULL, 1, NULL, NULL, NULL, '{\"department_ids\": [15, 16, 5, 14, 11, 10], \"broadcast\": false, \"ack_days\": 7}', '2026-07-17 07:48:48', NULL),
(48, '02/2021', 'Amendments to Circular No. 04 of 2018 on Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments', '2021-01-25', '/www/wwwroot/circular/backend/uploads/98df6b280077403c8d2e7681ae6204d2_Circular_02_2021_Searchable_OCR.pdf', 261, 'CENTRAL BANK OF SRI LANKA\nBANK SUPERVISION DEPARTMENT\n2 January 2021 CIRCULAR No. 02 of 2021\nAmendments to Circular No. 04 of 2018 on Guidelines to Licensed Banks on the\nAdoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments\nThe Central Bank of Sri Lanka, having considered the current exceptional circumstances, latest\nBudget proposal on International Sovereign Bonds and with a view to establishing consistent\npractices on the adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments\nby licensed banks, hereby issues the amendment to the Annex I of the Circular No. 04 of 2018\non Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard — SLFRS\n9: Financial Instruments.\nGuideline 2.5 (c) shall be inserted immediately after Guideline 2.5 (b) as follows:\n2.5(c) However, it is permitted to apply a minimum LGD of 10 per cent when\ncomputing expected losses for the year 2021.\nKe 2\nDirector of Bank Supervision', 'Medium', 'published', '2026-10-05 12:38:12', 1, 47, 6, '2026-09-28 12:38:12', '{\"department_ids\": [14, 15, 5, 11, 10, 16], \"broadcast\": false, \"ack_days\": 7}', '2026-07-17 08:22:48', '2026-09-28 12:38:12'),
(49, '02/2025', 'REPORTING OF INFORMATION TECHNOLOGY AND CYBERSECURITY INCIDENTS OF LICENSED BANKS', '2025-05-07', '/www/wwwroot/circular/backend/uploads/931e5effffc34cb5884cafdda8e88427_bsd_circular_no_2_of_2025_e.pdf', 2040, 'BANK SUPERVISION DEPARTMENT\n07 May 2025 CIRCULAR No. 02 of 2025\n$$ ———\nREPORTING OF INFORMATION TECHNOLOGY AND CYBERSECURITY\nINCIDENTS OF LICENSED BANKS\nThe Central Bank of Sri Lanka (CBSL) having observed the increased reliance on digital\ninfrastructure by licensed banks, the risk of cyberthreats, data breaches, and system failures\nthat require prompt and transparent reporting of such incidents to CBSL and relevant\nstakeholders to ascertain risks, mitigate potential disruptions and safeguard customer\ninformation and assets, hereby issues this Circular to licensed commercial banks and licensed\nspecialised banks (herein after referred to as “licensed banks”) with a view to ensuring the\noperational resilience of licensed banks in Sri Lanka. This Circular is issued further to the\nrequirements stipulated in the Banking Act Direction No. 16 of 2021 on “Regulatory\nFramework on Technology Risk Management and Resilience for Licensed Banks, as\namended”.\n2. Definitions: For the purpose of this Circular, the following definitions are applicable:\n2.1 Information Technology (IT) incident: An event which causes operational\ndisruption, potential financial losses, and reputational damage to a licensed bank due\nto failures or security breaches in the IT systems of such licensed bank.\n2.2 Cybersecurity incident: An event that compromises the confidentiality, integrity or\nthe availability of systems and information of a licensed bank.\n2.3 Online and digital scams: A fraudulent activity performed using the internet and\ndigital devices to deceive individuals into revealing personal, financial, or other\nsensitive information or losing their money.\n3. Categorisation of IT and cybersecurity incidents: At a minimum, following broad\ncategories of IT and cybersecurity incidents and any other such incident shall be reported\nto CBSL.\n3.1 Intrusion/ Hacking, Malware, Ransomware, Malicious Code, Virus, Phishing,\nDistributed Denial of Service (DDoS) Attacks, Social Engineering, Unauthorized\nCENTRAL BANK OF SRI LANKA\nBANK SUPERVISION DEPARTMENT\n07 May 2025 CIRCULAR No. 02 of 2025\nSystem Usage, Insider Threats, Avvaioed Persistent Threats (APTs) and Supply\nChain Attacks\n3.2 Online or digital scams affecting the customers\n3.3. Unplanned critical system outages/ interruptions/ _failures/ — slowness/\nunresponsiveness\n3.4 Regulatory non-compliances relating to IT and cybersecurity requirements\n4. Regulatory reporting: Licensed banks are required to report the above incidents to the\nDirector, Bank Supervision Department via techrisk.bsd@cbsl.lk, copying dbsd@cbsl.lk\nas directed in the Table 01 hereto.\nTable 01: Reporting IT and Cybersecurity Incidents\nTemplate Type of the Report Timelines for Reporting\nRef.\nImmediate reporting Within 2 hours of detection of the incident\nDetailed reporting Within 14 days of detection of the incident\nQuarterly reporting Within 15 days following the end of each quarter\n5. Revocation: Circular dated 25.01.2016 on “Reporting on Cybersecurity Events” is hereby\nrevoked with immediate effect.\nGe\nMrs. RRS De Silva Jayatillake\nDirector of Bank Supervision\nAnnex 01\nREPORTING INFORMATION TECHNOLOGY AND CYBER SECURITY INCIDENTS\n(Template for Immediate Reporting)\n2.4 Brief summary of the incident\n2.6 Immediate actions taken by the bank (if any) nnn\n2.7 Internal reporting authority ©! (including\ninitial the date of notification)\n2.8 Whether the incident has been reported to\nany other authority? ! If yes,\nName of the authority:\nDate and time of reporting:\n3. Date and time of reporting to BSD\n4. Key contact person of the bank\n42 Designation ———SS—C—~—SCSSSSCSCSCSCSCSCSCS\n[43 Contact number &emailaddress SSCSC~S~SCS\nLT al al\n(6, Data and information securityimpact [\n7. Impact on stakeholders and customers SSS\n8. Reputationalimpact SiS\ned\neS\n9. Regulatory or legal impact\n10. Financial impact\nGuidelines for reporting:\nLicensed Banks are required to submit the details as per the attached format within 2 hours of\ndetection to the Director of Bank Supervision via techrisk.bsd@cbsl.lk, copying dbsd@cbsl.lk,\nbased on the availability of the information considering the timeline for reporting.\n[a] Categories of Incidents:\n(i) Intrusion/ Hacking, Malware, Ransomware, Malicious code, Virus, Phishing, Distribute\nDenial of Service (DDoS) Attacks, Social Engineering, Unauthorized System Usage,\nInsider Threats, Advanced Persistent Threats (APTs) and Supply Chain Attacks\n(ii) Unplanned critical system outages/ interruptions/ failures/ slowness/ unresponsiveness\n(111) Online or digital scams affecting the customers\n(iv) Regulatory compliance failures\n(v) Any other technology or cyber related event\n[b] To whom the event has been internally escalated:\n(i) Chief Information Security Officer\n(ii) Chief Information Officer\n(iii) Chief Executive Officer\n(iv) Information Security Committee\n(v) Board Integrated Risk Management Committee\n(vi) Board of Directors\n[c] Whether this incident was reported to:\n(i) Sri Lanka Computer Emergency Readiness Team (SLCERT)\n(ii) Financial Sector Computer Security Incident Response Team (FinCSIRT)\n(111) Payment and Settlement Department of Central Bank of Sri Lanka\n(iv) Computer Crime Investigation Division (CCID)\n(v) Any other relevant legal authorities\n[d] Impact Assessment may include the following:\nBusiness Impact e Disruption to banking services\ne System downtimes\ne Operational delays\nData and Information Security e Compromise of customer data\nImpact e Unauthorized access to sensitive information\ne Breach of confidentiality, integrity, or availabilit\nStakeholders’ and Customer e Number of affected customers and accounts\nImpact e Disruptions in communication and service delivery\ne Customer complaints and potential compensations\nReputational Impact e Is this incident likely to attract media attention?\ne Loss of customer trust and confidence\ne Impact on investor and stakeholder relations\nRegulatory or Legal Impact e Potential legal liabilities and penalties\nFinancial Impact e Include the estimated/ actual loss to the bank/ customers/\nstakeholders, separatel\nAnnex 02\nREPORTING INFORMATION TECHNOLOGY AND CYBER SECURITY INCIDENTS\n(Template for Detailed Reporting)\nInformation on the Incident\n1. Name of the bank\n2. Initial date and time of reporting of the incident to\nBSD\n3.4 Internal reporting authority \"! (including initial date\nof notification\n3.5 Whether the incident has been reported to any other\nauthority? \"I If yes,\nName of the authority:\nDate and time of reporting:\n3.6 Whether this incident has been informed to the\nstakeholders/ customers of the bank. (if yes date and\ntime of reporting)\n4.1 Name\n4.3 Contact number & email address\nDetailed Root Cause Analysis\n5. Factors that caused the problem/ reasons for\noccurring\n6. Immediate actions taken by the bank to address the\nroot cause\n7. Interim actions taken by the bank to address the root\ncause\nImpact Assessment !4\n10. The impact on stakeholders and customers\n11. Reputational impact\n12. Regulatory or legal impact\n13. Financial impact\nFinal Assessment\n14. List the corrective actions taken to prevent future\noccurrences of similar types of incidents\n15. Target dates for the corrective actions (if any\nGuidelines for reporting:\nLicensed Banks are required to submit the full details as per the attached format with any\nsupporting documents within 14 working days of detection to the Director of Bank Supervision\nvia techrisk.bsd@cbsl.lk, copying dbsd@cbsl. k.\n[a] Categories of Incidents:\n(i) Intrusion/ Hacking, Malware, Ransomware, Malicious code, Virus, Phishing, Distribute\nDenial of Service (DDoS) Attacks, Social Engineering, Unauthorized System Usage,\nInsider Threats, Advanced Persistent Threats (APTs) and Supply Chain Attacks\n(ii) Unplanned critical system outages/ interruptions/ failures/ slowness/ unresponsiveness\n(ii1) Online or digital scams affecting the customers\n(iv) Regulatory compliance failures\n(v) Any other technology or cyber related event\n[b] To whom the event has been internally escalated:\n(i) Chief Information Security Officer\n(11) Chief Information Officer\n(111) Chief Executive Officer\n(iv) Information Security Committee\n(v) Board Integrated Risk Management Committee\n(vi) Board of Directors\n[c] Whether this incident was reported to:\n(1) Sri Lanka Computer Emergency Readiness Team (SLCERT)\n(ii) Financial Sector Computer Security Incident Response Team (FinCSIRT)\n(iii) Payment and Settlement Department of Central Bank of Sri Lanka\n(iv) Computer Crime Investigation Division (CCID)\n(v) Any other relevant legal authorities\n[d] Impact Assessment shall inter alia include the following:\nBusiness Impact\ne Disruption to banking services\ne System downtimes\ne Operational delays\n¢ Compromise of customer data\ne Unauthorized access to sensitive information\nBreach of confidentiality, integrity, or availabilit\nNumber of affected customers and accounts\nDisruptions in communication and service delivery\nCustomer complaints and potential compensations\nIs this incident likely to attract media attention?\nLoss of customer trust and confidence\nImpact on investor and stakeholder relations\nRegulatory or Legal Impact e Potential legal liabilities and penalties\nFinancial Impact e Include the estimated/ actual loss to the bank/ customers/ other\nstakeholders, separatel\nData and _ Information\nSecurity Impact\nStakeholders’\nCustomer Impact\nReputational Impact\nAnnex 03\nREPORTING INFORMATION TECHNOLOGY AND CYBER SECURITY INCIDENTS\n(Template For Quarterly Reporting)\nName of the Bank :\nReportasatQ 20. _\n————————\n7. Corrective actions taken by the bank\nImpacted party (bank, customer, any other\nstakeholder)\n9. Estimated/ actual impact of the incident\n\"oom\nAmount rcorediyebank[\nTema eporngantioniy®\n12. Has the incident been reported to any other\nauthority, if so name\n13. Law enforcement authorities involved (if\napplicable)\nReported by:\nName:\nDesignation:\nDate:\nGuidelines:\n[a]\n[b]\nCategories of Incidents:\n(i) Intrusion/ Hacking, Malware, Ransomware, Malicious code, Virus, Phishing, Distribute\nDenial of Service (DDoS) Attacks, Social Engineering, Unauthorized System Usage,\nInsider Threats, Advanced Persistent Threats (APTs) and Supply Chain Attacks\n(ii) Unplanned critical system outages/ interruptions/ failures/ slowness/ unresponsiveness\n(iii) Online or digital scams affecting the customers\n(iv) Regulatory compliance failures\n(v) Any other technology or cyber related event\nPlease provide the amount of loss to the bank/ customers or any other stakeholder in case of\nfinancial impact and description in case of operational impact.\n[c] To whom the event has been internally escalated:\n[c]\n(1) Chief Information Security Officer\n(ii) Chief Information Officer\n(111) Chief Executive Officer\n(iv) Information Security Committee\n(v) Board Integrated Risk Management Committee\n(vi) Board of Directors\nWhether this incident was reported to:\n(i) Sri Lanka Computer Emergency Readiness Team (SLCERT)\n(ii) Financial Sector Computer Security Incident Response Team (FinCSIRT)\n(111) Payment and Settlement Department of Central Bank of Sri Lanka\n(iv) Computer Crime Investigation Division (CCID)\n(v) Any other relevant legal authorities', 'High', 'review', NULL, 1, NULL, NULL, NULL, NULL, '2026-09-28 10:21:29', NULL),
(50, '03/2024', 'GUIDELINES FOR THE ESTABLISHMENT OF MOBILE BANKING UNITS OF LICENSED COMMERCIAL BAI\\KS', '2024-12-03', '/www/wwwroot/circular/backend/uploads/df2ed6efe11146c794f68c187f93b241_bsd_circular_no_3_of_2024_GUIDELINES_FOR_THE_ESTABLISHMENT_OF_MOBILE_BAIKING_UNITS_OF.pdf', 2169, 'CENTRAL BANK OF SRI LANKA\nO3 December 2024\nCIRCULAR No. 03 of 2024\nGUIDELINES FOR THE ESTABLISHMENT OF MOBILE BANKING UNITS OF\nLICENSED COMMERCIAL BANKS\nThe Central Bank of Sri Lanka, with a view to strengthening the process and adopting a\nuniform practice among licensed commercial banks (LCBs) in establishing Mobile Banking\nUnits (MBUs), hereby issues this Circular on Guidelines for the establishment of MBUs of\nLCBs.\n1. Empowerment In terms of Section 13A(1) of the Banking Act, No.30 of 1988,\nas amended, the Deputy Governor may on guidelines issued\nby the Central Bank of Sri Lanka for such purpose, grant\napproval for the establishment of MBUs, subject to such terms\nand conditions as he may determine, from time to time.\n2. Mobile Banking An MBU includes the following:\nUnits a) Banking services carried out in vehicles in different\nlocations;\nb) Barefoot banking, i.e., bank officers visiting customers\noutside the bank premises and transacting business with\n\' them;\nc) Banking services carried out by a unit of LCBs ona few\ndays of the week (not on all working days) in a\npermanent place with staff attached to a branch of LCB,\nwho visit the unit to transact business; and\nd) Banking services carried out on an ad-hoc basis at\ntemporary outlets operated at public places such as\ntemples, schools, carnivals, exhibitions, conferences,\netc.\n3%\n4,\nGovernance and\nRisk Management\nFramework\nPermissible Activities\nThe operations of MBUs are required to be governed by\nthe Board approved framework/operating guidelines.\nSuch framework/operating guidelines, at a minimum,\nshall cover the following aspects:\n(i) Scope of activities;\n(ii) Limits structure for deposits and withdrawals\nthrough MBUs;\n(iii) Procedures for mnoniing, reporting and\naccounting of MBU operations;\n(iv) Necessary internal controls when accessing the\nsystems, books and records to facilitate MBU\noperations;\n(v) Applicable physical and functional segregation of\nfunctions at MBU;\n(vi) Assigning the branch responsible for MBU\noperations;\n(vii) Compliance with the Customer Charter of\nlicensed banks;\n(viii) Procedure for logistic arrangements and prior\napproval from the relevant authorities, if\nnecessary;\n(ix) Security arrangements/insurance requirements;\nand\n(x) Reporting to the management (frequency,\nactivities, progress, concerns, etc.).\nAccepting deposits from existing customers and\neffecting withdrawals from accounts, including\ntransactions made through Self Service Machines;\nAccount opening subject to compliance with applicable\nlegal and regulatory requirements (Rules and\nregulations relating to Know Your Customer and\nCustomer Due Diligence, etc.);\nAccepting loan/credit card applications and receiving\nloan repayment instalments/credit card payments;\nPrior Approval to\nConduct MBU\nActivities\nGeneral\nRequirements\nd)\ne)\ng)\nh)\nConducting promotions/canvassing of banking\nproducts;\nOnboarding of existing customers to digital channels;\nFacilitating utility payments;\nOffering services of an advisory nature; and\nProviding any other services that are incidental or\nconsequential to the above that the Deputy Governor\nmay authorize an MBU to engage in.\nLCBs that intend to carry out mobile banking activities\nduring the upcoming quarter are required to submit the\nduly completed application (BSD-MBU-01) to the\nDirector of Bank Supervision (DBS) on a quarterly\nbasis, 15 working days prior to the commencement of\nsuch quarter.\nThe application should be submitted with a cover letter\nsigned by the Chief Executive Officer/Chief Operating\nOfficer/Deputy Chief Executive Officer/relevant\nDeputy General Manager.\nAn MBU is required to incorporate the accounts of the\nUnit in the general ledger of the branch to which it is\naffiliated on a real time basis except MBUs established\nat schools for students; and\nAn MBU is required to clearly display the name of the\nbank and the branch to which it is affiliated at the\nlocation where it conducts the mobile banking\nactivities, including on the vehicle, as the case may be,\nin all three languages.\nTa Wer\nDr. P Nandalal Weerasinghe\nChairman of the Governing Board and\nGovernor of the Central Bank of Sri Lanka\nBSD-MBU-01\nApplication Form for Operating a Mobile Banking Unit\nof a Licensed Commercial Bank\n1. Name of the licensed commercial bank\n2. Place of operating the MBU/Name of the Event\n. Reasons for establishing/operating the MBU\n4. Type of MBU [e.g., mobile banking vehicle (specify\nthe details of the vehicle)/visiting customer outside\nthe bank premises/a unit which is operated in a\npermanent place on a few days of the week/banking\nservices carried out on an ad hoc basis at temporary\noutlets operated at public places such as carnivals,\nexhibitions, conferences/other (please specify)]\n5. Dates/period/business hours of the proposed MBU\n6. The branch to which the MBU is affiliated\n7. Approval obtained (Board/Chief Executive Officer)\nDetails of staff assigned to the MBU (number and\ndesignations)\n9. Services offered by the MBU\n10. Whether the following self-service machines will be\nused by the MBU\n(a) Automated Teller (Yes/No)\nMachine\n(b) Cash Deposit Machine (Yes\n(c) Cash Recycler Machine (Yes/No\n(d) KIOSK\n(e) Others (specify)\ni\n~—\n2\\Z\n© ©.\n11. Security arrangements (for on-site and cash in\ntransit)\naS\n13. The communication system between the MBU and\n14. Whether the customer accounts are updated on real\n15. Availability of approved internal framework/\nguidelines\n16. Additional comments/justifications, if any', 'Medium', 'review', NULL, 1, NULL, NULL, NULL, NULL, '2026-09-28 10:54:20', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `circular_departments`
--

CREATE TABLE `circular_departments` (
  `circular_id` int(11) NOT NULL,
  `department_id` int(11) NOT NULL,
  `routed_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `circular_departments`
--

INSERT INTO `circular_departments` (`circular_id`, `department_id`, `routed_at`) VALUES
(48, 5, '2026-09-28 12:38:12'),
(48, 10, '2026-09-28 12:38:12'),
(48, 11, '2026-09-28 12:38:12'),
(48, 14, '2026-09-28 12:38:12'),
(48, 15, '2026-09-28 12:38:12'),
(48, 16, '2026-09-28 12:38:12');

-- --------------------------------------------------------

--
-- Table structure for table `classifications`
--

CREATE TABLE `classifications` (
  `id` int(11) NOT NULL,
  `circular_id` int(11) NOT NULL,
  `category` varchar(80) NOT NULL,
  `confidence` float DEFAULT NULL,
  `is_manual` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `classifications`
--

INSERT INTO `classifications` (`id`, `circular_id`, `category`, `confidence`, `is_manual`, `created_at`) VALUES
(101, 42, 'SME Relief Measures', NULL, 1, '2026-07-17 06:10:14'),
(102, 42, 'Credit', NULL, 1, '2026-07-17 06:10:14'),
(103, 42, 'Regulatory Compliance', NULL, 1, '2026-07-17 06:10:14'),
(104, 43, 'Credit', NULL, 1, '2026-07-17 06:13:34'),
(105, 43, 'SME Relief Measures', NULL, 1, '2026-07-17 06:13:34'),
(106, 43, 'Regulatory Compliance', NULL, 1, '2026-07-17 06:13:34'),
(107, 44, 'SME Relief Measures', NULL, 1, '2026-07-17 06:20:08'),
(108, 44, 'Loan Recovery', NULL, 1, '2026-07-17 06:20:08'),
(109, 44, 'Regulatory Compliance', NULL, 1, '2026-07-17 06:20:08'),
(110, 45, 'Banking Operations', NULL, 1, '2026-07-17 07:03:46'),
(111, 45, 'COVID-19 Recovery', NULL, 1, '2026-07-17 07:03:46'),
(112, 45, 'Credit', NULL, 1, '2026-07-17 07:03:46'),
(113, 45, 'Regulatory Compliance', NULL, 1, '2026-07-17 07:03:46'),
(114, 46, 'Credit', NULL, 1, '2026-07-17 07:42:23'),
(115, 46, 'Regulatory Compliance', NULL, 1, '2026-07-17 07:42:23'),
(116, 46, 'Loan Recovery', NULL, 1, '2026-07-17 07:42:23'),
(117, 47, 'SLFRS9', NULL, 1, '2026-07-17 08:05:53'),
(118, 47, 'Regulatory Compliance', NULL, 1, '2026-07-17 08:05:53'),
(119, 47, 'Financial Reporting', NULL, 1, '2026-07-17 08:05:53'),
(120, 48, 'Financial Reporting', NULL, 1, '2026-07-17 08:26:55'),
(121, 48, 'Regulatory Compliance', NULL, 1, '2026-07-17 08:26:55'),
(122, 48, 'SLFRS9', NULL, 1, '2026-07-17 08:26:55'),
(123, 48, 'Credit', NULL, 1, '2026-07-17 08:26:55');

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `id` int(11) NOT NULL,
  `name` varchar(120) NOT NULL,
  `code` varchar(20) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `departments`
--

INSERT INTO `departments` (`id`, `name`, `code`, `description`, `created_at`) VALUES
(2, 'Information Technology', 'IT', 'IT and systems', '2026-06-11 08:18:59'),
(4, 'Executive & Corporate Management', 'CM', NULL, '2026-07-12 05:10:23'),
(5, 'Credit Department', 'CD', NULL, '2026-07-12 08:55:01'),
(6, 'SME Banking Department', 'SME', NULL, '2026-07-12 08:55:32'),
(7, 'Business Banking', 'BB', NULL, '2026-07-12 08:55:52'),
(8, 'Loan Recovery Department', 'LRD', NULL, '2026-07-12 08:56:11'),
(9, 'Branch Operation', 'BO', NULL, '2026-07-12 08:56:32'),
(10, 'Legal & Compliance', 'COMP', NULL, '2026-07-12 08:57:16'),
(11, 'Risk Management', 'RM', NULL, '2026-07-12 08:58:14'),
(13, 'Treasury Department', 'TR', NULL, '2026-07-12 15:50:41'),
(14, 'Finance Department', 'FIN', NULL, '2026-07-12 15:51:11'),
(15, 'Accounting Department', 'ACC', NULL, '2026-07-12 15:51:51'),
(16, 'Audit Department', 'AUD', NULL, '2026-07-12 16:21:05');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `circular_id` int(11) DEFAULT NULL,
  `message` varchar(512) NOT NULL,
  `link` varchar(255) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `circular_id`, `message`, `link`, `is_read`, `created_at`) VALUES
(416, 5, 42, 'Circular 04/2024 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 06:10:14'),
(417, 6, 42, 'Circular 04/2024 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 06:10:14'),
(418, 5, 43, 'Circular 01/2025 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 06:13:34'),
(419, 6, 43, 'Circular 01/2025 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 06:13:34'),
(420, 5, 44, 'Circular 01/2021 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 06:20:08'),
(421, 6, 44, 'Circular 01/2021 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 06:20:08'),
(422, 5, 45, 'Circular 01/22 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 07:03:46'),
(423, 6, 45, 'Circular 01/22 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 07:03:46'),
(424, 5, 46, 'Circular 02/2022 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 07:42:23'),
(425, 6, 46, 'Circular 02/2022 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 07:42:23'),
(426, 5, 47, 'Circular 04/2018 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 08:05:53'),
(427, 6, 47, 'Circular 04/2018 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 08:05:53'),
(428, 5, 48, 'Circular 02/2021 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 08:26:55'),
(429, 6, 48, 'Circular 02/2021 submitted for approval by System Admin.', '/approvals', 0, '2026-07-17 08:26:55'),
(430, 2, 48, '[Medium] New circular 02/2021: Amendments to Circular No. 04 of 2018 on Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments — acknowledge by 05 Oct 2026.', '/circulars/48', 0, '2026-09-28 12:38:12'),
(431, 11, 48, '[Medium] New circular 02/2021: Amendments to Circular No. 04 of 2018 on Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments — acknowledge by 05 Oct 2026.', '/circulars/48', 0, '2026-09-28 12:38:12'),
(432, 12, 48, '[Medium] New circular 02/2021: Amendments to Circular No. 04 of 2018 on Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments — acknowledge by 05 Oct 2026.', '/circulars/48', 0, '2026-09-28 12:38:12'),
(433, 17, 48, '[Medium] New circular 02/2021: Amendments to Circular No. 04 of 2018 on Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments — acknowledge by 05 Oct 2026.', '/circulars/48', 0, '2026-09-28 12:38:12'),
(434, 18, 48, '[Medium] New circular 02/2021: Amendments to Circular No. 04 of 2018 on Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments — acknowledge by 05 Oct 2026.', '/circulars/48', 0, '2026-09-28 12:38:12'),
(435, 21, 48, '[Medium] New circular 02/2021: Amendments to Circular No. 04 of 2018 on Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments — acknowledge by 05 Oct 2026.', '/circulars/48', 0, '2026-09-28 12:38:12'),
(436, 22, 48, '[Medium] New circular 02/2021: Amendments to Circular No. 04 of 2018 on Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments — acknowledge by 05 Oct 2026.', '/circulars/48', 0, '2026-09-28 12:38:12'),
(437, 23, 48, '[Medium] New circular 02/2021: Amendments to Circular No. 04 of 2018 on Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments — acknowledge by 05 Oct 2026.', '/circulars/48', 0, '2026-09-28 12:38:12'),
(438, 24, 48, '[Medium] New circular 02/2021: Amendments to Circular No. 04 of 2018 on Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments — acknowledge by 05 Oct 2026.', '/circulars/48', 0, '2026-09-28 12:38:12'),
(439, 27, 48, '[Medium] New circular 02/2021: Amendments to Circular No. 04 of 2018 on Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments — acknowledge by 05 Oct 2026.', '/circulars/48', 0, '2026-09-28 12:38:12'),
(440, 28, 48, '[Medium] New circular 02/2021: Amendments to Circular No. 04 of 2018 on Guidelines to Licensed Banks on the Adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments — acknowledge by 05 Oct 2026.', '/circulars/48', 0, '2026-09-28 12:38:12'),
(441, 1, 48, 'Your circular 02/2021 was approved and published by Senidu Kalhara.', '/circulars/48', 1, '2026-09-28 12:38:31'),
(442, 1, 42, 'Your circular 04/2024 was rejected by Senidu Kalhara: Duplicate informations', '/circulars/42', 1, '2026-09-28 12:40:40');

-- --------------------------------------------------------

--
-- Table structure for table `summaries`
--

CREATE TABLE `summaries` (
  `id` int(11) NOT NULL,
  `circular_id` int(11) NOT NULL,
  `summary_text` text NOT NULL,
  `entities` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`entities`)),
  `word_count` int(11) DEFAULT NULL,
  `bert_model` varchar(120) DEFAULT NULL,
  `bart_model` varchar(120) DEFAULT NULL,
  `processing_seconds` float DEFAULT NULL,
  `rouge_score` float DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `summaries`
--

INSERT INTO `summaries` (`id`, `circular_id`, `summary_text`, `entities`, `word_count`, `bert_model`, `bart_model`, `processing_seconds`, `rouge_score`, `created_at`) VALUES
(64, 42, 'Overview:\nThis circular provides relief measures to Small and Medium Enterprises (SMEs) affected by the Easter Sunday attack, Covid-19 pandemic, and macroeconomic conditions. Licensed commercial banks and specialized banks will provide these measures to eligible SME borrowers.\n\nKey Points:\n- Licensed banks must engage with SME borrowers who have been classified as Stage 3 on or after April 1, 2019, and have commenced discussions on business revival by March 31, 2025.\n- Rescheduling of impaired loans with eligible SME borrowers will be considered based on repayment capacity and submission of an acceptable business revival plan.\n- Repayment of rescheduled loans must commence within the following deadlines:\n	+ For aggregate capital outstanding below Rs. 25 Mn: not later than December 31, 2025\n	+ For aggregate capital outstanding between Rs. 25 Mn - Rs. 50 Mn: not later than September 30, 2025\n	+ For aggregate capital outstanding above Rs. 50 Mn: not later than June 30, 2025\n- Licensed banks may waive off unpaid interest (excluding capitalized interest) applicable to the period between April 1, 2019, and December 15, 2024.\n- Licensed banks must report credit facilities restructured under this circular to the Credit Information Bureau of Sri Lanka.', '[{\"text\": \"SMEs\", \"label\": \"TOPIC\"}, {\"text\": \"Relief Measures\", \"label\": \"TOPIC\"}, {\"text\": \"Macro Economic Conditions\", \"label\": \"TOPIC\"}, {\"text\": \"Loan Rescheduling\", \"label\": \"TOPIC\"}, {\"text\": \"Interest Waiver\", \"label\": \"TOPIC\"}]', 197, 'bert-base-uncased', 'llama3.2:3b', 188.8, NULL, '2026-07-17 05:58:21'),
(65, 43, 'Overview:\nThe Central Bank of Sri Lanka has issued a new circular to provide relief measures to affected Small and Medium Enterprises (SMEs). Licensed banks are required to establish a Relief Banking Unit to implement these measures. The circular aims to ensure effective implementation of the relief measures in a consistent manner across all licensed banks.\n\nKey Points:\n- Licensed banks must reschedule credit facilities for eligible borrowers up to 10 years, considering repayment capacity and an acceptable revival plan.\n- Banks must establish a transparent grievance-handling mechanism for disputes related to auctioned properties.\n- Licensed banks must report details of borrowers who approached them to avail relief measures, including facility number, borrower name, amount outstanding, and status of discussion.\n- Banks must reschedule loans with interest waived off by the bank on rescheduling.\n- The reporting period for monthly details of borrowers is from 15.12.2024 to the reporting date.', '[{\"text\": \"Relief Banking Unit\", \"label\": \"TOPIC\"}, {\"text\": \"SMEs\", \"label\": \"TOPIC\"}, {\"text\": \"Credit Rescheduling\", \"label\": \"TOPIC\"}, {\"text\": \"Grievance Handling\", \"label\": \"TOPIC\"}, {\"text\": \"Loan Reporting\", \"label\": \"TOPIC\"}]', 150, 'bert-base-uncased', 'llama3.2:3b', 90.4, NULL, '2026-07-17 06:12:40'),
(66, 44, 'Overview:\nLicensed commercial banks and licensed specialised banks are required to suspend recovery actions against Small and Medium Enterprise (SME) Paddy Millers for a period of six months due to the COVID-19 pandemic. This suspension is to support government initiatives aimed at supporting SME Paddy Millers during the upcoming harvesting seasons.\nKey Points:\n- Licensed banks must suspend recovery actions against SME Paddy Millers from 1 January 2021, with some exceptions.\n- Recovery actions can be suspended on condition that a debt re-payment agreement is reached between the bank and the borrower.\n- Licensed banks must defer passing new resolutions under relevant Acts until 30 June 2021.\n- Auctioning of assets will be suspended until 30 June 2021 in cases where resolutions for recovery have already been passed.\n- Borrowers with on-going litigations in courts relating to recovery can enter into an agreement by submitting an affidavit to Courts agreeing to comply with debt re-payment requirements.', '[{\"text\": \"SME Paddy Millers\", \"label\": \"TOPIC\"}, {\"text\": \"COVID-19 pandemic\", \"label\": \"TOPIC\"}, {\"text\": \"Bank Recovery\", \"label\": \"TOPIC\"}, {\"text\": \"Debt Repayment\", \"label\": \"TOPIC\"}, {\"text\": \"Auction Suspension\", \"label\": \"TOPIC\"}]', 156, 'bert-base-uncased', 'llama3.2:3b', 101.02, NULL, '2026-07-17 06:18:08'),
(67, 45, 'Overview:\nThe Central Bank of Sri Lanka has issued guidelines for licensed banks to establish Post COVID-19 Revival Units to assist underperforming and non-performing borrowers affected by the pandemic. The purpose is to revive viable businesses and contribute to economic development.\n\nKey Points:\n- Licensed banks must formulate a revival and rehabilitation policy approved by the Board of Directors, including the mandate for establishment of the Unit, its scope of activities, and financial strategies for borrowers.\n- The Revival Unit shall be headed by a Key Management Personnel with sufficient authority and seniority, and licensed banks must ensure adequate staffing and expertise for credit appraisal and monitoring.\n- Licensed banks are required to report progress of rehabilitation proposals availed to borrowers as at the end of each quarter, within 15 working days, commencing June 30, 2022.\n- The Unit shall conduct awareness programs on rehabilitation initiatives, procedures, and methodologies, and provide credit counselling and business advisory services.\n- Licensed banks must adopt accounting treatment for facilities considered under the Unit as per Sri Lanka Accounting Standards and related Circulars/guidelines issued by CBSL.\n- Licensed banks may seek advice from the Institute of Chartered Accountants of Sri Lanka and Auditors for additional guidance on accounting considerations.\n- The restructuring of facilities granted under refinance or interest subsidy schemes shall be considered in accordance with related guidelines issued by the Regional Development Department of CBSL or the Ministry of Finance.', '[{\"text\": \"Post COVID Revival Units\", \"label\": \"TOPIC\"}, {\"text\": \"Licensed Banks\", \"label\": \"TOPIC\"}, {\"text\": \"Rehabilitation Policies\", \"label\": \"TOPIC\"}, {\"text\": \"Credit Appraisal\", \"label\": \"TOPIC\"}, {\"text\": \"Economic Development\", \"label\": \"TOPIC\"}]', 238, 'bert-base-uncased', 'llama3.2:3b', 124.08, NULL, '2026-07-17 07:00:22'),
(68, 46, 'Overview:\nThe Central Bank of Sri Lanka (CBSL) has issued a circular to provide concessions to affected borrowers due to extraordinary macroeconomic circumstances. Licensed commercial banks and specialized banks are required to implement these concessions to devise suitable repayment arrangements for borrowers.\nKey Points:\n- Licensed banks must provide appropriate concessions, including grace period for capital or interest, restructuring of credit facilities, or any other concession, for performing credit facilities of individuals or businesses whose income or business has been adversely affected by the current macroeconomic conditions.\n- Concessions are expected to be provided to affected borrowers in all economic sectors on a case-by-case basis for a period of six months from the date of this Circular, based on the new repayment capacity/viability of the borrower.\n- Licensed banks shall devise a mechanism to structure the repayment plan not exceeding the contracted instalment value of the existing credit facility or facilities, with an extended tenure, to match with the repayment capabilities of the borrowers.\n- In the case of Rupee facilities considered for concessions, the interest rate applicable for the concessionary period (including the recovery period) shall not exceed the latest contracted rate of interest or the Standard Lending Facility Rate applicable on the date of this Circular (15.5%), whichever is higher.\n- Licensed banks shall suspend recovery actions including parate execution and forced repossession of leased assets against all credit facilities that have been classified as non-performing on or after 01.01.2020, until 31.12.2022 in order to enable the borrowers to arrange timely repayments.\n- Licensed banks shall report the details of concessions availed by their borrowers to the Bank Supervision Department, as at each month end, within 15 working days, commencing from 31 July 2022.\n- Any borrower who is willing for an early settlement of credit facilities shall make a request to the respective licensed bank on or before 30.09.2022.\n- Licensed banks may also consider providing rebates for such early settlements, on a case-by-case basis.', '[{\"text\": \"Concessions\", \"label\": \"TOPIC\"}, {\"text\": \"Macro Economic\", \"label\": \"TOPIC\"}, {\"text\": \"Repayment Arrangements\", \"label\": \"TOPIC\"}, {\"text\": \"Interest Rates\", \"label\": \"TOPIC\"}, {\"text\": \"Borrowers\", \"label\": \"TOPIC\"}]', 328, 'bert-base-uncased', 'llama3.2:3b', 119.05, NULL, '2026-07-17 07:37:10'),
(72, 47, 'Overview:\nThis circular sets out guidelines for licensed banks in Sri Lanka to adopt the Sri Lanka Accounting Standard - SLFRS 9: Financial Instruments. The Central Bank of Sri Lanka aims to establish consistent and prudent practices on the adoption of this standard, with a focus on sound credit risk management.\nKey Points:\n- Licensed banks must classify and measure financial assets and liabilities according to the guidelines in Table 1 and Table 2, respectively.\n- Banks must have policies and procedures in place for assessing and measuring credit risk, including the use of robust models and experienced credit judgment.\n- Expected Credit Losses (ECL) must be calculated for all financial instruments, with a focus on significant increases in credit risk, such as payment defaults or changes in economic conditions.\n- Licensed banks must disclose the total amount of first-day impact arising from the adoption of SLFRS 9 and its impact to Capital Adequacy Ratio (CAR) throughout the transitional period, starting from January 1, 2018.\n- The Probability of Default (PD) and Loss Given Default (LGD) used for expected credit loss calculations must be based on at least five-year data, with a minimum LGD of 45% for exposures denominated in foreign currencies issued by sovereigns.\n- Licensed banks must have adequate systems, tools, and data to assess credit risk and account for ECL, including the use of valuation techniques that maximize the use of relevant observable inputs.', '[{\"text\": \"Licensed Banks\", \"label\": \"TOPIC\"}, {\"text\": \"Sri Lanka Accounting Standard\", \"label\": \"TOPIC\"}, {\"text\": \"Credit Risk Management\", \"label\": \"TOPIC\"}]', 237, 'bert-base-uncased', 'llama3.2:3b', 341.43, NULL, '2026-07-17 07:58:47'),
(77, 49, 'Overview:\nLicensed banks in Sri Lanka are required to report IT and cybersecurity incidents to the Central Bank of Sri Lanka (CBSL) to ensure operational resilience and safeguard customer information and assets.\n\nKey Points:\n- Licensed banks must report IT and cybersecurity incidents, including intrusions, hacking, malware, ransomware, and online scams, within 2 hours of detection using the attached reporting templates.\n- Quarterly reports on IT and cybersecurity incidents must be submitted by licensed banks to CBSL within 15 days following the end of each quarter.\n- Detailed reports on IT and cybersecurity incidents must be submitted to CBSL within 14 working days of detection, including information on the incident, root cause analysis, impact assessment, and corrective actions taken.\n- Licensed banks are required to report any other technology or cyber-related events that may affect their customers or stakeholders.\n- The reporting templates for immediate, detailed, and quarterly reports must be submitted via techrisk.bsd@cbsl.lk, copying dbsd@cbsl.lk as directed in the attached Table 01.', '[{\"text\": \"IT incident reporting\", \"label\": \"TOPIC\"}, {\"text\": \"cybersecurity regulations\", \"label\": \"TOPIC\"}, {\"text\": \"bank operational resilience\", \"label\": \"TOPIC\"}, {\"text\": \"customer data protection\", \"label\": \"TOPIC\"}, {\"text\": \"technology risk management\", \"label\": \"TOPIC\"}]', 163, 'bert-base-uncased', 'llama3.2:3b', 186.55, NULL, '2026-09-28 10:45:38'),
(78, 50, 'Overview:\nThe Central Bank of Sri Lanka has issued a new circular to guide licensed commercial banks (LCBs) in establishing Mobile Banking Units (MBUs). The circular aims to strengthen the process and adopt a uniform practice among LCBs. It outlines guidelines for the establishment, operation, and governance of MBUs.\nKey Points:\n- Licensed commercial banks must submit a completed application (BSD-MBU-01) to the Director of Bank Supervision (DBS) on a quarterly basis, 15 working days prior to the commencement of such quarter.\n- The application should be signed by the Chief Executive Officer/Chief Operating Officer/Deputy Chief Executive Officer/relevant Deputy General Manager.\n- MBUs must incorporate the accounts of the unit in the general ledger of the branch to which it is affiliated on a real-time basis, except for those established at schools for students.\n- An MBU must clearly display the name of the bank and the branch to which it is affiliated at the location where it conducts mobile banking activities, including on the vehicle, as the case may be, in all three languages.', '[{\"text\": \"Licensed Commercial Banks\", \"label\": \"TOPIC\"}, {\"text\": \"Mobile Banking Units\", \"label\": \"TOPIC\"}, {\"text\": \"Quarterly Applications\", \"label\": \"TOPIC\"}, {\"text\": \"Bank Supervision\", \"label\": \"TOPIC\"}, {\"text\": \"Branch Governance\", \"label\": \"TOPIC\"}]', 175, 'bert-base-uncased', 'llama3.2:3b', 132.03, NULL, '2026-09-28 10:56:52'),
(79, 48, 'Overview:\nThe Central Bank of Sri Lanka has issued an amendment to Circular No. 04 of 2018 regarding the adoption of Sri Lanka Accounting Standard — SLFRS 9: Financial Instruments by licensed banks. This circular aims to establish consistent practices in the face of exceptional circumstances. The amendment applies to all licensed banks.\n\nKey Points:\n- Licensed banks are permitted to apply a minimum Loss Given Default (LGD) of 10 per cent when computing expected losses for the year 2021.\n- The amendment inserts a new guideline 2.5(c) into Circular No. 04 of 2018, allowing for this exception.\n- This change applies immediately and is effective from January 2, 2021.\n- Banks must ensure compliance with the amended guidelines to avoid any potential risks or penalties.\n- The Central Bank of Sri Lanka will monitor and enforce adherence to the revised guidelines.\n- No specific deadline for implementation is mentioned in the circular.', '[{\"text\": \"Licensed banks\", \"label\": \"TOPIC\"}, {\"text\": \"Loss Given Default\", \"label\": \"TOPIC\"}, {\"text\": \"SLFRS 9\", \"label\": \"TOPIC\"}, {\"text\": \"Exceptional circumstances\", \"label\": \"TOPIC\"}, {\"text\": \"Compliance requirements\", \"label\": \"TOPIC\"}]', 153, 'bert-base-uncased', 'llama3.2:3b', 147.11, NULL, '2026-09-28 13:01:15');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(80) NOT NULL,
  `email` varchar(120) NOT NULL,
  `full_name` varchar(120) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` varchar(20) NOT NULL DEFAULT 'Employee',
  `department_id` int(11) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime DEFAULT current_timestamp(),
  `last_login` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `email`, `full_name`, `password_hash`, `role`, `department_id`, `is_active`, `created_at`, `last_login`) VALUES
(1, 'admin', 'admin@bank.lk', 'System Admin', '$2b$12$MHa16S2NghXm0W.elovdy.XobVq.bUhs7ETdGdLMys8uMy9uQBaLu', 'Administrator', 2, 1, '2026-06-11 08:18:59', '2026-09-28 13:44:20'),
(2, 'manager', 'manager@bank.lk', 'Compliance Manager', '$2b$12$MHa16S2NghXm0W.elovdy.XobVq.bUhs7ETdGdLMys8uMy9uQBaLu', 'Manager', 10, 1, '2026-06-11 08:18:59', '2026-07-06 11:17:25'),
(3, 'employee', 'employee@bank.lk', 'Branch Employee', '$2b$12$MHa16S2NghXm0W.elovdy.XobVq.bUhs7ETdGdLMys8uMy9uQBaLu', 'Employee', 2, 1, '2026-06-11 08:18:59', '2026-07-12 09:39:40'),
(4, 'tharindu', 'tharindu@bank.lk', 'Tharindu Perera', '$2b$12$p6G9WRnASz9QuDGkSL68sei60EneJcbissfwRP60TqaugYB3D5c5S', 'Manager', 2, 1, '2026-06-11 10:59:26', '2026-06-11 10:59:49'),
(5, 'Rashmi', 'rashmi@bank.lk', 'Rashmi Dissanayaka', '$2b$12$zh0pJtCBG/gco653Xaf44.BI8rWD93GSv0Eu95Kz1JdBp8Lt7.aZ6', 'Compliance Officer', 10, 1, '2026-07-11 08:51:52', '2026-07-18 17:44:14'),
(6, 'Senidu', 'senidu@bank.lk', 'Senidu Kalhara', '$2b$12$tVHUkdWxcn0qLBNC9klyhumJBJdeED6pN6KJDWf2RlDfPvtl3kpGy', 'Compliance Officer', 10, 1, '2026-07-12 05:02:36', '2026-09-28 12:31:32'),
(7, 'Sehantha', 'sehantha@bank.lk', 'Sehantha Thathsiluni', '$2b$12$kwhtlhUrzcRCDkwtfN9P4u8Dl5ksmXKY7nC5ZwO4pH3dNn7cElcdK', 'Employee', 9, 1, '2026-07-12 09:05:38', '2026-09-29 06:01:40'),
(8, 'Thinula', 'thinula@bank.lk', 'Thinula Damsith', '$2b$12$o5bRbt4eiM/Qepc9/Ua2p.LZPlzjJ2ty6.gfzhNzV1gf8cK4tItIK', 'Manager', 9, 1, '2026-07-12 09:07:34', NULL),
(9, 'Thiran', 'thiran@bank.lk', 'Thiran Randika', '$2b$12$bNGIf3l.5X9RaOINlbnUI.P4DDYSOPhSyImo46OoaCW/glA.KsAMK', 'Employee', 7, 1, '2026-07-12 09:08:43', NULL),
(10, 'Charana', 'charana@bank.lk', 'Charana Munasighe', '$2b$12$CGcs7sTCMSkenqmPDbug3ec0SXpMmHxdnrixS9rMELArt36ziC.2u', 'Manager', 7, 1, '2026-07-12 09:09:49', NULL),
(11, 'Hiruni', 'hiruni@bank.lk', 'Hiruni Ramesha', '$2b$12$N/C/PEet0VFG7WeZGr0fmeoaFZ9mAnmHeiG7Rq3a0ke.RNi0gKAdW', 'Employee', 5, 1, '2026-07-12 09:11:00', NULL),
(12, 'Wageesha', 'wageesha@bank.lk', 'Wageesha Narandeniya', '$2b$12$xL9Uni35KTodwxeP7.kPOe7yku1DdQpdRPxPWQ3t3HFjF0tTsxZRu', 'Manager', 5, 1, '2026-07-12 09:11:58', NULL),
(13, 'Prabhath', 'prabhath@bank.lk', 'Prabhath Chathura', '$2b$12$seEPUPRTylRR/7Sl5iCutOUc7dgD0pRhZmB8szuHzVG0EbVAaUPMi', 'Employee', 4, 1, '2026-07-12 09:12:48', NULL),
(14, 'TharinduR', 'tharindu.r@bank.lk', 'Tharindu Ranasinghe', '$2b$12$fBpn0N09MxvidcpsKgGGLOBwKBWYh2HQ0T1ftTxGBA53ixU7mmtDO', 'Manager', 4, 1, '2026-07-12 09:17:21', NULL),
(15, 'Buwaneka', 'buwaneka@bank.lk', 'Buwaneka Deshan', '$2b$12$aWTqWKjbhTOqmPfqKvUQ.ur2HmOZyCYbjmNgFFj.5XrRJTll3yW02', 'Employee', 8, 1, '2026-07-12 09:18:34', NULL),
(16, 'Amanda', 'amanda@bank.lk', 'Amanda Dissanayaka', '$2b$12$RmMYOBV69s06HXGC9p5R7OB0Vjr1RJiClB99OoUFZrQx3hngdATq6', 'Manager', 8, 1, '2026-07-12 09:19:43', NULL),
(17, 'Ruvini', 'ruvini@bank.lk', 'Ruvini Maduthya', '$2b$12$nKMpB1N9CUe/t1yLRgoOnudWFS6U/kyK/dDcQImqqrT0LMA9YbR3G', 'Employee', 11, 1, '2026-07-12 09:24:09', NULL),
(18, 'Dananjani', 'dananjani@bank.lk', 'Dananjani Kulatunge', '$2b$12$w4mbUxxyleUaWn1Tgq8kyu5zBK.iVisAb3UnosMK6.HQ3AV4eS4n2', 'Manager', 11, 1, '2026-07-12 09:25:26', NULL),
(19, 'Haritha', 'harith@bank.lk', 'Haritha Layomin', '$2b$12$/o37bkGvnzcuw/oX7folxuEiM5.hUju291RE16kRSN7.s/RyUO6i6', 'Employee', 6, 1, '2026-07-12 09:27:06', NULL),
(20, 'Dilki', 'dilki@bank.lk', 'Dilki Ishara', '$2b$12$SM3m/WtLjuqqDciOjWeW0O8IFGxARW5g3QcsEMarxqKkU3XDjhfGK', 'Manager', 6, 1, '2026-07-12 09:28:00', NULL),
(21, 'Shehani', 'shehani@bank.lk', 'Shehani Ahinsa', '$2b$12$eGF1ab3STvtRbir3eUK5jeuTLKfJuob2QO476P.wwSsqzlMrLs1qq', 'Employee', 14, 1, '2026-07-12 15:54:33', NULL),
(22, 'Piyumi', 'piyumi@bank.lk', 'Piyumi Jagodage', '$2b$12$aHS6sMdxmyd4bxzrMeWSne/q5W1WrysmRDZ4W7QvakO9GQtsfEWpe', 'Manager', 15, 1, '2026-07-12 15:55:24', NULL),
(23, 'Ayodya', 'ayodya@bank.lk', 'Ayodya Indeewari', '$2b$12$2uZK1PoziFk2Tm/kyvWyn.d6rAuNM4lMwymtTSJ.3kEokR82rrKSC', 'Employee', 15, 1, '2026-07-12 15:56:50', NULL),
(24, 'Isuruni', 'isuruni@bank.lk', 'Isuruni Udyoga', '$2b$12$NDqrCjTDMCQDuTKd6hA1KOqp7E0GfWtLR7MBBIAZmvpCMljJtgBpC', 'Manager', 14, 1, '2026-07-12 15:57:52', NULL),
(25, 'Hasaranga', 'hasaranga@bank.lk', 'Hasaranga Ganesha', '$2b$12$WHH3kd3gN8PWh9TjjSzIwuYIfDY9OKqibXnZY8nMnX6gicwTqohRK', 'Employee', 13, 1, '2026-07-12 16:00:12', NULL),
(26, 'Harshani', 'harshani@bank.lk', 'Harshani Prasadika', '$2b$12$3gqefm1UVk3zKITpjQtYDOD0pU.P6r0.08YjB8yrTqToW.RW61xSC', 'Manager', 13, 1, '2026-07-12 16:01:01', NULL),
(27, 'Nisansala', 'nisansala@bank.lk', 'Nisansala Gamage', '$2b$12$FturOYnnXaNT/Eps4iFxIuoFHTnW7RVBSjsZojt6G0gbteOr4dpHK', 'Employee', 16, 1, '2026-07-12 16:22:04', NULL),
(28, 'Iresha', 'iresha@bank.lk', 'Iresha Sandamali', '$2b$12$wc2umyQVjxWKc6cC3tvxwupJXWvqF3txfq8Y0T86mwGwr13T1/882', 'Manager', 16, 1, '2026-07-12 16:22:42', '2026-09-29 05:49:04'),
(29, 'chamudika', 'chamuhasanthi1@gmail.com', 'Chamudika Hasanthi', '$2b$12$AuNxOKCzF3F91Dvu8EeJse7qi0WdRO8w0nCabYE6yHBkvomZOWxMe', 'Employee', 2, 1, '2026-09-28 13:39:54', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `vector_index_metadata`
--

CREATE TABLE `vector_index_metadata` (
  `id` int(11) NOT NULL,
  `total_vectors` int(11) DEFAULT 0,
  `total_circulars` int(11) DEFAULT 0,
  `embedding_model` varchar(120) DEFAULT NULL,
  `dimension` int(11) DEFAULT NULL,
  `index_path` varchar(512) DEFAULT NULL,
  `last_rebuilt_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `acknowledgements`
--
ALTER TABLE `acknowledgements`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_ack_user_circular` (`circular_id`,`user_id`),
  ADD KEY `fk_ack_user` (`user_id`);

--
-- Indexes for table `audit_log`
--
ALTER TABLE `audit_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_audit_user` (`user_id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Indexes for table `change_requests`
--
ALTER TABLE `change_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_req_circular` (`circular_id`),
  ADD KEY `fk_req_requester` (`requester_id`),
  ADD KEY `fk_req_resolver` (`resolved_by`);

--
-- Indexes for table `chat_conversations`
--
ALTER TABLE `chat_conversations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_conv_user` (`user_id`),
  ADD KEY `fk_conv_circular` (`circular_id`);

--
-- Indexes for table `chat_log`
--
ALTER TABLE `chat_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_chat_user` (`user_id`),
  ADD KEY `fk_chatlog_conversation` (`conversation_id`);

--
-- Indexes for table `circulars`
--
ALTER TABLE `circulars`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_circular_number` (`circular_number`),
  ADD KEY `fk_circulars_uploader` (`uploaded_by`),
  ADD KEY `fk_circular_amends` (`amends_circular_id`),
  ADD KEY `fk_circular_approver` (`approved_by`);

--
-- Indexes for table `circular_departments`
--
ALTER TABLE `circular_departments`
  ADD PRIMARY KEY (`circular_id`,`department_id`),
  ADD KEY `fk_cd_department` (`department_id`);

--
-- Indexes for table `classifications`
--
ALTER TABLE `classifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_class_circular` (`circular_id`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_notif_user` (`user_id`),
  ADD KEY `fk_notif_circular` (`circular_id`);

--
-- Indexes for table `summaries`
--
ALTER TABLE `summaries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_summary_circular` (`circular_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `fk_users_department` (`department_id`);

--
-- Indexes for table `vector_index_metadata`
--
ALTER TABLE `vector_index_metadata`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `acknowledgements`
--
ALTER TABLE `acknowledgements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=349;

--
-- AUTO_INCREMENT for table `audit_log`
--
ALTER TABLE `audit_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=570;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `change_requests`
--
ALTER TABLE `change_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `chat_conversations`
--
ALTER TABLE `chat_conversations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `chat_log`
--
ALTER TABLE `chat_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=53;

--
-- AUTO_INCREMENT for table `circulars`
--
ALTER TABLE `circulars`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT for table `classifications`
--
ALTER TABLE `classifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=124;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=443;

--
-- AUTO_INCREMENT for table `summaries`
--
ALTER TABLE `summaries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=80;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT for table `vector_index_metadata`
--
ALTER TABLE `vector_index_metadata`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `acknowledgements`
--
ALTER TABLE `acknowledgements`
  ADD CONSTRAINT `fk_ack_circular` FOREIGN KEY (`circular_id`) REFERENCES `circulars` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_ack_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `audit_log`
--
ALTER TABLE `audit_log`
  ADD CONSTRAINT `fk_audit_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `change_requests`
--
ALTER TABLE `change_requests`
  ADD CONSTRAINT `fk_req_circular` FOREIGN KEY (`circular_id`) REFERENCES `circulars` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_req_requester` FOREIGN KEY (`requester_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_req_resolver` FOREIGN KEY (`resolved_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `chat_conversations`
--
ALTER TABLE `chat_conversations`
  ADD CONSTRAINT `fk_conv_circular` FOREIGN KEY (`circular_id`) REFERENCES `circulars` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_conv_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `chat_log`
--
ALTER TABLE `chat_log`
  ADD CONSTRAINT `fk_chat_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_chatlog_conversation` FOREIGN KEY (`conversation_id`) REFERENCES `chat_conversations` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `circulars`
--
ALTER TABLE `circulars`
  ADD CONSTRAINT `fk_circular_amends` FOREIGN KEY (`amends_circular_id`) REFERENCES `circulars` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_circular_approver` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_circulars_uploader` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `circular_departments`
--
ALTER TABLE `circular_departments`
  ADD CONSTRAINT `fk_cd_circular` FOREIGN KEY (`circular_id`) REFERENCES `circulars` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_cd_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `classifications`
--
ALTER TABLE `classifications`
  ADD CONSTRAINT `fk_class_circular` FOREIGN KEY (`circular_id`) REFERENCES `circulars` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notif_circular` FOREIGN KEY (`circular_id`) REFERENCES `circulars` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `summaries`
--
ALTER TABLE `summaries`
  ADD CONSTRAINT `fk_summaries_circular` FOREIGN KEY (`circular_id`) REFERENCES `circulars` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_department` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
