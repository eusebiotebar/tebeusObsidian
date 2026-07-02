<# 
.SYNOPSIS
Genera resumen semanal a partir de la plantilla Plantilla-Resumen.md,
agregando datos de los daily logs de la semana.
#>
param(
  [string]$VaultRoot = (Split-Path -Parent $PSScriptRoot),
  [string]$LogsPath = "02-Daily-Logs",
  [string]$SummariesPath = "03-Res$([char]0x00FA)menes",
  [string]$Template = "Plantilla-Resumen",
  [string]$ObsPathCmd = "obsidian",
  [datetime]$Date = (Get-Date)
)

$utf8 = [System.Text.UTF8Encoding]::new($true)

$SummariesDir = Join-Path -Path $VaultRoot -ChildPath $SummariesPath
if (-not (Test-Path $SummariesDir)) { New-Item -ItemType Directory -Path $SummariesDir | Out-Null }

$LogsDir = Join-Path -Path $VaultRoot -ChildPath $LogsPath
$TemplatesDir = Join-Path -Path $VaultRoot -ChildPath "06-Plantillas"

$daysToMonday = [int]$Date.Date.DayOfWeek - [int][DayOfWeek]::Monday
if ($daysToMonday -lt 0) { $daysToMonday += 7 }
$weekStart = $Date.Date.AddDays(-$daysToMonday)
$weekEnd   = $weekStart.AddDays(4)
$dateFmt = "yyyy-MM-dd"

$summaryFile = Join-Path -Path $SummariesDir -ChildPath ("Resumen-Semanal-{0}.md" -f $weekEnd.ToString($dateFmt))
if (Test-Path $summaryFile) { Remove-Item -Path $summaryFile -Force }

# =============================================================================
# Recopilar datos de los dailies de la semana
# =============================================================================
$weekCompleted  = @{ }
$weekPending    = @{ }
$weekHighlights = @()
$weekNotes     = @()
$weekMeetings  = @()

for ($d = 0; $d -lt 5; $d++) {
  $dow = $weekStart.AddDays($d)
  [string]$date = Get-Date $dow -Format "yyyy-MM-dd"
  $dYear = (Get-Date $dow).ToString("yyyy")
  $dMonth = (Get-Date $dow).ToString("yyyy-MM")
  $p = Join-Path -Path $LogsDir -ChildPath "$dYear/$dMonth/$date.md"
  if (-not (Test-Path $p)) { continue }

  $content = [System.IO.File]::ReadAllText($p, $utf8)
  $lines   = $content -split "`r?`n"

  # Resumen del Dia
  $rIdx = -1
  for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match '^## Resumen del') { $rIdx = $i; break }
  }
  if ($rIdx -ge 0) {
    $body = @()
    for ($i = $rIdx + 1; $i -lt $lines.Length; $i++) {
      $l = $lines[$i]
      if ($l -match '^## ' -or $l -match '^# ') { break }
      if ($l.Trim() -and $l.Trim() -ne '- [ ]' -and $l.Trim() -ne '- [ ] ' -and $l.Trim() -ne '-') {
        $body += $l.Trim()
      }
    }
    if ($body.Count -gt 0) {
      $dayLabel = (Get-Date $date).ToString("ddd dd MMM")
      $weekHighlights += ("- **{0}:** {1}" -f $dayLabel, ($body -join " "))
    }
  }

  # Notas / Notes
  $nIdx = -1
  for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match '^## (Notas|Notes)$') { $nIdx = $i; break }
  }
  if ($nIdx -ge 0) {
    for ($i = $nIdx + 1; $i -lt $lines.Length; $i++) {
      $l = $lines[$i].Trim()
      if ($l -match '^## ' -or $l -match '^# ') { break }
      if ($l -and $l -ne '-' -and $l -ne '- [ ]') {
        $weekNotes += $l
      }
    }
  }

  # Reuniones / Meetings
  $mIdx = -1
  for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match '^## (Reuniones|Meetings)$') { $mIdx = $i; break }
  }
  if ($mIdx -ge 0) {
    for ($i = $mIdx + 1; $i -lt $lines.Length; $i++) {
      $l = $lines[$i].Trim()
      if ($l -match '^## ' -or $l -match '^# ') { break }
      if ($l -and $l -ne '-' -and $l -ne '- [ ]') {
        $weekMeetings += $l
      }
    }
  }

  # Tareas completadas (clave = texto normalizado para dedup)
  foreach ($line in $lines) {
    if ($line -match '^- \[x\] (.+)') {
      $key = $matches[1].Trim()
      if ($key -and -not $weekCompleted.ContainsKey($key)) {
        $weekCompleted[$key] = $line.Trim()
      }
    }
  }

  # Tareas pendientes (clave = texto normalizado para dedup)
  foreach ($line in $lines) {
    if ($line -match '^- \[ \] (.+)') {
      $key = $matches[1].Trim()
      if ($key -and -not $weekPending.ContainsKey($key)) {
        $weekPending[$key] = $line.Trim()
      }
    }
  }
}

