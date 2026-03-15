# AGENTS.md

# Enterprise Development Guidelines

This document defines the **engineering standards, architecture rules, documentation requirements, and collaboration practices** for this repository.

It applies to:

* All developers working on the project
* Code reviewers
* New team members
* AI coding agents
* Automation tools

The objective is to ensure:

* maintainable code
* reusable architecture
* consistent development practices
* traceable code updates
* high engineering standards

---

# Core Development Principles

All contributors must follow these principles:

1. **Reuse before creating new code**
2. Maintain **clean and readable architecture**
3. Follow the **existing project structure**
4. Avoid duplicate logic
5. Write **scalable and testable code**
6. Ensure **every change is documented and marked**

---

# Mandatory Rule: Check Existing Functionality First

Before implementing any feature or utility:

1. Search the repository for similar functionality.
2. Check shared modules and reusable components.
3. Extend existing functionality instead of creating duplicate logic.

Avoid:

* duplicate networking services
* duplicate utilities
* duplicate UI components
* multiple implementations of the same feature

If an implementation already exists, **reuse or extend it**.

---

# Project Architecture

The project follows:

**MVVM + Coordinator Architecture**

### Responsibilities

View
Handles UI rendering and user interaction.

ViewModel
Contains business logic and state management.

Coordinator
Handles navigation flow.

Service Layer
Handles networking and API communication.

Example flow:

```
View → ViewModel → Service → API
```

---

# Repository Structure

```
Project/
│
├── App/
│
├── Modules/
│   ├── FeatureA
│   ├── FeatureB
│
├── Core/
│   ├── Networking
│   ├── Utilities
│   ├── Extensions
│
├── UIComponents/
│   ├── ReusableViews
│   ├── DesignSystem
│
├── Services/
│
├── Resources/
│
├── Tests/
│
├── README.md
├── AGENTS.md
└── LICENSE
```

---

# Design System Guidelines

All UI must follow the design system.

Rules:

* Do not hardcode colors
* Use shared typography styles
* Use reusable components
* Follow spacing and layout guidelines

Example:

```
DesignSystem/
├── Colors.swift
├── Typography.swift
├── Spacing.swift
```

Example usage:

```swift
label.font = Typography.heading
label.textColor = AppColors.primaryText
```

---

# Reusable UI Components

Reusable UI components must be used whenever possible.

Examples:

* Custom buttons
* Custom text fields
* Table view cells
* Collection view cells
* Empty states
* Loading views

Reusable components must be placed in:

```
UIComponents/ReusableViews/
```

Example:

```swift
final class PrimaryButton: UIButton {

    func configure(title: String) {
        setTitle(title, for: .normal)
    }

}
```

---

# Feature Module Template

Each new feature should follow the module structure.

```
Modules/
└── Wallet
    ├── View
    ├── ViewModel
    ├── Coordinator
    ├── Service
    └── Models
```

Responsibilities:

View → UI layout
ViewModel → state & logic
Service → API calls
Coordinator → navigation

---

# Swift Coding Best Practices

All Swift code must follow modern best practices.

Rules:

* Prefer `struct` over `class`
* Avoid force unwrap (`!`)
* Use protocol-oriented programming
* Keep functions small and focused
* Use meaningful naming

Example:

```swift
protocol WalletServiceProtocol {
    func fetchBalance() async throws -> Balance
}
```

---

# SwiftUI Development Rules

SwiftUI views must remain declarative.

Rules:

* Keep logic inside ViewModels
* Use `@StateObject` for ownership
* Create reusable UI components
* Avoid business logic inside Views

Example:

```swift
struct WalletView: View {

    @StateObject var viewModel: WalletViewModel

    var body: some View {
        Text(viewModel.balanceText)
    }

}
```

---

# UIKit Development Rules

UIKit screens must follow MVVM.

Guidelines:

* Avoid massive view controllers
* Move logic into ViewModels
* Reuse UI components

Recommended limit:

**500 lines per ViewController**

---

# Combine Usage

Combine should be used for:

* reactive UI updates
* async streams
* state binding

Example:

```swift
viewModel.$balance
    .receive(on: DispatchQueue.main)
    .sink { value in
        self.balanceLabel.text = value
    }
```

---

# SwiftLint Rules

All code must pass SwiftLint.

Recommended configuration:

Line Length
Maximum: **120**

Function Length
Recommended: **<= 50 lines**

