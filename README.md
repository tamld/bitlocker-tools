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
journey
    title BitLocker Script Workflow
    section Start
      User: 5: Run bitlocker.cmd
    section Check Drives
      Script: 5: Check available drives
      BitLocker: 5: Return list of drives
      Script: 5: Display list of available drives
      User: 5: Select a drive
      Script: 5: Validate selected drive
      BitLocker: 5: Return validation result
    section Valid Drive
      Script: 5: Check BitLocker status
      BitLocker: 5: Return BitLocker status
      Script: 5: Prompt for encryption method
      User: 5: Select encryption method
      Script: 5: Enable BitLocker with selected encryption method
      BitLocker: 5: Return encryption status
      Script: 5: Display encryption status
    section BitLocker Enabled
      Script: 5: Check encryption method
      BitLocker: 5: Return encryption method
      Script: 5: Check if TPM is used
      BitLocker: 5: Return TPM status
      Script: 5: Check partition information
      BitLocker: 5: Return partition information
      Script: 5: Display BitLocker status and details
      User: 5: Perform decryption
      Script: 5: Decrypt drive
      BitLocker: 5: Return decryption status
      Script: 5: Display decryption status
    section Invalid Drive
      Script: 5: Display "Invalid drive selected"
```