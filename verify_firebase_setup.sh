#!/bin/bash

# Firebase Index Verification Script
# This script checks if all required Firebase indexes are properly deployed

echo "🔥 Firebase Index Verification for Rhythmbhara Tara Sadhana"
echo "============================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    print_status "ERROR" "Firebase CLI is not installed"
    echo "Please install it with: npm install -g firebase-tools"
    exit 1
fi

print_status "SUCCESS" "Firebase CLI is installed"

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    print_status "ERROR" "Not logged in to Firebase"
    echo "Please run: firebase login"
    exit 1
fi

print_status "SUCCESS" "Firebase authentication verified"

# Check if correct project is selected
current_project=$(firebase use --current 2>/dev/null | grep "currently using" | cut -d' ' -f4 | tr -d '()')

if [ "$current_project" != "rhythmbhara-tara-sadhana-517d0" ]; then
    print_status "WARNING" "Current project is '$current_project', switching to 'rhythmbhara-tara-sadhana-517d0'"
    firebase use rhythmbhara-tara-sadhana-517d0
    if [ $? -ne 0 ]; then
        print_status "ERROR" "Failed to switch to project rhythmbhara-tara-sadhana-517d0"
        exit 1
    fi
fi

print_status "SUCCESS" "Using correct Firebase project: rhythmbhara-tara-sadhana-517d0"

# Deploy indexes if firestore.indexes.json exists
if [ -f "firestore.indexes.json" ]; then
    print_status "INFO" "Found firestore.indexes.json, deploying indexes..."
    
    # Deploy indexes
    firebase deploy --only firestore:indexes
    
    if [ $? -eq 0 ]; then
        print_status "SUCCESS" "Firestore indexes deployed successfully"
    else
        print_status "ERROR" "Failed to deploy Firestore indexes"
        exit 1
    fi
else
    print_status "ERROR" "firestore.indexes.json not found"
    print_status "INFO" "This file should be in the project root directory"
    exit 1
fi

# Deploy rules as well
if [ -f "firestore.rules" ]; then
    print_status "INFO" "Deploying Firestore rules..."
    firebase deploy --only firestore:rules
    
    if [ $? -eq 0 ]; then
        print_status "SUCCESS" "Firestore rules deployed successfully"
    else
        print_status "WARNING" "Failed to deploy Firestore rules (not critical for indexes)"
    fi
else
    print_status "WARNING" "firestore.rules not found (not critical for indexes)"
fi

echo
print_status "INFO" "Index deployment completed!"
echo
echo "📊 Expected indexes that should be building/active:"
echo "   - notifications (userId, createdAt)"
echo "   - notifications (userId, isRead, createdAt)"
echo "   - notifications (userId, type, createdAt)"
echo "   - notifications (userId, priority, createdAt)"
echo "   - admin_notifications (sentAt)"
echo "   - admin_notifications (type, sentAt)"
echo "   - admin_notifications (priority, sentAt)"
echo "   - user_notifications (userId, createdAt)"
echo "   - user_notifications (userId, isRead, createdAt)"
echo "   - user_notifications (userId, type, createdAt)"
echo "   - user_notifications (userId, priority, createdAt)"
echo
echo "🌐 Check index status in Firebase Console:"
echo "   https://console.firebase.google.com/project/rhythmbhara-tara-sadhana-517d0/firestore/indexes"
echo
echo "⏳ Note: Index building typically takes 5-15 minutes"
echo "   You can run your Flutter app now, but some queries may fail until indexes are ready"
echo
echo "🧪 To test the fixes in your Flutter app:"
echo "   1. flutter clean && flutter pub get"
echo "   2. flutter run"
echo "   3. Navigate to Notifications screen"
echo "   4. Try swiping notifications (dismissible test)"
echo "   5. Check console for any remaining errors"
echo
print_status "SUCCESS" "Verification script completed successfully!"
