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
sequenceDiagram
    participant User
    participant Script
    participant BitLocker

    User->>Script: Run bitlocker.cmd
    Script->>BitLocker: Check available drives
    BitLocker-->>Script: Return list of drives
    Script->>User: Display list of available drives
    User->>Script: Select a drive
    Script->>BitLocker: Validate selected drive
    BitLocker-->>Script: Return validation result
    alt Valid drive
        Script->>BitLocker: Check BitLocker status
        BitLocker-->>Script: Return BitLocker status
        alt BitLocker not enabled
            Script->>BitLocker: Enable BitLocker with AES-256 encryption
            BitLocker-->>Script: Return encryption status
            Script->>User: Display encryption status
        else BitLocker enabled
            Script->>BitLocker: Check encryption method
            BitLocker-->>Script: Return encryption method
            Script->>BitLocker: Check if TPM is used
            BitLocker-->>Script: Return TPM status
            Script->>BitLocker: Check partition information
            BitLocker-->>Script: Return partition information
            Script->>User: Display BitLocker status and details
        end
    else Invalid drive
        Script->>User: Display "Invalid drive selected"
    end
```