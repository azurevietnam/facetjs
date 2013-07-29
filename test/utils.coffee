async = require('async')
chai = require("chai")
expect = chai.expect

uniformizeResults = (result) ->
  if not result?.prop
    return result

  ret = {}
  for k, p of result
    continue unless result.hasOwnProperty(k)
    continue if k is 'split'
    if k is 'prop'
      prop = {}
      for name, value of p
        continue unless p.hasOwnProperty(name)
        if typeof value is 'number' and value isnt Math.floor(value)
          prop[name] = Number(value.toPrecision(5))
        else if Array.isArray(value) and
              typeof value[0] is 'number' and
              typeof value[1] is 'number' and
              (value[0] isnt Math.floor(value[0]) or value[1] isnt Math.floor(value[1]))
          prop[name] = [value[0].toFixed(3), value[1].toFixed(3)]
        else
          prop[name] = value
      p = prop

    ret[k] = p

  if result.splits
    ret.splits = result.splits.map(uniformizeResults)
  return ret

exports.wrapVerbose = (requester, name) ->
  return (query, callback) ->
    console.log "Requesting #{name}:"
    console.log '', JSON.stringify(query, null, 2)
    startTime = Date.now()
    requester query, (err, result) ->
      if err
        console.log "GOT #{name} ERROR", err
      else
        console.log "GOT RESULT FROM #{name} (took #{Date.now() - startTime}ms)"
      callback(err, result)
      return

exports.makeEqualityTest = (driverFns) ->
  return ({drivers, query, verbose}) ->
    throw new Error("must have at least two drivers") if drivers.length < 2

    driversToTest = drivers.map (driverName) ->
      driverFn = driverFns[driverName]
      throw new Error("no such driver #{driverName}") unless driverFn
      return (callback) ->
        driverFn({query}, callback)
        return

    return (done) ->
      async.parallel driversToTest, (err, results) ->
        if err
          console.log "got error from driver"
          console.log err
          throw err

        results = results.map(uniformizeResults)

        if verbose
          console.log('vvvvvvvvvvvvvvvvvvvvvvv')
          console.log(JSON.stringify(results[0], null, 2))
          console.log('^^^^^^^^^^^^^^^^^^^^^^^')

        i = 1
        while i < drivers.length
          try
            expect(results[0]).to.deep.equal(results[i], "results of '#{drivers[0]}' and '#{drivers[i]}' must match")
          catch e
            console.log "results of '#{drivers[0]}' and '#{drivers[i]}' (expected) must match"
            throw e
          i++

        done()
        return

exports.makeErrorTest = (driverFns) ->
  return ({drivers, request, error, verbose}) -> (done) ->
    throw new Error("must have at least one driver") if drivers.length < 1

    numberOfTestsLeft = drivers.length

    drivers.forEach (driverName) ->
      driverFn = driverFns[driverName]
      throw new Error("no such driver #{driverName}") unless driverFn
      driverFn request, (err, results) ->
        numberOfTestsLeft--
        expect(err).to.be.ok
        expect(err.message).equal(error, "#{driverName} driver error should match")
        if numberOfTestsLeft is 0
          done()
        return
      return
    return
