-- SavedVariables root
simpleAuras = simpleAuras or {}

-- runtime only
sA = sA or { auraTimers = {}, frames = {}, dualframes = {} }
sA.SuperWoW = SetAutoloot and true or false
sAinCombat = nil

-- perf: cache globals we use a lot (Lua 5.0-safe)
local gsub   = string.gsub
local find   = string.find
local lower  = string.lower
local floor  = math.floor
local tinsert = table.insert
local getn   = table.getn
local GetTime = GetTime

-- message helper
sA.PREFIX = "|c194b7dccsimple|cffffffffAuras: "
function sA:Msg(msg)
  DEFAULT_CHAT_FRAME:AddMessage(self.PREFIX .. msg)
end

-- Track temporary casts for updating durations
local ActiveCasts = {} -- ActiveCasts[targetGUID][spellID] = time of cast

---------------------------------------------------
-- SavedVariables Initialization
---------------------------------------------------

-- Ensure tables exist
if not simpleAuras then simpleAuras = {} end
simpleAuras.auras   = simpleAuras.auras   or {}
simpleAuras.refresh = simpleAuras.refresh or 5
if sA.SuperWoW then
  simpleAuras.auradurations = simpleAuras.auradurations or {}
  simpleAuras.updating      = simpleAuras.updating or 0
end

---------------------------------------------------
-- Helper Functions
---------------------------------------------------

local function GetAuraDurationBySpellID(spellID)
  if not spellID then return nil end
  return simpleAuras.auradurations[spellID]
end

-- SuperWoW: learn and track aura durations
if sA.SuperWoW then
  local sADuration = CreateFrame("Frame")
  sADuration:RegisterEvent("RAW_COMBATLOG")
  sADuration:RegisterEvent("UNIT_CASTEVENT")
  sADuration:SetScript("OnEvent", function()
    local timestamp = GetTime()

    if event == "RAW_COMBATLOG" and simpleAuras.auradurations then
      local raw = arg2
      if not raw or not find(raw, "fades from") then return end

      local _, _, spellName  = string.find(raw, "^(.-) fades from ")
      local _, _, targetGUID = string.find(raw, "from (.-).$")

      if lower(targetGUID or "") == "you" then _, targetGUID = UnitExists("player") end
      targetGUID = gsub(targetGUID or "", "^0x", "")
      if not spellName or targetGUID == "" then return end
      if not sA.auraTimers[targetGUID] then return end

      for spellID in pairs(sA.auraTimers[targetGUID]) do
        local n = SpellInfo(spellID)
        if n then
          n = gsub(n, "%s*%(%s*Rank%s+%d+%s*%)", "")
          if n == spellName then
            -- if we were learning this duration, compute actual
            if ActiveCasts[targetGUID] and ActiveCasts[targetGUID][spellID] then
              local castTime = ActiveCasts[targetGUID][spellID]
              local actual   = timestamp - castTime
              simpleAuras.auradurations[spellID] = floor(actual + 0.5)
              if simpleAuras.updating == 1 then
                sA:Msg("Updated duration for " .. spellName .. " ("..spellID..") to: " .. floor(actual + 0.5) .. "s")
              end
              ActiveCasts[targetGUID][spellID] = nil
            end

            sA.auraTimers[spellID] = nil
            if not next(sA.auraTimers[targetGUID]) then
              sA.auraTimers[targetGUID] = nil
            end
            break
          end
        end
      end

    elseif event == "UNIT_CASTEVENT" and simpleAuras.auradurations then
      local casterGUID, targetGUID, evType, spellID = arg1, arg2, arg3, arg4
      if evType ~= "CAST" or not spellID then return end

      local dur       = GetAuraDurationBySpellID(spellID)
      local spellName = SpellInfo(spellID)

      local _, playerGUID = UnitExists("player")
      playerGUID = gsub(playerGUID, "^0x", "")
      casterGUID = gsub(casterGUID or "", "^0x", "")
      if targetGUID then targetGUID = gsub(targetGUID, "^0x", "") end

      if dur and dur > 0 and simpleAuras.updating == 0 then
        sA.auraTimers[targetGUID] = sA.auraTimers[targetGUID] or {}
        sA.auraTimers[targetGUID][spellID] = timestamp + dur
      elseif casterGUID == playerGUID then
        if not targetGUID or targetGUID == "" then targetGUID = playerGUID end
        ActiveCasts[targetGUID] = ActiveCasts[targetGUID] or {}
        ActiveCasts[targetGUID][spellID] = timestamp
        sA.auraTimers[targetGUID] = sA.auraTimers[targetGUID] or {}
        sA.auraTimers[targetGUID][spellID] = 0
        if simpleAuras.updating == 1 then
          sA:Msg("Updating duration for " .. (spellName or spellID) .. " ("..spellID..") - wait for it to fade.")
        end
      end
    end
  end)
