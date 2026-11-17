# AGENTS.md

Guidance for AI coding agents (Codex, Copilot, Claude Code, etc.) working
in this repository.

## Project

BSJ-MM-SEC-0 is a security research repository maintained by
MohammadArshiya Rahgozar (@marshiyar) and Mobin Norouzi. The repository
is public.

## Hard rules

- Never commit secrets, credentials, private keys, tokens, or `.env`
  files. Use placeholders such as `<API_KEY>` in examples.
- Never commit target data, packet captures, memory dumps, malware
  samples, or binaries. See `.gitignore`.
- Never include real hostnames, IP addresses, or personal data of
  third-party targets in code, comments, or commit messages.
- Do not publish details of unfixed vulnerabilities in third-party
  software. Follow coordinated disclosure (see `SECURITY.md`).
- Proof-of-concept code must be safe by default: no destructive
  payloads, no mass scanning, no self-propagation, and it must only
  target hosts passed in explicitly by the user.
- Do not weaken security tooling: never disable CodeQL, pre-commit
  hooks, or gitleaks, and never add `# nosec`-style suppressions
  without explaining why in the PR.

## Workflow

- Work on a branch and open a pull request into `main`; never push to
  `main` directly.
- Run `pre-commit run --all-files` before committing. All hooks must
  pass.
- GitHub Actions must be pinned to a full-length commit SHA with the
  version in a comment, e.g.
  `uses: actions/checkout@<sha> # v7.0.1`. Tags like `@v4` will fail.
- When adding code in a new language, enable that language in the
  matrix in `.github/workflows/codeql.yml`.
- Keep PRs small and describe what changed and why.

## Code style

- Python: target 3.12+, follow PEP 8, add type hints. Manage
  dependencies with uv (`uv add <pkg>`); commit `pyproject.toml`
  and `uv.lock`, not `requirements.txt`.
- Prefer the standard library over new dependencies.

## Reviews

When reviewing, prioritize: leaked secrets or target data, unsafe
PoC behavior, injection and deserialization flaws, unpinned actions,
and changes that reduce existing security checks.
