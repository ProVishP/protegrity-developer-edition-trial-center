#!/bin/bash
# Complete cleanup and setup with proper Docker Compose v2
# Paste this into EC2 Instance Connect

set -e

echo "=========================================="
echo "STEP 1: Cleanup Previous Installation"
echo "=========================================="

# Stop any running containers
if [ -d ~/developer-edition ]; then
    cd ~/developer-edition
    docker-compose down 2>/dev/null || docker compose down 2>/dev/null || true
fi

# Stop streamlit
pkill -f "streamlit run" 2>/dev/null || true

# Remove directories
rm -rf ~/developer-edition ~/protegrity-developer-edition-trial-center ~/streamlit.log
echo "✓ Previous installations removed"

# Clean bashrc
sed -i '/DEV_EDITION_EMAIL/d' ~/.bashrc 2>/dev/null || true
sed -i '/DEV_EDITION_PASSWORD/d' ~/.bashrc 2>/dev/null || true
sed -i '/DEV_EDITION_API_KEY/d' ~/.bashrc 2>/dev/null || true
echo "✓ Environment cleaned"

echo ""
echo "=========================================="
echo "STEP 2: Install Docker Compose V2"
echo "=========================================="

# Remove old docker-compose if exists
sudo rm -f /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install Docker Compose V2 from GitHub releases
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "Installing Docker Compose $COMPOSE_VERSION..."
sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create symlink for 'docker compose' command
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo ln -sf /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose

# Verify installation
/usr/local/bin/docker-compose --version
echo "✓ Docker Compose V2 installed"

echo ""
echo "=========================================="
echo "STEP 3: Install Developer Edition"
echo "=========================================="

# Clone Developer Edition
cd ~
git clone https://github.com/Protegrity-Developer-Edition/protegrity-developer-edition.git developer-edition
cd developer-edition
echo "✓ Developer Edition cloned"

# Check if docker-compose.yml exists and is valid
if [ ! -f docker-compose.yml ]; then
    echo "ERROR: docker-compose.yml not found!"
    exit 1
fi

# Start with Docker Compose V2 syntax
echo "Starting containers with Docker Compose V2..."
docker-compose up -d

if [ $? -ne 0 ]; then
    echo ""
    echo "⚠ Docker Compose failed. Checking docker-compose.yml for issues..."
    echo "If 'post_start' is still not supported, we may need to comment it out."
    echo ""
    echo "Attempting to fix docker-compose.yml..."
    
    # Backup original
    cp docker-compose.yml docker-compose.yml.backup
    
    # Comment out post_start lines (temporary workaround)
    sed -i 's/^\(\s*\)post_start:/\1# post_start:/g' docker-compose.yml
    sed -i 's/^\(\s*\)- /\1# - /g' docker-compose.yml
    
    echo "Retrying with modified docker-compose.yml..."
    docker-compose up -d
fi

echo "✓ Docker containers starting"

echo ""
echo "=========================================="
echo "STEP 4: Wait for Services"
echo "=========================================="

echo "Waiting 2 minutes for services to initialize..."
sleep 120

echo ""
echo "Container status:"
docker-compose ps

echo ""
echo "Testing API health..."
for i in {1..5}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "✓ API is healthy!"
        break
    else
        echo "Attempt $i: API not ready, waiting 10s..."
        sleep 10
    fi
done

echo ""
echo "=========================================="
echo "STEP 5: Configure Credentials"
echo "=========================================="

cat >> ~/.bashrc << 'EOF'

# Protegrity Developer Edition Credentials
export DEV_EDITION_EMAIL='vishal.paranjpe@protegrity.com'
export DEV_EDITION_PASSWORD='SpjWy8c#eVeswcId'
export DEV_EDITION_API_KEY='5qHIgfdAj75Rra6qfoIQa1Gp7vnfJJdC7ts5UNAI'
EOF

source ~/.bashrc
echo "✓ Credentials configured"

echo ""
echo "=========================================="
echo "STEP 6: Install Trial Center"
echo "=========================================="

cd ~
git clone https://github.com/ProVishP/protegrity-developer-edition-trial-center.git
cd protegrity-developer-edition-trial-center
echo "✓ Trial Center cloned"

echo "Installing Python dependencies..."
# Try to install from TestPyPI first (for v1.1.0), fall back to PyPI
pip3 install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple protegrity-developer-python==1.1.0 --quiet 2>/dev/null || {
    echo "⚠ v1.1.0 not found on TestPyPI, installing latest available version..."
    pip3 install protegrity-developer-python --quiet
}

# Install remaining dependencies
pip3 install -r requirements.txt --quiet
echo "✓ Dependencies installed"

echo ""
echo "=========================================="
echo "STEP 7: Start Trial Center"
echo "=========================================="

# Start in background
nohup python3 -m streamlit run app.py --server.port 8502 --server.address 0.0.0.0 > ~/streamlit.log 2>&1 &
STREAMLIT_PID=$!

echo "✓ Trial Center started (PID: $STREAMLIT_PID)"
sleep 5

# Check if streamlit is running
if ps -p $STREAMLIT_PID > /dev/null 2>&1; then
    echo "✓ Streamlit is running"
else
    echo "⚠ Streamlit may have failed to start. Check logs:"
    echo "  tail -f ~/streamlit.log"
fi

echo ""
echo "=========================================="
echo "✅ SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "🌐 Trial Center URL: http://100.30.227.81:8502"
echo ""
echo "📋 Useful Commands:"
echo "  Check logs:      tail -f ~/streamlit.log"
echo "  Stop Trial:      pkill -f 'streamlit run'"
echo "  Restart Trial:   cd ~/protegrity-developer-edition-trial-center && nohup python3 -m streamlit run app.py --server.port 8502 --server.address 0.0.0.0 > ~/streamlit.log 2>&1 &"
echo "  Check Docker:    cd ~/developer-edition && docker-compose ps"
echo "  Stop Docker:     cd ~/developer-edition && docker-compose down"
echo ""
echo "=========================================="
