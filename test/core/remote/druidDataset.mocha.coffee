{ expect } = require("chai")

{ WallTime } = require('chronology')
if not WallTime.rules
  tzData = require("chronology/lib/walltime/walltime-data.js")
  WallTime.init(tzData.rules, tzData.zones)

facet = require('../../../build/facet')
{ Expression, Dataset, TimeRange } = facet.core

context = {
  wiki: Dataset.fromJS({
    source: 'druid',
    dataSource: 'wikipedia_editstream',
    timeAttribute: 'time',
    forceInterval: true,
    approximate: true,
    attributes: {
      time: { type: 'TIME' }
      language: { type: 'STRING' }
      page: { type: 'STRING' }
      added: { type: 'NUMBER' }
      deleted: { type: 'NUMBER' }
    }
    filter: facet('time').in(TimeRange.fromJS({
      start: new Date("2013-02-26T00:00:00Z")
      end: new Date("2013-02-27T00:00:00Z")
    }))
  })
}

contextNoApprox = {
  wiki: Dataset.fromJS({
    source: 'druid',
    dataSource: 'wikipedia_editstream',
    timeAttribute: 'time',
    forceInterval: true,
    approximate: false,
    attributes: {
      time: { type: 'TIME' }
      language: { type: 'STRING' }
      page: { type: 'STRING' }
      added: { type: 'NUMBER' }
    }
    filter: facet('time').in(TimeRange.fromJS({
      start: new Date("2013-02-26T00:00:00Z")
      end: new Date("2013-02-27T00:00:00Z")
    }))
  })
}

