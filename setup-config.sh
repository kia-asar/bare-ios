#!/bin/bash
# setup-config.sh
# Quick setup script for creating configuration files from templates

set -e

echo "🔧 Bare Configuration Setup"
echo "================================"
echo ""

# Check if we're in the right directory
if [ ! -f "bare/Dev.xcconfig.template" ]; then
    echo "❌ Error: Run this script from the project root directory"
    exit 1
fi

cd bare

# Check if config files already exist
if [ -f "Dev.xcconfig" ] || [ -f "Prod.xcconfig" ]; then
    echo "⚠️  Configuration files already exist:"
    [ -f "Dev.xcconfig" ] && echo "   - Dev.xcconfig"
    [ -f "Prod.xcconfig" ] && echo "   - Prod.xcconfig"
    echo ""
    read -p "Overwrite existing files? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Create Dev.xcconfig
echo "📝 Creating Dev.xcconfig..."
cp Dev.xcconfig.template Dev.xcconfig

# Create Prod.xcconfig
echo "📝 Creating Prod.xcconfig..."
cp Prod.xcconfig.template Prod.xcconfig

echo ""
echo "✅ Configuration files created!"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Edit bare/Dev.xcconfig and add your credentials:"
echo "   - POSTHOG_API_KEY"
echo "   - SUPABASE_URL"
echo "   - SUPABASE_ANON_KEY"
echo ""
echo "2. Edit bare/Prod.xcconfig with production credentials"
echo ""
echo "3. (Optional) Add Firebase configuration files:"
echo "   - bare/bare/Config/Firebase/GoogleService-Info-Dev.plist"
echo "   - bare/bare/Config/Firebase/GoogleService-Info-Prod.plist"
echo ""
echo "4. Build the project with 'bare dev' or 'bare prod' scheme"
echo ""
echo "For detailed instructions, see: CONFIGURATION_SETUP.md"
