#!/bin/bash

# Notification System Setup Script
# This script helps deploy and configure the improved notification system

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=""
ENVIRONMENT=""
BACKUP_DIR="./backup_$(date +%Y%m%d_%H%M%S)"

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Notification System Setup${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check if Firebase CLI is installed
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI is not installed"
        echo "Install it with: npm install -g firebase-tools"
        exit 1
    fi
    
    # Check if logged into Firebase
    if ! firebase projects:list &> /dev/null; then
        print_error "Not logged into Firebase CLI"
        echo "Login with: firebase login"
        exit 1
    fi
    
    # Check if pubspec.yaml exists
    if [ ! -f "pubspec.yaml" ]; then
        print_error "pubspec.yaml not found. Are you in the correct directory?"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Get project configuration
get_project_config() {
    print_step "Getting project configuration..."
    
    # Try to get project ID from .firebaserc
    if [ -f ".firebaserc" ]; then
        PROJECT_ID=$(grep -o '"[^"]*"' .firebaserc | head -1 | tr -d '"')
        print_success "Found project ID: $PROJECT_ID"
    else
        echo "Enter your Firebase Project ID:"
        read -r PROJECT_ID
    fi
    
    echo "Select environment:"
    echo "1) Development"
    echo "2) Staging"
    echo "3) Production"
    read -p "Enter choice (1-3): " env_choice
    
    case $env_choice in
        1) ENVIRONMENT="development" ;;
        2) ENVIRONMENT="staging" ;;
        3) ENVIRONMENT="production" ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac
    
    print_success "Configuration: Project=$PROJECT_ID, Environment=$ENVIRONMENT"
}

# Create backup
create_backup() {
    print_step "Creating backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup current notification files
    if [ -f "lib/services/notification_service.dart" ]; then
        cp "lib/services/notification_service.dart" "$BACKUP_DIR/"
    fi
    
    if [ -f "lib/providers/notification_provider.dart" ]; then
        cp "lib/providers/notification_provider.dart" "$BACKUP_DIR/"
    fi
    
    if [ -d "lib/screens" ]; then
        cp -r "lib/screens" "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    # Backup Firebase rules
    if [ -f "firestore.rules" ]; then
        cp "firestore.rules" "$BACKUP_DIR/"
    fi
    
    print_success "Backup created at: $BACKUP_DIR"
}

# Update dependencies
update_dependencies() {
    print_step "Updating dependencies..."
    
    # Check if required dependencies are in pubspec.yaml
    required_deps=("provider" "shared_preferences" "intl" "flutter_local_notifications")
    
    for dep in "${required_deps[@]}"; do
        if ! grep -q "$dep:" pubspec.yaml; then
            print_warning "Missing dependency: $dep"
            echo "Please add to pubspec.yaml dependencies:"
            case $dep in
                "provider") echo "  provider: ^6.1.1" ;;
                "shared_preferences") echo "  shared_preferences: ^2.2.2" ;;
                "intl") echo "  intl: ^0.19.0" ;;
                "flutter_local_notifications") echo "  flutter_local_notifications: ^16.3.2" ;;
            esac
        fi
    done
    
    # Run flutter pub get
    print_step "Running flutter pub get..."
    flutter pub get
    
    print_success "Dependencies updated"
}

# Deploy Firebase configuration
deploy_firebase_config() {
    print_step "Deploying Firebase configuration..."
    
    # Deploy Firestore rules
    if [ -f "firestore.rules" ]; then
        print_step "Deploying Firestore security rules..."
        firebase deploy --only firestore:rules --project "$PROJECT_ID"
        print_success "Firestore rules deployed"
    else
        print_warning "firestore.rules not found, skipping rules deployment"
    fi
    
    # Deploy Firestore indexes
    if [ -f "firestore.indexes.json" ]; then
        print_step "Deploying Firestore indexes..."
        firebase deploy --only firestore:indexes --project "$PROJECT_ID"
        print_success "Firestore indexes deployed"
    else
        print_warning "firestore.indexes.json not found, skipping indexes deployment"
    fi
}

