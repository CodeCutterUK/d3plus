copy       = require "../../../../../util/copy.coffee"
events     = require "../../../../../client/pointer.coffee"
fetchColor = require "../../../../../core/fetch/color.coffee"
fetchValue = require "../../../../../core/fetch/value.js"
legible    = require "../../../../../color/legible.coffee"

module.exports = (node, vars) ->

  clickRemove = d3.event.type is events.click and (vars.tooltip.value.long or vars.tooltip.html.value)
  create      = [events.over, events.move].indexOf(d3.event.type) >= 0
  x           = node.d3plus.x
  y           = node.d3plus.y
  r           = node.d3plus.r or 0
  graph       = vars.axes
  timing      = vars.timing.mouseevents

  if not clickRemove and create
    color    = legible fetchColor vars, node
    lineData = ["x","y"].filter (axis) -> axis isnt vars.axes.stacked and vars[axis].mouse.value
  else
    lineData = []

  lineInit = (line) ->
    line
      .attr "x2", (d) -> if d is "x" then x else x - r
      .attr "y2", (d) -> if d is "y" then y else y + r
      .attr "opacity", 0

  lineStyle = (line) ->
    line
      .attr "x1", (d) -> if d is "x" then x else x - r
      .attr "y1", (d) -> if d is "y" then y else y + r
      .style "stroke", (d) -> if vars.shape.value is "area" then "white" else color
      .attr "stroke-dasharray", (d) -> vars[d].mouse.dasharray.value
      .attr "shape-rendering", (d) -> vars[d].mouse.rendering.value
      .style "stroke-width", (d) -> vars[d].mouse.width

  lines = vars.g.labels.selectAll("line.d3plus_mouse_axis_label").data lineData

  lines.enter().append "line"
    .attr "class","d3plus_mouse_axis_label"
    .attr "pointer-events", "none"
    .call lineInit
    .call lineStyle

  lines.transition().duration timing
    .attr "x2", (d) -> if d is "x" then x else node.d3plus.x0 or graph.margin.left - vars[d].ticks.size
    .attr "y2", (d) -> if d is "y" then y else node.d3plus.y0 or graph.height + graph.margin.top + vars[d].ticks.size
    .style "opacity", 1
    .call lineStyle

  lines.exit().transition().duration timing
    .call(lineInit).remove()

  textStyle = (text) ->
    text
      .attr "font-size",   (d) -> vars[d].ticks.font.size
      .attr "fill",        (d) -> vars[d].ticks.font.color
      .attr "font-family", (d) -> vars[d].ticks.font.family.value
      .attr "font-weight", (d) -> vars[d].ticks.font.weight
      .attr "x", (d) -> if d is "x" then x else graph.margin.left - 5 - vars[d].ticks.size
      .attr "y", (d) ->
        if d is "y" then y else
          if node.d3plus.y0
            node.d3plus.y + (node.d3plus.y0 - node.d3plus.y)/2 + graph.margin.top - 6
          else graph.height + graph.margin.top + 5 + vars[d].ticks.size
      .attr "fill", if vars.shape.value is "area" then "white" else color

  texts = vars.g.labels.selectAll("text.d3plus_mouse_axis_label").data lineData

  texts.enter().append "text"
    .attr "class", "d3plus_mouse_axis_label"
    .attr "id", (d) -> d+"_d3plusmouseaxislabel"
    .attr "dy", (d) -> if d is "y" then vars[d].ticks.font.size * 0.35 else vars[d].ticks.font.size
    .style "text-anchor", (d) -> if d is "y" then "end" else "middle"
    .attr "opacity", 0
    .attr "pointer-events", "none"
    .call textStyle

  texts
    .text (d) ->
      axis = vars.axes.stacked or d
      val  = fetchValue vars, node, vars[axis].value
      vars.format.value val, vars[axis].value, vars
    .transition().duration(timing).delay timing
      .attr "opacity", 1
      .call textStyle

  texts.exit().transition().duration timing
    .attr("opacity", 0).remove()

  rectStyle = (rect) ->
    getText = (axis) -> d3.select("text#"+axis+"_d3plusmouseaxislabel").node().getBBox()
    rect
      .attr "x", (d) ->
        width = getText(d).width
        if d is "x" then x - width/2 - 5 else graph.margin.left - vars[d].ticks.size - width - 10
      .attr "y", (d) ->
        mod = getText(d).height/2 + 5
        if d is "y" then y-mod else
          if node.d3plus.y0
            node.d3plus.y + (node.d3plus.y0 - node.d3plus.y)/2 + graph.margin.top - mod
          else graph.height + graph.margin.top + vars[d].ticks.size
      .attr "width", (d) -> getText(d).width + 10
      .attr "height", (d) -> getText(d).height + 10
      .style "stroke", if vars.shape.value is "area" then "transparent" else color
      .attr "fill", if vars.shape.value is "area" then color else vars.background.value
      .attr "shape-rendering", (d) -> vars[d].mouse.rendering.value
      .style "stroke-width", (d) -> vars[d].mouse.width

  rects = vars.g.labels.selectAll("rect.d3plus_mouse_axis_label").data lineData

  rects.enter().insert("rect", "text.d3plus_mouse_axis_label")
    .attr "class", "d3plus_mouse_axis_label"
    .attr "pointer-events", "none"
    .attr("opacity", 0).call rectStyle

  rects.transition().duration(timing).delay timing
    .attr("opacity", 1).call rectStyle

  rects.exit().transition().duration timing
    .attr("opacity", 0).remove()
