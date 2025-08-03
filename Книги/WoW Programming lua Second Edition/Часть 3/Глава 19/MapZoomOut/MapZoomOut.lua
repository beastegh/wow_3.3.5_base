local timerFrame = CreateFrame("Frame")
local DELAY = 20
local counter = 0
local origSetZoom = Minimap.SetZoom

function Minimap.SetZoom(...)
  -- Показать фрейм таймера, запуск таймера
  timerFrame:Show()
  counter = 0
  -- Вызов оригинальной функции SetZoom
  return origSetZoom(...)
end

local function OnUpdate(self, elapsed)
-- Увеличение переменной счетчика
counter = counter + elapsed
  if counter >= DELAY then
    -- Проверка текущего уровня масштабирования
    local z = Minimap:GetZoom()
    if z > 0 then
      origSetZoom(Minimap, z - 1)
    else
      -- Включение/выключение кнопок
      MinimapZoomIn:Enable()
      MinimapZoomOut:Disable()
      self:Hide()
    end
  end
end

timerFrame:SetScript("OnUpdate", OnUpdate)

if Minimap:GetZoom() == 0 then
  timerFrame:Hide()
end