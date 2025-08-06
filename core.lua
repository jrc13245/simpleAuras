simpleAuras = simpleAuras or {}
sA = {}
sA.frames = sA.frames or {}
sA.dualframes = sA.dualframes or {}

simpleAuras.refresh = simpleAuras.refresh or 5
simpleAuras.auras = simpleAuras.auras or {}

-- Utility: Skin any frame with flat background and 1px black border
function sA:SkinFrame(frame, bg, border)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(unpack(bg or {0.1, 0.1, 0.1, 0.95}))
	frame:SetBackdropBorderColor(unpack(border or {0, 0, 0, 1}))
end

-- Setup gui frame-- Create main GUI frame
gui = CreateFrame("Frame", "sAGUI", UIParent)
local title = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", gui, "TOP", 0, -5)
title:SetText("simpleAuras")
gui:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
gui:SetWidth(300)
gui:SetHeight(400)
gui:SetMovable(true)
gui:EnableMouse(true)
gui:RegisterForDrag("LeftButton")
gui:SetScript("OnDragStart", function() gui:StartMoving() end)
gui:SetScript("OnDragStop", function() gui:StopMovingOrSizing() end)
sA:SkinFrame(gui)
gui:Hide()

function sA:Init()
	
	for id, aura in ipairs(simpleAuras.auras) do
		local frame = CreateFrame("Frame", "sAAura"..id, UIParent)
		frame:SetFrameStrata("BACKGROUND")
		frame:SetFrameLevel(128 - id)
		frame.texture = frame:CreateTexture(nil, "BACKGROUND")
		frame.texture:SetAllPoints(frame)
		frame:Hide()
		sA.frames[id] = frame
	end
  
  sA:UpdateAuras()
  
end

local TestAura = CreateFrame("Frame", "sATest", UIParent)
TestAura:SetFrameStrata("BACKGROUND")
TestAura:SetFrameLevel(128)
TestAura.texture = TestAura:CreateTexture(nil, "BACKGROUND")
TestAura.texture:SetAllPoints(TestAura)
TestAura:SetFrameLevel(128)
TestAura:Hide()
sA.TestAura = TestAura

local TestAuraDual = CreateFrame("Frame", "sATest", UIParent)
TestAuraDual:SetFrameStrata("BACKGROUND")
TestAuraDual:SetFrameLevel(128)
TestAuraDual.texture = TestAuraDual:CreateTexture(nil, "BACKGROUND")
TestAuraDual.texture:SetAllPoints(TestAuraDual)
TestAuraDual:SetFrameLevel(128)
TestAuraDual:Hide()
sA.TestAuraDual = TestAuraDual

table.insert(UISpecialFrames, "sATest")

function sA:GetAuraInfo(unit, index, auraType)

	local name, texture, duration, stacks, buffindex
	
	if not sAScanner then
		sAScanner = CreateFrame("GameTooltip", "sAScanner", UIParent, "GameTooltipTemplate")
		sAScanner:SetOwner(UIParent, "ANCHOR_NONE")
	end
	
	sAScanner:ClearLines()
	
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
		
	end

	name = sAScannerTextLeft1:GetText()
	
	return name, icon, math.floor(duration+1-(1/simpleAuras.refresh)), stacks
	
end

function sA:UpdateAuras()
	if not gui:IsShown() then
		TestAuraDual:Hide()
	end
	for id, aura in ipairs(simpleAuras.auras) do
	
		local i = 1
		local show = 0
		
		if aura.name == "" then return end
		while true do
		
			local name, icon, duration, stacks = sA:GetAuraInfo(aura.unit, i, aura.type)
			if not name then break end
			if name == aura.name then
				show = 1
				if aura.autodetect == 1 then
					aura.texture = icon
				end
			end
			i = i + 1
		end
		
		if show then
			local frame = sA.frames[id]
			local dualframe = sA.dualframes[id]
			
			if aura.invert == 1 then
				show = 1 - show
			end
			
			if (show == 1 or gui:IsShown()) and (not gui.editor or not gui.editor:IsShown()) then
				frame:SetPoint("CENTER", UIParent, "CENTER", aura.xpos or 0, aura.ypos or 0)
				frame:SetFrameLevel((128 - id))
				frame:SetWidth(aura.size or 32)
				frame:SetHeight(aura.size or 32)
				frame.texture:SetTexture(aura.texture)
				simpleAuras.auras[id].texture = aura.texture
				frame.texture:SetVertexColor(unpack(aura.color or {1, 1, 1}))
				frame:Show()
				
				if aura.dual == 1 then
					if not sA.dualframes[id] then
						dualframe = CreateFrame("Frame", "sAAura"..id, UIParent)
						dualframe:SetFrameStrata("BACKGROUND")
						dualframe:SetFrameLevel(128 - id)
						dualframe.texture = dualframe:CreateTexture(nil, "BACKGROUND")
						dualframe.texture:SetAllPoints(dualframe)
						dualframe:Hide()
						sA.dualframes[id] = dualframe
					end
					dualframe:SetPoint("CENTER", UIParent, "CENTER", (-1*aura.xpos) or 0, aura.ypos or 0)
					dualframe:SetFrameLevel((128 - id))
					dualframe:SetWidth(aura.size or 32)
					dualframe:SetHeight(aura.size or 32)
					dualframe.texture:SetTexture(aura.texture)
					dualframe.texture:SetTexCoord(1, 0, 0, 1)
					simpleAuras.auras[id].texture = aura.texture
					dualframe.texture:SetVertexColor(unpack(aura.color or {1, 1, 1}))
					dualframe:Show()
				end
				
			else
				frame:Hide()
				if aura.dual and dualframe then
					dualframe:Hide()
				end
			end
		end
		
	end
end

sAEvent = CreateFrame("Frame", "sAEvent", UIParent)
sAEvent:RegisterEvent("PLAYER_ENTERING_WORLD")
sAEvent:SetScript("OnEvent", function() sA:Init() end)
sAEvent:SetScript("OnUpdate", function()
	local time = GetTime()
	local refreshRate = simpleAuras.refresh
	refreshRate = 1/refreshRate
	if (time - (sAEvent.lastUpdate or 0)) < refreshRate then return end
	sAEvent.lastUpdate = time
	sA:UpdateAuras()
end)

sAScanner = CreateFrame("GameTooltip", "sAScanner", UIParent, "GameTooltipTemplate")
sAScanner:SetOwner(UIParent, "ANCHOR_NONE")