<!--
SPDX-License-Identifier: Apache-2.0
Copyright 2026 Andexor Network, Inc.
Author: Ed Jenkins <ed@andexor.net>
-->

# Install Pre-requisites

Most projects have certain pre-requisites that are required for development, testing, or running in production. Install the ones that are needed.

## NodeJS

For projects written in TypeScript, you need NodeJS.

The following script was copied from
[Node.js — Download Node.js®](https://nodejs.org/en/download/current).

### Download and install nvm:

> `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | bash`<br/>
> `exit`

### Start a new shell and download and install Node.js:

> `nvm install 26`

### Verify the Node.js version:

> `node -v`

### Verify npm version:

> `npm -v`

## Spec Kit

Some projects use Spec Kit to manage feature requirements and development.

If you have not installed uv yet, install it first.

> Run `install-uv.sh`<br/>
> Run `install-spec-kit.sh`

## License Checker

### TypeScript

For TypeScript projects, use @lizenz/checker.

To install it, run `npm install --save-dev @lizenz/checker`.

To run it, use `npx @lizenz/checker --excludePackages foo,bar --failOn GPL-3.0-or-later --markdown`
or copy run.sh from andexor-net-website.

### Python

For Python projects, use pip-licenses.

To install it, run `uv --quiet add pip-licenses`.

To run it, run `uv --quiet sync` and `uv run pip-licenses --format=markdown`
or copy setup.sh from andexor-net-website-ping.

## Playwright System Dependencies

For TypeScript projects, playwright is required for testing.

> Run `npx playwright install-deps webkit`

Here are some additional optional dependencies
you can install if you want, but Firefox is low priority,
so it is not included by default.

> Run `npx playwright install firefox`<br/>
> Run `npx playwright install-deps firefox`

Likewise, if you want to run tests for iPhone and iPad,
you can install these optional dependencies.
This hangs on my current development machine,
so they are not included by default at this time.
In the mean time, I use the device browser
in Chrome Dev Tools.

> Run `npx playwright install webkit`<br/>
> Run `npx playwright install-deps webkit`

## FontAwesome

Front-end applications may use FontAwesome icons.
The packages are added by setup.sh.
The Duotone icons are Font Awesome Pro,
used under a commercial annual
subscription held by Andexor Network, Inc.

- Purchased: 08/25/2026.
- Expires, or must be renewed: 08/25/2027. Renew before that date and update the expiration date here. After it lapses, a new install of the Pro icons fails, and so does the build.
- The license file is `.npmrc`. It is excluded from GitHub by `.gitignore`.

## Higgsfield

Front-end applications may use Higgsfield skills to create images and videos with AI.

To install them,

> Run `install-higgsfield.sh`

Then

> Run `./setup.sh`

## Cloudflare Workers

This service is deployed to Cloudflare Workers.

If you do not have Cloudflare installed and integrated with Claude Code,
then open Claude Code and paste this text into the prompt.

> Fetch and execute the appropriate instructions<br/>
> to set me up for Cloudflare from<br/>
> https://developers.cloudflare.com/agent-setup/prompt.md

Then log in. Use the browser-callback flow, not the default device-code flow.

> Run `install-cf.sh`

Then log in. Use the browser-callback flow, not the default device-code flow.

> Run `cf auth login --no-device`
