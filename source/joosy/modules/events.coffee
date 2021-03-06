#= require joosy/joosy

# @nodoc
class SynchronizationContext
  constructor:    -> @actions = []
  do: (action)    -> @actions.push action
  after: (@after) ->

#
# @nodoc
#
# Events namespace
#
# Creates unified collection of bindings to a particular instance
# that can be unbinded alltogether
#
# @example
#   namespace = new Namespace(something)
#
#   namespace.bind 'event1', ->
#   namespace.bind 'event2', ->
#   namespace.unbind() # unbinds both bindings
#
class Namespace
  #
  # @param [Object] @parent         Any instance that can trigger events
  #
  constructor: (@parent) ->
    @bindings = []

  bind: (args...) ->
    @bindings.push @parent.bind(args...)

  unbind: ->
    @parent.unbind b for b in @bindings
    @bindings = []


#
# Basic events implementation
#
# @mixin
#
Joosy.Modules.Events =

  #
  # Creates events namespace
  #
  # @example
  #   namespace = @entity.eventsNamespace ->
  #     @bind 'action1', ->
  #     @bind 'action2', ->
  #
  #   namespace.unbind()
  #
  # @example
  #   namespace = @entity.eventsNamespace()
  #   namespace.bind 'action1', ->
  #   namespace.bind 'action2', ->
  #   namespace.unbind()
  #
  eventsNamespace: (actions) ->
    namespace = new Namespace @
    actions?.call?(namespace)
    namespace

  #
  # Waits for the list of given events to happen at least once. Then runs callback.
  #
  # @overload ~wait(events, callback)
  #   Uses internal unique ID as the name of the binding
  #
  # @overload ~wait(name, events, callback)
  #   Allows to pass custom name for the binding
  #
  # @param [String] name                Custom name for the binding
  # @param [String] events              List of events to wait for separated by space
  # @param [Array] events               List of events to wait in the form of Array
  # @param [Function] callback          Action to run when all events were triggered at least once
  # @param [Hash] options               Options
  #
  # @return [String]                    An ID (or custom name) of binding
  #
  wait: (name, events, callback) ->
    @__oneShotEvents = {} unless @hasOwnProperty('__oneShotEvents')

    # (events, callback) ->
    if arguments.length == 2
      callback = events
      events   = name
      name     = @__allocateEventName(@__oneShotEvents)

    events = @__splitEvents(events)

    if events.length > 0
      @__oneShotEvents[name] = [events, callback]
    else
      callback()

    name

  #
  # Removes waiter action
  #
  # @param [String] target            Name of {Joosy.Modules.Events~wait} binding
  #
  unwait: (target) ->
    delete @__oneShotEvents[target] if @hasOwnProperty '__oneShotEvents'

  #
  # Binds action to run each time any of given event was triggered
  #
  # @overload ~bind(events, callback)
  #   Uses internal unique ID as the name of the binding
  #
  # @overload ~bind(name, events, callback)
  #   Allows to pass custom name for the binding
  #
  # @param [String] name                Custom name for the binding
  # @param [String] events              List of events to wait for separated by space
  # @param [Array] events               List of events to wait in the form of Array
  # @param [Function] callback          Action to run on trigger
  #
  # @return [String]                    An ID (or custom name) of binding
  #
  bind: (name, events, callback) ->
    @__boundEvents = {} unless @hasOwnProperty '__boundEvents'

    # (events, callback) ->
    if arguments.length == 2
      callback = events
      events   = name
      name     = @__allocateEventName(@__boundEvents)

    events = @__splitEvents(events)

    if events.length > 0
      @__boundEvents[name] = [events, callback]
    else
      callback()

    name

  #
  # Unbinds action from runing on trigger
  #
  # @param [String] target            Name of {Joosy.Modules.Events~bind} binding
  #
  unbind: (target) ->
    delete @__boundEvents[target] if @hasOwnProperty '__boundEvents'

  #
  # @private
  #
  __allocateEventName: (collection) ->
    eventIndex = 0

    while collection.hasOwnProperty(eventIndex.toString())
      eventIndex += 1

    eventIndex.toString()

  #
  # Triggers event for {Joosy.Modules.Events~bind} and {Joosy.Modules.Events~wait}
  #
  # @param [String] event           Name of event to trigger
  # @param [Mixed] data             Data to pass to event
  #
  trigger: (event, data...) ->
    Joosy.Modules.Log.debugAs @, "Event #{event} triggered"

    if typeof(event) == 'string'
      remember = false
    else
      remember = event.remember
      event    = event.name

    if @hasOwnProperty '__oneShotEvents'
      fire = []
      for name, [events, callback] of @__oneShotEvents
        while (needle = events.indexOf(event)) != -1
          events.splice needle, 1

        if events.length == 0
          fire.push name
      for name in fire
        do (name) =>
          callback = @__oneShotEvents[name][1]
          delete @__oneShotEvents[name]
          callback data...

    if @hasOwnProperty '__boundEvents'
      for name, [events, callback] of @__boundEvents
        if events.indexOf(event) != -1
          callback data...

    if remember
      @__triggeredEvents = {} unless @hasOwnProperty '__triggeredEvents'
      @__triggeredEvents[event] = true

  #
  # Runs set of callbacks finializing with result callback
  #
  # @example Basic usage
  #   @synchronize (context) ->
  #     context.do (done) -> done()
  #     context.do (done) -> done()
  #     context.after ->
  #       console.log 'Success!'
  #
  # @param [Function] block           Configuration block (see example)
  #
  synchronize: (block) ->
    context = new SynchronizationContext
    counter = 0

    block(context)

    if context.actions.length == 0
      context.after.call(@)
    else
      for action in context.actions
        do (action) =>
          action.call @, ->
            if ++counter >= context.actions.length
              context.after.call(@)

  #
  # Turns the list of events given in form of stiring into the array
  #
  # @param [String] events
  # @return [Array]
  # @private
  #
  __splitEvents: (events) ->
    if typeof(events) == 'string'
      if events.length == 0
        events = []
      else
        events = events.trim().split /\s+/

    if @hasOwnProperty '__triggeredEvents'
      events = events.filter (e) => !@__triggeredEvents[e]

    events

# AMD wrapper
if define?.amd?
  define 'joosy/modules/events', -> Joosy.Modules.Events