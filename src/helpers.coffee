
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

