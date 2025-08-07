-- Initiate Globals
simpleAuras = simpleAuras or {}
sA = {}
sA.frames = {}
sA.dualframes = {}

-- Get AuraData and RefreshRate from SavedVariables
simpleAuras.auras = simpleAuras.auras or {}
simpleAuras.refresh = simpleAuras.refresh or 5

-- Set AddOnFrame
local sAParent = CreateFrame("Frame", "sAParentFrame", nil)
sAParent:SetFrameStrata("BACKGROUND")
sAParent:SetAllPoints(UIParent)

-- Function to skin frames with flat background and 1px black border
function sA:SkinFrame(frame, bg, border)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(unpack(bg or {0.1, 0.1, 0.1, 0.95}))
	frame:SetBackdropBorderColor(unpack(border or {0, 0, 0, 1}))
end

-- Get AuraData
function sA:GetAuraInfo(unit, index, auraType)

	local name, texture, duration, stacks, buffindex

	-- Create Scanner-Tooltip if not previously created
	if not sAScanner then
		sAScanner = CreateFrame("GameTooltip", "sAScanner", sAParent, "GameTooltipTemplate")
		sAScanner:SetOwner(sAParent, "ANCHOR_NONE")
	end

	-- Wipe Scanner-Tooltip Data
	sAScanner:ClearLines()

	-- PLayerBuffs start with ID 0 instead of 1
	if unit == "Player" then
	
		if auraType == "Buff" then
			buffindex = GetPlayerBuff(index-1,"HELPFUL")
			sAScanner:SetPlayerBuff(buffindex)
		else
			buffindex = GetPlayerBuff(index-1,"HARMFUL")
			sAScanner:SetPlayerBuff(buffindex)
		end
		
		icon = GetPlayerBuffTexture(buffindex)
		duration = GetPlayerBuffTimeLeft(buffindex)
		stacks = GetPlayerBuffApplications(buffindex)
	
	else

		if auraType == "Buff" then
			sAScanner:SetUnitBuff(unit, index)
			icon = UnitBuff(unit, index)
		else
			sAScanner:SetUnitDebuff(unit, index)
			icon = UnitDebuff(unit, index)
		end
		
		duration = 0 -- temp
		
	end

	name = sAScannerTextLeft1:GetText()
	
	return name, icon, math.floor(duration+1-(1/simpleAuras.refresh)), stacks -- Round Duration for proper display, needs review/testing
	
end

