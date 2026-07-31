# Pong in MSP430 Assembly

This is a single-player Pong game that I wrote in MSP430 assembly for the **MSP430FR6989**. The game uses a 128×128 TFT display for the paddle and ball, the joystick for player input, the LaunchPad's segmented LCD for the score, and a buzzer for sound effects.

I made this project mainly to practice working directly with a microcontroller's peripherals in assembly. Instead of relying on a graphics or hardware library, the program configures and controls the SPI interface, ADC, timers, GPIO interrupts, LCD memory, and buzzer directly.

## What the game does

- Draws a black paddle and a red ball on a white TFT background
- Reads the joystick's vertical axis through the 12-bit ADC
- Moves the ball using a timer interrupt
- Detects collisions with the paddle and the edges of the screen
- Ends the round when the player misses the ball
- Keeps score on the MSP430FR6989 LaunchPad's six-digit segmented LCD
- Increases the ball and paddle step size after the first score digit rolls over
- Plays different buzzer tones for a paddle hit and for game over
- Randomizes the starting positions using ADC readings mixed with timer values

## Hardware

The project is configured for:

- TI MSP430FR6989 LaunchPad
- 128×128 SPI TFT display
- Analog joystick
- Buzzer
- The LaunchPad's built-in segmented LCD and push buttons

The TFT, joystick, and buzzer pin usage matches an Educational BoosterPack MKII-style setup. If a different expansion board is used, the GPIO and ADC mappings in `Pong.asm` will need to be changed.

### Important pin and peripheral assignments

| Function | Assignment used in the code |
| --- | --- |
| TFT interface | eUSCI_B0 in SPI master mode |
| TFT D/C | P2.3 |
| TFT chip select | P2.5 |
| TFT reset | P9.4 |
| Buzzer | P2.7 |
| Joystick horizontal axis | ADC input A10 |
| Joystick vertical axis | ADC input A4 |
| Push buttons | P1.1 and P1.2 |
| Score display | MSP430 LCD controller |

Only the vertical joystick direction is needed during normal gameplay. The horizontal ADC reading is still used as part of the random starting-position calculation.

## Controls

- Press **P1.2 / S2** to begin a round.
- Move the joystick up or down to control the paddle.
- Press **P1.1 / S1** during the game to reset and start a new round.

The goal is to keep returning the ball with the paddle for as long as possible. Missing the ball on the left side ends the round and plays the game-over sound.

## How the program works

Most of the game is interrupt-driven. After the hardware is initialized, the main loop simply waits while the peripherals handle the actual gameplay.

### Display

The TFT is controlled through eUSCI_B0 in SPI mode. Commands and pixel data are sent using the `tft_cmd_sr`, `tft_data_sr`, and `spi_byte` routines. The program sets drawing windows on the display and writes BGR pixel values directly.

To keep drawing simple, the paddle and ball are moved by:

1. Drawing the old pixels in white
2. Updating their coordinates
3. Drawing the new pixels in black or red

### Paddle input

The ADC repeatedly samples the joystick. The `ADC12_ISR` compares the vertical reading against upper and lower thresholds. If the joystick is outside the center region, the paddle is moved while still checking the screen boundaries.

### Ball movement and collision detection

Timer0_A controls the ball update rate. The ball direction is stored as one of four states:

| State | Direction |
| --- | --- |
| 0 | Up-right |
| 1 | Up-left |
| 2 | Down-right |
| 3 | Down-left |

`MoveBall` uses a jump table to choose the correct coordinate update. `CheckBallBounds` then handles:

- Top and bottom wall bounces
- Right wall bounces
- Paddle collisions
- A missed paddle and game over

### Score and difficulty

Timer1_A updates the score on the LaunchPad's segmented LCD. The LCD patterns are stored in lookup tables and written directly into the correct LCD memory locations.

The score currently behaves like a survival timer rather than a hit counter. After the first decimal rollover, the movement step changes from one pixel to two pixels, making the game faster.

### Sound

The buzzer routines generate square waves directly on P2.7 using software delays. A low note is used for a paddle hit, while a short descending sequence is used for game over.

## Register usage

Because the project is written entirely in assembly, several registers have fixed jobs during the game:

| Register | Purpose |
| --- | --- |
| R4 | Paddle movement direction |
| R5 | Temporary value and jump-table offset |
| R6 | Ball X coordinate |
| R7 | Ball Y coordinate |
| R8 | Paddle top coordinate |
| R9 | Paddle bottom coordinate |
| R10, R11, R13 | Blue, green, and red pixel bytes |
| R12 | Loop counter |
| R14 | Ball direction state |
| R15 | General subroutine and macro argument |

## Project structure

```text
Pong_Assembly/
├── Pong.asm                         # Game logic and hardware control
├── lnk_msp430fr6989.cmd             # MSP430FR6989 linker configuration
├── targetConfigs/
│   ├── MSP430FR6989.ccxml           # CCS target/debug configuration
│   └── readme.txt
├── .ccsproject                      # Code Composer Studio project settings
├── .cproject                        # Build configurations
└── .project                         # Eclipse/CCS project metadata
```

## Building and running

The repository already contains a Code Composer Studio project. Its saved configuration uses **Code Composer Studio 12.2.0** and **TI MSP430 Code Generation Tools 21.6.1.LTS**.

1. Clone this repository:

   ```bash
   git clone https://github.com/SafwanKamal/Pong_Assembly.git
   ```

2. Open Code Composer Studio.
3. Go to **File → Import → Code Composer Studio → CCS Projects**.
4. Select the cloned `Pong_Assembly` directory.
5. Confirm that the target device is **MSP430FR6989**.
6. Connect the LaunchPad with the display/joystick expansion board attached.
7. Build the project.
8. Start a debug session and load the program onto the board.
9. Run the program and press **S2** to start.

If CCS asks for a compiler version that is not installed, either install the recorded MSP430 compiler version or change the project to an available compatible MSP430 toolchain.

## Main source sections

The main routines in `Pong.asm` are:

- `HardResetState` — clears the previous peripheral and game state
- `Configuration` — initializes the TFT controller
- `CanvasReset` — clears the screen and starts a new round
- `MovePaddle` and `DrawPaddle` — update the paddle graphics
- `MoveBall` and `DrawBall` — update the ball graphics
- `CheckBallBounds` — handles wall, paddle, and game-over collisions
- `SetRandomBallXY` and `SetRandomPaddleX` — generate starting coordinates
- `LCDWrite` — writes score digits to the segmented LCD
- `ADC12_ISR` — processes joystick movement
- `TIMER0_A0_ISR` — updates the ball
- `Timer1_A0_ISR` — updates the score and game speed
- `PORT1_ISR` — handles the push buttons

## Possible improvements

Some directions I would like to explore further are:

- Separating the display driver and game logic into different assembly files
- Making the score count paddle hits instead of elapsed time
- Adding a proper start screen and game-over message
- Using hardware PWM for the buzzer instead of delay loops
- Adding multiple speed levels instead of one step increase
- Improving button and joystick debouncing
- Adding a second paddle or another game mode
