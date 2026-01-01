pipeline {
    agent any
    
    tools {
        nodejs 'node-20'
    }
    
    environment {
        APP_DIR = '/var/www/fastfood-app'
        APP_NAME = 'fastfood-app'
        LOG_FILE = '/var/log/fastfood-app.log'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📦 ===== STAGE 1: CHECKOUT ====='
                echo '📥 Cloning repository from GitHub...'
                git branch: 'main', 
                    url: 'https://github.com/vighnesh32/fastfood-cicd-project.git'
                echo '✅ Repository cloned successfully!'
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo '⚙️ ===== STAGE 2: INSTALL DEPENDENCIES ====='
                echo '📦 Installing Node.js dependencies...'
                sh '''
                    node --version
                    npm --version
                    npm install
                '''
                echo '✅ Dependencies installed successfully!'
            }
        }
        
        stage('Run Tests') {
            steps {
                echo '🧪 ===== STAGE 3: RUN TESTS ====='
                echo '🔍 Running application tests...'
                sh 'npm test'
                echo '✅ All tests passed!'
            }
        }
        
        stage('Build Information') {
            steps {
                echo '🔨 ===== STAGE 4: BUILD INFORMATION ====='
                echo '📝 Adding build metadata...'
                script {
                    sh """
                        echo 'Build Number: ${BUILD_NUMBER}'
                        echo 'Build Date: \$(date)'
                        echo 'Git Commit: \$(git rev-parse --short HEAD)'
                        
                        # Update build version in HTML
                        sed -i 's/1.0/1.0.${BUILD_NUMBER}/g' index.html
                    """
                }
                echo '✅ Build information updated!'
            }
        }
        
        stage('Deploy Application') {
            steps {
                echo '🚀 ===== STAGE 5: DEPLOY ====='
                echo '📂 Deploying to production directory...'
                script {
                    sh """
                        # Create application directory if it doesn't exist
                        sudo mkdir -p ${APP_DIR}
                        
                        # Create log file and set permissions
                        sudo touch ${LOG_FILE}
                        sudo chown jenkins:jenkins ${LOG_FILE}
                        sudo chmod 664 ${LOG_FILE}
                        
                        # Backup previous version (optional)
                        if [ -d ${APP_DIR} ] && [ "\$(ls -A ${APP_DIR})" ]; then
                            echo '💾 Creating backup of previous version...'
                            sudo cp -r ${APP_DIR} ${APP_DIR}.backup.\$(date +%Y%m%d_%H%M%S) || true
                        fi
                        
                        # Copy new files
                        echo '📁 Copying application files...'
                        sudo rm -rf ${APP_DIR}/*
                        sudo cp -r * ${APP_DIR}/
                        sudo chown -R jenkins:jenkins ${APP_DIR}
                        
                        # Navigate to application directory
                        cd ${APP_DIR}
                        
                        # Install production dependencies
                        echo '📦 Installing production dependencies...'
                        npm install --production
                        
                        # Force kill any process using port 3000
                        echo '🛑 Force killing any process on port 3000...'
                        sudo fuser -k 3000/tcp || true
                        sudo killall -9 node || true
                        sleep 3
                        
                        # Stop existing PM2 process if running
                        echo '🛑 Stopping existing PM2 application...'
                        pm2 stop ${APP_NAME} || true
                        pm2 delete ${APP_NAME} || true
                        sleep 2
                        
                        # Start application with PM2 in fork mode
                        echo '▶️ Starting application with PM2...'
                        pm2 start server.js \\
                            --name ${APP_NAME} \\
                            --time \\
                            --max-memory-restart 500M \\
                            --log /var/log/fastfood-app.log \\
                            --error /var/log/fastfood-app.log \\
                            --merge-logs
                        
                        # Save PM2 configuration
                        pm2 save --force
                        
                        # Wait for application to start
                        sleep 5
                        
                        # Display PM2 status
                        echo '📊 Application Status:'
                        pm2 list
                        pm2 info ${APP_NAME}
                    """
                }
                echo '✅ Application deployed successfully!'
            }
        }
        
        stage('Health Check') {
            steps {
                echo '💚 ===== STAGE 6: HEALTH CHECK ====='
                echo '🔍 Verifying deployment...'
                script {
                    sh '''
                        # Check if PM2 process is running
                        echo '🔍 Checking PM2 process status...'
                        if pm2 list | grep -q "fastfood-app.*online"; then
                            echo "✅ PM2 process is running"
                        else
                            echo "❌ PM2 process not found or not online"
                            pm2 list
                            pm2 logs fastfood-app --lines 50 --nostream
                            exit 1
                        fi
                        
                        # Check if port 3000 is listening
                        echo '🔍 Checking if application is listening on port 3000...'
                        if sudo lsof -ti:3000 > /dev/null 2>&1; then
                            echo "✅ Application is listening on port 3000"
                        else
                            echo "❌ No process listening on port 3000"
                            exit 1
                        fi
                        
                        # Check if application is responding to HTTP requests
                        echo '🔍 Performing health check on /health endpoint...'
                        MAX_ATTEMPTS=15
                        ATTEMPT=1
                        
                        while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
                            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health || echo "000")
                            
                            if [ "$HTTP_CODE" = "200" ]; then
                                echo "✅ Health check passed! (HTTP $HTTP_CODE)"
                                echo "📋 Health Check Response:"
                                curl -s http://localhost:3000/health | python3 -m json.tool || curl -s http://localhost:3000/health
                                
                                # Test menu endpoint
                                echo ""
                                echo "🍔 Testing menu endpoint..."
                                MENU_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/menu)
                                if [ "$MENU_CODE" = "200" ]; then
                                    echo "✅ Menu endpoint is working! (HTTP $MENU_CODE)"
                                else
                                    echo "⚠️ Menu endpoint returned HTTP $MENU_CODE"
                                fi
                                
                                echo ""
                                echo "🎉 All validation checks passed!"
                                exit 0
                            fi
                            
                            echo "⏳ Attempt $ATTEMPT/$MAX_ATTEMPTS: Health check returned HTTP $HTTP_CODE, retrying in 2 seconds..."
                            sleep 2
                            ATTEMPT=$((ATTEMPT + 1))
                        done
                        
                        echo "❌ Health check failed after $MAX_ATTEMPTS attempts!"
                        echo "📋 Application Logs (last 30 lines):"
                        pm2 logs fastfood-app --lines 30 --nostream
                        echo ""
                        echo "📊 PM2 Status:"
                        pm2 list
                        pm2 info fastfood-app
                        exit 1
                    '''
                }
                echo '✅ Application is healthy and running!'
            }
        }
    }
    
    post {
        success {
            echo '🎉 ===== PIPELINE SUCCESS ====='
            echo "✅ Build Number: ${BUILD_NUMBER}"
            echo '✅ All stages completed successfully!'
            echo '================================'
            echo '🌐 Application URL: http://35.154.81.182:3000'
            echo '💚 Health Check: http://35.154.81.182:3000/health'
            echo '📋 API Menu: http://35.154.81.182:3000/api/menu'
            echo '================================'
            script {
                sh '''
                    echo "📊 Final PM2 Status:"
                    pm2 list
                '''
            }
        }
        failure {
            echo '❌ ===== PIPELINE FAILED ====='
            echo "💔 Build Number: ${BUILD_NUMBER}"
            echo '📋 Check console output for errors'
            echo "📝 Log file: ${LOG_FILE}"
            echo '================================'
            script {
                sh '''
                    echo "📋 Recent Application Logs:"
                    pm2 logs fastfood-app --lines 50 --nostream || tail -50 /var/log/fastfood-app.log || echo "No logs available"
                    echo ""
                    echo "📊 PM2 Status:"
                    pm2 list || echo "PM2 not responding"
                '''
            }
        }
        always {
            echo '🧹 ===== CLEANUP ====='
            echo '📊 Pipeline execution completed'
            echo "⏱️ Duration: ${currentBuild.durationString}"
        }
    }
}
