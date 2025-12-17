# Bare iOS Project Guidelines

> **Central AI Guidelines**: See `docs/AI_GUIDELINES.md` for complete, cross-platform AI tool guidelines.
> This file contains Claude Code-specific context and references.

## Project Overview
This is an iOS application project built with Xcode, with potential for future expansion to macOS and other Apple platforms. All development must adhere to the highest software engineering standards with a focus on correctness, efficiency, and optimal architectural decisions.

## Development Workflow

### Planning First, Always
- **MANDATORY**: Plan every task thoroughly before implementation
- Analyze solutions at both low-level (implementation details) and high-level (system architecture)
- Only proceed to implementation once the plan is validated at all levels
- Consider edge cases, performance implications, and maintainability during planning

### Think Through Solutions
- Evaluate correctness: Does the solution solve the problem completely?
- Evaluate efficiency: Is this the most performant approach?
- Evaluate architecture: Does this fit well with existing patterns and future scalability?

## Code Quality Standards

### DRY (Don't Repeat Yourself)
- Maximize code reusability across the codebase
- Extract common functionality into reusable components, utilities, or extensions
- Avoid duplicating logic - if you need the same behavior twice, abstract it
- This improves maintainability and reduces bugs

### Simplicity & Clear Responsibilities
- Always choose the simplest solution that solves the problem
- Each component/class/function should have a single, clear responsibility
- Simple code is:
  - Less error-prone
  - More efficient
  - Easier to test
  - Easier to maintain
- Avoid over-engineering - build what's needed, not what might be needed

### Code Organization
- Group related functionality together
- Use clear, descriptive naming conventions
- Keep files focused and reasonably sized
- Follow Swift naming conventions and idioms

## Architecture Principles

### Design Systems Approach
- Employ centralized systems for all major functionality
- Create design systems for UI components (colors, typography, spacing, etc.)
- Build reusable, composable components
- Maintain consistency across the application

### UI Design System (MANDATORY)

**CRITICAL: Always use DesignTokens from BareKit for ALL UI values**

```swift
import BareKit

// ✅ CORRECT - Use DesignTokens
.padding(DesignTokens.Spacing.md)
.background(DesignTokens.Colors.surfaceLight)
.cornerRadius(DesignTokens.CornerRadius.md)

// ❌ WRONG - Never hardcode values
.padding(16)
.background(Color.gray.opacity(0.1))
.cornerRadius(12)
```

**Strict Rules:**
- **NEVER** hardcode colors with opacity - use `DesignTokens.Colors.*`
- **NEVER** hardcode spacing/padding values - use `DesignTokens.Spacing.*`
- **NEVER** hardcode corner radius - use `DesignTokens.CornerRadius.*`
- This applies to **ALL targets**: main app, Share Extension, widgets, notifications, etc.
- DesignTokens is in BareKit, accessible everywhere
- If you need a new value, add it to `DesignTokens.swift` first

**Available Tokens:**
- Colors: `backgroundOverlay`, `surfaceLight`, `surfaceMedium`, `borderLight`, `borderError`, `interactiveOverlay`, `primaryGradientStart`, `shadowLight`, `shadowBlue`
- Spacing: `xs` (8), `sm` (12), `md` (16), `lg` (20), `xl` (24), `xxl` (32), `xxxl` (40)
- CornerRadius: `sm` (8), `md` (12), `lg` (16), `xl` (20)

**Why This Matters:**
- Ensures visual consistency across all app targets
- Single source of truth for design updates
- Supports theming and design system evolution
- Prevents UI fragmentation between main app and extensions

### Centralization
- Centralize configuration, constants, and shared resources
- Use dependency injection for better testability
- Avoid scattered, duplicated setup code
- Make it easy to update behavior in one place

### iOS Best Practices
- Follow Apple's Human Interface Guidelines
- Use native iOS patterns and conventions
- Leverage SwiftUI and modern iOS frameworks appropriately
- Consider accessibility from the start
- Handle memory management properly
- Follow Swift's API Design Guidelines

## Git & Commit Practices

### Commit Messages
- Keep commit messages concise and focused
- Describe WHAT changed and WHY (the "what" should be clear from the diff)
- Use imperative mood: "Add feature" not "Added feature"
- **NEVER mention AI, Claude, LLM, or any generative AI tools in commits**
- No "Co-Authored-By: Claude" or "Generated with AI" tags
- Example good commits:
  - "Add user authentication flow"
  - "Fix memory leak in image cache"
  - "Refactor network layer for better error handling"

