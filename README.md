# Noble Nights Project Guidelines

This document provides project-specific information for developers working on Noble Nights.

## Build/Configuration Instructions

- **Engine Version**: Godot 4.6.1+ (Headless support is available for CI/CLI).
- **Core Plugins**:
  - `Dialogic`: Used for narrative, dialogue, and triggering game events.
  - `gltf2meshlib`: Utility for converting GLTF assets to MeshLibraries.

- **Project Structure**:
  - `scripts/GameManager.gd`: The central state manager, handling level transitions and character lists.                                          
  - `scripts/stats/`: Contains unit data (`CharacterData`), runtime state (`CharacterState`), and resource definitions (Skills, Weapons).         
  - `scripts/commands/`: Implementation of the Command pattern for all combat actions (e.g., Attack, Move).                                       
  - `scenes/levels/`: GridMap-based level designs.  

## Testing Information

### Running Tests via CLI
The project supports standalone script execution for logic verification. Use the `--headless` flag to run tests without a GPU.

**Example Command:**
```bash
godot --headless --script tools/test_save_load.gd
```

## Additional Development Information

### Code Style & Patterns                                                                                                                         
- **Strict Typing**: The project has `gdscript/warnings/untyped_declaration=2` enabled. Always provide explicit types for variables, function parameters, and return values.                                                                                                                      
- **State Management (GameManager)**: All primary state transitions (level changes, character lists) must be funneled through `GameManager.gd`. Use its signals (`level_changed`, `characters_updated`) to react to state changes.                                                                  
- **Command Pattern**: Combat actions are encapsulated as `Command` objects (found in `scripts/commands/`). They should operate on isolated state data (e.g., `CharacterState`) to produce a new state, facilitating reliable AI simulation.                                                          
- **Pure Logic**: Core state components (`CharacterState`, etc., located in `scripts/stats/`) are designed to be "pure" (minimal to no dependency on the SceneTree or Node access) to facilitate simulation and testing.                                                                              
- **Dialogic Integration**: Use `Main` and `Event` calls inside Dialogic timelines to trigger game transitions (e.g., loading levels, starting battles).

### Debugging
- Use the `GameState.clone()` method to create snapshots of the game state for "what-if" analysis in AI or undo systems.
- Check `scripts/combat/terrain.gd` for level weights used in pathfinding.
