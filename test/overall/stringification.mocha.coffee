{ expect } = require("chai")

facet = require('../../build/facet')
{ Expression, Dataset, $ } = facet

describe "stringification", ->
  it "works in advanced case", ->

    ex = $()
      .def("diamonds", $('diamonds').filter($("color").is('D')))
      .apply('Count', $('diamonds').count())
      .apply('TotalPrice', $('diamonds').sum('$price'))
      .apply('Cuts',
        $("diamonds").group("$cut").label('Cut')
          .def('diamonds', $('diamonds').filter($('cut').is('$^Cut')))
          .apply('Count', $('diamonds').count())
          .sort('$Count', 'descending')
          .limit(2)
          .apply('Carats',
            $("diamonds").group($("carat").numberBucket(0.25)).label('Carat')
              .def('diamonds', $('diamonds').filter($("carat").numberBucket(0.25).is('$^Carat')))
              .apply('Count', $('diamonds').count())
              .sort('$Count', 'descending')
              .limit(3)
          )
      )

    expect(ex.toString()).to.equal("""
      $().def('diamonds', $diamonds.filter($color = "D"))
        .apply(Count, $diamonds.count())
        .apply(TotalPrice, $diamonds.sum($price))
        .apply(Cuts, $diamonds.group($cut).label('Cut').def('diamonds', $diamonds.filter($cut = $^Cut))
        .apply(Count, $diamonds.count())
        .sort($Count, descending)
        .limit(2)
        .apply(Carats, $diamonds.group($carat.numberBucket(0.25)).label('Carat').def('diamonds', $diamonds.filter($carat.numberBucket(0.25) = $^Carat))
        .apply(Count, $diamonds.count())
        .sort($Count, descending)
        .limit(3)))
    """)
