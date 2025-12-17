# bare Setup Guide

This guide walks you through setting up the bare iOS app with Supabase integration.

## Prerequisites

- Xcode 16+ (for iOS 26/Swift 6.0)
- Supabase account and project
- Apple Developer account (for app signing and entitlements)

## 1. Supabase Configuration

### 1.1 Database Setup

Run the migrations in order against your Supabase database:

```bash
# Connect to your Supabase project
psql "postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT-REF].supabase.co:5432/postgres"

# Run migrations
\i migrations/001_init_schema.sql
\i migrations/002_ingestion_rpcs.sql
```

### 1.2 Edge Functions

Deploy the Edge Functions to Supabase:

```bash
# Install Supabase CLI if not already installed
brew install supabase/tap/supabase

# Link to your project
supabase link --project-ref [YOUR-PROJECT-REF]

# Deploy functions
supabase functions deploy studio_canonicalize_and_check
supabase functions deploy studio_create_post_with_canonicalization
```

### 1.3 Storage Bucket

Create a storage bucket for thumbnails:

1. Go to Storage in Supabase Dashboard
2. Create a new bucket named `studio_thumbnails`
3. Set it to Public (or Private with signed URLs if preferred)

### 1.4 Configure Redirects

In Supabase Dashboard → Authentication → URL Configuration:
- Add `bareapp://auth-callback` to Redirect URLs

## 2. iOS App Configuration

### 2.1 Create Secrets.plist

1. Copy the template:
   ```bash
   cp bare/bare/Resources/Secrets.plist.template bare/bare/Resources/Secrets.plist
   ```

2. Edit `Secrets.plist` with your Supabase credentials:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>SUPABASE_URL</key>
       <string>https://[YOUR-PROJECT-REF].supabase.co</string>
       <key>SUPABASE_ANON_KEY</key>
       <string>[YOUR-ANON-KEY]</string>
   </dict>
   </plist>
   ```

3. **Important**: `Secrets.plist` is git-ignored. Never commit it.

### 2.2 Add BareKit to Xcode Project

1. Open `bare.xcodeproj` in Xcode
2. Select the `bare` target
3. Go to "Frameworks, Libraries, and Embedded Content"
4. Click "+" → "Add Package Dependency"
5. Choose "Add Local..." and select the `BareKit` folder
6. Add `BareKit` to both `bare` and `ShareExtension` targets

### 2.3 Configure Entitlements

#### Main App Target (`bare`)

1. Select the `bare` target → Signing & Capabilities
2. Add the following capabilities:

**Keychain Sharing**
- Add group: `$(AppIdentifierPrefix)co.bareapp.bare.sharedkeychain` (must be the FIRST entry in both app and extension)

**App Groups**
- Add group: `group.co.bareapp.bare`

**Associated Domains** (for deep linking)
- Add: `applinks:your-domain.com` (if applicable)

3. Under Info tab, add URL Types:
   - Identifier: `co.bareapp.bare`
   - URL Schemes: `bareapp`
   - Role: Editor

#### Share Extension Target (`ShareExtension`)

1. Select the `ShareExtension` target → Signing & Capabilities
2. Add the same capabilities:

**Keychain Sharing**
- Add group: `$(AppIdentifierPrefix)co.bareapp.bare.sharedkeychain` (must be the FIRST entry to match the app)

Note: The app uses KeychainAccess without hardcoding an access group. iOS uses the first keychain access group from entitlements; matching the first entry across targets enables session sharing.

**App Groups**
- Add group: `group.co.bareapp.bare`

### 2.4 Update Team and Bundle IDs

1. Select each target and update:
   - Team: Your Apple Developer Team
   - Bundle Identifier: `co.bareapp.bare` (main app)
   - Bundle Identifier: `co.bareapp.bare.ShareExtension` (extension)

## 3. Testing

### 3.1 Test Authentication

1. Run the app
2. Enter your email on the sign-in screen
3. Check your email for the magic link
4. Click the link (should open the app via deep link)
5. Verify you're signed in and see the grid view

### 3.2 Test Share Extension

1. Open Safari or any app
2. Share a URL
3. Select "bare" from the share sheet
4. Add optional instructions
5. Tap "Save"
6. Open the main app and verify the post appears

## 4. Database Migrations (CI/CD)

For automated migrations in CI, create `.github/workflows/migrate.yml`:

```yaml
name: Database Migrations

