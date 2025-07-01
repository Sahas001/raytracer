const std = @import("std");

const RGB = packed struct {
    r: u8,
    g: u8,
    b: u8,
};

const Color = packed struct {
    rgb: RGB,
};

const Vec3 = struct {
    data: @Vector(3, f64),

    pub fn init(a: f64, b: f64, c: f64) Vec3 {
        return Vec3{ .data = @Vector(3, f64){ a, b, c } };
    }

    pub fn x(self: Vec3) f64 {
        return self.data[0];
    }
    pub fn y(self: Vec3) f64 {
        return self.data[1];
    }
    pub fn z(self: Vec3) f64 {
        return self.data[2];
    }

    pub fn setX(self: *Vec3, ordinate: f64) void {
        self.data[0] = ordinate;
    }
    pub fn setY(self: *Vec3, ordinate: f64) void {
        self.data[1] = ordinate;
    }
    pub fn setZ(self: *Vec3, ordinate: f64) void {
        self.data[2] = ordinate;
    }
    pub fn add(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .data = .{
                self.data[0] + other.data[0],
                self.data[1] + other.data[1],
                self.data[2] + other.data[2],
            },
        };
    }
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
        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();
        errdefer file.close();

        const fwriter = file.writer();

        var bufferedWriter = std.io.bufferedWriter(fwriter);
        var bwriter = bufferedWriter.writer();

        try bwriter.print("P3\n{} {}\n255\n", .{ self.image_width, self.image_height });

        for (self.data) |pixel| {
            // Output color
            try bwriter.print("{} {} {}\n", .{ pixel.rgb.r, pixel.rgb.g, pixel.rgb.b });
        }
        try bufferedWriter.flush();
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
        std.debug.print("Row remaining {d}\n", .{image_height - y});
        for (0..image_width) |x| {
            var r: f64 = @as(f64, @floatFromInt(x)) / @as(f64, @floatFromInt(image_width - 1));
            var g: f64 = @as(f64, @floatFromInt(y)) / @as(f64, @floatFromInt(image_width - 1));
            var b: f64 = 0;

            r *= 255.999;
            g *= 255.999;
            b *= 255.999;

            const index = y * image_width + x;

            ppm.data[index].rgb = RGB{
                .r = @intFromFloat(r),
                .g = @intFromFloat(g),
                .b = @intFromFloat(b),
            };
        }
    }
    std.debug.print("Done.      \n", .{});

    try ppm.saveInFile("test.ppm");
}
