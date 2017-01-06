class EdgeSetter

  edges: []

  polygonIntersect = (c, d, a, b) ->
    x1 = c[0]
    x2 = d[0]
    x3 = a[0]
    x4 = b[0]
    y1 = c[1]
    y2 = d[1]
    y3 = a[1]
    y4 = b[1]
    x13 = x1 - x3
    x21 = x2 - x1
    x43 = x4 - x3
    y13 = y1 - y3
    y21 = y2 - y1
    y43 = y4 - y3
    ua = (x43 * y13 - (y43 * x13)) / (y43 * x21 - (x43 * y21))
    [
      x1 + ua * x21
      y1 + ua * y21
    ]

  # TODO - DOCUMENT - USED IN edgePoint function
  pointInBox = (rect, b) ->
    b.x > rect.x and b.x < rect.x + rect.width and b.y > rect.y and b.y < rect.y + rect.height

  # TODO - DOCUMENT - USED IN edgePoint function
  pointInLine = (a, c, d) ->
    a[0] >= Math.min(c[0], d[0]) and a[0] <= Math.max(c[0], d[0]) and a[1] >= Math.min(c[1], d[1]) and a[1] <= Math.max(c[1], d[1])

  # TODO - DOCUMENT
  # TODO - should be a class method
  # TODO - edgePoint should be its own class
  edgePoint: (rect, a, b) ->
    comparePoint = a
    if pointInBox(rect, b)
      comparePoint = b
    lines = [
      [
        [ rect.x, rect.y]
        [ rect.x + rect.width, rect.y]
      ]
      [
        [rect.x, rect.y + rect.height]
        [rect.x + rect.width,rect.y + rect.height]
      ]
      [
        [rect.x,rect.y]
        [rect.x,rect.y + rect.height]
      ]
      [
        [rect.x + rect.width,rect.y]
        [rect.x + rect.width,rect.y + rect.height]
      ]
    ]
    intersects = lines.map((x) ->
      polygonIntersect x[0], x[1], a, b
    )
    if pointInLine(intersects[0], a, b) and intersects[0][0] >= rect.x and intersects[0][0] <= rect.x + rect.width
      intersects[0]
    else if pointInLine(intersects[1], a, b) and intersects[1][0] >= rect.x and intersects[1][0] <= rect.x + rect.width
      intersects[1]
    else if pointInLine(intersects[2], a, b) and intersects[2][1] >= rect.y and intersects[2][1] <= rect.y + rect.height
      intersects[2]
    else if pointInLine(intersects[3], a, b) and intersects[3][1] >= rect.y and intersects[3][1] <= rect.y + rect.height
      intersects[3]
    else
      null

  makeCenteredBox: (node) ->
    box = {}
    box.x = node.x - node.width / 2
    box.y = node.y - node.height / 2
    box.width = node.width
    box.height = node.height
    return box

  coordinate: (d, dest, src, origin, eptIndex) =>
    box = @makeCenteredBox(d[origin])
    ept = @edgePoint(box,[d.source.x,d.source.y],[d.target.x,d.target.y])
    d[dest] = d[origin][src]
    d[dest] = ept[eptIndex] if ept != null
    return d[dest]

# # # # #

module.exports = new EdgeSetter()
