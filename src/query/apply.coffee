
class FacetApply
  constructor: ->
    return

  _ensureAggregate: (applyAggregate) ->
    if not @aggregate
      @aggregate = applyAggregate # Set the aggregate if it is so far undefined
      return
    if @aggregate isnt applyAggregate
      throw new TypeError("incorrect apply aggregate '#{@aggregate}' (needs to be: '#{applyAggregate}')")
    return

  _ensureArithmetic: (applyArithmetic) ->
    if not @arithmetic
      @arithmetic = applyArithmetic # Set the arithmetic if it is so far undefined
      return
    if @arithmetic isnt applyArithmetic
      throw new TypeError("incorrect apply arithmetic '#{@arithmetic}' (needs to be: '#{applyArithmetic}')")
    return

  _initSimpleAggregator: (args) ->
    switch args.length
      when 1
        if typeof args[0] isnt 'string'
          { @name, @aggregate, @attribute } = args[0]
        else
          [@attribute] = args

      when 2
        if typeof args[1] is 'string'
          [@name, @attribute] = args
        else
          [@attribute, @options] = args

      when 3
        [@name, @attribute, @options] = args

      else
        throwBadArgs()

    return

  _initArithmetic: (args) ->
    switch args.length
      when 1
        if not Array.isArray(args[0])
          { @name, @arithmetic, @operands } = args[0]
          @operands = @operands.map(FacetApply.fromSpec)
        else
          [@operands] = args

      when 2
        [@name, @operands] = args

      else
        throwBadArgs()

    throw new Error("must have two operands got #{@operands.length}") unless @operands.length is 2
    return

  toString: ->
    return "base apply"

  valueOf: ->
    throw new Error("base apply has no value")

  isAdditive: ->
    return false



class ConstantApply extends FacetApply
  constructor: (arg) ->
    if arguments.length is 1
      if typeof arg is 'number'
        @value = arg
      else
        { @aggregate, @value } = arg
    else if arguments.length isnt 0
      throwBadArgs()



    @_ensureAggregate('constant')

  toString: ->
    return String(@value)

  valueOf: ->
    apply = { aggregate: @aggregate, value: @value }
    apply.name = @name if @name
    return apply

  isAdditive: ->
    return true



class CountApply extends FacetApply
  constructor: ->
    if arguments.length is 1
      { @aggregate } = arguments[0]
    else if arguments.length isnt 0
      throwBadArgs()
    @_ensureAggregate('count')

  toString: ->
    return "count()"

  valueOf: ->
    apply = { aggregate: @aggregate }
    apply.name = @name if @name
    return apply

  isAdditive: ->
    return true



class SumApply extends FacetApply
  constructor: ->
    @_initSimpleAggregator(arguments)
    @_ensureAggregate('sum')

  toString: ->
    return "#{@aggregate}(#{@attribute})"

  valueOf: ->
    apply = { aggregate: @aggregate, attribute: @attribute }
    apply.name = @name if @name
    return apply

  isAdditive: ->
    return true



class AverageApply extends FacetApply
  constructor: (arg) ->
    @_initSimpleAggregator(arguments)
    @_ensureAggregate('average')

  toString: ->
    return "#{@aggregate}(#{@attribute})"

  valueOf: ->
    apply = { aggregate: @aggregate, attribute: @attribute }
    apply.name = @name if @name
    return apply



class MinApply extends FacetApply
  constructor: (arg) ->
    @_initSimpleAggregator(arguments)
    @_ensureAggregate('min')

  toString: ->
    return "#{@aggregate}(#{@attribute})"

  valueOf: ->
    apply = { aggregate: @aggregate, attribute: @attribute }
    apply.name = @name if @name
    return apply



class MaxApply extends FacetApply
  constructor: (arg) ->
    @_initSimpleAggregator(arguments)
    @_ensureAggregate('max')

  toString: ->
    return "#{@aggregate}(#{@attribute})"

  valueOf: ->
    apply = { aggregate: @aggregate, attribute: @attribute }
    apply.name = @name if @name
    return apply



class UniqueCountApply extends FacetApply
  constructor: (arg) ->
    @_initSimpleAggregator(arguments)
    @_ensureAggregate('uniqueCount')

  toString: ->
    return "#{@aggregate}(#{@attribute})"

  valueOf: ->
    apply = { aggregate: @aggregate, attribute: @attribute }
    apply.name = @name if @name
    return apply



