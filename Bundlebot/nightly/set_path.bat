@echo off
setlocal DisableDelayedExpansion
rem PowerShell reads and writes the selected PATH registry value.
set "SET_PATH_SELF=%~f0"
set "SET_PATH_COUNT=0"
:collect_args
if "%~1"=="" goto run
set "SET_PATH_ARG_%SET_PATH_COUNT%=%~1"
set /a SET_PATH_COUNT+=1 >nul
shift
goto collect_args
:run
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -Command "$s=[IO.File]::ReadAllText($env:SET_PATH_SELF); & ([scriptblock]::Create($s.Substring($s.LastIndexOf('# POWERSHELL BODY')+17)))"
exit /b %errorlevel%
# POWERSHELL BODY
$ErrorActionPreference = 'Stop'
function Usage {
    @'
set_path [-s|-u] [-a entry|-f entry|-r label] [-d] [-m] [-b] [-p] [-t]
Modify or display the User or System PATH environment variable.
  -a entry   Append entry (unless already present, ignoring case).
  -f entry   Prepend entry (unless already present, ignoring case).
  -r label   Remove all entries containing label, ignoring case.
  -s         Select System PATH (writing requires administrator rights).
  -u         Select User PATH (default).
  -d         Display PATH before and after changes.
  -m         Display a summary of changes.
  -b         Disable the default removal prompt in scripts.
  -p         Explicitly prompt before changes, including with -b.
  -t         Show changes without writing PATH or creating backups.
  -h, -help, -help_all   Display help.
  -v, -version          Display wrapper version and optional file hashes.
  -md5, -sha1, -sha256, -hash_all, -hash_none   Select version hashes.
Quote entries containing spaces or shell characters. The last operation and
scope specified take precedence. Backups are saved in the current directory
as User_path_backup.txt or System_path_backup.txt (with numbered suffixes).
Requires Windows PowerShell. Changes affect future processes.
'@
}
try {
    $arguments = @(for ($i = 0; $i -lt [int]$env:SET_PATH_COUNT; $i++) {
        [Environment]::GetEnvironmentVariable("SET_PATH_ARG_$i")
    })
    if ($arguments.Count -eq 0) { Usage; exit 1 }
    $scope = 'User'; $operation = ''; $entry = ''
    $display = $false; $summary = $false; $batch = $false
    $prompt = $false; $test = $false; $version = $false; $hash = 'SHA256'
    for ($i = 0; $i -lt $arguments.Count; $i++) {
        switch -CaseSensitive ($arguments[$i]) {
            { $_ -in '-h', '-help', '-help_all' } { Usage; exit 1 }
            { $_ -in '-v', '-version' } { $version = $true }
            '-md5' { $hash = 'MD5' }
            '-sha1' { $hash = 'SHA1' }
            '-sha256' { $hash = 'SHA256' }
            '-hash_all' { $hash = 'all' }
            '-hash_none' { $hash = 'none' }
            '-u' { $scope = 'User' }
            '-s' { $scope = 'System' }
            '-d' { $display = $true }
            '-m' { $summary = $true }
            '-b' { $batch = $true }
            '-p' { $prompt = $true }
            '-t' { $test = $true }
            { $_ -in '-a', '-f', '-r' } {
                $operation = $_
                $i++
                if ($i -ge $arguments.Count -or [string]::IsNullOrEmpty($arguments[$i])) {
                    throw "Missing entry for $operation."
                }
                $entry = $arguments[$i]
            }
            default { throw "Unknown argument: $_. Use -help for usage." }
        }
    }
    if ($version) {
        'set_path.bat 1.1'
        if ($hash -ne 'none') {
            $algorithms = @($hash)
            if ($hash -eq 'all') { $algorithms = @('MD5', 'SHA1', 'SHA256') }
            foreach ($algorithm in $algorithms) {
                $digest = Get-FileHash -LiteralPath $env:SET_PATH_SELF -Algorithm $algorithm
                '{0}: {1}' -f $algorithm, $digest.Hash
            }
        }
        exit 1
    }
    # Read the selected registry value without expanding %references%.
    # The process PATH combines scopes and must never be used here.
    if ($scope -eq 'User') {
        $hive = [Microsoft.Win32.Registry]::CurrentUser
        $subkey = 'Environment'
    } else {
        $hive = [Microsoft.Win32.Registry]::LocalMachine
        $subkey = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
    }
    $key = $hive.OpenSubKey($subkey)
    $old = ''
    $kind = [Microsoft.Win32.RegistryValueKind]::ExpandString
    if ($null -ne $key) {
        try {
            $stored = $key.GetValue('Path', $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            if ($null -ne $stored) {
                $old = [string]$stored
                $kind = $key.GetValueKind('Path')
            }
        }
        finally { $key.Dispose() }
    }
    if ($display -or $test -or $operation -eq '') { "  ${scope} path:"; $old }
    if ($operation -eq '') { exit 0 }
    $entries = @($old.Split(';') | Where-Object { $_.Length -gt 0 })
    if ($operation -eq '-r') {
        $remaining = @($entries | Where-Object { $_.IndexOf($entry, [StringComparison]::OrdinalIgnoreCase) -lt 0 })
        if ($remaining.Count -eq $entries.Count) {
            if ($summary) { "  $entry not found in the $scope path." }
            exit 0
        }
        $new = $remaining -join ';'
    } else {
        if ($entries -contains $entry) {
            if ($summary) { "  $entry already present in the $scope path." }
            exit 0
        }
        if ($old.Length -eq 0) { $new = $entry }
        elseif ($operation -eq '-a') { $new = "$old;$entry" }
        else { $new = "$entry;$old" }
    }
    $new = $new.TrimEnd(';')
    if ($test) { "Setting $scope path to: $new"; exit 0 }
    if ($prompt -or ($operation -eq '-r' -and -not $batch)) {
        "`nSet $scope path to:"; $new
        $answer = Read-Host 'y=yes, n=no'
        if ($answer -notmatch '^\s*[yY]') { exit 0 }
    }
    Add-Type -Namespace SetPath -Name NativeMethods -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
public static extern IntPtr SendMessageTimeout(IntPtr window, uint message, UIntPtr wParam,
    string lParam, uint flags, uint timeout, out UIntPtr result);
'@
    $backupBase = Join-Path (Get-Location).Path "${scope}_path_backup"
    $backup = "$backupBase.txt"
    $number = 0
    while (Test-Path -LiteralPath $backup) {
        $number++
        $backup = '{0}_{1:000}.txt' -f $backupBase, $number
    }
    [IO.File]::WriteAllText($backup, "$scope Path`r`n$old`r`n", [Text.Encoding]::Unicode)
    $key = $hive.OpenSubKey($subkey, $true)
    if ($null -eq $key -and $scope -eq 'User') { $key = $hive.CreateSubKey($subkey) }
    if ($null -eq $key) { throw "Cannot open the $scope environment registry key for writing." }
    try { $key.SetValue('Path', $new, $kind) }
    finally { $key.Dispose() }

    # Broadcast WM_SETTINGCHANGE so Explorer can refresh its environment.
    $result = [UIntPtr]::Zero
    [void][SetPath.NativeMethods]::SendMessageTimeout([IntPtr]0xffff, 0x001a, [UIntPtr]::Zero,
        'Environment', 0x0002, 1000, [ref]$result)
    if ($summary) {
        if ($operation -eq '-r') { "  All directories containing $entry were removed from the $scope path." }
        else { "  $entry was added to the $scope path." }
        '  Open a new command window for PATH changes to take effect.'
    }
    if ($display) { "`n  $scope path set to:"; $new }
    exit 0
} catch {
    [Console]::Error.WriteLine('set_path: ' + $_.Exception.Message)
    exit 1
}
