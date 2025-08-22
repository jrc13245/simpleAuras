-- perf: cache globals
local floor, format = math.floor, string.format
local getn = table.getn

-- Parent frame
local sAParent = CreateFrame("Frame", "sAParentFrame", UIParent)
sAParent:SetFrameStrata("BACKGROUND")
sAParent:SetAllPoints(UIParent)

-- Utility: skin frame with backdrop
function sA:SkinFrame(frame, bg, border)
  frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
  local bgr = bg or {0.1, 0.1, 0.1, 0.95}
  local bdr = border or {0, 0, 0, 1}
  frame:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
  frame:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
end

-- Cooldown info by spell name
function sA:GetCooldownInfo(spellName)
  local i = 1
  while true do
    local name = GetSpellName(i, "spell")
    if not name then break end
    if name == spellName then
      local start, duration, enabled = GetSpellCooldown(i, "spell")
      local texture = GetSpellTexture(i, "spell")
      local remaining
      if duration and duration > 0 and enabled == 1 then
        if duration > 1.5 then
          remaining = (start + duration) - GetTime()
          if remaining and remaining <= 0 then remaining = nil end
        end
      end
      return texture, remaining, 0
    end
    i = i + 1
  end
  return nil, nil, nil
end

-- superwow-aware aura search
local function find_aura(name, unit, auratype)
  local function search(is_debuff)
    local i = (unit == "Player") and 0 or 1
    while true do
      local tex, stacks, sid, rem
      if unit == "Player" then
        local buffType = is_debuff and "HARMFUL" or "HELPFUL"
        local bid      = GetPlayerBuff(i, buffType)
        tex    = GetPlayerBuffTexture(bid)
        stacks = GetPlayerBuffApplications(bid)
        sid    = GetPlayerBuffID(bid)
        rem    = GetPlayerBuffTimeLeft(bid)
      else
        if is_debuff then
          tex, stacks, _, sid, rem = UnitDebuff(unit, i)
        else
          tex, stacks, sid, rem = UnitBuff(unit, i)
        end
      end
      if not tex then break end
      if sid and name == SpellInfo(sid) then
        return true, stacks, sid, rem, tex
      end
      i = i + 1
    end
    return false
  end

  local was_found, stacks, sid, rem, tex
  if auratype == "Buff" then
    was_found, stacks, sid, rem, tex = search(false)
  else
    was_found, stacks, sid, rem, tex = search(true)
    if not was_found then
      was_found, stacks, sid, rem, tex = search(false)
    end
  end
  return was_found, stacks, sid, rem, tex
end

-- Get Icon / Duration / Stacks (SuperWoW)
function sA:GetAuraInfo(name, unit, auratype)
  if auratype == "Cooldown" then
    local texture, remaining_time = self:GetCooldownInfo(name)
    return texture, remaining_time, 1
  end

  local found, stacks, spellID, remaining_time, texture = find_aura(name, unit, auratype)
  if found then
    if (not remaining_time or remaining_time == 0) and spellID and sA.auraTimers then
      local _, unitGUID = UnitExists(unit)
      if unitGUID then
        unitGUID = string.upper(string.gsub(unitGUID, "^0x", ""))
        local timers = sA.auraTimers[unitGUID]
        if timers and timers[spellID] then
          local expiry = timers[spellID]
          if expiry > GetTime() then
            remaining_time = expiry - GetTime()
          else
            remaining_time = 0
          end
        end
      end
    end
    return texture, remaining_time, stacks
  end
end

