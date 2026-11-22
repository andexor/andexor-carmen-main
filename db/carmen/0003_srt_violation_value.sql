-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Andexor Network, Inc.
-- Author: Ed Jenkins <ed@andexor.net>

-- Migration: srt_violation_value.
-- Recreate every SRT trigger so that a violation names the rejected value, for example:
--   SRT violation: company.stage value 'HOT' is not in COMPANY_STAGE
-- The message is built from the row, which needs SQLite 3.47 or later. No data changes. Issue #20.
--
-- Write only this migration's changes. Never edit another migration file, and do not insert into
-- schema_migration (tools/migrate.py does). Mark every column that holds an SRT code with a
-- "-- SRT domain: X" comment on its line, in CREATE TABLE or ALTER TABLE ... ADD COLUMN; the
-- triggers are generated. Then run ./tools/build_schema.sh and python3 tools/check_schemas.py.

DROP TRIGGER srt_app_user_role_ins;
DROP TRIGGER srt_app_user_role_upd;
CREATE TRIGGER srt_app_user_role_ins BEFORE INSERT ON app_user
WHEN NEW.role IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='USER_ROLE' AND code=NEW.role AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: app_user.role value ' || quote(NEW.role) || ' is not in USER_ROLE'); END;
CREATE TRIGGER srt_app_user_role_upd BEFORE UPDATE OF role ON app_user
WHEN NEW.role IS NOT NULL AND NEW.role IS NOT OLD.role AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='USER_ROLE' AND code=NEW.role AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: app_user.role value ' || quote(NEW.role) || ' is not in USER_ROLE'); END;

DROP TRIGGER srt_service_category_ins;
DROP TRIGGER srt_service_category_upd;
CREATE TRIGGER srt_service_category_ins BEFORE INSERT ON service
WHEN NEW.category IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='SERVICE_CATEGORY' AND code=NEW.category AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: service.category value ' || quote(NEW.category) || ' is not in SERVICE_CATEGORY'); END;
CREATE TRIGGER srt_service_category_upd BEFORE UPDATE OF category ON service
WHEN NEW.category IS NOT NULL AND NEW.category IS NOT OLD.category AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='SERVICE_CATEGORY' AND code=NEW.category AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: service.category value ' || quote(NEW.category) || ' is not in SERVICE_CATEGORY'); END;

DROP TRIGGER srt_import_batch_source_ins;
DROP TRIGGER srt_import_batch_source_upd;
CREATE TRIGGER srt_import_batch_source_ins BEFORE INSERT ON import_batch
WHEN NEW.source IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='LEAD_SOURCE' AND code=NEW.source AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: import_batch.source value ' || quote(NEW.source) || ' is not in LEAD_SOURCE'); END;
CREATE TRIGGER srt_import_batch_source_upd BEFORE UPDATE OF source ON import_batch
WHEN NEW.source IS NOT NULL AND NEW.source IS NOT OLD.source AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='LEAD_SOURCE' AND code=NEW.source AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: import_batch.source value ' || quote(NEW.source) || ' is not in LEAD_SOURCE'); END;

DROP TRIGGER srt_company_stage_ins;
DROP TRIGGER srt_company_stage_upd;
CREATE TRIGGER srt_company_stage_ins BEFORE INSERT ON company
WHEN NEW.stage IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='COMPANY_STAGE' AND code=NEW.stage AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: company.stage value ' || quote(NEW.stage) || ' is not in COMPANY_STAGE'); END;
CREATE TRIGGER srt_company_stage_upd BEFORE UPDATE OF stage ON company
WHEN NEW.stage IS NOT NULL AND NEW.stage IS NOT OLD.stage AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='COMPANY_STAGE' AND code=NEW.stage AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: company.stage value ' || quote(NEW.stage) || ' is not in COMPANY_STAGE'); END;