end

-- Timed updates
local sAEvent = CreateFrame("Frame", "sAEvent", UIParent)
sAEvent:SetScript("OnUpdate", function()
  local time = GetTime()
  local refreshRate = 1 / (simpleAuras.refresh or 5)
  if (time - (sAEvent.lastUpdate or 0)) < refreshRate then return end
  sAEvent.lastUpdate = time
  sA:UpdateAuras()
end)

-- Combat state
local sACombat = CreateFrame("Frame")
sACombat:RegisterEvent("PLAYER_REGEN_DISABLED")
sACombat:RegisterEvent("PLAYER_REGEN_ENABLED")
sACombat:SetScript("OnEvent", function()
  if event == "PLAYER_REGEN_DISABLED" then
    sAinCombat = true
  elseif event == "PLAYER_REGEN_ENABLED" then
    sAinCombat = nil
  end
end)

---------------------------------------------------
-- Slash Commands
---------------------------------------------------
SLASH_sA1 = "/sa"
SLASH_sA2 = "/simpleauras"
SlashCmdList["sA"] = function(msg)
  if type(msg) ~= "string" then msg = "" end

  local cmd, val, fad
  local _, _, a, b, c = string.find(msg, "^(%S+)%s*(%S*)%s*(%S*)$")
  if a then cmd = a else cmd = "" end
  if b then val = b else val = "" end
  if c then fad = c else fad = "" end

  -- toggle / show / hide
  if cmd == "" or cmd == "show" or cmd == "hide" then
    if cmd == "show" then
      if not gui:IsVisible() then gui:Show() end
    elseif cmd == "hide" then
      if gui:IsVisible() then gui:Hide(); if sA.TestAura then sA.TestAura:Hide() end; if sA.TestAuraDual then sA.TestAuraDual:Hide() end end
    else
      if gui:IsVisible() then gui:Hide(); if sA.TestAura then sA.TestAura:Hide() end; if sA.TestAuraDual then sA.TestAuraDual:Hide() end else gui:Show() end
    end
    sA:RefreshAuraList()
    return
  end

  -- refresh rate
  if cmd == "refresh" then
    local num = tonumber(val)
    if num and num >= 1 and num <= 10 then
      simpleAuras.refresh = num
      sA:Msg("Refresh set to " .. num .. " times per second")
    else
      sA:Msg("Usage: /sa refresh X — 1 to 10 updates per second (default: 5)")
      sA:Msg("Current refresh = " .. tostring(simpleAuras.refresh))
    end
    return
  end

  -- SuperWoW: enable live learning
  if cmd == "update" then
    if sA.SuperWoW then
      local num = tonumber(val)
      if num and num >= 0 and num <= 1 then
        simpleAuras.updating = num
        sA:Msg("Aura duration update status set to " .. num)
      else
        sA:Msg("Usage: /sa update X — 1=learn aura durations (default: 0)")
        sA:Msg("Current update status = " .. tostring(simpleAuras.updating))
      end
    else
      sA:Msg("/sa update requires SuperWoW!")
    end
    return
  end

  -- SuperWoW: manually set duration
  if cmd == "learn" then
    if sA.SuperWoW then
      local spell = tonumber(val)
      local fade  = tonumber(fad)
      if spell and fade then
        simpleAuras.auradurations[spell] = fade
        sA:Msg("Set duration of " .. (SpellInfo(spell) or spell) .. " ("..spell..") to " .. fade .. " seconds.")
      else
        sA:Msg("Usage: /sa learn <spellID> <durationSeconds>")
      end
    else
      sA:Msg("/sa learn requires SuperWoW!")
    end
    return
  end

  -- help
  sA:Msg("Usage:")
  sA:Msg("/sa, /sa show, /sa hide — open/close settings")
  sA:Msg("/sa refresh X — 1..100 updates/sec (default: 5)")
  if sA.SuperWoW then
    sA:Msg("/sa update X — 1=learn aura durations (default: 0)")
    sA:Msg("/sa learn <spellID> <duration>")
  end
end
