goto eof

:is_cfast_installed
set "cfastinstalled=1"
if exist "%~dp0..\..\cfast\." exit /b 0
where /q cfast.exe
if errorlevel 1 set "cfastinstalled=0"
exit /b 0

:remove_install_path
setlocal
set "FDS_PATH_TO_REMOVE=%~1"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command ^
  "$ErrorActionPreference = 'Stop';" ^
  "$target = [IO.Path]::GetFullPath($env:FDS_PATH_TO_REMOVE).TrimEnd('\');" ^
  "$comparison = [StringComparison]::OrdinalIgnoreCase;" ^
  "$keys = @([Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true), [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment', $true));" ^
  "foreach ($key in $keys) {" ^
  "  if ($null -eq $key) { continue };" ^
  "  try {" ^
  "    $old = $key.GetValue('Path', $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames);" ^
  "    if ($null -eq $old) { continue };" ^
  "    $new = ($old.Split(';') | Where-Object {" ^
  "      $entry = [Environment]::ExpandEnvironmentVariables($_.Trim().Trim([char]34));" ^
  "      if ([string]::IsNullOrWhiteSpace($entry) -or -not [IO.Path]::IsPathRooted($entry)) { return $true };" ^
  "      try { $entry = [IO.Path]::GetFullPath($entry).TrimEnd('\') } catch { return $true };" ^
  "      -not ($entry.Equals($target, $comparison) -or $entry.StartsWith($target + '\', $comparison))" ^
  "    }) -join ';';" ^
  "    if ($new -cne $old) { $key.SetValue('Path', $new, $key.GetValueKind('Path')) }" ^
  "  } finally { $key.Dispose() }" ^
  "}"
if errorlevel 1 echo *** WARNING: Could not remove "%FDS_PATH_TO_REMOVE%" from PATH.
endlocal
exit /b

:eof