-- Tooltip-based aura info (no SuperWoW)
function sA:GetAuraInfoBase(auraname, unit, auratype)
  if auratype == "Cooldown" then
    local texture, remaining_time = self:GetCooldownInfo(auraname)
    return texture, remaining_time, 1
  end

  if not sAScanner then
    sAScanner = CreateFrame("GameTooltip", "sAScanner", sAParent, "GameTooltipTemplate")
    sAScanner:SetOwner(sAParent, "ANCHOR_NONE")
  end

  local function AuraInfo(unit, index, kind)
    local name, icon, duration, stacks
    sAScanner:ClearLines()
    if unit == "Player" then
      local buffindex = (kind == "Buff") and GetPlayerBuff(index - 1, "HELPFUL") or GetPlayerBuff(index - 1, "HARMFUL")
      sAScanner:SetPlayerBuff(buffindex)
      icon     = GetPlayerBuffTexture(buffindex)
      duration = GetPlayerBuffTimeLeft(buffindex)
      stacks   = GetPlayerBuffApplications(buffindex)
    else
      if kind == "Buff" then
        sAScanner:SetUnitBuff(unit, index)
        icon = UnitBuff(unit, index)
      else
        sAScanner:SetUnitDebuff(unit, index)
        icon = UnitDebuff(unit, index)
      end
      duration = 0
    end
    name = sAScannerTextLeft1:GetText()
    return name, icon, duration, stacks
  end

  local i = 1
  while true do
    local name, icon, duration, stacks = AuraInfo(unit, i, auratype)
    if not name then break end
    if name == auraname then
      return icon, duration, stacks
    end
    i = i + 1
  end
end

-- Create aura display frame
local function CreateAuraFrame(id)
  local f = CreateFrame("Frame", "sAAura" .. id, UIParent)
  f:SetFrameStrata("BACKGROUND")
  f.durationtext = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.durationtext:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
  f.durationtext:SetPoint("CENTER", f, "CENTER", 0, 0)
  f.stackstext = f:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  f.stackstext:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  f.stackstext:SetPoint("TOPLEFT", f.durationtext, "CENTER", 1, -6)
  f.texture = f:CreateTexture(nil, "BACKGROUND")
  f.texture:SetAllPoints(f)
  return f
end

-- Create mirrored dual frame
local function CreateDualFrame(id)
  local f = CreateAuraFrame(id)
  f.texture:SetTexCoord(1, 0, 0, 1)
  f.durationtext:SetPoint("CENTER", f, "CENTER", 0, 0)
  f.stackstext:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
  return f
end