DROP TRIGGER srt_company_source_ins;
DROP TRIGGER srt_company_source_upd;
CREATE TRIGGER srt_company_source_ins BEFORE INSERT ON company
WHEN NEW.source IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='LEAD_SOURCE' AND code=NEW.source AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: company.source value ' || quote(NEW.source) || ' is not in LEAD_SOURCE'); END;
CREATE TRIGGER srt_company_source_upd BEFORE UPDATE OF source ON company
WHEN NEW.source IS NOT NULL AND NEW.source IS NOT OLD.source AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='LEAD_SOURCE' AND code=NEW.source AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: company.source value ' || quote(NEW.source) || ' is not in LEAD_SOURCE'); END;

DROP TRIGGER srt_company_meeting_mode_ins;
DROP TRIGGER srt_company_meeting_mode_upd;
CREATE TRIGGER srt_company_meeting_mode_ins BEFORE INSERT ON company
WHEN NEW.meeting_mode IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='MEETING_MODE' AND code=NEW.meeting_mode AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: company.meeting_mode value ' || quote(NEW.meeting_mode) || ' is not in MEETING_MODE'); END;
CREATE TRIGGER srt_company_meeting_mode_upd BEFORE UPDATE OF meeting_mode ON company
WHEN NEW.meeting_mode IS NOT NULL AND NEW.meeting_mode IS NOT OLD.meeting_mode AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='MEETING_MODE' AND code=NEW.meeting_mode AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: company.meeting_mode value ' || quote(NEW.meeting_mode) || ' is not in MEETING_MODE'); END;

DROP TRIGGER srt_company_recommendation_ins;
DROP TRIGGER srt_company_recommendation_upd;
CREATE TRIGGER srt_company_recommendation_ins BEFORE INSERT ON company
WHEN NEW.recommendation IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='RECOMMENDATION' AND code=NEW.recommendation AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: company.recommendation value ' || quote(NEW.recommendation) || ' is not in RECOMMENDATION'); END;
CREATE TRIGGER srt_company_recommendation_upd BEFORE UPDATE OF recommendation ON company
WHEN NEW.recommendation IS NOT NULL AND NEW.recommendation IS NOT OLD.recommendation AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='RECOMMENDATION' AND code=NEW.recommendation AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: company.recommendation value ' || quote(NEW.recommendation) || ' is not in RECOMMENDATION'); END;

DROP TRIGGER srt_contact_role_ins;
DROP TRIGGER srt_contact_role_upd;
CREATE TRIGGER srt_contact_role_ins BEFORE INSERT ON contact
WHEN NEW.role IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='CONTACT_ROLE' AND code=NEW.role AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: contact.role value ' || quote(NEW.role) || ' is not in CONTACT_ROLE'); END;
CREATE TRIGGER srt_contact_role_upd BEFORE UPDATE OF role ON contact
WHEN NEW.role IS NOT NULL AND NEW.role IS NOT OLD.role AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='CONTACT_ROLE' AND code=NEW.role AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: contact.role value ' || quote(NEW.role) || ' is not in CONTACT_ROLE'); END;

DROP TRIGGER srt_ai_model_provider_ins;
DROP TRIGGER srt_ai_model_provider_upd;
CREATE TRIGGER srt_ai_model_provider_ins BEFORE INSERT ON ai_model
WHEN NEW.provider IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='AI_PROVIDER' AND code=NEW.provider AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: ai_model.provider value ' || quote(NEW.provider) || ' is not in AI_PROVIDER'); END;
CREATE TRIGGER srt_ai_model_provider_upd BEFORE UPDATE OF provider ON ai_model
WHEN NEW.provider IS NOT NULL AND NEW.provider IS NOT OLD.provider AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='AI_PROVIDER' AND code=NEW.provider AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: ai_model.provider value ' || quote(NEW.provider) || ' is not in AI_PROVIDER'); END;

