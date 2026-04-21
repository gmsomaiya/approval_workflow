-- =============================================================
-- Approval Workflow SaaS — PostgreSQL Schema
-- Version : 1.0
-- Notes   : Reference schema, will evolve during development.
--           Run as a superuser or the DB owner.
-- =============================================================

-- -------------------------------------------------------
-- Extensions
-- -------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "citext";     -- case-insensitive email

-- -------------------------------------------------------
-- ENUM types  (must be created before any table uses them)
-- -------------------------------------------------------
CREATE TYPE billing_cycle_type        AS ENUM ('monthly', 'yearly');
CREATE TYPE rotation_reason_type      AS ENUM ('scheduled', 'compromised', 'admin_request');
CREATE TYPE user_role_type            AS ENUM ('admin', 'user', 'approver');
CREATE TYPE template_status_type      AS ENUM ('draft', 'published', 'active', 'inactive');
CREATE TYPE field_type_enum           AS ENUM ('string', 'integer', 'float', 'boolean', 'date',
                                               'datetime', 'dropdown', 'multiselect', 'textarea');
CREATE TYPE auth_type_enum            AS ENUM ('none', 'bearer_token', 'api_key', 'basic_auth');
CREATE TYPE assignee_type_enum        AS ENUM ('specific_user', 'role', 'hierarchy', 'team');
CREATE TYPE tat_miss_action_type      AS ENUM ('wait', 'escalate', 'auto_approve', 'auto_reject');
CREATE TYPE condition_type_enum       AS ENUM ('field_value', 'user_role', 'team_membership', 'custom');
CREATE TYPE condition_operator_enum   AS ENUM ('equals', 'not_equals', 'greater_than', 'less_than',
                                               'contains', 'in', 'not_in');
CREATE TYPE condition_action_enum     AS ENUM ('skip_step', 'goto_step', 'end_workflow', 'route_to_user');
CREATE TYPE rejection_action_enum     AS ENUM ('back_to_submitter', 'route_to_user', 'escalate', 'end_workflow');
CREATE TYPE submission_status_type    AS ENUM ('draft', 'submitted', 'in_review', 'approved',
                                               'rejected', 'cancelled', 'completed');
CREATE TYPE priority_type             AS ENUM ('low', 'normal', 'high', 'urgent');
CREATE TYPE approval_decision_type    AS ENUM ('pending', 'approved', 'rejected', 'hold');
CREATE TYPE audit_action_type         AS ENUM ('create', 'update', 'delete', 'login', 'logout');
CREATE TYPE user_type_enum            AS ENUM ('user', 'super_admin');
CREATE TYPE notification_type_enum    AS ENUM ('tat_reminder', 'approval_request', 'status_update',
                                               'rejection', 'escalation', 'system_alert');
CREATE TYPE setting_type_enum         AS ENUM ('string', 'integer', 'boolean', 'json', 'email', 'url');
CREATE TYPE email_template_type_enum  AS ENUM ('approval_request', 'tat_reminder', 'status_update',
                                               'rejection', 'completion');

-- =============================================================
-- 1. SUPER ADMIN TABLES
-- =============================================================

CREATE TABLE super_admins (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    email           CITEXT      UNIQUE NOT NULL,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    is_active       BOOLEAN     DEFAULT true,
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by      UUID        REFERENCES super_admins(id)
);

CREATE INDEX idx_super_admins_email  ON super_admins(email);
CREATE INDEX idx_super_admins_active ON super_admins(is_active);

-- -------------------------------------------------------