-- Update aura display
function sA:UpdateAuras()
  -- hide test/editor when not editing
  if not gui or not gui.editor or not gui.editor:IsVisible() then
    if sA.TestAura     then sA.TestAura:Hide() end
    if sA.TestAuraDual then sA.TestAuraDual:Hide() end
    if gui and gui.editor then gui.editor:Hide(); gui.editor = nil end
  end

  local total = getn(simpleAuras.auras)
  for id = 1, total do
    local aura = simpleAuras.auras[id]
    local currentDuration, currentStacks, show, currentDurationtext = 600, 20, 0, ""

    if aura.name ~= "" and ((aura.inCombat == 1 and sAinCombat) or (aura.outCombat == 1 and not sAinCombat)) then
      local icon, duration, stacks
      if sA.SuperWoW then
        icon, duration, stacks = self:GetAuraInfo(aura.name, aura.unit, aura.type)
      else
        icon, duration, stacks = self:GetAuraInfoBase(aura.name, aura.unit, aura.type)
      end
      if icon then
        show, currentDuration, currentStacks = 1, duration, stacks
        if aura.autodetect == 1 and simpleAuras.auras[id].texture ~= icon then
          aura.texture = icon
          simpleAuras.auras[id].texture = icon
        end
      end

      if aura.type == "Cooldown" then
        show = 0
        if aura.invert == 1 and not currentDuration then show = 1 end
        if aura.dual   == 1 and currentDuration then show = 1 end
      elseif aura.invert == 1 then
        show = 1 - show
      end
    end

    local frame     = self.frames[id]     or CreateAuraFrame(id)
    local dualframe = self.dualframes[id] or (aura.dual == 1 and CreateDualFrame(id))
    self.frames[id] = frame
    if aura.dual == 1 and aura.type ~= "Cooldown" then self.dualframes[id] = dualframe end

    if (show == 1 or (gui and gui:IsVisible())) and (not gui or not gui.editor or not gui.editor:IsVisible()) then
      local color = (aura.lowduration == 1 and currentDuration and currentDuration <= aura.lowdurationvalue)
        and (aura.lowdurationcolor or {1, 0, 0, 1})
        or  (aura.auracolor        or {1, 1, 1, 1})

      if aura.duration == 1 then
        if currentDuration and currentDuration > 100 then
          currentDurationtext = floor(currentDuration/60 + 0.5) .. "m"
        else
          if currentDuration and (currentDuration <= (aura.lowdurationvalue or 5)) then
            currentDurationtext = string.format("%.1f", floor(currentDuration*10 + 0.5)/10)
          elseif currentDuration then
            currentDurationtext = floor(currentDuration + 0.5)
          end
        end
      end

      if currentDurationtext == "0.0" then
        currentDurationtext = 0
      elseif currentDurationtext == "0" then
        currentDurationtext = "learning..."
      end

      frame:SetPoint("CENTER", UIParent, "CENTER", aura.xpos or 0, aura.ypos or 0)
      frame:SetFrameLevel(128 - id)
      frame:SetWidth(48*(aura.scale or 1))
      frame:SetHeight(48*(aura.scale or 1))
      frame.texture:SetTexture(aura.texture)
      frame.durationtext:SetText((aura.duration == 1 and (sA.SuperWoW or aura.unit == "Player" or aura.type == "Cooldown")) and currentDurationtext or "")
      frame.stackstext:SetText((aura.stacks   == 1) and currentStacks or "")
      if aura.duration == 1 then frame.durationtext:SetFont("Fonts\\FRIZQT__.TTF", (20*aura.scale), "OUTLINE") end
      if aura.stacks   == 1 then frame.stackstext:SetFont("Fonts\\FRIZQT__.TTF", (14*aura.scale), "OUTLINE") end

      local r, g, b, durationalpha = unpack(color or {1,1,1,1})
      if aura.type == "Cooldown" and currentDuration then
        frame.texture:SetVertexColor(r*0.5, g*0.5, b*0.5, durationalpha)
      else
        frame.texture:SetVertexColor(r, g, b, durationalpha)
      end

      local durationcolor = {1.0, 0.82, 0.0, durationalpha}
      local stackcolor    = {1, 1, 1, durationalpha}
      if (sA.SuperWoW or aura.unit == "Player" or aura.type == "Cooldown") and (currentDuration and currentDuration <= (aura.lowdurationvalue or 5)) then
        durationcolor = {1, 0, 0, durationalpha}
        stackcolor    = {1, 1, 1, durationalpha}
      end
      frame.durationtext:SetTextColor(unpack(durationcolor))
      frame.stackstext:SetTextColor(unpack(stackcolor))
      frame:Show()

      if aura.dual == 1 and aura.type ~= "Cooldown" then
        dualframe:SetPoint("CENTER", UIParent, "CENTER", (-1 * (aura.xpos or 0)), aura.ypos or 0)
        dualframe:SetFrameLevel(128 - id)
        dualframe:SetWidth(48*(aura.scale or 1))
        dualframe:SetHeight(48*(aura.scale or 1))
        dualframe.texture:SetTexture(aura.texture)
        if aura.type == "Cooldown" and currentDuration then
          dualframe.texture:SetVertexColor(r*0.5, g*0.5, b*0.5, durationalpha)
        else
          dualframe.texture:SetVertexColor(r, g, b, durationalpha)
        end
        dualframe.durationtext:SetText((aura.duration == 1 and (sA.SuperWoW or aura.unit == "Player" or aura.type == "Cooldown")) and currentDurationtext or "")
        dualframe.stackstext:SetText((aura.stacks   == 1) and currentStacks or "")
        if aura.duration == 1 then dualframe.durationtext:SetFont("Fonts\\FRIZQT__.TTF", (20*aura.scale), "OUTLINE") end
        if aura.stacks   == 1 then dualframe.stackstext:SetFont("Fonts\\FRIZQT__.TTF", (14*aura.scale), "OUTLINE") end
        dualframe.durationtext:SetTextColor(unpack(durationcolor))
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
