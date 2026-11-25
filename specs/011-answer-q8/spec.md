<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Feature Specification: Answer Q8: the Claude model is claude-sonnet-5-5

**Feature Branch**: `44-answer-q8`

**Created**: 2026-11-25

**Status**: Implemented. No database change, so nothing to apply.

**Input**: Issue #44. Open item Q8 asked which Claude model Carmen uses. Ed answered on 2026-11-25: `claude-sonnet-5-5`. Where this spec and an earlier document differ, this spec governs.

## Requirements

- **FR-001**: The Claude model is `claude-sonnet-5-5`, for research runs and for scoring runs.
- **FR-002**: The seeded `ai_model` row for provider `CLAUDE` holds `model_id` `claude-sonnet-5-5`, and `ai.default_research_model` and `ai.default_scoring_model` point to that row. This is already so in migration `0001` and in both databases, so no migration is added.
- **FR-003**: The model stays a value in `ai_model`, edited in Settings. A later change of model needs no deploy.
- **FR-004**: `specs/001-review-open-items/decisions.md` lists Q8 as closed, and `CLAUDE.md` no longer lists Q8 as open.

## Success criteria

- **SC-001**: In the preview and in production, `ai_model` holds one active `CLAUDE` row with `model_id` `claude-sonnet-5-5`, and both default-model settings resolve to it.
- **SC-002**: `./tools/build_schema.sh && python3 tools/check_schemas.py` prints ALL PASS.
