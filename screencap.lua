local screencap = {}

-- output_path should end in .png
function screencap.record(fps, duration, output_path)
  local timer = 0
  local delay_s = 1/fps
  local frame_count = 0
  local tempDir = "frames"
  local tempName = "frame"
  local apngasm_path = "/home/we/dust/code/capture/apngasm"
  
  os.execute("mkdir /tmp/"..tempDir)

  clock.run(
    function()
      
      -- capture each frame
      while timer < duration do
        _norns.screen_export_png("/tmp/"..tempDir.."/"..tempName..string.format("%04d",frame_count)..".png")
        frame_count = frame_count + 1
        timer = timer + delay_s
        clock.sleep(delay_s)
      end
      
      -- assemble frames
      local s = "/tmp/"..tempDir.."/"..tempName.."*.png"
      os.execute("mogrify -gamma 1.25 -filter point -resize 400% -background black -extent 120% /tmp/frames/*.png")
      os.execute(apngasm_path.. " " ..output_path.. " " ..s.. " 1 " ..fps)
      os.execute("rm -r /tmp/frames")
    end
  )
end

-- output_path should end in .zip
function screencap.record_no_render(fps, duration, output_path)
  local timer = 0
  local delay_s = 1/fps
  local frame_count = 0
  local tempDir = "norns_screencap"
  local tempName = "frame"
  local apngasm_path = "/home/we/dust/code/capture/apngasm"
  
  os.execute("mkdir /tmp/"..tempDir)

  clock.run(
    function()
      
      -- capture each frame
      while timer < duration do
        _norns.screen_export_png("/tmp/"..tempDir.."/"..tempName..string.format("%04d",frame_count)..".png")
        frame_count = frame_count + 1
        timer = timer + delay_s
        clock.sleep(delay_s)
      end
      
      -- assemble frames
      print("Done recording!")
      print("Zipping...")
      --zip -r -j f.zip ./a
      os.execute("zip -r -j "..output_path.." /tmp/"..tempDir.."/")
      print("Zipped!")
      print("Removing files from system...")
      os.execute("rm -r /tmp/"..tempDir)
      print("Done!")
    end
  )
end

-- zip_file should be produced by record_no_render()
function screencap.render_png(zip_file, output_png, fps)
  os.execute("/home/we/dust/code/capture/render_zip_as_png.sh "..zip_file.." "..output_png.." "..fps)
end

-- zip_file should be produced by record_no_render()
function screencap.render_gif(zip_file, output_gif, fps)
  os.execute("/home/we/dust/code/capture/render_zip_as_gif.sh "..zip_file.." "..output_gif.." "..fps)
end

return screencap