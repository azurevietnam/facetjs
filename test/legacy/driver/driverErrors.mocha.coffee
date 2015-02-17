{ expect } = require("chai")

utils = require('../../utils')

{ druidRequester } = require('facetjs-druid-requester')
{ mySqlRequester } = require('facetjs-mysql-requester')

facet = require("../../../build/facet")
{ FacetFilter, simpleDriver, mySqlDriver, druidDriver } = facet.legacy

info = require('../../info')

# Set up drivers
driverFns = {}

# Simple
diamondsData = require('../../../data/diamonds.js')
driverFns.simple = simpleDriver(diamondsData)

# MySQL
sqlPass = mySqlRequester({
  host: info.mySqlHost
  database: info.mySqlDatabase
  user: info.mySqlUser
  password: info.mySqlPassword
})

driverFns.mySql = mySqlDriver({
  requester: sqlPass
  table: 'wiki_day_agg'
  filters: null
})

# Druid
druidPass = druidRequester({
  host: info.druidHost
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
