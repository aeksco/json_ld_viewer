# TODO - this should be re-written
# TODO - this should be re-written
# This should perhaps be the first part of the re-write

Resource = require './resource'
Predicate = require './predicate'

class Graph
  _resources: {}
  resources: {}
  nodes: []
  edges: []
  predicates: []
  entities: []

  makeLink: (source, target, arrow) ->
    link = {}
    link.source = source
    link.target = target
    link.value = 1
    link.display = true
    link.arrow = arrow
    @edges.push link
    link

  getNamespace: (obj) ->
    uri = obj.uri
    namespace = uri.split("/").filter((str) -> return str.length > 0)
    namespace = namespace[1].replace('.org','')
    namespace = namespace.replace('www.openarchives','ore')
    # console.log namespace
    return namespace

  # THIS IS FIND/CREATE PREDICATE
  getPredicate: (subject, predicate) ->
    uri = subject.uri + ' ' + predicate.uri

    resource = @resources[uri]
    return resource if resource

    # Builds namespace
    namespace = @getNamespace(predicate)
    predicate.namespace = namespace

    # Builds new predicate
    options = {}
    options.pred_namespace = namespace
    options.subject = subject
    options.predicate = predicate
    options.uri = uri

    # TODO - should be abstracted elsewhere
    # Generic AddResource method
    resource = new Predicate(options)
    @resources[resource.uri] = resource

    # Makes link between
    link = @makeLink(subject, resource, false)
    subject.links.push link
    resource.links.push link

    return resource

  # TODO - this should be re-written or removed.
  # The graph itself should not be responsible for any decoration.
  # THIS IS A BIG REPEAT OF WHATS HAPPENING ABOVE
  # THIS WILL BECOME THE RESOURCE CLASS
  getResource: (uri) ->
    resource = @resources[uri]
    return resource if resource

    # TODO - should be abstracted to
    # a FindOrCreate factory method
    resource = new Resource({ uri: uri })
    @resources[uri] = resource
    return resource

  # TODO - what to do with this?
  # TODO - this is part of decoration, not core code
  RDF_TYPE = "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
  RDFS_LABEL = "http://www.w3.org/2000/01/rdf-schema#label"
  FOAF_NAME = "http://xmlns.com/foaf/0.1/name"
  DC_TITLE = "http://purl.org/dc/elements/1.1/title"
  DCT_TITLE = "http://purl.org/dc/terms/title"
  SKOS_PREFLABEL = "http://www.w3.org/2004/02/skos/core#prefLabel"

  WHITELISTED = [RDF_TYPE, RDFS_LABEL, FOAF_NAME, DC_TITLE, DCT_TITLE, SKOS_PREFLABEL]

  # TODO consistent naming
  buildElement: (subj, pred, valuePair) =>

    # Resource
    resource = @getResource(subj.key)
    resource.display = true

    # Predicate
    predicate = @getResource(pred.key)
    predicate.isPredicate = true

    # TODO - valuePair Class

    # console.log 'BUILDING ELEMENT'
    # console.log subj
    # console.log pred
    # console.log resource
    # console.log predicate
    # console.log obj

    # TODO - ValuePair.prototype.isLiteral()
    if valuePair.type == 'literal'
      # console.log pred.key

      if WHITELISTED.indexOf(pred.key) > -1
        resource.label = valuePair.value
      else
        resource.addAttr(predicate.uri, valuePair.value)

      return resource

    # TODO - describes a type?
    else if pred.key == RDF_TYPE
      return resource.addType(@getResource(valuePair.value))

    # TODO - what does this mean?
    else
      # console.log 'ELSE'
      sp = @getPredicate(resource, predicate)
      o = @getResource(valuePair.value)

      # TODO - valuePair Class
      o.label = ' ' if valuePair.type == 'bnode' and o.label == o.uri

      # console.log sp
      sp.objects.push o
      o.display = true
      o.objectOf.push sp
      link = @makeLink(sp, o, true)
      sp.links.push link

      # TODO - resource
      resource.addRelation(predicate.uri, o)

      return resource

  formatResource: (resource) ->
    resource.subject.attribs[resource.predicate.uri] = resource.objects
    resource.display = false
    resource.objects.forEach (o) ->
      o.display = false
      return
    resource.links.forEach (l) ->
      l.display = false
      return

    return resource

  filterResource: (resource) ->
    result = resource.type == 'predicate'

    if result
      result = resource.objects.reduce(((prev, o) ->
        d3.keys(o.attribs).length == 0 and d3.keys(o.relations).length == 0 and o.types.length == 0 and d3.keys(o.objectOf).length == 1 and prev
      ), result)

    return result

  # # # # #

  load: (d) =>

    # Builds all graph elements
    d3.entries(d).forEach (subject) =>
      d3.entries(subject.value).forEach (predicate) =>
        predicate.value.forEach (valuePair) => @buildElement(subject, predicate, valuePair)

    # Sets d3.values
    window.resources = @resources

    d3.values(@resources)
    .filter (resource) => @filterResource(resource)
    .forEach (resource) => @formatResource(resource)

    # # #

    # PREDICATES
    @predicates = d3.values(@resources).filter((node) ->
      if node.type == 'predicate' and !node.isPredicate
        node.display = node.display and node.subject.display
        node.display
      else
        false
    ).filter((node) ->
      node.display = node.display and node.objects.reduce(((prev, o) ->
        prev or o.display
      ), false)
      node.display
    )

    @predicates.forEach (p) ->
      p.label = p.predicate.label
      return

    # #

    # NODES
    @nodes = d3.values(@resources).filter((node) ->
      !node.isPredicate and node.display
    )

    # #

    # ENTITIES
    @entities = d3.values(@resources).filter((node) ->
      node.type == 'resource' and !node.isPredicate and node.display
    ).sort((a, b) ->
      a.objectOf.length - (b.objectOf.length)
    )

    # #

    # EDGES
    @edges = d3.values(@edges).filter((l) ->
      l.display and l.source.display and l.target.display
    )
    return

# # # # #

module.exports = Graph