on:
  push:
    branches: [main]
    paths:
      - 'migrations/**'

jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install PostgreSQL client
        run: sudo apt-get install -y postgresql-client
      
      - name: Run migrations
        env:
          DATABASE_URL: ${{ secrets.SUPABASE_DB_URL }}
        run: |
          for file in migrations/*.sql; do
            echo "Applying $file..."
            psql $DATABASE_URL -f "$file"
          done
```

Add `SUPABASE_DB_URL` to your GitHub secrets.

## 5. Ingestion Workflow (n8n)

### 5.1 Setup Database Webhook

In Supabase Dashboard → Database → Webhooks:

1. Create a new webhook
2. Table: `studio_ingestion_jobs`
3. Events: INSERT
4. HTTP Request:
   - Method: POST
   - URL: Your n8n webhook URL
   - Headers: Add authentication if needed

### 5.2 n8n Workflow

Create an n8n workflow with these nodes:

1. **Webhook Trigger** - receives DB webhook
2. **Function Node** - call `studio_claim_ingestion_job` RPC
3. **If Node** - check if job was claimed
4. **HTTP Request** - fetch URL content
5. **AI/Processing Nodes** - extract data, generate thumbnails, etc.
6. **Function Node** - call `studio_complete_ingestion_job` on success
7. **Error Handler** - call `studio_retry_ingestion_job` on failure

## Troubleshooting

### "Failed to initialize dependencies"
- Check that `Secrets.plist` exists and has valid credentials
- Verify Supabase URL and anon key are correct

### "Please sign in to the main app first" (Share Extension)
- Make sure you've signed in to the main app
- Verify Keychain Sharing group is identical in both targets
- Check that the App Identifier Prefix is correct

### Deep link not working
- Verify URL scheme `bareapp` is configured
- Check that redirect URL `bareapp://auth-callback` is in Supabase
- Ensure you're testing on a physical device or properly configured simulator

### Posts not appearing
- Check RLS policies are correctly applied
- Verify Edge Functions are deployed
- Check Supabase logs for errors

## Development Tips

- Use `#Preview` macros for rapid SwiftUI iteration
- Test auth flows on a physical device for best results
- Monitor Supabase logs during development
- Use Xcode's Network debugging to inspect requests

## Next Steps

- Configure push notifications (future feature)
- Implement AI chat (see `AIChatService` placeholder)
- Add additional RLS policies as needed



## 5. Observability Setup

### 5.1 Firebase Configuration

1. Create Firebase projects for each environment:
   - Development: `bare-dev`
   - Production: `bare-prod`

2. Download `GoogleService-Info.plist` for each project
3. Place them in:
   - `bare/bare/Config/Firebase/Debug/GoogleService-Info.plist`
   - `bare/bare/Config/Firebase/Release/GoogleService-Info.plist`

4. Enable services in Firebase Console:
   - Analytics (without Ad ID)
   - Remote Config
   - Crashlytics
   - Performance Monitoring

### 5.2 PostHog Configuration

1. Sign up at [PostHog](https://posthog.com/)
2. Create a project
3. Copy your Project API Key and Host URL

### 5.3 Create Secrets.plist for Observability

```bash
cp bare/bare/Config/Secrets.plist.template bare/bare/Config/Secrets.plist
```

Edit with your credentials:
- `POSTHOG_API_KEY`: Your PostHog project API key
- `POSTHOG_HOST`: e.g., `https://app.posthog.com`

### 5.4 Add SDK Dependencies in Xcode

1. **Firebase**: File → Add Package Dependencies
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Products: FirebaseAnalytics, FirebaseRemoteConfig, FirebaseCrashlytics, FirebasePerformance

2. **PostHog**: File → Add Package Dependencies
   - URL: `https://github.com/PostHog/posthog-ios`
   - Product: PostHog

### 5.5 Add Build Run Scripts

In Xcode, bare app target → Build Phases → + New Run Script Phase:

**Crashlytics** (after Compile Sources):
```bash
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```

**Performance** (after Crashlytics):
```bash
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/FirebasePerformance/run"
```

Input Files for both:
- `${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}`
- `${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}`

**Note**: Analytics are disabled in Debug builds by default. See [OBSERVABILITY.md](docs/OBSERVABILITY.md) for details.

