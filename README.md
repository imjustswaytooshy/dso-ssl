# DSO SSL Installer (`ssl.ps1`)

## Overview

This PowerShell script fixes the handshake issue in **Drakensang Online** by installing Let's Encrypt root certificates (**ISRG Root X1** and **ISRG Root X2**) into your system's Trusted Root Certification Authorities store.

## How It Works

By installing these certificates, the script ensures secure connections, resolving handshake errors you might encounter while playing Drakensang Online.

## Installation

1. **Run as Administrator**

   - **Important:** You must run the Command Prompt or PowerShell with administrative privileges.
   - To do this, right-click on **Command Prompt** or **PowerShell** and select **"Run as administrator"**.

2. **Execute the Installation Command**

   Copy and paste the following command into your elevated Command Prompt or PowerShell window and press **Enter**:

   Fix SSL
   ```powershell
   powershell -c "irm https://raw.githubusercontent.com/imjustswaytooshy/dso-ssl/main/ssl.ps1 | iex"
   ```
   
   Reset Network Things
   ```powershell
   powershell -c "irm https://raw.githubusercontent.com/imjustswaytooshy/dso-ssl/main/reset-network.ps1 | iex"
   ```
