# Dev container image for BSJ-MM-SEC-0.
#
# The same image is used two ways:
#   - as the VS Code / devcontainer CLI dev container (tier 1), and
#   - locked down by `make sandbox` (tier 2) for code we did not write.
# See SANDBOXING.md.
#
# Every image is pinned by digest. To update, resolve the new digest with
#   docker buildx imagetools inspect <image>:<tag>
# and change both the tag comment and the digest. Dependabot also opens
# PRs for it (see .github/dependabot.yml).
#
# Python tools (uv, pre-commit and their dependencies) are pinned with
# hashes in tools.lock, generated from tools.in by `make devcontainer-lock`.

# Python 3.12 on Debian 13 (trixie), slim variant
FROM python:3.15-slim-trixie@sha256:65a65fc7b30b06cb6df4930fd4650697cb23f4c2698ab81fc87e4b031bc36928

ARG USERNAME=researcher
ARG USER_UID=1000
ARG USER_GID=1000

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_PYTHON_DOWNLOADS=never \
    UV_LINK_MODE=copy \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

# git for the dev container, make so `make` targets work inside it.
# Debian packages come from the pinned base release and are not pinned
# individually.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git make \
    && rm -rf /var/lib/apt/lists/*

# Wheels only, every file checked against its hash in tools.lock.
# Installed as root into the system site-packages, so the non-root user
# cannot modify them.
COPY tools.lock /tmp/tools.lock
RUN pip install --require-hashes --only-binary=:all: --no-deps -r /tmp/tools.lock \
    && rm /tmp/tools.lock \
    && uv --version \
    && pre-commit --version

# Non-root user. No sudo is installed, on purpose.
RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}" \
    && mkdir -p /work \
    && chown "${USER_UID}:${USER_GID}" /work

USER ${USERNAME}
WORKDIR /work
CMD ["bash"]
