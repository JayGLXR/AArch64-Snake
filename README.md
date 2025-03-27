# AArch64 Snake Competition

A two-player snake game written in AArch64 assembly for Apple Silicon Macs. Watch as two AI-controlled snakes compete to eat the most food and grow longer!

## Features

- Two AI-controlled snakes competing on the same board
- Multiple food items (8) scattered across the board
- Snakes grow longer when they eat food
- Snakes can wrap around the board edges
- Real-time score tracking
- ASCII-based graphics
- Smooth animation with 200ms delay between frames

## Game Elements

- `1` - Snake 1's head
- `2` - Snake 2's head
- `@` - Snake body segments
- `F` - Food items
- `#` - Board walls
- `.` - Empty spaces

## Requirements

- Apple Silicon Mac (M1/M2/M3)
- macOS with Command Line Tools installed
- AArch64 assembly toolchain

## Compilation

To compile the game, run:

```bash
as -arch arm64 snake_game_final.s -o snake_game_final.o && \
ld -o snake_game_final snake_game_final.o -lSystem -syslibroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib -e _main -arch arm64
```

## Running the Game

After compilation, run the game with:

```bash
./snake_game_final
```

## Game Rules

1. Each snake starts with 5 body segments
2. Snakes move automatically in different patterns
3. Eating food increases a snake's length and score
4. Snakes can wrap around the board edges
5. The game runs for 100 steps
6. The snake with the highest score wins

## Technical Details

- Board size: 30x20 cells
- Initial snake length: 5 segments
- Maximum snake length: 20 segments
- Number of food items: 8
- Frame delay: 200ms
- Game duration: 100 steps

## Implementation Notes

- Written in pure AArch64 assembly
- Uses macOS system calls for I/O and timing
- Implements circular buffer for snake body segments
- Features pseudo-random food placement
- Includes boundary wrapping and collision detection
- Optimized for Apple Silicon's AArch64 architecture
- Uses AArch64-specific features:
  - 64-bit registers (x0-x30)
  - Advanced SIMD instructions
  - Conditional execution
  - Load/Store instructions
  - System call interface 