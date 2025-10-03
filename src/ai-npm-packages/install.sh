#!/bin/sh
set -e

echo "Installing AI NPM packages..."

# Ensure npm is available (check both system and NVM locations)
NPM_CMD=""
if command -v npm >/dev/null 2>&1; then
    NPM_CMD="npm"
elif [ -d "/usr/local/share/nvm" ]; then
    # Find the latest Node.js version in NVM
    LATEST_NODE=$(ls -1 /usr/local/share/nvm/versions/node/ | sort -V | tail -1)
    if [ -f "/usr/local/share/nvm/versions/node/${LATEST_NODE}/bin/npm" ]; then
        NPM_CMD="/usr/local/share/nvm/versions/node/${LATEST_NODE}/bin/npm"
    fi
fi

if [ -z "$NPM_CMD" ]; then
    echo "Error: npm is not installed. Please ensure Node.js feature is installed first."
    exit 1
fi

echo "Using npm at: $NPM_CMD"

# -------- Resolve user and home --------
# Prefer REMOTE_USER if present (devcontainers), fall back sensibly
REMOTE_USER="${REMOTE_USER:-${_REMOTE_USER:-${USERNAME:-vscode}}}"

# Verify user exists; if not, fall back to root
if ! id -u "${REMOTE_USER}" >/dev/null 2>&1; then
    echo "Warning: user '${REMOTE_USER}' not found. Falling back to 'root'."
    REMOTE_USER="root"
fi

# Resolve HOME for user
USER_HOME="$(getent passwd "${REMOTE_USER}" 2>/dev/null | cut -d: -f6)"
[ -n "${USER_HOME}" ] || USER_HOME="/root"

# -------- Configure npm prefix (check if NVM is managing Node.js) --------
# Check if we're in an NVM-managed environment
if command -v nvm >/dev/null 2>&1 || [ -d "/usr/local/share/nvm" ]; then
  echo "NVM detected - using existing npm configuration"
  # NVM already manages npm prefix, no need to override
else
  NPM_PREFIX="${NPM_PREFIX:-${USER_HOME}/.npm-global}"
  
  echo "Configuring npm prefix at ${NPM_PREFIX} for ${REMOTE_USER}..."
  mkdir -p "${NPM_PREFIX}/bin"
  # Chown if possible (root builds); ignore if not needed
  if command -v id >/dev/null 2>&1; then
    USER_GROUP="$(id -gn "${REMOTE_USER}" 2>/dev/null || echo "${REMOTE_USER}")"
    chown -R "${REMOTE_USER}:${USER_GROUP}" "${NPM_PREFIX}" 2>/dev/null || true
  fi

  # Ensure PATH picks up the user-local npm bin
  PROFILE_SNIPPET='export PATH="$HOME/.npm-global/bin:$PATH"'

  ensure_path_snippet() {
    rcfile="$1"
    if [ -f "$rcfile" ]; then
      if ! grep -q '\.npm-global/bin' "$rcfile" 2>/dev/null; then
        echo "$PROFILE_SNIPPET" >> "$rcfile"
      fi
    else
      # create the rcfile and add the snippet
      echo "$PROFILE_SNIPPET" >> "$rcfile"
    fi
  }

  ensure_path_snippet "${USER_HOME}/.bashrc"
  ensure_path_snippet "${USER_HOME}/.zshrc"

  # System-wide profile snippet
  mkdir -p /etc/profile.d
  echo "$PROFILE_SNIPPET" > /etc/profile.d/10-npm-global-path.sh
  chmod 0644 /etc/profile.d/10-npm-global-path.sh
  chown root:root /etc/profile.d/10-npm-global-path.sh 2>/dev/null || true
fi

# -------- Run-as helper (works with/without sudo) --------
as_user() {
  # Usage: as_user <user> <env HOME=...> <command...>
  _user="$1"; shift
  # Prefer sudo, else runuser, else su
  if command -v sudo >/dev/null 2>&1; then
    # shellcheck disable=SC2145
    sudo -H -u "$_user" "$@"
  elif command -v runuser >/dev/null 2>&1; then
    runuser -u "$_user" -- "$@"
  else
    # Fallback to su, ensuring arguments (and env overrides) survive quoting
    su - "$_user" -s /bin/sh -c 'exec "$@"' -- "$@"
  fi
}

# -------- Persist npm prefix in user's npm config --------
# Only set npm prefix if not using NVM
if ! (command -v nvm >/dev/null 2>&1 || [ -d "/usr/local/share/nvm" ]); then
  echo "Setting npm config prefix for ${REMOTE_USER}..."
  as_user "${REMOTE_USER}" env HOME="${USER_HOME}" npm config set prefix "${NPM_PREFIX}" || true
else
  echo "Skipping npm config prefix setting - using NVM-managed configuration"
fi

# -------- Optional global installs --------
# Get packages from feature option, fallback to environment variable, then default
AI_NPM_PACKAGES="${PACKAGES:-${AI_NPM_PACKAGES:-@anthropic-ai/claude-code @openai/codex}}"

maybe_install_pkg() {
  pkg="$1"
  echo "Installing ${pkg}..."
  # Set PATH to include the directory containing npm
  NPM_DIR=$(dirname "${NPM_CMD}")
  as_user "${REMOTE_USER}" env HOME="${USER_HOME}" PATH="${NPM_DIR}:$PATH" "${NPM_CMD}" install -g "${pkg}" || {
    echo "Warning: install failed for ${pkg}, continuing..."
    return 0
  }
}

if [ -n "${AI_NPM_PACKAGES}" ]; then
  echo "Installing requested AI_NPM_PACKAGES: ${AI_NPM_PACKAGES}"
  set -f  # disable globbing to prevent expansion of package names
  for p in ${AI_NPM_PACKAGES}; do
    maybe_install_pkg "$p"
  done
  set +f  # re-enable globbing
else
  echo "No AI_NPM_PACKAGES specified; skipping global installs."
  # If you really want these, set AI_NPM_PACKAGES in devcontainer.json / compose:
  # AI_NPM_PACKAGES="@anthropic-ai/claude-code"
fi

echo "AI NPM packages installation complete!"
