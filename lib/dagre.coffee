uuid4 = ->
  d = (new Date).getTime()
  uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
    r = (d + Math.random() * 16) % 16 | 0
    d = Math.floor(d / 16)
    (if c == 'x' then r else r & 0x3 | 0x8).toString 16
  )
  uuid


DagreProcess = (nodes, predicates, links, rankDir='lr') ->

  # Create a new directed graph
  g = new (dagre.graphlib.Graph)(multigraph: true)

  # Set an object for the graph label
  g.setGraph {}

  # Default to assigning a new object as a label for each new edge.
  g.setDefaultEdgeLabel -> {}

  # TODO - nodes should be their own class
  nodes.forEach (node) ->
    # if (!node.id) { if (node.type == 'resource') { node.id = node.uri; }}
    node.id = node.uri
    g.setNode node.uri, node
    return

  # TODO - predicates should be their own class
  # ID should be assigned in constructor.
  predicates.forEach (predicate) ->
    if !predicate.id
      predicate.id = uuid4()
    g.setNode predicate.uri, predicate
    return

  # Links should be own class
  links.forEach (link) ->
    g.setEdge link.source.uri, link.target.uri
    return

  opts = {}
  opts.nodesep = 10
  opts.ranksep = 10
  opts.edgesep = 20
  opts.align = 'rb'
  # opts.rankdir = rankDir || 'tb'
  opts.rankdir = 'tb'
  # opts.align = 'UD';
  # opts.ranker = "tight-tree"
  # opts.ranker = 'longest-path'
  # opts.acyclicer = "greedy";
  # opts.marginx = 30
  # opts.marginy = 30
  dagre.layout g, opts

  dimension = 'x'
  down = d3.min
  up = d3.max

  switch opts.rankdir.toLowerCase()
    when 'lr'
      dimension = 'x'
      down = d3.min
      up = d3.max
    when 'lr'
      dimension = 'x'
      down = d3.min
      up = d3.max
    when 'rl'
      dimension = 'x'
      down = d3.max
      up = d3.min
    when 'tb'
      dimension = 'y'
      down = d3.min
      up = d3.max
    when 'bt'
      dimension = 'y'
      down = d3.max
      up = d3.min

  positions = d3.set(d3.merge([
    predicates.map((x) ->
      x[dimension]
    )
    nodes.map((x) ->
      x[dimension]
    )
  ])).values().map(parseFloat)

  scale = d3.scaleThreshold().domain(positions).range(positions)

  predicates.forEach (predicate) ->
    subj = predicate.subject[dimension]
    obj = down(predicate.objects, (d) ->
      d[dimension]
    )
    extent = d3.extent([
      subj
      obj
    ])
    if predicate[dimension] < extent[0] or predicate[dimension] > extent[1]
      predicate[dimension] = scale(d3.mean(extent))
    return

  g

# # # # #

module.exports = DagreProcess
