#!/bin/bash
# Quick setup for local development

set -e

echo "🔧 Setting up Enterprise AI Grid locally..."

# Install dependencies
npm install
pip install -r requirements.txt

# Setup pre-commit hooks
pre-commit install

# Create local environment file
cat > .env << EOF
NODE_ENV=development
AWS_REGION=us-east-1
DATABASE_URL=postgresql://localhost:5432/devdb
REDIS_URL=redis://localhost:6379
EOF

echo "✅ Local setup complete!"
echo "Run 'docker-compose up' to start services"
