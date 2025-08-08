-- gui.lua (cleaned & completed)

-- Deep copy helper
local function deepCopy(tbl)
  local t = {}
  for k, v in pairs(tbl) do
    t[k] = (type(v) == "table") and deepCopy(v) or v
  end
  return t
end

-- Create Test frames (used by editor preview)
local TestAura = CreateFrame("Frame", "sATest", UIParent)
TestAura:SetFrameStrata("BACKGROUND")
TestAura:SetFrameLevel(128)
TestAura.texture = TestAura:CreateTexture(nil, "BACKGROUND")
TestAura.texture:SetAllPoints(TestAura)
TestAura.durationtext = TestAura:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TestAura.durationtext:SetFont("Fonts\FRIZQT__.TTF", 12, "OUTLINE")
TestAura.durationtext:SetPoint("CENTER", TestAura, "CENTER", 0, 0)
TestAura.stackstext = TestAura:CreateFontString(nil, "OVERLAY", "GameFontWhite")
TestAura.stackstext:SetFont("Fonts\FRIZQT__.TTF", 8, "OUTLINE")
TestAura.stackstext:SetPoint("TOPLEFT", TestAura.durationtext, "CENTER", 1, -6)
TestAura:Hide()
sA.TestAura = TestAura

local TestAuraDual = CreateFrame("Frame", "sATestDual", UIParent)
TestAuraDual:SetFrameStrata("BACKGROUND")
TestAuraDual:SetFrameLevel(128)
TestAuraDual.texture = TestAuraDual:CreateTexture(nil, "BACKGROUND")
TestAuraDual.texture:SetAllPoints(TestAuraDual)
TestAuraDual.durationtext = TestAuraDual:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TestAuraDual.durationtext:SetFont("Fonts\FRIZQT__.TTF", 12, "OUTLINE")
TestAuraDual.durationtext:SetPoint("CENTER", TestAuraDual, "CENTER", 0, 0)
TestAuraDual.stackstext = TestAuraDual:CreateFontString(nil, "OVERLAY", "GameFontWhite")
TestAuraDual.stackstext:SetFont("Fonts\FRIZQT__.TTF", 8, "OUTLINE")
TestAuraDual.stackstext:SetPoint("TOPLEFT", TestAuraDual.durationtext, "CENTER", 1, -6)
TestAuraDual:Hide()
sA.TestAuraDual = TestAuraDual

table.insert(UISpecialFrames, "sATest")
table.insert(UISpecialFrames, "sATestDual")

-- Main GUI frame
if not gui then
  gui = CreateFrame("Frame", "sAGUI", UIParent)
  gui:SetFrameStrata("HIGH")
  gui:SetPoint("CENTER")
  gui:SetWidth(300)
  gui:SetHeight(400)
  gui:SetMovable(true)
  gui:EnableMouse(true)
  gui:RegisterForDrag("LeftButton")
  gui:SetScript("OnDragStart", function(self) self:StartMoving() end)
  gui:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  sA:SkinFrame(gui)

  local title = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -5)
  title:SetText("simpleAuras")

  gui:Hide()
  table.insert(UISpecialFrames, "sAGUI")
end

