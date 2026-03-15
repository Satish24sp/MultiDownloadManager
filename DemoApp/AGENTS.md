# AGENTS.md

## Maintainer Profile

**Name:** Satish
**Role:** Senior iOS Engineer
**Location:** New Delhi, India 🇮🇳

**GitHub:** https://github.com/Satish24sp
**Portfolio:** https://satish24sp.github.io
**Medium:** https://medium.com/@satish24sp
**LinkedIn:** https://linkedin.com/in/satish-iosdev

### Professional Summary

Senior iOS Engineer with **7+ years of experience building large-scale mobile applications**.
Delivered **15+ production apps** used by **9M+ users across 6+ countries**.

Specialized in:

* Swift
* UIKit
* SwiftUI
* Combine
* MVVM + Coordinator architecture
* Clean Architecture
* Fintech-grade mobile applications

Currently working on **Wallet & Self-Care modules at Paytm**, supporting **millions of users**.

---

# Purpose of This File

`AGENTS.md` provides guidance for:

* Developers contributing to the repository
* AI coding agents
* Automation tools
* Code reviewers

It ensures that all contributions follow the **same architecture, coding standards, and development workflow**.

---

# Engineering Philosophy

All code must prioritize:

1. Readability
2. Maintainability
3. Performance
4. Scalability
5. Security

Code written in this repository should be **production-ready and capable of supporting millions of users**.

---

# Technology Stack

## Primary Languages

* Swift
* Objective-C (legacy modules)

## iOS Frameworks

* UIKit
* SwiftUI
* Combine
* StoreKit
* Foundation
* CoreData

## Architecture

Primary patterns used:

* MVVM
* MVVM + Coordinator
* Clean Architecture
* Protocol Oriented Programming

## Backend / Services

* Firebase
* PubNub
* AWS
* REST APIs
* JSON APIs

## Security

* AES-256 encryption
* Secure token handling
* Encrypted storage
* Secure API communication

## Tools

* Xcode
* Swift Package Manager
* Git
* Instruments
* Swift Testing (WWDC24)
* XCTest

---

# Apps and Impact

Applications built by the maintainer have collectively reached **millions of users worldwide**.

Examples include:

### Paytm

Wallet & Self-Care modules
2M+ Monthly Active Users
4.7★ rating with millions of reviews

### My Liberty

Telecom SuperApp for Liberty Puerto Rico
523K downloads
4.8★ rating

### Glo Café

Telecom services platform
1.89M+ downloads

### Pay+

Fintech wallet for National Bank of Oman
1.2M+ downloads

### Utkarsh

Ed-Tech learning platform
1.3M+ users

### Sanskar TV

Spiritual streaming application
983K+ users

Total impact:

* 15+ apps
* 9M+ downloads
* Deployed across 6+ countries

---

# Repository Structure

Typical structure used in iOS repositories:

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
├── Services/
│   ├── API
│   ├── Firebase
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

# Architecture Guidelines

Primary architecture:

**MVVM + Coordinator**

### Responsibilities

View

* UI rendering
* user interaction

ViewModel

* business logic
* state management
* data transformation

Coordinator

* navigation logic
* screen transitions

Service Layer

* networking
* database access
* API communication

Flow example:

```
View → ViewModel → Service → API
```

---

# Swift Coding Standards

Use modern Swift best practices.

### Rules

* Prefer `struct` over `class`
* Use value semantics where possible
* Avoid force unwrap (`!`)
* Write clear and descriptive names
* Use type safety
* Prefer protocol-oriented design

### Example

```swift
protocol WalletServiceProtocol {
    func fetchBalance() async throws -> Balance
}
```

---

# SwiftUI Development Rules

SwiftUI views must remain declarative.

Guidelines:

* Keep business logic in ViewModels
* Use `@StateObject` for ViewModel ownership
* Avoid heavy logic inside Views
* Maintain small reusable components

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

UIKit modules must follow MVVM.

Guidelines:

* Keep ViewControllers lightweight
* Move logic into ViewModels
* Avoid large controllers

Recommended maximum size:

**500 lines per ViewController**

---

# Combine Usage

Combine is used for:

* reactive state binding
* async event streams
* UI updates

Example:

```swift
viewModel.$balance
    .receive(on: DispatchQueue.main)
    .sink { value in
        self.balanceLabel.text = value
    }
```

---

# Dependency Management

Preferred dependency manager:

**Swift Package Manager (SPM)**

Guidelines:

* Avoid unnecessary dependencies
* Prefer lightweight libraries
* Extract reusable code into packages

---

# Security Guidelines

Never commit:

* API keys
* private certificates
* tokens
* `.env` files
* credentials

Secrets must be stored using:

* secure environment configuration
* encrypted storage
* server-side configuration

---

# Git Workflow

Branching strategy:

main
Stable production code

develop
Active development

feature/*
New features

fix/*
Bug fixes

Examples:

```
feature/wallet-module
feature/payment-api
fix/login-crash
```

---

# Commit Message Standards

Use structured commit messages.

Format:

```
type: short description
```

Examples:

```
feat: add wallet balance API integration
fix: resolve crash on login screen
refactor: improve networking layer
docs: update README
```

Commit types:

* feat
* fix
* refactor
* docs
* test
* chore

---

# Pull Request Guidelines

All pull requests must:

1. Use a feature branch
2. Provide a clear description
3. Pass build checks
4. Follow architecture rules

Example PR template:

```
## Description

Explain what was changed.

## Type

Feature / Bug Fix / Refactor

## Testing

Explain how the change was verified.
```

---

# Performance Guidelines

Applications must remain:

* responsive
* memory efficient
* optimized for launch time

Rules:

* Avoid heavy operations on the main thread
* Use background queues
* Profile using Instruments when needed

---

# Testing Requirements

Before merging code:

* ensure project builds successfully
* run unit tests
* verify UI functionality

Preferred frameworks:

* XCTest
* Swift Testing (WWDC24)

---

# AI Agent Instructions

AI agents interacting with this repository must:

1. Understand project structure before editing files
2. Follow MVVM + Coordinator architecture
3. Avoid modifying stable core modules unnecessarily
4. Write readable and maintainable Swift code
5. Add documentation for complex logic
6. Follow best reusable code practices

Agents must prioritize:

* stability
* maintainability
* performance
* security

---

# Contribution Workflow

1. Fork the repository
2. Create a feature branch
3. Implement the feature
4. Add tests
5. Submit a pull request

---

# Maintainer Contact

Satish
Senior iOS Engineer

Portfolio
https://satish24sp.github.io

GitHub
https://github.com/Satish24sp

Medium
https://medium.com/@satish24sp

LinkedIn
https://linkedin.com/in/satish-iosdev
