# cstudio

iOS app for saving and organizing content with AI-powered analysis.

## Quick Start

**First time setup?** → See [QUICKSTART.md](QUICKSTART.md) to add CStudioKit and fix build errors.

1. **Setup**: Follow [SETUP.md](SETUP.md) for complete configuration
2. **Build**: Open `cstudio.xcodeproj` in Xcode 16+
3. **Run**: Build and run on iOS 26+ device or simulator

## Features

- 📱 Share Extension - Save content from any app
- 🔐 Email Magic Link Auth - Passwordless via Supabase
- 🔄 Auto-Sync - Seamless between app and extension
- 📊 Grid View - Instagram-like content grid
- 🎯 Smart Ingestion - Background processing with retries
- 🔍 URL Canonicalization - Dedupe by normalized URLs

## Documentation

- [SETUP.md](SETUP.md) - Complete setup guide
- [Architecture Guidelines](docs/ARCHITECTURE.md) - Core patterns & principles
- [Contributing](docs/CONTRIBUTING.md) - Development workflow
- [Key Decisions](docs/DECISIONS.md) - Architectural choices & rationale
- [Technology Stack](docs/TECHNOLOGY_STACK.md) - Tech choices & version policy

## Architecture

- **iOS**: Swift 6.0, SwiftUI, iOS 26 (main) / iOS 18 (extension)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **Ingestion**: n8n workflows triggered by database webhooks
- **Code Sharing**: CStudioKit Swift package for app+extension

## Key Technologies

- Swift 6.0 with strict concurrency
- SwiftUI-first architecture
- Supabase for backend (PostgreSQL with RLS, Auth, Storage)
- JSONB for flexible payloads
- n8n for ingestion workflows
- Protocol-driven dependency injection

---

**Note**: Flexible foundation for future development. Extend as needed without constraints.
