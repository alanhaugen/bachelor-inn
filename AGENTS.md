# AGENTS.md

## Agent framework

The coding agent harness is called pi

A model has access to four tools only: read, write, edit, and bash
 
## Project Overview

This is a Godot 4.6.1+ game project.

- Language: GDScript with `gdscript/warnings/untyped_declaration=2` enabled

## Code Guidelines
- Prefer clear, readable code over clever optimizations
- Keep functions small and focused
- Use meaningful variable and function names
- Avoid unnecessary dependencies

## Project Structure**:
- `scripts/GameManager.gd`: The central state manager, handling level transitions and character lists.
- `scripts/stats/`: Contains unit data (`CharacterData`), runtime state (`CharacterState`), and resource definitions (Skills, Weapons).
- `scripts/commands/`: Implementation of the Command pattern for all combat actions (e.g., Attack, Move).
- `scenes/levels/`: GridMap-based level designs. 

## Testing
- Tests are found in tools
- Exampple: godot --headless --script tools/test_save_load.gd
## Agent Instructions

When modifying this project:

- Do not break existing functionality unless explicitly instructed
- Keep changes minimal and well-scoped
- Maintain consistency with existing code style
- Prefer simple and robust solutions over complex ones

## Game-Specific Notes
- This is a game project, so performance and responsiveness matter
- Avoid blocking the main loop
- Testing & Validation

## After making changes:
- Run tests in tools
- Ensure no crashes or major regressions occur

## Summary
- This is a Godot game project
- Keep it compilable, stable, and simple.