CREATE TABLE subscription_plans (
    id                  UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(100)   NOT NULL,
    description         TEXT,
    price_monthly       NUMERIC(10,2)  NOT NULL,
    price_yearly        NUMERIC(10,2),
    max_templates       INTEGER        NOT NULL,
    max_users           INTEGER        NOT NULL,
    max_monthly_forms   INTEGER        NOT NULL,
    max_storage_gb      INTEGER        NOT NULL,
    max_webhook_calls   INTEGER        NOT NULL,
    is_active           BOOLEAN        DEFAULT true,
    created_at          TIMESTAMPTZ    DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ    DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_subscription_plans_active ON subscription_plans(is_active);

-- =============================================================
-- 2. TENANT MANAGEMENT TABLES
-- =============================================================

CREATE TABLE tenants (
    id                      UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_code             VARCHAR(50)         UNIQUE NOT NULL,  -- e.g. COMP_ABC_001
    name                    VARCHAR(255)        NOT NULL,
    domain                  VARCHAR(255),
    subscription_plan_id    UUID                REFERENCES subscription_plans(id),
    secret_key_hash         VARCHAR(255)        NOT NULL,
    secret_key_created_at   TIMESTAMPTZ         DEFAULT CURRENT_TIMESTAMP,
    secret_key_expires_at   TIMESTAMPTZ,
    billing_cycle           billing_cycle_type  DEFAULT 'monthly',
    subscription_start_date DATE,
    subscription_end_date   DATE,
    is_active               BOOLEAN             DEFAULT true,
    created_at              TIMESTAMPTZ         DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ         DEFAULT CURRENT_TIMESTAMP,
    created_by              UUID                REFERENCES super_admins(id)
);

CREATE UNIQUE INDEX idx_tenants_tenant_code ON tenants(tenant_code);
CREATE INDEX        idx_tenants_active      ON tenants(is_active);
CREATE INDEX        idx_tenants_domain      ON tenants(domain);

-- -------------------------------------------------------

CREATE TABLE tenant_usage_limits (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID        NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    max_templates       INTEGER     NOT NULL,
    max_users           INTEGER     NOT NULL,
    max_monthly_forms   INTEGER     NOT NULL,
    max_storage_gb      INTEGER     NOT NULL,
    max_webhook_calls   INTEGER     NOT NULL,
    effective_from      DATE        NOT NULL,
    effective_until     DATE,
    created_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tenant_usage_limits_tenant    ON tenant_usage_limits(tenant_id);
CREATE INDEX idx_tenant_usage_limits_effective ON tenant_usage_limits(effective_from, effective_until);

-- -------------------------------------------------------

CREATE TABLE tenant_key_rotation_history (
    id                  UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID                  NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    old_key_hash        VARCHAR(255)          NOT NULL,
    new_key_hash        VARCHAR(255)          NOT NULL,
    rotation_reason     rotation_reason_type  NOT NULL,
    rotated_at          TIMESTAMPTZ           DEFAULT CURRENT_TIMESTAMP,
    old_key_disabled_at TIMESTAMPTZ           NOT NULL,
    rotated_by          UUID                  -- user or super_admin id
);

CREATE INDEX idx_tenant_key_rotation_tenant ON tenant_key_rotation_history(tenant_id);
CREATE INDEX idx_tenant_key_rotation_date   ON tenant_key_rotation_history(rotated_at);

-- =============================================================
-- 3. USER MANAGEMENT TABLES
-- =============================================================

CREATE TABLE users (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID            NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email               CITEXT          NOT NULL,
    first_name          VARCHAR(100)    NOT NULL,
    last_name           VARCHAR(100)    NOT NULL,
    password_hash       VARCHAR(255)    NOT NULL,
    role                user_role_type  NOT NULL DEFAULT 'user',
    department          VARCHAR(100),
    manager_id          UUID            REFERENCES users(id),
    is_active           BOOLEAN         DEFAULT true,
    last_login_at       TIMESTAMPTZ,
    password_changed_at TIMESTAMPTZ,
    created_at          TIMESTAMPTZ     DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ     DEFAULT CURRENT_TIMESTAMP,
    created_by          UUID            REFERENCES users(id)
);

CREATE UNIQUE INDEX idx_users_email_tenant_role ON users(email, tenant_id, role);
CREATE INDEX        idx_users_tenant            ON users(tenant_id);
CREATE INDEX        idx_users_active            ON users(is_active);
CREATE INDEX        idx_users_manager           ON users(manager_id);

-- -------------------------------------------------------

CREATE TABLE teams (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID        NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name           VARCHAR(255) NOT NULL,
    description    TEXT,
    department     VARCHAR(100),
    parent_team_id UUID        REFERENCES teams(id),
    is_active      BOOLEAN     DEFAULT true,
    created_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by     UUID        REFERENCES users(id)
);

CREATE INDEX idx_teams_tenant ON teams(tenant_id);
CREATE INDEX idx_teams_parent ON teams(parent_team_id);

-- -------------------------------------------------------

CREATE TABLE team_members (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id        UUID        NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id        UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    hierarchy_level INTEGER    DEFAULT 1,
    role_in_team   VARCHAR(100),
    is_active      BOOLEAN     DEFAULT true,
    joined_at      TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    left_at        TIMESTAMPTZ,
    created_by     UUID        REFERENCES users(id)
);

CREATE UNIQUE INDEX idx_team_members_team_user ON team_members(team_id, user_id) WHERE is_active = true;
CREATE INDEX        idx_team_members_user       ON team_members(user_id);

-- =============================================================
-- 4. FORM TEMPLATE TABLES
-- =============================================================

CREATE TABLE form_templates (
    id                        UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                 UUID                  NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name                      VARCHAR(255)          NOT NULL,
    description               TEXT,
    category                  VARCHAR(100),
    version                   INTEGER               DEFAULT 1,
    status                    template_status_type  DEFAULT 'draft',
    allow_attachments         BOOLEAN               DEFAULT false,
    max_attachments           INTEGER               DEFAULT 3,
    max_attachment_size_mb    INTEGER               DEFAULT 5,
    allowed_file_types        JSONB,                -- ["pdf","doc","jpg"]
    allow_approval_attachments BOOLEAN              DEFAULT false,
    monthly_usage_count       INTEGER               DEFAULT 0,
    total_usage_count         INTEGER               DEFAULT 0,
    is_deleted                BOOLEAN               DEFAULT false,
    created_at                TIMESTAMPTZ           DEFAULT CURRENT_TIMESTAMP,
    updated_at                TIMESTAMPTZ           DEFAULT CURRENT_TIMESTAMP,
    created_by                UUID                  REFERENCES users(id),
    published_at              TIMESTAMPTZ,
    published_by              UUID                  REFERENCES users(id)
);

CREATE INDEX idx_form_templates_tenant   ON form_templates(tenant_id);
CREATE INDEX idx_form_templates_status   ON form_templates(status);
CREATE INDEX idx_form_templates_active   ON form_templates(tenant_id, status) WHERE is_deleted = false;
CREATE INDEX idx_form_templates_category ON form_templates(category);

-- -------------------------------------------------------

CREATE TABLE form_template_fields (
    id               UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id      UUID             NOT NULL REFERENCES form_templates(id) ON DELETE CASCADE,
    field_name       VARCHAR(100)     NOT NULL,
    field_label      VARCHAR(255)     NOT NULL,
    field_type       field_type_enum  NOT NULL,
    is_required      BOOLEAN          DEFAULT false,
    field_order      INTEGER          NOT NULL,
    max_length       INTEGER,
    min_value        NUMERIC,
    max_value        NUMERIC,
    default_value    TEXT,
    options          JSONB,            -- ["opt1","opt2"] for dropdown / multiselect
    validation_rules JSONB,
    conditional_logic JSONB,
    created_at       TIMESTAMPTZ      DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_form_template_fields_template ON form_template_fields(template_id);
CREATE INDEX idx_form_template_fields_order    ON form_template_fields(template_id, field_order);

-- -------------------------------------------------------

CREATE TABLE form_template_webhooks (
    id               UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id      UUID            NOT NULL REFERENCES form_templates(id) ON DELETE CASCADE,
    webhook_url      VARCHAR(500)    NOT NULL,
    backup_url       VARCHAR(500),
    auth_type        auth_type_enum  DEFAULT 'none',
    auth_credentials JSONB,          -- encrypted at application layer
    signing_secret   VARCHAR(255),
    timeout_seconds  INTEGER         DEFAULT 30,
    retry_count      INTEGER         DEFAULT 3,
    retry_intervals  JSONB           DEFAULT '[60, 300, 900]',  -- seconds: 1m, 5m, 15m
    enabled_events   JSONB           NOT NULL,  -- ["submitted","approved","rejected",...]
    is_active        BOOLEAN         DEFAULT true,
    last_success_at  TIMESTAMPTZ,
    last_failure_at  TIMESTAMPTZ,
    failure_count    INTEGER         DEFAULT 0,
    created_at       TIMESTAMPTZ     DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMPTZ     DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_form_template_webhooks_template ON form_template_webhooks(template_id);
CREATE INDEX idx_form_template_webhooks_active   ON form_template_webhooks(is_active);

-- =============================================================
-- 5. WORKFLOW TABLES
-- =============================================================

CREATE TABLE workflows (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID        NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    template_id UUID        NOT NULL REFERENCES form_templates(id) ON DELETE CASCADE,
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    version     INTEGER     DEFAULT 1,
    is_active   BOOLEAN     DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by  UUID        REFERENCES users(id)
);

CREATE INDEX idx_workflows_tenant   ON workflows(tenant_id);
CREATE INDEX idx_workflows_template ON workflows(template_id);
CREATE INDEX idx_workflows_active   ON workflows(is_active);

-- -------------------------------------------------------

CREATE TABLE workflow_steps (
    id                UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id       UUID                  NOT NULL REFERENCES workflows(id) ON DELETE CASCADE,
    step_name         VARCHAR(255)          NOT NULL,
    step_order        INTEGER               NOT NULL,
    assignee_type     assignee_type_enum    NOT NULL,
    assignee_config   JSONB                 NOT NULL,
    tat_hours         INTEGER,
    reminder_hours    INTEGER,
    tat_miss_action   tat_miss_action_type  DEFAULT 'wait',
    escalation_config JSONB,
    require_comments  BOOLEAN               DEFAULT false,
    allow_attachments BOOLEAN               DEFAULT false,
    created_at        TIMESTAMPTZ           DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_workflow_steps_workflow ON workflow_steps(workflow_id);
CREATE INDEX idx_workflow_steps_order    ON workflow_steps(workflow_id, step_order);

-- -------------------------------------------------------

CREATE TABLE workflow_step_conditions (
    id              UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
    step_id         UUID                    NOT NULL REFERENCES workflow_steps(id) ON DELETE CASCADE,
    condition_type  condition_type_enum     NOT NULL,
    field_name      VARCHAR(100),
    operator        condition_operator_enum NOT NULL,
    condition_value JSONB                   NOT NULL,
    action          condition_action_enum   NOT NULL,
    action_config   JSONB,
    created_at      TIMESTAMPTZ             DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_workflow_step_conditions_step ON workflow_step_conditions(step_id);

-- -------------------------------------------------------

CREATE TABLE workflow_rejection_paths (
    id                       UUID                   PRIMARY KEY DEFAULT gen_random_uuid(),
    step_id                  UUID                   NOT NULL REFERENCES workflow_steps(id) ON DELETE CASCADE,
    rejection_action         rejection_action_enum  NOT NULL,
    route_to_user_id         UUID                   REFERENCES users(id),
    route_to_step_id         UUID                   REFERENCES workflow_steps(id),
    allow_revision           BOOLEAN                DEFAULT true,
    max_revisions            INTEGER                DEFAULT 3,
    reset_approval_chain     BOOLEAN                DEFAULT false,
    require_revision_comments BOOLEAN               DEFAULT true,
    created_at               TIMESTAMPTZ            DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_workflow_rejection_paths_step ON workflow_rejection_paths(step_id);

-- =============================================================
-- 6. FORM SUBMISSION TABLES
-- =============================================================

CREATE TABLE form_submissions (
    id                       UUID                    PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id                UUID                    NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    template_id              UUID                    REFERENCES form_templates(id),
    workflow_id              UUID                    REFERENCES workflows(id),
    request_number           VARCHAR(50)             NOT NULL,   -- e.g. LR-2024-001
    submitter_id             UUID                    REFERENCES users(id),
    form_data                JSONB                   NOT NULL,
    current_step_id          UUID                    REFERENCES workflow_steps(id),
    current_assignee_id      UUID                    REFERENCES users(id),
    status                   submission_status_type  DEFAULT 'draft',
    priority                 priority_type           DEFAULT 'normal',
    estimated_completion_date TIMESTAMPTZ,
    actual_completion_date   TIMESTAMPTZ,
    revision_count           INTEGER                 DEFAULT 0,
    is_revision              BOOLEAN                 DEFAULT false,
    original_submission_id   UUID                    REFERENCES form_submissions(id),
    created_at               TIMESTAMPTZ             DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMPTZ             DEFAULT CURRENT_TIMESTAMP,
    submitted_at             TIMESTAMPTZ,
    completed_at             TIMESTAMPTZ,
    UNIQUE (tenant_id, request_number)
);

CREATE INDEX idx_form_submissions_tenant    ON form_submissions(tenant_id);
CREATE INDEX idx_form_submissions_template  ON form_submissions(template_id);
CREATE INDEX idx_form_submissions_submitter ON form_submissions(submitter_id);
CREATE INDEX idx_form_submissions_assignee  ON form_submissions(current_assignee_id);
CREATE INDEX idx_form_submissions_status    ON form_submissions(status);
CREATE INDEX idx_form_submissions_submitted ON form_submissions(submitted_at);
CREATE INDEX idx_form_submissions_tenant_status_date
    ON form_submissions(tenant_id, status, submitted_at);

-- -------------------------------------------------------

CREATE TABLE form_submission_attachments (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id     UUID        NOT NULL REFERENCES form_submissions(id) ON DELETE CASCADE,
    original_filename VARCHAR(255) NOT NULL,
    stored_filename   VARCHAR(255) NOT NULL,
    file_path         VARCHAR(500) NOT NULL,
    file_size_bytes   BIGINT       NOT NULL,
    mime_type         VARCHAR(100) NOT NULL,
    uploaded_by       UUID        REFERENCES users(id),
    uploaded_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_form_submission_attachments_submission ON form_submission_attachments(submission_id);

-- -------------------------------------------------------

CREATE TABLE form_submission_approvals (
    id               UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id    UUID                  NOT NULL REFERENCES form_submissions(id) ON DELETE CASCADE,
    step_id          UUID                  REFERENCES workflow_steps(id),
    assignee_id      UUID                  REFERENCES users(id),
    decision         approval_decision_type DEFAULT 'pending',
    comments         TEXT,
    decision_date    TIMESTAMPTZ,
    tat_due_date     TIMESTAMPTZ,
    tat_reminded_at  TIMESTAMPTZ,
    tat_escalated_at TIMESTAMPTZ,
    escalated_to_id  UUID                  REFERENCES users(id),
    created_at       TIMESTAMPTZ           DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMPTZ           DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_form_submission_approvals_submission ON form_submission_approvals(submission_id);
CREATE INDEX idx_form_submission_approvals_assignee   ON form_submission_approvals(assignee_id);
CREATE INDEX idx_form_submission_approvals_decision   ON form_submission_approvals(decision);
CREATE INDEX idx_form_submission_approvals_tat_due    ON form_submission_approvals(tat_due_date);
CREATE INDEX idx_form_submission_approvals_assignee_decision_date
    ON form_submission_approvals(assignee_id, decision, tat_due_date);

-- -------------------------------------------------------

CREATE TABLE approval_attachments (
    id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    approval_id       UUID        NOT NULL REFERENCES form_submission_approvals(id) ON DELETE CASCADE,
    original_filename VARCHAR(255) NOT NULL,
    stored_filename   VARCHAR(255) NOT NULL,
    file_path         VARCHAR(500) NOT NULL,
    file_size_bytes   BIGINT       NOT NULL,
    mime_type         VARCHAR(100) NOT NULL,
    uploaded_by       UUID        REFERENCES users(id),
    uploaded_at       TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_approval_attachments_approval ON approval_attachments(approval_id);

-- =============================================================
-- 7. USAGE TRACKING TABLES
-- =============================================================

CREATE TABLE tenant_usage_tracking (
    id                     UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id              UUID        NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    usage_date             DATE        NOT NULL,
    active_users_count     INTEGER     DEFAULT 0,
    forms_submitted_count  INTEGER     DEFAULT 0,
    templates_created_count INTEGER    DEFAULT 0,
    storage_used_bytes     BIGINT      DEFAULT 0,
    webhook_calls_count    INTEGER     DEFAULT 0,
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, usage_date)
);

CREATE INDEX idx_tenant_usage_tracking_date         ON tenant_usage_tracking(usage_date);
CREATE INDEX idx_tenant_usage_tracking_tenant_month
    ON tenant_usage_tracking(tenant_id, DATE_TRUNC('month', usage_date));

-- -------------------------------------------------------

CREATE TABLE webhook_delivery_logs (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID        NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    template_id      UUID        REFERENCES form_templates(id),
    submission_id    UUID        REFERENCES form_submissions(id),
    webhook_url      VARCHAR(500) NOT NULL,
    event_type       VARCHAR(50)  NOT NULL,
    payload          JSONB        NOT NULL,
    http_status_code INTEGER,
    response_body    TEXT,
    response_time_ms INTEGER,
    retry_count      INTEGER      DEFAULT 0,
    delivered_at     TIMESTAMPTZ,
    failed_at        TIMESTAMPTZ,
    next_retry_at    TIMESTAMPTZ,
    created_at       TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_webhook_delivery_logs_tenant     ON webhook_delivery_logs(tenant_id);
CREATE INDEX idx_webhook_delivery_logs_submission ON webhook_delivery_logs(submission_id);
CREATE INDEX idx_webhook_delivery_logs_status     ON webhook_delivery_logs(http_status_code);
CREATE INDEX idx_webhook_delivery_logs_next_retry
    ON webhook_delivery_logs(next_retry_at, retry_count) WHERE next_retry_at IS NOT NULL;

-- =============================================================
-- 8. AUDIT & NOTIFICATION TABLES
-- =============================================================

CREATE TABLE audit_logs (
    id          UUID               PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID               REFERENCES tenants(id) ON DELETE CASCADE,
    table_name  VARCHAR(100)       NOT NULL,
    record_id   UUID               NOT NULL,
    action      audit_action_type  NOT NULL,
    old_values  JSONB,
    new_values  JSONB,
    user_id     UUID,              -- users or super_admins
    user_type   user_type_enum     NOT NULL,
    ip_address  INET,
    user_agent  TEXT,
    created_at  TIMESTAMPTZ        DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_tenant       ON audit_logs(tenant_id);
CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_user         ON audit_logs(user_id, user_type);
CREATE INDEX idx_audit_logs_created_at   ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_tenant_table_date
    ON audit_logs(tenant_id, table_name, created_at);

-- -------------------------------------------------------

CREATE TABLE system_notifications (
    id                    UUID                   PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID                   REFERENCES tenants(id) ON DELETE CASCADE,
    user_id               UUID                   REFERENCES users(id),
    notification_type     notification_type_enum NOT NULL,
    title                 VARCHAR(255)           NOT NULL,
    message               TEXT                   NOT NULL,
    related_submission_id UUID                   REFERENCES form_submissions(id),
    is_read               BOOLEAN                DEFAULT false,
    sent_via_email        BOOLEAN                DEFAULT false,
    email_sent_at         TIMESTAMPTZ,
    created_at            TIMESTAMPTZ            DEFAULT CURRENT_TIMESTAMP,
    read_at               TIMESTAMPTZ
);

CREATE INDEX idx_system_notifications_tenant ON system_notifications(tenant_id);
CREATE INDEX idx_system_notifications_user   ON system_notifications(user_id);
CREATE INDEX idx_system_notifications_unread ON system_notifications(user_id, is_read);
CREATE INDEX idx_system_notifications_type   ON system_notifications(notification_type);

-- =============================================================
-- 9. SYSTEM CONFIGURATION TABLES
-- =============================================================

CREATE TABLE system_settings (
    id            UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID              REFERENCES tenants(id) ON DELETE CASCADE,
    setting_key   VARCHAR(100)      NOT NULL,
    setting_value JSONB             NOT NULL,
    setting_type  setting_type_enum NOT NULL,
    description   TEXT,
    is_encrypted  BOOLEAN           DEFAULT false,
    created_at    TIMESTAMPTZ       DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ       DEFAULT CURRENT_TIMESTAMP,
    updated_by    UUID              REFERENCES users(id),
    UNIQUE (tenant_id, setting_key)
);

-- -------------------------------------------------------

CREATE TABLE email_templates (
    id            UUID                       PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id     UUID                       REFERENCES tenants(id) ON DELETE CASCADE,
    template_name VARCHAR(100)               NOT NULL,
    template_type email_template_type_enum   NOT NULL,
    subject       VARCHAR(255)               NOT NULL,
    body_html     TEXT                       NOT NULL,
    body_text     TEXT,
    variables     JSONB,
    is_active     BOOLEAN                    DEFAULT true,
    created_at    TIMESTAMPTZ                DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ                DEFAULT CURRENT_TIMESTAMP,
    created_by    UUID                       REFERENCES users(id)
);

CREATE INDEX idx_email_templates_tenant ON email_templates(tenant_id);
CREATE INDEX idx_email_templates_type   ON email_templates(template_type);

-- =============================================================
-- 10. VIEWS
-- =============================================================

CREATE VIEW tenant_active_users AS
SELECT
    t.id          AS tenant_id,
    t.tenant_code,
    t.name        AS tenant_name,
    COUNT(u.id)   AS active_user_count
FROM tenants t
LEFT JOIN users u ON t.id = u.tenant_id AND u.is_active = true
WHERE t.is_active = true
GROUP BY t.id, t.tenant_code, t.name;

-- -------------------------------------------------------

CREATE VIEW user_pending_approvals AS
SELECT
    u.id                          AS user_id,
    u.email,
    u.tenant_id,
    COUNT(fsa.id)                 AS pending_count,
    COUNT(CASE WHEN fsa.tat_due_date < NOW() THEN 1 END) AS overdue_count,
    MIN(fsa.tat_due_date)         AS earliest_due_date
FROM users u
LEFT JOIN form_submission_approvals fsa
    ON u.id = fsa.assignee_id AND fsa.decision = 'pending'
WHERE u.is_active = true
GROUP BY u.id, u.email, u.tenant_id;

-- -------------------------------------------------------

CREATE VIEW tenant_monthly_usage AS
SELECT
    t.id          AS tenant_id,
    t.tenant_code,
    DATE_TRUNC('month', CURRENT_DATE)   AS usage_month,
    COALESCE(SUM(tut.forms_submitted_count),  0) AS forms_submitted,
    COALESCE(SUM(tut.webhook_calls_count),    0) AS webhook_calls,
    COALESCE(MAX(tut.storage_used_bytes),     0) AS storage_used_bytes,
    COALESCE(MAX(tut.active_users_count),     0) AS peak_active_users
FROM tenants t
LEFT JOIN tenant_usage_tracking tut
    ON t.id = tut.tenant_id
    AND tut.usage_date >= DATE_TRUNC('month', CURRENT_DATE)
WHERE t.is_active = true
GROUP BY t.id, t.tenant_code;

-- =============================================================
-- 11. AUDIT TRIGGER
-- =============================================================

CREATE OR REPLACE FUNCTION audit_trigger_fn()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (tenant_id, table_name, record_id, action, old_values, user_id, user_type)
        VALUES (
            OLD.tenant_id,
            TG_TABLE_NAME, OLD.id, 'delete', to_jsonb(OLD),
            NULLIF(current_setting('app.current_user_id',  true), '')::UUID,
            COALESCE(current_setting('app.current_user_type', true), 'user')::user_type_enum
        );
        RETURN OLD;

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (tenant_id, table_name, record_id, action, old_values, new_values, user_id, user_type)
        VALUES (
            NEW.tenant_id,
            TG_TABLE_NAME, NEW.id, 'update', to_jsonb(OLD), to_jsonb(NEW),
            NULLIF(current_setting('app.current_user_id',  true), '')::UUID,
            COALESCE(current_setting('app.current_user_type', true), 'user')::user_type_enum
        );
        RETURN NEW;

    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (tenant_id, table_name, record_id, action, new_values, user_id, user_type)
        VALUES (
            NEW.tenant_id,
            TG_TABLE_NAME, NEW.id, 'create', to_jsonb(NEW),
            NULLIF(current_setting('app.current_user_id',  true), '')::UUID,
            COALESCE(current_setting('app.current_user_type', true), 'user')::user_type_enum
        );
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_form_submissions_audit
    AFTER INSERT OR UPDATE OR DELETE ON form_submissions
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER trg_form_templates_audit
    AFTER INSERT OR UPDATE OR DELETE ON form_templates
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER trg_users_audit
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER trg_form_submission_approvals_audit
    AFTER INSERT OR UPDATE OR DELETE ON form_submission_approvals
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- =============================================================
-- 12. DATA RETENTION FUNCTIONS  (schedule via pg_cron or cron)
-- =============================================================

CREATE OR REPLACE FUNCTION cleanup_old_audit_logs()
RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE deleted_count INTEGER;
BEGIN
    DELETE FROM audit_logs WHERE created_at < NOW() - INTERVAL '2 years';
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END; $$;

CREATE OR REPLACE FUNCTION cleanup_old_webhook_logs()
RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE deleted_count INTEGER;
BEGIN
    DELETE FROM webhook_delivery_logs
    WHERE created_at < NOW() - INTERVAL '6 months'
      AND http_status_code BETWEEN 200 AND 299;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END; $$;

CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE deleted_count INTEGER;
BEGIN
    DELETE FROM system_notifications
    WHERE created_at < NOW() - INTERVAL '1 year'
      AND is_read = true;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END; $$;

-- =============================================================
-- END OF SCHEMA
-- =============================================================
