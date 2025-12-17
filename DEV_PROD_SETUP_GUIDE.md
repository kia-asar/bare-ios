# Dev/Prod Environment Setup Guide

This guide covers all manual steps needed to set up Dev and Prod environments for the bare iOS app.

## Overview

The app uses:
- **Two environments**: Dev and Prod
- **Two Firebase projects**: Separate projects with unique bundle IDs
- **Two PostHog projects**: Separate analytics tracking
- **Build configurations**: Dev and Prod (replaces Debug/Release)
- **Schemes**: "bare Dev" and "bare Prod"
- **`.xcconfig` files**: Environment-specific settings

## Part 1: Xcode Configuration

### Step 1.1: Create Build Configurations

1. Open `bare.xcodeproj` in Xcode
2. Select the **bare** project (top of navigator)
3. Go to **Info** tab
4. Under **Configurations**:
   - Click **"+"** → Duplicate "Debug Configuration"
   - Rename to: `Dev`
   - Click **"+"** → Duplicate "Release Configuration"
   - Rename to: `Prod`
5. **Optional**: Delete the old "Debug" and "Release" configurations

### Step 1.2: Assign .xcconfig Files to Configurations

1. Still in the **Info** tab under **Configurations**
2. For **Dev** configuration:
   - Expand "Dev" row
   - For "bare" target → select `Dev` from dropdown
   - For "ShareExtension" target → select `Dev` from dropdown
   - For "BareKit" → select `None` (not needed)
3. For **Prod** configuration:
   - Expand "Prod" row
   - For "bare" target → select `Prod` from dropdown
   - For "ShareExtension" target → select `Prod` from dropdown
   - For "BareKit" → select `None`

**Note**: If `.xcconfig` files don't appear in the dropdown:
1. Make sure they're added to the project
2. Right-click on `bare/Config` folder → "Add Files to bare"
3. Select `Dev.xcconfig` and `Prod.xcconfig`
4. **Do NOT check** "Copy items if needed"
5. **Do NOT check** any target membership

### Step 1.3: Create Schemes

#### Create "bare Dev" Scheme:

1. Menu: **Product** → **Scheme** → **Manage Schemes**
2. Select existing "bare" scheme → click gear icon ⚙️ → **Duplicate**
3. Name it: `bare Dev`
4. Configure each action to use **Dev** configuration:
   - **Build**: (no changes needed)
   - **Run**: Build Configuration → `Dev`
   - **Test**: Build Configuration → `Dev`
   - **Profile**: Build Configuration → `Dev`
   - **Analyze**: Build Configuration → `Dev`
   - **Archive**: Build Configuration → `Dev`
