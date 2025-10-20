
<#
.SYNOPSIS
    Folder Synchroniser with GUI using Robocopy.

.DESCRIPTION
    This PowerShell script provides a graphical interface (Windows Forms) to synchronise two folders using Robocopy.
    It includes advanced options for flexibility and performance, making it ideal for backup or folder mirroring tasks.

.FEATURES
    - GUI for selecting Source and Destination folders.
    - Creates a subdirectory in the Destination named after the Source folder.
    - Option to choose between:
        * Mirror mode (/MIR) – deletes extra files in destination.
        * Copy-only mode (/E) – keeps extra files in destination.
    - Optional log file:
        * If not specified, automatically creates a log file in the destination subfolder.
        * Log file name format: RoboCopyLog_yyyy-MM-dd_HH-mm-ss.log.
    - Progress bar and live status updates showing current file being copied.
    - Cancel button to stop Robocopy mid-run.
    - Persistence of last chosen Source, Destination, checkbox states, and thread count.
    - Multi-threading support:
        * Checkbox to enable multi-threading.
        * Customisable thread count (/MT:<threads>) for faster performance.
    - Default retry and wait settings (/R:2 /W:5) for quick error handling.

.EXAMPLE
    Scenario 1: Mirror mode with multi-threading
        - Select Source and Destination folders.
        - Check "Mirror (Deletes extra files)" to make destination identical to source.
        - Enable "Multi-threading" and set Threads to 32 for high-speed sync.
        - Leave Log File blank to auto-create a timestamped log in the destination subfolder.
        - Click "Synchronise" to start.

    Scenario 2: Safe copy without deletion
        - Select Source and Destination folders.
        - Leave "Mirror" unchecked (uses /E).
        - Disable multi-threading for standard copy.
        - Specify a custom log file path if needed.
        - Click "Synchronise" to start.

.NOTES
    Author: [Your Name]
    Requires: PowerShell 5.1 or later, Robocopy (built into Windows)
    Run as Administrator if syncing protected folders.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web.Extensions  # For JSON serialization

# Config file path for persistence
$configFile = "$env:USERPROFILE\folderSyncSettings.json"

# Load previous settings if available
$previousSettings = @{
    SourceFolder = ""
    DestFolder = ""
    MirrorChecked = $false
    MultiThreadChecked = $false
    ThreadCount = "16"
}
if (Test-Path $configFile) {
    $json = Get-Content $configFile -Raw
    $previousSettings = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).DeserializeObject($json)
}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Folder Synchroniser"
$form.Size = New-Object System.Drawing.Size(550, 540)
$form.StartPosition = "CenterScreen"

# Labels
$labelSource = New-Object System.Windows.Forms.Label
$labelSource.Text = "Source Folder:"
$labelSource.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($labelSource)

$labelDest = New-Object System.Windows.Forms.Label
$labelDest.Text = "Destination Folder:"
$labelDest.Location = New-Object System.Drawing.Point(10, 70)
$form.Controls.Add($labelDest)

$labelLog = New-Object System.Windows.Forms.Label
$labelLog.Text = "Log File Path (optional):"
$labelLog.Location = New-Object System.Drawing.Point(10, 120)
$form.Controls.Add($labelLog)

# Textboxes
$textSource = New-Object System.Windows.Forms.TextBox
$textSource.Location = New-Object System.Drawing.Point(150, 20)
$textSource.Width = 300
$textSource.Text = $previousSettings.SourceFolder
$form.Controls.Add($textSource)

$textDest = New-Object System.Windows.Forms.TextBox
$textDest.Location = New-Object System.Drawing.Point(150, 70)
$textDest.Width = 300
$textDest.Text = $previousSettings.DestFolder
$form.Controls.Add($textDest)

$textLog = New-Object System.Windows.Forms.TextBox
$textLog.Location = New-Object System.Drawing.Point(150, 120)
$textLog.Width = 300
$form.Controls.Add($textLog)

# Browse buttons
$browseSource = New-Object System.Windows.Forms.Button
$browseSource.Text = "Browse"
$browseSource.Location = New-Object System.Drawing.Point(460, 20)
$form.Controls.Add($browseSource)

$browseDest = New-Object System.Windows.Forms.Button
$browseDest.Text = "Browse"
$browseDest.Location = New-Object System.Drawing.Point(460, 70)
$form.Controls.Add($browseDest)

$browseLog = New-Object System.Windows.Forms.Button
$browseLog.Text = "Browse"
$browseLog.Location = New-Object System.Drawing.Point(460, 120)
$form.Controls.Add($browseLog)

# Dialogs
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$fileDialog = New-Object System.Windows.Forms.SaveFileDialog
$fileDialog.Filter = "Log files (*.log)|*.log"

$browseSource.Add_Click({ if ($folderDialog.ShowDialog() -eq "OK") { $textSource.Text = $folderDialog.SelectedPath } })
$browseDest.Add_Click({ if ($folderDialog.ShowDialog() -eq "OK") { $textDest.Text = $folderDialog.SelectedPath } })
$browseLog.Add_Click({ if ($fileDialog.ShowDialog() -eq "OK") { $textLog.Text = $fileDialog.FileName } })

