const std = @import("std");

pub fn main() !void {

    // Image
    const image_width: u16 = 256;
    const image_height: u16 = 256;

    // Render
    const stdout = std.io.getStdOut().writer();
    try stdout.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |i| {
        for (0..image_width) |j| {
            // Color
            const r: u8 = @intCast(i * 255 / (image_height - 1));
            const g: u8 = @intCast(j * 255 / (image_width - 1));
            const b: u8 = 0;

            // Output color
            try stdout.print("{d} {d} {d}\n", .{ r, g, b });
        }
    }
}
