local gridcap = require 'capture/gridcap'

function init()
  print('rendering to '..gridcap.output_path)
  gridcap:render_frames()
  print('render complete!')
end