describe "RemoteDataset", ->
  describe "breakupApplies", ->
    wikiDataset = context.wiki

    it "breaks up correctly in simple case", ->
      ex = facet()
        .apply('Count', '$wiki.count()')
        .apply('Added', '$wiki.sum($added)')
        .apply('Volatile', '$wiki.max($added) - $wiki.min($deleted)')

      expect(wikiDataset.breakUpApplies(ex.actions).join('\n')).to.equal("""
        .apply(Count, $wiki.count())
        .apply(Added, $wiki.sum($added))
        .def('_sd_0', $wiki.max($added))
        .def('_sd_1', $wiki.min($deleted))
        .apply(Volatile, ($_sd_0:NUMBER + $_sd_1:NUMBER.negate()))
        """)

    it "breaks up correctly in case of duplicate name", ->
      ex = facet()
        .apply('Count', '$wiki.count()')
        .apply('Added', '$wiki.sum($added)')
        .apply('Volatile', '$wiki.sum($added) - $wiki.sum($deleted)')

      expect(wikiDataset.breakUpApplies(ex.actions).join('\n')).to.equal("""
        .apply(Count, $wiki.count())
        .apply(Added, $wiki.sum($added))
        .def('_sd_0', $wiki.sum($deleted))
        .apply(Volatile, ($Added:NUMBER + $_sd_0:NUMBER.negate()))
        """)

    it "breaks up correctly in case of variable reference", ->
      ex = facet()
        .apply('Count', '$wiki.count()')
        .apply('Added', '$wiki.sum($added)')
        .apply('Volatile', '$Added - $wiki.sum($deleted)')

      expect(wikiDataset.breakUpApplies(ex.actions).join('\n')).to.equal("""
        .apply(Count, $wiki.count())
        .apply(Added, $wiki.sum($added))
        .def('_sd_0', $wiki.sum($deleted))
        .apply(Volatile, ($Added + $_sd_0:NUMBER.negate()))
        """)

    it "breaks up correctly in case of duplicate apply", ->
      ex = facet()
        .apply('Added', '$wiki.sum($added)')
        .apply('Added2', '$wiki.sum($added)')
        .apply('Volatile', '$Added - $wiki.sum($deleted)')

      expect(wikiDataset.breakUpApplies(ex.actions).join('\n')).to.equal("""
        .apply(Added, $wiki.sum($added))
        .apply(Added2, $Added)
        .def('_sd_0', $wiki.sum($deleted))
        .apply(Volatile, ($Added + $_sd_0:NUMBER.negate()))
        """)

    it "breaks up correctly in case of duplicate apply (same name)", ->
      ex = facet()
        .apply('Added', '$wiki.sum($added)')
        .apply('Added', '$wiki.sum($added)')
        .apply('Volatile', '$Added - $wiki.sum($deleted)')

      expect(wikiDataset.breakUpApplies(ex.actions).join('\n')).to.equal("""
        .apply(Added, $wiki.sum($added))
        .def('_sd_0', $wiki.sum($deleted))
        .apply(Volatile, ($Added + $_sd_0:NUMBER.negate()))
        """)

  describe "simplifies / digests", ->
    it "a (timeBoundary) total", ->
      ex = facet()
        .apply('maximumTime', '$wiki.max($time)')
        .apply('minimumTime', '$wiki.min($time)')

      ex = ex.referenceCheck(context).resolve(context).simplify()
      expect(ex.op).to.equal('literal')
      remoteDataset = ex.value
      expect(remoteDataset.getQueryAndPostProcess().query).to.deep.equal({
        "dataSource": "wikipedia_editstream"
        "queryType": "timeBoundary"
      })

    it "a total", ->
      ex = facet()
        .def("wiki",
          facet('^wiki')
            .apply('addedTwice', '$added * 2')
            .filter(facet("language").is('en'))
        )
        .apply('Count', '$wiki.count()')
        .apply('TotalAdded', '$wiki.sum($added)')

      ex = ex.referenceCheck(context).resolve(context).simplify()

      expect(ex.op).to.equal('literal')
      remoteDataset = ex.value
      expect(remoteDataset.getQueryAndPostProcess().query).to.deep.equal({
        "aggregations": [
          {
            "name": "Count"
            "type": "count"
          }
          {
            "fieldName": "added"
            "name": "TotalAdded"
            "type": "doubleSum"
          }
        ]
        "dataSource": "wikipedia_editstream"
        "filter": {
          "dimension": "language"
          "type": "selector"
          "value": "en"
        }
        "granularity": "all"
        "intervals": [
          "2013-02-26/2013-02-27"
        ]
        "queryType": "timeseries"
      })

    it "a split", ->
      ex = facet('wiki').split("$page", 'Page')
        .apply('Count', '$wiki.count()')
        .apply('Added', '$wiki.sum($added)')
        .sort('$Count', 'descending')
        .limit(5)

      ex = ex.referenceCheck(context).resolve(context).simplify()

      expect(ex.op).to.equal('literal')
      remoteDataset = ex.value
      expect(remoteDataset.getQueryAndPostProcess().query).to.deep.equal({
        "aggregations": [
          {
            "name": "Count"
            "type": "count"
          }
          {
            "fieldName": "added"
            "name": "Added"
            "type": "doubleSum"
          }
        ]
        "dataSource": "wikipedia_editstream"
        "dimension": {
          "dimension": "page"
          "outputName": "Page"
          "type": "default"
        }
        "granularity": "all"
        "intervals": [
          "2013-02-26/2013-02-27"
        ]
        "metric": "Count"
        "queryType": "topN"
        "threshold": 5
      })

    it "a split (no approximate)", ->
      ex = facet('wiki').split("$page", 'Page')
        .apply('Count', '$wiki.count()')
        .apply('Added', '$wiki.sum($added)')
        .sort('$Count', 'descending')
        .limit(5)

      ex = ex.referenceCheck(contextNoApprox).resolve(contextNoApprox).simplify()

      expect(ex.op).to.equal('literal')
      remoteDataset = ex.value
      expect(remoteDataset.getQueryAndPostProcess().query).to.deep.equal({
        "aggregations": [
          {
            "name": "Count"
            "type": "count"
          }
          {
            "fieldName": "added"
            "name": "Added"
            "type": "doubleSum"
          }
        ]
        "dataSource": "wikipedia_editstream"
        "dimensions": [
          {
            "dimension": "page"
            "outputName": "Page"
            "type": "default"
          }
        ]
        "granularity": "all"
        "intervals": [
          "2013-02-26/2013-02-27"
        ]
        "limitSpec": {
          "columns": [
            "Count"
          ]
          "limit": 5
          "type": "default"
        }
        "queryType": "groupBy"
      })

    it "filters", ->
      ex = facet()
        .def("wiki",
          facet('^wiki')
            .filter(facet("language").contains('en'))
        )
        .apply('Count', '$wiki.count()')

      ex = ex.referenceCheck(context).resolve(context).simplify()

      expect(ex.op).to.equal('literal')
      remoteDataset = ex.value
      expect(remoteDataset.getQueryAndPostProcess().query).to.deep.equal({
        "aggregations": [
          {
            "name": "Count"
            "type": "count"
          }
        ]
        "dataSource": "wikipedia_editstream"
        "filter": {
          "dimension": "language"
          "query": {
            "type": "fragment"
            "values": [
              "en"
            ]
          }
          "type": "search"
        }
        "granularity": "all"
        "intervals": [
          "2013-02-26/2013-02-27"
        ]
        "queryType": "timeseries"
      })
