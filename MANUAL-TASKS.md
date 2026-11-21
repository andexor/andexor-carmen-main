<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Manual tasks

Setup steps that a person must do on a platform such as Cloudflare, GitHub, or Google, and cannot be scripted. Each step is listed here until it is done. Mark a step `[x]` with the date when it is finished.

## Email (decision Q5)

Cloudflare Email Sending, through the `send_email` binding, to Ed only in version 1. Q5 stays open until the digest reaches the inbox from the running Worker. Adding the `send_email` binding and sending a real digest happens in `andexor-carmen-api`, so it is tracked there, not here.

- [x] Sending domain: `carmen.andexor.net` (2026-11-19). The records are on `cf-bounce.carmen.andexor.net` (MX, SPF), `cf-bounce._domainkey.carmen.andexor.net` (DKIM), and `_dmarc.carmen.andexor.net`. The root MX, SPF, and DMARC records belong to Google Workspace and are unchanged.
- [x] `ed@andexor.net` verified as a destination address (2026-11-19).
- [x] Test email sent with the REST API (2026-11-19). SPF, DKIM (domain `carmen.andexor.net`), and DMARC all pass.
- [X] Get test mail out of the spam folder. Authentication passes, so this is a sender reputation matter. A Gmail filter that only applies a label was created (2026-11-19); send another test to see whether it lands in the inbox. If not, add `carmen@carmen.andexor.net` to Contacts, or add the address or domain to the approved senders list in the Google Workspace admin console (Gmail, Spam, Phishing, and Malware).
- [X] Optional: add `rua=mailto:dmarc@andexor.net` to the `_dmarc.carmen.andexor.net` record to receive reports.
- [X] After the proxied `AAAA carmen` record is added (see Cloudflare below), send another test to confirm email still works.

Online DNS scanners that look only at `carmen.andexor.net` report no SPF, DKIM, or MX. That is expected: the records are on the `cf-bounce` name and use the selector `cf-bounce`.

## Cloudflare

- [X] DNS: proxied `AAAA carmen` and proxied `AAAA carmen-preview`, each with content `100::`.
- [x] Zero Trust organization created (on or before 2026-11-17, the date of its first service token): team name `andexor`, team domain `andexor.cloudflareaccess.com`. Identity providers: Cloudflare and One-time PIN. Specified in `specs/002-cloudflare-access/spec.md` (issue #8).
- [x] (2026-11-21) Cloudflare Access: one application for `carmen.andexor.net` and one for `carmen-preview.andexor.net`, each with the hostname only and no path (this covers `/` and `/api/*`), with an allow-list of email addresses.
- [x] (2026-11-21) Application Audience (AUD) tag of each Access application (Zero Trust, Access controls, Applications, Edit, Additional settings). The api repo needs them with the team domain `andexor.cloudflareaccess.com`. They are identifiers, not secrets, and they change only if an application is deleted and recreated.
  - Production (`Carmen`): `17fc8e216219c7456af6fce2bb529e0c99df04b37eb244317d5ac662c2aa451c`
  - Preview (`Carmen preview`): `8154464c2b9aa058e7457872b661ce7b80996e8437f1b7e3fe678ab5068c0429`
- [x] (2026-11-21) Cloudflare Access service token `andexor-carmen-api` for CI, with a Service Auth policy on the preview application only, so the smoke test can sign in to the preview. Tested: production refuses it (403), and preview lets it through (522 until the Worker is deployed). Duration one year (8760h); it expires 2027-11-17. Cloudflare renews it in place (same Client ID and Secret), so GitHub secrets do not change on renewal.
- [x] (2026-11-21) Notifications: add an "Expiring Access Service Token" alert (dash.cloudflare.com, Notifications, Add), so Cloudflare emails a week before `andexor-carmen-api` expires.
- [x] (2026-11-21) Cloudflare Account API token for each repo, added to that repo's GitHub Actions and Dependabot secrets. GitHub secrets verified 2026-11-21 in api and ui (`CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, `ACCESS_CLIENT_ID`, `ACCESS_CLIENT_SECRET`, in both Actions and Dependabot). The Cloudflare token list was not checked.
- [x] (2026-11-21) Secrets Store: `carmen-claude-api-key` (Claude Console key). Verified in `default_secrets_store`: scope Workers only, status active.
- [x] (2026-11-21) Secrets Store: `carmen-typesafe-api-key` (the TypeSafe Console production key; a copy in GitHub secrets is not visible to the Worker). Verified in `default_secrets_store`: scope Workers only, status active. The preview key is not stored (preview binds no AI keys, per the api PRD). Still to do in the api repo: enable the Jev model in Settings.
- [x] (2026-11-21) Budget alert (account-wide; Cloudflare has no Workers AI-only alert, and spending limits cover only Workers and Durable Objects): the auto-created "Default budget alert" is enabled. The threshold was not checked; change it under Manage Account, Billing, Billable Usage.

## GitHub

- [ ] Default-branch ruleset with the required check `Preview and smoke test`, after the workflow has run once.
