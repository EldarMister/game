# ONE SHOT

Created by ELDAR STUDIO

## Overview
ONE SHOT is a dark, atmospheric 3D duel where every round hinges on a single shared revolver. The core experience is a tense sequence of choices: who takes the shot, what the outcome means, and how far the player can push their luck. The game is built to feel minimal, focused, and intense, with a single table setting, a dealer opponent, and a revolving cycle of rounds.

## Technology Stack
- Engine: Godot 4.x
- Language: GDScript
- Project type: 3D
- UI: Godot Control-based UI with responsive anchors for different resolutions
- Audio: Godot AudioStreamPlayer with smooth transitions for win/lose state music
- Save data: local persistence using `user://` files

## Core Gameplay Loop
1. A round begins with a freshly loaded set of bullets.
2. The player always starts.
3. Each turn is one shot with the shared revolver.
4. The target can be self or the dealer.
5. The round ends when the revolver is empty or a life total reaches zero.

## Key Mechanics
- One shared revolver is used by both the player and the dealer.
- Bullets are a mix of live and blank rounds.
- Lives are limited; a live shot reduces life by 1, blanks do no damage.
- Turns strictly alternate: player -> dealer -> player -> dealer.
- The dealer can choose to shoot the player or themselves.

## Game States
The project is organized around a state-driven flow:
- Intro / entry flow
- Active gameplay round
- Win state
- Lose state
- Return to menu

## UI and Menus
- Main menu includes play, language selection, coins display, and social buttons.
- HUD provides minimal in-game feedback (round info, lives, bet).
- UI is scalable for mobile devices using proper anchors and stretch settings.

## Economy (Lightweight)
The project includes a simple coin system:
- Coins persist between sessions using local save files.
- Bets are placed before a round and resolved after win/loss.

## Controls
- Mouse or touch: select targets and interact with the revolver.
- Buttons and HUD controls handle menu and round flow.

## Art Direction
- Minimalist, dark environment
- Focused lighting with a single table scene
- High-contrast UI elements for clarity

## Credits
ELDAR STUDIO

## License
This project is dual-licensed:
- CC BY-NC-SA 4.0 for all assets
- MIT for everything else
