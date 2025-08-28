#!/bin/bash
set -euo pipefail

mkdir -p /workspace/reports

# Load feature toggles
declare -A TOOLS
CONFIG_PATH="/workspace/.analisys-tools.yaml"
if [ -f "$CONFIG_PATH" ]; then
  echo "📄 Using analysis config from analyzed project"
elif [ -f /usr/local/etc/.analisys-tools.yaml ]; then
  echo "📄 Using default analysis config from image"
  CONFIG_PATH="/usr/local/etc/.analisys-tools.yaml"
else
  echo "❌ No .analisys-tools.yaml found. Aborting."
  exit 1
fi

while IFS=":" read -r key value; do
  key=$(echo "$key" | xargs | tr '[:lower:]' '[:upper:]')
  value=$(echo "$value" | xargs | tr '[:lower:]' '[:upper:]')
  TOOLS["$key"]="$value"
done < "$CONFIG_PATH"

is_enabled() {
  [[ "${TOOLS[$1]:-NO}" == "YES" ]]
}

# Detect project type
PROJECT_TYPE="AUTOMATIC"
if [ -f /workspace/.project_type.yml ]; then
  PROJECT_TYPE=$(grep -i 'PROJECT_TYPE:' /workspace/.project_type.yml | awk '{print toupper($2)}')
  [[ "$PROJECT_TYPE" != "REACT" && "$PROJECT_TYPE" != "PYTHON" && "$PROJECT_TYPE" != "DOTNET" ]] && PROJECT_TYPE="AUTOMATIC"
fi

if [ "$PROJECT_TYPE" == "AUTOMATIC" ]; then
  echo "🔍 Attempting automatic project type detection..."
  if find /workspace -name "*.csproj" | grep -q .; then
    PROJECT_TYPE="DOTNET"
  elif find /workspace -name "package.json" | xargs grep -q '"react'; then
    PROJECT_TYPE="REACT"
  elif find /workspace -name "*.py" | grep -q .; then
    PROJECT_TYPE="PYTHON"
  else
    echo "❌ Could not detect project type. Failing analysis."
    exit 1
  fi
fi

echo "✅ Detected project type: $PROJECT_TYPE"

# Stack-specific analysis
run_dotnet() {
  is_enabled DOTNET_FORMAT && dotnet format /workspace || echo "dotnet-format skipped or failed"
  is_enabled DOTNET_TEST && dotnet test /workspace /p:CollectCoverage=true /p:CoverletOutputFormat=json /p:CoverletOutput=/workspace/reports/dotnet-coverage.json || echo "dotnet test failed"
}

run_python() {
  is_enabled BANDIT && bandit -r /workspace -f json -o /workspace/reports/bandit.json || echo "Bandit failed"
  is_enabled PYLINT && pylint /workspace/**/*.py --output-format=json > /workspace/reports/pylint.json || echo "Pylint failed"
  is_enabled PYTEST && pytest --cov=. --cov-report=json:/workspace/reports/python-coverage.json || echo "Pytest failed"
}

run_react() {
  is_enabled ESLINT && eslint /workspace --format json -o /workspace/reports/eslint.json || echo "ESLint failed"
  is_enabled JEST && jest --coverage --coverageReporters=json-summary --coverageDirectory=/workspace/reports || echo "Jest failed"
}

# Common tools
run_semgrep() {
  is_enabled SEMGRP && semgrep scan --config auto --json > /workspace/reports/semgrep.json || echo "Semgrep failed"
}

run_trivy() {
  is_enabled TRIVY && trivy fs /workspace --format json --output /workspace/reports/trivy.json || echo "Trivy failed"
}

run_sonar() {
  if is_enabled SONAR && [ -n "${SONAR_TOKEN:-}" ] && [ -n "${SONAR_PROJECT_KEY:-}" ]; then
    sonar-scanner \
      -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
      -Dsonar.sources=/workspace \
      -Dsonar.host.url="${SONAR_HOST_URL:-https://sonarcloud.io}" \
      -Dsonar.login="$SONAR_TOKEN" || echo "SonarScanner failed"
  fi
}

run_snyk() {
  if is_enabled SNYK && [ -n "${SNYK_TOKEN:-}" ]; then
    snyk auth "$SNYK_TOKEN"
    case "$PROJECT_TYPE" in
      REACT) snyk test --file=/workspace/package.json --json > /workspace/reports/snyk-react.json || echo "Snyk React failed" ;;
      PYTHON) snyk test --file=/workspace/requirements.txt --json > /workspace/reports/snyk-python.json || echo "Snyk Python failed" ;;
      DOTNET) csproj=$(find /workspace -name "*.csproj" | head -n 1); snyk test --file="$csproj" --json > /workspace/reports/snyk-dotnet.json || echo "Snyk .NET failed" ;;
    esac
  fi
}

run_gitleaks() {
  is_enabled GITLEAKS && gitleaks detect --source=/workspace --report-path=/workspace/reports/gitleaks.json --no-banner || echo "Gitleaks failed"
}

run_codeql() {
  if is_enabled CODEQL; then
    mkdir -p /workspace/codeql-db
    codeql database create /workspace/codeql-db --language=$(echo "$PROJECT_TYPE" | tr '[:upper:]' '[:lower:]') --source-root=/workspace || echo "CodeQL DB creation failed"
    codeql database analyze /workspace/codeql-db codeql-suites/${PROJECT_TYPE,,}-code-scanning.qls --format=sarifv2 --output=/workspace/reports/codeql.sarif || echo "CodeQL analysis failed"
  fi
}

run_dependency_check() {
  is_enabled DEPENDENCY_CHECK && dependency-check.sh --project "Analysis" --scan /workspace --format "JSON" --out /workspace/reports || echo "Dependency-Check failed"
}

run_cloc() {
  is_enabled CLOC && cloc /workspace --json > /workspace/reports/cloc.json || echo "Cloc failed"
}

# Execute stack-specific
case "$PROJECT_TYPE" in
  DOTNET) run_dotnet ;;
  PYTHON) run_python ;;
  REACT) run_react ;;
esac

# Execute common tools
run_semgrep
run_trivy
run_sonar
run_snyk
run_gitleaks
run_codeql
run_dependency_check
run_cloc
