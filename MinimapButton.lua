-- MinimapButton.lua (Boss Tactics)
-- Dependency-free minimap launcher with a persisted position.

local BT = BossTactics
local MB = {}
BT.MinimapButton = MB

local MIN_RADIUS = 80

local function GetButtonRadius()
    -- Retail UI layouts and minimap addons can change the minimap dimensions.
    -- Keep the launcher's centre just beyond the current map edge instead of
    -- relying on a radius that only fits the stock minimap size.
    local width = Minimap:GetWidth() or 0
    local height = Minimap:GetHeight() or 0
    return math.max(MIN_RADIUS, math.max(width, height) * 0.5 + 10)
end

function MB:ApplyPosition()
    if not self.button or not BT.db then return end
    local angle = math.rad(BT.db.minimapAngle or 225)
    local radius = GetButtonRadius()
    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * radius, math.sin(angle) * radius)
end

function MB:SetShown(shown)
    if not self.button then return end
    self.button:SetShown(shown ~= false)
end

function MB:Create()
    if self.button then
        self:SetShown(BT.db and BT.db.showMinimapIcon)
        self:ApplyPosition()
        return
    end

    local button = CreateFrame("Button", "BossTacticsMinimapButton", Minimap)
    self.button = button
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(22, 22)
    background:SetPoint("CENTER", 0, 0)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\AddOns\\" .. BT.ADDON_NAME .. "\\BossTacticsIcon.jpg")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetVertexColor(0.788, 0.643, 0.298, 1)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            BT:OpenSettings()
        else
            BT:OpenJournal()
        end
    end)

    button:SetScript("OnEnter", function(btn)
        border:SetVertexColor(0.894, 0.776, 0.459, 1)
        GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
        GameTooltip:SetText("Boss Tactics", 1, 0.82, 0.18)
        GameTooltip:AddLine(BT:L("MINIMAP_LEFT_CLICK"), 1, 1, 1)
        GameTooltip:AddLine(BT:L("MINIMAP_RIGHT_CLICK"), 1, 1, 1)
        GameTooltip:AddLine(BT:L("MINIMAP_DRAG"), 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        border:SetVertexColor(0.788, 0.643, 0.298, 1)
        GameTooltip:Hide()
    end)

    button:SetScript("OnDragStart", function(btn)
        btn:SetScript("OnUpdate", function()
            local scale = UIParent:GetEffectiveScale()
            local cursorX, cursorY = GetCursorPosition()
            local centerX, centerY = Minimap:GetCenter()
            cursorX, cursorY = cursorX / scale, cursorY / scale
            BT.db.minimapAngle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX)) % 360
            MB:ApplyPosition()
        end)
    end)
    button:SetScript("OnDragStop", function(btn)
        btn:SetScript("OnUpdate", nil)
    end)

    self:ApplyPosition()
    self:SetShown(BT.db and BT.db.showMinimapIcon)
end
