const std = @import("std");

const RGB = packed struct {
    r: u8,
    g: u8,
    b: u8,
};

const Color = packed struct {
    rgb: RGB,
};

const PPM = struct {
    image_width: usize,
    image_height: usize,
    data: []Color,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !PPM {
        const self = PPM{ .image_width = width, .image_height = height, .data = try allocator.alloc(Color, width * height), .allocator = allocator };

        return self;
    }
    fn deinit(self: *PPM) void {
        self.allocator.free(self.data);
    }
    pub fn saveInFile(self: *PPM, filename: []const u8) !void {
        var file = try std.fs.cwd().openFile(filename, .{ .mode = .write_only });
        defer file.close();
        errdefer file.close();

        var fwriter = file.writer();
        try fwriter.print("P3\n{} {}\n255\n", .{ self.image_width, self.image_height });

        for (self.data) |pixel| {
            // Output color
            try fwriter.print("{} {} {}\n", .{ pixel.rgb.r, pixel.rgb.g, pixel.rgb.b });
        }
    }
};

pub fn main() !void {
    // Image
    const image_width: usize = 256;
    const image_height: usize = 256;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var ppm = try PPM.init(allocator, image_width, image_height);
    defer ppm.deinit();

    // Fill the image with a gradient
    for (0..image_height) |y| {
        for (0..image_width) |x| {
            const index = y * image_width + x;
            ppm.data[index].rgb = RGB{
                .r = @intCast(x % 256),
                .g = @intCast(y % 256),
                .b = @intCast((x + y) % 256),
            };
        }
    }

    try ppm.saveInFile("test.ppm");
}
