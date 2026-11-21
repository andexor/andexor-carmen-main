<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Manual setup runbook: Cloudflare, Claude, TypeSafe, and GitHub

Every manual step needed to put a Workers app behind Cloudflare Access, let continuous integration and continuous delivery (CI/CD) sign in to it, send email, and give it its Claude and TypeSafe keys. Written for Andexor Carmen, and reusable for any other app or customer: replace the values in angle brackets.

Checked on 2026-11-21 against Cloudflare's documentation, the Claude platform documentation, and the TypeSafe documentation. These products rename and move menus often. If a path below does not match, use the deep links in each step, or search the product's docs for the bold page name. Places where the docs did not name a menu are marked FILL IN: write the exact menu you used the next time you follow this.

## Everything that is done by hand

| System | Step | Section |
| --- | --- | --- |
| Cloudflare | Proxied DNS record for each hostname | 1 |
| Cloudflare | Zero Trust organization (team name, Free plan) | 2 |
| Cloudflare | One-time PIN login method | 3 |
| Cloudflare | Access application per hostname, with an Allow policy | 4 |
| Cloudflare | CI service token and its preview-only Service Auth policy | 5, 6 |
| Cloudflare | Record the team domain and the AUD tags | 7 |
| Cloudflare | Test the token on preview and production | 8 |
| Cloudflare | Expiring service token alert | 9 |
| Cloudflare | Account API token for each repo | 11 |
| Cloudflare | Secrets Store secrets, scope Workers | 11 |
| Cloudflare | Budget alert | 11 |
| Cloudflare | Email Sending: onboard the sending domain | 12 |
| Cloudflare | Email Routing: verify the destination address | 13 |
| Cloudflare | Email Sending API token, and a test send | 13 |
| Google Workspace | Keep test mail out of spam | 13 |
| Claude Console | Workspace (optional), billing, spend limit, API key | 14 |
| TypeSafe Console | API keys (production and preview) | 15 |
| GitHub | Repositories, Actions and Dependabot secrets, review team, branch ruleset | 16 |

## The three names

| Name | What it is |
| --- | --- |
| Cloudflare One | The product family (Access, Gateway, Tunnel, and others). Same thing as Zero Trust. |
| Zero Trust | The sidebar item in the dashboard, and the name of your organization. |
| Access | The one feature used here: a login gate in front of a hostname. Found under Zero Trust, then Access controls. |

All dashboard paths start at https://dash.cloudflare.com with your account selected.

## Values to decide first

| Value | Carmen example | Notes |
| --- | --- | --- |
| Team name | `andexor` | Becomes `<team-name>.cloudflareaccess.com`. Pick one you will keep. |
| Production hostname | `carmen.andexor.net` | One Access application per hostname. |
| Preview hostname | `carmen-preview.andexor.net` | Separate application, separate policies. |
| Allowed email addresses | `ed@andexor.net` | People who may sign in. |
| CI service token name | `andexor-carmen-api` | One token, allowed on preview only. |
| Email sending domain | `carmen.andexor.net` | A subdomain, so the root domain's mail setup is untouched. |
| Sender address | `carmen@carmen.andexor.net` | Any local part on the sending domain. |
| Email recipient | `ed@andexor.net` | Version 1 sends only to this address. |

## 1. DNS record for the hostname

Skip this if the Worker uses a Custom Domain, because Cloudflare creates the record. It is needed when the Worker uses Routes, which is how Carmen splits `/api/*` and `/*` between two Workers. A Route only takes effect when a proxied DNS record exists for the hostname.

