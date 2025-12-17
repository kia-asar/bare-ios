# Quick Start - Fix "No such module 'BareKit'" Error

## Step 1: Add BareKit Package to Xcode

1. Open the project:
   ```bash
   open /Users/kiarash/kialabs/bare-ios/bare/bare.xcodeproj
   ```

2. In Xcode:
   - Select the **project** (top "bare" with blue icon) in the navigator
   - Go to the **"Package Dependencies"** tab in the main editor
   - Click the **"+"** button at the bottom left
   - Choose **"Add Local..."**
   - Navigate to and select: `/Users/kiarash/kialabs/bare-ios/BareKit`
   - Click **"Add Package"**

3. In the dialog that appears:
   - Check **both** `bare` and `ShareExtension` targets
   - Click **"Add Package"**

## Step 2: Configure Secrets.plist

The `Secrets.plist` file has been created from the template. Edit it with your Supabase credentials:

1. Open in Xcode or any text editor:
   ```bash
   open bare/bare/Resources/Secrets.plist
   ```

2. Replace the placeholder values:
   ```xml
   <key>SUPABASE_URL</key>
   <string>https://YOUR-PROJECT-REF.supabase.co</string>
   <key>SUPABASE_ANON_KEY</key>
   <string>YOUR-ANON-KEY-HERE</string>
   ```

3. Get your credentials from:
   - Supabase Dashboard → Project Settings → API
   - Copy "Project URL" and "anon public" key

## Step 3: Build the Project

1. In Xcode, select a target device/simulator
2. Press **Cmd+B** to build
3. If successful, press **Cmd+R** to run

## Troubleshooting

### "Unable to find module dependency: 'Supabase'"
This is normal! When you add BareKit, Xcode will automatically fetch Supabase Swift SDK as a dependency.
- Go to: **File → Packages → Resolve Package Versions**
- Wait for Xcode to download and resolve all dependencies
- This may take 1-2 minutes on first run

### "Secrets.plist file not found"
- Make sure you created `Secrets.plist` in `bare/bare/Resources/`
- In Xcode, verify it appears in the project navigator
- If not, drag and drop it into the project (make sure to add to `bare` target)

### "Invalid Supabase URL"
- Check that your URL starts with `https://`
- Verify it ends with `.supabase.co`
- No trailing slash

### BareKit still not found
- Clean build folder: **Cmd+Shift+K**
- Close and reopen Xcode
- Verify `BareKit` appears under "Package Dependencies" in project navigator

### Build errors in BareKit
- The package requires Supabase Swift SDK (declared in `Package.swift`)
- Xcode should automatically fetch it when you add the package
- If not, try: **File → Packages → Resolve Package Versions**
- If still failing: **File → Packages → Reset Package Caches**, then resolve again

## Next Steps

After the app builds successfully, follow [SETUP.md](SETUP.md) for:
- Database migrations
- Edge Functions deployment
- Entitlements configuration
- n8n webhook setup


## Analytics Behavior

**Important**: Analytics services (Firebase + PostHog) are configured but have environment-specific behavior:

- **Debug builds**: Analytics **disabled by default** (no data sent)
- **Release builds**: Analytics **enabled by default** (implied consent)

To enable analytics in Debug for testing:
```swift
AppGroup.userDefaults?.set(true, forKey: "analytics_consent_granted")
```

See [OBSERVABILITY.md](docs/OBSERVABILITY.md) for full details on analytics, logging, feature flags, and crash reporting.
