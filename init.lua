-- SavedVariables root
simpleAuras = simpleAuras or {}

-- runtime only
sA = { auraTimers = {}, frames = {}, dualframes = {} }
sA.SuperWoW = SetAutoloot and true or false
sAinCombat = nil

-- Track temporary casts for updating durations
local ActiveCasts = {} -- ActiveCasts[targetGUID][spellID] = time of cast

---------------------------------------------------
-- SavedVariables Initialization
---------------------------------------------------

-- Ensure table exists
if not simpleAuras then simpleAuras = {} end

-- Defaults
simpleAuras.auras          = simpleAuras.auras or {}
simpleAuras.refresh        = simpleAuras.refresh or 10
if sA.SuperWoW then
	simpleAuras.auradurations  = simpleAuras.auradurations or {}
	simpleAuras.updating       = simpleAuras.updating or 0
end

---------------------------------------------------
-- Helper Functions
---------------------------------------------------

-- Get duration helper
local function GetAuraDurationBySpellID(spellID)
    if not spellID then return nil end
    return simpleAuras.auradurations[spellID]
end

-- Durations
if sA.SuperWoW then
	local sADuration = CreateFrame("Frame")
	sADuration:RegisterEvent("RAW_COMBATLOG")
	sADuration:RegisterEvent("UNIT_CASTEVENT")
	sADuration:SetScript("OnEvent", function()
	    
		local timestamp = GetTime()
		
	    if event == "RAW_COMBATLOG" and simpleAuras.auradurations then
	        local raw = arg2
	        if not raw or not string.find(raw, "fades from") then return end
	        local _, _, spellName = string.find(raw, "^(.-) fades from ")
	        local _, _, targetGUID = string.find(raw, "from (.-).$")
	        if string.lower(targetGUID) == "you" then
	            _, targetGUID = UnitExists("player")
	        end
	        targetGUID = string.gsub(targetGUID or "", "^0x", "")
	        if not spellName or not targetGUID then return end
			
	        if not sA.auraTimers[targetGUID] then return end
			
			for spellID in pairs(sA.auraTimers[targetGUID]) do
				local n = SpellInfo(spellID)
				if n then
					n = string.gsub(n, "%s*%(%s*Rank%s+%d+%s*%)", "")
					if n == spellName then
						-- Calculate actual duration if updating
						if ActiveCasts[targetGUID] and ActiveCasts[targetGUID][spellID] then
							local castTime = ActiveCasts[targetGUID][spellID]
							local actualDur = timestamp - castTime
							simpleAuras.auradurations[spellID] = math.floor(actualDur+0.5)
							if simpleAuras.updating == 1 then
								DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccsimple|cffffffffAuras: Updated duration for "..spellName.." ("..spellID..") to: "..(math.floor(actualDur+0.5)).."s")
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
	
	    -- Handle casts (gains)
	    elseif event == "UNIT_CASTEVENT" and simpleAuras.auradurations then
	        local casterGUID, targetGUID, evType, spellID = arg1, arg2, arg3, arg4
	        if evType ~= "CAST" or not targetGUID or not spellID then return end
	        local dur = GetAuraDurationBySpellID(spellID)
	        local spellName = SpellInfo(spellID)
	
			local _, playerGUID = UnitExists("player")
			playerGUID = string.gsub(playerGUID, "^0x", "")
	        if targetGUID then targetGUID = string.gsub(targetGUID, "^0x", "") end
	        casterGUID = string.gsub(casterGUID, "^0x", "")
			
	        if dur and dur > 0 and simpleAuras.updating == 0 then
	            sA.auraTimers[targetGUID] = sA.auraTimers[targetGUID] or {}
	            sA.auraTimers[targetGUID][spellID] = timestamp + dur
	        elseif casterGUID == playerGUID then
				if targetGUID == "" then targetGUID = playerGUID end
				ActiveCasts[targetGUID] = ActiveCasts[targetGUID] or {}
				ActiveCasts[targetGUID][spellID] = timestamp
				sA.auraTimers[targetGUID] = sA.auraTimers[targetGUID] or {}
				sA.auraTimers[targetGUID][spellID] = 0
				if simpleAuras.updating == 1 then
					DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccsimple|cffffffffAuras: Updating duration for "..spellName.." ("..spellID..") - wait for it to fade.")
				end
	        end
			
	    end
	end)
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

-- Slash Command
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
		if cmd == "show" then
			if not gui:IsVisible() then gui:Show() end
		elseif cmd == "hide" then
			if gui:IsVisible() then gui:Hide() sA.TestAura:Hide() sA.TestAuraDual:Hide() end
		else 
			if gui:IsVisible() then gui:Hide() sA.TestAura:Hide() sA.TestAuraDual:Hide() else gui:Show() end
		end
		RefreshAuraList()
		return
	end
	
	-- refresh command
	if cmd == "refresh" then
		local num = tonumber(val)
		if num and num >= 1 and num <= 100 then
			simpleAuras.refresh = num
			DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccsimple|cffffffffAuras: Refresh set to " .. num .. " times per second")
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccsimple|cffffffffAuras Usage: /sa refresh X - Set refresh rate. (1 to 100 updates per second. Default: 10)")
			DEFAULT_CHAT_FRAME:AddMessage("Current refresh = " .. tostring(simpleAuras.refresh) .. " times per second")
		end
		return
	end
	
	-- refresh command
	if cmd == "update" then
		if sA.SuperWoW then
			local num = tonumber(val)
			if num and num >= 0 and num <= 1 then
				simpleAuras.updating = num
				DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccsimple|cffffffffAuras: Aura durations update status set to " .. num)
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccsimple|cffffffffAuras Usage: /sa update X - force aura durations updates (1 = learn aura durations. Default: 0)")
				DEFAULT_CHAT_FRAME:AddMessage("Current update status = " .. tostring(simpleAuras.updating))
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccsimple|cffffffffAuras: /sa update requires SuperWoW!")
		end
		return
	end
	
	-- manual learning of durations
	if cmd == "learn" then
		if sA.SuperWoW then
			local spell = tonumber(val)
			local fade = tonumber(fad)
			if spell and fade then
				simpleAuras.auradurations[spell] = fade
				DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccsimple|cffffffffAuras: Set Duration of "..SpellInfo(spell).."("..spell..") to " .. fade .. " seconds.")
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccsimple|cffffffffAuras Usage: /sa learn spellID Duration - manually set duration of spell.")
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccsimple|cffffffffAuras: /sa learn requires SuperWoW!")
		end
		return
	end
	

	-- Unknown command fallback
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccsimple|cffffffffAuras Usage:")
	DEFAULT_CHAT_FRAME:AddMessage("/sa or /sa show or /sa hide - Show/hide simpleAuras Settings")
	DEFAULT_CHAT_FRAME:AddMessage("/sa refresh X - Set refresh rate. (1 to 100 updates per second. Default: 10)")
	if sA.SuperWoW then
		DEFAULT_CHAT_FRAME:AddMessage("/sa update X - force aura durations updates (1 = learn aura durations. Default: 0)")
		DEFAULT_CHAT_FRAME:AddMessage("/sa learn X Y - manually set duration Y for aura with ID X.")
	end


end


