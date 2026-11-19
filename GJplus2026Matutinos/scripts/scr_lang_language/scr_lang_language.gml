function lang(_string) {
    if (ds_map_exists(global.language_map, _string)) {
        return global.language_map[? _string];
    }
    return _string;
}