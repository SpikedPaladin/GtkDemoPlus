blueprints = files(
    'ui/main-listitem.blp',
    'ui/main-window.blp',
    'ui/notebook.blp',
    
    'ui/dialogs/add-item-dialog.blp',
    
    'ui/items/reorderable-item.blp',
    
    'ui/pages/animation-page.blp',
    'ui/pages/reorderable-page.blp',
    'ui/pages/transition-page.blp',
)

blp_target = custom_target(
    'blueprints',
    
    input: blueprints,
    output: '.',
    command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
)

resources = gnome.compile_resources(
    'resources',
    'gresource.xml',
    source_dir: meson.current_build_dir(),
    dependencies: blp_target
)

message(get_option('datadir'))

install_data(
    output + '.gschema.xml',
    install_dir: get_option('datadir') / 'glib-2.0' / 'schemas'
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
    test(
        'Validate schema file',
        compile_schemas,
        args: ['--strict', '--dry-run', meson.current_source_dir()]
    )
endif