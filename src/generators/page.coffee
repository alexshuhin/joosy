Generator = require './generator'

module.exports = class extends Generator
  @generate: (name) -> (new @(name)).generate()

  constructor: (@name, destination, templates) ->
    super(destination, templates)

  files: ->
    namespace = @getNamespace @name
    basename  = @getBasename @name

    [
      @join @destination, 'pages', @join(namespace...), "#{basename}.coffee"
      @join @destination, 'templates', 'pages', @join(namespace...), "#{basename}.jst.hamlc"
    ]

  generate: (skip) ->
    return false unless @exists(@destination)

    files = @files()

    @template ['page', 'basic.coffee'], files[0],
      namespace_name: @getNamespace(@name).map (x) -> x.camelize()
      class_name: @getBasename(@name).camelize()
      view_name: @name

    @file files[1]

    @actions