```sql
-- Create database
CREATE DATABASE IF NOT EXISTS hotel_app;
USE hotel_app;

-- =========================
-- Core user & roles
-- =========================

CREATE TABLE users (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(100),
    last_name       VARCHAR(100),
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    is_active       TINYINT(1) DEFAULT 1,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE roles (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) UNIQUE NOT NULL,
    description VARCHAR(255),
    is_system   TINYINT(1) DEFAULT 0,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE privileges (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code        VARCHAR(150) UNIQUE NOT NULL,
    description VARCHAR(255)
);

CREATE TABLE role_privileges (
    role_id       BIGINT UNSIGNED NOT NULL,
    privilege_id  BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (role_id, privilege_id),
    FOREIGN KEY (role_id) REFERENCES roles(id),
    FOREIGN KEY (privilege_id) REFERENCES privileges(id)
);

CREATE TABLE user_roles (
    user_id BIGINT UNSIGNED NOT NULL,
    role_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (role_id) REFERENCES roles(id)
);

-- =========================
-- Payroll & scheduling
-- =========================

CREATE TABLE departments (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    description VARCHAR(255)
);

CREATE TABLE employee_profiles (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED NOT NULL,
    department_id   BIGINT UNSIGNED,
    hourly_rate     DECIMAL(10,2),
    hire_date       DATE,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (department_id) REFERENCES departments(id)
);

CREATE TABLE shifts (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id     BIGINT UNSIGNED NOT NULL,
    start_time      DATETIME NOT NULL,
    end_time        DATETIME NOT NULL,
    scheduled_by    BIGINT UNSIGNED,
    status          ENUM('scheduled','completed','cancelled') DEFAULT 'scheduled',
    FOREIGN KEY (employee_id) REFERENCES employee_profiles(id),
    FOREIGN KEY (scheduled_by) REFERENCES users(id)
);

-- Scenarios / Forecast / Actuals

CREATE TABLE forecast_scenarios (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    description     TEXT,
    start_date      DATE,
    end_date        DATE,
    created_by      BIGINT UNSIGNED,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE forecast_data_imports (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    scenario_id         BIGINT UNSIGNED NOT NULL,
    source_name         VARCHAR(150),
    file_path           VARCHAR(255),
    imported_at         DATETIME,
    FOREIGN KEY (scenario_id) REFERENCES forecast_scenarios(id)
);

CREATE TABLE forecast_values (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    scenario_id     BIGINT UNSIGNED NOT NULL,
    metric_name     VARCHAR(150) NOT NULL,
    metric_date     DATE NOT NULL,
    value           DECIMAL(15,4),
    FOREIGN KEY (scenario_id) REFERENCES forecast_scenarios(id)
);

CREATE TABLE actual_metrics (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_id   BIGINT UNSIGNED,
    metric_name     VARCHAR(150) NOT NULL,
    metric_date     DATE NOT NULL,
    value           DECIMAL(15,4),
    FOREIGN KEY (department_id) REFERENCES departments(id)
);

-- =========================
-- Housekeeping assistance
-- =========================

CREATE TABLE rooms (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_number     VARCHAR(20) UNIQUE NOT NULL,
    floor           INT,
    status          ENUM('vacant','occupied','out_of_order') DEFAULT 'vacant'
);

CREATE TABLE housekeepers (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id     BIGINT UNSIGNED NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employee_profiles(id)
);

CREATE TABLE room_cleanings (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_id         BIGINT UNSIGNED NOT NULL,
    housekeeper_id  BIGINT UNSIGNED NOT NULL,
    start_time      DATETIME,
    end_time        DATETIME,
    status          ENUM('assigned','in_progress','completed','failed') DEFAULT 'assigned',
    FOREIGN KEY (room_id) REFERENCES rooms(id),
    FOREIGN KEY (housekeeper_id) REFERENCES housekeepers(id)
);

CREATE TABLE cleaning_notifications (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_cleaning_id    BIGINT UNSIGNED NOT NULL,
    supervisor_id       BIGINT UNSIGNED NOT NULL,
    sent_at             DATETIME NOT NULL,
    status              ENUM('sent','read') DEFAULT 'sent',
    FOREIGN KEY (room_cleaning_id) REFERENCES room_cleanings(id),
    FOREIGN KEY (supervisor_id) REFERENCES users(id)
);

CREATE TABLE supervisor_communications (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sender_id       BIGINT UNSIGNED NOT NULL,
    receiver_id     BIGINT UNSIGNED NOT NULL,
    message         TEXT NOT NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id),
    FOREIGN KEY (receiver_id) REFERENCES users(id)
);

CREATE TABLE work_orders (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    created_by      BIGINT UNSIGNED NOT NULL,
    assigned_to     BIGINT UNSIGNED,
    room_id         BIGINT UNSIGNED,
    title           VARCHAR(150) NOT NULL,
    description     TEXT,
    priority        ENUM('low','medium','high') DEFAULT 'medium',
    status          ENUM('open','in_progress','completed','cancelled') DEFAULT 'open',
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    due_at          DATETIME,
    FOREIGN KEY (created_by) REFERENCES users(id),
    FOREIGN KEY (assigned_to) REFERENCES users(id),
    FOREIGN KEY (room_id) REFERENCES rooms(id)
);

CREATE TABLE work_order_photos (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    work_order_id   BIGINT UNSIGNED NOT NULL,
    file_path       VARCHAR(255) NOT NULL,
    uploaded_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id)
);

CREATE TABLE housekeeping_inspections (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_cleaning_id BIGINT UNSIGNED NOT NULL,
    inspector_id    BIGINT UNSIGNED NOT NULL,
    score           INT NOT NULL,
    comments        TEXT,
    inspected_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (room_cleaning_id) REFERENCES room_cleanings(id),
    FOREIGN KEY (inspector_id) REFERENCES users(id)
);

CREATE TABLE inspection_photos (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    inspection_id       BIGINT UNSIGNED NOT NULL,
    file_path           VARCHAR(255) NOT NULL,
    uploaded_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (inspection_id) REFERENCES housekeeping_inspections(id)
);

-- Recognition system

CREATE TABLE recognition_scores (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id     BIGINT UNSIGNED NOT NULL,
    date            DATE NOT NULL,
    score           INT NOT NULL,
    avg_clean_time  INT, -- seconds or minutes
    FOREIGN KEY (employee_id) REFERENCES employee_profiles(id)
);

CREATE TABLE recognition_daily_comparisons (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    date            DATE NOT NULL,
    department_id   BIGINT UNSIGNED,
    best_employee_id BIGINT UNSIGNED,
    best_score      INT,
    best_combined_metric DECIMAL(10,4),
    FOREIGN KEY (department_id) REFERENCES departments(id),
    FOREIGN KEY (best_employee_id) REFERENCES employee_profiles(id)
);

CREATE TABLE frequent_issues (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_id         BIGINT UNSIGNED,
    description     TEXT NOT NULL,
    occurrences     INT DEFAULT 1,
    last_seen_at    DATETIME,
    FOREIGN KEY (room_id) REFERENCES rooms(id)
);

CREATE TABLE recognition_streaks (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id     BIGINT UNSIGNED NOT NULL,
    streak_type     ENUM('score','time','combined') NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE,
    length_days     INT,
    FOREIGN KEY (employee_id) REFERENCES employee_profiles(id)
);

CREATE TABLE recognition_benchmarks (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    description     TEXT,
    metric_type     ENUM('score','time','combined') NOT NULL,
    threshold_value DECIMAL(10,4) NOT NULL,
    created_by      BIGINT UNSIGNED NOT NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- =========================
-- Accounting
-- =========================

CREATE TABLE recurring_expenses (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vendor_name     VARCHAR(150),
    description     TEXT,
    amount          DECIMAL(12,2),
    frequency       ENUM('daily','weekly','monthly','quarterly','yearly'),
    next_due_date   DATE,
    last_paid_date  DATE
);

CREATE TABLE journal_entries (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    entry_date      DATE NOT NULL,
    description     TEXT,
    created_by      BIGINT UNSIGNED,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE journal_entry_lines (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    journal_entry_id BIGINT UNSIGNED NOT NULL,
    account_code    VARCHAR(50) NOT NULL,
    debit           DECIMAL(12,2) DEFAULT 0,
    credit          DECIMAL(12,2) DEFAULT 0,
    FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id)
);

CREATE TABLE accounts_payable (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vendor_name     VARCHAR(150),
    invoice_number  VARCHAR(100),
    invoice_date    DATE,
    due_date        DATE,
    amount          DECIMAL(12,2),
    status          ENUM('open','paid','cancelled') DEFAULT 'open'
);

CREATE TABLE accounts_payable_photos (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ap_id           BIGINT UNSIGNED NOT NULL,
    file_path       VARCHAR(255) NOT NULL,
    detected_amount DECIMAL(12,2),
    uploaded_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ap_id) REFERENCES accounts_payable(id)
);

CREATE TABLE cost_per_metrics (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    metric_name     VARCHAR(150) NOT NULL,
    unit            VARCHAR(50),
    date            DATE NOT NULL,
    value           DECIMAL(12,4) NOT NULL
);

-- =========================
-- Scheduler / maintenance / inventory
-- =========================

CREATE TABLE equipment_inventory (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    category        VARCHAR(100),
    serial_number   VARCHAR(100),
    quantity        INT DEFAULT 1,
    expiration_date DATE,
    used_for_breakfast TINYINT(1) DEFAULT 0,
    used_for_cleaning  TINYINT(1) DEFAULT 0
);

CREATE TABLE scheduled_tasks (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(150) NOT NULL,
    description     TEXT,
    department_id   BIGINT UNSIGNED,
    assigned_to     BIGINT UNSIGNED,
    start_time      DATETIME,
    end_time        DATETIME,
    is_recurring    TINYINT(1) DEFAULT 0,
    recurrence_rule VARCHAR(255), -- e.g. cron-like or custom
    status          ENUM('pending','in_progress','completed','cancelled') DEFAULT 'pending',
    FOREIGN KEY (department_id) REFERENCES departments(id),
    FOREIGN KEY (assigned_to) REFERENCES users(id)
);

CREATE TABLE task_time_checks (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    task_id         BIGINT UNSIGNED NOT NULL,
    check_time      DATETIME NOT NULL,
    note            TEXT,
    FOREIGN KEY (task_id) REFERENCES scheduled_tasks(id)
);

CREATE TABLE maintenance_work_orders (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    work_order_id   BIGINT UNSIGNED NOT NULL,
    type            ENUM('maintenance','preventative','project','fire_life_safety') NOT NULL,
    FOREIGN KEY (work_order_id) REFERENCES work_orders(id)
);

CREATE TABLE fire_life_safety_checks (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    maintenance_id  BIGINT UNSIGNED NOT NULL,
    check_date      DATE NOT NULL,
    passed          TINYINT(1) DEFAULT 1,
    notes           TEXT,
    FOREIGN KEY (maintenance_id) REFERENCES maintenance_work_orders(id)
);

CREATE TABLE projects (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    description     TEXT,
    start_date      DATE,
    end_date        DATE,
    status          ENUM('planned','active','completed','on_hold') DEFAULT 'planned',
    owner_id        BIGINT UNSIGNED,
    FOREIGN KEY (owner_id) REFERENCES users(id)
);

-- =========================
-- Breakfast helper
-- =========================

CREATE TABLE ingredients (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    unit            VARCHAR(50) NOT NULL
);

CREATE TABLE breakfast_inventory (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ingredient_id   BIGINT UNSIGNED NOT NULL,
    quantity_on_hand DECIMAL(12,4) NOT NULL,
    unit_cost       DECIMAL(12,4),
    last_updated    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
);

CREATE TABLE recipes (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    description     TEXT
);

CREATE TABLE recipe_ingredients (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    recipe_id       BIGINT UNSIGNED NOT NULL,
    ingredient_id   BIGINT UNSIGNED NOT NULL,
    quantity        DECIMAL(12,4) NOT NULL,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id),
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
);

CREATE TABLE order_guides (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ingredient_id   BIGINT UNSIGNED NOT NULL,
    par_level       DECIMAL(12,4),
    reorder_point   DECIMAL(12,4),
    last_price      DECIMAL(12,4),
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
);

CREATE TABLE recipe_usage_logs (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    recipe_id       BIGINT UNSIGNED NOT NULL,
    served_count    INT NOT NULL,
    used_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id)
);

CREATE TABLE food_waste_photos (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    recipe_id       BIGINT UNSIGNED,
    file_path       VARCHAR(255) NOT NULL,
    estimated_value DECIMAL(12,2),
    wasted_at       DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id)
);

-- =========================
-- Dashboard / homepage
-- =========================

CREATE TABLE manager_dashboard_metrics (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    manager_id      BIGINT UNSIGNED NOT NULL,
    department_id   BIGINT UNSIGNED,
    metric_name     VARCHAR(150) NOT NULL,
    metric_value    DECIMAL(15,4),
    metric_date     DATE NOT NULL,
    FOREIGN KEY (manager_id) REFERENCES users(id),
    FOREIGN KEY (department_id) REFERENCES departments(id)
);

CREATE TABLE user_dashboard_preferences (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED NOT NULL,
    preferred_widgets JSON,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- =========================
-- Deliver hospitality
-- =========================

CREATE TABLE clock_events (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_id     BIGINT UNSIGNED NOT NULL,
    clock_type      ENUM('in','out') NOT NULL,
    clock_time      DATETIME NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES employee_profiles(id)
);

CREATE TABLE hospitality_notifications (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED NOT NULL,
    message         TEXT NOT NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    delivered_at    DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE notification_recaps (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED NOT NULL,
    recap_date      DATE NOT NULL,
    recap_text      TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE guest_issues (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_id         BIGINT UNSIGNED,
    guest_name      VARCHAR(150),
    issue_type      VARCHAR(150),
    description     TEXT,
    reported_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    status          ENUM('open','in_progress','resolved') DEFAULT 'open',
    FOREIGN KEY (room_id) REFERENCES rooms(id)
);

CREATE TABLE recovery_actions (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    guest_issue_id  BIGINT UNSIGNED NOT NULL,
    action_type     ENUM('task_unfinished','other') NOT NULL,
    description     TEXT,
    performed_by    BIGINT UNSIGNED,
    performed_at    DATETIME,
    FOREIGN KEY (guest_issue_id) REFERENCES guest_issues(id),
    FOREIGN KEY (performed_by) REFERENCES users(id)
);

CREATE TABLE good_to_knows (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    guest_issue_id  BIGINT UNSIGNED,
    customer_name   VARCHAR(150),
    notes           TEXT,
    created_by      BIGINT UNSIGNED,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (guest_issue_id) REFERENCES guest_issues(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE customer_suggestions (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    good_to_know_id BIGINT UNSIGNED,
    suggestion_text TEXT,
    FOREIGN KEY (good_to_know_id) REFERENCES good_to_knows(id)
);
```
