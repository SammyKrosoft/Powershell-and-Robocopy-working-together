Here’s the updated **README in Markdown** with a **GUI screenshot placeholder** and a **sample log file snippet** for better visual appeal:

***

# 📂 Folder Synchroniser (PowerShell + Robocopy)

## ✅ Overview

This PowerShell script provides a **graphical interface (Windows Forms)** to synchronise two folders using **Robocopy**.  
It’s ideal for backups, folder mirroring, and advanced copy operations with user-friendly controls.

***

## ✨ Features

*   **GUI for Source & Destination selection**
*   Creates a **subfolder in Destination** named after Source
*   **Mirror mode (/MIR)** or **Copy-only mode (/E)**
*   **Optional log file** (auto-generated if blank)
*   **Progress bar & live file updates**
*   **Cancel button** to stop sync mid-run
*   **Persistence** of last settings (folders, checkboxes, thread count)
*   **Multi-threading support** with custom thread count (/MT)
*   Auto log naming:  
    `RoboCopyLog_yyyy-MM-dd_HH-mm-ss.log`

***

## ✅ Prerequisites

*   **Windows OS** (Robocopy is built-in)
*   **PowerShell 5.1 or later**
*   Run as **Administrator** if syncing protected folders

***

## ▶️ How to Run

1.  **Download the script**:  
    Save the `.ps1` file to your local machine.
2.  **Unblock the script** (if downloaded from the internet):
    ```powershell
    Unblock-File -Path "C:\Path\To\FolderSync.ps1"
    ```
3.  **Run the script in PowerShell**:
    ```powershell
    powershell.exe -ExecutionPolicy Bypass -File "C:\Path\To\FolderSync.ps1"
    ```
4.  **Use the GUI**:
    *   Select **Source** and **Destination** folders.
    *   Choose **Mirror** or **Copy-only** mode.
    *   Enable **Multi-threading** and set thread count (optional).
    *   Click **Synchronise**.

***

## ✅ Example Usage

### Mirror mode with multi-threading:

*   Check **Mirror (Deletes extra files)**.
*   Enable **Multi-threading**, set threads to `32`.
*   Leave log file blank → auto log created in destination subfolder.

### Safe copy without deletion:

*   Leave **Mirror** unchecked.
*   Disable multi-threading.
*   Specify a custom log file path if needed.

***

## 🖼 GUI Screenshot

<placeholder for later>

*(Replace the placeholder with an actual screenshot of the running script GUI.)*

***

## 📄 Sample Log File Snippet

```text
-------------------------------------------------------------------------------
   ROBOCOPY     ::     Robust File Copy for Windows
-------------------------------------------------------------------------------

Started : Mon Oct 20 14:35:12 2025

Source : C:\SourceFolder\
Dest   : D:\Backup\SourceFolder\

Files : *.*

Options : /MIR /R:2 /W:5 /LOG:D:\Backup\SourceFolder\RoboCopyLog_2025-10-20_14-35-12.log /MT:16

-------------------------------------------------------------------------------
   New File          example.txt
   New File          report.docx
   New Dir           Images
   New File          Images\photo1.jpg
-------------------------------------------------------------------------------

Total    Copied   Skipped  Mismatch    FAILED    Extras
Dirs :         3         3         0         0         0         0
Files:        10        10         0         0         0         0
Bytes:   1.23 m   1.23 m         0         0         0         0
Times:   0:00:02   0:00:02                       0:00:00   0:00:00

Ended : Mon Oct 20 14:35:14 2025
```

***

## ⚠️ Notes

*   Default retry and wait settings: `/R:2 /W:5`.
*   Cancel button stops Robocopy immediately.
*   Settings persist for next run.

***

✅ This README is **GitHub-ready**.  
Would you like me to **also provide the actual GUI screenshot template (PowerShell running)** so you can capture and upload easily? Or keep the placeholder?
