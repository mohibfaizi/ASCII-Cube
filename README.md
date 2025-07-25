# Zig ASCII Cube

This is a fun project written in Zig that renders a spinning 3D cube using ASCII characters in your terminal.

## How to Run

To run the project, you will need to have Zig installed. You can find installation instructions on the [official Zig website](https://ziglang.org/learn/getting-started/).

Once Zig is installed, you can clone this repository and run the following command in the project's root directory:

```bash
zig build run
```

This will compile and run the application, and you should see a spinning ASCII cube in your terminal.

## Code Overview

The project is structured into a few key files:

*   `src/main.zig`: This is the main entry point of the application. It contains all the logic for rendering the cube, handling the screen buffer, and the main application loop.
*   `build.zig`: This file contains the build script for the project. It defines how to compile the executable and run the application.

