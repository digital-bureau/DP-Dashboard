-- DESIGN REFERENCE ONLY. Not connected to the standalone HTML Dashboard.
-- PostgreSQL 15+; all RLS tables default deny until authorized policies are designed.
-- Dates use ISO Gregorian years; fiscal BE months are represented as TEXT '2569-10'.
CREATE SCHEMA IF NOT EXISTS niems_pim;
CREATE TABLE IF NOT EXISTS niems_pim.workstreams (
  code varchar(8) PRIMARY KEY, group_code varchar(12) NOT NULL CHECK(group_code IN ('ITCO','NDEMS')),
  name text NOT NULL, planned_month_intensity jsonb NOT NULL,
  source_reference text NOT NULL, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS niems_pim.procurement (
  code varchar(8) PRIMARY KEY, ordinal integer NOT NULL UNIQUE,
  name text NOT NULL, budget_type varchar(16) NOT NULL CHECK(budget_type IN ('ลงทุน','ดำเนินงาน')),
  planned_amount numeric(16,2) NOT NULL CHECK(planned_amount>=0),
  expected_procurement_month varchar(7), expected_use_month varchar(7),
  tor_draft_in_source boolean, source_reference text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS niems_pim.workstream_execution (
  workstream_code varchar(8) PRIMARY KEY REFERENCES niems_pim.workstreams(code),
  owner_user_id uuid, status text, actual_progress_pct numeric(5,2)
  CHECK(actual_progress_pct BETWEEN 0 AND 100), actual_due_date date,
  notes text, updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS niems_pim.monthly_execution (
  workstream_code varchar(8) REFERENCES niems_pim.workstreams(code),
  fiscal_month varchar(7) NOT NULL, actual_progress_pct numeric(5,2)
  CHECK(actual_progress_pct BETWEEN 0 AND 100), report_date date, notes text,
  reported_by uuid, updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(workstream_code,fiscal_month)
);
CREATE TABLE IF NOT EXISTS niems_pim.procurement_execution (
  procurement_code varchar(8) PRIMARY KEY REFERENCES niems_pim.procurement(code),
  owner_user_id uuid, status text, approved_allocation numeric(16,2) CHECK(approved_allocation>=0),
  recorded_commitment numeric(16,2) CHECK(recorded_commitment>=0),
  recorded_disbursement numeric(16,2) CHECK(recorded_disbursement>=0),
  tor_review_status text, notes text, updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS niems_pim.confirmed_mapping (
  procurement_code varchar(8) REFERENCES niems_pim.procurement(code),
  workstream_code varchar(8) REFERENCES niems_pim.workstreams(code),
  approved_by uuid, approved_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(procurement_code,workstream_code)
);
CREATE TABLE IF NOT EXISTS niems_pim.contracts (
  id uuid PRIMARY KEY, procurement_code varchar(8) NOT NULL REFERENCES niems_pim.procurement(code),
  contract_number text NOT NULL, vendor_name text, signed_on date, due_on date,
  contracted_amount numeric(16,2) CHECK(contracted_amount>=0),
  disbursed_amount numeric(16,2) CHECK(disbursed_amount>=0),
  status text, owner_user_id uuid, notes text, updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS niems_pim.staff (
  id uuid PRIMARY KEY, display_name text NOT NULL, group_code varchar(16),
  position_name text, monthly_capacity_hours numeric(8,2) CHECK(monthly_capacity_hours>=0),
  active boolean NOT NULL DEFAULT true, updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS niems_pim.work_allocations (
  id uuid PRIMARY KEY, staff_id uuid NOT NULL REFERENCES niems_pim.staff(id),
  workstream_code varchar(8) NOT NULL REFERENCES niems_pim.workstreams(code),
  fiscal_month varchar(7) NOT NULL, planned_hours numeric(9,2) CHECK(planned_hours>=0),
  actual_hours numeric(9,2) CHECK(actual_hours>=0), notes text, updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS niems_pim.outcome_indicators (
  code text PRIMARY KEY, name text NOT NULL,
  workstream_code varchar(8) REFERENCES niems_pim.workstreams(code),
  unit text, target_value numeric(15,3), actual_value numeric(15,3),
  planned_fiscal_month varchar(7), source_document text,
  notes text, updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS niems_pim.evidence (
  id uuid PRIMARY KEY, title text NOT NULL, related_type text NOT NULL,
  related_code text, evidence_date date, notes text,
  object_storage_path text, sha256 text, uploader_user_id uuid,
  uploaded_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS niems_pim.risk_register (
  id uuid PRIMARY KEY, risk_title text NOT NULL, related_code text,
  severity text, owner_user_id uuid, mitigation_status text,
  due_date date, mitigation_plan text, notes text,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS niems_pim.audit_events (
  id uuid PRIMARY KEY, occurred_at timestamptz NOT NULL DEFAULT now(),
  actor_user_id uuid, event_type text NOT NULL,
  subject_type text NOT NULL, subject_id text NOT NULL,
  old_record jsonb, new_record jsonb, correlation_id uuid
);
-- Lock down access by default. Policies and app roles require an approved design.
ALTER TABLE niems_pim.workstreams ENABLE ROW LEVEL SECURITY;
ALTER TABLE niems_pim.procurement ENABLE ROW LEVEL SECURITY;
ALTER TABLE niems_pim.workstream_execution ENABLE ROW LEVEL SECURITY;
ALTER TABLE niems_pim.monthly_execution ENABLE ROW LEVEL SECURITY;
ALTER TABLE niems_pim.procurement_execution ENABLE ROW LEVEL SECURITY;
ALTER TABLE niems_pim.confirmed_mapping ENABLE ROW LEVEL SECURITY;
ALTER TABLE niems_pim.contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE niems_pim.staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE niems_pim.work_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE niems_pim.outcome_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE niems_pim.evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE niems_pim.risk_register ENABLE ROW LEVEL SECURITY;
ALTER TABLE niems_pim.audit_events ENABLE ROW LEVEL SECURITY;
-- No permissive policies are intentionally supplied. Do not deploy as a public app without RBAC/RLS security review.
