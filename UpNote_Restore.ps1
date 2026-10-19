$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
$dialog.Description = 'UpNote TXT Restore - select the folder containing links'
$dialog.ShowNewFolderButton = $false

if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit }

$root = $dialog.SelectedPath
$logPath = Join-Path $root 'UpNote_restore_log.txt'
$ws = New-Object -ComObject WScript.Shell

$copied = 0; $skipped = 0; $issues = 0; $deleted = 0
$log = New-Object System.Collections.Generic.List[string]

$log.Add("UpNote TXT Restore")
$log.Add("Root: $root")
$log.Add("Started: $((Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))")
$log.Add("")

$links = @(Get-ChildItem -LiteralPath $root -Filter '*.lnk' -File -Recurse -ErrorAction SilentlyContinue)

foreach ($link in $links) {
    try {
        $shortcut = $ws.CreateShortcut($link.FullName)
        $target   = $shortcut.TargetPath

        if ([string]::IsNullOrWhiteSpace($target) -or
            -not (Test-Path -LiteralPath $target -PathType Leaf)) {
            $issues++
            $log.Add("[MISSING] $($link.FullName) -> $target")
            continue
        }

        $dest    = Join-Path $link.DirectoryName ([IO.Path]::GetFileName($target))
        $srcFull = [IO.Path]::GetFullPath($target)
        $dstFull = [IO.Path]::GetFullPath($dest)

        if ($srcFull.Equals($dstFull, [StringComparison]::OrdinalIgnoreCase)) {
            $skipped++
            $log.Add("[SKIP-SAME] $dest")
            continue
        }

        if (Test-Path -LiteralPath $dest) {
            $issues++
            $log.Add("[CONFLICT] $target | dest: $dest")
            continue
        }

        Copy-Item -LiteralPath $target -Destination $dest
        $copied++
        $log.Add("[COPIED] $target -> $dest")

        Remove-Item -LiteralPath $link.FullName -Force
        $deleted++
        $log.Add("[DELETED-LNK] $($link.FullName)")
    }
    catch {
        $issues++
        $log.Add("[ERROR] $($link.FullName) | $($_.Exception.Message)")
    }
}

$log.Add("")
$log.Add("Copied: $copied")
$log.Add("Skipped: $skipped")
$log.Add("Deleted links: $deleted")
$log.Add("Issues: $issues")
$log | Set-Content -LiteralPath $logPath -Encoding UTF8

[System.Windows.Forms.MessageBox]::Show(
    "Done.`n`nCopied: $copied`nSkipped: $skipped`nDeleted links: $deleted`nIssues: $issues`n`nLog: $logPath",
    'UpNote TXT Restore',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
) | Out-Null