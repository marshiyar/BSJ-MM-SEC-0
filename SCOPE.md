# Scope

This file is a **template** for recording what the maintainers are
authorized to test.

**The real target list is not kept in this repository.** This repository
is public. Real scope records, with hostnames, IP addresses, device serial
numbers, account names, contacts and authorization documents, are kept in
a private location that only the maintainers can access. Never commit them
here, and never paste them into an issue, PR, commit message or AI agent
prompt that ends up in this repository.

Copy the template below into the private location, one entry per
engagement or target set.

## Rules

- No entry, no testing. If a system is not covered by a current entry, it
  is out of scope.
- An entry needs written permission from someone who has the right to
  give it. For systems you own, record that you own them.
- Stay inside the dates, techniques and limits the entry lists.
- If you find something outside scope, stop and record it. Do not
  continue testing it.
- Report findings in third-party software through that project's own
  disclosure process. See [SECURITY.md](SECURITY.md).

## Template

```markdown
### <Short name for the engagement>

- ID: <e.g. SCOPE-2026-001>
- Status: <draft | active | expired | closed>
- Maintainers: <who may test>
- Authorized by: <name and role of the person who gave permission,
  or "owned by the maintainers">
- Authorization record: <where the written permission is stored>
- Valid from: <YYYY-MM-DD>
- Valid until: <YYYY-MM-DD>

In scope:
- <system, device, application or firmware, with version>

Out of scope:
- <anything explicitly excluded, including shared or production systems>

Allowed:
- <techniques, e.g. static analysis, fuzzing on lab devices>

Not allowed:
- <e.g. denial of service, social engineering, testing on production>

Environment:
- <isolation tier from SANDBOXING.md, lab machine or network used>

Data handling:
- <what data may be collected, where it is stored, when it is deleted>

Contacts:
- <who to notify about findings or incidents, and how>

Disclosure:
- <vendor process, embargo, agreed timeline>

Notes:
- <anything else>
```
