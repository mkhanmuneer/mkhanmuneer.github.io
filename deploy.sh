#!/bin/bash

# --- SETUP INSTRUCTIONS ---
# 1. Save this file as deploy.sh
# 2. Run: chmod +x deploy.sh
# 3. Run: ./deploy.sh or bash deploy.sh or sh deploy.sh
# ---------------------------

# --- CONFIGURATION ---
ENV_NAME="dataco_env"
THRESHOLD_KB=1000 
LOG_DIR="logs"
LOG_FILE="$LOG_DIR/build_$(date +'%Y%m%d_%H%M%S').log"
SITE_URL="https://mkhanmuneer.github.io/"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Start logging (Requires Bash)
exec > >(tee "$LOG_FILE") 2>&1

echo "--------------------------------------------------------"
echo "🛠️  PORTFOLIO DEPLOYMENT PIPELINE: $(date)"
echo "--------------------------------------------------------"

# 1. PRE-FLIGHT GIT CHECK
echo "🔍 Step 1: Checking Git Status..."
if [[ -n $(git status --porcelain | grep -E '^(M|A|D|R|C|U| )M') ]]; then
    echo "⚠️  WARNING: Uncommitted changes detected."
    read -p "❓ Proceed anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Deployment aborted. Commit your config changes first."
        exit 1
    fi
fi

# 2. ENVIRONMENT VALIDATION
if [[ "$CONDA_DEFAULT_ENV" != "$ENV_NAME" ]]; then
    echo "❌ ERROR: Active environment is '$CONDA_DEFAULT_ENV', expected '$ENV_NAME'."
    exit 1
fi

# 3. TOOLCHAIN CHECK
quarto_ver=$(quarto --version)
echo "✅ Env: $ENV_NAME | Quarto: $quarto_ver"

# 4. PRE-BUILD CLEANUP
# Expanded to catch index_files, index_copy_files, etc.
rm -rf docs _site/ .quarto/ *_files/ 
# Optional: Don't rm -rf _freeze/ here to keep the cache!
echo "🧹 Build folders and root asset caches cleared."

# 5. RENDER
echo "🚀 Step 5: Executing Quarto Render..."
# --clean ensures a 100% fresh build from source
quarto render --clean --log-level info

# 6. DATA INTEGRITY AUDIT
echo "🔍 Step 6: Auditing _freeze integrity..."
if [ -d "_freeze" ]; then
    freeze_size=$(du -sk _freeze | cut -f1)
    if [ "$freeze_size" -lt "$THRESHOLD_KB" ]; then
        echo "⚠️  WARNING: _freeze folder is unusually small (${freeze_size}KB)."
        read -p "❓ Proceed with deployment? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Deployment aborted."
            exit 1
        fi
    else
        echo "✅ Integrity check passed (${freeze_size}KB)."
    fi
else
    echo "❌ ERROR: _freeze folder missing."
    exit 1
fi

# 7. DEPLOYMENT & LOG ROTATION
if [ $? -eq 0 ] && [ -d "docs" ]; then
    echo "📦 Step 7: Staging all authorized assets..."
    
    # Use '.' to catch all new projects/images automatically
    git add .
    
    status_msg="Prod Build: $(date +'%Y-%m-%d %H:%M') | Freeze: ${freeze_size}KB"
    
    # Only commit if there are actually changes to avoid 'nothing to commit' errors
    if git diff-index --quiet HEAD --; then
        echo "ℹ️  No changes detected. Skipping commit."
    else
        git commit -m "$status_msg"
        echo "📤 Step 8: Pushing to GitHub..."
        git push origin main
    fi
    
    # KEEP ONLY THE LAST 5 LOGS (Cleanliness)
    ls -t "$LOG_DIR"/build_*.log | tail -n +6 | xargs -r rm --
    
    echo "--------------------------------------------------------"
    echo "🎉 DEPLOYMENT SUCCESSFUL: $(date +'%H:%M:%S')"
    echo "📂 Log: $LOG_FILE"
    echo "🌐 Live Site: $SITE_URL"
    echo "--------------------------------------------------------"
    
    # This makes the URL "clickable" in most modern terminals (Ctrl + Click)
    # We also trigger a system beep (\a) to notify you
    echo -e "\n🔗 Click to preview: \e[4;34m$SITE_URL\e[0m\n"
    echo -e "\a"
else
    echo "❌ ERROR: Build failed. Check $LOG_FILE"
    exit 1
fi