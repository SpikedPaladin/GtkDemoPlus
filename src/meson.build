deps = [
    dependency('gtk4'),
    dependency('libadwaita-1'),
    dependency('gl')
]

sources = files(
    'app.vala',
)

subdir('models')
subdir('ui')

app = executable(
    output,
    
    resources,
    sources,
    dependencies: deps,
    link_args : [ '-lepoxy', '-lm' ],
    win_subsystem: 'windows',
    install: true,
)
