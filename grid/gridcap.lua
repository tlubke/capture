local shared = include "shared"
local themes = include "grid/themes"
local err_no_grid = "grid capture has no set grid."
local temp_dir = "/tmp/gridcap/"

local function clone (t)
  local new_t = {}
  local i, v = next(t, nil)
  while i do
    if type(v) == "table" then
      new_t[i] = clone(v)
    else
      new_t[i] = v
    end
    i, v = next(t, i)
  end
  return new_t
end

local gridcap = {}

local unpaused = true
local stopped  = true

gridcap.grid = nil
gridcap.frames = nil
gridcap.fps = nil
gridcap.output_path = nil
gridcap.colors = { -- default
  key = "#fbfbfb",
  led = "#fff03e",
  grid = "#e6e6e6",
  outline = "black"
}

function gridcap:set_grid(g)
  if self.grid ~= nil then return end

  local function clone_function(fn)
    local dumped = string.dump(fn)
    local cloned = load(dumped)
    local i = 1
    while true do
      local name = debug.getupvalue(fn, i)
      if not name then
        break
      end
      debug.upvaluejoin(cloned, i, fn, i)
      i = i + 1
    end
    return cloned
  end

  -- create state of grid leds
  g.led_state = {}
  for i=1, g.cols do
    g.led_state[i] = {}
    for j=1, g.rows do
      g.led_state[i][j] = 0
    end
  end
  -- extend g:led()
  if g.led2 == nil then
    g.led2 = clone_function(g.led)
    g.led = function(g, x, y, z) g:led2(x, y, z) g.led_state[x][y] = z end
  end

  if g.all2 == nil then
    g.all2 = clone_function(g.all)
    g.all = function(g,z)
      g:all2(z)
      for x = 1, #g.led_state do
        for y =1, #g.led_state[x] do
          g.led_state[x][y] = z
        end
      end
    end
  end
  self.grid = g
end

function gridcap:set_colors(key, led, grid, outline)
  self.colors.key = key
  self.colors.led = led
  self.colors.grid = grid
  self.colors.outline = outline
end

function gridcap:set_theme(theme)
  if themes[theme] then
    self:set_colors(table.unpack(themes[theme]))
  else
    self:set_colors(table.unpack(themes["default"]))
  end
end

function gridcap:record(fps)
  local timer = 0
  local delay_s = 1/fps
  local frame_count = 1
  local frames = {}
  local g = self.grid

  if g == nil then
    print(err_no_grid)
    return
  end

  if stopped == false then
    print("Already recording.")
    return
  end

  stopped = false

  shared.mkdir(temp_dir)

  clock.run(
    function()
      
      ::record_loop:
      while unpaused do
        frames[frame_count] = clone(g.led_state)
        frame_count = frame_count + 1
        timer = timer + delay_s
        clock.sleep(delay_s)
      end

      if stopped then
        self.frames = frames
        self.fps = fps
        return
      end

    until unpause do
      clock.sleep(1)
    end
    goto record_loop
  )

  return timer
end

function gridcap:pause() unpaused = false end
function gridcap:resume() unpaused = true end

function gridcap:stop() 
  stopped = true
  print("Done recording!")
end

function gridcap:render(output_path)
  self.output_path = output_path
  norns.script.load("/home/we/dust/code/capture/grid/renderer.lua")
end

function gridcap:render_led_state(led_state, export_path)
  local g = self.grid
  if g == nil then
    print(err_no_grid)
    return
  end
  local key_size = 9
  local key_spacing = 6
  local margin = 11
  local grid_width =  (g.cols*(key_size+key_spacing))-key_spacing+(2*margin)
  local grid_height = (g.rows*(key_size+key_spacing))-key_spacing+(2*margin)

  local start = util.time()
  local script =
      'convert -size '
    ..grid_width
    ..'x'
    ..grid_height
    ..' xc:none'
    ..' -fill none'
    ..' -stroke '
    ..self.colors.outline
    ..' \\\n'


  -- draw grid
  script =
      script
    ..'-draw "fill '
    ..self.colors.grid
    ..'\troundrectangle '
    ..'0,0 ' -- corner 1 coordinate
    ..grid_width-1 -- corner 2 x
    ..','
    ..grid_height-1 -- corner 2 y
    ..' '
    ..key_size -- round corner 1 by x pixels
    ..','
    ..key_size -- round corner 2 by x pixels
    ..' " \\\n'


  -- draw keys' background if needed
  if self.colors.key ~= self.colors.grid then
    for y = 1, g.rows do
      for x = 1, g.cols do
        local rect_size =
            ((x-1)*(key_size+key_spacing))+margin
          ..','
          ..((y-1)*(key_size+key_spacing))+margin
          ..' '
          ..((x-1)*(key_size+key_spacing))+key_size-1+margin
          ..','
          ..((y-1)*(key_size+key_spacing))+key_size-1+margin
        script =
            script
          ..'-draw "fill '
          ..self.colors.key
          ..'\trectangle '
          ..rect_size
          ..' " \\\n'
      end
    end
  end

  -- draw leds over keys' background
  for y = 1, g.rows do
    for x = 1, g.cols do
      local fill_opacity =
          'fill-opacity '
        ..led_state[x][y] * 0.07
      local rect_size =
          ((x-1)*(key_size+key_spacing))+margin
        ..','
        ..((y-1)*(key_size+key_spacing))+margin
        ..' '
        ..((x-1)*(key_size+key_spacing))+key_size-1+margin
        ..','
        ..((y-1)*(key_size+key_spacing))+key_size-1+margin
      script =
          script
        ..'-draw "fill '
        ..self.colors.led
        ..' '
        ..fill_opacity
        ..'\trectangle '
        ..rect_size
        ..' " \\\n'
    end
  end
  script = script..export_path
  os.execute(script)
end

function gridcap:screenshot(output_path)
  local g = self.grid
  self:render_led_state(g.led_state, output_path)
  print("grid state exported to "..output_path)
end

function gridcap:render_frames()
  for i=1, #self.frames do
    self:render_led_state(self.frames[i], temp_dir..string.format("frame%04d", i)..".gif")
  end
  
  os.execute(string.format("convert -delay %f -dispose previous -loop 0 %s*.gif %s", 100/self.fps, temp_dir, self.output_path))
  shared.rmdir(temp_dir)
end

return gridcap
