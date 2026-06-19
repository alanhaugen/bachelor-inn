# Noble Nights Project Guidelines

This document provides project-specific information for developers working on Noble Nights.

## Build/Configuration Instructions

- **Engine Version**: Godot 4.6.1+ (Headless support is available for CI/CLI).
- **Core Plugins**:
  - `Dialogic`: Used for narrative, dialogue, and triggering game events.
  - `gltf2meshlib`: Utility for converting GLTF assets to MeshLibraries.
- **Project Structure**:
  - `scripts/combat/`: Contains the core simulation logic (`GameState`, `MoveGenerator`).
  - `scripts/combat/commands/`: Implementation of the Command pattern for game actions.
  - `scripts/stats/`: Unit data (`CharacterData`) and runtime state (`CharacterState`).
  - `scenes/levels/`: GridMap-based level designs.

## Testing Information

### Running Tests via CLI
The project supports standalone script execution for logic verification. Use the `--headless` flag to run tests without a GPU.

**Example Command:**
```bash
godot --headless --script test_logic.gd
```

## Additional Development Information

### Code Style & Patterns
- **Strict Typing**: The project has `gdscript/warnings/untyped_declaration=2` enabled. Always provide explicit types for variables, function parameters, and return values.
- **Command Pattern**: Combat actions are encapsulated as `Command` objects. They can be executed on a `GameState` to produce a new state (useful for AI simulation).
- **Pure Logic**: `GameState`, `CharacterState`, and `Terrain` are designed to be "pure" (minimal to no dependency on the SceneTree or Node access) to facilitate simulation and testing.
- **Dialogic Integration**: Use `Main` and `Event` calls inside Dialogic timelines to trigger game transitions (e.g., loading levels, starting battles).

### Debugging
- Use the `GameState.clone()` method to create snapshots of the game state for "what-if" analysis in AI or undo systems.
- Check `scripts/combat/terrain.gd` for level weights used in pathfinding.
