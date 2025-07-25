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

const symbols = "$$**++--@@==";
const camrea_v = Vec3{
    .x = 0,
    .y = 0,
    .z = 1,
};

fn drawCube(rx: f32, ry: f32, rz: f32) void {
    for (cube_triangles, 0..) |triangle, s| {
        var transformed_vertices: [3]Vec3 = undefined;
        for (0..3) |i| {
            transformed_vertices[i] = cube_vertices[triangle[i]];
            transformed_vertices[i] = rotateAroundX(transformed_vertices[i], rx);
            transformed_vertices[i] = rotateAroundY(transformed_vertices[i], ry);
            transformed_vertices[i] = rotateAroundZ(transformed_vertices[i], rz);

            transformed_vertices[i].z += 8;
            const scale = 60;
            transformed_vertices[i].y *= scale;
            transformed_vertices[i].x *= scale * 3;
        }

        const v_01 = Vec3{
            .x = transformed_vertices[1].x - transformed_vertices[0].x,
            .y = transformed_vertices[1].y - transformed_vertices[0].y,
            .z = transformed_vertices[1].z - transformed_vertices[0].z,
        };
        const v_02 = Vec3{
            .x = transformed_vertices[2].x - transformed_vertices[0].x,
            .y = transformed_vertices[2].y - transformed_vertices[0].y,
            .z = transformed_vertices[2].z - transformed_vertices[0].z,
        };
        const normal = cross_product(v_01, v_02);
        if (dot_product(camrea_v, normal) >= 0) {
            continue;
        }

        var projected_points: [3]Vec2 = undefined;
        for (0..3) |i| {
            projected_points[i] = project(transformed_vertices[i]);
        }
        drawTriangle(projected_points[0], projected_points[1], projected_points[2], symbols[s]);
    }
}

fn dot_product(a: Vec3, b: Vec3) f32 {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

fn cross_product(a: Vec3, b: Vec3) Vec3 {
    return Vec3{
        .x = a.y * b.z - a.z * b.y,
        .y = a.z * b.x - a.x * b.z,
        .z = a.x * b.y - a.y * b.x,
    };
}

fn rotateAroundY(v: Vec3, rotation_angle_red: f32) Vec3 {
    return Vec3{
        .x = @cos(rotation_angle_red) * v.x + @sin(rotation_angle_red) * v.z,
        .y = v.y,
        .z = @sin(rotation_angle_red) * v.x + @cos(rotation_angle_red) * v.z,
    };
}

fn rotateAroundZ(v: Vec3, rotation_angle_red: f32) Vec3 {
    return Vec3{
        .x = @cos(rotation_angle_red) * v.x - @sin(rotation_angle_red) * v.y,
        .y = @sin(rotation_angle_red) * v.x + @cos(rotation_angle_red) * v.y,
        .z = v.z,
    };
}

fn rotateAroundX(v: Vec3, rotation_angle_red: f32) Vec3 {
    return Vec3{
        .x = v.x,
        .y = @cos(rotation_angle_red) * v.y - @sin(rotation_angle_red) * v.z,
        .z = @sin(rotation_angle_red) * v.y + @cos(rotation_angle_red) * v.z,
    };
}

fn project(v: Vec3) Vec2 {
    return Vec2{
        .x = @round(v.x / v.z + NB_COLS / 2),
        .y = @round(v.y / v.z + NB_ROWS / 2),
    };
}

fn drawTriangle(vec0: Vec2, vec1: Vec2, vec2: Vec2, symbol: u8) void {
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
        drawFlatBottom(v0, v1, v2, symbol);
        return;
    }
    if (v0.y == v1.y) {
        drawFlatTop(v0, v1, v2, symbol);
    }

    const midpoint = Vec2{
        .x = v0.x + (v2.x - v0.x) * (v1.y - v0.y) / (v2.y - v0.y),
        .y = v1.y,
    };
    drawFlatBottom(v0, v1, midpoint, symbol);
    drawFlatTop(v1, midpoint, v2, symbol);
}

fn drawFlatTop(t0: Vec2, t1: Vec2, b: Vec2, symbol: u8) void {
    var x_b = t0.x;
    var x_e = t1.x;

    const x_inc_0: f32 = (b.x - t0.x) / (b.y - t0.y);
    const x_inc_1: f32 = (b.x - t1.x) / (b.y - t1.y);

    const y_b: usize = @intFromFloat(t0.y);
    const y_e: usize = @intFromFloat(b.y + 1);
    for (y_b..y_e) |y| {
        drawScanLine(y, @intFromFloat(@round(x_b)), @intFromFloat(@round(x_e)), symbol);
        x_b += x_inc_0;
        x_e += x_inc_1;
    }
}

fn drawFlatBottom(t: Vec2, b0: Vec2, b1: Vec2, symbol: u8) void {
    var x_b = t.x;
    var x_e = t.x;

    const x_dec_0: f32 = (t.x - b0.x) / (b0.y - t.y);
    const x_dec_1: f32 = (t.x - b1.x) / (b1.y - t.y);

    const y_b: usize = @intFromFloat(t.y);
    const y_e: usize = @intFromFloat(b0.y + 1);
    for (y_b..y_e) |y| {
        // update values of x_b and x_e
        drawScanLine(y, @intFromFloat(@round(x_b)), @intFromFloat(@round(x_e)), symbol);
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

var target_delta_time_ns: i128 = 16_666_667;
var prev_time_ns: i128 = undefined;

fn setTargetFPS(fps: i128) void {
    prev_time_ns = std.time.nanoTimestamp();
    target_delta_time_ns = @divTrunc(@as(i128, 1e9), fps);
}

fn getDeltaTime() f32 {
    const now = std.time.nanoTimestamp();
    const delta_t_ns = now - prev_time_ns;
    prev_time_ns = now;
    const sleep_time = target_delta_time_ns - delta_t_ns;
    if (sleep_time > 0) {
        std.time.sleep(@intCast(sleep_time));
    } else {
        return @as(f32, @floatFromInt(delta_t_ns)) * @as(f32, 1e-9);
    }
    return @as(f32, @floatFromInt(delta_t_ns)) * @as(f32, 1e-9);
}

pub fn main() !void {
    setTargetFPS(60);
    const stdout = std.io.getStdOut().writer();
    // clears screen & hides cursor

    try stdout.writeAll("\x1B[2J\x1B[?25l");
    // put cursor at position (0 , 0)
    buffer[0] = '\x1B';
    buffer[1] = '[';
    buffer[2] = 'H';
    var rx: f32 = 0.0;
    var ry: f32 = 0.0;
    var rz: f32 = 0.0;
    while (true) {
        const delta_time = getDeltaTime();
        clearScreen();
        // update
        //drawFlatBottom(Vec2{ .x = 100, .y = 5 }, Vec2{ .x = 200, .y = 30 }, Vec2{ .x = 10, .y = 30 });
        //drawFlatTop(Vec2{ .x = 200, .y = 5 }, Vec2{ .x = 10, .y = 5 }, Vec2{ .x = 100, .y = 30 });
        //drawTriangle(Vec2{ .x = 10, .y = 5 }, Vec2{ .x = 150, .y = 15 }, Vec2{ .x = 70, .y = 34 });
        drawCube(rx, ry, rz);
        try displayScreen(stdout);
        rx = @mod((rx + 0.8 * delta_time), (2 * std.math.pi));
        ry = @mod((ry + 0.8 * delta_time), (2 * std.math.pi));
        rz = @mod((rz + 0.8 * delta_time), (2 * std.math.pi));

        // std.time.sleep(100_000_000);
    }
}