5. Check **"Shared"** (so it's committed to git)
6. Click "Close"

#### Create "bare Prod" Scheme:

1. Menu: **Product** → **Scheme** → **Manage Schemes**
2. Select "bare Dev" scheme → click gear icon ⚙️ → **Duplicate**
3. Name it: `bare Prod`
4. Configure each action to use **Prod** configuration:
   - **Run**: Build Configuration → `Prod`
   - **Test**: Build Configuration → `Prod`
   - **Profile**: Build Configuration → `Prod`
   - **Analyze**: Build Configuration → `Prod`
   - **Archive**: Build Configuration → `Prod`
5. Check **"Shared"**
6. Click "Close"

### Step 1.4: Verify Schemes

- Scheme selector (top-left in Xcode) should show:
  - ✅ "bare Dev"
  - ✅ "bare Prod"
- Select "bare Dev" → build should use Dev config
- Select "bare Prod" → build should use Prod config

## Part 2: Firebase Setup

### Step 2.1: Create Firebase Projects

#### Dev Firebase Project:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** (or use existing project)
3. Name: `bare-dev` (or your preferred name)
4. Enable Google Analytics: **Yes** (optional but recommended)
5. Complete project creation

#### Prod Firebase Project:

1. Click **"Add project"** again
2. Name: `bare-prod` (or your preferred name)
3. Enable Google Analytics: **Yes**
4. Complete project creation

### Step 2.2: Register iOS Apps

#### In Dev Firebase Project:

1. Open `bare-dev` project in Firebase Console
2. Click **iOS** icon to add an iOS app
3. **iOS bundle ID**: `co.bareapp.bare.dev` ⚠️ Must match exactly
4. **App nickname**: "bare Dev" (optional)
5. **App Store ID**: (leave blank for now)
6. Click **"Register app"**
7. **Download** `GoogleService-Info.plist`
8. Save as: `GoogleService-Info-Dev.plist` (rename immediately)
9. Complete the wizard (skip SDK installation steps)

#### In Prod Firebase Project:

1. Open `bare-prod` project in Firebase Console
2. Click **iOS** icon to add an iOS app
3. **iOS bundle ID**: `co.bareapp.bare` ⚠️ Must match exactly
4. **App nickname**: "bare Prod" (optional)
5. **App Store ID**: (add when published)
6. Click **"Register app"**
7. **Download** `GoogleService-Info.plist`
8. Save as: `GoogleService-Info-Prod.plist` (rename immediately)
9. Complete the wizard

### Step 2.3: Enable Firebase Services

Repeat for **both** Dev and Prod projects:

#### Analytics:
1. Navigate to **Analytics** → **Dashboard**
2. Already enabled by default ✅

#### Crashlytics:
1. Navigate to **Crashlytics**
2. Click **"Enable Crashlytics"**
3. Follow setup instructions

#### Performance Monitoring:
1. Navigate to **Performance**
2. Click **"Get started"**
3. Enable Performance Monitoring

#### Remote Config:
1. Navigate to **Remote Config**
2. Click **"Create configuration"**
3. Add initial parameters (or do this later)

### Step 2.4: Install Firebase Plists in Xcode

1. In Finder, locate your downloaded files:
   - `GoogleService-Info-Dev.plist`
   - `GoogleService-Info-Prod.plist`
2. In Xcode, navigate to `bare/bare/Config/Firebase/` folder
3. Drag both `.plist` files into Xcode:
   - **Target Membership**: Check **"bare"** only (not ShareExtension)
   - **Copy items if needed**: Check this box ✅
   - They should be copied to `bare/bare/Config/Firebase/`
4. Verify files appear in Xcode project navigator

### Step 2.5: Restrict API Keys (Security)

#### Dev Project:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select `bare-dev` project
3. Navigate to **APIs & Services** → **Credentials**
4. Find the iOS API key (from `GoogleService-Info-Dev.plist`)
5. Click **Edit**
6. Under **Application restrictions**:
   - Select **"iOS apps"**
   - Click **"Add an app"**
   - Bundle ID: `co.bareapp.bare.dev`
7. Click **Save**

#### Prod Project:
1. Select `bare-prod` project in Cloud Console
2. Navigate to **APIs & Services** → **Credentials**
3. Find the iOS API key
4. Click **Edit**
5. Under **Application restrictions**:
   - Select **"iOS apps"**
   - Bundle ID: `co.bareapp.bare`
6. Click **Save**

## Part 3: PostHog Setup

### Step 3.1: Create PostHog Projects

#### Dev Project:
1. Go to [PostHog](https://app.posthog.com/) (or self-hosted instance)
2. Create new project: "bare Dev"
3. Copy **Project API Key** (starts with `phc_`)
4. Note the **Host URL** (usually `https://us.i.posthog.com`)

#### Prod Project:
1. Create another project: "bare Prod"
2. Copy **Project API Key**
3. Note the **Host URL**

### Step 3.2: Configure .xcconfig Files

#### Dev.xcconfig:
1. Open `bare/Config/Dev.xcconfig`
2. Replace `YOUR_POSTHOG_DEV_API_KEY_HERE` with your actual Dev API key
3. Update `POSTHOG_HOST` if using self-hosted instance
4. Save file

#### Prod.xcconfig:
1. Open `bare/Config/Prod.xcconfig`
2. Replace `YOUR_POSTHOG_PROD_API_KEY_HERE` with your actual Prod API key
3. Update `POSTHOG_HOST` if needed
4. Save file

**⚠️ Important**: These files are in `.gitignore`. Copy `.template` files if starting fresh.

## Part 4: Apple Developer Setup

### Step 4.1: Register App IDs

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **"+"** button

#### Dev App ID:
1. Select **"App IDs"** → Continue
2. **Description**: "bare Dev"
3. **Bundle ID**: `co.bareapp.bare.dev` (Explicit)
4. Enable capabilities:
   - App Groups ✅
   - Sign in with Apple ✅
   - (any others needed)
5. Click **Register**

#### Prod App ID:
1. Click **"+"** again
2. **Description**: "bare"
3. **Bundle ID**: `co.bareapp.bare` (Explicit)
4. Enable same capabilities as Dev
5. Click **Register**

### Step 4.2: Create App Group (Shared)

1. Click **Identifiers** → **"+"** button
2. Select **"App Groups"** → Continue
3. **Description**: "bare App Group"
4. **Identifier**: `group.co.bareapp.bare`
5. Click **Register**

### Step 4.3: Associate App IDs with App Group

For **both** `co.bareapp.bare.dev` and `co.bareapp.bare`:
1. Select the App ID
2. Under **App Groups** → Click **Edit** (or **Configure**)
3. Check your `group.co.bareapp.bare`
4. Click **Save**

### Step 4.4: Create Provisioning Profiles

Create profiles for **both** Dev and Prod App IDs:
1. Navigate to **Profiles** → **"+"** button
2. Select profile type (Development, Ad Hoc, or App Store)
3. Select App ID
4. Select certificates and devices
5. Download and install profiles

## Part 5: App Icons (Optional but Recommended)

### Step 5.1: Create Dev App Icon

1. Open `bare/bare/Assets.xcassets` in Xcode
2. Right-click → **"New iOS App Icon"**
3. Name it: `AppIcon-Dev`
4. Add your Dev app icon images (with badge/indicator to distinguish from Prod)
   - Recommended: Add "DEV" text overlay or colored banner

### Step 5.2: Verify Icon Configuration

- Dev configuration uses: `AppIcon-Dev` (set in `Dev.xcconfig`)
- Prod configuration uses: `AppIcon` (set in `Prod.xcconfig`)

## Part 6: Verification

### Step 6.1: Build and Run Dev

1. Select **"bare Dev"** scheme
2. Build and run (⌘R)
3. Check console logs:
   ```
   ✅ Firebase configured for environment: Dev
   PostHog analytics enabled
   ✅ Observability initialized
   ```
4. Verify in Firebase Console (Dev project) that events appear
5. Verify in PostHog (Dev project) that events appear

### Step 6.2: Build and Run Prod

1. Select **"bare Prod"** scheme
2. Build and run (⌘R)
3. Check console logs:
   ```
   ✅ Firebase configured for environment: Prod
   PostHog analytics enabled
   ✅ Observability initialized
   ```
4. Verify Firebase Prod project receives events
5. Verify PostHog Prod project receives events

### Step 6.3: Verify Coexistence

1. Build and install **Dev** on device
2. Note app name shows "bare Dev"
3. Build and install **Prod** on same device
4. **Both apps should be installed** side-by-side ✅
5. Dev and Prod should have different icons (if configured)

## Troubleshooting

### "GoogleService-Info-Dev.plist not found"
- Verify files are in `bare/bare/Config/Firebase/`
- Verify files are added to **bare** target in Xcode
- Check Build Phases → Copy Bundle Resources

### ".xcconfig not applied"
- Verify .xcconfig files are selected in project → Info → Configurations
- Clean build folder (⌘⇧K) and rebuild
- Check that target is set to use configuration-level settings

### "PostHog API key not configured"
- Verify `Dev.xcconfig` and `Prod.xcconfig` have actual API keys (not `YOUR_...`)
- Rebuild project (configuration changes require rebuild)

### "Bundle ID already exists" on device
- This means both Dev and Prod have the same bundle ID
- Verify configurations are using different bundle IDs:
  - Dev: `co.bareapp.bare.dev`
  - Prod: `co.bareapp.bare`

### Firebase events going to wrong project
- Check console logs to see which environment was loaded
- Verify correct scheme is selected
- Verify `GoogleService-Info-Dev.plist` and `-Prod.plist` have correct project IDs

## Next Steps

After completing this setup:

1. ✅ Commit scheme files to git (they're in `.xcworkspace/xcshareddata/xcschemes/`)
2. ✅ Share `.xcconfig.template` files with team (actual `.xcconfig` files are gitignored)
3. ✅ Document PostHog API keys in secure team location (password manager, CI/CD secrets)
4. ✅ Set up CI/CD with separate Dev/Prod lanes
5. ✅ Configure TestFlight with separate Dev and Prod groups

## Summary Checklist

- [ ] Xcode configurations created (Dev, Prod)
- [ ] .xcconfig files assigned to configurations
- [ ] Schemes created (bare Dev, bare Prod)
- [ ] Firebase Dev project created
- [ ] Firebase Prod project created
- [ ] iOS apps registered in both Firebase projects (different bundle IDs)
- [ ] Firebase services enabled (Analytics, Crashlytics, Performance, Remote Config)
- [ ] `GoogleService-Info-Dev.plist` downloaded and added to Xcode
- [ ] `GoogleService-Info-Prod.plist` downloaded and added to Xcode
- [ ] Firebase API keys restricted in Google Cloud Console
- [ ] PostHog Dev project created
- [ ] PostHog Prod project created
- [ ] PostHog API keys added to `.xcconfig` files
- [ ] Apple Developer App IDs created (Dev, Prod)
- [ ] App Group created and associated
- [ ] Provisioning profiles created
- [ ] App icons differentiated (optional)
- [ ] Dev build verified
- [ ] Prod build verified
- [ ] Coexistence verified (both apps on same device)

## Reference

- **Bundle IDs**:
  - Dev: `co.bareapp.bare.dev`
  - Prod: `co.bareapp.bare`
- **App Group**: `group.co.bareapp.bare`
- **Config Files**:
  - `bare/Config/Dev.xcconfig`
  - `bare/Config/Prod.xcconfig`
- **Firebase Plists**:
  - `bare/bare/Config/Firebase/GoogleService-Info-Dev.plist`
  - `bare/bare/Config/Firebase/GoogleService-Info-Prod.plist`

