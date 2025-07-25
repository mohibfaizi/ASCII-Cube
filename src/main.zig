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

fn drawTriangle(vec0: Vec2, vec1: Vec2, vec2: Vec2) void {
    var v0 = vec0;
    var v1 = vec1;
    var v2 = vec2;
    //sort the vertices by ASC y
    if (v0.y > v1.y) {
        v0 = vec1;
        v1 = vec0;
    }
    if (v1.y > v2.y) {
        const tmp = v2;
        v2 = v1;
        v1 = tmp;
    }
    if (v0.y > v1.y) {
        const tmp = v0;
        v0 = v1;
        v1 = tmp;
    }

    if (v2.y == v1.y) {
        drawFlatBottom(v0, v1, v2);
        return;
    }
    if (v0.y == v1.y) {
        drawFlatTop(v0, v1, v2);
    }

    const midpoint = Vec2{
        .x = v0.x + (v2.x - v0.x) * (v1.y - v0.y) / (v2.y - v0.y),
        .y = v1.y,
    };
    drawFlatBottom(v0, v1, midpoint);
    drawFlatTop(v1, midpoint, v2);
}

fn drawFlatTop(t0: Vec2, t1: Vec2, b: Vec2) void {
    var x_b = t0.x;
    var x_e = t1.x;

    const x_inc_0: f32 = (b.x - t0.x) / (b.y - t0.y);
    const x_inc_1: f32 = (b.x - t1.x) / (b.y - t1.y);

    const y_b: usize = @intFromFloat(t0.y);
    const y_e: usize = @intFromFloat(b.y + 1);
    for (y_b..y_e) |y| {
        drawScanLine(y, @intFromFloat(@round(x_b)), @intFromFloat(@round(x_e)), '*');
        x_b += x_inc_0;
        x_e += x_inc_1;
    }
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
        //drawFlatBottom(Vec2{ .x = 100, .y = 5 }, Vec2{ .x = 200, .y = 30 }, Vec2{ .x = 10, .y = 30 });
        //drawFlatTop(Vec2{ .x = 200, .y = 5 }, Vec2{ .x = 10, .y = 5 }, Vec2{ .x = 100, .y = 30 });
        drawTriangle(Vec2{ .x = 10, .y = 5 }, Vec2{ .x = 150, .y = 15 }, Vec2{ .x = 70, .y = 34 });
        try displayScreen(stdout);
        std.time.sleep(100_000_000);
    }
}
