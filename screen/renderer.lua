local screencap = require 'capture/screencap'

function init()
  print('rendering to '..screenpath.output_path)
  
  local fps = screencap.fps
  local output_path = screencap.output_path
  local zip_file = screencap.last_zip
  
  if screencap.render_type == "gif" then
    os.execute(string.format("/home/we/dust/code/capture/render_zip_as_png.sh %s %s %s", zip_file, output_path, fps)
  else
    os.execute(string.format("/home/we/dust/code/capture/render_zip_as_gif.sh %s %s %s", zip_file, output_path, fps)
  end
  
  print('render complete!')
end
  