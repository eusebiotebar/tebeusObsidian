module.exports = async (app) => {
  const goalTitle = await app.plugins.plugins['quickadd'].api.prompt('Título del nuevo objetivo:');
  if (!goalTitle) return;

  const goalFile = app.vault.getAbstractFileByPath('04-Objetivos/00-Objetivos.md');
  if (!goalFile) {
    new Notice('No se encontró 04-Objetivos/00-Objetivos.md');
    return;
  }

  const content = await app.vault.read(goalFile);
  const sectionMatch = content.match(/^## Objetivos del Año 2026\s*\n/i);

  if (!sectionMatch) {
    new Notice('No se encontró la sección "Objetivos del Año 2026"');
    return;
  }

  // Calc end of section: find next ## heading boundary
  const sectionStart = sectionMatch.index + sectionMatch[0].length;
  const restAfterSection = content.slice(sectionStart);
  const nextHeading = restAfterSection.match(/^##\s+/m);
  const sectionEnd = nextHeading
    ? sectionStart + nextHeading.index
    : content.length;
  const insertPos = nextHeading
    ? sectionEnd
    : content.length;

  const newContent = content.slice(0, insertPos) +
    `- [ ] ${goalTitle}\n` +
    content.slice(insertPos);

  await app.vault.modify(goalFile, newContent);

  const leaf = app.workspace.getLeaf('tab');
  await leaf.openFile(goalFile);

  new Notice('Objetivo añadido a Objetivos del Año 2026');
};
