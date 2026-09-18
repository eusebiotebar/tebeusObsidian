---
cssclass: command-center
title: Command Center
date: 2026-06-17
banner: "07-Archivos/Command Center.jpg"
---

```dataviewjs
// ============================================================
// COMMAND CENTER — Panel de Control
// Renderiza: hero, acciones rápidas, KPIs, parrilla técnica, métricas
// Dependencia: DataviewJS obligatorio
// ============================================================

// ── Forzar clase command-center ──
document.querySelectorAll(".markdown-preview-view, .markdown-source-view, .cm-content")
  .forEach(el => el.classList.add("command-center"));

// ── Inline critico anti-flash ──
const fs = document.createElement("style");
fs.textContent = `.command-center{opacity:0;transition:opacity .15s}.command-center.cc-loaded{opacity:1}`;
document.head.appendChild(fs);

// ── Forzar modo lectura ──
try {
  const leaf = app.workspace.getLeaf(false);
  const vs = leaf.getViewState();
  if (vs.type === "markdown" && vs.state?.mode !== "preview") {
    vs.state.mode = "preview";
    leaf.setViewState(vs, { history: false });
  }
} catch(e) { /* silencioso */ }

// ── Inyectar CSS ──
(async () => {
  try {
    if (!document.getElementById("cc-style")) {
      const css = await app.vault.adapter.read(".obsidian/snippets/command-center.css");
      const s = document.createElement("style");
      s.id = "cc-style";
      s.textContent = css;
      document.head.appendChild(s);
    }
    const badge = document.getElementById("cc-badge") || document.createElement("div");
    badge.id = "cc-badge";
    badge.textContent = "CC ONLINE";
    Object.assign(badge.style, {
      position: "fixed", bottom: "8px", right: "8px", zIndex: "9999",
      background: "#4ade80", color: "#000", font: "bold 9px/1 monospace",
      letterSpacing: "0.12em", padding: "2px 8px", borderRadius: "3px",
      opacity: "0.8", pointerEvents: "none"
    });
    if (!badge.isConnected) document.body.appendChild(badge);
  } catch (e) {
    dv.paragraph("❌ Error CSS: " + e.message);
  }
  document.querySelectorAll(".command-center").forEach(el => el.classList.add("cc-loaded"));
})();

const now = new Date();
const timeStr = now.toLocaleTimeString("es-ES", { hour: "2-digit", minute: "2-digit" });
const dateStr = now.toLocaleDateString("es-ES", { day: "numeric", month: "short", year: "numeric" });

// ── HERO ──
const hero = dv.el("div", "", { cls: "cc-hero" });
hero.innerHTML = `
  <div class="cc-hero-title"><span>◆</span> COMMAND CENTER</div>
  <div class="cc-hero-status">
    <span class="led"></span> SYS.ACTIVE
  </div>
  <div class="cc-hero-time">${dateStr} · ${timeStr}</div>
