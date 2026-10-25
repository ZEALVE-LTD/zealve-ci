# zealve-ci

Public host for the Zealve CI platform's **reusable GitHub Actions workflows**.

GitHub's free plan only allows reusable workflows to be called across repos when
they live in a **public** repository — the org's actual infra repo
(`ZEALVE-LTD/zealve-infra`, private) therefore cannot host them itself.

- No secrets, no infrastructure config, no app source live here — the workflows
  receive credentials via `secrets: inherit` from the calling repo at run time.
- The registry they push to (`registry.zealve.com`) is htpasswd-authenticated
  and IP-allowlisted to the three Zealve VPSes.
- Ownership, docs, and the runner/deploy machinery:
  `ZEALVE-LTD/zealve-infra` → `docs/CI-PLATFORM.md`.
