const std = @import("std");

const RGB = packed struct {
    r: u8,
    g: u8,
    b: u8,
};

const Color = packed struct {
    rgb: RGB,
};

fn ray_color(ray: Ray) Color {
    const unit_direction: Vec3 = ray.direction().divide(ray.direction().length());
    const t: f64 = 0.5 * (unit_direction.y() + 1.0);
    const white = Vec3.init(1.0, 1.0, 1.0);
    const blue = Vec3.init(0.5, 0.7, 1.0);
    const blended = white.multiply(1.0 - t).add(blue.multiply(t));

    return Color{
        .rgb = RGB{
            .r = @intFromFloat(255.999 * blended.x()),
            .g = @intFromFloat(255.999 * blended.y()),
            .b = @intFromFloat(255.999 * blended.z()),
        },
    };
}

const point3 = Vec3;

const Ray = struct {
    orig: point3,
    dir: Vec3,

    pub fn init(orig: Vec3, dir: point3) Ray {
        return Ray{
            .orig = orig,
            .dir = dir,
        };
    }
    pub fn at(self: Ray, t: f64) point3 {
        return self.origin.add(self.direction.multiply(t));
    }
    pub fn origin(self: Ray) point3 {
        return self.origin;
    }
    pub fn direction(self: Ray) Vec3 {
        return self.dir;
    }
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

    pub fn sub(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .data = .{
                self.data[0] - other.data[0],
                self.data[1] - other.data[1],
                self.data[2] - other.data[2],
            },
        };
    }

    pub fn multiply(self: Vec3, scalar: f64) Vec3 {
        return Vec3{
            .data = .{
                self.data[0] * scalar,
                self.data[1] * scalar,
                self.data[2] * scalar,
            },
        };
    }
    pub fn divide(self: Vec3, scalar: f64) Vec3 {
        return Vec3{
            .data = .{
                self.data[0] / scalar,
                self.data[1] / scalar,
                self.data[2] / scalar,
            },
        };
    }

    pub fn lengthSquared(self: Vec3) f64 {
        return self.data[0] * self.data[0] + self.data[1] * self.data[1] + self.data[2] * self.data[2];
    }
    pub fn length(self: Vec3) f64 {
        return std.math.sqrt(self.lengthSquared());
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

    // Aspect ratio
    const aspect_ratio: f64 = 16.0 / 9.0;
    const image_width: u64 = 400;

    // Image
    var image_height: u64 = @intFromFloat(image_width / aspect_ratio);
    image_height = @max(image_height, 1); // Ensure height is at least 1

    // Camera

    const focal_length = 1.0;
    const viewport_height: f64 = 2.0;
    const mutiplier: f64 = @floatFromInt(image_width / image_height);
    const viewport_width: f64 = viewport_height * mutiplier;
    const camera_center = point3.init(0, 0, 0);

    // Vectors across horizontal and vertical axes

    const viewport_horizontal = Vec3.init(viewport_width, 0, 0);
    const viewport_vertical = Vec3.init(0, -viewport_height, 0);

    const pixel_delta_horizontal = viewport_horizontal.divide(@floatFromInt(image_width));
    const pixel_delta_vertical = viewport_vertical.divide(@floatFromInt(image_height));

    const viewport_origin = camera_center.sub(Vec3.init(0, 0, focal_length)).sub(viewport_vertical.multiply(0.5)).sub(viewport_horizontal.multiply(0.5));

    const pixel_origin = viewport_origin.add(pixel_delta_horizontal.multiply(0.5)).add(pixel_delta_vertical.multiply(0.5));

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var ppm = try PPM.init(allocator, image_width, image_height);
    defer ppm.deinit();

    // Fill the image with a gradient
    for (0..image_height) |y| {
        std.debug.print("Row remaining {d}\n", .{image_height - y});
        for (0..image_width) |x| {
            const index = y * image_width + x;
            const pixel_position = pixel_origin.add(pixel_delta_horizontal.multiply(@floatFromInt(x))).add(pixel_delta_vertical.multiply(@floatFromInt(y)));
            const ray_direction = pixel_position.sub(camera_center);

            const ray = Ray.init(camera_center, ray_direction);
            const color = ray_color(ray);

            ppm.data[index].rgb = RGB{
                .r = color.rgb.r,
                .g = color.rgb.g,
                .b = color.rgb.b,
            };

            // var r: f64 = @as(f64, @floatFromInt(x)) / @as(f64, @floatFromInt(image_width - 1));
            // var g: f64 = @as(f64, @floatFromInt(y)) / @as(f64, @floatFromInt(image_width - 1));
            // var b: f64 = 0;
            //
            // r *= 255.999;
            // g *= 255.999;
            // b *= 255.999;
            //
            // const index = y * image_width + x;
            //
            // ppm.data[index].rgb = RGB{
            //     .r = @intFromFloat(r),
            //     .g = @intFromFloat(g),
            //     .b = @intFromFloat(b),
            // };
        }
    }
    std.debug.print("Done.      \n", .{});

    try ppm.saveInFile("test.ppm");
}