1. Go to **DNS**, then **Records** for the zone (https://dash.cloudflare.com/?to=/:account/:zone/dns/records).
2. Select **Add record**.
3. Type `AAAA`, Name `<subdomain>`, IPv6 address `100::`, Proxy status **Proxied**. The address `100::` is a reserved placeholder. Cloudflare answers the request before it goes anywhere.
4. Select **Save**. Repeat for the preview subdomain.

Without this record, the hostname does not resolve (`ERR_NAME_NOT_RESOLVED`) and the Access login page never appears.

## 2. Create the Zero Trust organization (once per Cloudflare account)

Skip this if **Zero Trust** already opens a dashboard.

1. Select **Zero Trust**.
2. On the onboarding screen, enter a team name.
3. Choose the **Zero Trust Free** plan. Cloudflare still asks for payment details but does not charge the Free plan.

New organizations get the **Cloudflare** identity provider as the default login method. Your team name is shown under **Zero Trust**, then **Settings**.

## 3. Add the One-time PIN login method

The Cloudflare login only works for people who are members of your Cloudflare account. One-time PIN emails a code to any address your policy allows, so teammates and customers do not need a Cloudflare account.

1. Go to **Zero Trust**, then **Integrations**, then **Identity providers**.
2. Under **Your identity providers**, select **Add new identity provider**.
3. Select **One-time PIN**.
4. If your mail system filters or spam-sorts these codes, allow the sender domain `notify.cloudflare.com` and the address `noreply@notify.cloudflare.com`.

## 4. Create an Access application for each hostname

1. Go to **Zero Trust**, then **Access controls**, then **Applications**.
2. Select **Create new application**, then **Self-hosted and private**.
3. Select **Add public hostname**. In the **Domain** list, pick the zone, and enter the subdomain. Leave the path empty: a hostname with no path protects the whole site, so `/` and `/api/*` are both covered.
4. Under **Access policies**, create a policy:
   - Action: **Allow**
   - Rule type: **Include**
   - Selector: **Emails** (use **Emails ending in** to allow a whole domain)
   - Value: the allowed address
5. Allow the login methods **Cloudflare** and **One-time PIN** on the application.
6. Name the application, then create it.

Every Access application denies everyone by default. Only an Allow policy lets people in. Repeat for the preview hostname, as a separate application.

## 5. Create the CI service token

A service token is a Client ID and Client Secret pair that lets a machine sign in.

1. Go to **Zero Trust**, then **Access controls**, then **Service credentials**, then **Service Tokens** (https://one.dash.cloudflare.com/?to=/:account/access/service-auth/service-tokens).
2. Select **Create Service Token**.
3. Name it, and choose a **Service Token Duration**. This sets the expiry date. One year (8760h) works.
4. Select **Generate token**.
5. Copy the Client ID (ends in `.access`) and the Client Secret now. The secret is shown once. If you lose it, generate a new token.
6. Store both in GitHub secrets (see step 11). Never put them in a repo.

## 6. Let the token into the preview application only

1. Go to **Zero Trust**, then **Access controls**, then **Applications**.
2. Select the preview application, then **Edit**, then the **Policies** tab.
3. Select **Create new policy**:
   - Action: **Service Auth**. Not Allow. Allow policies do not accept tokens.
   - Rule type: **Include**
   - Selector: **Service Token**
   - Value: the token from step 5
4. Make sure the policy is on the application's policy list, then save the application.

Do not add this policy to the production application. A token allowed on production would let CI touch production data. Do not create a second application on the same hostname just to add the token. Add the policy to the existing application.

An application can have both policies. The Allow policy serves people in a browser, and the Service Auth policy serves machines.

## 7. Record the team domain and the AUD tags

The API needs both to verify the Access token on every request.

- Team domain: `<team-name>.cloudflareaccess.com`, under **Zero Trust**, then **Settings**.
- Application Audience (AUD) tag, one per application: **Zero Trust**, then **Access controls**, then **Applications**, select **Edit**, then **Additional settings**. The tag never changes unless you delete and recreate the application. It is an identifier, not a secret.

## 8. Test

Save this script outside the repo (or in a git-ignored file) and run it once per hostname. Use double quotes around the headers, because single quotes send the variable name as text and every request fails with 401.

```bash
#!/bin/bash
HOST="$1"
CF_ACCESS_CLIENT_ID="<client-id>.access"
CF_ACCESS_CLIENT_SECRET="<client-secret>"

curl -s -o /dev/null -w '%{http_code}' \
  -H "CF-Access-Client-Id: ${CF_ACCESS_CLIENT_ID}" \
  -H "CF-Access-Client-Secret: ${CF_ACCESS_CLIENT_SECRET}" \
  "https://${HOST}/"
echo ""
```

| Test | Expected result |
| --- | --- |
| Preview hostname with the token | Not 401, 403, or a redirect. With no Worker deployed yet, 522 is expected: Access let the request in, and no origin answered. |
| Production hostname with the token | 401 or 403. The token is not allowed there. |
| Browser, private window, either hostname | The Access sign-in page. After signing in, an error page until the Worker is deployed. |

Organizations created on or after 2026-10-05 have strict service token authentication on by default and cannot turn it off. In that mode a failed token request always gets 401 or 403, never a login redirect, and only Service Auth policies can authorize a token request.

If the preview returns 401, check **Zero Trust**, then **Insights**, then **Logs**, then **Access authentication logs**. Access logs expired or disabled tokens, wrong secrets, and tokens not allowed on the application. It does not log malformed headers or unknown Client IDs, so no log entry at all usually means a typo in the Client ID or a missing `.access` suffix.

## 9. Alert before the token expires

1. Go to **Notifications** (https://dash.cloudflare.com/?to=/:account/notifications).
2. Select **Add**, then **Expiring Access Service Token**.
3. Name it and save. It emails a week before any service token expires.

To renew, go to **Service Tokens**, find the token, and use its refresh action, or **Edit** to choose a new duration. The Client ID and Secret stay the same, so GitHub secrets do not change. To replace a secret you suspect is exposed, use the three dots, then **Rotate secret**, and choose a grace period (one hour to 30 days) or revoke the old secret immediately.

## 10. Do not turn on "Block traffic to all domains"

Under **Zero Trust**, then **Access controls**, then **Access settings**, there is a switch named **Block traffic to all domains in this account**. Leave it off. Turned on, it blocks every hostname in the account that has no Access application, including public sites.

## 11. Account API token, GitHub secrets, Secrets Store, and billing alert

### Account API token (one per repo, for deploys)

1. Go to **Manage account**, then **Account API tokens** (https://dash.cloudflare.com/?to=/:account/api-tokens).
2. Select **Create Token**. Enter a name, the permissions, and an optional expiration date.
3. Select **Continue to summary**, review it, then **Create Token**.
4. Copy the value now. It is shown once.

Creating account tokens needs the Super Administrator role or the API Token Provisioning role. If a deploy binds a Secrets Store secret, the token needs the **Account Secrets Store Edit** permission. A token with only Read fails at deploy time.

### GitHub secrets

Add these in each repo that deploys or runs the smoke test, under **Settings**, then **Secrets and variables**, in both **Actions** and **Dependabot**:

| Secret | Value |
| --- | --- |
| `CLOUDFLARE_API_TOKEN` | The Account API token for that repo |
| `CLOUDFLARE_ACCOUNT_ID` | The Cloudflare account ID |
| `ACCESS_CLIENT_ID` | The service token Client ID |
| `ACCESS_CLIENT_SECRET` | The service token Client Secret |

From a terminal, `gh secret set <NAME> -R <owner>/<repo>` asks for the value, and adding `--app dependabot` sets the Dependabot copy.

### Secrets Store (keys the Worker reads at run time)

1. Go to the **Secrets Store** page (https://dash.cloudflare.com/?to=/:account/secrets-store).
2. Select **Create secret**.
3. Enter the name (no spaces) and the value, and choose **Workers** as the **Permission scope**. Choose only Workers unless another service needs it.
4. Select **Save**. The value cannot be viewed afterward.

A secret in GitHub is not visible to a Worker. Only a Secrets Store secret bound to the Worker is. A Worker binds one secret by name, so a separate key for preview needs its own secret name.

### Billing alert

Cloudflare has no alert for Workers AI alone. Budget alerts cover all usage-based products together, Workers AI included. Pay-as-you-go accounts get a default $10 alert automatically.

1. Go to **Manage account**, then **Billing**, then **Billable Usage**.
2. Select **Set Budget Alert**, enter an amount above $0, and select **Create**. The same alert can be created under **Notifications**, then **Add**, then **Budget Alert**.

Alerts are informational and are processed daily, so an email arrives the day after the threshold is crossed. The Workers Paid plan fee is not counted. Spending limits exist only for Workers and Durable Objects, and they block usage at the limit.

## 12. Email Sending: onboard the sending domain

Email Service needs the domain to use Cloudflare DNS. Email Sending treats each subdomain as its own sending domain, so onboarding `carmen.andexor.net` does not touch the root domain's mail records.

1. Go to **Compute**, then **Email Service**, then **Email Sending** (https://dash.cloudflare.com/?to=/:account/email-service/sending).
2. Select **Onboard Domain** and choose the domain or subdomain to send from.
3. Review the records Cloudflare will add on the `cf-bounce` subdomain, then select **Done**:
   - MX records for bounces, on `cf-bounce.<sending-domain>`
   - SPF record, on `cf-bounce.<sending-domain>`
   - DKIM record, on `cf-bounce._domainkey.<sending-domain>`
   - DMARC record, on `_dmarc.<sending-domain>`. Cloudflare adds it only if the domain has none. You can edit it afterward and Cloudflare keeps your edit.
4. Wait 5 to 15 minutes. Check the records under **Email Sending**, then **Settings**. They show as **Locked**, which means Email Service manages them.

Optional: add `rua=mailto:<address>` to the `_dmarc.<sending-domain>` record to receive DMARC reports.

Online DNS scanners that look only at `<sending-domain>` report no SPF, DKIM, or MX. That is expected, because the records are on the `cf-bounce` name and use the selector `cf-bounce`. A scanner needs the full name `cf-bounce.<sending-domain>` for SPF, and the selector `cf-bounce` for DKIM.

## 13. Email Routing destination, API token, test send, and spam

Email Routing is a zone-level feature on the root domain. Onboarding it replaces the root domain's MX records with Cloudflare's, and it fails with error 2008 if another provider's MX records exist. Carmen does not receive mail, so it does not onboard the root domain: the root domain's mail stays with Google Workspace. Only a destination address is needed.

1. Go to **Compute**, then **Email Service**, then **Email Routing**, then **Destination Addresses** (https://dash.cloudflare.com/?to=/:account/email-service/routing).
2. Enter the recipient address (`ed@andexor.net`) in the inline form and submit it.
3. Open the verification email Cloudflare sends and select **Verify email address**.

Destination addresses belong to the account, and sends to a verified destination address are free. Before a sending domain is onboarded, mail can go only to verified destination addresses.

### API token for sending

1. Go to **Manage account**, then **Account API tokens**, then **Create Token** (https://dash.cloudflare.com/?to=/:account/api-tokens).
2. Give it only the **Email Sending: Edit** permission. Anyone holding this token can send mail from any onboarded domain on the account, so treat it like a password.
3. Copy the value. It is shown once.

### Test send

1. Send one test email through the REST API (see the Email Service docs page "Send emails with the REST API"), from an address on the sending domain to the verified recipient. The REST API field names differ from the Workers binding: `from` takes `address`, and the reply field is `reply_to`.
2. Open the message in Gmail, choose **Show original**, and check that SPF, DKIM, and DMARC all say PASS.

### If the test mail lands in spam

Authentication passing with spam placement means a new sender with no reputation. It is not a configuration error.

1. In Gmail, create a filter for `<sender address>` that applies a label (Gmail has no filter option to never send to spam). Send another test.
2. If it still lands in spam, add the sender to Contacts, or add the address or the domain to the approved senders list in the Google Workspace admin console. FILL IN: the exact admin console path, which was not tried for Carmen.

### Later, in the app repo

The Worker sends through the `send_email` binding in its Wrangler configuration. Send one real message from the running Worker and confirm it reaches the inbox before closing the email decision.

## 14. Claude Console

Docs: https://platform.claude.com/docs.

1. Sign in at https://platform.claude.com. The organization page is https://platform.claude.com/settings/organization. The docs do not say how to create an organization. FILL IN: how the Carmen organization was created.
2. Optional workspace: go to https://platform.claude.com/settings/workspaces, then **Create workspace**, enter a name, pick a color, and select **Create workspace**. Only organization admins can do this. Every organization already has a **Default Workspace**.
3. Billing and credits: FILL IN. The Claude documentation I read does not name the page for adding a payment method or buying credits. Write the exact menu you used.
4. Spend limit: https://platform.claude.com/settings/spend-limits. Select **Set limit** or **Adjust limit** next to **Monthly spend limit**. To limit one workspace, pick it from the dropdown under **Workspace limits** first. **Add notification** under **Email notifications** sets spend alerts. Your own limit cannot exceed your tier's cap.
5. API key: go to https://platform.claude.com/settings/keys and select **Create key**. Enter a name, choose an expiration, set **Linked account** (yourself or a service account), and optionally pick a workspace to scope the key to. A key scoped to one workspace needs no workspace header. An unscoped key must send the `anthropic-workspace-id` header or the API returns 400. Copy the key now. It is shown once.
6. Store the key in Cloudflare Secrets Store (step 11), named `carmen-claude-api-key`, scope Workers. A copy in GitHub secrets is not visible to the Worker.

Usage and cost: https://platform.claude.com/usage and https://platform.claude.com/cost. Rate limits: https://platform.claude.com/usage/limits.

## 15. TypeSafe Console

Docs: https://docs.typesafe.ai. The docs describe only the keys page and the rate-limits page. I did not open the console pages themselves.

1. Go to https://console.typesafe.ai/keys and create an API key. FILL IN: how the account was created, how billing was added, and how the keys are named. The docs do not cover them.
2. Create one key for production and one for preview if you want them separate. Carmen stores only the production key. Preview binds no AI keys, so the preview key stays unused. Keep it in a password manager.
3. Store the production key in Cloudflare Secrets Store (step 11), named `carmen-typesafe-api-key`, scope Workers. Add a copy to GitHub secrets only in a repository whose CI calls Jev. For Carmen, only the app that calls Jev needs it, so the TypeSafe key is not in the other repositories' secrets.
4. The environment variable name in TypeSafe's tools is `TYPESAFE_API_KEY`. Requests send the key as `Authorization: Bearer <key>`. A missing or wrong key returns 401.
5. After the secret exists, enable the Jev model in the app's Settings. That step happens in the app, once the app exists.

Limits and cost: https://console.typesafe.ai/rate-limits shows your organization's limits. Jev is billed per input token only. Pricing is on https://docs.typesafe.ai/models.md.

## 16. GitHub

1. Repositories: create each repository under the organization (`andexor`). Carmen's three repositories are public.
2. Secrets: add the four secrets from step 11 in each repository that deploys or runs the smoke test, in both **Actions** and **Dependabot**. Under **Settings**, then **Secrets and variables**. These GitHub paths come from general knowledge, not from GitHub's current docs, so check them the first time.
3. Pull requests: every pull request is assigned to the author and requests review from the organization's `write` team, and it closes an issue with `Closes #<number>`.
4. Branch ruleset: protect the default branch with a ruleset that requires the check `Preview and smoke test`. The check only appears in the ruleset's list after the workflow has run once, so add the requirement after the first run. This is not done yet for Carmen's app repositories.

## Verify from the terminal (read-only)

These list names and dates only, never secret values:

```bash
cf zero-trust access service-tokens list
cf alerting policies list
cf secrets-store secrets list --store-id <store-id>
gh secret list -R <owner>/<repo>
gh secret list --app dependabot -R <owner>/<repo>
```

## Setting this up for a customer

- Use the customer's own Cloudflare account. Do not share your tokens or secrets across customers.
- Run steps 2 to 10 in their account, with their hostnames and their team name.
- Give each customer's CI its own service token and its own Account API token.
- Hand over the team domain and the AUD tags. Do not hand over any secret by email or chat.
