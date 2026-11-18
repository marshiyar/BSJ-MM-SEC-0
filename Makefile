# Container targets for BSJ-MM-SEC-0. See SANDBOXING.md.
#
#   make devcontainer-build          build the image
#   make sandbox WORK=<dir>          locked-down shell with only <dir> mounted
#   make sandbox WORK=<dir> CMD=...  run one command in the sandbox instead
#   make sandbox-check WORK=<dir>    prove the restrictions are in place
#   make devcontainer-lock           regenerate .devcontainer/tools.lock
#
# ENGINE can be docker or podman.

ENGINE   ?= docker
IMAGE    ?= bsj-mm-sec-0-dev
CMD      ?= bash
# Run as your own uid/gid so files written to WORK belong to you. Never as
# root: if make itself runs as root, fall back to the image's user (1000).
HOST_UID := $(shell id -u)
SB_UID   := $(if $(filter 0,$(HOST_UID)),1000,$(HOST_UID))
SB_GID   := $(if $(filter 0,$(HOST_UID)),1000,$(shell id -g))
# Resource limits. Raise them on the command line if a job needs more.
SB_MEM   ?= 2g
SB_CPUS  ?= 2
SB_PIDS  ?= 256

# Pass -t only when stdin is a terminal, so CMD=... also works in scripts.
TTY_FLAG := $(shell [ -t 0 ] && echo -t)

WORK_ABS = $(abspath $(WORK))

# Every restriction lives here, so `sandbox` and `sandbox-check` cannot drift.
SANDBOX_FLAGS = \
	--rm -i $(TTY_FLAG) \
	--network none \
	--read-only \
	--cap-drop ALL \
	--security-opt no-new-privileges \
	--user $(SB_UID):$(SB_GID) \
	--env HOME=/home/researcher \
	--memory $(SB_MEM) --cpus $(SB_CPUS) --pids-limit $(SB_PIDS) \
	--tmpfs /tmp:rw,noexec,nosuid,nodev,size=256m \
	--tmpfs /home/researcher:rw,nosuid,nodev,size=256m,uid=$(SB_UID),gid=$(SB_GID) \
	--mount type=bind,source=$(WORK_ABS),target=/work \
	--workdir /work

.PHONY: devcontainer-build devcontainer-lock sandbox sandbox-check check-work

devcontainer-build:
	$(ENGINE) build -t $(IMAGE) -f .devcontainer/Dockerfile .devcontainer

devcontainer-lock:
	uv pip compile .devcontainer/tools.in --universal --python-version 3.12 \
		--generate-hashes --no-header --upgrade -o .devcontainer/tools.lock

# Refuse to start unless WORK names one existing directory that is not
# this repository, a git checkout, the home directory or the filesystem root.
# Code in the sandbox can write to WORK, and a writable .git/hooks would let
# it run on the host the next time someone uses git there.
check-work:
	@test -n "$(WORK)" || { echo "Set WORK to the one directory to mount, e.g. make sandbox WORK=../scratch/job1" >&2; exit 1; }
	@test -d "$(WORK_ABS)" || { echo "WORK=$(WORK) is not a directory" >&2; exit 1; }
	@case "$(WORK_ABS)" in /|"$(abspath $(HOME))"|"$(CURDIR)") echo "Refusing to mount $(WORK_ABS): pick a dedicated work directory" >&2; exit 1;; esac
	@! git -C "$(WORK_ABS)" rev-parse --git-dir >/dev/null 2>&1 || { echo "Refusing to mount $(WORK_ABS): it is inside a git checkout" >&2; exit 1; }

sandbox: check-work devcontainer-build
	$(ENGINE) run $(SANDBOX_FLAGS) $(IMAGE) $(CMD)

# Runs inside the sandbox and fails if any restriction is missing.
sandbox-check: check-work devcontainer-build
	$(ENGINE) run $(SANDBOX_FLAGS) $(IMAGE) sh -c '\
	  fail=0; \
	  ok()  { echo "ok    $$1"; }; \
	  bad() { echo "FAIL  $$1"; fail=1; }; \
	  [ "$$(id -u)" != 0 ] && ok "runs as uid $$(id -u)" || bad "runs as root"; \
	  grep -q "^CapEff:[[:space:]]*0*$$" /proc/self/status && ok "no capabilities" || bad "has capabilities"; \
	  grep -q "^NoNewPrivs:[[:space:]]*1$$" /proc/self/status && ok "no-new-privileges set" || bad "no-new-privileges missing"; \
	  touch /usr/sandbox-probe 2>/dev/null && bad "root filesystem is writable" || ok "root filesystem is read-only"; \
	  [ "$$(ls /sys/class/net)" = lo ] && ok "only loopback network" || bad "network interfaces: $$(ls /sys/class/net | tr "\n" " ")"; \
	  python -c "import socket; socket.create_connection((\"1.1.1.1\", 443), timeout=3)" 2>/dev/null && bad "outbound connection succeeded" || ok "outbound connection blocked"; \
	  touch /work/.sandbox-probe && rm -f /work/.sandbox-probe && ok "/work is writable" || bad "/work is not writable"; \
	  exit $$fail'
