module.exports = async (params) => {
  const { app, quickAddApi } = params;
  const today = new Date();
  const yyyy = today.getFullYear();
  const mm = String(today.getMonth() + 1).padStart(2, "0");
  const dd = String(today.getDate()).padStart(2, "0");
  const dateStr = `${yyyy}-${mm}-${dd}`;

  const task = await quickAddApi.inputPrompt("Tarea completada:");
  if (!task) return;

  const dailyPath = `02-Daily-Logs/${yyyy}/${yyyy}-${mm}/${dateStr}.md`;
  let file = app.vault.getAbstractFileByPath(dailyPath);

  if (!file) {
    const template = await app.vault.adapter.read(
      "06-Plantillas/Plantilla-Daily-Log.md"
    );
    const content = template
      .replace(/\{\{date\}\}/g, dateStr)
      .replace(/\{\{title\}\}/g, `Daily Log ${dateStr}`);
    file = await app.vault.create(dailyPath, content);
  }

  const content = await app.vault.read(file);
  const marker = "## Tareas Completadas";
  const idx = content.indexOf(marker);

  if (idx === -1) return;

  const afterMarker = content.slice(idx + marker.length);
  const nextSection = afterMarker.search(/\n## /);
  const insertPos =
    nextSection === -1
      ? content.length
      : idx + marker.length + nextSection;

  const newLine = `- [x] ${task} ✅ ${dateStr}\n`;
  const updated = content.slice(0, insertPos) + newLine + content.slice(insertPos);

  await app.vault.modify(file, updated);
  new Notice(`Añadido al daily ${dateStr}`);
};
