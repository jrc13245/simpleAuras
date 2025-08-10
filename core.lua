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

-- Get aura info
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
  if unit ~= "Player" and (not duration or duration == 0) and name then
	CleveRoids.ValidateUnitDebuff(unit,name)
	if remaining_aura_duration then
		duration = remaining_aura_duration
	end
  end
  return name, icon, duration, stacks
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
  if not gui.editor or not gui.editor:IsVisible() then
    if sA.TestAura then sA.TestAura:Hide() end
    if sA.TestAuraDual then sA.TestAuraDual:Hide() end
    if gui.editor then gui.editor:Hide(); gui.editor = nil end
  end

  for id, aura in ipairs(simpleAuras.auras) do
  
    local currentDuration, currentStacks, show = 600, 20, 0

    if aura.name ~= "" then
      local i = 1
      while true do
        local name, icon, duration, stacks = self:GetAuraInfo(aura.unit, i, aura.type)
        if not name then break end
        if name == aura.name then
          show, currentDuration, currentStacks = 1, duration, stacks
		  if name == "Holy Fire" then print(name..":"..currentDuration) end
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
	
      if currentDuration and currentDuration > 100 then
        currentDurationtext = math.floor(currentDuration/60+0.5).."m"
	  else
		if currentDuration and ((aura.lowduration == 1 and currentDuration <= aura.lowdurationvalue) or (aura.lowduration ~= 1 and currentDuration <= 5)) then
          currentDurationtext = string.format("%.1f", math.floor(currentDuration*10+0.5)/10)
		else
          currentDurationtext = math.floor(currentDuration+0.5)
		end
	  end
	  
	  frame:SetPoint("CENTER", UIParent, "CENTER", aura.xpos or 0, aura.ypos or 0)
      frame:SetFrameLevel(128 - id)
      frame:SetWidth(48*(aura.scale or 1))
      frame:SetHeight(48*(aura.scale or 1))
      frame.texture:SetTexture(aura.texture)
      frame.texture:SetVertexColor(unpack(color))
      frame.durationtext:SetText((aura.duration == 1) and currentDurationtext or "")
      frame.stackstext:SetText((aura.stacks   == 1) and currentStacks or "")
      if aura.duration == 1 then frame.durationtext:SetFont("Fonts\\FRIZQT__.TTF", (18*aura.scale), "OUTLINE") end
      if aura.stacks == 1 then frame.stackstext:SetFont("Fonts\\FRIZQT__.TTF", (12*aura.scale), "OUTLINE") end
	  
	  local _, _, _, durationalpha = unpack(aura.auracolor or {1,1,1,1})
	  local durationcolor = {1.0, 0.82, 0.0, durationalpha}
	  local stackcolor = {1, 1, 1, durationalpha}
	  if aura.duration == 1
        and ((currentDuration and aura.lowduration == 1 and currentDuration <= aura.lowdurationvalue)
        or (aura.lowduration ~= 1 and currentDuration <= 5)) then
          local _, _, _, durationalpha = unpack(aura.auracolor)
          durationcolor = {1, 0, 0, durationalpha}
          stackcolor = {1, 1, 1, durationalpha}
	  end

	  frame.durationtext:SetTextColor(unpack(durationcolor))
	  frame.stackstext:SetTextColor(unpack(stackcolor))

      frame:Show()

      if aura.dual == 1 then
        dualframe:SetPoint("CENTER", UIParent, "CENTER", (-1 * (aura.xpos or 0)), aura.ypos or 0)
        dualframe:SetFrameLevel(128 - id)
        dualframe:SetWidth(48*(aura.scale or 1))
        dualframe:SetHeight(48*(aura.scale or 1))
        dualframe.texture:SetTexture(aura.texture)
        dualframe.texture:SetVertexColor(unpack(color))
        dualframe.durationtext:SetText((aura.duration == 1 and aura.unit == "Player") and currentDurationtext or "")
        dualframe.stackstext:SetText((aura.stacks   == 1) and currentStacks or "")
        if aura.duration == 1 then dualframe.durationtext:SetFont("Fonts\\FRIZQT__.TTF", (18*aura.scale), "OUTLINE") end
        if aura.stacks == 1 then dualframe.stackstext:SetFont("Fonts\\FRIZQT__.TTF", (12*aura.scale), "OUTLINE") end
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