`;

// ── ACTIONS ──
// Create a container div for the action buttons using Dataview's element helper.
// This will hold all the generated buttons in the Command Center UI.
const actions = dv.el("div", "", { cls: "cc-actions" });
// Define an array of button specifications. Each object includes:
// - label: text (with emojis) displayed on the button.
// - hint: a subtitle or tooltip explaining the action.
// - id: (optional) command ID to execute via Obsidian's command palette.
// - path: (optional) file path to open when the button is clicked.
// - color: a custom color key used for styling via data-color attribute.
const btns = [
  { label: "✦ Nueva Tarea", hint: "quickadd macro", id: "quickadd:choice:macro_nueva_tarea", color: "green" },
  { label: "✦ Nuevo Objetivo", hint: "quickadd macro", id: "quickadd:choice:macro_nuevo_objetivo", color: "purple" },
  { label: "📋 Daily Hoy", hint: `abrir ${dateStr}`, path: `02-Daily-Logs/${now.getFullYear()}/${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,"0")}/${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,"0")}-${String(now.getDate()).padStart(2,"0")}.md`, color: "yellow" },
  { label: "✦ Añadir Proyecto", hint: "quickadd macro", id: "quickadd:choice:macro_nuevo_proyecto", color: "cyan" },
  { label: "📅 Nueva Reunión", hint: "quickadd macro", id: "quickadd:choice:macro_nueva_reunion", color: "orange" },
  { label: "✅ Tarea Completada", hint: "añadir al daily", id: "quickadd:choice:macro_tarea_completada", color: "green" },
];
// Iterate over each button definition and create a <button> element inside the actions container.
for (const b of btns) {
  const el = actions.createEl("button", { cls: "cc-action" });
  // Store the color key in a data attribute; CSS can target [data-color="green"] etc.
  el.dataset.color = b.color;
  // Build the inner HTML with a label and a hint element.
  el.innerHTML = `<div class="cc-action-label">${b.label}</div><div class="cc-action-hint">${b.hint}</div>`;
  // Click handler: either execute a command by ID or open a file path.
  el.onclick = () => {
    if (b.id) {
      const cmd = app.commands.commands[b.id];
      if (cmd) { app.commands.executeCommandById(b.id); return; }
      new Notice(`Comando no encontrado: ${b.id}`);
      return;
    }
    if (b.path) {
      const file = app.vault.getAbstractFileByPath(b.path);
      if (file) { app.workspace.getLeaf('tab').openFile(file); }
      else { new Notice(`No encontrado: ${b.path}`); }
    }
  };
}
// End of ACTIONS block


// ── KPIS ──
const allProjects = dv.pages('"01-Proyectos"').where(p => (p.file.tags || []).includes("#proyecto"));
const activeProjects = allProjects.where(p => p.status === "active");
const dailyLogs = dv.pages('"02-Daily-Logs"').where(p => (p.file.tags || []).includes("#daily-log"));
const resumenes = dv.pages('"03-Resúmenes"');
const objetivosFile = dv.page("04-Objetivos/00-Objetivos");
const reuniones = dv.pages('"01-Proyectos"').where(p => (p.file.tags || []).includes("#reunion"));

// Count tasks in active projects
let pendingTasks = 0;
let completedTasks = 0;
for (const p of activeProjects) {
  const text = await dv.io.load(p.file.path);
  if (text) {
    pendingTasks += (text.match(/^-\s+\[\s\]\s+/gm) || []).length;
    completedTasks += (text.match(/^-\s+\[[xX]\]\s+/gm) || []).length;
  }
}

const kpis = dv.el("div", "", { cls: "cc-kpis" });
const kpiData = [
  { value: activeProjects.length, label: "Proyectos Activos", color: "green" },
  { value: pendingTasks, label: "Tareas Pendientes", color: "yellow" },
  { value: reuniones.length, label: "Reuniones", color: "orange" },
  { value: dailyLogs.length, label: "Daily Logs", color: "cyan" },
  { value: resumenes.length, label: "Resúmenes Semanales", color: "purple" },
];
for (const k of kpiData) {
  const card = kpis.createEl("div", { cls: "cc-kpi" });
  card.dataset.color = k.color;
  card.innerHTML = `<div class="cc-kpi-value">${k.value}</div><div class="cc-kpi-label">${k.label}</div>`;
}
```

## 📋 Gestión de Tareas (Flujo de Proyecto)

> **Flujo recomendado:** Añade tareas en la sección `## Tareas` de cada proyecto.
> Las tareas se muestran aquí agrupadas por vencimiento y proyecto.

```dataviewjs
const today = dv.date('today');
const yesterday = dv.date('today').minus({days:1});

const projects = dv.pages('"01-Proyectos"')
  .where(p => p.file.tasks.length > 0);

// Collect all tasks with project info
const allTasks = [];
for (const p of projects) {
  for (const t of p.file.tasks) {
    if (t.completed) continue;
    if (t.status === "-") continue; // tareas canceladas (Tasks: [-])
    const taskText = t.text;
    // Try to find due date from inline field or Tasks syntax
    let due = null;
    const dueMatch = taskText.match(/📅\s*(\d{4}-\d{2}-\d{2})/);
    if (dueMatch) due = dv.date(dueMatch[1]);
    else if (t.due) due = t.due;
    
    allTasks.push({
      task: t,
      text: taskText.replace(/📅\s*\d{4}-\d{2}-\d{2}/g, '').trim(),
      project: p.file.link,
      projectName: p.title || p.file.name,
      due: due,
      status: !due ? 'no-date' :
              due < today ? 'overdue' :
              due.day === today.day && due.month === today.month && due.year === today.year ? 'today' :
              'upcoming'
    });
  }
}

// Group by status
const groups = {
  overdue: allTasks.filter(t => t.status === 'overdue').sort((a,b) => a.due - b.due),
  today: allTasks.filter(t => t.status === 'today'),
  upcoming: allTasks.filter(t => t.status === 'upcoming').sort((a,b) => a.due - b.due),
  'no-date': allTasks.filter(t => t.status === 'no-date'),
};

const icons = { overdue: '⏰', today: '📅', upcoming: '🔜', 'no-date': '📌' };
const labels = { overdue: 'Vencidas', today: 'Hoy', upcoming: 'Próximas', 'no-date': 'Sin fecha' };

for (const [key, tasks] of Object.entries(groups)) {
  if (tasks.length === 0) continue;
  dv.header(3, `${icons[key]} ${labels[key]} (${tasks.length})`);
  
  // Group by project within each status
  const byProject = {};
  for (const t of tasks) {
    const pname = t.projectName;
    if (!byProject[pname]) byProject[pname] = { link: t.project, tasks: [] };
    byProject[pname].tasks.push(t);
  }
  
  let md = '';
  for (const [pname, data] of Object.entries(byProject)) {
    md += `**${data.link}**\n`;
    for (const t of data.tasks) {
      const dueStr = t.due ? ` — 📅 ${t.due.toFormat('dd/MM')}` : '';
      md += `- [ ] ${t.text}${dueStr}\n`;
    }
    md += '\n';
  }
  dv.paragraph(md);
}
```

