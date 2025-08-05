pub const Event = union(enum) {
    resize: struct { width: u32, height: u32 },
    quit: void,
};
