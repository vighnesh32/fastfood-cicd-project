#!/bin/bash
set -e

echo "💚 ===== VALIDATING SERVICE ====="

# Wait for application to fully start
echo "⏳ Waiting for application to start..."
sleep 15

# Check if PM2 process is running
if ! pm2 list | grep -q "fastfood-app"; then
    echo "❌ PM2 process not found!"
    pm2 list
    exit 1
fi

echo "✅ PM2 process is running"

# Check if PM2 process is online (not errored)
if pm2 list | grep "fastfood-app" | grep -q "errored"; then
    echo "❌ Application is in errored state!"
    pm2 logs fastfood-app --lines 20 --nostream
    exit 1
fi

echo "✅ Application is online"

# Check if application is listening on port 3000 (using ss instead of lsof)
echo "🔍 Checking if port 3000 is listening..."
if sudo ss -tlnp | grep -q ":3000"; then
    echo "✅ Application is listening on port 3000"
else
    echo "❌ Port 3000 is not listening!"
    sudo ss -tlnp
    exit 1
fi

# Perform HTTP check to root endpoint
echo "🌐 Testing HTTP connection..."
MAX_ATTEMPTS=15
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "000")
    
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "304" ]; then
        echo "✅ HTTP check passed! (HTTP $HTTP_CODE)"
        
        # Test if health endpoint exists (optional - won't fail if missing)
        HEALTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health 2>/dev/null || echo "000")
        if [ "$HEALTH_CODE" = "200" ]; then
            echo "✅ Health endpoint available!"
            curl -s http://localhost:3000/health 2>/dev/null || true
        else
            echo "ℹ️ Health endpoint not available (OK - not required)"
        fi
        
        # Test if menu endpoint exists (optional)
        MENU_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/menu 2>/dev/null || echo "000")
        if [ "$MENU_CODE" = "200" ]; then
            echo "✅ Menu endpoint is working!"
        else
            echo "ℹ️ Menu endpoint not available (OK - not required)"
        fi
        
        echo "🎉 All validation checks passed!"
        echo "🌐 Application available at: http://44.199.191.251:3000"
        exit 0
    fi
    
    echo "⏳ Attempt $ATTEMPT/$MAX_ATTEMPTS: HTTP returned $HTTP_CODE, retrying..."
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

echo "❌ HTTP check failed after $MAX_ATTEMPTS attempts!"
echo "📋 PM2 Status:"
pm2 list
echo "📋 PM2 Logs:"
pm2 logs fastfood-app --lines 30 --nostream

exit 1