DROP TRIGGER srt_ai_run_kind_ins;
DROP TRIGGER srt_ai_run_kind_upd;
CREATE TRIGGER srt_ai_run_kind_ins BEFORE INSERT ON ai_run
WHEN NEW.kind IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='AI_RUN_KIND' AND code=NEW.kind AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: ai_run.kind value ' || quote(NEW.kind) || ' is not in AI_RUN_KIND'); END;
CREATE TRIGGER srt_ai_run_kind_upd BEFORE UPDATE OF kind ON ai_run
WHEN NEW.kind IS NOT NULL AND NEW.kind IS NOT OLD.kind AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='AI_RUN_KIND' AND code=NEW.kind AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: ai_run.kind value ' || quote(NEW.kind) || ' is not in AI_RUN_KIND'); END;

DROP TRIGGER srt_ai_run_status_ins;
DROP TRIGGER srt_ai_run_status_upd;
CREATE TRIGGER srt_ai_run_status_ins BEFORE INSERT ON ai_run
WHEN NEW.status IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='RUN_STATUS' AND code=NEW.status AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: ai_run.status value ' || quote(NEW.status) || ' is not in RUN_STATUS'); END;
CREATE TRIGGER srt_ai_run_status_upd BEFORE UPDATE OF status ON ai_run
WHEN NEW.status IS NOT NULL AND NEW.status IS NOT OLD.status AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='RUN_STATUS' AND code=NEW.status AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: ai_run.status value ' || quote(NEW.status) || ' is not in RUN_STATUS'); END;

DROP TRIGGER srt_ai_run_recommendation_ins;
DROP TRIGGER srt_ai_run_recommendation_upd;
CREATE TRIGGER srt_ai_run_recommendation_ins BEFORE INSERT ON ai_run
WHEN NEW.recommendation IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='RECOMMENDATION' AND code=NEW.recommendation AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: ai_run.recommendation value ' || quote(NEW.recommendation) || ' is not in RECOMMENDATION'); END;
CREATE TRIGGER srt_ai_run_recommendation_upd BEFORE UPDATE OF recommendation ON ai_run
WHEN NEW.recommendation IS NOT NULL AND NEW.recommendation IS NOT OLD.recommendation AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='RECOMMENDATION' AND code=NEW.recommendation AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: ai_run.recommendation value ' || quote(NEW.recommendation) || ' is not in RECOMMENDATION'); END;

DROP TRIGGER srt_ai_run_fact_decision_ins;
DROP TRIGGER srt_ai_run_fact_decision_upd;
CREATE TRIGGER srt_ai_run_fact_decision_ins BEFORE INSERT ON ai_run_fact
WHEN NEW.decision IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='PROPOSAL_STATUS' AND code=NEW.decision AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: ai_run_fact.decision value ' || quote(NEW.decision) || ' is not in PROPOSAL_STATUS'); END;
CREATE TRIGGER srt_ai_run_fact_decision_upd BEFORE UPDATE OF decision ON ai_run_fact
WHEN NEW.decision IS NOT NULL AND NEW.decision IS NOT OLD.decision AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='PROPOSAL_STATUS' AND code=NEW.decision AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: ai_run_fact.decision value ' || quote(NEW.decision) || ' is not in PROPOSAL_STATUS'); END;

DROP TRIGGER srt_enrichment_key_value_type_ins;
DROP TRIGGER srt_enrichment_key_value_type_upd;
CREATE TRIGGER srt_enrichment_key_value_type_ins BEFORE INSERT ON enrichment_key
WHEN NEW.value_type IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ENRICHMENT_VALUE_TYPE' AND code=NEW.value_type AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: enrichment_key.value_type value ' || quote(NEW.value_type) || ' is not in ENRICHMENT_VALUE_TYPE'); END;
CREATE TRIGGER srt_enrichment_key_value_type_upd BEFORE UPDATE OF value_type ON enrichment_key
WHEN NEW.value_type IS NOT NULL AND NEW.value_type IS NOT OLD.value_type AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ENRICHMENT_VALUE_TYPE' AND code=NEW.value_type AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: enrichment_key.value_type value ' || quote(NEW.value_type) || ' is not in ENRICHMENT_VALUE_TYPE'); END;

