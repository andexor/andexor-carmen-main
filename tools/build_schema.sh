#!/bin/bash

# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Andexor Network, Inc.
# Author: Ed Jenkins <ed@andexor.net>

# Build db/carmen/0001_init.sql from 0001_init.base.sql plus the generated SRT triggers,
# then regenerate the entity-relationship diagrams in doc/uml/.
# Run from the repo root. Add a line to the list below when a column starts holding an SRT code.

set -euo pipefail

BASE=db/carmen/0001_init.base.sql
OUT=db/carmen/0001_init.sql

cp "$BASE" "$OUT"
python3 tools/gen_srt_triggers.py \
    app_user.role:USER_ROLE \
    service.category:SERVICE_CATEGORY \
    import_batch.source:LEAD_SOURCE \
    company.stage:COMPANY_STAGE \
    company.source:LEAD_SOURCE \
    company.meeting_mode:MEETING_MODE \
    company.recommendation:RECOMMENDATION \
    contact.role:CONTACT_ROLE \
    ai_model.provider:AI_PROVIDER \
    ai_run.kind:AI_RUN_KIND \
    ai_run.status:RUN_STATUS \
    ai_run.recommendation:RECOMMENDATION \
    ai_run_fact.decision:PROPOSAL_STATUS \
    enrichment_fact.source:ENRICHMENT_SOURCE \
    enrichment_key.value_type:ENRICHMENT_VALUE_TYPE \
    rubric_criterion.section:RUBRIC_SECTION \
    rubric_criterion.answer_type:ANSWER_TYPE \
    rubric_answer.source:ANSWER_SOURCE \
    deal.stage:DEAL_STAGE \
    deal.engagement_model:ENGAGEMENT_MODEL \
    agreement.type:AGREEMENT_TYPE \
    agreement.status:AGREEMENT_STATUS \
    agreement.engagement_model:ENGAGEMENT_MODEL \
    agreement.amount_period:AMOUNT_PERIOD \
    activity.kind:ACTIVITY_KIND \
    task.status:TASK_STATUS \
    notification.kind:NOTIFICATION_KIND \
    notification.channel:CHANNEL \
    notification.status:NOTIFICATION_STATUS \
    >> "$OUT"
echo "Wrote $OUT"
python3 tools/gen_erd.py
