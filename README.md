<h1 align="center"> BitLocker Tools </h1>

<p align="center">
  <img src="https://img.shields.io/badge/status-active-brightgreen" alt="Status">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="License">
</p>
<p align="center">
  <img src="https://img.shields.io/github/forks/tamld/bitlocker-tools.svg">
  <img src="https://img.shields.io/github/stars/tamld/bitlocker-tools.svg">
  <img src="https://img.shields.io/github/followers/tamld.svg?style=social&label=Follow&maxAge=2592000">
</p>

## Introduction

The BitLocker Tools provide a set of utilities to manage BitLocker encryption on Windows systems. These tools help you enable, disable, and manage BitLocker encryption on your drives with ease.

## Workflow
```mermaid
flowchart TD
    A[Run bitlocker.cmd] --> B[Check available drives]
    B --> C[Return list of drives]
    C --> D[Display list of available drives]
    D --> E[Select a drive]
    E --> F[Validate selected drive]
    F --> G{Valid drive?}
    G -->|Yes| H[Check BitLocker status]
    G -->|No| I[Display Invalid drive selected]
    H --> J{BitLocker enabled?}
    J -->|No| K[Prompt for encryption method]
    K --> L[Select encryption method]
    L --> M[Enable BitLocker with selected encryption method]
    M --> N[Return encryption status]
    N --> O[Display encryption status]
    J -->|Yes| P[Check encryption method]
    P --> Q[Return encryption method]
    Q --> R[Check if TPM is used]
    R --> S[Return TPM status]
    S --> T[Check partition information]
    T --> U[Return partition information]
    U --> V[Display BitLocker status and details]
    V --> W[Perform decryption]
    W --> X[Decrypt drive]
    X --> Y[Return decryption status]
    Y --> Z[Display decryption status]
```