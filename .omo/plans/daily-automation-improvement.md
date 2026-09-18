# Plan: Daily Log Automation Enhancements

## TL;DR
- Improve New-DailyLog.ps1 to insert imported tasks directly into the existing "Tareas Pendientes" section of today's daily template, ensure Schedule-DailyLog.ps1 tests pass, and add a new script to generate weekly summaries every Friday at 14:00.

## Context
- Daily logs are created via New-DailyLog.ps1. Current behavior imports tasks from yesterday as a new section, which is not aligned with the template. A new weekly summary script is desired for weekly reflections.

## Work Objectives
- [ ] Refactor New-DailyLog.ps1 to insert imported tasks into the existing "Tareas Pendientes" section of the Today daily, preserving the template structure.
- [ ] Validate and fix any parsing issues; ensure correct insertion without duplicating sections.
- [ ] Validate Schedule-DailyLog.ps1 by running a quick test to ensure daily creation works and task copying is correct.
- [ ] Create a new script WeeklySummary.ps1 that creates a concise summary entry in 03-Resúmenes every Friday at 14:00.
- [ ] Schedule WeeklySummary.ps1 to run weekly on Friday at 14:00.
- [ ] Provide end-to-end verification that a weekly summary includes all dailies for the week and a brief summary of the week.
- [ ] Ensure no Git commits are produced (recurring behavior for a Obsidian vault).

## Verification Strategy
- Agent-Executed QA Scenarios for each script:
  - New-DailyLog.ps1: verify that the daily is created under 02-Daily-Logs with today’s date, contains a copy of yesterday’s tasks inside the existing "Tareas Pendientes" section, and includes a link to the previous daily.
  - Schedule-DailyLog.ps1: run the script and confirm the task is registered in Windows Task Scheduler with the expected trigger (weekday daily at 07:00). The daily creation should appear when the job runs.
  - WeeklySummary.ps1: verify that a new 03-Resúmenes file is created on the Friday at 14:00 with a curated short summary including the week’s date range and a list of the dailies.
  - Scheduling: ensure all jobs run without errors and do not leave stale files.

## Execution Strategy (Wave-based)
Wave 1 — New-DailyLog.ps1 improvements (foundation)
- 1. Refactor code path to insert imported tasks into the existing Tareas Pendientes section.
- 2. Add robust parsing to locate the Tareas Pendientes header in Today.md and insert under it.
- 3. Add tests or validation steps (agent QA) to verify correct insertion.

Wave 2 — Schedule-DailyLog.ps1 validation
- 4. Create quick test to ensure scheduling command is registered and triggers the daily script as expected.
- 5. Validate when the script runs that the daily is produced and tasks are copied correctly.

Wave 3 — Weekly Summary script
- 6. Implement WeeklySummary.ps1 to create a succinct summary in 03-Resúmenes.
- 7. Schedule WeeklySummary.ps1 to run every Friday at 14:00.
- 8. Verify end-to-end weekly summary creation and content accuracy.

Wave 4 — Final validation and cleanup
- 9. Run full set of QA scenarios across all scripts.
- 10. Update docs/draft plan with results and finalize rollout plan.

## Plan Artifacts
- Plan file: .sisyphus/plans/daily-automation-improvement.md
- Drafts: .sisyphus/drafts/daily-automation-improvement.md (to mirror decisions)

## Acceptance Criteria (summary)
- New-DailyLog.ps1 inserts imported tasks under Tareas Pendientes in Today’s daily correctly for all tested days.
- Schedule-DailyLog.ps1 runs and creates a Windows Scheduled Task with expected trigger and runs without errors.
- WeeklySummary.ps1 creates a weekly summary in 03-Resúmenes.md and is scheduled to run Fridays at 14:00.
- All tasks execute without creating commits in the Obsidian vault directory.

Plan ready for execution. Please confirm to proceed with generation and execution of the plan.
