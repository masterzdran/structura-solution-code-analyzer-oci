# 🔍 DevOps Analysis Pipeline

This project provides a secure, modular, and extensible pipeline for analyzing code quality, security, and technical debt across multiple stacks — including **React/TypeScript**, **Python**, and **.NET** — using Docker and GitHub Actions.

It includes:

- A hardened **Docker image** with all analysis tools pre-installed
- Unified **GitHub Actions workflows** for CI integration and image publishing
- Two configuration files:
  - `.project_type.yml` — defines the stack type
  - `.analisys-tools.yaml` — toggles individual tools
- A workflow to **build and publish the Docker image** to Docker Hub and GitHub Artifacts

---

## 📦 Project Structure

```text
.
├── Dockerfile
├── analyze.sh
├── build-image.sh
├── .analisys-tools.yaml         # Default tool toggles
├── .project_type.yml            # Stack type
├── code-analyzer-github-actions-example.yaml
├── README.md
├── .devcontainer/
│   ├── devcontainer.json
│   └── Dockerfile
└── .github/
    └── workflows/
        └── code-analyzer-oci.yaml    # Builds and publishes Docker image
```

# 🐳 Docker Image

The [Dockerfile](Dockerfile) installs and configures the following tools:

- **SAST**: Semgrep, SonarScanner, Bandit, ESLint, Pylint, dotnet-format, CodeQL
- **SCA**: Trivy, Snyk, OWASP Dependency-Check
- **Secrets Detection**: Gitleaks
- **Coverage**: Jest, Pytest, dotnet test + Coverlet
- **Metrics**: Cloc

The image is built and published via the [code-analyzer-oci.yaml](.github/workflows/code-analyzer-oci.yaml) workflow.

# 🚀 Docker Image Publishing Workflow

Located at [.github/workflows/code-analyzer-oci.yaml](.github/workflows/code-analyzer-oci.yaml), this workflow:

- Builds the Docker image from the latest commit on main
- Pushes it to Docker Hub
- Uploads a `.tar` archive of the image to GitHub Actions artifacts

## Required Secrets

| Secret Name         | Description                        |
|---------------------|------------------------------------|
| DOCKERHUB_USERNAME  | Your Docker Hub username           |
| DOCKERHUB_TOKEN     | A personal access token for Docker |

# ⚙️ GitHub Actions Analysis Workflow

See [code-analyzer-github-actions-example.yaml](code-analyzer-github-actions-example.yaml) for a sample workflow:

- Triggers on every pull request to main
- Mounts the repo into the container
- Executes `analyze.sh` inside the container
- Uploads all generated reports as a downloadable artifact

## Required Secrets

| Secret Name        | Description                        |
|--------------------|------------------------------------|
| SNYK_TOKEN         | API token for Snyk CLI             |
| SONAR_TOKEN        | Authentication token for SonarCloud |
| SONAR_PROJECT_KEY  | Unique project key in SonarCloud   |
| SONAR_HOST_URL     | Optional (default: https://sonarcloud.io) |

# 📘 Configuration Files

## .project_type.yml

Defines the stack type for targeted analysis.

```yaml
PROJECT_TYPE: REACT
```

Accepted values:
- REACT
- PYTHON
- DOTNET
- AUTOMATIC (default if missing or invalid)

## .analisys-tools.yaml

Feature toggle for each tool. Set to yes or no.

```yaml
SEMGRP: yes
TRIVY: yes
SONAR: yes
SNYK: yes
GITLEAKS: yes
CODEQL: yes
DEPENDENCY_CHECK: yes
ESLINT: yes
PYLINT: yes
BANDIT: yes
JEST: yes
PYTEST: yes
DOTNET_FORMAT: yes
DOTNET_TEST: yes
CLOC: yes
```
Only tools marked yes will be executed. If this file is missing in the analyzed project, the default version from the Docker image will be used.

# 📁 Report Output

All tools write their results to **/workspace/reports**, which maps to the **reports/** folder in your repo. These are uploaded as GitHub Actions artifacts.

Example contents:
```text
reports/
├── semgrep.json
├── snyk-react.json
├── bandit.json
├── eslint.json
├── python-coverage.json
├── dotnet-coverage.json
├── gitleaks.json
├── codeql.sarif
├── dependency-check-report.json
├── cloc.json
```

# ✅ Best Practices Followed

- Non-root execution inside Docker
- Secure shell scripting (`set -euo pipefail`)
- OWASP-aligned scanning tools
- Modular, toggleable architecture
- Clean separation of concerns
- Secrets injected via GitHub Actions only

# 📞 Support & Contributions

Feel free to fork, extend, or integrate this pipeline into your own CI/CD workflows. For questions or improvements, open an issue or start a discussion.

