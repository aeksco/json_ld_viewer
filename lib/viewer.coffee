EdgePointer = require('./edge')
DagreProcess = require('./dagre')
Graph = require('./graph')

# # # # #

# TODO - this should be abstracted into a different method that can easily be overwritten.
# TODO - perhaps this should be a part of the resource class?
makeNodeSVG = (entities, vis, nodeWidth, graph, renderer) ->
  node = vis.selectAll('g.node').data(entities).enter()

  # TODO - options.nodeWidth
  node = node.append('svg:foreignObject')
  .attr('width', nodeWidth)
  .attr('style', 'overflow:hidden;')

  node.append('xhtml:body')
  body = node.selectAll('body')

  resource = body.append('div')
  .attr('data-uri', (d) -> d.uri )
  .attr('style', 'position:inherit;').attr('class', (d) -> d.getClass())
  .html((d) -> d.render() )

  return node

# TODO - this should be abstracted into the graph class
# TODO - perhaps this should be a part of the Predicate class?
makePredicateSVG = (predicates, vis) ->
  result = vis.selectAll('g.predicate')
  .data(predicates)
  .enter()
  # .append('svg:foreignObject')
  .append("svg:text")
  .attr("class","link")
  .attr("text-anchor","middle")
  .attr("alignment-baseline","middle")
  .attr('x', (d) -> d.x )
  .attr('y', (d) -> d.y )
  # .text( (d) -> return d.render() )
  .html( (d) -> d.render() )

  # body = result.append('xhtml:body')
  # .append('div')
  # .attr('data-uri', (d) -> d.uri )
  # .attr('style', 'position:inherit;').attr('class', (d) -> d.classes )
  # .append('div').html( (d) -> d.render() )

  return result

# TODO - this should be abstracted into the graph class
# TODO - should be link class
makeLinkSVG = (edges, vis) ->
  result = {}
  result.link = vis.selectAll('line.link').data(edges).enter().append('svg:g').attr('class', 'link')
  result.link.append('svg:line')
  .attr('class', 'link')
  .attr('x1', (d) -> d.source.x)
  .attr('y1', (d) -> d.source.y)
  .attr('x2', (d) -> d.target.x)
  .attr('y2', (d) -> d.target.y)

  result.arrowhead = result.link.filter((d) ->
    d.arrow
  ).append('svg:polygon').attr('class', 'arrowhead').attr('transform', (d) ->
    angle = Math.atan2(d.y2 - (d.y1), d.x2 - (d.x1))
    'rotate(' + angle + ', ' + d.x2 + ', ' + d.y2 + ')'

  ).attr('points', (d) ->
    [
      [d.x2, d.y2].join(',')
      [d.x2 - 3, d.y2 + 8].join(',')
      [d.x2 + 3,d.y2 + 8].join(',')
    ].join ' '
  )

  return result

# TODO - needed in 4.0 upgrade?
d3.selection::moveToFront = ->
  @each ->
    @parentNode.appendChild this
    return

# TODO - abstract and make more configurable
# TODO - must update to D3 ~4.0

