# AGENTS.md

## Maintainer

**Satish**
Senior iOS Engineer
New Delhi, India 🇮🇳

GitHub: https://github.com/Satish24sp
Portfolio: https://satish24sp.github.io
Medium: https://medium.com/@satish24sp

Experience: **7+ years building large-scale iOS applications**

Impact:

* 15+ shipped iOS apps
* 9M+ downloads
* Apps deployed in 6+ countries
* Fintech, Telecom, EdTech, and Media platforms

---

# Repository Purpose

This repository contains **production-grade iOS applications, libraries, and experiments** focused on:

* scalable mobile architecture
* modern Swift development
* performance optimization
* clean code practices

This file provides instructions for:

* human contributors
* AI coding agents
* automated code tools

---

# AI Agent Behavior Rules

Agents working in this repository must follow these principles.

### Always

* Understand the project structure before modifying files
* Follow existing architecture patterns
* Write readable and maintainable code
* Add documentation when introducing complex logic
* Ensure the project builds successfully after changes

### Never

* Rewrite large modules without clear reason
* Change architecture patterns
* Add heavy dependencies without justification
* Commit secrets or credentials

---

# Project Architecture

The primary architecture used in this repository is:

**MVVM + Coordinator**

### Responsibilities

View
UI rendering and user interaction

ViewModel
business logic and state management

Coordinator
navigation and flow management

Service Layer
networking and data fetching

Example flow:

View → ViewModel → Service → API

---

# Technology Stack

## Language

Swift (primary)
Objective-C (legacy modules)

## Frameworks

UIKit
SwiftUI
Combine
Foundation
CoreData
StoreKit

## Backend & Services

Firebase
AWS
PubNub
REST APIs

## Security

AES-256 encryption
Secure API token handling
Encrypted local storage

## Tools

Xcode
Swift Package Manager
Git
Instruments
Swift Testing (WWDC24)
XCTest

---

# Coding Standards

### Swift Guidelines

Use modern Swift best practices.

Rules:

* Prefer struct over class
* Avoid force unwrap
* Use protocol-oriented programming
* Keep functions small and reusable
* Use descriptive naming

Example:

```swift
protocol WalletServiceProtocol {
    func fetchBalance() async throws -> Balance
}
```

---

# SwiftUI Guidelines

SwiftUI views must remain declarative.

Rules:

* Keep business logic in ViewModels
* Use `@StateObject` for ViewModel ownership
* Avoid heavy logic inside Views
* Use reusable components

Example:

```
struct WalletView: View {

    @StateObject var viewModel: WalletViewModel

    var body: some View {
        Text(viewModel.balanceText)
    }
}
```

---

# UIKit Guidelines

UIKit modules must follow MVVM.

Rules:

* Avoid massive view controllers
* Move logic into ViewModels
* Keep UI code separate from business logic

Recommended:

Max **500 lines per ViewController**

---

# Combine Usage

Combine is used for:

* reactive UI updates
* async event streams
* state binding

Example:

```
viewModel.$balance
    .receive(on: DispatchQueue.main)
    .sink { value in
        self.balanceLabel.text = value
    }
```

---

# Dependency Management

Preferred package manager:

Swift Package Manager

Guidelines:

* Avoid unnecessary dependencies
* Prefer lightweight libraries
* Reuse internal modules where possible

---

# Security Rules

Never commit:

API keys
Private certificates
Access tokens
Secrets
.env files

Secrets must be stored in secure configuration.

---

# Repository Structure

Typical project structure:

```
Project/
│
├── App/
├── Modules/
│   ├── FeatureA
│   ├── FeatureB
│
├── Core/
│   ├── Networking
│   ├── Utilities
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

# Git Workflow

Branch strategy:

main → production code
develop → active development

feature/* → new features
fix/* → bug fixes

Example:

```
feature/wallet-module
fix/login-crash
```

---

# Commit Message Convention

Use structured commits.

Format:

```
type: short description
```

Examples:

```
feat: add wallet balance API
fix: resolve crash on login
refactor: improve networking layer
docs: update documentation
```

Commit types:

feat
fix
refactor
docs
test
chore

---

# Pull Request Rules

All PRs must include:

* clear description
* architecture compliance
* successful build
* tests when applicable

PR template:

```
## Description
Explain the change.

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
* optimized for launch performance

Rules:

* avoid heavy work on main thread
* use background queues
* profile using Instruments

---

# Testing Requirements

Before merging code:

* build must succeed
* run unit tests
* verify UI flows

Testing frameworks:

XCTest
Swift Testing (WWDC24)

---

# AI Code Generation Guidelines

AI agents should:

* generate modular Swift code
* follow MVVM architecture
* create reusable components
* document complex logic
* avoid large monolithic files

When modifying code:

1. analyze current implementation
2. propose minimal changes
3. maintain backward compatibility

---

# Contribution Process

1 Fork repository
2 Create feature branch
3 Implement changes
4 Run tests
5 Submit pull request

---

# Contact

Maintained by:

Satish
Senior iOS Engineer

Portfolio
https://satish24sp.github.io
