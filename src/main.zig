const sdl = @cImport(@cInclude("SDL2/SDL.h"));
const std = @import("std");

const screen_width = 1920;
const screen_height = 1080;

const Paddle = struct { width: i32 = 200, height: i32 = 30, x: i32 = 500, y: i32 = screen_height - 60, vel_x: i32 = 0 };
const Ball = struct { radius: i32 = 15, x: i32 = screen_width / 2, y: i32 = screen_height / 2, vel_x: i32 = 0, vel_y: i32 = 0 };
const Block = struct { width: i32 = 200, height: i32 = 30, x: i32, y: i32, hp: i32 = 1 };

fn handle_event(event: sdl.SDL_Event) bool {
    var should_close = false;
    switch (event.type) {
        sdl.SDL_QUIT => should_close = true,
        else => should_close = false,
    }
    return should_close;
}

pub fn render_borders(renderer: ?*sdl.SDL_Renderer) void {
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

pub fn render_paddle(renderer: ?*sdl.SDL_Renderer, paddle: *Paddle) void {
    const paddle_rect = sdl.SDL_Rect{ .x = paddle.x, .y = paddle.y, .w = paddle.width, .h = paddle.height };
    _ = sdl.SDL_SetRenderDrawColor(renderer, 0xcc, 0xcc, 0xcc, 0xff);
    _ = sdl.SDL_RenderFillRect(renderer, &paddle_rect);
}

pub fn render_block(renderer: ?*sdl.SDL_Renderer, block: *Block) void {
    const block_rect = sdl.SDL_Rect{ .x = block.x, .y = block.y, .w = block.width, .h = block.height };
    _ = sdl.SDL_SetRenderDrawColor(renderer, 0x00, 0xcc, 0xcc, 0xff);
    _ = sdl.SDL_RenderFillRect(renderer, &block_rect);
}

// Midpoint Circle Algorithm, repeated in order to fill.  It doesn't fill completely, but the missing pixels
// look like arrows, which works aesthetically.
pub fn render_ball(renderer: ?*sdl.SDL_Renderer, ball: *Ball) void {
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

    var paddle = Paddle{};
    var ball = Ball{};
    var block = Block{ .x = 30, .y = 30 };

    var running = true;
    while (running) {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) > 0) {
            const should_close = handle_event(event);
            if (should_close) {
                running = false;
            }
        }
        _ = sdl.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
        _ = sdl.SDL_RenderClear(renderer);
        render_borders(renderer);
        render_paddle(renderer, &paddle);
        render_ball(renderer, &ball);
        render_block(renderer, &block);
        _ = sdl.SDL_RenderPresent(renderer);
    }
}
