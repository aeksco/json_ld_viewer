# TODO - this should be re-written
# TODO - this should be re-written
# This should perhaps be the first part of the re-write

# TODO - should be generic resource
Resource = require './resource'

# # # # #

class Predicate extends Resource

  # TODO - simplify
  defaults:
    attribs: {}
    depth: -1
    display: true
    isPredicate: false
    label: false
    links: []
    objects: []
    type: 'predicate'
    types: []
    uri: false
    width: 0

  template: require './templates/predicate'

  setClass: ->
    classes = _.pluck(@types, 'localPart')
    css = "predicate #{@namespace} " # TODO - make this an option PLEASE.
    @classes = css + classes.join(' ')

  getClass: ->
    # console.log @namespace
    return @classes + @namespace

  # setNamespace: ->
  #   console.log 'setNamespace'
  #   np = super
  #   console.log np
  #   @namespace = np

# # # # #

module.exports = Predicate
