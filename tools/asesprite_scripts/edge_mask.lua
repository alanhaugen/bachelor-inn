-- totally not gpt generated edge detection for aseprite

if app.apiVersion < 1 then
  return app.alert("This script requires Aseprite v1.2.10-beta3 or newer")
end

local cel = app.activeCel
if not cel then
  return app.alert("There is no active image")
end

-- Dialog for neighbor choice
local d = Dialog("Edge Detection Mask")
d:combobox{
  id="neighbors",
  label="Neighbor mode:",
  option="8-neighbor",
  options={"4-neighbor", "8-neighbor"}
}
:button{ id="ok", text="&OK", focus=true }
:button{ text="&Cancel" }
:show()

local data = d.data
if not data.ok then return end

local use8 = (data.neighbors == "8-neighbor")

local img0 = cel.image
local w, h = img0.width, img0.height
local maskImg = Image(w, h, img0.colorMode)

local rgba = app.pixelColor.rgba
local rgbaA = app.pixelColor.rgbaA

-- Fill entire canvas black first
for y = 0, h-1 do
  for x = 0, w-1 do
    maskImg:putPixel(x, y, rgba(0, 0, 0, 255))
  end
end

-- Define neighbor offsets
local offsets4 = {
  {1,0}, {-1,0}, {0,1}, {0,-1}
}
local offsets8 = {
  {1,0}, {-1,0}, {0,1}, {0,-1},
  {1,1}, {1,-1}, {-1,1}, {-1,-1}
}
local offsets = use8 and offsets8 or offsets4

-- Edge detection
for y = 0, h-1 do
  for x = 0, w-1 do
    local alpha = rgbaA(img0:getPixel(x, y))
    if alpha == 255 then
      local isEdge = false
      for _,off in ipairs(offsets) do
        local nx, ny = x+off[1], y+off[2]
        if nx < 0 or ny < 0 or nx >= w or ny >= h then
          isEdge = true
          break
        else
          if rgbaA(img0:getPixel(nx, ny)) < 255 then
            isEdge = true
            break
          end
        end
      end
      if isEdge then
        maskImg:putPixel(x, y, rgba(255, 255, 255, 255))
      end
    end
  end
end

-- Place result in new layer
local sprite = app.activeSprite
local frame = app.activeFrame
local currentLayer = app.activeLayer
local maskLayerName = currentLayer.name .. "_EdgeMask"

-- search manually for existing layer
local maskLayer = nil
for i, layer in ipairs(sprite.layers) do
  if layer.name == maskLayerName then
    maskLayer = layer
    break
  end
end

if not maskLayer then
  maskLayer = sprite:newLayer()
  maskLayer.name = maskLayerName
end

sprite:newCel(maskLayer, frame, maskImg, cel.position)

app.refresh()
