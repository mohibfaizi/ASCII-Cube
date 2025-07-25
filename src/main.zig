const std = @import("std");

const NB_COLS = 206;
const NB_ROWS = 49;

var screen: [NB_ROWS][NB_COLS]u8 = .{.{' '} ** NB_COLS} ** NB_ROWS;
const cleard_screen: [NB_ROWS][NB_COLS]u8 = .{.{' '} ** NB_COLS} ** NB_ROWS;
var buffer: [3 + NB_ROWS * (NB_COLS + 1)]u8 = undefined;

fn displayScreen(stdout: std.fs.File.Writer) !void {
    for (0..NB_ROWS) |i| { // for (int i =0; i < NB_ROWS; i++)
        const offset = 3 + i * (NB_COLS + 1);
        @memcpy(buffer[offset .. offset + NB_COLS], &screen[i]);
        buffer[offset + NB_COLS] = '\n';
    }
    try stdout.writeAll(&buffer);
}

fn clearScreen() void {
    screen = cleard_screen;
}

const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
};
const Vec2 = struct {
    x: f32,
    y: f32,
};

const cube_vertices: [8]Vec3 = .{
    Vec3{ .x = -1, .y = -1, .z = -1 }, // 0
    Vec3{ .x = -1, .y = 1, .z = -1 }, // 1
    Vec3{ .x = 1, .y = 1, .z = -1 }, // 2
    Vec3{ .x = 1, .y = -1, .z = -1 }, // 3
    Vec3{ .x = 1, .y = 1, .z = 1 }, // 4
    Vec3{ .x = 1, .y = -1, .z = 1 }, // 5
    Vec3{ .x = -1, .y = -1, .z = 1 }, // 6
    Vec3{ .x = -1, .y = 1, .z = 1 }, // 7
};

const cube_triangles: [12][3]u8 = .{
    // front face
    .{ 0, 1, 2 },
    .{ 0, 2, 3 },
    // right
    .{ 3, 2, 4 },
    .{ 3, 4, 5 },
    // back
    .{ 5, 4, 7 },
    .{ 5, 7, 6 },
    // left
    .{ 6, 7, 1 },
    .{ 6, 1, 0 },
    // top
    .{ 6, 0, 3 },
    .{ 6, 3, 5 },
    // bottom
    .{ 1, 7, 4 },
    .{ 1, 4, 2 },
};

fn drawCube() void {
    for (cube_triangles) |triangle| {
        var transformed_vertices: [3]Vec3 = undefined;
        for (0..3) |i| {
            transformed_vertices[i] = cube_vertices[triangle[i]];
        }
    }
}

fn drawTriangle(v0: Vec2, v1: Vec2, v2: Vec2) void {
    _ = v0;
    _ = v1;
    _ = v2;
}

fn drawFlatBottom(t: Vec2, b0: Vec2, b1: Vec2) void {
    var x_b = t.x;
    var x_e = t.x;

    const x_dec_0: f32 = (t.x - b0.x) / (b0.y - t.y);
    const x_dec_1: f32 = (t.x - b1.x) / (b1.y - t.y);

    const y_b: usize = @intFromFloat(t.y);
    const y_e: usize = @intFromFloat(b0.y + 1);
    for (y_b..y_e) |y| {
        // update values of x_b and x_e
        drawScanLine(y, @intFromFloat(@round(x_b)), @intFromFloat(@round(x_e)), '*');
        x_b -= x_dec_0;
        x_e -= x_dec_1;
    }
}

fn drawScanLine(y: usize, x0: usize, x1: usize, symbol: u8) void {
    var left = x0;
    var right = x1;
    if (left > right) {
        left = x1;
        right = x0;
    }

    for (left..right + 1) |x| {
        screen[y][x] = symbol;
    }
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
        clearScreen();
        // update
        drawFlatBottom(Vec2{ .x = 100, .y = 5 }, Vec2{ .x = 200, .y = 30 }, Vec2{ .x = 10, .y = 30 });
        try displayScreen(stdout);
        std.time.sleep(100_000_000);
    }
}
