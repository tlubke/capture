local temp_dir = "/tmp/screencap/"
local apngasm_path = "/home/we/dust/code/capture/screen/apngasm"

local screencap = {}

local unpaused = true
local stopped  = true

screencap.fps = nil
screencap.output_path = nil
screencap.output_type = nil

function screencap.record(fps)
  local timer = 0
  local delay_s = 1/fps
  local frame_count = 1

  if stopped == false then
    print("Already recording.")
    return
  end

  stopped = false

  os.execute(string.format("mkdir ", temp_dir))

  clock.run(
    function()
      ::record_loop::
      while unpaused do
        _norns.screen_export_png(temp_dir..string.format("frame%04d",frame_count)..".png")
        frame_count = frame_count + 1
        timer = timer + delay_s
        clock.sleep(delay_s)
      end
      
      if stopped then
        self.fps = fps
        return
      end

      until unpaused do
        clock.sleep(1)
      end
      goto record_loop
    end
  )

  return timer
end

function screencap:pause() unpaused = false end
function screencap:resume() unpaused = true end

function screencap:stop()
  stopped = true
  print("Done recording!")

  -- assemble frames
  print("Zipping...")
  os.execute(string.format("zip -r -j %s %s", temp_dir))
  print("Zipped!")
  print("Removing files from system...")
  os.execute(string.format("rm -r %s", temp_dir))
  print("Done!")
end

-- zip_file should be produced by record()
function screencap:render(output_path)
  self.output_path = output_path
  
  if output_path:find("*.png") ~= nil then
    self.output_type = "png"
  else if output_path:find("*.gif") ~= nil then
    self.output_type = "gif"
  else
    -- do some defaults, maybe timestamp and ignore output path then render as gif
  end
    
  norns.script.load("/home/we/dust/code/capture/screen/renderer.lua")
end

return screencap