### Git Best Practices
- Make atomic commits (one logical change per commit)
- Commit frequently with meaningful messages
- Keep commits focused and reviewable
- Use feature branches for new work
- Keep the main branch stable and deployable

## Key Principles Summary

1. **Plan before coding** - Think through the entire solution first
2. **DRY** - Never repeat yourself, maximize reusability
3. **Simplicity** - Choose the simplest effective solution
4. **Clear responsibilities** - Each component has one clear purpose
5. **Centralize** - Use design systems and centralized configurations
6. **Best practices** - Follow iOS/Swift conventions and patterns
7. **Clean commits** - Concise messages, no AI mentions

## Testing & Quality Assurance
- Write testable code from the start
- Consider unit test coverage for business logic
- Test on different device sizes and iOS versions
- Handle error cases gracefully
- Validate user input appropriately

## Performance Considerations
- Profile before optimizing
- Consider memory usage, especially with images and data
- Use lazy loading where appropriate
- Avoid blocking the main thread
- Cache appropriately but watch memory pressure

## Documentation Standards

### Purpose of Documentation
Documentation serves to provide **guidelines, patterns, and critical setup instructions** for maintaining consistency, efficiency, and best practices. Documentation is **NOT** for recording what happened or intermediate implementation steps.

### What to Document

**DO Create/Maintain:**
- **Architecture guidelines** - Core patterns, principles, and system design
- **Setup instructions** - Critical configuration and environment setup steps
- **Best practices** - Development standards and conventions
- **Technology stack** - Choices, versions, and rationale
- **API patterns** - How to work with existing systems
- **Contributing guidelines** - How to work on the codebase

**DO NOT Create:**
- Implementation summaries or "what we did" documents
- Step-by-step task completion logs
- Intermediate checklists for one-time tasks
- Issue resolution logs (e.g., "Swift6 fixes", "Build fixes")
- Process documentation that has no future value
- Multiple redundant setup guides

### Documentation Organization

**Core Documentation (root `/docs`)**:
- Keep architectural, technical, and contribution docs in `/docs/` folder
- Examples: `ARCHITECTURE.md`, `CONTRIBUTING.md`, `DECISIONS.md`, `TECHNOLOGY_STACK.md`

**Setup Documentation (root)**:
- Keep essential setup guides at project root
- Examples: `README.md`, `SETUP.md`, `QUICKSTART.md`
- Consolidate redundant setup docs - prefer one comprehensive guide over many small ones

**Temporary Documentation (`/temp-docs` - if needed)**:
- If you must create intermediate documentation (planning docs, task logs, etc.), place them in `/temp-docs/`
- Clearly label them as temporary
- These can be deleted once the task is complete
- Never reference temporary docs from permanent documentation

### Rules for AI Tools (Claude, Cursor, etc.)

**NEVER create intermediate .md files unless explicitly requested by the user**

Examples of what NOT to create:
- `IMPLEMENTATION_SUMMARY.md`
- `TASK_COMPLETE.md`
- `FIX_DOCUMENTATION.md`
- `CHANGES_MADE.md`
- Any file documenting what you just did

**IF you must create temporary documentation:**
1. Ask the user first
2. Place it in `/temp-docs/` folder
3. Make it clear it's temporary and can be deleted
4. Never link to it from permanent docs

**WHEN documenting your work:**
- Update existing documentation files instead of creating new ones
- Add to `ARCHITECTURE.md` if architectural changes were made
- Update `SETUP.md` if setup steps changed
- Modify `CONTRIBUTING.md` if development workflow changed
- Edit the relevant existing doc - don't create a new one

**Exception:** If setting up a completely new system (e.g., adding an entirely new service), ONE setup guide at the root level is acceptable if it's comprehensive and will have ongoing value.

### Documentation Maintenance
- Regularly review documentation for relevance
- Delete outdated or redundant documentation
- Consolidate similar documentation into comprehensive guides
- Keep docs concise - remove unnecessary verbosity

---

These guidelines ensure the codebase remains maintainable, scalable, and of the highest quality as the project grows.
