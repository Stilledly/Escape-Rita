# Escape Rita - 3D Horror Chase Game

A scary 3D game made in Godot 4.4 where you must escape from a monster while collecting flowers to unlock your freedom.

## Objective

Your goal is to:
1. **Collect 7 magical flowers** scattered around the dark environment
2. **Pick up the emerald** (only available after collecting all flowers)
3. **Find the fox statue** and offer the emerald to it
4. **Escape through the opened door** to victory!

## Controls

- **WASD** - Move around
- **Mouse** - Look around
- **Shift** - Sprint (uses stamina)
- **Space** - Jump
- **F** - Toggle flashlight
- **E** - Interact with objects
- **ESC** - Toggle mouse cursor

## Game Features

### Player Features
- **First-person perspective** with mouse look
- **Flashlight** to illuminate the dark environment
- **Stamina system** - sprinting drains stamina, walking regenerates it
- **Footstep sounds** that the monster can hear
- **Interaction system** to collect items

### Monster AI
- **Patrolling behavior** - follows predetermined patrol routes
- **Vision cone detection** - can see you if you're in front of it
- **Hearing system** - investigates sounds you make
- **Chase mode** - pursues you when spotted
- **Search mode** - looks for you after losing sight
- **Glowing red eyes** for scary atmosphere

### Collectibles
- **Flowers** - Glowing pink flowers that float and rotate
- **Emerald** - Green crystal that unlocks the victory condition
- **Fox Statue** - Ancient statue that accepts the emerald offering

### Atmosphere
- **Dark environment** with limited lighting
- **Fog effects** for spooky atmosphere
- **Dynamic lighting** from flashlight and collectibles
- **Scary red-eyed monster** hunting you

## Tips for Survival

1. **Use your flashlight wisely** - it helps you see but might attract the monster
2. **Listen for the monster** - it makes sounds when moving
3. **Don't sprint everywhere** - manage your stamina and make less noise when walking
4. **Hide behind objects** when the monster is near
5. **Learn the patrol patterns** to avoid the monster
6. **Collect flowers systematically** - remember where you've been

## Technical Details

Built with Godot 4.4 featuring:
- 3D CharacterBody3D for physics-based movement
- NavigationAgent3D for monster AI pathfinding
- Area3D for collision detection and interaction
- SpotLight3D for dynamic lighting effects
- Tween animations for smooth visual effects

## Development Notes

This is a complete game prototype with all core systems implemented:
- Player controller with stamina and interaction
- Monster AI with multiple behavioral states
- Collectible system with game progression
- UI elements for feedback
- Win/lose conditions

The game can be expanded with:
- Multiple levels/environments
- More complex monster behaviors
- Additional collectible types
- Sound effects and music
- Save/load system
- Settings menu

Enjoy escaping from Rita! 🌸👾
