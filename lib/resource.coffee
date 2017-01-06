# TODO - this should be re-written
# TODO - this should be re-written
# This should perhaps be the first part of the re-write

class Resource

  defaults:
    attribs: {}
    depth: -1
    display: false
    isPredicate: false
    label: false
    links: []
    objectOf: []
    objects: []
    relations: {}
    type: 'resource'
    types: []
    uri: false
    width: 0

  template: require './templates/resource'

  getValue: (data) ->
    value = data.value.map( (d) ->
      return d.uri if d.type == "resource"
      return d
    ).join(', ')

    console.log value

    return value

  render: (data) ->
    templateData = _.clone(@)
    _.extend(templateData, { val: @getValue(data) }) if data
    return @template(templateData)

  value: (uri) ->
    console.log 'GETTING VALUE???'
    results = @relations[uri]
    # console.log(results)
    if results == null or results.length == 0
      results = @attribs[uri]
    if results == null or results.length == 0
      return null

    return results[0]

  constructor: (options) ->
    for key, val of @defaults
      @[key] = _.clone(@defaults[key])

    # Sets options
    for key, val of options
      @[key] = options[key]

    # Sets @localPart
    @setLocalPart()

    # Decorators
    # TODO - abstract this into another class
    @setNamespace()
    @setClass()
    @setPLabel()
    @setTitle()

    return @

  # TODO - abstract into decorator class
  # TODO - should only be invoked after Dagre
  setNamespace: ->
    return @namespace = @predicate.namespace if @predicate

    uri = @uri
    namespace = uri.split("/").filter((str) -> return str.length > 0)
    # console.log namespace
    return '' unless namespace[1] # TODO - remove. this breaks on different sets
    namespace = namespace[1].replace('.org','')
    # console.log namespace
    namespace = namespace.replace('www.openarchives','ore')
    return @namespace = namespace

  setPLabel: ->
    return @pLabel = false unless @predicate
    if !!@predicate.label
      return @pLabel = @predicate.label
    else
      return @pLabel = @predicate.localPart

  setClass: ->
    classes = _.pluck(@types, 'localPart')
    css = 'card card-block resource ' # TODO - make this an option PLEASE.
    # css += @namespace + ' '
    @classes = css + classes.join(' ')

  # TODO - combine this & setClass()
  getClass: ->
    @namespace = @label.split(':')[0]
    @setTypes()
    return @classes + @namespace

  setTitle: ->
    @prettyUri = @uri.replace('http://dmo.org/archive/media/anirban/Work/Mock_Dvds', '/MOCK_DATA')
    @prettyUri = @prettyUri.replace('\%2', '/') # TODO - un-encode URI, underscore?
    @title = @localPart || @prettyUri
    return

  # TODO - decorator
  setTypes: ->
    # console.log @icon
    # console.log @
    # console.log @.comment
    types = []
    for each in @types
      types.push { css: each.namespace, text: each.namespace + ':' + each.localPart }

    @_types = types
    @_types.push { css: @namespace, text: @label }
    return @_types

  # TODO - what's actually happening here?
  setLocalPart: ->
    @localPart = @uri.split('#').filter((d) -> d.length > 0 )
    @localPart = @localPart[@localPart.length - 1]
    @localPart = @localPart.split('/').filter((d) -> d.length > 0 )
    @localPart = @localPart[@localPart.length - 1]
    @label = @localPart
    type = @label.split('.').pop()
    @icon = type.toLowerCase()
    return true

  addRelation: (id, obj) ->
    @relations[id] ||= []
    @relations[id].push obj
    return @

  addType: (resource) ->
    @types.push(resource)
    return @

  addAttr: (key, val) ->
    @attribs[key] ||= []
    @attribs[key].push val

# # # # #

module.exports = Resource