-- Update Auras
function sA:UpdateAuras()

	-- Hide Dual TestAura if GUI isn't shown
	if not gui.editor or not gui.editor:IsVisible() then
		sA.TestAura:Hide()
		sA.TestAuraDual:Hide()
		if gui.editor then
			gui.editor:Hide()
		end
		gui.editor = nil
	end

	-- Cycle through Auras
	for id, aura in ipairs(simpleAuras.auras) do
	
		local currentDuration = nil
		local currentStacks = nil
		local i = 1
		local show = 0

		-- Skip this part if <unnamed>
		if aura.name ~= "" then
			while true do
			
				local name, icon, duration, stacks = sA:GetAuraInfo(aura.unit, i, aura.type)
				if not name then break end
				if name == aura.name then
					show = 1
					currentDuration = duration
					currentStacks = stacks
					-- Update aura icon if autodetect is active
					if aura.autodetect == 1 then
						aura.texture = icon
						simpleAuras.auras[id].texture = aura.texture
					end
					
				end
				
				i = i + 1
				
			end

			-- Switch 1 <-> if invert is active
			if aura.invert == 1 then
				show = 1 - show
			end
		end

		-- Get Frames
		local frame = sA.frames[id]
		local dualframe = sA.dualframes[id]
		
		-- Show if Conditions met or main GUI is shown - but not if AuraEditor is open
		if (show == 1 or (gui and gui:IsVisible())) and (not gui.editor or not gui.editor:IsVisible()) then

			-- Create AuraFrame if not already existing
			if not sA.frames[id] then
			  frame = CreateFrame("Frame", "sAAura"..id, UIParent)
			  frame:SetFrameStrata("BACKGROUND")
			  frame.durationtext = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			  frame.durationtext:SetPoint("CENTER", frame, "CENTER", 0, 0)
			  frame.stackstext = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
			  frame.stackstext:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
			  frame.stackstext:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
			  sA.frames[id] = frame
			else
			  frame = sA.frames[id]
			end

			-- Ensure texture exists
			if not frame.texture then
			  frame.texture = frame:CreateTexture(nil, "BACKGROUND")
			  frame.texture:SetAllPoints(frame)
			end
			
			if aura.lowduration == 1 and currentDuration and currentDuration <= aura.lowdurationvalue then
				auracolor = aura.lowdurationcolor or {1, 0, 0, 1}
			else
				auracolor = aura.auracolor or {1, 1, 1, 1}
			end


			-- Update Aura Display and Show
			frame:SetPoint("CENTER", UIParent, "CENTER", aura.xpos or 0, aura.ypos or 0)
			frame:SetFrameLevel((128 - id)) -- Set z-index according to ID Order
			frame:SetWidth(aura.size or 32)
			frame:SetHeight(aura.size or 32)
			frame.texture:SetTexture(aura.texture)
			frame.texture:SetVertexColor(unpack(auracolor))
			
			if aura.duration and aura.duration == 1 and aura.unit == "Player" then
				-- Duration Text
				frame.durationtext:SetText(currentDuration)
			else
				frame.durationtext:SetText("")
			end
			
			if aura.stacks and aura.stacks == 1 then
				-- Duration Text
				frame.stackstext:SetText(currentStacks)
			else
				frame.stackstext:SetText("")
			end
			
			frame:Show()

			-- if DualDisplay is active
			if aura.dual == 1 then

				-- Create DualFrame if not already existing
				if not sA.dualframes[id] then
					dualframe = CreateFrame("Frame", "sAAura"..id, UIParent)
					dualframe:SetFrameStrata("BACKGROUND")
					dualframe.texture = dualframe:CreateTexture(nil, "BACKGROUND")
					dualframe.texture:SetAllPoints(dualframe)
				    dualframe.durationtext = dualframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				    dualframe.durationtext:SetPoint("CENTER", dualframe, "CENTER", 0, 0)
				    dualframe.stackstext = dualframe:CreateFontString(nil, "OVERLAY", "GameFontWhite")
				    dualframe.stackstext:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
				    dualframe.stackstext:SetPoint("BOTTOMRIGHT", dualframe, "BOTTOMRIGHT", -2, 2)
					dualframe:Hide()
					sA.dualframes[id] = dualframe
				end

				-- Update DualAura Display and Show: Mirror the Standard Aura horizontally
				dualframe:SetPoint("CENTER", UIParent, "CENTER", (-1*aura.xpos) or 0, aura.ypos or 0)
				dualframe:SetFrameLevel((128 - id)) -- Set z-index according to ID Order
				dualframe:SetWidth(aura.size or 32)
				dualframe:SetHeight(aura.size or 32)
				dualframe.texture:SetTexture(aura.texture)
				dualframe.texture:SetTexCoord(1, 0, 0, 1) -- Mirror Aura horizontally
				dualframe.texture:SetVertexColor(unpack(auracolor))
			
				if aura.duration and aura.duration == 1 and aura.unit == "Player" then
					-- Duration Text
					dualframe.durationtext:SetText(currentDuration)
				else
					dualframe.durationtext:SetText("")
				end
				
				if aura.stacks and aura.stacks == 1 then
					-- Duration Text
					dualframe.stackstext:SetText(currentStacks)
				else
					dualframe.stackstext:SetText("")
				end
				
				dualframe:Show()
			end
			
		else

			-- Hide Frames if neither Conditions are met nor main GUI is open - or when Editor is opened
			if frame then
				frame:Hide()
			end
			if aura.dual and dualframe then
				dualframe:Hide()
			end
			
		end
		
	end
end

-- Events Setup
sAEvent = CreateFrame("Frame", "sAEvent", sAParent)

-- Timebased Update of Aura Displays every (1-refresh)secs
sAEvent:SetScript("OnUpdate", function()
	local time = GetTime()
	local refreshRate = simpleAuras.refresh
	refreshRate = 1/refreshRate
	if (time - (sAEvent.lastUpdate or 0)) < refreshRate then return end
	sAEvent.lastUpdate = time
	sA:UpdateAuras()
end)
