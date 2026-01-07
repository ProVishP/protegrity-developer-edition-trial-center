# Dev Edition Trial Center Architecture

## Overview

Dev Edition Trial Center wraps Protegrity Developer Edition services into a guided sandbox that shows how semantic guardrails, data discovery, protection, and redaction cooperate to prepare GenAI prompts. It consists of a reusable Python pipeline, a comprehensive launch script, and a Streamlit UI that presents the pipeline as an interactive trial experience with multiple execution modes.

## Component map

- **Launch Script (`launch_trial_center.sh`)** – Comprehensive bash launcher that validates prerequisites (Docker, Python environment, services), manages Docker Compose lifecycle, performs health checks, and launches the Streamlit UI. Provides clear feedback about missing credentials and configuration status.
- **Streamlit UI (`app.py`)** – Interactive web interface that collects prompts, displays guardrail scores, previews protected/redacted outputs, and exposes a Run log tab that streams pipeline diagnostics. Features:
  - **Sidebar configuration** – Centralized controls for semantic domain, pipeline mode, and sample prompts
  - **Domain-specific processors** – Three semantic guardrail domains:
    - customer-support: Customer service interaction risks
    - financial: Banking and financial context risks
    - healthcare: Medical and health-related scenario risks
  - **Domain-specific sample prompts** – 12 pre-loaded examples (4 per domain) demonstrating different guardrail outcomes including legitimate requests, data exfiltration attempts, privilege escalation, and off-topic diversions
  - **Execution modes** – Five pipeline configurations:
    - Full Pipeline: All steps with sequential numbering (Steps 1-5)
    - Semantic Guardrail: Guardrail scoring only
    - Discover Sensitive Data: Entity discovery only
    - Find, Protect & Unprotect: Discovery → Protection → Unprotection (Steps 1-3)
    - Find & Redact: Discovery → Redaction (Steps 1-2)
  - **Expandable result sections** – Each step renders in a professional expandable card with status indicators and copy-to-clipboard functionality
  - **Dynamic step numbering** – Each mode shows appropriate step numbers for its workflow
  - **Error handling** – Displays clear error messages when protection fails without showing sensitive data
  - **Professional UI styling** – Enhanced CSS with color-coded status indicators, gradient buttons, and copy-enabled code blocks
- **Pipeline core (`trial_center_pipeline.py`)** – Provides `SemanticGuardrailClient`, `PromptSanitizer`, and helper utilities that the UI and CLI reuse. Key features:
  - **Silent failure detection** – Identifies when protection doesn't modify text (indicating credential or authentication issues)
  - **No fallback logic** – Removed automatic fallback from protection to redaction; instead surfaces clear errors
  - **Structured results** – `SanitizationResult` includes `sanitize_error` field for tracking protection failures
- **CLI (`run_trial_center.py`)** – Batch-friendly entry point for processing files via the same pipeline and persisting reports to disk.
- **Developer Edition containers** – Docker Compose brings up Semantic Guardrail (port 8581) and Data Discovery/Classification services (port 8580). The pipeline communicates with these services via REST (guardrail) and the `protegrity_developer_python` SDK (discovery/protection/redaction).

## Data flow

```
User Input
   │
   ├─► Domain Selection (customer-support | financial | healthcare)
   ├─► Pipeline Mode Selection
   └─► Prompt (manual or sample)
   │
   ▼
Streamlit UI ──► Sidebar Configuration ──► Execution Path
   │                                              │
   │                                              ├─► Full Pipeline
   │                                              ├─► Semantic Guardrail Only
   │                                              ├─► Discover Only
   │                                              ├─► Find, Protect & Unprotect
   │                                              └─► Find & Redact
   │
   ▼
SemanticGuardrailClient ──► Semantic Guardrail service (REST + domain parameter)
   │                               │
   │                               └─► GuardrailResult (score/outcome/explanation)
   │
   ├─► Data Discovery via SDK ──► Discovery entities
   │
   ├─► PromptSanitizer (protect) ──► Protection attempt
   │         │                           │
   │         │                           ├─► Success: Protected tokens
   │         │                           └─► Failure: Error displayed (no data shown)
   │         │
   │         └─► find_and_unprotect via SDK (only if protection succeeded)
   │                   │
   │                   ├─► Success: Original text restored
   │                   └─► Failure: Error with credential tips
   │
   ├─► PromptSanitizer (redact) ──► Redacted output (always succeeds)
   │
   └─► Results rendered with dynamic step numbering and error handling
```

1. The user selects a sample prompt or writes their own in the trial UI.
2. User chooses an execution mode from the dropdown menu.
3. Based on selected mode, the pipeline executes only relevant steps with appropriate step numbering.
4. `SemanticGuardrailClient` posts the prompt to the local Semantic Guardrail service and surfaces the outcome exactly as returned.
5. `PromptSanitizer` executes `find_and_protect`. If the text remains unchanged (indicating credential failure), `sanitize_error` is set and no data is displayed.
6. When protection succeeds, `find_and_unprotect` is attempted to verify reversibility.
7. A dedicated `PromptSanitizer` instance always performs redaction in Full Pipeline and Find & Redact modes.
8. The UI renders each stage with mode-appropriate step numbers and comprehensive error handling.

## Configuration & extensibility

- **Domain processors** – Three semantic guardrail domains available: `customer-support`, `financial`, `healthcare`. Selected domain is passed to the v1.1 API for context-aware risk evaluation.
- **Guardrail settings** – Domain parameter dynamically set based on user selection in sidebar; configured in `GuardrailConfig`
- **Environment variables** – `DEV_EDITION_EMAIL`, `DEV_EDITION_PASSWORD`, and `DEV_EDITION_API_KEY` enable reversible protection. Launch script detects missing credentials and provides clear warnings.
- **Caching** – The UI caches service client construction so repeated runs stay responsive.
- **Line-wise sanitisation** – `PromptSanitizer` processes multi-line prompts one line at a time, matching the sample CLI behaviour and yielding predictable redaction/protection output while preserving blank lines.
- **Modular rendering** – UI functions (`_render_protection`, `_render_unprotect`, etc.) accept dynamic step numbers for flexible display across execution modes. Each renders as an expandable card with professional styling.
- **Domain-specific sample prompts** – Embedded in `DOMAIN_SAMPLE_PROMPTS` dictionary with 4 samples per domain covering legitimate requests, data exfiltration, privilege escalation, and off-topic scenarios
- **Next steps** – Teams can extend the architecture with additional domain processors, conversation-level guardrails, policy presets stored under `configs/`, or alternative UIs (Gradio, FastAPI) that reuse the same pipeline module.

## Error handling philosophy

The Trial Center follows a transparent error handling approach:
- **No automatic fallbacks** – When protection fails, errors are surfaced clearly rather than silently switching to redaction
- **Security-first display** – Sensitive data is never displayed when protection fails
- **Clear guidance** – Error messages include actionable tips (e.g., setting environment variables)
- **Silent failure detection** – Detects when SDK operations complete without errors but don't modify data (indicating authentication issues)
- **Comprehensive feedback** – Each step provides success/failure indication with specific error details
