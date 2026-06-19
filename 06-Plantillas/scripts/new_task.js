module.exports = async (params) => {
  const app = params.app;

  const projects = app.vault.getMarkdownFiles()
    .filter(f => f.path.startsWith('01-Proyectos/'))
    .sort((a, b) => a.basename.localeCompare(b.basename));

  if (projects.length === 0) {
    new Notice('No hay proyectos en 01-Proyectos/');
    return;
  }

  const selected = await params.quickAddApi.suggester(
    projects.map(p => p.basename),
    projects
  );
  if (!selected) return;

  const leaf = app.workspace.getLeaf(false);
  await leaf.openFile(selected);

  setTimeout(() => {
    try {
      const editor = leaf.view?.editor;
      if (editor) {
        const content = editor.getValue();
        const match = content.match(/^##\s+Tareas\s*$/m);
        if (match) {
          const lineBefore = content.substring(0, match.index).split('\n');
          editor.setCursor(lineBefore.length - 1 + 1, 0);
        }
      }

      const commands = Object.values(app.commands.commands);
      const cmd = commands.find(c => c.name && /tasks?.*creat/i.test(c.name))
                || commands.find(c => c.id && /tasks?.*creat/i.test(c.id));
      if (cmd) {
        app.commands.executeCommandById(cmd.id);
      } else {
        const names = commands.filter(c => c.name && /task/i.test(c.name)).map(c => c.name).slice(0, 8);
        new Notice('Tasks no encontrado. ¿Será alguno: ' + names.join(', ') + '?');
      }
    } catch (e) {
      new Notice('Error: ' + e.message);
    }
  }, 500);
};
