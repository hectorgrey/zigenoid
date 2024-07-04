const sdl = @cImport(@cInclude("SDL2/SDL.h"));
const std = @import("std");

pub fn main() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) < 0) {
        std.debug.print("Failed to initialise SDL: {s}\n", .{sdl.SDL_GetError()});
        return error.Unknown;
    }
    defer sdl.SDL_Quit();

    const window_flags = 0;
    const screen_width = 1920;
    const screen_height = 1080;

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

    var running = true;
    while (running) {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) > 0) {
            switch (event.type) {
                sdl.SDL_QUIT => running = false,
                else => {},
            }
        }
        _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = sdl.SDL_RenderClear(renderer);
        _ = sdl.SDL_RenderPresent(renderer);
    }
}
