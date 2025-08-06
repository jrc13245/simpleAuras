-- MAIN FUNCTIONS

-- Aura List Refresh
local function RefreshAuraList()

	-- Hide Previous Items and wipe AuraList
	for _, prevAuraList in ipairs(gui.list or {}) do prevAuraList:Hide() end
	gui.list = {}

	-- Cycle through all Auras
	for i, aura in ipairs(simpleAuras.auras) do

		local id = i

		-- Create List Item
		local ListItem = CreateFrame("Button", nil, gui)
		ListItem:SetWidth(260)
		ListItem:SetHeight(20)
		ListItem:SetPoint("TOPLEFT", 20, -30 - (id - 1) * 22)
		sA:SkinFrame(ListItem, {0.2, 0.2, 0.2, 1})
		ListItem:SetScript("OnEnter", function() ListItem:SetBackdropColor(0.5, 0.5, 0.5, 1) end)
		ListItem:SetScript("OnLeave", function() ListItem:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

		-- Create Item Text
		ListItem.text = ListItem:CreateFontString(nil, "ARTWORK", "GameFontWhite")
		ListItem.text:SetPoint("LEFT", ListItem, "LEFT", 5, 0)
		ListItem.text:SetText("["..id.."] "..(aura.name ~= "" and aura.name or "<unnamed>"))
		ListItem.text:SetTextColor(unpack(aura.color or {1, 1, 1}))
		ListItem:SetScript("OnClick", function()
			-- Close Testauras and Editor Window if already open
			if gui.editor then
				sA.TestAura:Hide()
				sA.TestAuraDual:Hide()
				gui.editor:Hide()
				gui.editor = nil
			end
			-- Open Edit Window for Aura
			sA:EditAura(id)
		end)
	
		-- Up Button
		if id > 1 then
			local up = CreateFrame("Button", nil, ListItem)
			up:SetWidth(15)
			up:SetHeight(15)
			up:SetPoint("RIGHT", ListItem, "RIGHT", -19, 0)
			sA:SkinFrame(up, {0.15, 0.15, 0.15, 1})
			up.text = up:CreateFontString(nil, "OVERLAY", "GameFontWhite")
			up.text:SetFont("Fonts\\FRIZQT__.TTF", 24)
			up.text:SetPoint("CENTER", up, "CENTER", -1, -8)
			up.text:SetText("ˆ")
			up:SetFontString(up.text)
			up:SetScript("OnClick", function()
				simpleAuras.auras[id], simpleAuras.auras[id-1] = simpleAuras.auras[id-1], simpleAuras.auras[id]
				RefreshAuraList()
			end)
		end

		-- Down Button
		if id < table.getn(simpleAuras.auras) then
			local down = CreateFrame("Button", nil, ListItem)
			down:SetWidth(15)
			down:SetHeight(15)
			down:SetPoint("RIGHT", ListItem, "RIGHT", -2, 0)
			sA:SkinFrame(down, {0.15, 0.15, 0.15, 1})
			down.text = down:CreateFontString(nil, "OVERLAY", "GameFontWhite")
			down.text:SetFont("Fonts\\FRIZQT__.TTF", 24)
			down.text:SetPoint("CENTER", down, "CENTER", -1, -8)
			down.text:SetText("ˇ")
			down:SetFontString(down.text)
			down:SetScript("OnClick", function()
				simpleAuras.auras[id], simpleAuras.auras[id+1] = simpleAuras.auras[id+1], simpleAuras.auras[id]
				RefreshAuraList()
			end)
		end

		-- Add to AuraList
		gui.list[id] = ListItem
		
	end
	
end



-- EDITOR FUNCTIONS

-- Save Aura
local function SaveAura(id)
	
	-- Save Values
	simpleAuras.auras[id].name = gui.editor.name:GetText()
	simpleAuras.auras[id].unit = gui.editor.unitButton.text:GetText()
	simpleAuras.auras[id].type = gui.editor.typeButton.text:GetText()
	simpleAuras.auras[id].color = gui.editor.color
	simpleAuras.auras[id].autodetect = gui.editor.autoDetect.value
	simpleAuras.auras[id].texture = gui.editor.texturePath:GetText()
	simpleAuras.auras[id].size = gui.editor.size:GetText()
	simpleAuras.auras[id].xpos = gui.editor.x:GetText()
	simpleAuras.auras[id].ypos = gui.editor.y:GetText()
	simpleAuras.auras[id].invert = gui.editor.invert.value
	simpleAuras.auras[id].dual = gui.editor.dual.value

	-- Clear Focus
	gui.editor.name:ClearFocus()
	gui.editor.texturePath:ClearFocus()
	gui.editor.size:ClearFocus()
	gui.editor.x:ClearFocus()
	gui.editor.y:ClearFocus()

	-- Hide TestAuras
	sA.TestAura:Hide()
	sA.TestAuraDual:Hide()

	-- Hide and wipe Editor Window
	gui.editor:Hide()
	gui.editor = nil

	-- Refresh AuraList and show Editor Window for Aura
	RefreshAuraList()
	sA:EditAura(id)
	return
	
end



-- GENERAL FUNCTIONS

-- Copy independently
local function independentCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = independentCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

-- AddAura and Copy
local function AddAura(id)

	-- Add new Aura
	table.insert(simpleAuras.auras, {})
	-- Get the new ID and set Default Values for Name and Texture
	local newid = table.getn(simpleAuras.auras)
	simpleAuras.auras[newid].name = ""
	simpleAuras.auras[newid].texture = "Interface\\Icons\\INV_Misc_QuestionMark"

	-- Insert existing Aura into new Aura if an ID is provided
	if id then
		simpleAuras.auras[newid] = independentCopy(simpleAuras.auras[id])
	end
	
	-- Hide and wipe Editor Frame, also hide Testauras
	if gui.editor and gui.editor:IsShown() then
		gui.editor:Hide()
		gui.editor = nil
		sA.TestAura:Hide()
		sA.TestAuraDual:Hide()
	end
	
	-- Rerun Init to generate new Frames
	sA:UpdateAuras()

	-- Refresh AuraList and show new Aura
	RefreshAuraList()
	sA:EditAura(newid)
	
	return
	
end



-- MAIN WINDOW

-- Create main GUI frame
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
table.insert(UISpecialFrames, "sAGUI") -- Add GUI to SpecialFrames (ESC to close)

-- Add Button
local add = CreateFrame("Button", nil, gui)
add:SetPoint("TOPLEFT", 2, -2)
add:SetWidth(20)
add:SetHeight(20)
sA:SkinFrame(add, {0.2, 0.2, 0.2, 1})
add.text = add:CreateFontString(nil, "OVERLAY", "GameFontNormal")
add.text:SetPoint("CENTER", add, "CENTER", 0, 0)
add.text:SetText("+")
add:SetFontString(add.text)
add:SetScript("OnClick", function() AddAura() end)
add:SetScript("OnEnter", function() add:SetBackdropColor(0.1, 0.4, 0.1, 1) end)
add:SetScript("OnLeave", function() add:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

-- Close Button
local close = CreateFrame("Button", nil, gui)
close:SetWidth(20)
close:SetHeight(20)
close:SetPoint("TOPRIGHT", gui, "TOPRIGHT", -2, -2)
sA:SkinFrame(close, {0.2, 0.2, 0.2, 1})
close.text = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
close.text:SetPoint("CENTER", close, "CENTER", 0.5, 1)
close.text:SetText("x")
close:SetFontString(close.text)
close:SetScript("OnClick", function()
	gui:Hide()
	sA.TestAura:Hide()
	sA.TestAuraDual:Hide()
end)
close:SetScript("OnEnter", function() close:SetBackdropColor(0.4, 0.1, 0.1, 1) end)
close:SetScript("OnLeave", function() close:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

-- Create Testframe (used in editor)
local TestAura = CreateFrame("Frame", "sATest", UIParent)
TestAura:SetFrameStrata("BACKGROUND")
TestAura:SetFrameLevel(128)
TestAura.texture = TestAura:CreateTexture(nil, "BACKGROUND")
TestAura.texture:SetAllPoints(TestAura)
TestAura:Hide()
sA.TestAura = TestAura

-- Create Testframe for dual display (used in editor)
local TestAuraDual = CreateFrame("Frame", "sATestDual", UIParent)
TestAuraDual:SetFrameStrata("BACKGROUND")
TestAuraDual:SetFrameLevel(128)
TestAuraDual.texture = TestAuraDual:CreateTexture(nil, "BACKGROUND")
TestAuraDual.texture:SetAllPoints(TestAuraDual)
TestAuraDual:Hide()
sA.TestAuraDual = TestAuraDual

-- Add TestFrames to SpecialFrames
table.insert(UISpecialFrames, "sATest")
table.insert(UISpecialFrames, "sATestDual")

-- Build AuraList
RefreshAuraList()



-- EDITOR WINDOW

-- Build Editor Window
function sA:EditAura(id)
	local aura = simpleAuras.auras[id]
	if not aura then return end
	
	local ed = gui.editor
	if not ed then
		
		-- Show Testaura(s)
		sA.TestAura:SetPoint("CENTER", UIParent, "CENTER", aura.xpos or 0, aura.ypos or 0)
		sA.TestAura:SetWidth(aura.size or 32)
		sA.TestAura:SetHeight(aura.size or 32)
		sA.TestAura.texture:SetTexture(aura.texture)
		sA.TestAura.texture:SetVertexColor(unpack(aura.color or {1, 1, 1, 1}))
		sA.TestAura:Show()
		
		if aura.dual == 1 then
			sA.TestAuraDual:SetPoint("CENTER", UIParent, "CENTER", (-1*aura.xpos) or 0, aura.ypos or 0)
			sA.TestAuraDual:SetWidth(aura.size or 32)
			sA.TestAuraDual:SetHeight(aura.size or 32)
			sA.TestAuraDual.texture:SetTexture(aura.texture)
			sA.TestAuraDual.texture:SetTexCoord(1, 0, 0, 1)
			sA.TestAuraDual.texture:SetVertexColor(unpack(aura.color or {1, 1, 1, 1}))
			sA.TestAuraDual:Show()
		end
	
		ed = CreateFrame("Frame", "sAEdit", gui)
		ed:SetWidth(300)
		ed:SetHeight(400)
		ed:SetPoint("LEFT", gui, "RIGHT", 10, 0)
		sA:SkinFrame(ed)

		ed:SetMovable(true)
		ed:EnableMouse(true)
		ed:RegisterForDrag("LeftButton")
		ed:SetScript("OnDragStart", function() ed:StartMoving() end)
		ed:SetScript("OnDragStop", function() ed:StopMovingOrSizing() end)
		table.insert(UISpecialFrames, "sAEdit")

		-- Title
		ed.title = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.title:SetPoint("TOP", ed, "TOP", 0, -5)
		ed.title:SetText("[" .. tostring(id) .. "] " .. (aura.name ~= "" and aura.name or "<unnamed>"))

		-- Aura Name Label
		ed.nameLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.nameLabel:SetPoint("TOPLEFT", ed, "TOPLEFT", 12.5, -40)
		ed.nameLabel:SetText("Aura Name:")

		-- Aura Name Input
		ed.name = CreateFrame("EditBox", nil, ed)
		ed.name:SetPoint("LEFT", ed.nameLabel, "RIGHT", 5, 0)
		ed.name:SetWidth(198)
		ed.name:SetHeight(20)
		ed.name:SetMultiLine(false)
		ed.name:SetAutoFocus(false)
		ed.name:SetFontObject(GameFontHighlightSmall)
		ed.name:SetTextColor(1, 1, 1)
		ed.name:SetMaxLetters(100)
		ed.name:SetJustifyH("LEFT")
		ed.name:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
		ed.name:SetBackdropColor(0.1, 0.1, 0.1, 1)
		ed.name:SetBackdropBorderColor(0, 0, 0, 1)
		ed.name:SetText(aura.name or "")
		
		-- Separator
		local lineone = ed:CreateTexture(nil, "ARTWORK")
		lineone:SetTexture("Interface\\Buttons\\WHITE8x8")
		lineone:SetVertexColor(1, 0.8, 0.06, 1)
		lineone:SetPoint("TOPLEFT", ed.nameLabel, "BOTTOMLEFT", 0, -15)
		lineone:SetWidth(275)
		lineone:SetHeight(1)
		
		-- Texture Row
		ed.texLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.texLabel:SetPoint("TOPLEFT", lineone, "BOTTOMLEFT", 0, -15)
		ed.texLabel:SetText("Icon/Texture:")



		-- Color Picker with Alpha (from pfUI)
		ed.colorpicker = CreateFrame("Button", nil, ed)
		ed.colorpicker:SetWidth(24)
		ed.colorpicker:SetHeight(12)
		ed.colorpicker:SetPoint("LEFT", ed.texLabel, "RIGHT", 5, 0)
		sA:SkinFrame(ed.colorpicker, {1, 1, 1, 1}) -- Use your existing skin function

		-- Display current color
		ed.colorpicker.prev = ed.colorpicker:CreateTexture(nil, "OVERLAY")
		ed.colorpicker.prev:SetAllPoints(ed.colorpicker)

		local cr, cg, cb, ca = unpack(simpleAuras.auras[id].color or {1, 1, 1, 1})
		ed.colorpicker.prev:SetTexture(cr, cg, cb, ca)
		ed.color = simpleAuras.auras[id].color

		ed.colorpicker:SetScript("OnClick", function()
		  local preview = this.prev
		  local r0, g0, b0, a0 = unpack(simpleAuras.auras[id].color or {1, 1, 1, 1})

		  -- Apply selected color
		  function ColorPickerFrame.func()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			local a = 1 - OpacitySliderFrame:GetValue()

			r = math.floor(r * 100 + 0.5) / 100
			g = math.floor(g * 100 + 0.5) / 100
			b = math.floor(b * 100 + 0.5) / 100
			a = math.floor(a * 100 + 0.5) / 100
			
			preview:SetTexture(r, g, b, a)

			sA.TestAura.texture:SetVertexColor(r, g, b, a)
			if simpleAuras.auras[id].dual == 1 then
			  sA.TestAuraDual.texture:SetVertexColor(r, g, b, a)
			end
			gui.list[id].text:SetTextColor(r, g, b, a)

            if not this:GetParent():IsShown() then
              simpleAuras.auras[id].color = {r, g, b, a}
              ed.color = {r, g, b, a}
            end
			
		  end

		  -- Revert on cancel
		  function ColorPickerFrame.cancelFunc()
			preview:SetTexture(r0, g0, b0, a0)
			sA.TestAura.texture:SetVertexColor(r0, g0, b0, a0)
			if simpleAuras.auras[id].dual == 1 then
			  sA.TestAuraDual.texture:SetVertexColor(r0, g0, b0, a0)
			end
			gui.list[id].text:SetTextColor(r0, g0, b0, a0)
		  end

		  -- Configure and show the ColorPickerFrame
		  ColorPickerFrame:SetColorRGB(r0, g0, b0)
		  ColorPickerFrame.hasOpacity = true
		  ColorPickerFrame.opacityFunc = ColorPickerFrame.func
		  ColorPickerFrame.opacity = 1 - a0
		  ColorPickerFrame:SetFrameStrata("DIALOG")
		  ShowUIPanel(ColorPickerFrame)
		end)



		-- Autodetect checkbox
		ed.autoDetect = CreateFrame("Button", nil, ed)
		ed.autoDetect:SetWidth(16)
		ed.autoDetect:SetHeight(16)
		ed.autoDetect:SetPoint("LEFT", ed.colorpicker, "RIGHT", 73, 0)
		sA:SkinFrame(ed.autoDetect, {0.15, 0.15, 0.15, 1})

		ed.autoDetect.checked = ed.autoDetect:CreateTexture(nil, "OVERLAY")
		ed.autoDetect.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
		ed.autoDetect.checked:SetVertexColor(1, 0.8, 0.06, 1)
		ed.autoDetect.checked:SetPoint("CENTER", ed.autoDetect, "CENTER", 0, 0)
		ed.autoDetect.checked:SetWidth(7)
		ed.autoDetect.checked:SetHeight(7)
		ed.autoDetect.checked:Hide()

		-- Initial state
		ed.autoDetect.value = aura.autodetect or 0

		if ed.autoDetect.value == 1 then
			ed.autoDetect.checked:Show()
		end

		-- Toggle on click
		ed.autoDetect:SetScript("OnClick", function()
			if ed.autoDetect.value == 1 then
				ed.autoDetect.checked:Hide()
				ed.autoDetect.value = 0
			else
				ed.autoDetect.checked:Show()
				ed.autoDetect.value = 1
			end
			simpleAuras.auras[id].autodetect = ed.autoDetect.value
		end)

		ed.autoLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.autoLabel:SetPoint("LEFT", ed.autoDetect, "RIGHT", 5, 1)
		ed.autoLabel:SetText("Autodetect")

		-- Texture path input
		ed.texturePath = CreateFrame("EditBox", nil, ed)
		ed.texturePath:SetPoint("TOPLEFT", ed.texLabel, "BOTTOMLEFT", 0, -10)
		ed.texturePath:SetWidth(200)
		ed.texturePath:SetHeight(20)
		ed.texturePath:SetMultiLine(false)
		ed.texturePath:SetAutoFocus(false)
		ed.texturePath:SetFontObject(GameFontHighlightSmall)
		ed.texturePath:SetTextColor(1, 1, 1)
		ed.texturePath:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
		ed.texturePath:SetBackdropColor(0.1, 0.1, 0.1, 1)
		ed.texturePath:SetBackdropBorderColor(0, 0, 0, 1)
		ed.texturePath:SetText(aura.texture or "")

		-- Browse button (non-functional)
		ed.browseBtn = CreateFrame("Button", nil, ed)
		ed.browseBtn:SetWidth(60)
		ed.browseBtn:SetHeight(20)
		ed.browseBtn:SetPoint("LEFT", ed.texturePath, "RIGHT", 15, 0)
		sA:SkinFrame(ed.browseBtn, {0.2, 0.2, 0.2, 1})
		ed.browseBtn.text = ed.browseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.browseBtn.text:SetPoint("CENTER", ed.browseBtn, "CENTER", 0, 0)
		ed.browseBtn.text:SetText("Browse")
		ed.browseBtn:SetFontString(ed.browseBtn.text)
		
		
		
		ed.browseBtn:SetScript("OnClick", function()
		  if ed.browseFrame then
			ed.browseFrame:Show()
			return
		  end

		  -- Create the overlay frame
		  local bf = CreateFrame("Frame", nil, ed)
		  bf:SetAllPoints(ed)
		  bf:SetFrameStrata("DIALOG")
		  sA:SkinFrame(bf)
		  ed.browseFrame = bf
		  
		  -- Title
		ed.browsetitle = bf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.browsetitle:SetPoint("TOP", bf, "TOP", 0, -5)
		ed.browsetitle:SetText("Select Texture")

		  -- Close button
		  local close = CreateFrame("Button", nil, bf)
		  close:SetWidth(20)
		  close:SetHeight(20)
		  close:SetPoint("TOPRIGHT", -2, -2)
		  sA:SkinFrame(close, {0.2, 0.2, 0.2, 1})
		  close.text = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		  close.text:SetPoint("CENTER", close, "CENTER", 0.5, 1)
		  close.text:SetText("x")
		  close:SetFontString(close.text)
		  close:SetScript("OnClick", function()
			bf:Hide()
		  end)

		  -- ScrollFrame setup
			local scroll = CreateFrame("ScrollFrame", nil, bf)
			scroll:SetPoint("TOPLEFT", 10, -30)
			scroll:SetPoint("BOTTOMRIGHT", -10, 40)

			local content = CreateFrame("Frame", nil, scroll)
			content:SetWidth(250)
			content:SetHeight(1000)
			scroll:SetScrollChild(content)

			-- Add mouse wheel support using a frame overlay
			local wheel = CreateFrame("Frame", nil, scroll)
			wheel:SetAllPoints(scroll)
			wheel:EnableMouseWheel(true)
			wheel:SetScript("OnMouseWheel", function()
			local dir = arg1 or 0
			  local step = 30
			  local current = scroll:GetVerticalScroll() or 0
			  local max = (content:GetHeight() or 0) - (scroll:GetHeight() or 1)
			  local target = math.max(0, math.min(current - dir * step, max))
			  scroll:SetVerticalScroll(target)
			end)


		  -- Create grid of texture buttons
		  local numPerRow = 6
		  local size = 36
		  local padding = 4
		  local total = 246
		  local rows = math.ceil(total / numPerRow)
		  local selectedTexture

		  content:SetHeight(rows * (size + padding))

		  for i = 1, total do
			local btn = CreateFrame("Button", nil, content)
			local row = math.floor((i - 1) / numPerRow)
			local col = math.mod(i - 1, numPerRow)
			btn:SetWidth(size)
			btn:SetHeight(size)
			btn:SetPoint("TOPLEFT", col * (size + padding) + 22, -row * (size + padding))

			local tex = btn:CreateTexture(nil, "BACKGROUND")
			tex:SetAllPoints(btn)
			tex:SetTexture("Interface\\AddOns\\simpleAuras\\Auras\\Aura" .. i)

			btn.texturePath = "Interface\\AddOns\\simpleAuras\\Auras\\Aura" .. i

			btn:SetScript("OnClick", function()
			  selectedTexture = btn.texturePath
			  -- Highlight selected
			  for _, child in ipairs({content:GetChildren()}) do
				child:SetBackdropColor(0.2, 0.2, 0.2, 1)
			  end
			  sA:SkinFrame(btn, {0.5, 0.5, 0.5, 1})
			end)

			sA:SkinFrame(btn, {0.2, 0.2, 0.2, 1})
		  end
		  
		  
		  
-- Custom styled scrollbar
local scrollbar = CreateFrame("Slider", nil, bf)
scrollbar:SetOrientation("VERTICAL")
scrollbar:SetWidth(10)
scrollbar:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 4, 0)
scrollbar:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 4, 0)
sA:SkinFrame(scrollbar, {0.2, 0.2, 0.2, 1})

-- Scroll thumb (the draggable knob)
local thumb = scrollbar:CreateTexture(nil, "OVERLAY")
thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
thumb:SetVertexColor(1, 0.8, 0.1, 1)
thumb:SetWidth(6)
thumb:SetHeight(30)
scrollbar:SetThumbTexture(thumb)

scrollbar:SetMinMaxValues(0, 1)
scrollbar:SetValueStep(1)
scrollbar:SetValue(0)

-- Sync slider to scroll frame
scrollbar:SetScript("OnValueChanged", function()
  scroll:SetVerticalScroll(scrollbar:GetValue())
end)

scroll:SetScript("OnVerticalScroll", function()
  scrollbar:SetValue(scroll:GetVerticalScroll())
end)


-- Update scroll position when scrollbar moves
scrollbar:SetScript("OnValueChanged", function()
  scroll:SetVerticalScroll(scrollbar:GetValue())
end)

-- Link scrollframe to scrollbar
scroll:SetScript("OnVerticalScroll", function()
  scrollbar:SetValue(scroll:GetVerticalScroll())
end)
-- Update scrollbar range
local contentHeight = content:GetHeight()
local visibleHeight = scroll:GetHeight()
local maxScroll = math.max(0, contentHeight - visibleHeight - 332)
scrollbar:SetMinMaxValues(0, maxScroll)
scrollbar:SetValue(0)



		  -- Select button
		  local select = CreateFrame("Button", nil, bf)
		  select:SetWidth(80)
		  select:SetHeight(20)
		  select:SetPoint("BOTTOM", 0, 10)
		  sA:SkinFrame(select, {0.2, 0.2, 0.2, 1})
		  select.text = select:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		  select.text:SetPoint("CENTER", select, "CENTER", 0, 0)
		  select.text:SetText("Select")
		  select:SetFontString(select.text)

		  select:SetScript("OnClick", function()
			if selectedTexture then
			  ed.texturePath:SetText(selectedTexture)
			  ed.browseFrame:Hide()
			  SaveAura(id)
			end
		  end)
		end)
		
		

		-- Size Label
		ed.sizeLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.sizeLabel:SetPoint("TOPLEFT", ed.texturePath, "TOPLEFT", 0, -30)
		ed.sizeLabel:SetText("Size:")

		-- Size Input
		ed.size = CreateFrame("EditBox", nil, ed)
		ed.size:SetPoint("LEFT", ed.sizeLabel, "RIGHT", 5, 0)
		ed.size:SetWidth(30)
		ed.size:SetHeight(20)
		ed.size:SetMultiLine(false)
		ed.size:SetAutoFocus(false)
		ed.size:SetFontObject(GameFontHighlightSmall)
		ed.size:SetTextColor(1, 1, 1)
		ed.size:SetMaxLetters(4)
		ed.size:SetJustifyH("CENTER")
		ed.size:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
		ed.size:SetBackdropColor(0.1, 0.1, 0.1, 1)
		ed.size:SetBackdropBorderColor(0, 0, 0, 1)
		ed.size:SetText(aura.size or 32)

		-- x Label
		ed.xLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.xLabel:SetPoint("LEFT", ed.size, "RIGHT", 35, 0)
		ed.xLabel:SetText("x pos:")

		-- x Input
		ed.x = CreateFrame("EditBox", nil, ed)
		ed.x:SetPoint("LEFT", ed.xLabel, "RIGHT", 5, 0)
		ed.x:SetWidth(30)
		ed.x:SetHeight(20)
		ed.x:SetMultiLine(false)
		ed.x:SetAutoFocus(false)
		ed.x:SetFontObject(GameFontHighlightSmall)
		ed.x:SetTextColor(1, 1, 1)
		ed.x:SetMaxLetters(4)
		ed.x:SetJustifyH("CENTER")
		ed.x:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
		ed.x:SetBackdropColor(0.1, 0.1, 0.1, 1)
		ed.x:SetBackdropBorderColor(0, 0, 0, 1)
		ed.x:SetText(aura.xpos or 0)

		-- y Label
		ed.yLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.yLabel:SetPoint("LEFT", ed.x, "RIGHT", 30, 0)
		ed.yLabel:SetText("y pos:")
		   
		-- y Input
		ed.y = CreateFrame("EditBox", nil, ed)
		ed.y:SetPoint("LEFT", ed.yLabel, "RIGHT", 5, 0)
		ed.y:SetWidth(30)
		ed.y:SetHeight(20)
		ed.y:SetMultiLine(false)
		ed.y:SetAutoFocus(false)
		ed.y:SetFontObject(GameFontHighlightSmall)
		ed.y:SetTextColor(1, 1, 1)
		ed.y:SetMaxLetters(4)
		ed.y:SetJustifyH("CENTER")
		ed.y:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
		ed.y:SetBackdropColor(0.1, 0.1, 0.1, 1)
		ed.y:SetBackdropBorderColor(0, 0, 0, 1)
		ed.y:SetText(aura.ypos or 0)
		
		-- Separator
		local linetwo = ed:CreateTexture(nil, "ARTWORK")
		linetwo:SetTexture("Interface\\Buttons\\WHITE8x8")
		linetwo:SetVertexColor(1, 0.8, 0.06, 1)
		linetwo:SetPoint("TOPLEFT", ed.sizeLabel, "BOTTOMLEFT", 0, -15)
		linetwo:SetWidth(275)
		linetwo:SetHeight(1)

		-- Conditions Label
		ed.conditionsLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.conditionsLabel:SetPoint("TOP", linetwo, "BOTTOM", 0, -15)
		ed.conditionsLabel:SetJustifyH("CENTER")
		ed.conditionsLabel:SetText("Conditions")
		
		-- Unit Dropdown
		ed.unitLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.unitLabel:SetPoint("TOPLEFT", linetwo, "BOTTOMLEFT", 0, -45)
		ed.unitLabel:SetText("Unit:")
		ed.unitButton = CreateFrame("Button", nil, ed)
		ed.unitButton:SetWidth(80)
		ed.unitButton:SetHeight(20)
		ed.unitButton:SetPoint("LEFT", ed.unitLabel, "RIGHT", 5, 0)
		sA:SkinFrame(ed.unitButton, {0.2, 0.2, 0.2, 1})
		ed.unitButton.text = ed.unitButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.unitButton.text:SetPoint("CENTER", ed.unitButton, "CENTER", 0, 0)
		ed.unitButton.text:SetText(aura.unit or "Player")

		ed.unitButton:SetScript("OnClick", function()
			if not ed.unitButton.menu then
			local menu = CreateFrame("Frame", nil, ed)
			menu:SetPoint("TOPLEFT", ed.unitButton, "BOTTOMLEFT", 0, -2)
			menu:SetFrameStrata("DIALOG")
			menu:SetFrameLevel(10)
			menu:SetWidth(80)
			menu:SetHeight(40)
			sA:SkinFrame(menu, {0.15, 0.15, 0.15, 1})
			menu:Hide()
			ed.unitButton.menu = menu
			local function makeChoice(text, index)
				local b = CreateFrame("Button", nil, menu)
				b:SetWidth(80)
				b:SetHeight(20)
				b:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -((index - 1) * 20))
				sA:SkinFrame(b, {0.2, 0.2, 0.2, 1})
				b.text = b:CreateFontString(nil, "OVERLAY", "GameFontWhite")
				b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
				b.text:SetText(text)

				b:SetScript("OnClick", function()
				ed.unitButton.text:SetText(text)
				aura.unit = text
				menu:Hide()
				end)
			end
			makeChoice("Player", 1)
			makeChoice("Target", 2)
			end
			local menu = ed.unitButton.menu
			if menu:IsVisible() then
			menu:Hide()
			else
			menu:Show()
			end
		end)
		
		-- Type Dropdown
		ed.typeLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.typeLabel:SetPoint("LEFT", ed.unitButton, "RIGHT", 42, 0)
		ed.typeLabel:SetText("Type:")
		ed.typeButton = CreateFrame("Button", nil, ed)
		ed.typeButton:SetWidth(80)
		ed.typeButton:SetHeight(20)
		ed.typeButton:SetPoint("LEFT", ed.typeLabel, "RIGHT", 5, 0)
		sA:SkinFrame(ed.typeButton, {0.2, 0.2, 0.2, 1})
		ed.typeButton.text = ed.typeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.typeButton.text:SetPoint("CENTER", ed.typeButton, "CENTER", 0, 0)
		ed.typeButton.text:SetText(aura.type or "Buff")
		ed.typeButton:SetScript("OnClick", function()
			-- If menu doesn't exist yet, create and store it
			if not ed.typeButton.menu then
				local menu = CreateFrame("Frame", nil, ed)
				menu:SetPoint("TOPLEFT", ed.typeButton, "BOTTOMLEFT", 0, -2)
				menu:SetFrameStrata("DIALOG")
				menu:SetFrameLevel(10)
				menu:SetWidth(80)
				menu:SetHeight(40)
				sA:SkinFrame(menu, {0.15, 0.15, 0.15, 1})
				menu:Hide()
				ed.typeButton.menu = menu
			-- Create choices
			local function makeChoice(text, index)
				local b = CreateFrame("Button", nil, menu)
				b:SetWidth(80)
				b:SetHeight(20)
				b:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -((index - 1) * 20))
				sA:SkinFrame(b, {0.2, 0.2, 0.2, 1})
				b.text = b:CreateFontString(nil, "OVERLAY", "GameFontWhite")
				b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
				b.text:SetText(text)
				b:SetScript("OnClick", function()
					ed.typeButton.text:SetText(text)
					aura.type = text
					menu:Hide()
				end)
			end
				makeChoice("Buff", 1)
				makeChoice("Debuff", 2)
			end
			-- Toggle
			local menu = ed.typeButton.menu
			if menu:IsVisible() then
				menu:Hide()
			else
				menu:Show()
			end
				
		end)

		-- Invert Label
		ed.invertLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.invertLabel:SetPoint("BOTTOMLEFT", ed, "BOTTOMLEFT", 52.5, 30)
		ed.invertLabel:SetText("Invert:")

		-- Invert checkbox
		ed.invert = CreateFrame("Button", nil, ed)
		ed.invert:SetWidth(16)
		ed.invert:SetHeight(16)
		ed.invert:SetPoint("LEFT", ed.invertLabel, "RIGHT", 10, 0)
		sA:SkinFrame(ed.invert, {0.15, 0.15, 0.15, 1})
		ed.invert.checked = ed.invert:CreateTexture(nil, "OVERLAY")
		ed.invert.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
		ed.invert.checked:SetVertexColor(1, 0.8, 0.06, 1)
		ed.invert.checked:SetPoint("CENTER", ed.invert, "CENTER", 0, 0)
		ed.invert.checked:SetWidth(7)
		ed.invert.checked:SetHeight(7)
		ed.invert.checked:Hide()
		ed.invert.value = aura.invert or 0
		if ed.invert.value == 1 then
			ed.invert.checked:Show()
		end
		ed.invert:SetScript("OnClick", function()
			if ed.invert.value == 1 then
				ed.invert.checked:Hide()
				ed.invert.value = 0
			else
				ed.invert.checked:Show()
				ed.invert.value = 1
			end
			simpleAuras.auras[id].invert = ed.invert.value
			SaveAura(id)
		end)

		-- Dual Label
		ed.dualLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.dualLabel:SetPoint("LEFT", ed.invertLabel, "RIGHT", 90, 0)
		ed.dualLabel:SetText("Dual:")

		-- Dual checkbox
		ed.dual = CreateFrame("Button", nil, ed)
		ed.dual:SetWidth(16)
		ed.dual:SetHeight(16)
		ed.dual:SetPoint("LEFT", ed.dualLabel, "RIGHT", 10, 0)
		sA:SkinFrame(ed.dual, {0.15, 0.15, 0.15, 1})
		ed.dual.checked = ed.dual:CreateTexture(nil, "OVERLAY")
		ed.dual.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
		ed.dual.checked:SetVertexColor(1, 0.8, 0.06, 1)
		ed.dual.checked:SetPoint("CENTER", ed.dual, "CENTER", 0, 0)
		ed.dual.checked:SetWidth(7)
		ed.dual.checked:SetHeight(7)
		ed.dual.checked:Hide()
		ed.dual.value = aura.dual or 0
		if ed.dual.value == 1 then
			ed.dual.checked:Show()
		end
		ed.dual:SetScript("OnClick", function()
			if ed.dual.value == 1 then
				ed.dual.checked:Hide()
				ed.dual.value = 0
			else
				ed.dual.checked:Show()
				ed.dual.value = 1
			end
			simpleAuras.auras[id].dual = ed.dual.value
			SaveAura(id)
		end)
		
		---- Separator
		--local linetwo = ed:CreateTexture(nil, "ARTWORK")
		--linetwo:SetTexture("Interface\\Buttons\\WHITE8x8")
		--linetwo:SetVertexColor(0.4, 0.4, 0.4, 1)
		--linetwo:SetPoint("LEFT", ed, "RIGHT", -12, 0)
		--linetwo:SetWidth(1)
		--linetwo:SetHeight(400)
		--
		---- Separator
		--local linethree = ed:CreateTexture(nil, "ARTWORK")
		--linethree:SetTexture("Interface\\Buttons\\WHITE8x8")
		--linethree:SetVertexColor(0.4, 0.4, 0.4, 1)
		--linethree:SetPoint("RIGHT", ed, "LEFT", 12, 0)
		--linethree:SetWidth(1)
		--linethree:SetHeight(400)

		-- Save Button
		ed.save = CreateFrame("Button", nil, ed)
		ed.save:SetPoint("BOTTOMLEFT", 2, 2)
		ed.save:SetWidth(60)
		ed.save:SetHeight(20)
		sA:SkinFrame(ed.save, {0.2, 0.2, 0.2, 1})
		ed.save.text = ed.save:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.save.text:SetPoint("CENTER", ed.save, "CENTER", 0, 0)
		ed.save.text:SetText("Save")
		ed.save:SetFontString(ed.save.text)
		ed.save:SetScript("OnEnter", function() ed.save:SetBackdropColor(0.1, 0.4, 0.1, 1) end)
		ed.save:SetScript("OnLeave", function() ed.save:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

		-- Delete Button
		ed.delete = CreateFrame("Button", nil, ed)
		ed.delete:SetPoint("BOTTOMRIGHT", -2, 2)
		ed.delete:SetWidth(60)
		ed.delete:SetHeight(20)
		sA:SkinFrame(ed.delete, {0.2, 0.2, 0.2, 1})
		ed.delete.text = ed.delete:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.delete.text:SetPoint("CENTER", ed.delete, "CENTER", 0, 0)
		ed.delete.text:SetText("Delete")
		ed.delete:SetFontString(ed.delete.text)
		ed.delete:SetScript("OnEnter", function() ed.delete:SetBackdropColor(0.4, 0.1, 0.1, 1) end)
		ed.delete:SetScript("OnLeave", function() ed.delete:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

		-- Close Button
		ed.close = CreateFrame("Button", nil, ed)
		ed.close:SetPoint("TOPRIGHT", -2, -2)
		ed.close:SetWidth(20)
		ed.close:SetHeight(20)
		sA:SkinFrame(ed.close, {0.2, 0.2, 0.2, 1})
		ed.close.text = ed.close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.close.text:SetPoint("CENTER", ed.close, "CENTER", 0.5, 1)
		ed.close.text:SetText("x")
		ed.close:SetFontString(ed.close.text)
		ed.close:SetScript("OnEnter", function() ed.close:SetBackdropColor(0.4, 0.1, 0.1, 1) end)
		ed.close:SetScript("OnLeave", function() ed.close:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

		-- Copy Button
		ed.copy = CreateFrame("Button", nil, ed)
		ed.copy:SetPoint("TOPLEFT", 2, -2)
		ed.copy:SetWidth(20)
		ed.copy:SetHeight(20)
		sA:SkinFrame(ed.copy, {0.2, 0.2, 0.2, 1})
		ed.copy.text = ed.copy:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.copy.text:SetPoint("CENTER", ed.copy, "CENTER", 0.5, 1)
		ed.copy.text:SetText("c")
		ed.copy:SetFontString(ed.copy.text)
		ed.copy:SetScript("OnEnter", function() ed.copy:SetBackdropColor(0.5, 0.5, 0.5, 1) end)
		ed.copy:SetScript("OnLeave", function() ed.copy:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

		gui.editor = ed
	
	end


	
	-- EDITOR FUNCTIONS
	
	-- COPY
	ed.copy:SetScript("OnClick", function() AddAura(id) end)
	
	-- CLOSE
	ed.close:SetScript("OnClick", function()
		ed:Hide()
		gui.editor = nil
		sA.TestAura:Hide()
		sA.TestAuraDual:Hide()
	end)
	
	-- DELETE
	ed.delete:SetScript("OnClick", function()
		if ed.confirm then ed.confirm:Show() return end
		ed.confirm = CreateFrame("Frame", nil, ed)
		ed.confirm:SetFrameStrata("DIALOG")
		ed.confirm:SetFrameLevel(10)
		ed.confirm:SetPoint("CENTER", ed, "CENTER", 0, 0)
		ed.confirm:SetWidth(250)
		ed.confirm:SetHeight(80)
		sA:SkinFrame(ed.confirm, {0.15, 0.15, 0.15, 1})
	
		local msg = ed.confirm:CreateFontString(nil, "OVERLAY", "GameFontWhite")
		msg:SetPoint("TOP", 0, -20)
		msg:SetText("Delete '["..id.."] "..(aura.name ~= "" and aura.name or "<unnamed>").."'?")
		msg:SetTextColor(1,0,0)
	
		-- Delete? Yes
		local yes = CreateFrame("Button", nil, ed.confirm)
		yes:SetPoint("BOTTOMLEFT", 30, 10)
		yes:SetWidth(60)
		yes:SetHeight(20)
		sA:SkinFrame(yes, {0.2, 0.2, 0.2, 1})
		yes.text = yes:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		yes.text:SetPoint("CENTER", yes, "CENTER", 0, 0)
		yes.text:SetText("Yes")
		yes:SetFontString(yes.text)
		yes:SetScript("OnClick", function()
			if sA.frames[id] then
				sA.frames[id]:Hide()
				table.remove(simpleAuras.auras, id)
				table.remove(sA.frames, table.getn(sA.frames))
			end
			if aura.dual == 1 and sA.dualframes[id] then
				sA.dualframes[id]:Hide()
				table.remove(sA.dualframes, table.getn(sA.dualframes))
			end
			ed.confirm:Hide()
			ed:Hide()
			gui.editor = nil
			sA.TestAura:Hide()
			sA.TestAuraDual:Hide()
			RefreshAuraList()
		end)
	
		-- Delete? No
		local no = CreateFrame("Button", nil, ed.confirm)
		no:SetPoint("BOTTOMRIGHT", -30, 10)
		no:SetWidth(60)
		no:SetHeight(20)
		sA:SkinFrame(no, {0.2, 0.2, 0.2, 1})
		no.text = no:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		no.text:SetPoint("CENTER", no, "CENTER", 0, 0)
		no.text:SetText("No")
		no:SetFontString(no.text)
		no:SetScript("OnClick", function()
			ed.confirm:Hide()
		end)
	end)

	-- SAVE
	ed.name:SetScript("OnEnterPressed", function() SaveAura(id) end)
	ed.texturePath:SetScript("OnEnterPressed", function() SaveAura(id) end)
	ed.size:SetScript("OnEnterPressed", function() SaveAura(id) end)
	ed.x:SetScript("OnEnterPressed", function() SaveAura(id) end)
	ed.y:SetScript("OnEnterPressed", function() SaveAura(id) end)
	ed.save:SetScript("OnClick", function() SaveAura(id) end)

	ed:Show()
	
end



-- SLASH COMMAND

SLASH_sA1 = "/sa"
SLASH_sA2 = "/simpleauras"
SlashCmdList["sA"] = function(msg)

	-- Get Command
	if type(msg) ~= "string" then
		msg = ""
	end

	-- Get Command Arguments
	local cmd, val
	local s, e, a, b = string.find(msg, "^(%S*)%s*(%S*)$")
	if a then cmd = a else cmd = "" end
	if b then val = b else val = "" end
	
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
		if num and num >= 1 and num <= 10 then
			simpleAuras.refresh = num
			DEFAULT_CHAT_FRAME:AddMessage("refresh set to " .. num .. " times per second")
		else
			DEFAULT_CHAT_FRAME:AddMessage("Usage: /sa refresh X - Set refresh rate. (1 to 10 updates per second. Default: 5)")
			DEFAULT_CHAT_FRAME:AddMessage("Current refresh = " .. tostring(simpleAuras.refresh) .. " times per second")
		end
		return
	end

	-- Unknown command fallback
	DEFAULT_CHAT_FRAME:AddMessage("Usage:")
	DEFAULT_CHAT_FRAME:AddMessage("/sa or /sa show or /sa hide - Show/hide simpleAuras Settings")
	DEFAULT_CHAT_FRAME:AddMessage("/sa refresh X - Set refresh rate. (1 to 10 updates per second. Default: 5)")

end