class QuantileApply extends FacetApply
  constructor: ->
    switch arguments.length
      when 1
        if typeof arguments[0] isnt 'string'
          { @name, @attribute, @quantile, @options } = arguments[0]
        else
          throwBadArgs()
      when 2
        [@attribute, @quantile] = arguments
      when 3
        if typeof arguments[2] is 'number'
          [@name, @attribute, @quantile] = arguments
        else
          [@attribute, @quantile, @options] = arguments
      when 4
        [@name, @attribute, @qunatile, @options] = arguments
      else
        throwBadArgs()
    @_ensureAggregate('quantile')

  toString: ->
    return "quantile(#{@attribute}, #{@quantile})"

  valueOf: ->
    apply = { aggregate: @aggregate, attribute: @attribute, quantile: @quantile }
    apply.name = @name if @name
    apply.options = @options if @options
    return apply

  isAdditive: ->
    return true



class AddApply extends FacetApply
  constructor: ->
    @_initArithmetic(arguments)
    @_ensureArithmetic('add')

  toString: ->
    return "(#{@operands[0]}) + (#{@operands[1]})"

  valueOf: ->
    apply = { arithmetic: @arithmetic, operands: @operands.map(getValueOf) }
    apply.name = @name if @name
    return apply

  isAdditive: ->
    return @operands[0].isAdditive() and @operands[1].isAdditive()



class SubtractApply extends FacetApply
  constructor: ->
    @_initArithmetic(arguments)
    @_ensureArithmetic('subtract')

  toString: ->
    return "(#{@operands[0]}) - (#{@operands[1]})"

  valueOf: ->
    apply = { arithmetic: @arithmetic, operands: @operands.map(getValueOf) }
    apply.name = @name if @name
    return apply

  isAdditive: ->
    return @operands[0].isAdditive() and @operands[1].isAdditive()



class MultiplyApply extends FacetApply
  constructor: ->
    @_initArithmetic(arguments)
    @_ensureArithmetic('multiply')

  toString: ->
    return "(#{@operands[0]}) * (#{@operands[1]})"

  valueOf: ->
    apply = { arithmetic: @arithmetic, operands: @operands.map(getValueOf) }
    apply.name = @name if @name
    return apply

  isAdditive: ->
    return (
      (@operands[0] instanceof ConstantApply and @operands[1].isAdditive()) or
      (@operands[0].isAdditive() and @operands[1] instanceof ConstantApply)
    )



class DivideApply extends FacetApply
  constructor: ->
    @_initArithmetic(arguments)
    @_ensureArithmetic('divide')

  toString: ->
    return "(#{@operands[0]}) / (#{@operands[1]})"

  valueOf: ->
    apply = { arithmetic: @arithmetic, operands: @operands.map(getValueOf) }
    apply.name = @name if @name
    return apply

  isAdditive: ->
    return @operands[0].isAdditive() and @operands[1] instanceof ConstantApply



# Make lookup
applyAggregateConstructorMap = {
  "constant": ConstantApply
  "count": CountApply
  "sum": SumApply
  "average": AverageApply
  "min": MinApply
  "max": MaxApply
  "uniqueCount": UniqueCountApply
  "quantile": QuantileApply
}

applyArithmeticConstructorMap = {
  "add": AddApply
  "subtract": SubtractApply
  "multiply": MultiplyApply
  "divide": DivideApply
}

FacetApply.fromSpec = (applySpec) ->
  if applySpec.aggregate
    ApplyConstructor = applyAggregateConstructorMap[applySpec.aggregate]
    throw new Error("unsupported aggregate #{applySpec.aggregate}") unless ApplyConstructor
  else if applySpec.arithmetic
    ApplyConstructor = applyArithmeticConstructorMap[applySpec.arithmetic]
    throw new Error("unsupported arithmetic #{applySpec.arithmetic}") unless ApplyConstructor
  else
    throw new Error("must have an arithmetic or attribute")
  return new ApplyConstructor(applySpec)


# Export!
exports.FacetApply = FacetApply
exports.ConstantApply = ConstantApply
exports.CountApply = CountApply
exports.SumApply = SumApply
exports.AverageApply = AverageApply
exports.MinApply = MinApply
exports.MaxApply = MaxApply
exports.UniqueCountApply = UniqueCountApply
exports.QuantileApply = QuantileApply
exports.AddApply = AddApply
exports.SubtractApply = SubtractApply
exports.MultiplyApply = MultiplyApply
exports.DivideApply = DivideApply

