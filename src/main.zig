const sdl = @cImport(@cInclude("SDL2/SDL.h"));
const std = @import("std");

const screen_width = 1920;
const screen_height = 1080;

const Paddle = struct { width: i32 = 200, height: i32 = 30, x: i32 = (screen_width / 2) - 100, y: i32 = screen_height - 60, vel_x: f64 = 0, left_bound: i32 = 30, right_bound: i32 = screen_width - 230, max_vel: f64 = 1000 };
const Ball = struct { radius: i32 = 15, x: i32 = screen_width / 2, y: i32 = screen_height / 2, vel_x: f64 = 0, vel_y: f64 = 0 };
const Block = struct { width: i32 = 200, height: i32 = 30, x: i32, y: i32, hp: i32 = 1 };
const KeyState = struct { is_down: bool = false, was_down: bool = false };
const KeyboardState = struct { left: KeyState = KeyState{}, right: KeyState = KeyState{} };

fn handle_event(event: sdl.SDL_Event, keyboard_state: *KeyboardState) bool {
    var should_close = false;
    switch (event.type) {
        sdl.SDL_QUIT => should_close = true,
        sdl.SDL_KEYDOWN => {
            switch (event.key.keysym.sym) {
                sdl.SDLK_LEFT => keyboard_state.left.is_down = true,
                sdl.SDLK_RIGHT => keyboard_state.right.is_down = true,
                else => {},
            }
        },
        sdl.SDL_KEYUP => {
            switch (event.key.keysym.sym) {
                sdl.SDLK_LEFT => keyboard_state.left.is_down = false,
                sdl.SDLK_RIGHT => keyboard_state.right.is_down = false,
                else => {},
            }
        },
        else => should_close = false,
    }
    return should_close;
}

fn render_borders(renderer: ?*sdl.SDL_Renderer) void {
    const top_rect = sdl.SDL_Rect{ .x = 0, .y = 0, .w = screen_width, .h = 10 };
    const left_rect = sdl.SDL_Rect{ .x = 0, .y = 10, .w = 10, .h = screen_height - 20 };
    const right_rect = sdl.SDL_Rect{ .x = screen_width - 10, .y = 10, .w = 10, .h = screen_height - 20 };
    const bottom_rect = sdl.SDL_Rect{ .x = 0, .y = screen_height - 10, .w = screen_width, .h = 10 };
    _ = sdl.SDL_SetRenderDrawColor(renderer, 0x00, 0x60, 0x5b, 0xff);
    _ = sdl.SDL_RenderFillRect(renderer, &top_rect);
    _ = sdl.SDL_RenderFillRect(renderer, &left_rect);
    _ = sdl.SDL_RenderFillRect(renderer, &right_rect);
    _ = sdl.SDL_RenderFillRect(renderer, &bottom_rect);
}

fn render_paddle(renderer: ?*sdl.SDL_Renderer, paddle: *Paddle) void {
    const paddle_rect = sdl.SDL_Rect{ .x = paddle.x, .y = paddle.y, .w = paddle.width, .h = paddle.height };
    _ = sdl.SDL_SetRenderDrawColor(renderer, 0xcc, 0xcc, 0xcc, 0xff);
    _ = sdl.SDL_RenderFillRect(renderer, &paddle_rect);
}

fn render_block(renderer: ?*sdl.SDL_Renderer, block: *Block) void {
    if (block.hp > 0) {
        const block_rect = sdl.SDL_Rect{ .x = block.x, .y = block.y, .w = block.width, .h = block.height };
        _ = sdl.SDL_SetRenderDrawColor(renderer, 0x00, 0xcc, 0xcc, 0xff);
        _ = sdl.SDL_RenderFillRect(renderer, &block_rect);
    }
}

// Midpoint Circle Algorithm, repeated in order to fill.  It doesn't fill completely, but the missing pixels
// look like arrows, which works aesthetically.
fn render_ball(renderer: ?*sdl.SDL_Renderer, ball: *Ball) void {
    var diameter: i32 = ball.radius * 2;
    _ = sdl.SDL_SetRenderDrawColor(renderer, 0xcc, 0xcc, 0xcc, 0xff);

    while (diameter > 0) {
        const radius: i32 = @divFloor(diameter, 2);
        var x: i32 = radius - 1;
        var y: i32 = 0;
        var tx: i32 = 1;
        var ty: i32 = 1;
        var err: i32 = tx - diameter;

        while (x >= y) {
            _ = sdl.SDL_RenderDrawPoint(renderer, ball.x + x, ball.y - y);
            _ = sdl.SDL_RenderDrawPoint(renderer, ball.x + x, ball.y + y);
            _ = sdl.SDL_RenderDrawPoint(renderer, ball.x - x, ball.y - y);
            _ = sdl.SDL_RenderDrawPoint(renderer, ball.x - x, ball.y + y);
            _ = sdl.SDL_RenderDrawPoint(renderer, ball.x + y, ball.y - x);
            _ = sdl.SDL_RenderDrawPoint(renderer, ball.x + y, ball.y + x);
            _ = sdl.SDL_RenderDrawPoint(renderer, ball.x - y, ball.y - x);
            _ = sdl.SDL_RenderDrawPoint(renderer, ball.x - y, ball.y + x);

            if (err <= 0) {
                y += 1;
                err += ty;
                ty += 2;
            }

            if (err > 0) {
                x -= 1;
                tx += 2;
                err += tx - diameter;
            }
        }

        diameter -= 2;
    }
}

fn test_border_collision(ball: *Ball) bool {
    if (ball.y > screen_height - ball.radius - 10) {
        return true;
    } else if (ball.y < ball.radius + 10) {
        ball.vel_y = -ball.vel_y;
    }
    if ((ball.x < ball.radius + 10) or (ball.x > screen_width - ball.radius - 10)) {
        ball.vel_x = -ball.vel_x;
    }
    return false;
}

