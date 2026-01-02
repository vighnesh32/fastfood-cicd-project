#!/bin/bash

echo "💚 ===== VALIDATING SERVICE ====="

# Wait for PM2 to fully start
echo "⏳ Waiting 25 seconds for application to stabilize..."
sleep 25

# Check if PM2 process exists and get status
PM2_LIST=$(pm2 jlist 2>/dev/null)

if echo "$PM2_LIST" | grep -q '"name":"fastfood-app"'; then
    echo "✅ PM2 process found!"
    
    # Check if it's online (not errored/stopped)
    if echo "$PM2_LIST" | grep '"name":"fastfood-app"' | grep -q '"status":"online"'; then
        echo "✅ Application status: ONLINE"
        echo "🎉 Deployment successful!"
        echo "🌐 Application URL: http://44.199.191.251:3000"
        pm2 list
        exit 0
    else
        echo "⚠️ Application exists but not online!"
        pm2 list
        pm2 logs fastfood-app --lines 30 --nostream
        exit 1
    fi
else
    echo "❌ PM2 process not found!"
    pm2 list
    exit 1
fi
