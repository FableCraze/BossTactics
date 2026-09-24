-- ImportExport.lua  (Boss Tactics)
-- Share custom boss tactics as copy-paste strings. Serializer + Base64 ported
-- do formato histórico. Novas exportações usam !BT1!; !BM1! e !BM2!
-- continuam aceitos para compatibilidade.
-- Unknown payload fields are silently dropped, known ones map to v4.
--
-- UI: export/import dialogs are children of the editor window (close with it,
-- no UISpecialFrames entry, no global names). Native templates + font objects
-- only — no pixel fonts from the old code.

local BT = BossTactics
local Theme = BT.Theme

local IE = {}
BT.ImportExport = IE

local PREFIX = "!BT1!"
local OLD_PREFIXES = { "!BM1!", "!BM2!" }

-- =========================================================================
-- Base64 encode / decode  (ported unchanged)
-- =========================================================================

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Base64Encode(data)
    local out = {}
    local pad = ""
    local len = #data
    local rem = len % 3
    if rem > 0 then
        pad = string.rep("=", 3 - rem)
        data = data .. string.rep("\0", 3 - rem)
        len = len + (3 - rem)
    end
    for i = 1, len, 3 do
        local b1, b2, b3 = data:byte(i, i + 2)
        local n = b1 * 65536 + b2 * 256 + b3
        local c1 = math.floor(n / 262144) % 64
        local c2 = math.floor(n / 4096) % 64
        local c3 = math.floor(n / 64) % 64
        local c4 = n % 64
        out[#out + 1] = B64:sub(c1 + 1, c1 + 1)
                     .. B64:sub(c2 + 1, c2 + 1)
                     .. B64:sub(c3 + 1, c3 + 1)
                     .. B64:sub(c4 + 1, c4 + 1)
    end
    local result = table.concat(out)
    if #pad > 0 then
        result = result:sub(1, #result - #pad) .. pad
    end
    return result
end

local B64_REV = {}
for i = 1, 64 do B64_REV[B64:byte(i)] = i - 1 end

local function Base64Decode(data)
    data = data:gsub("%s", "")
    local padLen = 0
    if data:sub(-2) == "==" then padLen = 2
    elseif data:sub(-1) == "=" then padLen = 1 end
    data = data:gsub("=", "A")

    local out = {}
    for i = 1, #data, 4 do
        local c1 = B64_REV[data:byte(i)]     or 0
        local c2 = B64_REV[data:byte(i + 1)] or 0
        local c3 = B64_REV[data:byte(i + 2)] or 0
        local c4 = B64_REV[data:byte(i + 3)] or 0
        local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
        out[#out + 1] = string.char(
            math.floor(n / 65536) % 256,
            math.floor(n / 256) % 256,
            n % 256
        )
    end
    local result = table.concat(out)
    if padLen > 0 then result = result:sub(1, #result - padLen) end
    return result
end

-- =========================================================================
-- Serializer — Lua table -> compact string  (ported unchanged)
-- =========================================================================

local function EscapeStr(s)
    return s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r")
end

local Serialize

Serialize = function(val)
    local t = type(val)
    if t == "string" then
        return '"' .. EscapeStr(val) .. '"'
    elseif t == "number" then
        if val == math.floor(val) and val >= -2147483648 and val <= 2147483647 then
            return tostring(math.floor(val))
        end
        return tostring(val)
    elseif t == "boolean" then
        return val and "T" or "F"
    elseif t == "nil" then
        return "N"
    elseif t == "table" then
        local parts = {}
        local isArr = true
        local maxN = 0
        for k in pairs(val) do
            if type(k) ~= "number" or k ~= math.floor(k) or k < 1 then
                isArr = false
                break
            end
            if k > maxN then maxN = k end
        end
        if isArr then
            for i = 1, maxN do
                if val[i] == nil then isArr = false; break end
            end
        end
        if isArr and maxN > 0 then
            for i = 1, maxN do
                parts[#parts + 1] = Serialize(val[i])
            end
        else
            local keys = {}
            for k in pairs(val) do keys[#keys + 1] = k end
            table.sort(keys, function(a, b)
                return tostring(a) < tostring(b)
            end)
            for _, k in ipairs(keys) do
                local sk
                if type(k) == "number" then
                    sk = "[" .. Serialize(k) .. "]"
                else
                    sk = tostring(k)
                end
                parts[#parts + 1] = sk .. "=" .. Serialize(val[k])
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "N"
end

-- =========================================================================
-- Deserializer — string -> Lua table (safe, no loadstring; ported unchanged)
-- =========================================================================

local function DeserializeFromPos(str, pos)
    while pos <= #str and str:sub(pos, pos):match("%s") do pos = pos + 1 end
    if pos > #str then return nil, pos end

    local ch = str:sub(pos, pos)

    if ch == '"' then
        local result = {}
        pos = pos + 1
        while pos <= #str do
            local c = str:sub(pos, pos)
            if c == '\\' then
                pos = pos + 1
                local esc = str:sub(pos, pos)
                if esc == "n" then result[#result + 1] = "\n"
                elseif esc == "r" then result[#result + 1] = "\r"
                elseif esc == '"' then result[#result + 1] = '"'
                elseif esc == "\\" then result[#result + 1] = "\\"
                else result[#result + 1] = esc end
            elseif c == '"' then
                return table.concat(result), pos + 1
            else
                result[#result + 1] = c
            end
            pos = pos + 1
        end
        return table.concat(result), pos

    elseif ch == "{" then
        local tbl = {}
        pos = pos + 1
        local arrayIndex = 1
        while pos <= #str do
            while pos <= #str and str:sub(pos, pos):match("[%s,]") do pos = pos + 1 end
            if pos > #str or str:sub(pos, pos) == "}" then
                return tbl, pos + 1
            end
            local key = nil
            if str:sub(pos, pos) == "[" then
                pos = pos + 1
                key, pos = DeserializeFromPos(str, pos)
                while pos <= #str and str:sub(pos, pos) ~= "=" do pos = pos + 1 end
                pos = pos + 1
            else
                local eqPos = nil
                local scanPos = pos
                local depth = 0
                while scanPos <= #str do
                    local sc = str:sub(scanPos, scanPos)
                    if sc == "{" then depth = depth + 1
                    elseif sc == "}" then
                        if depth == 0 then break end
                        depth = depth - 1
                    elseif sc == '"' then
                        scanPos = scanPos + 1
                        while scanPos <= #str and str:sub(scanPos, scanPos) ~= '"' do
                            if str:sub(scanPos, scanPos) == "\\" then scanPos = scanPos + 1 end
                            scanPos = scanPos + 1
                        end
                    elseif sc == "=" and depth == 0 then
                        eqPos = scanPos
                        break
                    elseif sc == "," and depth == 0 then
                        break
                    end
                    scanPos = scanPos + 1
                end

                if eqPos then
                    key = str:sub(pos, eqPos - 1)
                    key = strtrim(key)
                    local numKey = tonumber(key)
                    if numKey then key = numKey end
                    pos = eqPos + 1
                end
            end

            local value
            value, pos = DeserializeFromPos(str, pos)

            if key ~= nil then
                tbl[key] = value
            else
                tbl[arrayIndex] = value
                arrayIndex = arrayIndex + 1
            end
        end
        return tbl, pos

    elseif ch == "T" then
        return true, pos + 1
    elseif ch == "F" then
        return false, pos + 1
    elseif ch == "N" then
        return nil, pos + 1

    elseif ch:match("[%d%.%-]") then
        local numStr = ch
        pos = pos + 1
        while pos <= #str and str:sub(pos, pos):match("[%d%.eE%+%-]") do
            numStr = numStr .. str:sub(pos, pos)
            pos = pos + 1
        end
        return tonumber(numStr), pos
    end

    return nil, pos + 1
end

local function Deserialize(str)
    if not str or str == "" then return nil end
    local val = DeserializeFromPos(str, 1)
    return val
end

-- =========================================================================
-- Encode / decode — high-level
-- =========================================================================

function IE:ExportString(payload)
    return PREFIX .. Base64Encode(Serialize(payload))
end

--- Decode an import string. Returns payload table or nil, errorMsg.
--- Aceita o formato atual e os dois formatos históricos.
function IE:DecodeString(str)
    if not str or type(str) ~= "string" then
        return nil, BT:L("IMPORT_FAIL_FORMAT")
    end
    str = strtrim(str)
    local encoded
    if str:sub(1, #PREFIX) == PREFIX then
        encoded = str:sub(#PREFIX + 1)
    else
        for _, oldPrefix in ipairs(OLD_PREFIXES) do
            if str:sub(1, #oldPrefix) == oldPrefix then
                encoded = str:sub(#oldPrefix + 1)
                break
            end
        end
    end
    if not encoded then
        return nil, BT:L("IMPORT_FAIL_FORMAT")
    end
    if encoded == "" then
        return nil, BT:L("IMPORT_FAIL_FORMAT")
    end

    local ok, decoded = pcall(Base64Decode, encoded)
    if not ok or not decoded or decoded == "" then
        return nil, BT:L("IMPORT_FAIL_FORMAT")
    end

    local ok2, payload = pcall(Deserialize, decoded)
    if not ok2 or type(payload) ~= "table" then
        return nil, BT:L("IMPORT_FAIL_DATA")
    end

    local dtype = payload.type
    if dtype ~= "boss" and dtype ~= "dungeon" and dtype ~= "all"
        and dtype ~= "raidplan" and dtype ~= "raidplan_instance" then
        return nil, BT:L("IMPORT_FAIL_DATA")
    end

    return payload, nil
end

-- =========================================================================
-- Import — sanitize + apply
-- =========================================================================

-- Known v4 fields; anything else in a payload is silently ignored
local KNOWN_FIELDS = {
    dungeonName = true, encounterID = true, instanceID = true,
    tldr = true, abilities = true, tips = true, affixTips = true,
    season = true, isRaid = true, isNonSeason = true,
}

local function SanitizeBossData(data)
    local out = {}
    for k, v in pairs(data) do
        if KNOWN_FIELDS[k] then out[k] = v end
    end
    return out
end

--- Collect { [key] = data } from any payload type.
local function PayloadBosses(payload)
    local bosses = {}
    if payload.type == "boss" then
        if type(payload.key) == "string" and type(payload.data) == "table" then
            bosses[payload.key] = payload.data
        end
    elseif type(payload.bosses) == "table" then
        for key, data in pairs(payload.bosses) do
            if type(key) == "string" and type(data) == "table" then
                bosses[key] = data
            end
        end
    end
    return bosses
end

--- Build the preview summary + collision count for a decoded payload.
function IE:DescribePayload(payload)
    local bosses = PayloadBosses(payload)
    local count, collisions = 0, 0
    local firstKey, firstData
    for key, data in pairs(bosses) do
        count = count + 1
        if not firstKey then firstKey, firstData = key, data end
        if (BT.db and BT.db.customBosses and BT.db.customBosses[key])
            or (BT_BossData and BT_BossData[key]) then
            collisions = collisions + 1
        end
    end

    local lines = {}
    if count == 1 then
        local dn = firstData.dungeonName
        if type(dn) == "table" then dn = dn.en or dn.enUS end
        lines[#lines + 1] = string.format(BT:L("IMPORT_PREVIEW_BOSS"),
            firstKey, dn or "?", #(firstData.tldr or {}), #(firstData.abilities or {}))
    else
        lines[#lines + 1] = string.format(BT:L("IMPORT_PREVIEW_ALL"), count)
    end
    if collisions > 0 then
        lines[#lines + 1] = "|cffff8800" .. string.format(BT:L("IMPORT_OVERWRITE"), collisions) .. "|r"
    end
    return table.concat(lines, "\n"), count
end

--- Apply a decoded payload: save to customBosses, remerge, rebuild, refresh.
function IE:ApplyPayload(payload)
    local db = BT.db
    if not db then return 0 end
    db.customBosses = db.customBosses or {}
    if not BT_BossData then BT_BossData = {} end

    local count = 0
    for key, data in pairs(PayloadBosses(payload)) do
        local custom = SanitizeBossData(data)
        local isBuiltin = BT._originalFields[key] ~= nil
            or (BT_BossData[key] and not BT_BossData[key].isCustom)
        if not isBuiltin then custom.isCustom = true end
        db.customBosses[key] = custom
        count = count + 1
    end

    if count > 0 then
        BT:ApplyCustomBosses()
        BT:RebuildIndexes()
        local ED = BT.Editor
        if ED and ED.window and ED.window:IsShown() then
            ED:RefreshList()
            if ED.selectedKey then ED:FillForm(ED.selectedKey) end
        end
    end
    print(string.format(BT:L("IMPORT_SUCCESS"), count))
    return count
end

-- =========================================================================
-- Export actions
-- =========================================================================

function IE:ExportBoss(bossKey)
    local data = bossKey and BT_BossData and BT_BossData[bossKey]
    if not data then
        print(BT:L("EXPORT_EMPTY"))
        return
    end
    local str = self:ExportString({ type = "boss", key = bossKey, data = data })
    self:ShowExportDialog(str, bossKey)
end

function IE:ExportAll()
    local bosses = BT.db and BT.db.customBosses
    if not bosses or next(bosses) == nil then
        print(BT:L("EXPORT_CUSTOM_EMPTY"))
        return
    end
    local count = 0
    for _ in pairs(bosses) do count = count + 1 end
    local str = self:ExportString({ type = "all", bosses = bosses })
    self:ShowExportDialog(str, string.format(BT:L("EXPORT_ALL_LABEL"), count))
end

-- =========================================================================
-- Dialogs (children of the editor window — close with it, no globals)
-- =========================================================================

local function CreateDialog(titleText)
    local parent = (BT.Editor and BT.Editor.window) or UIParent
    local f = CreateFrame("Frame", nil, parent, "TooltipBackdropTemplate")
    f:SetSize(480, 300)
    f:SetPoint("CENTER", parent, "CENTER", 0, 0)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(s) s:StartMoving() end)
    f:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 12, -10)
    f.title:SetText(titleText)

    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.hint:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)

    if Theme then
        Theme:StyleWindow(f)
        Theme:StyleTitle(f.title)
    end

    return f
end

local function CreateDialogTextArea(f, bottomOffset)
    local inset = CreateFrame("Frame", nil, f, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", 10, -44)
    inset:SetPoint("BOTTOMRIGHT", -10, bottomOffset)

    local sf = CreateFrame("ScrollFrame", nil, inset, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 6, -6)
    sf:SetPoint("BOTTOMRIGHT", -26, 6)

    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetFontObject(GameFontHighlightSmall)
    eb:SetWidth(410)
    sf:SetScrollChild(eb)
    sf:EnableMouse(true)
    sf:SetScript("OnMouseDown", function() eb:SetFocus() end)

    return eb
end

-- ── Export dialog ──

function IE:ShowExportDialog(str, label)
    if not self.exportDlg then
        local f = CreateDialog(BT:L("EXPORT_TITLE"))
        self.exportDlg = f
        f.hint:SetText(BT:L("EXPORT_HINT"))
        f.eb = CreateDialogTextArea(f, 10)
        f.eb:SetScript("OnEditFocusGained", function(eb) eb:HighlightText() end)
        f.eb:SetScript("OnEscapePressed", function(eb)
            eb:ClearFocus()
            f:Hide()
        end)
        -- Read-only: any typing restores the export string
        f.eb:SetScript("OnTextChanged", function(eb, userInput)
            if userInput and f._str then
                eb:SetText(f._str)
                eb:HighlightText()
            end
        end)
        if Theme then Theme:StyleAddonTree(f) end
    end

    local f = self.exportDlg
    f.title:SetText(BT:L("EXPORT_TITLE") .. ": " .. (label or ""))
    f._str = str
    f.eb:SetText(str)
    f.eb:SetCursorPosition(0)
    f:Show()
    C_Timer.After(0.05, function()
        if f.eb:IsVisible() then
            f.eb:SetFocus()
            f.eb:HighlightText()
        end
    end)
end

-- ── Import dialog (paste -> preview -> confirm) ──

function IE:ShowImportDialog()
    if not self.importDlg then
        local f = CreateDialog(BT:L("IMPORT_TITLE"))
        self.importDlg = f
        f:SetHeight(340)
        f.hint:SetText(BT:L("IMPORT_HINT"))
        f.eb = CreateDialogTextArea(f, 78)

        f.preview = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.preview:SetPoint("BOTTOMLEFT", 12, 40)
        f.preview:SetPoint("BOTTOMRIGHT", -12, 40)
        f.preview:SetHeight(32)
        f.preview:SetJustifyH("LEFT")
        f.preview:SetJustifyV("BOTTOM")

        f.importBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.importBtn:SetSize(120, 22)
        f.importBtn:SetPoint("BOTTOMLEFT", 12, 10)
        f.importBtn:SetText(BT:L("BTN_IMPORT_DO"))
        f.importBtn:SetScript("OnClick", function()
            local payload, err = IE:DecodeString(f.eb:GetText())
            if not payload then
                f._pending = nil
                f.confirmBtn:Hide()
                f.preview:SetText("|cffff4444" .. (err or "?") .. "|r")
                return
            end
            local summary, count = IE:DescribePayload(payload)
            if count == 0 then
                f._pending = nil
                f.confirmBtn:Hide()
                f.preview:SetText("|cffff4444" .. BT:L("IMPORT_FAIL_DATA") .. "|r")
                return
            end
            f._pending = payload
            f.preview:SetText(summary)
            f.confirmBtn:Show()
        end)

        f.confirmBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        f.confirmBtn:SetSize(120, 22)
        f.confirmBtn:SetPoint("LEFT", f.importBtn, "RIGHT", 8, 0)
        f.confirmBtn:SetText(BT:L("BTN_CONFIRM"))
        f.confirmBtn:SetScript("OnClick", function()
            if f._pending then
                IE:ApplyPayload(f._pending)
                f._pending = nil
                f:Hide()
            end
        end)

        f.eb:SetScript("OnEscapePressed", function(eb)
            eb:ClearFocus()
            f:Hide()
        end)
        -- New text invalidates a pending preview
        f.eb:SetScript("OnTextChanged", function(_, userInput)
            if userInput then
                f._pending = nil
                f.confirmBtn:Hide()
                f.preview:SetText("")
            end
        end)
        if Theme then Theme:StyleAddonTree(f) end
    end

    local f = self.importDlg
    f._pending = nil
    f.confirmBtn:Hide()
    f.preview:SetText("")
    f.eb:SetText("")
    f:Show()
    C_Timer.After(0.05, function()
        if f.eb:IsVisible() then f.eb:SetFocus() end
    end)
end
