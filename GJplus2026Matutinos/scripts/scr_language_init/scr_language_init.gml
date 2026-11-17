function lang(_string) {
    if(variable_struct_exists(global.language_map, _string)){
        return global.language_map[$ _string];
    }
   
    return _string;
}