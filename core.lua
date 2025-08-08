-- core.lua (cleaned version)

-- Globals & defaults
simpleAuras = simpleAuras or {}
sA = { frames = {}, dualframes = {} }

simpleAuras.auras   = simpleAuras.auras   or {}
simpleAuras.refresh = simpleAuras.refresh or 5

-- Parent frame
local sAParent = CreateFrame("Frame", "sAParentFrame", nil)
sAParent:SetFrameStrata("BACKGROUND")
sAParent:SetAllPoints(UIParent)

-- Utility: skin frame with backdrop
function sA:SkinFrame(frame, bg, border)
  frame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  frame:SetBackdropColor(unpack(bg or {0.1, 0.1, 0.1, 0.95}))
  frame:SetBackdropBorderColor(unpack(border or {0, 0, 0, 1}))
end

-- Get aura info (1.12 compatible)
function sA:GetAuraInfo(unit, index, auraType)
  local name, icon, duration, stacks

  if not sAScanner then
    sAScanner = CreateFrame("GameTooltip", "sAScanner", sAParent, "GameTooltipTemplate")
    sAScanner:SetOwner(sAParent, "ANCHOR_NONE")
  end
  sAScanner:ClearLines()

  if unit == "Player" then
    local buffindex
    if auraType == "Buff" then
      buffindex = GetPlayerBuff(index - 1, "HELPFUL")
    else
      buffindex = GetPlayerBuff(index - 1, "HARMFUL")
    end
    sAScanner:SetPlayerBuff(buffindex)
    icon     = GetPlayerBuffTexture(buffindex)
    duration = GetPlayerBuffTimeLeft(buffindex)
    stacks   = GetPlayerBuffApplications(buffindex)
  else
    if auraType == "Buff" then
      sAScanner:SetUnitBuff(unit, index)
      icon = UnitBuff(unit, index)
    else
      sAScanner:SetUnitDebuff(unit, index)
      icon = UnitDebuff(unit, index)
    end
    duration = 0 -- temp for non-player units
  end

  name = sAScannerTextLeft1:GetText()
  local rounded = math.floor(duration + 1 - (1 / simpleAuras.refresh))
  return name, icon, rounded, stacks
end

-- Create aura display frame
local function CreateAuraFrame(id)
  local f = CreateFrame("Frame", "sAAura" .. id, UIParent)
  f:SetFrameStrata("BACKGROUND")
  f.durationtext = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.durationtext:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
  f.durationtext:SetPoint("CENTER")
  f.stackstext = f:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  f.stackstext:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
  f.stackstext:SetPoint("TOPLEFT", f.durationtext, "CENTER", 1, -6)
  f.texture = f:CreateTexture(nil, "BACKGROUND")
  f.texture:SetAllPoints(f)
  return f
end

-- Create mirrored dual frame
local function CreateDualFrame(id)
  local f = CreateAuraFrame(id)
  f.texture:SetTexCoord(1, 0, 0, 1)
  f.durationtext:SetPoint("CENTER")
  f.stackstext:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
  return f
end

-- Update aura display
function sA:UpdateAuras()
  if not gui.editor or not gui.editor:IsVisible() then
    if sA.TestAura then sA.TestAura:Hide() end
    if sA.TestAuraDual then sA.TestAuraDual:Hide() end
    if gui.editor then gui.editor:Hide(); gui.editor = nil end
  end

  for id, aura in ipairs(simpleAuras.auras) do
    local currentDuration, currentStacks, show = nil, nil, 0

    if aura.name ~= "" then
      local i = 1
      while true do
        local name, icon, duration, stacks = self:GetAuraInfo(aura.unit, i, aura.type)
        if not name then break end
        if name == aura.name then
          show, currentDuration, currentStacks = 1, duration, stacks
          if aura.autodetect == 1 then
            aura.texture = icon
            simpleAuras.auras[id].texture = icon
          end
        end
        i = i + 1
      end
      if aura.invert == 1 then show = 1 - show end
    end

    local frame     = self.frames[id]     or CreateAuraFrame(id)
    local dualframe = self.dualframes[id] or (aura.dual == 1 and CreateDualFrame(id))
    self.frames[id]     = frame
    if aura.dual == 1 then self.dualframes[id] = dualframe end

    if (show == 1 or (gui and gui:IsVisible())) and (not gui.editor or not gui.editor:IsVisible()) then
      local color = (aura.lowduration == 1 and currentDuration and currentDuration <= aura.lowdurationvalue)
        and (aura.lowdurationcolor or {1, 0, 0, 1})
        or  (aura.auracolor        or {1, 1, 1, 1})

      frame:SetPoint("CENTER", UIParent, "CENTER", aura.xpos or 0, aura.ypos or 0)
      frame:SetFrameLevel(128 - id)
      frame:SetWidth(aura.size or 32)
      frame:SetHeight(aura.size or 32)
      frame.texture:SetTexture(aura.texture)
      frame.texture:SetVertexColor(unpack(color))
      frame.durationtext:SetText((aura.duration == 1 and aura.unit == "Player") and currentDuration or "")
      frame.stackstext:SetText((aura.stacks   == 1) and currentStacks or "")
      frame:Show()

      if aura.dual == 1 then
        dualframe:SetPoint("CENTER", UIParent, "CENTER", (-1 * (aura.xpos or 0)), aura.ypos or 0)
        dualframe:SetFrameLevel(128 - id)
        dualframe:SetWidth(aura.size or 32)
        dualframe:SetHeight(aura.size or 32)
        dualframe.texture:SetTexture(aura.texture)
        dualframe.texture:SetVertexColor(unpack(color))
        dualframe.durationtext:SetText((aura.duration == 1 and aura.unit == "Player") and currentDuration or "")
        dualframe.stackstext:SetText((aura.stacks   == 1) and currentStacks or "")
        dualframe:Show()
      elseif dualframe then
        dualframe:Hide()
      end
    else
      if frame     then frame:Hide()     end
      if dualframe then dualframe:Hide() end
    end
  end
end

-- Event frame for timed updates
local sAEvent = CreateFrame("Frame", "sAEvent", sAParent)
sAEvent:SetScript("OnUpdate", function()
  local time = GetTime()
  local refreshRate = 1 / simpleAuras.refresh
  if (time - (sAEvent.lastUpdate or 0)) < refreshRate then return end
  sAEvent.lastUpdate = time
  sA:UpdateAuras()
end)
