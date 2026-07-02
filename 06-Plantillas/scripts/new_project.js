module.exports = async (params) => {
  const app = params.app;
  const projectName = await params.quickAddApi.inputPrompt('Nombre del nuevo proyecto (ej: 0113-Nombre-Proyecto):');
  if (!projectName) return;

  const localPath = await params.quickAddApi.inputPrompt('Ruta local del repositorio (ej: C:/Repos/nombre-proyecto):');
  const repoUrl = await params.quickAddApi.inputPrompt('URL del repositorio (ej: https://github.com/user/repo):');

  const today = new Date().toISOString().slice(0, 10);
  const projectFolder = `01-Proyectos/${projectName}`;
  const filePath = `${projectFolder}/${projectName}.md`;

  const templateFile = app.vault.getAbstractFileByPath('06-Plantillas/Plantilla-Proyecto.md');
  if (!templateFile) {
    new Notice('No se encontró la plantilla en 06-Plantillas/');
    return;
  }

  const existingFile = app.vault.getAbstractFileByPath(filePath);
  if (existingFile) {
    new Notice('Ya existe un proyecto con ese nombre');
    return;
  }

  const subfolders = ['reuniones', 'decisiones', 'recursos'];
  for (const sub of subfolders) {
    const folderPath = `${projectFolder}/${sub}`;
    if (!app.vault.getAbstractFileByPath(folderPath)) {
      await app.vault.createFolder(folderPath);
    }
  }

  let templateContent = await app.vault.read(templateFile);
  templateContent = templateContent
    .replace(/\{\{date\}\}/g, today)
    .replace(/\{\{title\}\}/g, projectName)
    .replace(/\{\{status\}\}/g, 'active')
    .replace(/\{\{path\}\}/g, localPath || '')
    .replace(/\{\{url\}\}/g, repoUrl || '');

  await app.vault.create(filePath, templateContent);

  const newFile = app.vault.getAbstractFileByPath(filePath);
  if (newFile) {
    const leaf = app.workspace.getLeaf('tab');
    await leaf.openFile(newFile);
  }

  new Notice(`Proyecto creado en ${projectFolder}/`);
};
