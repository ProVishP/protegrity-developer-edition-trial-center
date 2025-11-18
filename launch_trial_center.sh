#!/usr/bin/env bash

################################################################################
# Protegrity Developer Edition Trial Center Launcher
# 
# Purpose: Launches the Trial Center Streamlit UI with comprehensive
#          environment validation and service health checks.
#
# Requirements:
#   - Protegrity Developer Edition services running (in a separate installation)
#   - Python 3.11+ with virtual environment
#   - Streamlit installed in the virtual environment
#
# Environment Variables (optional):
#   - DEV_EDITION_EMAIL: Protegrity account email for reversible protection
#   - DEV_EDITION_PASSWORD: Protegrity account password
#   - DEV_EDITION_API_KEY: API key for protection services
#
# Usage:
#   ./launch_trial_center.sh [--help]
################################################################################

set -euo pipefail

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VENV_PATH="${SCRIPT_DIR}/.venv"
readonly OUTPUT_DIR="${SCRIPT_DIR}/output"
readonly GUARDRAIL_ENDPOINT="http://localhost:8581"
readonly DISCOVERY_ENDPOINT="http://localhost:8580"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_DOCKER_ERROR=1
readonly EXIT_VENV_ERROR=2
readonly EXIT_SERVICE_ERROR=3
readonly EXIT_DEPENDENCY_ERROR=4
readonly EXIT_USER_CANCEL=130

print_message() { echo -e "${1}${2}${NC}"; }
error_exit() { print_message "${RED}" "❌ ERROR: $1"; exit "${2:-1}"; }
print_success() { print_message "${GREEN}" "✅ $1"; }
print_warning() { print_message "${YELLOW}" "⚠️  $1"; }
print_info() { print_message "${BLUE}" "ℹ️  $1"; }
print_step() { print_message "${CYAN}" "▶ $1"; }

show_help() {
    cat << EOF
${GREEN}Protegrity Developer Edition Trial Center Launcher${NC}

${BLUE}PREREQUISITES:${NC}
    1. Protegrity Developer Edition must be installed and running:
       
       git clone https://github.com/Protegrity-Developer-Edition/protegrity-developer-edition.git
       cd protegrity-developer-edition
       docker-compose up -d
    
    2. Python 3.11+
    3. Python packages (automatically installed by this script)

${BLUE}USAGE:${NC}
    $0 [--help]

${BLUE}WHAT THIS SCRIPT DOES:${NC}
    ✓ Validates Docker and services are running
    ✓ Creates Python virtual environment (if needed)
    ✓ Automatically installs missing packages
    ✓ Verifies all dependencies are present
    ✓ Launches the Streamlit UI

${BLUE}ENVIRONMENT VARIABLES (optional):${NC}
    DEV_EDITION_EMAIL      - For reversible protection features
    DEV_EDITION_PASSWORD   - For reversible protection features
    DEV_EDITION_API_KEY    - For reversible protection features

EOF
}

check_docker() {
    print_step "Checking Docker..."
    command -v docker &> /dev/null || error_exit "Docker not installed" "${EXIT_DOCKER_ERROR}"
    docker info &> /dev/null || error_exit "Docker daemon not running" "${EXIT_DOCKER_ERROR}"
    print_success "Docker is running"
}

check_python() {
    print_step "Checking Python environment..."
    command -v python3 &> /dev/null || error_exit "Python 3 not installed" "${EXIT_VENV_ERROR}"
    
    if [[ ! -d "${VENV_PATH}" ]]; then
        print_warning "Creating virtual environment..."
        python3 -m venv "${VENV_PATH}" || error_exit "Failed to create venv" "${EXIT_VENV_ERROR}"
    fi
    print_success "Virtual environment ready"
}

activate_venv() {
    print_step "Activating virtual environment..."
    source "${VENV_PATH}/bin/activate" || error_exit "Failed to activate venv" "${EXIT_VENV_ERROR}"
    print_success "Virtual environment activated"
}

check_environment_variables() {
    print_step "Checking credentials..."
    
    if [[ -z "${DEV_EDITION_EMAIL:-}" ]] || [[ -z "${DEV_EDITION_PASSWORD:-}" ]] || [[ -z "${DEV_EDITION_API_KEY:-}" ]]; then
        echo
        print_warning "═══════════════════════════════════════════════════════════════"
        print_warning "  CREDENTIALS NOT CONFIGURED"
        print_warning "═══════════════════════════════════════════════════════════════"
        print_warning "Protection operations require credentials."
        print_warning "Discovery and Guardrail features will work without them."
        print_warning ""
        print_warning "To enable protection:"
        print_warning "  export DEV_EDITION_EMAIL='your-email@domain.com'"
        print_warning "  export DEV_EDITION_PASSWORD='your-password'"
        print_warning "  export DEV_EDITION_API_KEY='your-api-key'"
        print_warning "═══════════════════════════════════════════════════════════════"
        echo
    else
        print_success "Credentials configured"
    fi
}

check_dev_edition_services() {
    print_step "Checking Protegrity Developer Edition services..."
    
    if docker ps --filter "name=semantic_guardrail" --filter "status=running" 2>/dev/null | grep -q "semantic_guardrail" && \
       docker ps --filter "name=classification_service" --filter "status=running" 2>/dev/null | grep -q "classification_service"; then
        print_success "Developer Edition services detected"
        return 0
    fi
    
    echo
    print_message "${RED}" "╔═══════════════════════════════════════════════════════════════╗"
    print_message "${RED}" "║   PROTEGRITY DEVELOPER EDITION SERVICES NOT DETECTED          ║"
    print_message "${RED}" "╚═══════════════════════════════════════════════════════════════╝"
    echo
    print_warning "Please start Developer Edition services first:"
    echo
    print_info "1. Clone (if not done):"
    print_info "   git clone https://github.com/Protegrity-Developer-Edition/protegrity-developer-edition.git"
    echo
    print_info "2. Start services:"
    print_info "   cd protegrity-developer-edition"
    print_info "   docker-compose up -d"
    echo
    print_info "3. Wait 1-2 minutes, then run this script again"
    echo
    error_exit "Developer Edition services not found" "${EXIT_SERVICE_ERROR}"
}