viewRDF = (element, w, h, json, nodeWidth) ->
  # VARS - what stays, what goes?
  svg = d3.select(element)
  chart = d3.select(svg.node().parentNode)
  width = 0
  height = 0
  # // // // // // // // // //
  # TODO - should all be linked to resize events

  updateSize = ->
    width = parseInt(chart.style('width'))
    height = parseInt(chart.style('height'))
    svg.attr('width', width).attr 'height', height
    return

  window.svg = svg
  $(window).resize updateSize
  updateSize()
  # // // // // // // // // //
  # Builds the SVG layout
  svg.append('rect').attr('width', '100%').attr('height', '100%').attr 'class', 'rdf-canvas'
  container = svg.append('g').attr('id', 'navigator')
  vis = container.append('g').attr('id', 'navigator-inner')
  selector = container.append('rect').attr('class', 'selector').attr('display', 'none')
  # TODO - this should be abstracted into the graph class

  loadGraph = (graph) ->
    zoomed = false
    inner = d3.select('svg g')
    zoom = d3.zoom()
    links = makeLinkSVG(graph.edges, vis)
    predicates = makePredicateSVG(graph.predicates, vis)
    node = makeNodeSVG(graph.entities, vis, nodeWidth, graph, render)
    selected = null
    drag = d3.drag()
    moved = false
    # // // // // //
    # TODO - Controls Class
    # TODO - should be part of the graph class

    update = ->
      # TODO - links should be their own class
      # TODO - this can be abstracted heavily
      links.link.selectAll('line.link')
      .attr('x1', (d) -> EdgePointer.coordinate(d, 'x1', 'x', 'source', 0))
      .attr('y1', (d) -> EdgePointer.coordinate(d, 'y1', 'y', 'source', 1))
      .attr('x2', (d) -> EdgePointer.coordinate(d, 'x2', 'x', 'target', 0))
      .attr('y2', (d) -> EdgePointer.coordinate(d, 'y2', 'y', 'target', 1))

      selector.attr('display', if selected != null then null else 'none').attr('height', if selected != null then selected.height + 2 else 0).attr('width', if selected != null then selected.width + 2 else 0).attr('x', if selected != null then selected.x - (selected.width / 2) - 1 else 0).attr 'y', if selected != null then selected.y - (selected.height / 2) - 1 else 0
      node.filter((d) -> d == selected)
      .each (d) ->
        d3.select(this).moveToFront()
        return

      predicates.filter((d) -> d == selected)
      .each (d) ->
        d3.select(this).moveToFront()
        return

      # Nodes
      node
      .attr('x', (d) -> d.x - (d.width / 2))
      .attr('y', (d) -> d.y - (d.height / 2))

      # Predicates
      predicates
      .attr('x', (d) -> d.x)
      .attr('y', (d) -> d.y)

      # Links w/ arrowhead
      links.arrowhead.attr('points', (d) ->
        [
          [d.x2, d.y2].join(',')
          [d.x2 - 3, d.y2 + 8].join(',')
          [d.x2 + 3, d.y2 + 8].join(',')
        ].join ' '
      ).attr 'transform', (d) ->
        angle = Math.atan2(d.y2 - (d.y1), d.x2 - (d.x1)) * 180 / Math.PI + 90
        'rotate(' + angle + ', ' + d.x2 + ', ' + d.y2 + ')'
      return

    # TODO - should be part of the graph class

    render = ->
      # TODO - should be part of NODE class
      node.attr('height', (d) ->
        d.height = @childNodes[0].childNodes[0].clientHeight + 4
      ).attr 'width', (d) ->
        if d.width == 0 or d.width == nodeWidth
          d.width = @childNodes[0].childNodes[0].clientWidth + 4
        d.width
      # TODO - should be part of PREDICATE class
      predicates.each (d) ->
        d.height = @clientHeight + 4
        d.width = @clientWidth + 4
        return
      # DAGRE invoked
      DagreProcess node.data(), predicates.data(), links.link.data()
      # QUESTION - why Links.link.data?
      update()
      return

    zoom.on 'zoom', ->
      inner.attr 'transform', 'translate(' + d3.event.transform.x + ',' + d3.event.transform.y + ')' + ' scale(' + d3.event.transform.k + ')'
      zoomed = true
      return
    zoom.on 'start', ->
      zoomed = false
      return
    zoom.on 'end', ->
      if !zoomed
        selected = null
        update()
      return
    # // // // // //
    # TODO - drag class
    drag.on 'drag', (d, i) ->
      d.x += d3.event.dx
      d.y += d3.event.dy
      update()
      moved = true
      return
    drag.on 'start', (d) ->
      # console.log('DRAG START');
      Backbone.Radio.channel('data').trigger 'clicked', d.id
      moved = false
      d3.event.sourceEvent.stopPropagation()
      d3.select(this).classed 'dragging', true
      return
    drag.on 'end', (d) ->
      d3.select(this).classed 'dragging', false
      if !moved
        selected = if selected == d then null else d
        update()
      return
    #
    # // // // // //
    node.call drag
    predicates.call drag
    svg.call zoom
    render()
    return

  # TODO - pass in graph options
  # ResourceClass/NodeClass, PredicateClass, etc.
  # TODO - pass in JSON as option to graph
  graph = new Graph()
  graph.load(json)
  loadGraph(graph)
  return

# TODO - remove and export via a standardized wrapper function
# window.viewRDFNew = viewRDF

# # # # #

module.exports = viewRDF
