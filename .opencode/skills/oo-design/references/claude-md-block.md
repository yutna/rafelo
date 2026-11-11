# CLAUDE.md block

An agent doing ordinary work rarely opens a skill unless a project
tells it the pack is there. Adding this block to a project's
`CLAUDE.md` makes the pack discoverable when a change starts.

```markdown
## Object-oriented design skills

- This project's own written conventions win over the pack. When they
  disagree, follow the project and say so.
- The `oo-design` skill sizes a task and names the skill that fits.
  Load it before designing a class, module or system, or before a
  change that moves responsibilities between objects.
- When a language skill such as `oo-java` is installed for the
  code being changed, load it before editing that code, whatever
  the size of the change.
- Leave throwaway scripts and one-line fixes alone.
```
