const std = @import("std");

const RGB = packed struct {
    r: u8,
    g: u8,
    b: u8,
};

const Color = packed struct {
    rgb: RGB,
};

const sphere = struct {
    center: point3,
    radius: f64,

    pub fn init(center: point3, radius: f64) sphere {
        return sphere{ .center = center, .radius = radius };
    }

    pub fn hit(self: sphere, ray: Ray) f64 {
        return hitSphere(self.center, self.radius, ray);

        // TODO: This function should be overridden by the concrete hittable types.
        // Find the nearest intersection of the ray with the sphere.

    }
};

fn hitSphere(center: point3, radius: f64, ray: Ray) f64 {
    const oc = ray.origin().sub(center);
    const a = ray.direction().lengthSquared();
    const b = ray.direction().dot(oc);
    const c = oc.lengthSquared() - radius * radius;
    const discriminant = b * b - a * c;

    std.debug.print("a = {d}, b = {d}, c = {d}, discriminant = {d}\n", .{ a, b, c, discriminant });

    if (discriminant < 0) {
        return -1.0;
    } else {
        return (-b - std.math.sqrt(discriminant)) / a;
    }
}

fn ray_color(ray: Ray) Color {
    const sphere_center = point3.init(0, 0, -1);
    const radius = 0.5;
    const t = hitSphere(sphere_center, radius, ray);
    std.debug.print("t = {d}\n", .{t});
    if (t > 0.0) {
        const N = ray.at(t).sub(sphere_center).unitVector();
        return Color{
            .rgb = RGB{
                .r = @intFromFloat(255.999 * (N.x() + 1.0) * 0.5),
                .g = @intFromFloat(255.999 * (N.y() + 1.0) * 0.5),
                .b = @intFromFloat(255.999 * (N.z() + 1.0) * 0.5),
            },
        };
    }

    const unit_direction: Vec3 = ray.direction().unitVector();
    const a: f64 = 0.5 * (unit_direction.y() + 1.0);
    const white = Vec3.init(1.0, 1.0, 1.0);
    const blue = Vec3.init(0.5, 0.7, 1.0);
    const blended = white.multiply(1.0 - a).add(blue.multiply(a));

    return Color{
        .rgb = RGB{
            .r = @intFromFloat(255.999 * blended.x()),
            .g = @intFromFloat(255.999 * blended.y()),
            .b = @intFromFloat(255.999 * blended.z()),
        },
    };
}

pub const point3 = Vec3;

const Ray = struct {
    orig: point3,
    dir: Vec3,

    pub fn init(orig: point3, dir: Vec3) Ray {
        return Ray{
            .orig = orig,
            .dir = dir,
        };
    }
    pub fn at(self: Ray, t: f64) point3 {
        return self.orig.add(self.dir.multiply(t));
    }
    pub fn origin(self: Ray) point3 {
        return self.orig;
    }
    pub fn direction(self: Ray) Vec3 {
        return self.dir;
    }
};

pub const Vec3 = struct {
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
    pub fn dot(self: Vec3, other: Vec3) f64 {
        return self.data[0] * other.data[0] + self.data[1] * other.data[1] + self.data[2] * other.data[2];
    }
    pub fn cross(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .data = .{
                self.data[1] * other.data[2] - self.data[2] * other.data[1],
                self.data[2] * other.data[0] - self.data[0] * other.data[2],
                self.data[0] * other.data[1] - self.data[1] * other.data[0],
            },
        };
    }
    pub fn normalize(self: Vec3) Vec3 {
        const len = self.length();
        if (len == 0) {
            return self; // Avoid division by zero
        }
        return self.divide(len);
    }
    pub fn unitVector(self: Vec3) Vec3 {
        return self.normalize();
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
    const mutiplier = @as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height));
    const viewport_width: f64 = viewport_height * mutiplier;
    const camera_center = point3.init(0, 0, 0);

    // Vectors across horizontal and vertical axes

    const viewport_horizontal = Vec3.init(viewport_width, 0, 0);
    const viewport_vertical = Vec3.init(0, -viewport_height, 0);

    const pixel_delta_horizontal = viewport_horizontal.divide(@floatFromInt(image_width));
    const pixel_delta_vertical = viewport_vertical.divide(@floatFromInt(image_height));

    const viewport_origin = camera_center
        .sub(Vec3.init(0, 0, focal_length))
        .sub(viewport_vertical.multiply(0.5))
        .sub(viewport_horizontal.multiply(0.5));

    const pixel_origin = viewport_origin
        .add(pixel_delta_horizontal.multiply(0.5))
        .add(pixel_delta_vertical.multiply(0.5));

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var ppm = try PPM.init(allocator, image_width, image_height);
    defer ppm.deinit();

    // Fill the image with a gradient
    for (0..image_height) |y| {
        std.debug.print("Row remaining {d}\n", .{image_height - y});
        for (0..image_width) |x| {
            const index = y * image_width + x;

            const pixel_position = pixel_origin
                .add(pixel_delta_horizontal.multiply(@floatFromInt(x)))
                .add(pixel_delta_vertical.multiply(@floatFromInt(y)));

            const ray_direction = pixel_position.sub(camera_center);

            const ray = Ray.init(camera_center, ray_direction);
            const color = ray_color(ray);

            ppm.data[index].rgb = RGB{
                .r = color.rgb.r,
                .g = color.rgb.g,
                .b = color.rgb.b,
            };
        }
    }
    std.debug.print("Done.      \n", .{});

    try ppm.saveInFile("test.ppm");
}
