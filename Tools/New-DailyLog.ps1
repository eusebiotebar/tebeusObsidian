<# 
.SYNOPSIS
Genera daily log para Obsidian usando la plantilla con encoding correcto.
#>
param(
  [string]$VaultRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$LogsPath = "02-Daily-Logs"
)

$utf8 = [System.Text.UTF8Encoding]::new($true)
$LogsDir = Join-Path -Path $VaultRoot -ChildPath $LogsPath
if (-not (Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir | Out-Null }

$Today = (Get-Date).ToString("yyyy-MM-dd")
$TodayPath = Join-Path -Path $LogsDir -ChildPath "$Today.md"
if (Test-Path $TodayPath) { Remove-Item -Path $TodayPath -Force }

# Build template with proper UTF-8 encoding using UTF8.GetString with byte arrays
# This avoids the [char] concatenation bug in PowerShell
$byte81 = [byte[]](0xC3, 0x81)  # Á
$byteAD = [byte[]](0xC3, 0xAD) # í
$byteB3 = [byte[]](0xC3, 0xB3) # ó

$char81 = [System.Text.Encoding]::UTF8.GetString($byte81)
$charAD = [System.Text.Encoding]::UTF8.GetString($byteAD)
$charB3 = [System.Text.Encoding]::UTF8.GetString($byteB3)

$EstadoAnimo = "Estado de " + $char81 + "nimo"
$ResumenDia = "Resumen del D" + $charAD + "a"
$Reflexion = "Reflexi" + $charB3 + "n"

# Build the content line by line
$lines = @()
$lines += "---"
$lines += "title: Daily Log $Today"
$lines += "date: $Today"
$lines += "tags:"
$lines += "  - daily-log"
$lines += "  - $Today"
$lines += "status: draft"
$lines += "---"
$lines += ""
$lines += "# Daily Log $Today"
$lines += ""
$lines += "## $EstadoAnimo"
$lines += "[emoji]"
$lines += ""
$lines += "## $ResumenDia"
$lines += ""
$lines += ""
$lines += "## Tareas Completadas"
$lines += "- [ ]"
$lines += ""
$lines += "## Tareas Pendientes"
$lines += "- [ ]"
$lines += ""
$lines += "## Notas"
$lines += ""
$lines += ""
$lines += "## Reuniones"
$lines += ""
$lines += ""
$lines += "## $Reflexion"
$lines += ""
$lines += ""
$lines += "## Seguimiento"
$lines += "### $Today"
$lines += "Creado automaticamente."

$content = $lines -join "`n"
[System.IO.File]::WriteAllText($TodayPath, $content, $utf8)
Write-Host "Daily creado con fallback (UTF-8 BOM)"

# Copy yesterday's tasks from the LAST daily (skip weekends/empty days)
$allDailies = Get-ChildItem -Path $LogsDir -Filter "*.md" | Where-Object { $_.Name -ne "$Today.md" } | Sort-Object LastWriteTime -Descending

$lastDaily = $null
foreach ($d in $allDailies) {
  $dContent = [System.IO.File]::ReadAllText($d.FullName, $utf8)
  $dLines = $dContent -split "`r?`n"
  $hasPending = ($dLines | Where-Object { $_ -match '^\- \[ \] ' } | Measure-Object).Count
  if ($hasPending -gt 0) {
    $lastDaily = $d
    break
  }
}

$importTasks = @()
if ($lastDaily) {
  $yContent = [System.IO.File]::ReadAllText($lastDaily.FullName, $utf8)
  $yLines = $yContent -split "`r?`n"
  $importTasks = $yLines | Where-Object { $_ -match '^\- \[ \] ' }
  Write-Host ("Tareas encontradas en ultimo daily ({0}): {1}" -f $lastDaily.Name, $importTasks.Count)
}

if ($importTasks.Count -gt 0 -and (Test-Path $TodayPath)) {
  $content = [System.IO.File]::ReadAllText($TodayPath, $utf8)
  if ($null -ne $content -and $content.Length -gt 0) {
    $header = "## Tareas Pendientes"
    $idxHeader = $content.IndexOf($header)
    if ($idxHeader -ge 0) {
      $afterHeader = $content.Substring($idxHeader)
      $nl = $afterHeader.IndexOf("`n")
      if ($nl -gt 0) {
        $insertPos = $idxHeader + $nl + 1
        if ($insertPos -le $content.Length) {
          $insertBlock = ($importTasks -join "`n") + "`n"
          $newContent = $content.Substring(0, $insertPos) + $insertBlock + $content.Substring($insertPos)
          [System.IO.File]::WriteAllText($TodayPath, $newContent, $utf8)
          Write-Host ("Insertadas {0} tareas pendientes" -f $importTasks.Count)
        }
      }
    }
  }
}

# Enlace al Daily anterior
$LastDaily = $allDailies | Select-Object -First 1
if ($LastDaily) {
  $linkLine = "`n## Enlace al Daily anterior`n- [[02-Daily-Logs/$($LastDaily.Name)]]`n"
  [System.IO.File]::AppendAllText($TodayPath, $linkLine, $utf8)
  Write-Host "Enlace al daily anterior: $($LastDaily.Name)"
}

Write-Host "Daily generado: $TodayPath"