File Length
Recommended: **<= 500 lines**

Avoid:

* force unwraps
* duplicate logic
* large functions

Run SwiftLint before committing:

```
swiftlint
```

---

# Swift Documentation Guidelines

All important code must include **Swift documentation comments**.

Use triple slash `///`.

Example:

```swift
/// Fetch wallet balance from API
///
/// - Parameters:
///   - userId: Unique identifier for the user
///
/// - Returns: Wallet balance model
///
/// - Author: Developer Name
/// - Date: YYYY-MM-DD
func fetchWalletBalance(for userId: String) async throws -> Balance
```

---

# Documentation for Classes

```swift
/// ViewModel responsible for managing wallet balance state
///
/// - Author: Developer Name
/// - Date: YYYY-MM-DD
final class WalletViewModel {

}
```

---

# Documentation for Variables

```swift
/// Stores the current wallet balance
var walletBalance: Double = 0
```

---

# Documentation for Extensions

```swift
/// Extension for formatting currency values
extension Double {

    /// Converts double value into formatted currency string
    func currencyFormatted() -> String {
        return String(format: "%.2f", self)
    }

}
```

---

# Code Update Marking Guidelines

Every update to functions, variables, or extensions **must include update markers**.

This helps identify who changed the code and when.

Use the following markers:

```swift
// MARK: - ADDED by <DeveloperName> on <YYYY-MM-DD>
// MARK: - UPDATED by <DeveloperName> on <YYYY-MM-DD>
// MARK: - MODIFIED by <DeveloperName> on <YYYY-MM-DD>
// MARK: - FIXED by <DeveloperName> on <YYYY-MM-DD>
```

---

# Example: Updated Function

```swift
// MARK: - UPDATED by Satish on 2026-03-15

/// Fetch wallet balance from API
///
/// - Parameters:
///   - userId: Unique identifier
///
/// - Returns: Wallet balance model
func fetchWalletBalance(for userId: String) async throws -> Balance {

    return try await walletService.fetchBalance(userId)

}
```

---

# Example: Added Variable

```swift
// MARK: - ADDED by Satish on 2026-03-15

/// Cached wallet balance value
private var cachedWalletBalance: Double?
```

---

# Example: Modified Extension

```swift
// MARK: - MODIFIED by Satish on 2026-03-15

extension String {

    /// Returns trimmed string
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

}
```

---

# MARK Organization Guidelines

Use Swift MARK comments to organize code.

Recommended structure:

```swift
// MARK: - Properties
// MARK: - Initializer
// MARK: - Lifecycle
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Helpers
// MARK: - Extensions
```

Example:

```swift
final class WalletViewModel {

    // MARK: - Properties

    private let service: WalletService

    // MARK: - Initializer

    init(service: WalletService) {
        self.service = service
    }

}
```

---

# Git Workflow

Branch strategy:

main → production
develop → active development

feature/* → new features
fix/* → bug fixes

Example:

```
feature/profile-screen
feature/wallet-module
fix/login-crash
```

---

# Commit Message Convention

Use structured commit messages.

Format:

```
type: short description
```

Examples:

```
feat: add wallet balance API
fix: resolve login crash
refactor: improve networking layer
docs: update documentation
```

Commit types:

* feat
* fix
* refactor
* docs
* test
* chore

---

# Pull Request Rules

All pull requests must:

* follow architecture
* pass SwiftLint
* include documentation
* include update markers
* avoid duplicate logic

---

# PR Review Checklist

Reviewers must verify:

* documentation exists
* update markers are present
* reusable components are used
* architecture rules are followed
* SwiftLint passes
* performance impact is acceptable

---

# Testing Requirements

Before merging code:

* ensure project builds successfully
* run unit tests
* verify UI flows

Testing frameworks:

* XCTest
* Swift Testing

---

# AI Agent Rules

AI agents working in this repository must:

1. Check existing functionality before creating new code
2. Reuse existing components
3. Follow MVVM + Coordinator architecture
4. Respect SwiftLint rules
5. Add Swift documentation to generated code
6. Add update markers for modifications

Agents must prioritize:

* reusability
* readability
* performance
* maintainability

---

# Final Notes

This repository is maintained by a **team of developers**.

All contributions must comply with:

* architecture rules
* reusable component guidelines
* Swift documentation standards
* update marking rules
* SwiftLint enforcement
* performance best practices