# =============================================================================
# Construir el resumen usando la plantilla
# =============================================================================
$templatePath = Join-Path -Path $TemplatesDir -ChildPath "Plantilla-Resumen.md"
if (-not (Test-Path $templatePath)) {
  Write-Host "Plantilla no encontrada: $templatePath" -ForegroundColor Red
  Write-Host "Generando con fallback inline." -ForegroundColor Yellow
  $templateContent = $null
} else {
  $templateContent = [System.IO.File]::ReadAllText($templatePath, $utf8)
}

$outputLines = @()

if ($templateContent) {
  $templateLines = $templateContent -split "`r?`n"
  $i = 0

  while ($i -lt $templateLines.Length) {
    $line = $templateLines[$i]

    # Reemplazar placeholders
    $line = $line -replace '\{\{date\}\}', $weekEnd.ToString($dateFmt)
    $line = $line -replace '\{\{title\}\}', ("Resumen Semanal {0}" -f $weekEnd.ToString($dateFmt))
    $line = $line -replace '\{\{start\}\}', $weekStart.ToString($dateFmt)
    $line = $line -replace '\{\{end\}\}',   $weekEnd.ToString($dateFmt)

    # Rellenar Lo Mas Destacado
    if ($line -match '^## Lo M.s Destacado$') {
      $outputLines += $line
      $i++
      if ($i -lt $templateLines.Length -and $templateLines[$i].Trim() -eq '-') { $i++ }
      if ($weekHighlights.Count -gt 0) {
        foreach ($h in $weekHighlights) { $outputLines += $h }
      } else {
        $outputLines += "- (sin resumen del dia)"
      }
      continue
    }

    # Rellenar Tareas Completadas
    if ($line -match '^## Tareas Completadas$') {
      $outputLines += $line
      $i++
      if ($i -lt $templateLines.Length -and $templateLines[$i].Trim() -eq '-') { $i++ }
      if ($weekCompleted.Count -gt 0) {
        foreach ($t in $weekCompleted.Values) { $outputLines += $t }
      } else {
        $outputLines += "- "
      }
      continue
    }

    # Rellenar Objetivos Logrados (= mismas completadas)
    if ($line -match '^## Objetivos Logrados$') {
      $outputLines += $line
      $i++
      if ($i -lt $templateLines.Length -and $templateLines[$i].Trim() -eq '-') { $i++ }
      if ($weekCompleted.Count -gt 0) {
        foreach ($t in $weekCompleted.Values) { $outputLines += $t }
      } else {
        $outputLines += "- "
      }
      continue
    }

    # Rellenar Proximos Pasos (= tareas pendientes)
    if ($line -match '^## Pr.ximos Pasos$') {
      $outputLines += $line
      $i++
      if ($i -lt $templateLines.Length -and $templateLines[$i].Trim() -eq '-') { $i++ }
      if ($weekPending.Count -gt 0) {
        foreach ($t in $weekPending.Values) { $outputLines += $t }
      } else {
        $outputLines += "- "
      }
      continue
    }

    # Rellenar Notas Adicionales (Notas + Reuniones de los dailies)
    if ($line -match '^## Notas Adicionales$') {
      $outputLines += $line
      $i++
      if ($i -lt $templateLines.Length -and $templateLines[$i].Trim() -eq '-') { $i++ }
      $addedSomething = $false
      if ($weekMeetings.Count -gt 0) {
        $outputLines += "### Reuniones"
        $addedSomething = $true
        foreach ($m in $weekMeetings) {
          $item = if ($m -match '^- ') { $m } else { "- {0}" -f $m }
          $outputLines += $item
        }
        $outputLines += ""
      }
      if ($weekNotes.Count -gt 0) {
        $outputLines += "### Notas"
        $addedSomething = $true
        foreach ($n in $weekNotes) {
          $item = if ($n -match '^- ') { $n } else { "- {0}" -f $n }
          $outputLines += $item
        }
      }
      if (-not $addedSomething) {
        $outputLines += "- "
      }
      continue
    }

    $outputLines += $line
    $i++
  }
} else {
  # Fallback si no hay plantilla
  $outputLines += "---"
  $outputLines += "title: Resumen Semanal $($weekEnd.ToString($dateFmt))"
  $outputLines += "date: $($weekEnd.ToString($dateFmt))"
  $outputLines += "tags:"
  $outputLines += "  - resumen"
  $outputLines += "  - weekly"
  $outputLines += "periodo: Del $($weekStart.ToString($dateFmt)) al $($weekEnd.ToString($dateFmt))"
  $outputLines += "---"
  $outputLines += ""
  $outputLines += "# Resumen Semanal $($weekEnd.ToString($dateFmt))"
  $outputLines += ""
  $outputLines += "## Periodo"
  $outputLines += "Del $($weekStart.ToString($dateFmt)) al $($weekEnd.ToString($dateFmt))"
  $outputLines += ""
  $outputLines += "## Lo Mas Destacado"
  if ($weekHighlights.Count -gt 0) {
    foreach ($h in $weekHighlights) { $outputLines += $h }
  } else {
    $outputLines += "- "
  }
  $outputLines += ""
  $outputLines += "## Tareas Completadas"
  if ($weekCompleted.Count -gt 0) {
    foreach ($t in $weekCompleted.Values) { $outputLines += $t }
  } else {
    $outputLines += "- "
  }
  $outputLines += ""
  $outputLines += "## Objetivos Logrados"
  if ($weekCompleted.Count -gt 0) {
    foreach ($t in $weekCompleted.Values) { $outputLines += $t }
  } else {
    $outputLines += "- "
  }
  $outputLines += ""
  $outputLines += "## Lecciones Aprendidas"
  $outputLines += "- "
  $outputLines += ""
  $outputLines += "## Proximos Pasos"
  if ($weekPending.Count -gt 0) {
    foreach ($t in $weekPending.Values) { $outputLines += $t }
  } else {
    $outputLines += "- "
  }
  $outputLines += ""
  $outputLines += "## Notas Adicionales"
  if ($weekMeetings.Count -gt 0) {
    $outputLines += "### Reuniones"
    foreach ($m in $weekMeetings) {
      $item = if ($m -match '^- ') { $m } else { "- {0}" -f $m }
      $outputLines += $item
    }
    $outputLines += ""
  }
  if ($weekNotes.Count -gt 0) {
    $outputLines += "### Notas"
    foreach ($n in $weekNotes) {
      $item = if ($n -match '^- ') { $n } else { "- {0}" -f $n }
      $outputLines += $item
    }
  }
  if ($weekMeetings.Count -eq 0 -and $weekNotes.Count -eq 0) {
    $outputLines += "- "
  }
}

# Enlace al weekly anterior
$resFolder = "03-Res$([char]0x00FA)menes"
$outputLines += ""
$outputLines += "## Enlace al Weekly anterior"
$lastSummary = Get-ChildItem -Path $SummariesDir -Filter "Resumen-Semanal-*.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($lastSummary) {
  $outputLines += "- [[$resFolder/$($lastSummary.Name)]]"
}

[System.IO.File]::WriteAllText($summaryFile, ($outputLines -join "`n"), $utf8)
Write-Host "Resumen semanal generado: $summaryFile"
Write-Host ("  - Tareas completadas: {0}" -f $weekCompleted.Count)
Write-Host ("  - Tareas pendientes : {0}" -f $weekPending.Count)
Write-Host ("  - Dias procesados   : {0}" -f ($weekHighlights.Count))