# Checkboxes and thread input
$checkMirror = New-Object System.Windows.Forms.CheckBox
$checkMirror.Text = "Mirror (Deletes extra files)"
$checkMirror.Location = New-Object System.Drawing.Point(150, 160)
$checkMirror.Checked = [bool]$previousSettings.MirrorChecked
$form.Controls.Add($checkMirror)

$checkMT = New-Object System.Windows.Forms.CheckBox
$checkMT.Text = "Enable Multi-threading"
$checkMT.Location = New-Object System.Drawing.Point(150, 190)
$checkMT.Checked = [bool]$previousSettings.MultiThreadChecked
$form.Controls.Add($checkMT)

$labelThreads = New-Object System.Windows.Forms.Label
$labelThreads.Text = "Threads:"
$labelThreads.Location = New-Object System.Drawing.Point(300, 190)
$form.Controls.Add($labelThreads)

$textThreads = New-Object System.Windows.Forms.TextBox
$textThreads.Location = New-Object System.Drawing.Point(360, 188)
$textThreads.Width = 50
$textThreads.Text = $previousSettings.ThreadCount
$form.Controls.Add($textThreads)

# Progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 380)
$progressBar.Size = New-Object System.Drawing.Size(500, 25)
$progressBar.Style = 'Marquee'
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

# Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Status: Waiting"
$statusLabel.Location = New-Object System.Drawing.Point(20, 410)
$statusLabel.AutoSize = $true
$form.Controls.Add($statusLabel)

# Buttons
$syncButton = New-Object System.Windows.Forms.Button
$syncButton.Text = "Synchronise"
$syncButton.Location = New-Object System.Drawing.Point(150, 250)
$form.Controls.Add($syncButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.Location = New-Object System.Drawing.Point(280, 250)
$cancelButton.Enabled = $false
$form.Controls.Add($cancelButton)

# Variables
$process = $null

# Action on Sync click
$syncButton.Add_Click({
    $source = $textSource.Text
    $dest = $textDest.Text
    $manualLogPath = $textLog.Text

    if ([string]::IsNullOrWhiteSpace($source) -or [string]::IsNullOrWhiteSpace($dest)) {
        [System.Windows.Forms.MessageBox]::Show("Please select both folders.", "Error")
    } else {
        # Save settings for next run
        $settings = @{
            SourceFolder = $source
            DestFolder = $dest
            MirrorChecked = $checkMirror.Checked
            MultiThreadChecked = $checkMT.Checked
            ThreadCount = $textThreads.Text
        }
        $jsonOut = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).Serialize($settings)
        Set-Content -Path $configFile -Value $jsonOut

        # Prepare destination subfolder
        $sourceName = Split-Path $source -Leaf
        $newDest = Join-Path $dest $sourceName
        if (-not (Test-Path $newDest)) { New-Item -ItemType Directory -Path $newDest | Out-Null }

        # Robocopy options
        $options = if ($checkMirror.Checked) { "/MIR" } else { "/E" }
        $mtOption = ""
        if ($checkMT.Checked -and [int]::TryParse($textThreads.Text, [ref]$null)) {
            $mtOption = "/MT:$($textThreads.Text)"
        }

        # Determine log file path
        if ([string]::IsNullOrWhiteSpace($manualLogPath)) {
            $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
            $logPath = Join-Path $newDest "RoboCopyLog_$timestamp.log"
        } else {
            $logPath = $manualLogPath
        }
        $logOption = "/LOG:`"$logPath`""

        # Build command
        $cmd = "robocopy `"$source`" `"$newDest`" $options /R:2 /W:5 $logOption $mtOption"

        # Show progress
        $progressBar.Visible = $true
        $statusLabel.Text = "Status: Synchronisation in progress..."
        $cancelButton.Enabled = $true
        $form.Refresh()

        # Run Robocopy and capture output
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "cmd.exe"
        $processInfo.Arguments = "/c $cmd"
        $processInfo.RedirectStandardOutput = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null

        while (-not $process.HasExited) {
            $line = $process.StandardOutput.ReadLine()
            if ($line -and $line.Trim() -ne "") {
                if ($line -match "^\s{0,3}\S") {
                    $statusLabel.Text = "Copying: $line"
                    $form.Refresh()
                }
            }
        }

        $progressBar.Visible = $false
        $cancelButton.Enabled = $false
        $statusLabel.Text = "Status: Completed"
        [System.Windows.Forms.MessageBox]::Show("Synchronisation completed.`nLog saved at: $logPath", "Info")
    }
})

# Action on Cancel click
$cancelButton.Add_Click({
    if ($process -and -not $process.HasExited) {
        $process.Kill()
        $progressBar.Visible = $false
        $cancelButton.Enabled = $false
        $statusLabel.Text = "Status: Cancelled"
        [System.Windows.Forms.MessageBox]::Show("Synchronisation cancelled.", "Info")
    }
})

$form.Topmost = $true
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
