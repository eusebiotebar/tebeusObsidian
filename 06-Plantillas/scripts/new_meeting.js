module.exports = async (params) => {
  const { app, quickAddApi } = params;

  const projects = app.vault.getFiles().filter(f => 
    f.path.startsWith("01-Proyectos/") && 
    f.path.endsWith(".md") && 
    !f.path.includes("reuniones/") && 
    !f.path.includes("decisiones/") && 
    !f.path.includes("recursos/") &&
    f.path.split("/").length === 3
  );

  if (projects.length === 0) {
    new Notice("No se encontraron proyectos en 01-Proyectos/");
    return;
  }

  const projectList = projects.map(p => ({
    name: p.basename,
    path: p.path
  }));

  const selectedProject = await quickAddApi.suggester(
    projectList.map(p => p.name),
    projectList
  );

  if (!selectedProject) return;

  const meetingTitle = await quickAddApi.inputPrompt("Título de la reunión:");
  if (!meetingTitle) return;

  const now = new Date();
  const dateStr = now.toISOString().split("T")[0];
  const fileName = `${dateStr} ${meetingTitle}.md`;

  const projectFolder = selectedProject.path.split("/")[1];
  const targetPath = `01-Proyectos/${projectFolder}/reuniones/${fileName}`;
  const folderPath = `01-Proyectos/${projectFolder}/reuniones`;

  const folder = app.vault.getAbstractFileByPath(folderPath);
  if (!folder) {
    await app.vault.createFolder(folderPath);
  }

  let templateContent;
  try {
    templateContent = await app.vault.adapter.read("06-Plantillas/Plantilla-Reunion.md");
  } catch (e) {
    new Notice("Plantilla no encontrada: 06-Plantillas/Plantilla-Reunion.md");
    return;
  }

  const templateVars = {
    "{{title}}": meetingTitle,
    "{{date}}": dateStr,
    "{{proyecto_path}}": projectFolder,
    "{{proyecto_file}}": selectedProject.name,
  };

  let content = templateContent;
  for (const [key, value] of Object.entries(templateVars)) {
    content = content.replace(new RegExp(key.replace(/[{}]/g, "\\$&"), "g"), value);
  }

  const file = await app.vault.create(targetPath, content);

  const projectFilePath = selectedProject.path;
  const projectFile = app.vault.getAbstractFileByPath(projectFilePath);
  if (projectFile) {
    const projectContent = await app.vault.read(projectFile);
    const meetingLink = `- [[${targetPath.replace(".md", "")}]]`;
    
    if (projectContent.includes("## Reuniones")) {
      const updatedContent = projectContent.replace(
        "## Reuniones\n",
        `## Reuniones\n${meetingLink}\n`
      );
      await app.vault.modify(projectFile, updatedContent);
    }
  }

  await app.workspace.getLeaf('tab').openFile(file);
  
  new Notice(`Reunión creada: ${fileName}`);
};
