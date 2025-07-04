const main = @import("main.zig");

pub const hit_record = struct {
    p: main.point3,
    normal: main.Vec3,
    t: f64,
};

pub const hittable = struct {
    pub fn hit(self: *const hittable, r: main.Ray, t_min: f64, t_max: f64, rec: *hit_record) bool {
        // TODO: This function should be overridden by the concrete hittable types.
        _ = self;
        _ = r;
        _ = t_min;
        _ = t_max;
        _ = rec;
        return false;
    }
};
