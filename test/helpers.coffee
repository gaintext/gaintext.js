
helpers = require('../lib/gaintext/helpers')

{expect} = require('chai')


describe "helpers", ->

    describe "collapseText", ->
        it "doesn't touch empty lists", ->
            expect( helpers.collapseText [] ).to.eql []

        it "strips empty strings", ->
            expect( helpers.collapseText [""] ).to.eql []

        it "collapses strings", ->
            expect( helpers.collapseText ["a", "b", "c"] ).to.eql ["abc"]

        it "collapses strings around list", ->
            expect( helpers.collapseText ["a", "b", [1,2,3], "x", "y"] ).to.eql ["ab", [1,2,3], "xy"]

        it "collapses strings between lists", ->
            expect( helpers.collapseText [[1,2], "a", "b", [8,9]] ).to.eql [[1,2], "ab", [8,9]]

    describe "flatten", ->
        it "doesn't modify normal lists", ->
            expect( helpers.flatten [1, 2, 3] ).to.eql [1, 2, 3]

        it "removes one level", ->
            expect( helpers.flatten [1, [2], 3, [4]] ).to.eql [1, 2, 3, 4]

        it "removes only one level", ->
            expect( helpers.flatten [1, [2, [3], 4], 5] ).to.eql [1, 2, [3], 4, 5]

        it "removes null elements", ->
            expect( helpers.flatten [1, null, 3,] ).to.eql [1, 3]