DROP TRIGGER srt_enrichment_fact_source_ins;
DROP TRIGGER srt_enrichment_fact_source_upd;
CREATE TRIGGER srt_enrichment_fact_source_ins BEFORE INSERT ON enrichment_fact
WHEN NEW.source IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ENRICHMENT_SOURCE' AND code=NEW.source AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: enrichment_fact.source value ' || quote(NEW.source) || ' is not in ENRICHMENT_SOURCE'); END;
CREATE TRIGGER srt_enrichment_fact_source_upd BEFORE UPDATE OF source ON enrichment_fact
WHEN NEW.source IS NOT NULL AND NEW.source IS NOT OLD.source AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ENRICHMENT_SOURCE' AND code=NEW.source AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: enrichment_fact.source value ' || quote(NEW.source) || ' is not in ENRICHMENT_SOURCE'); END;

DROP TRIGGER srt_rubric_criterion_section_ins;
DROP TRIGGER srt_rubric_criterion_section_upd;
CREATE TRIGGER srt_rubric_criterion_section_ins BEFORE INSERT ON rubric_criterion
WHEN NEW.section IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='RUBRIC_SECTION' AND code=NEW.section AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: rubric_criterion.section value ' || quote(NEW.section) || ' is not in RUBRIC_SECTION'); END;
CREATE TRIGGER srt_rubric_criterion_section_upd BEFORE UPDATE OF section ON rubric_criterion
WHEN NEW.section IS NOT NULL AND NEW.section IS NOT OLD.section AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='RUBRIC_SECTION' AND code=NEW.section AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: rubric_criterion.section value ' || quote(NEW.section) || ' is not in RUBRIC_SECTION'); END;

DROP TRIGGER srt_rubric_criterion_answer_type_ins;
DROP TRIGGER srt_rubric_criterion_answer_type_upd;
CREATE TRIGGER srt_rubric_criterion_answer_type_ins BEFORE INSERT ON rubric_criterion
WHEN NEW.answer_type IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ANSWER_TYPE' AND code=NEW.answer_type AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: rubric_criterion.answer_type value ' || quote(NEW.answer_type) || ' is not in ANSWER_TYPE'); END;
CREATE TRIGGER srt_rubric_criterion_answer_type_upd BEFORE UPDATE OF answer_type ON rubric_criterion
WHEN NEW.answer_type IS NOT NULL AND NEW.answer_type IS NOT OLD.answer_type AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ANSWER_TYPE' AND code=NEW.answer_type AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: rubric_criterion.answer_type value ' || quote(NEW.answer_type) || ' is not in ANSWER_TYPE'); END;

DROP TRIGGER srt_rubric_answer_source_ins;
DROP TRIGGER srt_rubric_answer_source_upd;
CREATE TRIGGER srt_rubric_answer_source_ins BEFORE INSERT ON rubric_answer
WHEN NEW.source IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ANSWER_SOURCE' AND code=NEW.source AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: rubric_answer.source value ' || quote(NEW.source) || ' is not in ANSWER_SOURCE'); END;
CREATE TRIGGER srt_rubric_answer_source_upd BEFORE UPDATE OF source ON rubric_answer
WHEN NEW.source IS NOT NULL AND NEW.source IS NOT OLD.source AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ANSWER_SOURCE' AND code=NEW.source AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: rubric_answer.source value ' || quote(NEW.source) || ' is not in ANSWER_SOURCE'); END;

DROP TRIGGER srt_deal_stage_ins;
DROP TRIGGER srt_deal_stage_upd;
CREATE TRIGGER srt_deal_stage_ins BEFORE INSERT ON deal
WHEN NEW.stage IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='DEAL_STAGE' AND code=NEW.stage AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: deal.stage value ' || quote(NEW.stage) || ' is not in DEAL_STAGE'); END;
CREATE TRIGGER srt_deal_stage_upd BEFORE UPDATE OF stage ON deal
WHEN NEW.stage IS NOT NULL AND NEW.stage IS NOT OLD.stage AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='DEAL_STAGE' AND code=NEW.stage AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: deal.stage value ' || quote(NEW.stage) || ' is not in DEAL_STAGE'); END;