local debuffTimers = {}     -- [unit][debuffName] = { startTime = x }
local debuffDurations = {}  -- [debuffName] = learned duration

-- Scan current debuffs on a unit, update timers and learn durations
local function ScanDebuffs(unit)
    if not debuffTimers[unit] then debuffTimers[unit] = {} end

    local seen = {}

    for i = 1, 16 do
        local texture = UnitDebuff(unit, i)
        if not texture then break end

        GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        GameTooltip:SetUnitDebuff(unit, i)
        local debuffName = GameTooltipTextLeft1:GetText()

        if debuffName then
            seen[debuffName] = true
            local currentTime = GetTime()

            if not debuffTimers[unit][debuffName] then
                -- New debuff: track start time
				if not debuffDurations[debuffName] then
					DEFAULT_CHAT_FRAME:AddMessage(
						string.format("Start Learning duration: %s", debuffName)
					)
				end
                debuffTimers[unit][debuffName] = { startTime = currentTime }
            else
                -- Debuff is already tracked: check if reapply happened
                -- If elapsed time since startTime is more than 0.1 sec, do nothing
                -- But if elapsed time is very small (refresh), reset timer
                local elapsed = currentTime - debuffTimers[unit][debuffName].startTime
                if elapsed < 0.1 then
                    debuffTimers[unit][debuffName].startTime = currentTime
                    -- Optional: print debug message
                    -- DEFAULT_CHAT_FRAME:AddMessage("Debuff reapplied: "..debuffName)
                end
            end
        end
    end

    -- Check for removed debuffs and learn durations (same as before)
    for debuffName, data in pairs(debuffTimers[unit]) do
        if not seen[debuffName] then
            local duration = GetTime() - data.startTime
            if duration > 0 then
                if not debuffDurations[debuffName] then
                    debuffDurations[debuffName] = math.floor(duration+0.5)
					DEFAULT_CHAT_FRAME:AddMessage(
						string.format("Learned duration: %s = %.1f sec", debuffName, debuffDurations[debuffName])
					)
                end
            end
            debuffTimers[unit][debuffName] = nil
        end
    end
end


-- Return remaining debuff time on unit
function GetRemainingDebuffTime(unit, debuffName)
    if debuffTimers[unit] and debuffTimers[unit][debuffName] and debuffDurations[debuffName] then
        local startTime = debuffTimers[unit][debuffName].startTime
        local duration = debuffDurations[debuffName]
        local remaining = (startTime + duration) - GetTime()
        return math.max(0, remaining)
    end
    return 0
end

local function PrintTargetDebuffs()
	
    local unit = "target"
    if not UnitExists(unit) then
        print("No target selected.")
        return
    end

    if not debuffTimers[unit] then
        print("No debuffs tracked on target.")
        return
    end
	
	if debuffTimers[unit] then
		for debuffName, data in pairs(debuffTimers[unit]) do
			local remaining = GetRemainingDebuffTime(unit, debuffName)
			if remaining > 0 then
				print(string.format("- %s: %.1f seconds remaining", debuffName, remaining))
			end
		end
	end
end


-- Create frame for events and OnUpdate scanning
local f = CreateFrame("Frame")

-- Also scan immediately when target changes or unit aura changes
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("UNIT_AURA")
f:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_TARGET_CHANGED" then
        if UnitExists("target") then
            ScanDebuffs("target")
        else
            debuffTimers["target"] = nil
        end
    elseif event == "UNIT_AURA" and unit == "target" then
        ScanDebuffs(unit)
    end
end)


-- Event frame for timed updates
local sAEvent = CreateFrame("Frame", "sAEvent", sAParent)
sAEvent:SetScript("OnUpdate", function()
  local time = GetTime()
  local refreshRate = 1 / simpleAuras.refresh
  if (time - (sAEvent.lastUpdate or 0)) < refreshRate then return end
  sAEvent.lastUpdate = time
  sA:UpdateAuras()
end)
