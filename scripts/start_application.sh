#!/bin/bash
set -e

echo "▶️ ===== STARTING APPLICATION ====="

# Navigate to application directory
cd /home/ubuntu/fastfood-app

# Install production dependencies
echo "📦 Installing production dependencies..."
npm install --production

# Set environment variables
export NODE_ENV=production
export PORT=3000

# Kill any existing PM2 processes
echo "🛑 Stopping existing PM2 processes..."
pm2 delete all || true

# Start application with PM2 in FORK mode (not cluster)
echo "🚀 Starting Fast Food App with PM2..."
pm2 start server.js \
    --name fastfood-app \
    --time

# Save PM2 configuration
pm2 save

# Display PM2 status
echo "📊 Application Status:"
pm2 list

echo "✅ Application started successfully!"
echo "🌐 Access at: http://44.199.191.251:3000"
