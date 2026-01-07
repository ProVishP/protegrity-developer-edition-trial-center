# Protegrity Developer Edition Trial Center

An interactive Streamlit application demonstrating privacy-preserving GenAI workflows using [Protegrity Developer Edition v1.1.0](https://github.com/Protegrity-Developer-Edition/protegrity-developer-edition/tree/pre-release-1.1.0). This trial center showcases how to integrate data discovery, semantic guardrails, and data protection capabilities into AI/ML pipelines.

<!-- ![Trial Center UI](assets/trial_center_ui.png) -->

## 🎯 Overview

This Trial Center provides a hands-on environment to explore Protegrity's privacy and security capabilities for GenAI applications:

- **Data Discovery**: Automatically identify and classify sensitive data patterns
- **Semantic Guardrail**: Validate prompts for policy compliance and security risks using domain-specific processors (customer-support, financial, healthcare)
- **Protection & Unprotection**: Apply reversible encryption to sensitive data
- **Redaction**: Irreversibly mask sensitive information
- **Interactive UI**: User-friendly Streamlit interface with domain selection and pipeline mode configuration

## 🔧 Prerequisites

### 1. Protegrity Developer Edition (Required)

This Trial Center requires **Protegrity Developer Edition** services to be running. Install and start them first:

```bash
# Clone Protegrity Developer Edition
git clone https://github.com/Protegrity-Developer-Edition/protegrity-developer-edition.git
cd protegrity-developer-edition

# Switch to pre-release-1.1.0 branch
git checkout pre-release-1.1.0

# Start the services
docker compose up -d

# Wait 1-2 minutes for services to initialize
```

The following services must be accessible:
- **Semantic Guardrail**: `http://localhost:8581` - Validates prompts for security and policy compliance
- **Classification Service** (Data Discovery): `http://localhost:8580` - Identifies and classifies sensitive data

You can verify services are running:
```bash
# Check Semantic Guardrail (v1.1)
curl http://localhost:8581/pty/semantic-guardrail/v1.1/health

# Check Classification Service (v1.1)
curl http://localhost:8580/pty/data-discovery/v1.1/classify

# Or check Docker containers
docker ps | grep -E "semantic_guardrail|classification_service"
```

### 2. System Requirements

- **Docker Desktop** or Docker Engine
- **Python 3.12.11+** (updated for v1.1.0 compatibility)
- **macOS, Linux, or Windows** with WSL2

### 3. Protegrity Account (Optional)

For **reversible protection** features, you need:
- Protegrity Developer Edition account credentials
- Set as environment variables (see Configuration section)

**Note**: Discovery, Guardrail, and Redaction work without credentials.

## 🚀 Quick Start

### Option 1: Automated Launch (Recommended)

```bash
# Clone this repository
git clone https://github.com/YourUsername/protegrity-developer-edition-trial-center.git
cd protegrity-developer-edition-trial-center

# Run the launcher (handles everything automatically)
./launch_trial_center.sh
```

The launcher will:
✅ Validate Docker and Protegrity services
✅ Create and activate Python virtual environment
✅ Check and install **ALL** missing dependencies (including protegrity-developer-python)
✅ Verify all required packages are installed
✅ Check service health
✅ Launch Streamlit UI

**No manual package installation needed!** The launcher handles everything automatically.

### Option 2: Manual Setup

```bash
# 1. Create virtual environment
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# 2. Install ALL dependencies (including protegrity-developer-python)
pip install -r requirements.txt

# 3. Verify installation
python -c "import protegrity_developer_python, streamlit, requests, pandas; print('✅ All packages installed')"

# 4. Launch Streamlit
streamlit run app.py
```

**Note**: If you skip the virtual environment setup and install directly, ensure you have all packages from `requirements.txt` installed globally.

## ⚙️ Configuration

### Environment Variables

#### Required for Protection/Unprotection (Optional)

To enable **Protection** and **Unprotection** features:

```bash
export DEV_EDITION_EMAIL="your-email@example.com"
export DEV_EDITION_PASSWORD="your-password"
export DEV_EDITION_API_KEY="your-api-key"
```

#### Service Port Configuration (Optional)

Override default service ports if needed:

```bash
# Semantic Guardrail (default: 8581)
export SEMANTIC_GUARDRAIL_PORT="8581"

# Classification Service (default: 8580)
export CLASSIFICATION_SERVICE_PORT="8580"
```

These are rarely needed unless you've customized the Protegrity Developer Edition Docker setup.

**Without credentials:**
- ✅ Data Discovery works
- ✅ Semantic Guardrail works
- ✅ Redaction works
- ❌ Protection/Unprotection will show errors

## 📖 Features

### 1. **Domain-Specific Semantic Guardrails**
Validate prompts against security policies using specialized domain processors:
- **Customer Support**: Evaluates customer service interaction risks
- **Financial**: Assesses banking and financial context risks
- **Healthcare**: Analyzes medical and health-related scenarios
- Prompt injection detection
- Jailbreak attempt detection
- Sensitive data exposure prevention
- Context-aware policy validation

### 2. **Discovery Only**
Analyze text to identify sensitive data types (SSN, credit cards, emails, etc.) without modification.

### 3. **Find & Protect**
Discover sensitive data and apply reversible encryption (requires credentials).

### 4. **Find & Unprotect**
Decrypt previously protected data back to original form (requires credentials).

### 5. **Find & Redact**
Permanently mask sensitive data with `***REDACTED***` (no credentials needed).

### 6. **Pipeline Modes**
Choose execution path from sidebar:
- **Full Pipeline**: All steps (guardrail, discovery, protection, redaction)
- **Semantic Guardrail**: Risk evaluation only
- **Discover Sensitive Data**: Entity identification only
- **Find, Protect & Unprotect**: Reversible tokenization workflow
- **Find & Redact**: Permanent masking workflow

### 7. **Domain-Specific Sample Prompts**
Quick-load examples demonstrating various scenarios for each domain:
- Customer Support: Password resets, admin directory requests, data exports, off-topic chat
- Financial: Balance reviews, password retrieval attempts, executive data dumps, IT support
- Healthcare: Appointment scheduling, unauthorized chart access, employer disclosure, lifestyle advice

## 📁 Project Structure

```
protegrity-developer-edition-trial-center/
├── README.md                      # This file
├── ARCHITECTURE.md                # Technical architecture docs
├── requirements.txt               # Python dependencies
├── .gitignore                     # Git ignore patterns
│
├── app.py                         # Main Streamlit application
├── trial_center_pipeline.py       # Core pipeline logic
├── run_trial_center.py            # CLI runner
├── launch_trial_center.sh         # Automated launcher script
├── pyrightconfig.json             # Python type checking config
│
├── assets/                        # UI images and resources
│   └── protegrity_logo.svg
│
├── samples/                       # Legacy sample prompts (now embedded in UI)
│   ├── input_test.txt
│   ├── sample_approved.txt
│   ├── sample_data_leakage.txt
│   ├── sample_malicious.txt
│   └── sample_offtopic.txt
│
└── tests/                         # Unit and integration tests
    ├── test_trial_center_forge.py      # Tests for GuardianPromptForge
    └── test_trial_center_sanitizer.py  # Tests for PromptSanitizer
```

## 🔧 Troubleshooting

### Package Installation Issues

If you encounter `ModuleNotFoundError` for any package (e.g., `protegrity_developer_python`):

**Best Solution - Use the launcher script:**
```bash
# The launcher automatically detects missing packages and installs them
./launch_trial_center.sh
```
The launcher will show you exactly which packages are missing and install them automatically.

**Manual troubleshooting:**
```bash
# Activate virtual environment
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Force reinstall all packages
pip install --force-reinstall -r requirements.txt

# Verify installation
python -c "import protegrity_developer_python, streamlit, requests, pandas; print('✅ Success')"
```

### Common Issues

**1. Docker Services Not Running**
```bash
# Check if Docker is running
docker ps

# Verify Protegrity services are running
docker ps | grep -E "semantic_guardrail|classification_service"

# Expected output should show:
# - semantic_guardrail container on port 8581
# - classification_service container on port 8580

# If not running, start Protegrity Developer Edition services
cd path/to/protegrity-developer-edition
docker-compose up -d

# Wait for services to initialize (1-2 minutes)
sleep 120

# Test services are responding (v1.1 endpoints)
curl http://localhost:8581/pty/semantic-guardrail/v1.1/health  # Should return health status
curl http://localhost:8580/pty/data-discovery/v1.1/classify  # Should return 415 (needs POST with data)
```

**Note:** The Trial Center UI includes a "Service Status" panel that shows real-time health of both services.

**2. Port Already in Use**
```bash
# If port 8502 is busy, Streamlit will use the next available port
# Check the terminal output for the actual URL
```

**3. Protection Operations Failing**
- Ensure environment variables are set: `DEV_EDITION_EMAIL`, `DEV_EDITION_PASSWORD`, `DEV_EDITION_API_KEY`
- Get credentials at [Get Developer Edition API Credentials](https://www.protegrity.com/developers/get-api-credentials)
- Note: Discovery and Redaction work without credentials

**4. Virtual Environment Issues**
```bash
# Remove and recreate virtual environment
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## 🔗 Links

- **Protegrity Developer Edition**: [GitHub Repository](https://github.com/Protegrity-Developer-Edition/protegrity-developer-edition)
- **Get API Credentials**: [Developer Edition Credentials](https://www.protegrity.com/developers/get-api-credentials)
- **Documentation**: [API Docs](https://developer-edition.protegrity.io/docs)

## 🧪 Testing

```bash
# Run tests
pytest tests/

# Run with coverage
pytest --cov=. tests/
```

## 🤝 Contributing

This is a showcase project demonstrating Protegrity Developer Edition integration. Feel free to:
- Fork and enhance
- Submit issues
- Share improvements
- Use as a learning resource

## 📝 License

MIT License - See LICENSE file

## 🙏 Acknowledgments

Built using [Protegrity Developer Edition](https://github.com/Protegrity-Developer-Edition/protegrity-developer-edition) - a free, developer-friendly platform for exploring privacy-preserving technologies in AI/ML workflows.

Special thanks to the Protegrity team for providing powerful data protection capabilities through their Developer Edition.

## 📧 Support

For issues related to:
- **This Trial Center**: Open an issue in this repository
- **Protegrity Developer Edition**: Visit the [official repo](https://github.com/Protegrity-Developer-Edition/protegrity-developer-edition)

---

**Note**: This is an independent showcase project that uses Protegrity Developer Edition services. It is not officially maintained by Protegrity.