## PROYECTOS ACTIVOS

```dataview
TABLE status as Estado, priority as Prioridad, start-date as Inicio, due-date as Vencimiento
FROM "01-Proyectos"
WHERE contains(file.tags, "#proyecto") AND status = "active"
SORT priority DESC, file.mtime DESC
```

```dataviewjs
// ── TECHNICAL AREAS GRID (dinámico) ──
const all = dv.pages('"01-Proyectos"')
  .where(p => (p.file.tags || []).includes("#proyecto") && p.area);

// Agrupar por area
const byArea = {};
for (const p of all) {
  const area = p.area;
  if (!area) continue;
  if (!byArea[area]) byArea[area] = [];
  byArea[area].push(p);
}

// Orden de áreas predefinido
const areaOrder = [
  "CAN Bus & Protocolos",
  "UDP & Networking",
  "STM32 & MCU",
  "Simulink & MCU",
  "RPi & Linux",
  "Testing & Tools",
  "Documentación",
];
const sortedAreas = Object.keys(byArea).sort(
  (a, b) => (areaOrder.indexOf(a) - areaOrder.indexOf(b))
);

const areas = dv.el("div", "", { cls: "cc-grid" });
for (const areaName of sortedAreas) {
  const projects = byArea[areaName];
  const cell = areas.createEl("div", { cls: "cc-cell" });
  const title = cell.createEl("div", { cls: "cc-cell-title", text: areaName });
  const content = cell.createEl("div", { cls: "cc-cell-content" });
  for (const p of projects) {
    content.appendChild(dv.span(`[[${p.file.path}|${p.title || p.file.name}]]`));
    content.createEl("br");
  }
}
```

## REUNIONES RECIENTES

```dataview
TABLE date as Fecha, proyecto as Proyecto
FROM "01-Proyectos"
WHERE contains(file.tags, "#reunion")
SORT date DESC
LIMIT 10
```

## OBJETIVOS

```dataview
TASK
FROM "04-Objetivos/00-Objetivos"
WHERE !completed
LIMIT 12
```

```dataviewjs
// ── METRICS ──
const pAll = dv.pages('"01-Proyectos"').where(p => (p.file.tags || []).includes("#proyecto"));
const pActive = pAll.where(p => p.status === "active");
const pPaused = pAll.where(p => p.status === "paused");
const pCompleted = pAll.where(p => p.status === "completed");
const dLogs = dv.pages('"02-Daily-Logs"').where(p => (p.file.tags || []).includes("#daily-log"));
const res = dv.pages('"03-Resúmenes"');
const objs = dv.page("04-Objetivos/00-Objetivos");

let objPending = 0;
if (objs) {
  const text = await dv.io.load(objs.file.path);
  if (text) objPending = (text.match(/^-\s+\[\s\]\s+/gm) || []).length;
}

dv.table(["Métrica", "Valor"], [
  ["Proyectos Activos", pActive.length],
  ["Proyectos en Pausa", pPaused.length],
  ["Proyectos Completados", pCompleted.length],
  ["Total Proyectos", pAll.length],
  ["Reuniones", dv.pages('"01-Proyectos"').where(p => (p.file.tags || []).includes("#reunion")).length],
  ["Daily Logs", dLogs.length],
  ["Resúmenes Semanales", res.length],
  ["Objetivos Pendientes", objPending],
]);
```

---

```dataviewjs
dv.paragraph(`*Command Center · ${new Date().toISOString().slice(0, 10)}*`);
```
