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

## Running AI agents

These rules apply to any AI agent that works on this repository or on
research for it. See [SANDBOXING.md](SANDBOXING.md) for the tiers.

- An agent that executes code (runs commands, tests, scripts, or tools)
  runs in the locked-down container (`make sandbox`, tier 2) or higher.
  An agent that only reads and edits files may run on the main machine,
  but must not execute anything there.
- Give the agent only the work directory it needs. Never mount your home
  directory, SSH keys, cloud credentials, or a git checkout into its
  sandbox.
- API keys and tokens are passed as environment variables when the agent
  starts, for example `export PROVIDER_API_KEY=<API_KEY>` in the shell
  that launches it. Never write them to a file: not to `.env`, config
  files, scripts, notebooks, logs, or commit messages.
- Use a separate key for agent work, with the lowest limits and
  permissions the provider allows, so it can be revoked on its own.
- Log every agent run: who started it, when, which agent and model, the
  task given, the tier and work directory, and the commands it ran. Keep
  the logs outside this repository (`*.log` is ignored) and check them for
  secrets before sharing any part of them.
- An agent must stay within [SCOPE.md](SCOPE.md). It must not be given
  real target details unless that run is covered by an active scope
  entry, and it must not write those details into this repository.

## Code style

- Python: target 3.12+, follow PEP 8, add type hints. Manage
  dependencies with uv (`uv add <pkg>`); commit `pyproject.toml`
  and `uv.lock`, not `requirements.txt`.
- Prefer the standard library over new dependencies.

## Reviews

When reviewing, prioritize: leaked secrets or target data, unsafe
PoC behavior, injection and deserialization flaws, unpinned actions,
and changes that reduce existing security checks.