fn test_paddle_collision(ball: *Ball, paddle: *Paddle) void {
    if ((ball.y + ball.radius > paddle.y) and (ball.x - ball.radius > paddle.x) and (ball.x - ball.radius < paddle.x + paddle.width)) {
        ball.vel_y = -ball.vel_y;
        ball.vel_x += paddle.vel_x;
    }
}

fn test_block_collision(ball: *Ball, block: *Block) void {
    if (block.hp > 0 and (ball.y + ball.radius > block.y) and (ball.y - ball.radius < block.y + block.height) and (ball.x - ball.radius > block.x) and (ball.x - ball.radius < block.x + block.width)) {
        ball.vel_y = -ball.vel_y;
        block.hp -= 1;
    }
}

pub fn main() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) < 0) {
        std.debug.print("Failed to initialise SDL: {s}\n", .{sdl.SDL_GetError()});
        return error.Unknown;
    }
    defer sdl.SDL_Quit();

    const window_flags = 0;

    const window = sdl.SDL_CreateWindow("Zigenoid", sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED, screen_width, screen_height, window_flags);
    if (window == null) {
        std.debug.print("Failed to initialise SDL: {s}\n", .{sdl.SDL_GetError()});
        return error.Unknown;
    }
    defer sdl.SDL_DestroyWindow(window);

    const renderer = sdl.SDL_CreateRenderer(window, -1, 0);
    if (renderer == null) {
        std.debug.print("Failed to initialise SDL: {s}\n", .{sdl.SDL_GetError()});
        return error.Unknown;
    }
    defer sdl.SDL_DestroyRenderer(renderer);

    // TODO: Replace all of this with a gamestate singleton
    var paddle = Paddle{};
    var ball = Ball{ .vel_y = 10 };
    var keyboard_state = KeyboardState{};

    // TODO: Replace this with an 8x8 grid, which can optionally have a block inside.
    var blocks = std.ArrayList(Block).init(std.heap.page_allocator);
    defer blocks.deinit();
    blocks.append(Block{ .x = 55, .y = 30 }) catch |err| {
        return err;
    };
    blocks.append(Block{ .x = 285, .y = 30 }) catch |err| {
        return err;
    };
    blocks.append(Block{ .x = 515, .y = 30 }) catch |err| {
        return err;
    };
    blocks.append(Block{ .x = 745, .y = 30 }) catch |err| {
        return err;
    };
    blocks.append(Block{ .x = 975, .y = 30 }) catch |err| {
        return err;
    };
    blocks.append(Block{ .x = 1205, .y = 30 }) catch |err| {
        return err;
    };
    blocks.append(Block{ .x = 1435, .y = 30 }) catch |err| {
        return err;
    };
    blocks.append(Block{ .x = 1665, .y = 30 }) catch |err| {
        return err;
    };

    var running = true;

    const freq = @as(f64, @floatFromInt(sdl.SDL_GetPerformanceFrequency()));
    var count = @as(f64, @floatFromInt(sdl.SDL_GetPerformanceCounter()));
    var last_frame = count / freq;
    while (running) {
        count = @as(f64, @floatFromInt(sdl.SDL_GetPerformanceCounter()));
        const curr_frame = count / freq;
        const dt = curr_frame - last_frame;
        last_frame = curr_frame;
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) > 0) {
            const should_close = handle_event(event, &keyboard_state);
            if (should_close) {
                running = false;
            }
        }

        if (keyboard_state.left.is_down) {
            paddle.vel_x -= 30 * dt;
        }
        if (keyboard_state.right.is_down) {
            paddle.vel_x += 30 * dt;
        }

        paddle.x += @as(i32, @intFromFloat(paddle.vel_x));

        if (paddle.vel_x > paddle.max_vel) {
            paddle.vel_x = paddle.max_vel;
        } else if (paddle.vel_x < -paddle.max_vel) {
            paddle.vel_x = -paddle.max_vel;
        }

        if (paddle.vel_x > 0) {
            paddle.vel_x -= 10 * dt;
        } else if (paddle.vel_x < 0) {
            paddle.vel_x += 10 * dt;
        }
        if (paddle.x < paddle.left_bound) {
            paddle.x = paddle.left_bound;
            paddle.vel_x = -paddle.vel_x;
        } else if (paddle.x > paddle.right_bound) {
            paddle.x = paddle.right_bound;
            paddle.vel_x = -paddle.vel_x;
        }

        ball.x += @as(i32, @intFromFloat(ball.vel_x));
        ball.y += @as(i32, @intFromFloat(ball.vel_y));

        const should_close = test_border_collision(&ball);
        if (should_close) {
            running = false;
        }
        test_paddle_collision(&ball, &paddle);
        for (0..blocks.items.len) |i| {
            test_block_collision(&ball, &blocks.items[i]);
        }

        _ = sdl.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
        _ = sdl.SDL_RenderClear(renderer);
        render_borders(renderer);
        render_paddle(renderer, &paddle);
        render_ball(renderer, &ball);
        for (0..blocks.items.len) |i| {
            render_block(renderer, &blocks.items[i]);
        }
        _ = sdl.SDL_RenderPresent(renderer);

        count = @as(f64, @floatFromInt(sdl.SDL_GetPerformanceCounter()));
        const end_frame = (count / freq) - curr_frame;
        const ms_per_frame: f64 = 1000.0 / 60.0;
        sdl.SDL_Delay(@as(u32, @intFromFloat(ms_per_frame - end_frame)));
    }
}
