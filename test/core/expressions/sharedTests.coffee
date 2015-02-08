{ expect } = require("chai")

facet = require('../../../build/facet')
{ Expression } = facet.Core

exports.complexityIs = (expectedComplexity) ->
  it '#getComplexty() gets the complexity correctly', ->
    expect(Expression.fromJS(@expression).getComplexity()).to.equal(expectedComplexity)

exports.simplifiedExpressionIs = (expectedSimplifiedExpression) ->
  it '#simplify() returns the correct simplified expression', ->
    expect(Expression.fromJS(@expression).simplify().toJS()).to.deep.equal(expectedSimplifiedExpression)

exports.mergedAndWith = (testCaseTitle, mergingExpression) ->
  return {
    equals: (expectedExpression) ->
      it testCaseTitle, ->
        expect(Expression.fromJS(@expression).mergeAnd(Expression.fromJS(mergingExpression)).toJS()).to.deep.equal(expectedExpression)
  }