wait_for_service() {
    local service_name="$1"
    local endpoint="$2"
    local check_path="$3"
    local max_attempts=30
    local attempt=0
    
    print_step "Waiting for ${service_name}..."
    
    while [[ ${attempt} -lt ${max_attempts} ]]; do
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "${endpoint}${check_path}" 2>/dev/null || echo "000")
        
        if [[ "${http_code}" != "000" ]] && [[ "${http_code}" =~ ^[2-5][0-9][0-9]$ ]]; then
            print_success "${service_name} ready"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    echo
    error_exit "${service_name} not ready" "${EXIT_SERVICE_ERROR}"
}

check_services() {
    local http_code_guardrail=$(curl -s -o /dev/null -w "%{http_code}" "${GUARDRAIL_ENDPOINT}/docs" 2>/dev/null || echo "000")
    local http_code_discovery=$(curl -s -o /dev/null -w "%{http_code}" "${DISCOVERY_ENDPOINT}/pty/data-discovery/v1.0/classify" 2>/dev/null || echo "000")
    
    if [[ "${http_code_guardrail}" =~ ^[2-5][0-9][0-9]$ ]] && [[ "${http_code_discovery}" =~ ^[2-5][0-9][0-9]$ ]]; then
        print_success "Services are healthy"
        return 0
    fi
    
    print_step "Checking service health..."
    wait_for_service "Semantic Guardrail" "${GUARDRAIL_ENDPOINT}" "/docs"
    wait_for_service "Data Discovery" "${DISCOVERY_ENDPOINT}" "/pty/data-discovery/v1.0/classify"
}

setup_output_directory() {
    mkdir -p "${OUTPUT_DIR}" || error_exit "Failed to create output directory" "${EXIT_DEPENDENCY_ERROR}"
}

check_dependencies() {
    print_step "Checking Python dependencies..."
    
    # Check for all critical dependencies with detailed reporting
    local missing_deps=false
    local missing_list=()
    
    # Check each dependency individually for better error reporting
    if ! python -c "import protegrity_developer_python" &> /dev/null; then
        missing_deps=true
        missing_list+=("protegrity-developer-python")
    fi
    
    if ! python -c "import streamlit" &> /dev/null; then
        missing_deps=true
        missing_list+=("streamlit")
    fi
    
    if ! python -c "import requests" &> /dev/null; then
        missing_deps=true
        missing_list+=("requests")
    fi
    
    if ! python -c "import pandas" &> /dev/null; then
        missing_deps=true
        missing_list+=("pandas")
    fi
    
    if [[ "${missing_deps}" == "true" ]]; then
        echo
        print_warning "Missing packages detected: ${missing_list[*]}"
        print_warning "Installing all dependencies from requirements.txt..."
        echo
        
        if [[ -f "${SCRIPT_DIR}/requirements.txt" ]]; then
            pip install -r "${SCRIPT_DIR}/requirements.txt" || error_exit "Failed to install dependencies" "${EXIT_DEPENDENCY_ERROR}"
            echo
            print_success "All dependencies installed successfully"
        else
            error_exit "requirements.txt not found" "${EXIT_DEPENDENCY_ERROR}"
        fi
    else
        print_success "All dependencies verified (protegrity-developer-python, streamlit, requests, pandas)"
    fi
}

launch_ui() {
    print_step "Launching Trial Center UI..."
    echo
    
    print_info "═══════════════════════════════════════════════════════════════"
    print_info "  STARTING STREAMLIT WEB INTERFACE"
    print_info "═══════════════════════════════════════════════════════════════"
    print_info "Press Ctrl+C to stop"
    print_info "═══════════════════════════════════════════════════════════════"
    echo
    
    cd "${SCRIPT_DIR}" || error_exit "Failed to change directory" "${EXIT_DEPENDENCY_ERROR}"
    streamlit run app.py
}

cleanup() {
    local exit_code=$?
    [[ ${exit_code} -eq ${EXIT_USER_CANCEL} ]] && { echo; print_warning "Cancelled by user"; }
    [[ -n "${VIRTUAL_ENV:-}" ]] && deactivate 2>/dev/null || true
    exit "${exit_code}"
}

trap cleanup EXIT
trap 'exit ${EXIT_USER_CANCEL}' INT TERM

main() {
    [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]] && { show_help; exit 0; }
    
    echo
    print_message "${GREEN}" "╔═══════════════════════════════════════════════════════════════╗"
    print_message "${GREEN}" "║    PROTEGRITY DEVELOPER EDITION TRIAL CENTER                 ║"
    print_message "${GREEN}" "║           Privacy-Preserving GenAI Pipeline                  ║"
    print_message "${GREEN}" "╚═══════════════════════════════════════════════════════════════╝"
    echo
    
    check_docker
    check_dev_edition_services
    check_python
    activate_venv
    check_environment_variables
    check_services
    setup_output_directory
    check_dependencies
    
    echo
    print_success "All prerequisites validated!"
    echo
    
    launch_ui
}

main "$@"
