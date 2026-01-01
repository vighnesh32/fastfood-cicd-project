#!/bin/bash
set -e

echo "💚 ===== VALIDATING SERVICE ====="

# Wait for application to fully start
echo "⏳ Waiting for application to start..."
sleep 10

# Check if PM2 process is running
if ! pm2 list | grep -q "fastfood-app"; then
    echo "❌ PM2 process not found!"
    exit 1
fi

echo "✅ PM2 process is running"

# Check if application is listening on port 3000
if ! lsof -ti:3000 > /dev/null 2>&1; then
    echo "❌ Application not listening on port 3000!"
    exit 1
fi

echo "✅ Application is listening on port 3000"

# Perform health check
echo "🔍 Performing health check..."
MAX_ATTEMPTS=15
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Health check passed! (HTTP $HTTP_CODE)"
        
        # Display health check response
        echo "📋 Health Check Response:"
        curl -s http://localhost:3000/health | python3 -m json.tool
        
        # Test menu endpoint
        echo "🍔 Testing menu endpoint..."
        MENU_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/menu)
        if [ "$MENU_CODE" = "200" ]; then
            echo "✅ Menu endpoint is working!"
        fi
        
        echo "🎉 All validation checks passed!"
        exit 0
    fi
    
    echo "⏳ Attempt $ATTEMPT/$MAX_ATTEMPTS: Health check returned HTTP $HTTP_CODE, retrying..."
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

echo "❌ Health check failed after $MAX_ATTEMPTS attempts!"
echo "📋 PM2 Logs:"
pm2 logs fastfood-app --lines 20 --nostream

exit 1
