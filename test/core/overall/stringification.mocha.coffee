{ expect } = require("chai")

facet = require('../../../build/facet')
{ Expression, Dataset } = facet.core

describe "stringification", ->
  it "works in advanced case", ->

    ex = facet()
      .def("diamonds", facet('diamonds').filter(facet("color").is('D')))
      .apply('Count', facet('diamonds').count())
      .apply('TotalPrice', facet('diamonds').sum('$price'))
      .apply('Cuts',
        facet("diamonds").group("$cut").label('Cut')
          .def('diamonds', facet('diamonds').filter(facet('cut').is('$^Cut')))
          .apply('Count', facet('diamonds').count())
          .sort('$Count', 'descending')
          .limit(2)
          .apply('Carats',
            facet("diamonds").group(facet("carat").numberBucket(0.25)).label('Carat')
              .def('diamonds', facet('diamonds').filter(facet("carat").numberBucket(0.25).is('$^Carat')))
              .apply('Count', facet('diamonds').count())
              .sort('$Count', 'descending')
              .limit(3)
          )
      )

    expect(ex.toString()).to.equal('')