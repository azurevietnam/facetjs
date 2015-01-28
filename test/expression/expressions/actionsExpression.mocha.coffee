{ expect } = require("chai")

tests = require './sharedTests'

describe 'ActionsExpression', ->
  beforeEach ->
    this.expression = {
      op: 'actions'
      operand: '$diamonds'
      actions: [
        { action: 'apply', name: 'five', expression: { op: 'literal', value: 5 } }
      ]
    }

  tests.complexityIs(2)
