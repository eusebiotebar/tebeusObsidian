module.exports = async (app) => {
  const file = app.workspace.getActiveFile();
  if (!file) {
    new Notice('No hay archivo activo');
    return;
  }

  const taskTitle = await app.plugins.plugins['quickadd'].api.prompt('Titulo de la nueva tarea:');
  if (!taskTitle) return;

  const content = await app.vault.read(file);
  const tareasMatch = content.match(/^##\s+Tareas\s*\n/i);

  if (!tareasMatch) {
    new Notice('No se encontro la seccion ## Tareas');
    return;
  }

  const insertPos = tareasMatch.index + tareasMatch[0].length;
  const newContent = content.slice(0, insertPos) + `- [ ] ${taskTitle}\n` + content.slice(insertPos);

  await app.vault.modify(file, newContent);
  new Notice('Tarea anadida');
};
