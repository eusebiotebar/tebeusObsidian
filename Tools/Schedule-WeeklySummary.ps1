<# 
.SYNOPSIS
Registra la tarea programada para ejecutar WeeklySummary.ps1 los viernes a las 14:00.
#>
$TaskName = "ObsidianWeeklySummary"
$ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "WeeklySummary.ps1"

if (-not (Test-Path $ScriptPath)) {
  Write-Host "Script no encontrado: $ScriptPath" -ForegroundColor Red
  exit 1
}

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
  Write-Host "Scheduled task '$TaskName' ya existe. Nada que hacer."
  exit 0
}

$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Friday -At "14:00"
$Principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) `
                                        -LogonType Interactive -RunLevel Highest

try {
  Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal `
                         -Description "Genera resumen semanal de Obsidian cada viernes" -Force
  Write-Host "Tarea '$TaskName' registrada correctamente."
  Write-Host "  Usuario : $($Principal.UserId)"
  Write-Host "  Dia     : Viernes"
  Write-Host "  Hora    : 14:00"
  Write-Host "  Script  : $ScriptPath"
} catch {
  Write-Host "Error al registrar la tarea: $_" -ForegroundColor Red
  exit 1
}