DROP TRIGGER srt_deal_engagement_model_ins;
DROP TRIGGER srt_deal_engagement_model_upd;
CREATE TRIGGER srt_deal_engagement_model_ins BEFORE INSERT ON deal
WHEN NEW.engagement_model IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ENGAGEMENT_MODEL' AND code=NEW.engagement_model AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: deal.engagement_model value ' || quote(NEW.engagement_model) || ' is not in ENGAGEMENT_MODEL'); END;
CREATE TRIGGER srt_deal_engagement_model_upd BEFORE UPDATE OF engagement_model ON deal
WHEN NEW.engagement_model IS NOT NULL AND NEW.engagement_model IS NOT OLD.engagement_model AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ENGAGEMENT_MODEL' AND code=NEW.engagement_model AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: deal.engagement_model value ' || quote(NEW.engagement_model) || ' is not in ENGAGEMENT_MODEL'); END;

DROP TRIGGER srt_agreement_type_ins;
DROP TRIGGER srt_agreement_type_upd;
CREATE TRIGGER srt_agreement_type_ins BEFORE INSERT ON agreement
WHEN NEW.type IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='AGREEMENT_TYPE' AND code=NEW.type AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: agreement.type value ' || quote(NEW.type) || ' is not in AGREEMENT_TYPE'); END;
CREATE TRIGGER srt_agreement_type_upd BEFORE UPDATE OF type ON agreement
WHEN NEW.type IS NOT NULL AND NEW.type IS NOT OLD.type AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='AGREEMENT_TYPE' AND code=NEW.type AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: agreement.type value ' || quote(NEW.type) || ' is not in AGREEMENT_TYPE'); END;

DROP TRIGGER srt_agreement_status_ins;
DROP TRIGGER srt_agreement_status_upd;
CREATE TRIGGER srt_agreement_status_ins BEFORE INSERT ON agreement
WHEN NEW.status IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='AGREEMENT_STATUS' AND code=NEW.status AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: agreement.status value ' || quote(NEW.status) || ' is not in AGREEMENT_STATUS'); END;
CREATE TRIGGER srt_agreement_status_upd BEFORE UPDATE OF status ON agreement
WHEN NEW.status IS NOT NULL AND NEW.status IS NOT OLD.status AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='AGREEMENT_STATUS' AND code=NEW.status AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: agreement.status value ' || quote(NEW.status) || ' is not in AGREEMENT_STATUS'); END;

DROP TRIGGER srt_agreement_engagement_model_ins;
DROP TRIGGER srt_agreement_engagement_model_upd;
CREATE TRIGGER srt_agreement_engagement_model_ins BEFORE INSERT ON agreement
WHEN NEW.engagement_model IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ENGAGEMENT_MODEL' AND code=NEW.engagement_model AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: agreement.engagement_model value ' || quote(NEW.engagement_model) || ' is not in ENGAGEMENT_MODEL'); END;
CREATE TRIGGER srt_agreement_engagement_model_upd BEFORE UPDATE OF engagement_model ON agreement
WHEN NEW.engagement_model IS NOT NULL AND NEW.engagement_model IS NOT OLD.engagement_model AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ENGAGEMENT_MODEL' AND code=NEW.engagement_model AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: agreement.engagement_model value ' || quote(NEW.engagement_model) || ' is not in ENGAGEMENT_MODEL'); END;

DROP TRIGGER srt_agreement_amount_period_ins;
DROP TRIGGER srt_agreement_amount_period_upd;
CREATE TRIGGER srt_agreement_amount_period_ins BEFORE INSERT ON agreement
WHEN NEW.amount_period IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='AMOUNT_PERIOD' AND code=NEW.amount_period AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: agreement.amount_period value ' || quote(NEW.amount_period) || ' is not in AMOUNT_PERIOD'); END;
CREATE TRIGGER srt_agreement_amount_period_upd BEFORE UPDATE OF amount_period ON agreement
WHEN NEW.amount_period IS NOT NULL AND NEW.amount_period IS NOT OLD.amount_period AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='AMOUNT_PERIOD' AND code=NEW.amount_period AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: agreement.amount_period value ' || quote(NEW.amount_period) || ' is not in AMOUNT_PERIOD'); END;