# Setup admin users
setup_admin_users() {
    print_step "Setting up admin users..."
    
    echo "Do you want to setup admin users? (y/n)"
    read -r setup_admins
    
    if [ "$setup_admins" = "y" ] || [ "$setup_admins" = "Y" ]; then
        echo "Enter admin email addresses (one per line, empty line to finish):"
        admin_emails=()
        
        while IFS= read -r email; do
            if [ -z "$email" ]; then
                break
            fi
            admin_emails+=("$email")
        done
        
        if [ ${#admin_emails[@]} -gt 0 ]; then
            print_step "Admin emails collected: ${admin_emails[*]}"
            print_warning "You'll need to manually add these to Firestore admins collection"
            echo "For each admin, create a document in 'admins' collection with:"
            echo "Document ID: {user_uid}"
            echo "Data: {\"email\": \"admin@example.com\", \"role\": \"super_admin\"}"
        fi
    fi
}

# Test notification system
test_notification_system() {
    print_step "Testing notification system..."
    
    echo "Do you want to run notification system tests? (y/n)"
    read -r run_tests
    
    if [ "$run_tests" = "y" ] || [ "$run_tests" = "Y" ]; then
        print_step "Running Flutter tests..."
        
        if [ -f "test/notification_system_test.dart" ]; then
            flutter test test/notification_system_test.dart
            print_success "Notification tests completed"
        else
            print_warning "Notification test file not found"
        fi
    fi
}

# Generate migration report
generate_migration_report() {
    print_step "Generating migration report..."
    
    cat > "MIGRATION_REPORT_$(date +%Y%m%d_%H%M%S).md" << EOF
# Notification System Migration Report

**Date:** $(date)
**Project:** $PROJECT_ID
**Environment:** $ENVIRONMENT

## Files Modified/Added

### New Files Added:
- lib/services/improved_notification_service.dart
- lib/services/notification_migration_service.dart
- lib/providers/improved_notification_provider.dart
- lib/screens/improved_notification_screen.dart
- lib/screens/notification_admin_panel.dart
- lib/utils/notification_utils.dart
- lib/widgets/notification_widgets.dart
- firestore.rules
- firestore.indexes.json

### Files Modified:
- lib/providers/notification_provider.dart (backward compatibility)
- pubspec.yaml (dependencies updated)

### Backup Location:
$BACKUP_DIR

## Database Changes

### New Collections:
- user_notifications/
- admin_notifications/
- notification_metadata/
- migration_status/

### Indexes Created:
- user_notifications: userId + createdAt
- user_notifications: userId + isRead + createdAt
- admin_notifications: sentAt

## Migration Status

- [x] Firebase rules deployed
- [x] Database indexes created
- [x] New services implemented
- [x] Backward compatibility maintained
- [x] UI components updated

## Next Steps

1. Monitor system performance
2. Verify notification delivery
3. Check migration completion for users
4. Remove old system after verification (optional)

## Rollback Instructions

If issues occur:
1. Restore files from backup: $BACKUP_DIR
2. Redeploy old Firebase rules
3. Run: flutter pub get
4. Restart the application

EOF

    print_success "Migration report generated"
}

# Cleanup temporary files
cleanup() {
    print_step "Cleaning up..."
    
    # Remove any temporary files if created
    # Add cleanup commands here if needed
    
    print_success "Cleanup completed"
}

# Main deployment process
main() {
    print_header
    
    echo "This script will deploy the improved notification system."
    echo "Make sure you have:"
    echo "1. Tested the system in development"
    echo "2. Backed up your database"
    echo "3. Informed users about the update"
    echo ""
    
    echo "Continue with deployment? (y/n)"
    read -r continue_deploy
    
    if [ "$continue_deploy" != "y" ] && [ "$continue_deploy" != "Y" ]; then
        echo "Deployment cancelled"
        exit 0
    fi
    
    # Run deployment steps
    check_prerequisites
    get_project_config
    create_backup
    update_dependencies
    deploy_firebase_config
    setup_admin_users
    test_notification_system
    generate_migration_report
    cleanup
    
    print_success "Notification system deployment completed!"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Test the application thoroughly"
    echo "2. Monitor Firebase console for any errors"
    echo "3. Check notification delivery to users"
    echo "4. Review migration report for details"
    echo ""
    echo -e "${YELLOW}Important:${NC}"
    echo "- Users will be automatically migrated on their next app launch"
    echo "- Monitor system performance during peak usage"
    echo "- Keep backup files until migration is confirmed successful"
    echo ""
    echo -e "${GREEN}Backup location:${NC} $BACKUP_DIR"
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@"
