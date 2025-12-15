#!/bin/bash

# Protegrity Developer Edition + Trial Center Setup Script
# Run this script in the EC2 Instance Connect terminal

set -e

echo "===================================="
echo "Starting Protegrity Setup"
echo "===================================="

# 1. Clone Protegrity Developer Edition
echo "Step 1: Cloning Protegrity Developer Edition..."
cd ~
if [ ! -d "developer-edition" ]; then
    git clone https://github.com/Protegrity/developer-edition.git
    echo "✓ Repository cloned"
else
    echo "✓ Repository already exists"
fi

# 2. Start Docker containers
echo "Step 2: Starting Protegrity Docker services..."
cd ~/developer-edition
docker-compose up -d
echo "✓ Docker services started"

# 3. Wait for services
echo "Step 3: Waiting for services to initialize (2 minutes)..."
sleep 120
echo "✓ Services should be ready"

# 4. Verify Docker containers
echo "Step 4: Checking Docker containers..."
docker ps

# 5. Export environment variables
echo "Step 5: Setting up environment variables..."
export PROTEGRITY_EMAIL="vishal.paranjpe@protegrity.com"
export PROTEGRITY_PASSWORD="SpjWy8c#eVeswcId"
export PROTEGRITY_API_KEY="5qHIgfdAj75Rra6qfoIQa1Gp7vnfJJdC7ts5UNAI"
echo "✓ Environment variables set"

# 6. Start Streamlit
echo "Step 6: Starting Trial Center..."
cd ~/protegrity-developer-edition-trial-center
python3 -m streamlit run app.py --server.port 8502 --server.address 0.0.0.0

echo "===================================="
echo "Setup Complete!"
echo "===================================="
