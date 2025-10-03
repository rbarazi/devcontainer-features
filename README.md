# AI NPM Packages - Dev Container Feature

A Dev Container Feature that installs AI-related npm packages globally in your development container. By default, it installs `@anthropic-ai/claude-code` and `@openai/codex`, but you can customize which packages to install.

## Features

- Automatically installs specified npm packages globally
- Handles both standard npm and NVM-managed Node.js installations
- Configures npm prefix for non-root users
- Adds npm global bin directory to PATH
- Customizable package list via options

## Usage

### Basic Usage

Add this feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/rbarazi/devcontainer-features/ai-npm-packages:1": {}
  }
}
```

This will install the default packages: `@anthropic-ai/claude-code` and `@openai/codex`.

### Custom Package List

To install different or additional packages:

```json
{
  "features": {
    "ghcr.io/rbarazi/devcontainer-features/ai-npm-packages:1": {
      "packages": "@anthropic-ai/claude-code @some-other/package"
    }
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `packages` | string | `@anthropic-ai/claude-code @openai/codex` | Space-separated list of npm packages to install globally |

## Requirements

This feature depends on Node.js being installed. It will automatically install after the Node.js feature:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/rbarazi/devcontainer-features/ai-npm-packages:1": {}
  }
}
```

## How It Works

1. Detects whether npm is system-installed or managed by NVM
2. For non-NVM setups, configures a user-local npm prefix (`~/.npm-global`)
3. Adds the npm global bin directory to PATH in `.bashrc`, `.zshrc`, and system-wide profile
4. Installs specified packages globally as the container user (not root)
5. Handles permission and path configuration automatically

## Troubleshooting

### Packages not found after installation

If installed packages aren't available in your PATH, try:

1. Reload your shell: `source ~/.bashrc` or `source ~/.zshrc`
2. Check the installation: `npm list -g --depth=0`
3. Verify PATH includes npm global bin: `echo $PATH`

### Installation fails

- Ensure Node.js feature is installed and loads before this feature
- Check container logs for specific npm errors
- Verify package names are correct and available on npm registry

## Publishing This Feature

To publish this feature to GitHub Container Registry:

1. Create a new GitHub repository
2. Copy the contents of this directory to the repository
3. Set up the GitHub Actions workflow (see `.github/workflows/release.yml`)
4. Create a release tag (e.g., `v1.0.0`)
5. The feature will be automatically published to GHCR

## Development

### Testing Locally

To test this feature locally before publishing:

```json
{
  "features": {
    "./src": {}
  }
}
```

### File Structure

```
.
├── README.md
├── src/
│   ├── devcontainer-feature.json
│   └── install.sh
└── .github/
    └── workflows/
        └── release.yml
```

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
