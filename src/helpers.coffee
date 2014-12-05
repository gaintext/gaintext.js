
packrattle = require 'packrattle'

exports.flatten = flatten = (array) ->
  flattened = []
  for element in array
    if element instanceof Array
      flattened = flattened.concat element
    else unless element is null
      flattened.push element
  flattened

exports.collapseText = collapseText = (array) ->
    collapsed = []
    text = ''
    for element in array
        if typeof element == 'string'
            text = text.concat element
        else
            if text != ''
                collapsed.push text
                text = ''
            collapsed.push element
    if text != ''
        collapsed.push text
    collapsed

exports.flatseq = flatseq = (ps...) ->
    packrattle.seq(ps...).onMatch flatten

exports.within = within = (select, p) ->
    select = packrattle(select)
    packrattle.newParser "within",
        nested: [p]
        matcher: (state, cont) ->
            # remember old lineno, xpos
            startloc = state.loc
            startloc.pos = 0
            # 
            select.parse state, (rv) ->
                if not rv.ok then return cont(rv)
                endloc = rv.loc
                text = rv.match
#TBD                assert typeof(text) == 'string'
                p = packrattle(p)

                # create a new state for the matched range
                inner = state.clone()
                inner.internal =
                    text: text
                    end: text.length
                    trampoline: state.internal.trampoline
                inner.loc = startloc

                p.parse inner, (rv2) ->
                    rv2.state.loc = endloc
                    if rv2.ok
                        return new packrattle.Match(rv2.state, rv2.match, rv.commit)
                    else
                        return cont(rv2)

