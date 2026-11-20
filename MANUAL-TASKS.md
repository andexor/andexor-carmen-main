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
- [ ] Cloudflare Access: one application for `carmen.andexor.net` and one for `carmen-preview.andexor.net`, each covering `/` and `/api/*`, with an allow-list of email addresses.
- [ ] Cloudflare Access service token for CI, so the smoke test can sign in to the preview.
- [ ] Cloudflare Account API token for each repo, added to that repo's GitHub Actions and Dependabot secrets.
- [ ] Secrets Store: `carmen-claude-api-key` (Claude Console key).
- [ ] Secrets Store: `carmen-typesafe-api-key` (the TypeSafe Console key; a copy in GitHub secrets is not visible to the Worker). Then enable the Jev model in Settings.
- [ ] Workers AI: set a billing notification in the Cloudflare dashboard.

## GitHub

- [ ] Default-branch ruleset with the required check `Preview and smoke test`, after the workflow has run once.
