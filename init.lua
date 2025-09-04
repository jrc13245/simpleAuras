-- SavedVariables root
simpleAuras = simpleAuras or {}

-- runtime only
sA = sA or { auraTimers = {}, frames = {}, dualframes = {}, draggers = {} }
sA.SuperWoW = SetAutoloot and true or false
sA.learnNew = {}
local _, playerGUID = UnitExists("player")
sA.playerGUID = playerGUID

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
  simpleAuras.showlearned   = simpleAuras.showlearned or 0
end

---------------------------------------------------
-- Helper Functions
---------------------------------------------------

local function GetAuraDurationBySpellID(spellID, casterGUID)
  if not spellID or not casterGUID then return nil end
  if type(simpleAuras.auradurations[spellID]) ~= "table" then
	simpleAuras.auradurations[spellID] = nil
	return nil
  end
  return simpleAuras.auradurations[spellID][casterGUID]
end

local function inAuras(spellName)
    for _, aura in ipairs(simpleAuras.auras) do
        if aura.name == spellName then
            return true, aura.myCast
        end
    end
    return false
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
			
            if ActiveCasts[targetGUID] and ActiveCasts[targetGUID][spellID] and ActiveCasts[targetGUID][spellID].duration then
              local castTime = ActiveCasts[targetGUID][spellID].duration
              local actual   = timestamp - castTime
			  local casterGUID = ActiveCasts[targetGUID][spellID].castby
			  simpleAuras.auradurations[spellID] = simpleAuras.auradurations[spellID] or {}
              simpleAuras.auradurations[spellID][casterGUID] = floor(actual + 0.5)
			  sA.learnNew[spellID] = nil
              if simpleAuras.updating == 1 then
                sA:Msg("Updated " .. spellName .. " (ID:"..spellID..") to: " .. floor(actual + 0.5) .. "s")
              elseif simpleAuras.showlearned == 1 then
				sA:Msg("Learned " .. spellName .. " (ID:"..spellID..") duration: " .. floor(actual + 0.5) .. "s")
			  end
              ActiveCasts[targetGUID][spellID].duration = nil
              ActiveCasts[targetGUID][spellID].castby = nil
            end
			
            sA.auraTimers[targetGUID][spellID] = nil
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
	  
      local spellName = SpellInfo(spellID)
	  local found, myCast = inAuras(spellName)

	  if found and spellID then

		  -- Get a fresh player GUID each time to avoid stale data and normalize it.
		  local _, freshPlayerGUID = UnitExists("player")
		  if freshPlayerGUID then
			  sA.playerGUID = gsub(freshPlayerGUID, "^0x", "")
		  end
		  
		  -- Normalize other GUIDs for reliable comparison
		  if casterGUID then casterGUID = gsub(casterGUID, "^0x", "") end
		  if targetGUID then targetGUID = gsub(targetGUID, "^0x", "") end

		  local dur = GetAuraDurationBySpellID(spellID,casterGUID)
	  
		  if dur and dur > 0 and simpleAuras.updating == 0 and (casterGUID == sA.playerGUID or myCast == 0) then
			sA.auraTimers[targetGUID] = sA.auraTimers[targetGUID] or {}
			sA.auraTimers[targetGUID][spellID] = sA.auraTimers[targetGUID][spellID] or {}
			sA.auraTimers[targetGUID][spellID].duration = timestamp + dur
			sA.auraTimers[targetGUID][spellID].castby = casterGUID
			sA.learnNew[spellID] = nil
		  elseif casterGUID == sA.playerGUID or myCast == 0 then
		  
			if not targetGUID or targetGUID == "" then targetGUID = sA.playerGUID end
			
			ActiveCasts[targetGUID] = ActiveCasts[targetGUID] or {}
			ActiveCasts[targetGUID][spellID] = ActiveCasts[targetGUID][spellID] or {}
			ActiveCasts[targetGUID][spellID].duration = timestamp
			ActiveCasts[targetGUID][spellID].castby = casterGUID
			
			sA.auraTimers[targetGUID] = sA.auraTimers[targetGUID] or {}
			sA.auraTimers[targetGUID][spellID] = sA.auraTimers[targetGUID][spellID] or {}
			sA.auraTimers[targetGUID][spellID].duration = 0
			sA.auraTimers[targetGUID][spellID].castby = casterGUID
			
			-- Only learn auras that are not cast by the player
			if casterGUID ~= sA.playerGUID then
				sA.learnNew[spellID] = 1
			end
			
			if simpleAuras.updating == 1 then
			  sA:Msg("Updating " .. (spellName or spellID) .. " (ID:"..spellID..")...")
			elseif simpleAuras.showlearned == 1 then
			  sA:Msg("Learning " .. (spellName or spellID) .. " (ID:"..spellID..")...")
			end
			
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
		
  -- Cache the UI scale in a safe context
  sA.uiScale = UIParent:GetEffectiveScale()

  -- Handle Move Mode with Ctrl Key
  local mainFrame = _G["sAGUI"]
  if mainFrame and mainFrame:IsVisible() and IsControlKeyDown() and IsAltKeyDown() and IsShiftKeyDown() then

	if sA.moveAuras ~= 1 then
			
		-- TestAura
		if sA.TestAura and sA.TestAura:IsVisible() then
			
			sA.draggers[0]:Show()
			gui:SetAlpha(0)
			gui.editor:SetAlpha(0)
			
		else
	  
			-- Continuously show draggers for any visible frames while in move mode
			for id, frame in pairs(sA.frames) do
			  if frame:IsVisible() and sA.draggers[id] then
				sA.draggers[id]:Show()
				gui:SetAlpha(0)
				if gui.editor then
				  gui.editor:SetAlpha(0)
				end
			  end
			end
			
		end

		sA.moveAuras = 1

	end
	
  else

	if sA.moveAuras == 1 then
				
		-- Hide all draggers when not in move mode
	    for id, dragger in pairs(sA.draggers) do
	      if dragger then
			dragger:Hide()
	        gui:SetAlpha(1)
			if gui.editor then
	          gui.editor:SetAlpha(1)
			end
		  end
	    end
		
		-- Reload data if in editor
		if gui.editor and gui.auraEdit and sA.draggers[0] and sA.draggers[0]:IsVisible() then
			
			sA:SaveAura(gui.auraEdit)
			
		end

		sA.moveAuras = 0

	end
	
  end
		
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

	-- Get Command
	if type(msg) ~= "string" then
		msg = ""
	end

	-- Get Command Arguments
	local cmd, val
	local s, e, a, b, c = string.find(msg, "^(%S+)%s*(%S*)%s*(%S*)$")
	if a then cmd = a else cmd = "" end
	if b then val = b else val = "" end
	if c then fad = c else fad = "" end
	
	-- hide / show or no command
	if cmd == "" or cmd == "show" or cmd == "hide" then
		if gui.auraEdit then gui.auraEdit = nil end
		if cmd == "show" then
			if not gui:IsVisible() then gui:Show() end
		elseif cmd == "hide" then
			if gui:IsVisible() then gui:Hide() sA.TestAura:Hide() sA.TestAuraDual:Hide() end
		else 
			if gui:IsVisible() then gui:Hide() sA.TestAura:Hide() sA.TestAuraDual:Hide() else gui:Show() end
		end
		sA:RefreshAuraList()
		return
	end
	
	-- refresh command
	if cmd == "refresh" then
		local num = tonumber(val)
		if num and num >= 1 and num <= 10 then
			simpleAuras.refresh = num
			sA:Msg("Refresh set to " .. num .. " times per second")
		else
			sA:Msg("Usage: /sa refresh X - Set refresh rate. (1 to 10 updates per second. Default: 5)")
			sA:Msg("Current refresh = " .. tostring(simpleAuras.refresh) .. " times per second")
		end
		return
	end
	
	-- refresh command
	if cmd == "update" then
		local num = tonumber(val)
		if num and num >= 0 and num <= 1 then
			simpleAuras.updating = num
			sA:Msg("Aura durations update status set to " .. num)
		else
			sA:Msg("/sa update X - force aura durations updates (1 = learn aura durations. Default: 0)")
			sA:Msg("Current update status = " .. tostring(simpleAuras.updating))
		end
		return
	end
	
	-- manual learning of durations
	if cmd == "learn" then
		if sA.SuperWoW then
			local spell = tonumber(val)
			local fade = tonumber(fad)
			if spell and fade then
				local _, unitGUID = UnitExists("target")
				if not unitGUID then sA:Msg("No unit selected.") return end
				unitGUID = gsub(unitGUID, "^0x", "")
				simpleAuras.auradurations[spell] = simpleAuras.auradurations[spell] or {}
				simpleAuras.auradurations[spell][unitGUID] = fade
				sA:Msg("Set Duration of "..SpellInfo(spell).."("..spell..") cast by "..unitGUID.." to " .. fade .. " seconds.")
			else
				sA:Msg("/sa learn X Y - manually set duration Y of spellID X cast by current target.")
			end
		else
			sA:Msg("/sa learn needs SuperWoW to be installed!")
		end
		return
	end
	
	-- track others
	if cmd == "showlearned" then
		if sA.SuperWoW then
			local num = tonumber(val)
			if num and num >= 0 and num <= 1 then
				simpleAuras.showlearned = num
				sA:Msg("ShowLearned status set to " .. num)
			else
				sA:Msg("/sa showlearned X - shows new AuraDurations learned in chat (1 = show. Default: 0)")
				sA:Msg("Current ShowLearned status = " .. tostring(simpleAuras.showlearned or 0))
			end
			return
		else
			sA:Msg("/sa showlearned needs SuperWoW to be installed!")
		end
		return
	end
	
	-- delete
	if cmd == "delete" then
		local arg = val
		if val and val == "all" then
			simpleAuras.auradurations = {}
			sA:Msg("All learned AuraDurations deleted.")
		elseif val and val == "1" then
			local _, unitGUID = UnitExists("target")
			if not unitGUID then sA:Msg("No unit selected.") return end
			unitGUID = gsub(unitGUID, "^0x", "")
			for spellID, units in pairs(simpleAuras.auradurations) do
				if type(units) == "table" and units[unitGUID] then
					units[unitGUID] = nil
					if next(units) == nil then
						simpleAuras.auradurations[spellID] = nil
					end
				elseif type(units) ~= "table" and simpleAuras.auradurations[spellID] then
					simpleAuras.auradurations[spellID] = nil
				end
			end
			sA:Msg("All learned AuraDurations casted by unitGUID "..unitGUID.." deleted.")
		else
			sA:Msg("/sa delete 1 - Delete all learned AuraDurations of your target (or use 'all' instead of 1 to delete all durations).")
		end
		return
	end
	

	-- help or unknown command fallback
	sA:Msg("Usage:")
	sA:Msg("/sa or /sa show or /sa hide - Show/hide simpleAuras Settings")
	sA:Msg("/sa refresh X - Set refresh rate. (1 to 10 updates per second. Default: 5)")
	sA:Msg("/sa update X - force aura durations updates (1 = learn aura durations. Default: 0)")
	sA:Msg("/sa learn X Y - manually set duration Y of spellID X cast by current target.")
	sA:Msg("/sa showlearned X - shows new AuraDurations learned in chat (1 = show. Default: 0)")
	sA:Msg("/sa delete 1 - Delete all learned AuraDurations of your target (or use 'all' instead of 1 to delete all durations).")

end