DROP TRIGGER srt_activity_kind_ins;
DROP TRIGGER srt_activity_kind_upd;
CREATE TRIGGER srt_activity_kind_ins BEFORE INSERT ON activity
WHEN NEW.kind IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ACTIVITY_KIND' AND code=NEW.kind AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: activity.kind value ' || quote(NEW.kind) || ' is not in ACTIVITY_KIND'); END;
CREATE TRIGGER srt_activity_kind_upd BEFORE UPDATE OF kind ON activity
WHEN NEW.kind IS NOT NULL AND NEW.kind IS NOT OLD.kind AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='ACTIVITY_KIND' AND code=NEW.kind AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: activity.kind value ' || quote(NEW.kind) || ' is not in ACTIVITY_KIND'); END;

DROP TRIGGER srt_task_status_ins;
DROP TRIGGER srt_task_status_upd;
CREATE TRIGGER srt_task_status_ins BEFORE INSERT ON task
WHEN NEW.status IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='TASK_STATUS' AND code=NEW.status AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: task.status value ' || quote(NEW.status) || ' is not in TASK_STATUS'); END;
CREATE TRIGGER srt_task_status_upd BEFORE UPDATE OF status ON task
WHEN NEW.status IS NOT NULL AND NEW.status IS NOT OLD.status AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='TASK_STATUS' AND code=NEW.status AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: task.status value ' || quote(NEW.status) || ' is not in TASK_STATUS'); END;

DROP TRIGGER srt_notification_kind_ins;
DROP TRIGGER srt_notification_kind_upd;
CREATE TRIGGER srt_notification_kind_ins BEFORE INSERT ON notification
WHEN NEW.kind IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='NOTIFICATION_KIND' AND code=NEW.kind AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: notification.kind value ' || quote(NEW.kind) || ' is not in NOTIFICATION_KIND'); END;
CREATE TRIGGER srt_notification_kind_upd BEFORE UPDATE OF kind ON notification
WHEN NEW.kind IS NOT NULL AND NEW.kind IS NOT OLD.kind AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='NOTIFICATION_KIND' AND code=NEW.kind AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: notification.kind value ' || quote(NEW.kind) || ' is not in NOTIFICATION_KIND'); END;

DROP TRIGGER srt_notification_channel_ins;
DROP TRIGGER srt_notification_channel_upd;
CREATE TRIGGER srt_notification_channel_ins BEFORE INSERT ON notification
WHEN NEW.channel IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='CHANNEL' AND code=NEW.channel AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: notification.channel value ' || quote(NEW.channel) || ' is not in CHANNEL'); END;
CREATE TRIGGER srt_notification_channel_upd BEFORE UPDATE OF channel ON notification
WHEN NEW.channel IS NOT NULL AND NEW.channel IS NOT OLD.channel AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='CHANNEL' AND code=NEW.channel AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: notification.channel value ' || quote(NEW.channel) || ' is not in CHANNEL'); END;

DROP TRIGGER srt_notification_status_ins;
DROP TRIGGER srt_notification_status_upd;
CREATE TRIGGER srt_notification_status_ins BEFORE INSERT ON notification
WHEN NEW.status IS NOT NULL AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='NOTIFICATION_STATUS' AND code=NEW.status AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: notification.status value ' || quote(NEW.status) || ' is not in NOTIFICATION_STATUS'); END;
CREATE TRIGGER srt_notification_status_upd BEFORE UPDATE OF status ON notification
WHEN NEW.status IS NOT NULL AND NEW.status IS NOT OLD.status AND NOT EXISTS (SELECT 1 FROM srt WHERE domain='NOTIFICATION_STATUS' AND code=NEW.status AND active=1)
BEGIN SELECT RAISE(ABORT, 'SRT violation: notification.status value ' || quote(NEW.status) || ' is not in NOTIFICATION_STATUS'); END;
