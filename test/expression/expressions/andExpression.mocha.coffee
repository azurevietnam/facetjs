{ expect } = require("chai")

tests = require './sharedTests'

describe 'AndExpression', ->
  describe 'with boolean expressions', ->
    beforeEach ->
      this.expression = { op: 'and', operands: [
        { op: 'literal', value: true },
        { op: 'literal', value: false },
        { op: 'literal', value: false }
      ] }

    tests.complexityIs(4)
    tests.simplifiedExpressionIs({op: 'literal', value: false})

  describe 'with is/in expressions', ->
    beforeEach ->
      this.expression = { op: 'and', operands: [
        { op: 'is', lhs: "$test", rhs: "blah" },
        { op: 'is', lhs: "$test", rhs: "test2" },
      ] }

    tests.complexityIs(7)
    tests.simplifiedExpressionIs({op: 'literal', value: false})

  describe 'with number comparison expressions', ->
    beforeEach ->
      this.expression = { op: 'and', operands: [
        { op: 'lessThan', lhs: "$test", rhs: 1 },
        { op: 'lessThanOrEqual', lhs: "$test", rhs: 0 }
      ] }

    tests.complexityIs(7)
    tests.simplifiedExpressionIs({ op: 'lessThanOrEqual', lhs: "$test", rhs: 0 })

  describe 'with and expressions', ->
    beforeEach ->
      this.expression = { op: 'and', operands: [
        { op: 'and', operands: [{ op: 'lessThan', lhs: "$test1", rhs: 1 }, { op: 'lessThanOrEqual', lhs: "$test2", rhs: 0 }]}
        { op: 'and', operands: [{ op: 'lessThan', lhs: "$test3", rhs: 1 }, { op: 'lessThanOrEqual', lhs: "$test4", rhs: 0 }]}
      ] }

    tests.complexityIs(15)
    tests.simplifiedExpressionIs({ op: 'and', operands: [
      { op: 'lessThan', lhs: { op: 'ref', name: "test1" }, rhs: { op: 'literal', value: 1 }}
      { op: 'lessThanOrEqual', lhs: { op: 'ref', name: "test2" }, rhs: { op: 'literal', value: 0 }}
      { op: 'lessThan', lhs: { op: 'ref', name: "test3" }, rhs: { op: 'literal', value: 1 }}
      { op: 'lessThanOrEqual', lhs: { op: 'ref', name: "test4" }, rhs: { op: 'literal', value: 0 }}
    ] })