-- Add button
local addBtn = CreateFrame("Button", nil, gui)
addBtn:SetPoint("TOPLEFT", 2, -2)
addBtn:SetWidth(20)
addBtn:SetHeight(20)
sA:SkinFrame(addBtn, {0.2, 0.2, 0.2, 1})
addBtn.text = addBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
addBtn.text:SetPoint("CENTER")
addBtn.text:SetText("+")
addBtn:SetFontString(addBtn.text)
addBtn:SetScript("OnClick", function() AddAura() end)
addBtn:SetScript("OnEnter", function() addBtn:SetBackdropColor(0.1, 0.4, 0.1, 1) end)
addBtn:SetScript("OnLeave", function() addBtn:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

-- Close button
local closeBtn = CreateFrame("Button", nil, gui)
closeBtn:SetPoint("TOPRIGHT", -2, -2)
closeBtn:SetWidth(20)
closeBtn:SetHeight(20)
sA:SkinFrame(closeBtn, {0.2, 0.2, 0.2, 1})
closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
closeBtn.text:SetPoint("CENTER", 0.5, 1)
closeBtn.text:SetText("x")
closeBtn:SetFontString(closeBtn.text)
closeBtn:SetScript("OnClick", function()
  gui:Hide()
  if sA.TestAura then sA.TestAura:Hide() end
  if sA.TestAuraDual then sA.TestAuraDual:Hide() end
end)
closeBtn:SetScript("OnEnter", function() closeBtn:SetBackdropColor(0.4, 0.1, 0.1, 1) end)
closeBtn:SetScript("OnLeave", function() closeBtn:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

-- Refresh list of configured auras
function RefreshAuraList()
  for _, entry in ipairs(gui.list or {}) do entry:Hide() end
  gui.list = {}

  for i, aura in ipairs(simpleAuras.auras) do
    local row = CreateFrame("Button", nil, gui)
    row:SetWidth(260)
    row:SetHeight(20)
    row:SetPoint("TOPLEFT", 20, -30 - (i - 1) * 22)
    sA:SkinFrame(row, {0.2, 0.2, 0.2, 1})
    row:SetScript("OnEnter", function() row:SetBackdropColor(0.5, 0.5, 0.5, 1) end)
    row:SetScript("OnLeave", function() row:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    row.text:SetPoint("LEFT", 5, 0)
    row.text:SetText("[" .. i .. "] " .. (aura.name ~= "" and aura.name or "<unnamed>"))
    row.text:SetTextColor(unpack(aura.auracolor or {1, 1, 1}))
    row:SetScript("OnClick", function()
      if gui.editor then
        if sA.TestAura then sA.TestAura:Hide() end
        if sA.TestAuraDual then sA.TestAuraDual:Hide() end
        gui.editor:Hide()
        gui.editor = nil
      end
      sA:EditAura(i)
    end)

    if i > 1 then
      local up = CreateFrame("Button", nil, row)
      up:SetWidth(15)
      up:SetHeight(15)
      up:SetPoint("RIGHT", -19, 0)
      sA:SkinFrame(up, {0.15, 0.15, 0.15, 1})
      up.text = up:CreateFontString(nil, "OVERLAY", "GameFontWhite")
      up.text:SetFont("Fonts\FRIZQT__.TTF", 24)
      up.text:SetPoint("CENTER", -1, -8)
      up.text:SetText("ˆ")
      up:SetFontString(up.text)
      up:SetScript("OnClick", function()
        simpleAuras.auras[i], simpleAuras.auras[i-1] = simpleAuras.auras[i-1], simpleAuras.auras[i]
        RefreshAuraList()
      end)
    end

    if i < table.getn(simpleAuras.auras) then
      local down = CreateFrame("Button", nil, row)
      down:SetWidth(15)
      down:SetHeight(15)
      down:SetPoint("RIGHT", -2, 0)
      sA:SkinFrame(down, {0.15, 0.15, 0.15, 1})
      down.text = down:CreateFontString(nil, "OVERLAY", "GameFontWhite")
      down.text:SetFont("Fonts\FRIZQT__.TTF", 24)
      down.text:SetPoint("CENTER", -1, -8)
      down.text:SetText("ˇ")
      down:SetFontString(down.text)
      down:SetScript("OnClick", function()
        simpleAuras.auras[i], simpleAuras.auras[i+1] = simpleAuras.auras[i+1], simpleAuras.auras[i]
        RefreshAuraList()
      end)
    end

    gui.list[i] = row
  end
end

-- Save aura data from editor
function SaveAura(id)
  local ed = gui.editor
  if not ed then return end
  local data = simpleAuras.auras[id]
  data.name            = ed.name:GetText()
  data.auracolor       = ed.auracolor
  data.autodetect      = ed.autoDetect.value
  data.texture         = ed.texturePath:GetText()
  data.size            = tonumber(ed.size:GetText()) or ed.size:GetText()
  data.xpos            = tonumber(ed.x:GetText()) or ed.x:GetText()
  data.ypos            = tonumber(ed.y:GetText()) or ed.y:GetText()
  data.duration        = ed.duration.value
  data.stacks          = ed.stacks.value
  data.lowduration     = ed.lowduration.value
  data.lowdurationvalue= tonumber(ed.lowdurationvalue:GetText())
  data.lowdurationcolor= ed.lowdurationcolor
  data.unit            = ed.unitButton.text:GetText()
  data.type            = ed.typeButton.text:GetText()
  data.invert          = ed.invert.value
  data.dual            = ed.dual.value

  ed.name:ClearFocus()
  ed.texturePath:ClearFocus()
  ed.size:ClearFocus()
  ed.x:ClearFocus()
  ed.y:ClearFocus()
  ed.lowdurationvalue:ClearFocus()

  if sA.TestAura then sA.TestAura:Hide() end
  if sA.TestAuraDual then sA.TestAuraDual:Hide() end
  ed:Hide()
  gui.editor = nil
  RefreshAuraList()
  sA:EditAura(id)
end

-- Add new aura (optionally copy from existing)
function AddAura(copyId)
  table.insert(simpleAuras.auras, {})
  local newId = table.getn(simpleAuras.auras)
  if copyId and simpleAuras.auras[copyId] then
    simpleAuras.auras[newId] = deepCopy(simpleAuras.auras[copyId])
  else
    simpleAuras.auras[newId] = { name = "", texture = "Interface\Icons\INV_Misc_QuestionMark" }
  end
  if gui.editor and gui.editor:IsShown() then
    gui.editor:Hide()
    gui.editor = nil
    if sA.TestAura then sA.TestAura:Hide() end
    if sA.TestAuraDual then sA.TestAuraDual:Hide() end
  end
  sA:UpdateAuras()
  RefreshAuraList()
  sA:EditAura(newId)
end

-- Editor window / show and build controls
function sA:EditAura(id)
  local aura = simpleAuras.auras[id]
  if not aura then return end

  local ed = gui.editor
  if not ed then
    ed = CreateFrame("Frame", "sAEdit", gui)
    ed:SetWidth(300)
    ed:SetHeight(400)
    ed:SetPoint("LEFT", gui, "RIGHT", 10, 0)
    sA:SkinFrame(ed)
    ed:SetMovable(true)
    ed:EnableMouse(true)
    ed:RegisterForDrag("LeftButton")
    ed:SetScript("OnDragStart", function(self) self:StartMoving() end)
    ed:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    table.insert(UISpecialFrames, "sAEdit")

    ed.title = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.title:SetPoint("TOP", ed, "TOP", 0, -5)

    -- Name
    ed.nameLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.nameLabel:SetPoint("TOPLEFT", ed, "TOPLEFT", 12.5, -40)
    ed.nameLabel:SetText("Aura Name:")
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
    ed.name:SetBackdrop({ bgFile = "Interface\Buttons\WHITE8x8", edgeFile = "Interface\Buttons\WHITE8x8", edgeSize = 1 })
    ed.name:SetBackdropColor(0.1, 0.1, 0.1, 1)
    ed.name:SetBackdropBorderColor(0, 0, 0, 1)

    -- Separator
    local lineone = ed:CreateTexture(nil, "ARTWORK")
    lineone:SetTexture("Interface\Buttons\WHITE8x8")
    lineone:SetVertexColor(1, 0.8, 0.06, 1)
    lineone:SetPoint("TOPLEFT", ed.nameLabel, "BOTTOMLEFT", 0, -15)
    lineone:SetWidth(275)
    lineone:SetHeight(1)

    -- Texture label + color picker + autodetect
    ed.texLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.texLabel:SetPoint("TOPLEFT", lineone, "BOTTOMLEFT", 0, -15)
    ed.texLabel:SetText("Icon/Texture:")

    ed.auracolorpicker = CreateFrame("Button", nil, ed)
    ed.auracolorpicker:SetWidth(24)
    ed.auracolorpicker:SetHeight(12)
    ed.auracolorpicker:SetPoint("LEFT", ed.texLabel, "RIGHT", 5, 0)
    sA:SkinFrame(ed.auracolorpicker, {1,1,1,1})
    ed.auracolorpicker.prev = ed.auracolorpicker:CreateTexture(nil, "OVERLAY")
    ed.auracolorpicker.prev:SetAllPoints(ed.auracolorpicker)

    -- Autodetect checkbox
    ed.autoDetect = CreateFrame("Button", nil, ed)
    ed.autoDetect:SetWidth(16)
    ed.autoDetect:SetHeight(16)
    ed.autoDetect:SetPoint("LEFT", ed.auracolorpicker, "RIGHT", 73, 0)
    sA:SkinFrame(ed.autoDetect, {0.15,0.15,0.15,1})
    ed.autoDetect.checked = ed.autoDetect:CreateTexture(nil, "OVERLAY")
    ed.autoDetect.checked:SetTexture("Interface\Buttons\WHITE8x8")
    ed.autoDetect.checked:SetVertexColor(1, 0.8, 0.06, 1)
    ed.autoDetect.checked:SetPoint("CENTER", ed.autoDetect, "CENTER", 0, 0)
    ed.autoDetect.checked:SetWidth(7)
    ed.autoDetect.checked:SetHeight(7)
    ed.autoDetect.checked:Hide()

    ed.autoLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.autoLabel:SetPoint("LEFT", ed.autoDetect, "RIGHT", 5, 1)
    ed.autoLabel:SetText("Autodetect")

    -- Texture input + browse
    ed.texturePath = CreateFrame("EditBox", nil, ed)
    ed.texturePath:SetPoint("TOPLEFT", ed.texLabel, "BOTTOMLEFT", 0, -10)
    ed.texturePath:SetWidth(200)
    ed.texturePath:SetHeight(20)
    ed.texturePath:SetMultiLine(false)
    ed.texturePath:SetAutoFocus(false)
    ed.texturePath:SetFontObject(GameFontHighlightSmall)
    ed.texturePath:SetTextColor(1,1,1)
    ed.texturePath:SetBackdrop({ bgFile = "Interface\Buttons\WHITE8x8", edgeFile = "Interface\Buttons\WHITE8x8", edgeSize = 1 })
    ed.texturePath:SetBackdropColor(0.1,0.1,0.1,1)
    ed.texturePath:SetBackdropBorderColor(0,0,0,1)

    ed.browseBtn = CreateFrame("Button", nil, ed)
    ed.browseBtn:SetWidth(60)
    ed.browseBtn:SetHeight(20)
    ed.browseBtn:SetPoint("LEFT", ed.texturePath, "RIGHT", 15, 0)
    sA:SkinFrame(ed.browseBtn, {0.2,0.2,0.2,1})
    ed.browseBtn.text = ed.browseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.browseBtn.text:SetPoint("CENTER")
    ed.browseBtn.text:SetText("Browse")

    -- Size / position inputs
    ed.sizeLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.sizeLabel:SetPoint("TOPLEFT", ed.texturePath, "TOPLEFT", 0, -30)
    ed.sizeLabel:SetText("Size:")
    ed.size = CreateFrame("EditBox", nil, ed)
    ed.size:SetPoint("LEFT", ed.sizeLabel, "RIGHT", 5, 0)
    ed.size:SetWidth(30)
    ed.size:SetHeight(20)
    ed.size:SetMultiLine(false)
    ed.size:SetAutoFocus(false)
    ed.size:SetFontObject(GameFontHighlightSmall)
    ed.size:SetTextColor(1,1,1)
    ed.size:SetBackdrop({ bgFile = "Interface\Buttons\WHITE8x8", edgeFile = "Interface\Buttons\WHITE8x8", edgeSize = 1 })
    ed.size:SetBackdropColor(0.1,0.1,0.1,1)
    ed.size:SetBackdropBorderColor(0,0,0,1)

    ed.xLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.xLabel:SetPoint("LEFT", ed.size, "RIGHT", 35, 0)
    ed.xLabel:SetText("x pos:")
    ed.x = CreateFrame("EditBox", nil, ed)
    ed.x:SetPoint("LEFT", ed.xLabel, "RIGHT", 5, 0)
    ed.x:SetWidth(30)
    ed.x:SetHeight(20)
    ed.x:SetMultiLine(false)
    ed.x:SetAutoFocus(false)
    ed.x:SetFontObject(GameFontHighlightSmall)
    ed.x:SetTextColor(1,1,1)
    ed.x:SetBackdrop({ bgFile = "Interface\Buttons\WHITE8x8", edgeFile = "Interface\Buttons\WHITE8x8", edgeSize = 1 })
    ed.x:SetBackdropColor(0.1,0.1,0.1,1)
    ed.x:SetBackdropBorderColor(0,0,0,1)

    ed.yLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.yLabel:SetPoint("LEFT", ed.x, "RIGHT", 30, 0)
    ed.yLabel:SetText("y pos:")
    ed.y = CreateFrame("EditBox", nil, ed)
    ed.y:SetPoint("LEFT", ed.yLabel, "RIGHT", 5, 0)
    ed.y:SetWidth(30)
    ed.y:SetHeight(20)
    ed.y:SetMultiLine(false)
    ed.y:SetAutoFocus(false)
    ed.y:SetFontObject(GameFontHighlightSmall)
    ed.y:SetTextColor(1,1,1)
    ed.y:SetBackdrop({ bgFile = "Interface\Buttons\WHITE8x8", edgeFile = "Interface\Buttons\WHITE8x8", edgeSize = 1 })
    ed.y:SetBackdropColor(0.1,0.1,0.1,1)
    ed.y:SetBackdropBorderColor(0,0,0,1)

    -- Duration / stacks checkboxes
    ed.duration = CreateFrame("Button", nil, ed)
    ed.duration:SetWidth(16)
    ed.duration:SetHeight(16)
    ed.duration:SetPoint("TOPLEFT", ed.sizeLabel, "BOTTOMLEFT", 0, -15)
    sA:SkinFrame(ed.duration, {0.15,0.15,0.15,1})
    ed.duration.checked = ed.duration:CreateTexture(nil, "OVERLAY")
    ed.duration.checked:SetTexture("Interface\Buttons\WHITE8x8")
    ed.duration.checked:SetVertexColor(1,0.8,0.06,1)
    ed.duration.checked:SetPoint("CENTER", ed.duration, "CENTER", 0, 0)
    ed.duration.checked:SetWidth(7)
    ed.duration.checked:SetHeight(7)

    ed.duration.value = 0
    ed.duration:SetScript("OnClick", function(self)
      ed.duration.value = 1 - (ed.duration.value or 0)
      if ed.duration.value == 1 then ed.duration.checked:Show() else ed.duration.checked:Hide() end
      if simpleAuras.auras[id] then simpleAuras.auras[id].duration = ed.duration.value end
    end)
    ed.durationLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.durationLabel:SetPoint("LEFT", ed.duration, "RIGHT", 5, 0)
    ed.durationLabel:SetText("Show Duration")

    ed.stacks = CreateFrame("Button", nil, ed)
    ed.stacks:SetWidth(16)
    ed.stacks:SetHeight(16)
    ed.stacks:SetPoint("LEFT", ed.durationLabel, "RIGHT", 65, 0)
    sA:SkinFrame(ed.stacks, {0.15,0.15,0.15,1})
    ed.stacks.checked = ed.stacks:CreateTexture(nil, "OVERLAY")
    ed.stacks.checked:SetTexture("Interface\Buttons\WHITE8x8")
    ed.stacks.checked:SetVertexColor(1,0.8,0.06,1)
    ed.stacks.checked:SetPoint("CENTER", ed.stacks, "CENTER", 0, 0)
    ed.stacks.checked:SetWidth(7)
    ed.stacks.checked:SetHeight(7)
    ed.stacks.value = 0
    ed.stacks:SetScript("OnClick", function(self)
      ed.stacks.value = 1 - (ed.stacks.value or 0)
      if ed.stacks.value == 1 then ed.stacks.checked:Show() else ed.stacks.checked:Hide() end
      if simpleAuras.auras[id] then simpleAuras.auras[id].stacks = ed.stacks.value end
    end)
    ed.stacksLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.stacksLabel:SetPoint("LEFT", ed.stacks, "RIGHT", 5, 0)
    ed.stacksLabel:SetText("Show Stacks")

    -- Low duration options
    ed.lowduration = CreateFrame("Button", nil, ed)
    ed.lowduration:SetWidth(16)
    ed.lowduration:SetHeight(16)
    ed.lowduration:SetPoint("TOPLEFT", ed.sizeLabel, "BOTTOMLEFT", 0, -40)
    sA:SkinFrame(ed.lowduration, {0.15,0.15,0.15,1})
    ed.lowduration.checked = ed.lowduration:CreateTexture(nil, "OVERLAY")
    ed.lowduration.checked:SetTexture("Interface\Buttons\WHITE8x8")
    ed.lowduration.checked:SetVertexColor(1,0.8,0.06,1)
    ed.lowduration.checked:SetPoint("CENTER", ed.lowduration, "CENTER", 0, 0)
    ed.lowduration.checked:SetWidth(7)
    ed.lowduration.checked:SetHeight(7)
    ed.lowduration.value = 0
    ed.lowduration:SetScript("OnClick", function(self)
      ed.lowduration.value = 1 - (ed.lowduration.value or 0)
      if ed.lowduration.value == 1 then ed.lowduration.checked:Show() else ed.lowduration.checked:Hide() end
      if simpleAuras.auras[id] then simpleAuras.auras[id].lowduration = ed.lowduration.value end
    end)
    ed.lowdurationLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.lowdurationLabel:SetPoint("LEFT", ed.lowduration, "RIGHT", 5, 0)
    ed.lowdurationLabel:SetText("Low Duration Color")

    ed.lowdurationcolorpicker = CreateFrame("Button", nil, ed)
    ed.lowdurationcolorpicker:SetWidth(24)
    ed.lowdurationcolorpicker:SetHeight(12)
    ed.lowdurationcolorpicker:SetPoint("LEFT", ed.lowdurationLabel, "RIGHT", 10, 0)
    sA:SkinFrame(ed.lowdurationcolorpicker, {1,1,1,1})
    ed.lowdurationcolorpicker.prev = ed.lowdurationcolorpicker:CreateTexture(nil, "OVERLAY")
    ed.lowdurationcolorpicker.prev:SetAllPoints(ed.lowdurationcolorpicker)

    ed.lowdurationLabelprefix = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.lowdurationLabelprefix:SetPoint("LEFT", ed.lowdurationcolorpicker, "RIGHT", 20, 0)
    ed.lowdurationLabelprefix:SetText("(<=")

    ed.lowdurationvalue = CreateFrame("EditBox", nil, ed)
    ed.lowdurationvalue:SetPoint("LEFT", ed.lowdurationLabelprefix, "RIGHT", 2, 0)
    ed.lowdurationvalue:SetWidth(30)
    ed.lowdurationvalue:SetHeight(20)
    ed.lowdurationvalue:SetMultiLine(false)
    ed.lowdurationvalue:SetAutoFocus(false)
    ed.lowdurationvalue:SetFontObject(GameFontHighlightSmall)
    ed.lowdurationvalue:SetTextColor(1,1,1)
    ed.lowdurationvalue:SetBackdrop({ bgFile = "Interface\Buttons\WHITE8x8", edgeFile = "Interface\Buttons\WHITE8x8", edgeSize = 1 })
    ed.lowdurationvalue:SetBackdropColor(0.1,0.1,0.1,1)
    ed.lowdurationvalue:SetBackdropBorderColor(0,0,0,1)

    ed.lowdurationLabelsuffix = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.lowdurationLabelsuffix:SetPoint("LEFT", ed.lowdurationvalue, "RIGHT", 2, 0)
    ed.lowdurationLabelsuffix:SetText("sec)")

    -- Conditions (unit / type)
    local linetwo = ed:CreateTexture(nil, "ARTWORK")
    linetwo:SetTexture("Interface\Buttons\WHITE8x8")
    linetwo:SetVertexColor(1, 0.8, 0.06, 1)
    linetwo:SetPoint("TOPLEFT", ed.lowduration, "BOTTOMLEFT", 0, -15)
    linetwo:SetWidth(275)
    linetwo:SetHeight(1)

    ed.conditionsLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.conditionsLabel:SetPoint("TOP", linetwo, "BOTTOM", 0, -15)
    ed.conditionsLabel:SetJustifyH("CENTER")
    ed.conditionsLabel:SetText("Conditions")

    ed.unitLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.unitLabel:SetPoint("TOPLEFT", linetwo, "BOTTOMLEFT", 0, -45)
    ed.unitLabel:SetText("Unit:")
    ed.unitButton = CreateFrame("Button", nil, ed)
    ed.unitButton:SetWidth(80)
    ed.unitButton:SetHeight(20)
    ed.unitButton:SetPoint("LEFT", ed.unitLabel, "RIGHT", 5, 0)
    sA:SkinFrame(ed.unitButton, {0.2,0.2,0.2,1})
    ed.unitButton.text = ed.unitButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.unitButton.text:SetPoint("CENTER")

    ed.unitButton:SetScript("OnClick", function(self)
      if not ed.unitButton.menu then
        local menu = CreateFrame("Frame", nil, ed)
        menu:SetPoint("TOPLEFT", ed.unitButton, "BOTTOMLEFT", 0, -2)
        menu:SetFrameStrata("DIALOG")
        menu:SetFrameLevel(10)
        menu:SetWidth(80)
        menu:SetHeight(40)
        sA:SkinFrame(menu, {0.15,0.15,0.15,1})
        menu:Hide()
        ed.unitButton.menu = menu
        local function makeChoice(text, index)
          local b = CreateFrame("Button", nil, menu)
          b:SetWidth(80)
          b:SetHeight(20)
          b:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -((index - 1) * 20))
          sA:SkinFrame(b, {0.2,0.2,0.2,1})
          b.text = b:CreateFontString(nil, "OVERLAY", "GameFontWhite")
          b.text:SetPoint("CENTER")
          b.text:SetText(text)
          b:SetScript("OnEnter", function() b:SetBackdropColor(0.5,0.5,0.5,1) end)
          b:SetScript("OnLeave", function() b:SetBackdropColor(0.2,0.2,0.2,1) end)
          b:SetScript("OnClick", function()
            ed.unitButton.text:SetText(text)
            aura.unit = text
            menu:Hide()
            SaveAura(id)
          end)
        end
        makeChoice("Player", 1)
        makeChoice("Target", 2)
      end
      local menu = ed.unitButton.menu
      if menu:IsVisible() then menu:Hide() else menu:Show() end
    end)

    -- Type dropdown
    ed.typeLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.typeLabel:SetPoint("LEFT", ed.unitButton, "RIGHT", 42, 0)
    ed.typeLabel:SetText("Type:")
    ed.typeButton = CreateFrame("Button", nil, ed)
    ed.typeButton:SetWidth(80)
    ed.typeButton:SetHeight(20)
    ed.typeButton:SetPoint("LEFT", ed.typeLabel, "RIGHT", 5, 0)
    sA:SkinFrame(ed.typeButton, {0.2,0.2,0.2,1})
    ed.typeButton.text = ed.typeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.typeButton.text:SetPoint("CENTER")
    ed.typeButton:SetScript("OnClick", function(self)
      if not ed.typeButton.menu then
        local menu = CreateFrame("Frame", nil, ed)
        menu:SetPoint("TOPLEFT", ed.typeButton, "BOTTOMLEFT", 0, -2)
        menu:SetFrameStrata("DIALOG")
        menu:SetFrameLevel(10)
        menu:SetWidth(80)
        menu:SetHeight(40)
        sA:SkinFrame(menu, {0.15,0.15,0.15,1})
        menu:Hide()
        ed.typeButton.menu = menu
        local function makeChoice(text, index)
          local b = CreateFrame("Button", nil, menu)
          b:SetWidth(80)
          b:SetHeight(20)
          b:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -((index - 1) * 20))
          sA:SkinFrame(b, {0.2,0.2,0.2,1})
          b.text = b:CreateFontString(nil, "OVERLAY", "GameFontWhite")
          b.text:SetPoint("CENTER")
          b.text:SetText(text)
          b:SetScript("OnEnter", function() b:SetBackdropColor(0.5,0.5,0.5,1) end)
          b:SetScript("OnLeave", function() b:SetBackdropColor(0.2,0.2,0.2,1) end)
          b:SetScript("OnClick", function()
            ed.typeButton.text:SetText(text)
            aura.type = text
            menu:Hide()
            SaveAura(id)
          end)
        end
        makeChoice("Buff", 1)
        makeChoice("Debuff", 2)
      end
      local menu = ed.typeButton.menu
      if menu:IsVisible() then menu:Hide() else menu:Show() end
    end)

    -- Invert / Dual
    ed.invert = CreateFrame("Button", nil, ed)
    ed.invert:SetWidth(16)
    ed.invert:SetHeight(16)
    ed.invert:SetPoint("BOTTOMLEFT", ed, "BOTTOMLEFT", 52.5, 30)
    sA:SkinFrame(ed.invert, {0.15,0.15,0.15,1})
    ed.invert.checked = ed.invert:CreateTexture(nil, "OVERLAY")
    ed.invert.checked:SetTexture("Interface\Buttons\WHITE8x8")
    ed.invert.checked:SetVertexColor(1,0.8,0.06,1)
    ed.invert.checked:SetPoint("CENTER", ed.invert, "CENTER", 0, 0)
    ed.invert.checked:SetWidth(7)
    ed.invert.checked:SetHeight(7)
    ed.invert.value = 0
    ed.invert:SetScript("OnClick", function(self)
      ed.invert.value = 1 - (ed.invert.value or 0)
      if ed.invert.value == 1 then ed.invert.checked:Show() else ed.invert.checked:Hide() end
      if simpleAuras.auras[id] then simpleAuras.auras[id].invert = ed.invert.value end
    end)
    ed.invertLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.invertLabel:SetPoint("LEFT", ed.invert, "RIGHT", 5, 0)
    ed.invertLabel:SetText("Invert")

    ed.dual = CreateFrame("Button", nil, ed)
    ed.dual:SetWidth(16)
    ed.dual:SetHeight(16)
    ed.dual:SetPoint("LEFT", ed.invertLabel, "RIGHT", 90, 0)
    sA:SkinFrame(ed.dual, {0.15,0.15,0.15,1})
    ed.dual.checked = ed.dual:CreateTexture(nil, "OVERLAY")
    ed.dual.checked:SetTexture("Interface\Buttons\WHITE8x8")
    ed.dual.checked:SetVertexColor(1,0.8,0.06,1)
    ed.dual.checked:SetPoint("CENTER", ed.dual, "CENTER", 0, 0)
    ed.dual.checked:SetWidth(7)
    ed.dual.checked:SetHeight(7)
    ed.dual.value = 0
    ed.dual:SetScript("OnClick", function(self)
      ed.dual.value = 1 - (ed.dual.value or 0)
      if ed.dual.value == 1 then ed.dual.checked:Show() else ed.dual.checked:Hide() end
      if simpleAuras.auras[id] then simpleAuras.auras[id].dual = ed.dual.value end
    end)
    ed.dualLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.dualLabel:SetPoint("LEFT", ed.dual, "RIGHT", 5, 0)
    ed.dualLabel:SetText("Dual")

    -- Save / Delete / Close / Copy buttons
    ed.save = CreateFrame("Button", nil, ed)
    ed.save:SetPoint("BOTTOMLEFT", 2, 2)
    ed.save:SetWidth(60)
    ed.save:SetHeight(20)
    sA:SkinFrame(ed.save, {0.2,0.2,0.2,1})
    ed.save.text = ed.save:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.save.text:SetPoint("CENTER")
    ed.save.text:SetText("Save")
    ed.save:SetScript("OnEnter", function() ed.save:SetBackdropColor(0.1,0.4,0.1,1) end)
    ed.save:SetScript("OnLeave", function() ed.save:SetBackdropColor(0.2,0.2,0.2,1) end)

    ed.delete = CreateFrame("Button", nil, ed)
    ed.delete:SetPoint("BOTTOMRIGHT", -2, 2)
    ed.delete:SetWidth(60)
    ed.delete:SetHeight(20)
    sA:SkinFrame(ed.delete, {0.2,0.2,0.2,1})
    ed.delete.text = ed.delete:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.delete.text:SetPoint("CENTER")
    ed.delete.text:SetText("Delete")
    ed.delete:SetScript("OnEnter", function() ed.delete:SetBackdropColor(0.4,0.1,0.1,1) end)
    ed.delete:SetScript("OnLeave", function() ed.delete:SetBackdropColor(0.2,0.2,0.2,1) end)

    ed.close = CreateFrame("Button", nil, ed)
    ed.close:SetPoint("TOPRIGHT", -2, -2)
    ed.close:SetWidth(20)
    ed.close:SetHeight(20)
    sA:SkinFrame(ed.close, {0.2,0.2,0.2,1})
    ed.close.text = ed.close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.close.text:SetPoint("CENTER", 0.5, 1)
    ed.close.text:SetText("x")
    ed.close:SetScript("OnEnter", function() ed.close:SetBackdropColor(0.4,0.1,0.1,1) end)
    ed.close:SetScript("OnLeave", function() ed.close:SetBackdropColor(0.2,0.2,0.2,1) end)

    ed.copy = CreateFrame("Button", nil, ed)
    ed.copy:SetPoint("TOPLEFT", 2, -2)
    ed.copy:SetWidth(20)
    ed.copy:SetHeight(20)
    sA:SkinFrame(ed.copy, {0.2,0.2,0.2,1})
    ed.copy.text = ed.copy:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.copy.text:SetPoint("CENTER", 0.5, 1)
    ed.copy.text:SetText("c")

    gui.editor = ed
  end

  -- Populate fields with aura values
  ed.title:SetText("[" .. tostring(id) .. "] " .. (aura.name ~= "" and aura.name or "<unnamed>"))
  ed.name:SetText(aura.name or "")
  ed.auracolor = aura.auracolor or {1,1,1,1}
  ed.auracolorpicker = ed.auracolorpicker -- ensure exists
  ed.auracolorpicker.prev:SetTexture(unpack(ed.auracolor))

  ed.autoDetect.value = aura.autodetect or 0
  if ed.autoDetect.value == 1 then ed.autoDetect.checked:Show() else ed.autoDetect.checked:Hide() end

  ed.texturePath:SetText(aura.texture or "")
  ed.size:SetText(aura.size or 32)
  ed.x:SetText(aura.xpos or 0)
  ed.y:SetText(aura.ypos or 0)

  ed.duration.value = aura.duration or 0
  if ed.duration.value == 1 then ed.duration.checked:Show() else ed.duration.checked:Hide() end

  ed.stacks.value = aura.stacks or 0
  if ed.stacks.value == 1 then ed.stacks.checked:Show() else ed.stacks.checked:Hide() end

  ed.lowduration.value = aura.lowduration or 0
  if ed.lowduration.value == 1 then ed.lowduration.checked:Show() else ed.lowduration.checked:Hide() end
  ed.lowdurationvalue:SetText(aura.lowdurationvalue or 3)
  ed.lowdurationcolor = aura.lowdurationcolor or {1,1,1,1}
  ed.lowdurationcolorpicker.prev:SetTexture(unpack(ed.lowdurationcolor))

  ed.unitButton.text:SetText(aura.unit or "Player")
  ed.typeButton.text:SetText(aura.type or "Buff")
  ed.invert.value = aura.invert or 0
  if ed.invert.value == 1 then ed.invert.checked:Show() else ed.invert.checked:Hide() end
  ed.dual.value = aura.dual or 0
  if ed.dual.value == 1 then ed.dual.checked:Show() else ed.dual.checked:Hide() end

  -- Show Test aura(s)
  sA.TestAura:SetPoint("CENTER", UIParent, "CENTER", aura.xpos or 0, aura.ypos or 0)
  sA.TestAura:SetWidth(aura.size or 32)
  sA.TestAura:SetHeight(aura.size or 32)
  sA.TestAura.texture:SetTexture(aura.texture)
  sA.TestAura.texture:SetVertexColor(unpack(aura.auracolor or {1,1,1,1}))
  if aura.duration == 1 then sA.TestAura.durationtext:SetText("600") else sA.TestAura.durationtext:SetText("") end
  if aura.stacks == 1 then sA.TestAura.stackstext:SetText("20") else sA.TestAura.stackstext:SetText("") end
  sA.TestAura:Show()
  
  if aura.dual == 1 then
    sA.TestAuraDual:SetPoint("CENTER", UIParent, "CENTER", -(aura.xpos or 0), aura.ypos or 0)
    sA.TestAuraDual:SetWidth(aura.size or 32)
    sA.TestAuraDual:SetHeight(aura.size or 32)
    sA.TestAuraDual.texture:SetTexture(aura.texture)
    sA.TestAuraDual.texture:SetTexCoord(1,0,0,1)
    sA.TestAuraDual.texture:SetVertexColor(unpack(aura.auracolor or {1,1,1,1}))
    if aura.duration == 1 then sA.TestAuraDual.durationtext:SetText("600") else sA.TestAuraDual.durationtext:SetText("") end
    if aura.stacks == 1 then sA.TestAuraDual.stackstext:SetText("20") else sA.TestAuraDual.stackstext:SetText("") end
    sA.TestAuraDual:Show()
  else
    sA.TestAuraDual:Hide()
  end

  -- Editor button handlers
  ed.save:SetScript("OnClick", function() SaveAura(id) end)
  ed.close:SetScript("OnClick", function() ed:Hide(); gui.editor = nil; sA.TestAura:Hide(); sA.TestAuraDual:Hide() end)
  ed.copy:SetScript("OnClick", function() AddAura(id) end)

  ed.delete:SetScript("OnClick", function()
    if ed.confirm then ed.confirm:Show(); return end
    ed.confirm = CreateFrame("Frame", nil, ed)
    ed.confirm:EnableMouse(true)
    ed.confirm:SetFrameStrata("DIALOG")
    ed.confirm:SetFrameLevel(10)
    ed.confirm:SetPoint("CENTER", ed, "CENTER", 0, 0)
    ed.confirm:SetWidth(250)
    ed.confirm:SetHeight(80)
    sA:SkinFrame(ed.confirm, {0.15,0.15,0.15,1})
    local msg = ed.confirm:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    msg:SetPoint("TOP", 0, -20)
    msg:SetText("Delete '["..id.."] "..(aura.name ~= "" and aura.name or "<unnamed>").."'?")
    msg:SetTextColor(1,0,0)

    local yes = CreateFrame("Button", nil, ed.confirm)
    yes:SetPoint("BOTTOMLEFT", 30, 10)
    yes:SetWidth(60)
    yes:SetHeight(20)
    sA:SkinFrame(yes, {0.2,0.2,0.2,1})
    yes.text = yes:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yes.text:SetPoint("CENTER")
    yes.text:SetText("Yes")
    yes:SetScript("OnClick", function()
      table.remove(simpleAuras.auras, id)
      ed.confirm:Hide()
      ed:Hide()
      gui.editor = nil
      RefreshAuraList()
      sA.TestAura:Hide()
      sA.TestAuraDual:Hide()
    end)

    local no = CreateFrame("Button", nil, ed.confirm)
    no:SetPoint("BOTTOMRIGHT", -30, 10)
    no:SetWidth(60)
    no:SetHeight(20)
    sA:SkinFrame(no, {0.2,0.2,0.2,1})
    no.text = no:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    no.text:SetPoint("CENTER")
    no.text:SetText("No")
    no:SetScript("OnClick", function() ed.confirm:Hide() end)
  end)

  -- Color pickers behavior
  ed.auracolorpicker:SetScript("OnClick", function(self)
    local r0,g0,b0,a0 = unpack(ed.auracolor or {1,1,1,1})
    ColorPickerFrame.func = function()
      local r,g,b = ColorPickerFrame:GetColorRGB()
      local a = 1 - OpacitySliderFrame:GetValue()
      r = math.floor(r * 100 + 0.5) / 100
      g = math.floor(g * 100 + 0.5) / 100
      b = math.floor(b * 100 + 0.5) / 100
      a = math.floor(a * 100 + 0.5) / 100
      ed.auracolor = {r,g,b,a}
      ed.auracolorpicker.prev:SetTexture(r,g,b,a)
      sA.TestAura.texture:SetVertexColor(r,g,b,a)
      if simpleAuras.auras[id] and simpleAuras.auras[id].dual == 1 then
        sA.TestAuraDual.texture:SetVertexColor(r,g,b,a)
      end
      if gui.list[id] then gui.list[id].text:SetTextColor(r,g,b,a) end
    end
    ColorPickerFrame.cancelFunc = function()
      ed.auracolor = {r0,g0,b0,a0}
      ed.auracolorpicker.prev:SetTexture(r0,g0,b0,a0)
      sA.TestAura.texture:SetVertexColor(r0,g0,b0,a0)
      if simpleAuras.auras[id] and simpleAuras.auras[id].dual == 1 then
        sA.TestAuraDual.texture:SetVertexColor(r0,g0,b0,a0)
      end
      if gui.list[id] then gui.list[id].text:SetTextColor(r0,g0,b0,a0) end
    end
    ColorPickerFrame:SetColorRGB(r0,g0,b0)
    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacityFunc = ColorPickerFrame.func
    ColorPickerFrame.opacity = 1 - (a0 or 0)
    ColorPickerFrame:SetFrameStrata("DIALOG")
    ShowUIPanel(ColorPickerFrame)
  end)

  ed.lowdurationcolorpicker:SetScript("OnClick", function(self)
    local r0,g0,b0,a0 = unpack(ed.lowdurationcolor or {1,1,1,1})
    ColorPickerFrame.func = function()
      local r,g,b = ColorPickerFrame:GetColorRGB()
      local a = 1 - OpacitySliderFrame:GetValue()
      r = math.floor(r * 100 + 0.5) / 100
      g = math.floor(g * 100 + 0.5) / 100
      b = math.floor(b * 100 + 0.5) / 100
      a = math.floor(a * 100 + 0.5) / 100
      ed.lowdurationcolor = {r,g,b,a}
      ed.lowdurationcolorpicker.prev:SetTexture(r,g,b,a)
      sA.TestAura.texture:SetVertexColor(r,g,b,a)
      if simpleAuras.auras[id] and simpleAuras.auras[id].dual == 1 then
        sA.TestAuraDual.texture:SetVertexColor(r,g,b,a)
      end
    end
    ColorPickerFrame.cancelFunc = function()
      ed.lowdurationcolor = {r0,g0,b0,a0}
      ed.lowdurationcolorpicker.prev:SetTexture(r0,g0,b0,a0)
    end
    ColorPickerFrame:SetColorRGB(r0,g0,b0)
    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacityFunc = ColorPickerFrame.func
    ColorPickerFrame.opacity = 1 - (a0 or 0)
    ColorPickerFrame:SetFrameStrata("DIALOG")
    ShowUIPanel(ColorPickerFrame)
  end)

  -- Browse textures
  ed.browseBtn:SetScript("OnClick", function(self)
    if ed.browseFrame then ed.browseFrame:Show(); return end
    local bf = CreateFrame("Frame", nil, ed)
    bf:EnableMouse(true)
    bf:SetAllPoints(ed)
    bf:SetFrameStrata("DIALOG")
    sA:SkinFrame(bf)
    ed.browseFrame = bf

    bf.title = bf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bf.title:SetPoint("TOP", bf, "TOP", 0, -5)
    bf.title:SetText("Select Texture")

    local close = CreateFrame("Button", nil, bf)
    close:SetWidth(20)
    close:SetHeight(20)
    close:SetPoint("TOPRIGHT", -2, -2)
    sA:SkinFrame(close, {0.2,0.2,0.2,1})
    close.text = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    close.text:SetPoint("CENTER")
    close.text:SetText("x")
    close:SetScript("OnEnter", function() close:SetBackdropColor(0.5,0.5,0.5,1) end)
    close:SetScript("OnLeave", function() close:SetBackdropColor(0.2,0.2,0.2,1) end)
    close:SetScript("OnClick", function() bf:Hide() end)

    local scroll = CreateFrame("ScrollFrame", nil, bf)
    scroll:SetPoint("TOPLEFT", 10, -30)
    scroll:SetPoint("BOTTOMRIGHT", -10, 40)
    local content = CreateFrame("Frame", nil, scroll)
    local total = 246
    local numPerRow = 6
    local size = 36
    local padding = 4
    local rows = math.ceil(total / numPerRow)
    content:SetWidth(numPerRow * (size + padding))
    content:SetHeight(rows * (size + padding))
    scroll:SetScrollChild(content)

    for i = 1, total do
      local btn = CreateFrame("Button", nil, content)
      local row = math.floor((i - 1) / numPerRow)
      local col = (i - 1) % numPerRow
      btn:SetWidth(size)
      btn:SetHeight(size)
      btn:SetPoint("TOPLEFT", col * (size + padding) + 22, -row * (size + padding))
      local tex = btn:CreateTexture(nil, "BACKGROUND")
      tex:SetAllPoints(btn)
      tex:SetTexture("Interface\AddOns\simpleAuras\Auras\Aura" .. i)
      btn.texturePath = "Interface\AddOns\simpleAuras\Auras\Aura" .. i
      btn:SetScript("OnClick", function(self)
        if content.selected then sA:SkinFrame(content.selected, {0.2,0.2,0.2,1}) end
        content.selected = self
        sA:SkinFrame(self, {0.5,0.5,0.5,1})
      end)
      sA:SkinFrame(btn, {0.2,0.2,0.2,1})
    end

    local select = CreateFrame("Button", nil, bf)
    select:SetWidth(80)
    select:SetHeight(20)
    select:SetPoint("BOTTOM", 0, 10)
    sA:SkinFrame(select, {0.2,0.2,0.2,1})
    select.text = select:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    select.text:SetPoint("CENTER")
    select.text:SetText("Select")
    select:SetScript("OnClick", function()
      if content.selected and content.selected.texturePath then
        ed.texturePath:SetText(content.selected.texturePath)
        ed.browseFrame:Hide()
        SaveAura(id)
      end
    end)
  end)

  -- ensure editor visible
  ed:Show()
end

-- Init
RefreshAuraList()
