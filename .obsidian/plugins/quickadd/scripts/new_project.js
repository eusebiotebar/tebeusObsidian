module.exports = async (params) => {
  const app = params.app;
  const projectName = await params.quickAddApi.inputPrompt('Nombre del nuevo proyecto:');
  if (!projectName) return;

  const today = new Date().toISOString().slice(0, 10);
  const fileName = `01-Proyectos/${projectName}.md`;

  const templateFile = app.vault.getAbstractFileByPath('06-Plantillas/Plantilla-Proyecto.md');
  if (!templateFile) {
    new Notice('No se encontró la plantilla en 06-Plantillas/');
    return;
  }

  const existingFile = app.vault.getAbstractFileByPath(fileName);
  if (existingFile) {
    new Notice('Ya existe un proyecto con ese nombre');
    return;
  }

  let templateContent = await app.vault.read(templateFile);
  templateContent = templateContent
    .replace(/\{\{date\}\}/g, today)
    .replace(/\{\{title\}\}/g, projectName)
    .replace(/\{\{status\}\}/g, 'active');

  await app.vault.create(fileName, templateContent);

  const newFile = app.vault.getAbstractFileByPath(fileName);
  if (newFile) {
    const leaf = app.workspace.getLeaf('tab');
    await leaf.openFile(newFile);
  }

  new Notice('Proyecto creado en 01-Proyectos/');
};
