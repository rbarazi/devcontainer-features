# Setup Instructions

Follow these steps to publish your Dev Container Feature to GitHub Container Registry.

## 1. Create GitHub Repository

1. Go to https://github.com/new
2. Create a new repository (e.g., `devcontainer-features`)
3. Make it public (required for GHCR publishing)
4. Don't initialize with README (we already have one)

## 2. Push Code to Repository

```bash
# Navigate to the extracted feature directory
cd /tmp/ai-npm-packages-feature

# Initialize git repository
git init
git add .
git commit -m "Initial commit: AI NPM Packages feature"

# Add your GitHub repository as remote
git remote add origin https://github.com/rbarazi/devcontainer-features.git

# Push to main branch
git branch -M main
git push -u origin main
```

## 3. Create First Release

```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

This will trigger the GitHub Actions workflow to:
- Build and publish the feature to GHCR
- Create a GitHub release

## 4. Use the Feature in Other Projects

Once published, reference it in your `devcontainer.json`:

```json
{
  "name": "My Project",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/rbarazi/devcontainer-features/ai-npm-packages:1": {
      "packages": "@anthropic-ai/claude-code"
    }
  }
}
```

## 5. Update Existing Agentify Project

To use the published feature instead of the local one:

In `agentify/.devcontainer/devcontainer.json`, change:

```json
"features": {
  "ghcr.io/devcontainers/features/node:1": {},
  "./features/ai-npm-packages": {}
}
```

To:

```json
"features": {
  "ghcr.io/devcontainers/features/node:1": {},
  "ghcr.io/rbarazi/devcontainer-features/ai-npm-packages:1": {}
}
```

Then you can remove the local feature directory:

```bash
rm -rf .devcontainer/features/ai-npm-packages
```

## Version Updates

When you make changes to the feature:

1. Update the version in `src/devcontainer-feature.json`
2. Commit your changes
3. Create a new tag: `git tag v1.1.0`
4. Push the tag: `git push origin v1.1.0`
5. GitHub Actions will automatically publish the new version

## Feature Naming Convention

The feature will be available at:
```
ghcr.io/rbarazi/devcontainer-features/ai-npm-packages:VERSION
```

- `rbarazi`: Your GitHub username
- `devcontainer-features`: Your repository name
- `ai-npm-packages`: The feature ID from `devcontainer-feature.json`
- `VERSION`: Major version number (1, 2, etc.) or full semver (1.0.0)

## Testing Before Publishing

To test locally before publishing, use a relative path in `devcontainer.json`:

```json
{
  "features": {
    "../path/to/feature/src": {}
  }
}
```

## Troubleshooting

### Action fails with permission error
- Ensure the repository is public
- Check that Actions have write permissions: Settings → Actions → General → Workflow permissions → Read and write permissions

### Feature not found after publishing
- Wait a few minutes for GHCR to index the package
- Verify the tag was pushed: `git ls-remote --tags origin`
- Check the Actions tab for workflow status

### Feature installs but packages not available
- Ensure Node.js feature is listed before this feature
- Check container logs: `docker logs <container-id>`
- Verify PATH includes npm global bin: `echo $PATH`
