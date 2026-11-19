function language_import(_filename) {

    // Destroy the language map if it already exists
    if (ds_exists(global.language_map,ds_type_map)) {
        ds_map_destroy(global.language_map);
    }
    
    // Load the JSON file for the current language into a string
    var _json_file = working_directory + _filename;
    var _json_string = "";
    
    var _text_file = file_text_open_read(_json_file);
    do {
        
        _json_string += file_text_read_string(_text_file);
        file_text_readln(_text_file);
        
    } until (file_text_eof(_text_file))
    file_text_close(_text_file);
    
    // Decode the current JSON file into a DS map and assign it to the global.language_map variable
    global.language_map = json_decode(_json_string);
    
    // The remaining lines of code are simply for printing the result of the language import as
    // a debug message. You can comment these out or delete them if you don't need them.
    var _ds_size = ds_map_size(global.language_map);
    show_debug_message("GM Languages loaded strings: "+string(_ds_size)+" detected");
    var _ds_key = ds_map_find_first(global.language_map);
    show_debug_message(_ds_key);
    for (var i=0; i<_ds_size-1; i++) {
    
        _ds_key = ds_map_find_next(global.language_map,_ds_key);
        show_debug_message(_ds_key);
        
    }

}