chai = require("chai")
expect = chai.expect
utils = require('../utils')

{ FacetFilter } = require('../../build/query')

{ simpleLocator } = require('../../build/locator/simpleLocator')

{ druidRequester } = require('../../build/requester/druidRequester')
{ mySqlRequester } = require('../../build/requester/mySqlRequester')

{ simpleDriver } = require('../../build/driver/simpleDriver')
{ sqlDriver } = require('../../build/driver/sqlDriver')
{ druidDriver } = require('../../build/driver/druidDriver')

# Set up drivers
driverFns = {}

# Simple
diamondsData = require('../../data/diamonds.js')
driverFns.simple = simpleDriver(diamondsData)

# MySQL
sqlPass = mySqlRequester({
  locator: simpleLocator('localhost')
  database: 'facet'
  user: 'facet_user'
  password: 'HadleyWickham'
})

driverFns.mySql = sqlDriver({
  requester: sqlPass
  table: 'wiki_day_agg'
  filters: null
})

# # Druid
druidPass = druidRequester({
  locator: simpleLocator('10.186.40.119')
})

driverFns.druid = druidDriver({
  requester: druidPass
  dataSource: 'wikipedia_editstream'
  timeAttribute: 'time'
  approximate: true
  filter: FacetFilter.fromJS({
    type: 'within'
    attribute: 'time'
    range: [
      new Date("2013-02-26T00:00:00Z")
      new Date("2013-02-27T00:00:00Z")
    ]
  })
})

testError = utils.makeErrorTest(driverFns)

describe "Error compat test", ->
  describe "basics", ->
    it "request not supplied", testError {
      drivers: ['simple', 'mySql', 'druid']
      error: "request not supplied"
      request: null
    }

    it "query not supplied", testError {
      drivers: ['simple', 'mySql', 'druid']
      error: "query not supplied"
      request: {}
    }

    it "invalid query 1", testError {
      drivers: ['simple', 'mySql', 'druid']
      error: "query must be a FacetQuery"
      request: {
        query: {}
      }
    }

    it "invalid query 2", testError {
      drivers: ['simple', 'mySql', 'druid']
      error: "query must be a FacetQuery"
      request: {
        query: "poo"
      }
    }
