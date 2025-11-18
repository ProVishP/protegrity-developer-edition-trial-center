# Protegrity Developer Edition Trial Center

An interactive Streamlit application demonstrating privacy-preserving GenAI workflows using [Protegrity Developer Edition](https://github.com/Protegrity-Developer-Edition/protegrity-developer-edition). This trial center showcases how to integrate data discovery, semantic guardrails, and data protection capabilities into AI/ML pipelines.

![Trial Center UI](assets/trial_center_ui.png)

## 🎯 Overview

This Trial Center provides a hands-on environment to explore Protegrity's privacy and security capabilities for GenAI applications:

- **Data Discovery**: Automatically identify and classify sensitive data patterns
- **Semantic Guardrail**: Validate prompts for policy compliance and security risks
- **Protection & Unprotection**: Apply reversible encryption to sensitive data
- **Redaction**: Irreversibly mask sensitive information
- **Interactive UI**: User-friendly Streamlit interface for all operations

## 🔧 Prerequisites

### 1. Protegrity Developer Edition (Required)

This Trial Center requires **Protegrity Developer Edition** services to be running. Install and start them first:

```bash
# Clone Protegrity Developer Edition
git clone https://github.com/Protegrity-Developer-Edition/protegrity-developer-edition.git
cd protegrity-developer-edition

# Start the services
docker-compose up -d

# Wait 1-2 minutes for services to initialize
```

The following services must be accessible:
- **Semantic Guardrail**: `http://localhost:8581`
- **Data Discovery**: `http://localhost:8580`

### 2. System Requirements

- **Docker Desktop** or Docker Engine
- **Python 3.11+**
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
✅ Install dependencies
✅ Check service health
✅ Launch Streamlit UI

### Option 2: Manual Setup

```bash
# 1. Create virtual environment
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Launch Streamlit
streamlit run app.py
```

## ⚙️ Configuration

### Environment Variables (Optional)

To enable **Protection** and **Unprotection** features:

```bash
export DEV_EDITION_EMAIL="your-email@example.com"
export DEV_EDITION_PASSWORD="your-password"
export DEV_EDITION_API_KEY="your-api-key"
```

**Without credentials:**
- ✅ Data Discovery works
- ✅ Semantic Guardrail works
- ✅ Redaction works
- ❌ Protection/Unprotection will show errors

## 📖 Features

### 1. **Discovery Only**
Analyze text to identify sensitive data types (SSN, credit cards, emails, etc.) without modification.

### 2. **Find & Protect**
Discover sensitive data and apply reversible encryption (requires credentials).

### 3. **Find & Unprotect**
Decrypt previously protected data back to original form (requires credentials).

### 4. **Find & Redact**
Permanently mask sensitive data with `***REDACTED***` (no credentials needed).

### 5. **Semantic Guardrail**
Validate prompts against security policies:
- Prompt injection detection
- Jailbreak attempt detection
- Sensitive data exposure prevention
- Custom policy validation

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
│   ├── trial_center_ui.png
│   ├── protegrity_logo.png
│   └── workflow_diagram.png
│
├── samples/                       # Sample prompts for testing
│   ├── input_test.txt
│   ├── prompt_hr_leak.txt
│   ├── prompt_medical.txt
│   ├── prompt_financial.txt
│   └── prompt_jailbreak.txt
│
└── tests/                         # Unit and integration tests
    ├── test_pipeline.py
    └── test_integration.py
```

## 🔗 Links

- **Protegrity Developer Edition**: [GitHub Repository](https://github.com/Protegrity-Developer-Edition/protegrity-developer-edition)
- **Protegrity API Playground**: [Try APIs](https://developer-edition.protegrity.io/)
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
