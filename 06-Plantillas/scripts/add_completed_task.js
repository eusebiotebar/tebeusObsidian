module.exports = async (params) => {
  const { app, quickAddApi } = params;

  const today = new Date();
  const yyyy = today.getFullYear();
  const mm = String(today.getMonth() + 1).padStart(2, "0");
  const dd = String(today.getDate()).padStart(2, "0");
  const dateStr = `${yyyy}-${mm}-${dd}`;

  const tasksPlugin = app.plugins.plugins["obsidian-tasks-plugin"];
  if (!tasksPlugin?.apiV1) {
    new Notice("Plugin Tasks no disponible");
    return;
  }

  const projectFiles = app.vault
    .getMarkdownFiles()
    .filter((f) => f.path.startsWith("01-Proyectos/"))
    .sort((a, b) => a.path.localeCompare(b.path));

  const openTasks = [];
  for (const file of projectFiles) {
    const content = await app.vault.read(file);
    content.split("\n").forEach((line, index) => {
      const m = line.match(/^(\s*)- \[([^xX])\]\s*(.+)$/);
      if (m) {
        openTasks.push({
          file,
          lineIndex: index,
          indent: m[1],
          text: m[3].trim(),
          raw: line.trim(),
          path: file.path.replace("01-Proyectos/", ""),
        });
      }
    });
  }

  if (openTasks.length === 0) {
    new Notice("No hay tareas abiertas en 01-Proyectos/");
    return;
  }

  const selected = await quickAddApi.suggester(
    openTasks.map((t) => `${t.text}  ·  ${t.path}`),
    openTasks
  );
  if (!selected) return;

  const editedLine = await tasksPlugin.apiV1.editTaskLineModal(selected.raw);
  if (editedLine === "") {
    new Notice("Edición cancelada");
    return;
  }

  const content = await app.vault.read(selected.file);
  const lines = content.split("\n");
  const editedLines = editedLine.split("\n").map((l) => selected.indent + l.trim());
  lines.splice(selected.lineIndex, 1, ...editedLines);
  await app.vault.modify(selected.file, lines.join("\n"));

  const doneDate = (editedLine.match(/✅\s*(\d{4}-\d{2}-\d{2})/) || [])[1] || dateStr;
  const doneRegex = /^\- \[([xX])\]/;
  const isDone = doneRegex.test(editedLine.trim());
  if (!isDone) {
    new Notice("Tarea actualizada (sin completar)");
    return;
  }

  const dailyPath = `02-Daily-Logs/${yyyy}/${yyyy}-${mm}/${doneDate}.md`;
  let daily = app.vault.getAbstractFileByPath(dailyPath);

  if (!daily) {
    const template = await app.vault.adapter.read(
      "06-Plantillas/Plantilla-Daily-Log.md"
    );
    const tplContent = template
      .replace(/\{\{date\}\}/g, doneDate)
      .replace(/\{\{title\}\}/g, `Daily Log ${doneDate}`);
    daily = await app.vault.create(dailyPath, tplContent);
  }

  const dailyContent = await app.vault.read(daily);
  const marker = "## Tareas Completadas";
  const idx = dailyContent.indexOf(marker);
  if (idx === -1) {
    new Notice("Tarea actualizada (sección Tareas Completadas no encontrada)");
    return;
  }

  const afterMarker = dailyContent.slice(idx + marker.length);
  const nextSection = afterMarker.search(/\n## /);
  const insertPos =
    nextSection === -1
      ? dailyContent.length
      : idx + marker.length + nextSection;

  const clean = editedLine
    .trim()
    .replace(/^\- \[[xX]\]\s*/, "")
    .replace(/\s*✅\s*\d{4}-\d{2}-\d{2}\s*$/, "");
  const newLine = `- [x] ${clean} ✅ ${doneDate}\n`;

  const section = dailyContent.slice(idx + marker.length, insertPos);
  if (!section.includes(clean)) {
    const updated =
      dailyContent.slice(0, insertPos) + newLine + dailyContent.slice(insertPos);
    await app.vault.modify(daily, updated);
  }

  new Notice(`Tarea completada → daily ${doneDate}`);
};