const std = @import("std");

const NB_COLS = 206;
const NB_ROWS = 49;

var screen: [NB_ROWS][NB_COLS]u8 = .{.{' '} ** NB_COLS} ** NB_ROWS;
const cleard_screen: [NB_ROWS][NB_COLS]u8 = .{.{' '} ** NB_COLS} ** NB_ROWS;
var buffer: [3 + NB_ROWS * (NB_COLS + 1)]u8 = undefined;

fn display_screen(stdout: std.fs.File.Writer) !void {
    for (0..NB_ROWS) |i| { // for (int i =0; i < NB_ROWS; i++)
        const offset = 3 + i * (NB_COLS + 1);
        @memcpy(buffer[offset .. offset + NB_COLS], &screen[i]);
        buffer[offset + NB_COLS] = '\n';
    }
    try stdout.writeAll(&buffer);
}

fn clear_scren() void {
    screen = cleard_screen;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    // clears screen & hides cursor

    try stdout.writeAll("\x1B[2J\x1B[?25l");
    // put cursor at position (0 , 0)
    buffer[0] = '\x1B';
    buffer[1] = '[';
    buffer[2] = 'H';
    while (true) {
        clear_scren();
        // update
        screen[10][20] = '*';
        screen[10][21] = '*';
        screen[10][22] = '*';
        screen[10][23] = '*';
        try display_screen(stdout);
        std.time.sleep(100_000_000);
    }
}
