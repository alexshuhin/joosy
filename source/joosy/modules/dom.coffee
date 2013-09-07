#= require joosy/joosy

#
# DOM container handling, DOM elements and DOM events bindings
#
# @note Requires implementor to contain DOM node at @$container propert
#
# @mixin
#
Joosy.Modules.DOM =
  eventSplitter: /^(\S+)\s*(.*)$/

  included: ->
    #
    # Extends elements mapping scheme
    #
    # @example
    #   @mapElements
    #     'name':       '.selector'
    #     'name2':      '$name .selector'
    #     'category':
    #       'name3':    '.selector'
    #
    @mapElements = (map) ->
      unless @::hasOwnProperty "__elements"
        @::__elements = Joosy.Module.merge {}, @.__super__.__elements
      Joosy.Module.merge @::__elements, map

    #
    # Extends events mapping scheme
    #
    # @example
    #   @mapEvents
    #     'click':            ($container, event) -> #fires on container
    #     'click .selector':  ($element, event) -> #fires on .selector
    #     'click $name':      ($element, event) -> #fires on selector assigned to 'name' element
    #
    @mapEvents = (map) ->
      unless @::hasOwnProperty "__events"
        @::__events = Joosy.Module.merge {}, @.__super__.__events
      Joosy.Module.merge @::__events, map

  $: (selector, context) ->
    $(selector, context || @$container)

  #
  # Converts '$...' notation to selector from 'elements'
  #
  # @param [String] selector            Selector to convert
  # @private
  #
  __extractSelector: (selector) ->
    selector = selector.replace /(\$[A-z0-9\.\$]+)/g, (path) =>
      path    = path.split('.')
      keyword = path.pop()

      target = @
      target = target?[part] for part in path

      target?[keyword]?.selector

    selector.trim()

  #
  # Assigns elements defined in 'elements'
  #
  # @private
  # @example Sample elements
  #   @mapElements
  #     foo: '.foo'
  #     bar: '.bar'
  #
  __assignElements: (root, entries) ->
    root    ||= @
    entries ||= @__elements

    return unless entries

    for key,value of entries
      if value.constructor == Object
        @__assignElements root['$'+key]={}, value
      else
        value = @__extractSelector value
        root['$'+key] = @__wrapElement(value)
        root['$'+key].selector = value

  #
  # Wraps actual element closures. Required to clear context to avoid circular reference
  #
  # @private
  #
  __wrapElement: (value) ->
    (context) =>
      return @$(value) unless context
      return @$(value, context)

  #
  # Binds events defined in 'events' to container
  #
  # @private
  # @example Sample events
  #   @mapEvents
  #     'click': -> # this will raise on container click
  #     'click .foo': -> # this will raise on .foo click
  #     'click $foo': -> #this will search for selector of foo element
  #
  __delegateEvents: ->
    module = @
    events = @__events

    return unless events

    for keys, method of events
      do (keys, method) =>
        for key in keys.split(',')
          key = key.replace(/^\s+/, '')

          unless typeof(method) == 'function'
            method = @[method]
          callback = (event) ->
            method.call module, $(this), event

          match      = key.match @eventSplitter
          eventName  = match[1]
          selector   = @__extractSelector match[2]

          if selector == ""
            @$container.bind eventName, callback
            Joosy.Modules.Log.debugAs @, "#{eventName} binded on container"
          else if selector == undefined
            throw new Error "Unknown element #{match[2]} in #{Joosy.Module.__className @constructor} (maybe typo?)"
          else
            @$container.on eventName, selector, callback
            Joosy.Modules.Log.debugAs @, "#{eventName} binded on #{selector}"

  # @private
  __clearContainer: ->
    @$container.unbind().off()
    @$container = $()


# AMD wrapper
if define?.amd?
  define 'joosy/modules/dom', -> Joosy.Modules.DOM
