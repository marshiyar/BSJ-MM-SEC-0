# Sandboxing

Where code runs in this project, and when to move it somewhere more
isolated. This applies to everyone, human or AI agent.

## Isolation tiers

| Tier | Where | Use it for | Isolation |
| ---- | ----- | ---------- | --------- |
| 0 | Your main machine | Editing files, reading code, git, opening PRs | None. Nothing from this research runs here. |
| 1 | Dev container (`.devcontainer/`) | Running and testing code the maintainers wrote | Separate filesystem and non-root user. Network on. The repo is mounted read-write. |
| 2 | Locked-down container (`make sandbox`) | Running code written by others: third-party PoCs, tools, scripts, anything an AI agent wrote or will run | No network, read-only root filesystem, non-root user, all capabilities dropped, no privilege escalation, CPU, memory and process limits. Only one work directory you name is mounted. |
| 3 | Virtual machine | Anything that needs a network, root, kernel features, a GUI, or that might try to escape a container | Separate kernel. Snapshot before, revert after. |
| 4 | Dedicated lab machine | Hardware and firmware work, long-running or unknown samples, anything touching real devices or lab networks | Separate physical machine on an isolated network, with no access to personal accounts. |

Containers (tiers 1 and 2) share the host kernel. They reduce the blast
radius of buggy or nosy code. They are not a strong boundary against code
that is actively trying to escape. Use tier 3 or 4 for that.

## When to move up a tier

Start at the lowest tier that fits, and move up if any of these is true.

Move from tier 1 to tier 2 if:

- you did not write the code, or have not read all of it;
- an AI agent wrote it, or an AI agent will be running it;
- it came from an issue, a paste, a download, or another repo.

Move from tier 2 to tier 3 if:

- it needs network access, root, extra capabilities, or devices;
- it needs to modify the system, install packages at run time, or load
  kernel modules;
- it is a malware sample, an exploit, or anything described as
  "obfuscated", "packed" or "dropper";
- it failed in tier 2 in a way that suggests it was probing the sandbox.

Move from tier 3 to tier 4 if:

- it touches physical hardware, radios, or firmware on real devices;
- it must run unattended for long periods;
- a VM escape would put anything of value at risk.

When in doubt, go up a tier. Never move code down a tier because it was
inconvenient to run where it belongs.

## Using the containers

Requirements: Docker or Podman, and `make`.

### Tier 1: dev container

Open the repository in an editor that supports dev containers (for example
VS Code with the Dev Containers extension) and choose **Reopen in
Container**, or use the devcontainer CLI:

```bash
devcontainer up --workspace-folder .
```

The container runs as the non-root user `researcher`, with all
capabilities dropped and `no-new-privileges` set. It installs the
pre-commit hooks on first start.

### Tier 2: locked-down container

Put the code you want to run in its own directory outside this repository
and outside any git checkout, then:

```bash
mkdir -p ~/sandbox/job1
cp -r ~/Downloads/some-tool ~/sandbox/job1/

make sandbox WORK=~/sandbox/job1                        # interactive shell
make sandbox WORK=~/sandbox/job1 CMD="python tool.py"   # one command
make sandbox-check WORK=~/sandbox/job1                  # verify the restrictions
```

`make sandbox` refuses to start without `WORK`, and refuses to mount the
filesystem root, your home directory, this repository, or any git
checkout. Code in the sandbox can write to the work directory, and a
writable `.git/hooks` would let it run code on your machine the next time
you use git there.

Inside the sandbox:

- `/work` is the only directory shared with your machine;
- `/tmp` and the home directory are in-memory, wiped when the container
  exits, and `/tmp` does not allow executing files;
- there is no network, so install dependencies before you enter: put
  wheels in the work directory, or build a derived image.

Treat everything in the work directory as untrusted after a run. Review it
before you open or run anything from it on your main machine.

Limits default to 2 CPUs, 2 GB of memory and 256 processes. Override them
with `SB_CPUS`, `SB_MEM` and `SB_PIDS`. Use `ENGINE=podman` to use Podman.

### Updating the image

The base image is pinned by digest, and uv and pre-commit are pinned with
hashes in `.devcontainer/tools.lock`. Dependabot opens PRs for the base
image. To update the Python tools, edit `.devcontainer/tools.in` if needed
and run `make devcontainer-lock`.

## Setup checklist: tier 3 (virtual machine)

- [ ] Use a hypervisor that supports snapshots.
- [ ] Install a fresh OS from an official image and verify its checksum.
- [ ] Create a non-admin user for daily work in the VM.
- [ ] Turn off shared folders, shared clipboard, drag and drop, and USB
      passthrough. Move files in and out deliberately, one way at a time.
- [ ] Use NAT or host-only networking. Never bridge the VM onto your home
      or work network.
- [ ] Block the VM from reaching the host and your local network. Allow
      internet access only when a job needs it, and turn it off afterwards.
- [ ] Do not sign in to personal accounts, password managers, or cloud
      sync in the VM. Do not copy SSH keys or tokens into it.
- [ ] Install updates, then take a clean snapshot and name it with the
      date.
- [ ] Revert to the clean snapshot after each job that ran untrusted code.
- [ ] Encrypt the VM's disk, or keep it on an encrypted host disk.

## Setup checklist: tier 4 (lab machine)

- [ ] Use a machine that holds no personal or work data and is not used
      for anything else.
- [ ] Wipe it and install a fresh OS before research starts. Record how
      to rebuild it so it can be wiped again.
- [ ] Put it on its own network segment or VLAN, with no route to home or
      work networks. Use a separate router or firewall if possible.
- [ ] Give it only the internet access a job needs, and log its traffic.
- [ ] Use separate accounts and credentials that exist only for the lab.
      Never reuse personal passwords or keys.
- [ ] Turn off remote access services you do not use. If you need remote
      access, allow it only from a known management machine.
- [ ] Label devices under test, and keep a record of what is connected
      and why.
- [ ] Move data out through one reviewed path (for example a dedicated
      drive that is scanned before use), never by plugging lab media
      into personal machines.
- [ ] Before reusing any device or drive, wipe it.

## AI agents

Rules for AI agents are in [AGENTS.md](AGENTS.md#running-ai-agents). In
short: an agent that executes code runs in tier 2 or higher.

## What is authorized

Isolation is not authorization. Only test systems listed in the
maintainers' scope record. See [SCOPE.md](SCOPE.md).
