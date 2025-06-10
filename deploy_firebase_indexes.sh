#!/bin/bash

# Firebase Index Deployment Script for Rhythmbhara Tara Sadhana

echo "🔥 Deploying Firebase Indexes for Notification System..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Login to Firebase (if not already logged in)
echo "📱 Checking Firebase authentication..."
firebase login --reauth

# Deploy the indexes
echo "🚀 Deploying Firestore indexes..."
firebase deploy --only firestore:indexes

# Deploy rules as well to ensure everything is in sync
echo "🔒 Deploying Firestore rules..."
firebase deploy --only firestore:rules

echo "✅ Firebase deployment completed!"
echo ""
echo "📊 Index deployment status:"
echo "- notifications collection indexes: ✅ Deployed"
echo "- admin_notifications collection indexes: ✅ Deployed" 
echo "- user_notifications collection indexes: ✅ Deployed"
echo ""
echo "🔗 Check your Firebase Console for index build status:"
echo "https://console.firebase.google.com/project/rhythmbhara-tara-sadhana-517d0/firestore/indexes"
echo ""
echo "⏳ Note: Index building may take a few minutes to complete."
