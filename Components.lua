-- Components.lua  (Boss Tactics)
-- Shared visual constants: role atlas icons, TLDR colors, difficulty badge
-- colors, TLDR bullet parsing/filtering, font safety helpers.
--
-- Design rule: all text uses NAMED FONT OBJECTS (GameFontNormal*,
-- GameFontHighlight*) — never SetFont with hardcoded px. Sizing is done via
-- the panel-wide scale multiplier (frame:SetScale).

local BT = BossTactics
local Theme = BT.Theme
local C = {}
BT.Components = C

-- Shared readability baseline for the large planning windows.  The mini
-- panel keeps its own independent scale/font-size controls.
C.DEFAULT_WORKSPACE_FONT_SCALE = 1.2

-- ─── Role icons (atlas-based, native LFG role art) ──────────────────────────

C.ROLE_ATLAS = {
    TANK   = "roleicon-tiny-tank",
    HEALER = "roleicon-tiny-healer",
    DPS    = "roleicon-tiny-dps",
}

-- Inline text markup for TLDR bullet prefixes.
-- Roles use atlas escapes; KICK uses Counterspell (fileID 132938) since no
-- interrupt role atlas exists.
C.TLDR_ICONS = {
    tank      = "|A:roleicon-tiny-tank:14:14|a",
    healer    = "|A:roleicon-tiny-healer:14:14|a",
    dps       = "|A:roleicon-tiny-dps:14:14|a",
    interrupt = "|T132938:13:13:0:0:64:64:5:59:5:59|t",
}

-- Text color per parsed role. "general" has no entry on purpose — general
-- bullets render in the font object's own color (GameFontHighlight white).
C.TLDR_COLORS = {
    tank      = "|cff0099ff",
    healer    = "|cff33cc33",
    dps       = "|cffff6633",
    interrupt = "|cffffcc00",
}

-- Difficulty badge colors, Dungeon Journal style
-- (green / blue / purple / orange).
C.DIFF_COLORS = {
    NORMAL      = "|cff1eff00",
    LFR         = "|cff1eff00",
    HEROIC      = "|cff0070dd",
    ["HEROIC+"] = "|cff0070dd",
    MYTHIC      = "|cffa335ee",
    ["MYTHIC+"] = "|cffff8000",
}

-- Compact difficulty badge labels for bullet lines
C.DIFF_SHORT = {
    NORMAL      = "N",
    HEROIC      = "H",
    MYTHIC      = "M",
    ["HEROIC+"] = "H+",
    ["MYTHIC+"] = "M+",
    LFR         = "LFR",
}

-- Localized labels for the difficulty line in the panel header
C.DIFF_LABEL_KEYS = {
    NORMAL = "DIFF_NORMAL",
    HEROIC = "DIFF_HEROIC",
    MYTHIC = "DIFF_MYTHIC",
    LFR    = "DIFF_LFR",
}

-- Ability type icons + colors for the expanded details view.
-- Icons: stable vanilla-era texture paths (guaranteed present in all clients)
-- + fileID 132938 (Counterspell) kept consistent with the KICK bullet icon;
-- CD types reuse the role atlases.
C.ABILITY_TYPES = {
    INTERRUPT = { icon = "|T132938:14:14:0:0:64:64:5:59:5:59|t",                                       color = "|cffffcc00" },
    SOAK      = { icon = "|TInterface\\Icons\\Spell_Nature_WispSplode:14:14:0:0:64:64:5:59:5:59|t",    color = "|cffff9933" },
    MOVEMENT  = { icon = "|TInterface\\Icons\\Ability_Rogue_Sprint:14:14:0:0:64:64:5:59:5:59|t",       color = "|cff66b3ff" },
    DISPEL    = { icon = "|TInterface\\Icons\\Spell_Holy_DispelMagic:14:14:0:0:64:64:5:59:5:59|t",     color = "|cff55dd88" },
    STOP      = { icon = "|TInterface\\Icons\\Ability_Warrior_Shockwave:14:14:0:0:64:64:5:59:5:59|t",    color = "|cffff9933" },
    TANK_CD   = { icon = "|A:roleicon-tiny-tank:14:14|a",                                              color = "|cff0099ff" },
    HEALER_CD = { icon = "|A:roleicon-tiny-healer:14:14|a",                                            color = "|cff33cc33" },
    PRIORITY_TARGET = { icon = "|TInterface\\Icons\\Ability_Hunter_MarkedForDeath:14:14:0:0:64:64:5:59:5:59|t", color = "|cffff6666" },
    UTILITY   = { icon = "|TInterface\\Icons\\INV_Misc_EngGizmos_18:14:14:0:0:64:64:5:59:5:59|t",     color = "|cffcc99ff" },
}

-- Role filter cycle order for the header toggle
C.ROLE_CYCLE = { "ALL", "TANK", "HEALER", "DPS" }

C.ROLE_LABEL_KEYS = {
    ALL    = "ROLE_ALL_SHORT",
    TANK   = "ROLE_TANK_SHORT",
    HEALER = "ROLE_HEALER_SHORT",
    DPS    = "ROLE_DPS_SHORT",
}

-- ─── TLDR bullet parsing ────────────────────────────────────────────────────

--- Extract role prefix from a bullet line.
--- Reconhece os prefixos atuais em português e os formatos históricos.
--- @return role string ("tank"/"healer"/"dps"/"interrupt"/"general"), cleanText
function C.ParseTLDRRole(line)
    local prefix, rest = line:match("^(%u+):%s*(.+)$")
    if not prefix then return "general", line end
    prefix = prefix:upper()
    if prefix == "TANQUE" or prefix == "TANK" then return "tank", rest end
    if prefix == "CURADOR" or prefix == "CURA"
        or prefix == "HEAL" or prefix == "HEALER" or prefix == "HEALING"
        or prefix == "STABILITY" or prefix == "SURVIVAL" then
        return "healer", rest
    end
    if prefix == "DPS" then return "dps", rest end
    if prefix == "INTERROMPER" or prefix == "KICK" or prefix == "INTERRUPT" then
        return "interrupt", rest
    end
    return "general", line
end

--- Resolve a TLDR bullet (string or {text=..., difficulty=...}) to
--- (localizedText, difficultyTag).
--- FIX vs old code: table-form (difficulty-tagged) bullets are localized too —
--- the old version passed b.text through raw, skipping Localize.
function C.ResolveTLDRBullet(b)
    if type(b) == "table" then
        return BT:Localize(b.text) or "", b.difficulty
    end
    return BT:Localize(b) or "", nil
end

--- Should a bullet with this parsed role be visible under the user filter?
--- Role buttons are strict views: only entries explicitly tagged for the
--- selected role are shown. ALL remains the complete encounter summary.
function C.RoleVisible(role, filter)
    filter = (filter or "ALL"):upper()
    if filter == "ALL" then return true end
    if filter == "TANK"   then return role == "tank" end
    if filter == "HEALER" then return role == "healer" end
    if filter == "DPS"    then return role == "dps" end
    return false
end

--- Filter + parse TLDR bullets by difficulty context and user role filter.
--- @param bullets table      raw boss.tldr array
--- @param difficulty string  runtime difficulty (Detection.activeDifficulty) or nil
--- @param roleFilter string  user filter: ALL/TANK/HEALER/DPS
--- @return table  array of { text=clean, role=parsed, difficulty=tag or nil }
function C.FilterTLDRBullets(bullets, difficulty, roleFilter)
    local out = {}
    if not bullets then return out end
    local D = BT.Detection
    for sourceIndex, b in ipairs(bullets) do
        local text, diff = C.ResolveTLDRBullet(b)
        if text ~= "" and D:AbilityMatchesDifficulty({ difficulty = diff }, difficulty) then
            local role, clean = C.ParseTLDRRole(text)
            if C.RoleVisible(role, roleFilter) then
                out[#out + 1] = {
                    text = clean,
                    role = role,
                    difficulty = diff,
                    sourceIndex = sourceIndex,
                }
            end
        end
    end
    return out
end

--- Render one filtered bullet entry to a display string:
--- role icon + optional compact difficulty badge + role-colored text.
--- General bullets get a grey • plus two spaces so their text starts at
--- roughly the same x position as text after the 14px role icons.
function C.FormatBullet(entry)
    local icon  = C.TLDR_ICONS[entry.role]
    local color = C.TLDR_COLORS[entry.role]
    local pfx   = icon and (icon .. " ") or "|cff999999\226\128\162|r  "

    local diffTag = ""
    if entry.difficulty then
        local up = entry.difficulty:upper()
        local dc = C.DIFF_COLORS[up] or "|cffff8000"
        local short = C.DIFF_SHORT[up]
            or (up:sub(1, 1) .. (up:find("%+", 1) and "+" or ""))
        diffTag = dc .. "[" .. short .. "]|r "
    end

    if color then
        return pfx .. diffTag .. color .. entry.text .. "|r"
    end
    return pfx .. diffTag .. entry.text
end

--- Compact colored difficulty badge (" [M+]") for a difficulty tag, or "".
function C.FormatDiffBadge(difficulty)
    if not difficulty then return "" end
    local up = difficulty:upper()
    local dc = C.DIFF_COLORS[up] or "|cffff8000"
    local short = C.DIFF_SHORT[up]
        or (up:sub(1, 1) .. (up:find("%+", 1) and "+" or ""))
    return " " .. dc .. "[" .. short .. "]|r"
end

--- Filter full ability entries by difficulty context + user role filter
--- (same semantics as TLDR bullets).
function C.FilterAbilities(abilities, difficulty, roleFilter)
    local out = {}
    local sourceIndices = {}
    if not abilities then return out, sourceIndices end
    local D = BT.Detection
    for sourceIndex, ab in ipairs(abilities) do
        if D:AbilityMatchesDifficulty(ab, difficulty)
            and D:RoleMatchesFilter(ab.role, roleFilter) then
            out[#out + 1] = ab
            sourceIndices[#out] = sourceIndex
        end
    end
    return out, sourceIndices
end

--- Ability card title line: type icon + title in type color + diff badge.
--- Unknown type: grey bullet, plain white title.
function C.FormatAbilityTitle(ability)
    local info = ability.type and C.ABILITY_TYPES[ability.type]
    local icon = info and info.icon or "|cff999999\226\128\162|r"
    local title = BT:Localize(ability.title) or ""
    local badge = C.FormatDiffBadge(ability.difficulty)
    if info then
        return icon .. " " .. info.color .. title .. "|r" .. badge
    end
    return icon .. "  " .. title .. badge
end

local TRASH_ACTION_KEYS = {
    INTERRUPT = "TRASH_ACTION_INTERRUPT",
    SOAK = "TRASH_ACTION_SOAK",
    MOVEMENT = "TRASH_ACTION_MOVE",
    DISPEL = "TRASH_ACTION_DISPEL",
    TANK_CD = "TRASH_ACTION_DEFENSIVE",
    HEALER_CD = "TRASH_ACTION_DEFENSIVE",
    PRIORITY_TARGET = "TRASH_ACTION_FOCUS",
    UTILITY = "TRASH_ACTION_UTILITY",
    STOP = "TRASH_ACTION_STOP",
}

--- Compact trash mechanic: [Ability] - colored ACTION.
function C.FormatTrashMechanic(entry)
    local kind = entry and entry.type or "UTILITY"
    local info = C.ABILITY_TYPES[kind]
    local color = info and info.color or "|cffffffff"
    local icon = info and info.icon or ""
    local ability = BT:Localize(entry and entry.title) or ""
    local actionKey = TRASH_ACTION_KEYS[kind] or "TRASH_ACTION_WATCH"
    return icon .. " |cffffffff[" .. ability .. "]|r  -  " .. color .. BT:L(actionKey) .. "|r"
end

function C.SortTrashEntries(entries)
    table.sort(entries, function(a, b)
        local ap, bp = tonumber(a.priority) or 99, tonumber(b.priority) or 99
        if ap ~= bp then return ap < bp end
        local ae = BT:Localize(a.enemy) or ""
        local be = BT:Localize(b.enemy) or ""
        if ae ~= be then return ae < be end
        return (BT:Localize(a.title) or "") < (BT:Localize(b.title) or "")
    end)
    return entries
end

-- ─── Shared boss-data helpers (editor / journal) ────────────────────────────

--- Resolve a boss's dungeon name (plain string or {en=...} table form).
function C.ResolveDungeonName(data)
    local dName = data and data.dungeonName
    if type(dName) == "table" then dName = dName.en or dName.enUS end
    return dName
end

function C.IsRaidData(data)
    return type(data) == "table" and data.isRaid == true
end

function C.IsDungeonDifficultySelectionEnabled()
    return BT.Config and BT.Config.dungeonDifficultySelectionEnabled == true
end

--- Resolve a requested difficulty without touching detection or stored plans.
--- Dungeons are fixed to Normal while the internal switch is disabled.
function C.ResolveContentDifficulty(data, requested)
    if not C.IsRaidData(data) and not C.IsDungeonDifficultySelectionEnabled() then
        return "NORMAL"
    end
    requested = requested == "LFR" and "NORMAL" or requested
    if requested == "NORMAL" or requested == "HEROIC" or requested == "MYTHIC" then
        return requested
    end
    return "NORMAL"
end

function C.ShouldShowDifficultySelector(data)
    if type(data) ~= "table" then return false end
    return C.IsRaidData(data) or C.IsDungeonDifficultySelectionEnabled()
end

-- Explicit content metadata. Instance names are stable data keys; keeping the
-- season map here avoids repeating the same field on every boss entry.
C.INSTANCE_SEASON = {
    -- Midnight Season 1
    ["Magister's Terrace"] = 1, ["Maisara Caverns"] = 1,
    ["Nexus Point Xenas"] = 1, ["Windrunner Spire"] = 1,
    ["Algeth'ar Academy"] = 1, ["Seat of the Triumvirate"] = 1,
    ["Skyreach"] = 1, ["Pit of Saron"] = 1,
    ["The Voidspire"] = 1, ["The Dreamrift"] = 1,
    ["March on Quel'Danas"] = 1,

    -- Midnight Season 2
    ["Altar of Fangs"] = 2, ["Murder Row"] = 2,
    ["Den of Nalorakk"] = 2, ["The Blinding Vale"] = 2,
    ["Voidscar Arena"] = 2, ["Ruby Life Pools"] = 2,
    ["Temple of Sethraliss"] = 2, ["Kings' Rest"] = 2,
    ["The Venomous Abyss"] = 2,
    ["The Tidebound Grotto"] = 2,   -- Lair (single-boss raid instance)
}

function C.ResolveSeason(data)
    local season = data and tonumber(data.season)
    if season == 1 or season == 2 then return season end
    return C.INSTANCE_SEASON[C.ResolveDungeonName(data)]
end

function C.ContentSection(data)
    local season = C.ResolveSeason(data)
    if season == 2 then
        return data and data.isRaid and "S2_RAIDS" or "S2_DUNGEONS"
    elseif season == 1 then
        return data and data.isRaid and "S1_RAIDS" or "S1_DUNGEONS"
    end
    return "CUSTOM_OTHER"
end

--- All string boss keys sorted by: dungeons first, raids last, then dungeon
--- name, then journal order.
function C.SortedBossKeys()
    local keys = {}
    if not BT_BossData then return keys end
    for k, v in pairs(BT_BossData) do
        if type(k) == "string" and type(v) == "table" then
            keys[#keys + 1] = k
        end
    end
    table.sort(keys, function(a, b)
        local da, dbb = BT_BossData[a], BT_BossData[b]
        local sa, sb = C.ResolveSeason(da), C.ResolveSeason(dbb)
        local sra = sa == 2 and 0 or (sa == 1 and 1 or 2)
        local srb = sb == 2 and 0 or (sb == 1 and 1 or 2)
        if sra ~= srb then return sra < srb end
        local ra = da.isRaid and 1 or 0
        local rb = dbb.isRaid and 1 or 0
        if ra ~= rb then return ra < rb end
        local na = C.ResolveDungeonName(da) or "~"
        local nb = C.ResolveDungeonName(dbb) or "~"
        if na ~= nb then return na < nb end
        local ea = da.journalOrder or da.encounterID or 999999
        local eb = dbb.journalOrder or dbb.encounterID or 999999
        if ea ~= eb then return ea < eb end
        return a < b
    end)
    return keys
end

-- ─── Chat prefill (shared: mini panel share + journal share buttons) ────────
-- The only sanctioned send path in WoW 12.0+: pre-fill the editbox, the user
-- presses Enter. One click = one message, no hooks, no queues.

local SLASH_MAP = {
    PARTY         = "/p ",
    RAID          = "/raid ",
    INSTANCE_CHAT = "/i ",
    SAY           = "/s ",
}

-- Legacy enum may be absent in future clients
local PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE or 2

function C.ResolveChannel(preference)
    preference = preference or (BT.db and BT.db.shareChannel) or "AUTO"
    -- Groups formed by the Dungeon Finder / LFR / battleground queues are
    -- "instance" groups: PARTY and RAID chat do not exist for them and the
    -- only working channel is INSTANCE_CHAT. Premade groups (manual invites,
    -- Group Finder listings) are "home" groups and use PARTY/RAID as usual.
    local inInstanceGroup = IsInGroup(PARTY_CATEGORY_INSTANCE)
    local inHomeGroup = IsInGroup(LE_PARTY_CATEGORY_HOME or 1)

    if preference == "INSTANCE_CHAT" then
        if inInstanceGroup then
            return "INSTANCE_CHAT"
        elseif IsInRaid() then
            return "RAID"
        elseif IsInGroup() then
            return "PARTY"
        end
        return "SAY"
    elseif preference == "PARTY" or preference == "RAID" then
        -- An explicit /p or /raid preference cannot be honoured inside an
        -- instance-only group; route it to the channel that actually works.
        if inInstanceGroup and not inHomeGroup then
            return "INSTANCE_CHAT"
        end
        return preference
    elseif preference == "SAY" then
        return preference
    end

    -- AUTO: prefer the group's real channel. Zone type alone must not select
    -- /instance (a premade group inside a dungeon has no instance chat), so
    -- the decision is based purely on group category.
    if inInstanceGroup and not inHomeGroup then
        return "INSTANCE_CHAT"
    elseif IsInRaid() then
        return "RAID"
    elseif IsInGroup() then
        return "PARTY"
    end
    return "SAY"
end

--- Strip everything SendChatMessage rejects: UI escape sequences (colors,
--- textures, atlases) and any remaining raw "|" (invalid escape in chat).
function C.SanitizeChatText(text)
    text = tostring(text or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    text = text:gsub("|T[^|]*|t", "")
    text = text:gsub("|A[^|]*|a", "")
    text = text:gsub("|", "/")
    text = text:gsub("[%c]", " ")
    text = text:gsub("%s+", " ")
    return text
end

function C.PreFillChat(msg, chatType)
    if not msg or msg == "" then return end
    msg = C.SanitizeChatText(msg)
    msg = C.AppendShareSignature(msg)
    -- Text an addon writes into the chat box is tainted, so in restricted
    -- content the player's Enter would silently do nothing. Offer a copy box.
    if C.IsChatRestricted and C.IsChatRestricted() then
        print(BT:L("MSG_CHAT_RESTRICTED"))
        C.ShowChatCopyWindow(msg:match("^%[(.-)%]") or "", { msg })
        return
    end
    local slash = SLASH_MAP[chatType] or "/p "
    ChatFrame_OpenChat(slash .. msg)
end

-- Visible chat is capped at 255 bytes per message. Keep room for the boss and
-- sequence prefix and split only at byte-safe word boundaries. One TLDR bullet
-- normally becomes one chat message, which is much easier to scan than a
-- truncated wall of text.
local CHAT_SAFE_BYTES = 240

local function TrimLabel(text, maxBytes)
    text = C.SanitizeChatText(text)
    if #text <= maxBytes then return strtrim(text) end
    local cut = maxBytes
    local space = text:sub(1, cut):match("^.*()%s")
    if space and space > math.floor(maxBytes / 2) then cut = space - 1 end
    while cut > 0 do
        local nextByte = text:byte(cut + 1)
        if not nextByte or nextByte < 128 or nextByte > 191 then break end
        cut = cut - 1
    end
    return strtrim(text:sub(1, cut))
end

function C.GetShareSignature()
    if BT.db and BT.db.shareSignature == false then return nil end
    local signature = strtrim(C.SanitizeChatText(BT:L("SHARE_SIGNATURE")))
    return signature ~= "" and signature or nil
end

--- Add the optional credit to a single pre-filled line without exceeding the
--- conservative 240-byte chat payload. This path is used by per-ability share.
function C.AppendShareSignature(text)
    text = strtrim(C.SanitizeChatText(text))
    local signature = C.GetShareSignature()
    if not signature then return text end
    local available = CHAT_SAFE_BYTES - #signature - 1
    return TrimLabel(text, math.max(40, available)) .. " " .. signature
end

local function SplitChatText(text, maxBytes, out)
    text = strtrim(C.SanitizeChatText(text))
    while text ~= "" do
        if #text <= maxBytes then
            out[#out + 1] = text
            return
        end
        local cut = maxBytes
        local space = text:sub(1, cut):match("^.*()%s")
        if space and space > math.floor(maxBytes / 2) then
            cut = space - 1
        else
            while cut > 0 do
                local nextByte = text:byte(cut + 1)
                if not nextByte or nextByte < 128 or nextByte > 191 then break end
                cut = cut - 1
            end
        end
        if cut < 1 then return end
        out[#out + 1] = strtrim(text:sub(1, cut))
        text = strtrim(text:sub(cut + 1))
    end
end

function C.BuildChatLines(label, parts)
    label = TrimLabel(label, 60)
    local worstPrefix = "[" .. label .. " 99/99] "
    local bodyMax = math.max(80, CHAT_SAFE_BYTES - #worstPrefix)
    local bodies = {}
    for _, part in ipairs(parts or {}) do
        SplitChatText(part, bodyMax, bodies)
    end
    local lines = {}
    local total = #bodies
    for i, body in ipairs(bodies) do
        local prefix = total > 1
            and ("[" .. label .. " " .. i .. "/" .. total .. "] ")
            or ("[" .. label .. "] ")
        lines[#lines + 1] = prefix .. body
    end
    return lines
end

-- ─── 12.x addon chat restrictions ───────────────────────────────────────────
-- Blizzard's rule (12.0 alpha notes, relaxed Oct 2025; unchanged in 12.1):
-- addons may not send chat while a Mythic+ run is active and incomplete, a
-- PvP match is in progress, or an instance encounter is in progress --
-- "tools that facilitate sharing information before or after combat won't
-- be impacted". The client refuses SendChatMessage silently in that state
-- (ADDON_ACTION_BLOCKED, no Lua error). The authoritative query is
-- C_ChatInfo.InChatMessagingLockdown() (12.0.0); the restriction types in
-- C_RestrictedActions give the same picture. 'Map' (the "restricted map"
-- flag, true in any raid/M+ zone) is deliberately NOT treated as a block:
-- sharing before/after combat on those maps is allowed.
-- In the locked state the only remaining path is the one a player would
-- use: put the text in the chat edit box and let them press Enter.

local RESTRICTION_KEYS = { "Combat", "Encounter", "ChallengeMode", "PvPMatch", "Chat" }

local ChatSendRestricted   -- forward declaration, exposed as C.IsChatRestricted

function ChatSendRestricted()
    if InCombatLockdown and InCombatLockdown() then return true end
    if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown
        and C_ChatInfo.InChatMessagingLockdown() then
        return true
    end
    local RA = C_RestrictedActions
    local T = Enum and Enum.AddOnRestrictionType
    if RA and RA.IsAddOnRestrictionActive and T then
        for _, key in ipairs(RESTRICTION_KEYS) do
            if T[key] ~= nil and RA.IsAddOnRestrictionActive(T[key]) then
                return true
            end
        end
    end
    return false
end

C.IsChatRestricted = function() return ChatSendRestricted() end

-- Empirical backstop: if the client blocks one of our sends anyway (rule we
-- did not anticipate), notice it synchronously and stop trying until the
-- restriction state or zone changes, so the player never sees a stream of
-- ADDON_ACTION_BLOCKED errors.
local blockWatcher = CreateFrame("Frame")
local sendWasBlocked = false
local directSendBlockedHere = false
blockWatcher:RegisterEvent("ADDON_ACTION_BLOCKED")
blockWatcher:RegisterEvent("ADDON_ACTION_FORBIDDEN")
blockWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
pcall(blockWatcher.RegisterEvent, blockWatcher, "ADDON_RESTRICTION_STATE_CHANGED")
blockWatcher:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        if addonName == BT.ADDON_NAME then
            sendWasBlocked = true
        end
    else
        directSendBlockedHere = false
    end
end)

--- Send one line directly. Returns true when the client accepted the call.
local function SendVisibleChatLine(line, chatType)
    sendWasBlocked = false
    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        C_ChatInfo.SendChatMessage(line, chatType)
    elseif SendChatMessage then
        SendChatMessage(line, chatType)
    else
        return false
    end
    if sendWasBlocked then
        directSendBlockedHere = true
        return false
    end
    return true
end

-- ─── Copy-to-chat window (restricted content) ───────────────────────────────
-- In restricted content Retail 12.x blocks SendChatMessage from addons, and it
-- also blocks sending text that an addon put into the chat edit box: the box
-- becomes tainted, so the player's Enter silently does nothing. The only thing
-- left is a plain copy box -- the player copies the text and pastes it, which
-- is user input and therefore untainted.

local copyWindow

local function BuildCopyWindow()
    local f = CreateFrame("Frame", "BossTacticsChatCopyFrame", UIParent, "TooltipBackdropTemplate")
    f:SetSize(520, 280)
    f:SetPoint("CENTER")
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(w) w:StartMoving() end)
    f:SetScript("OnDragStop", function(w) w:StopMovingOrSizing() end)
    tinsert(UISpecialFrames, "BossTacticsChatCopyFrame")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 12, -10)

    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.hint:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -3)
    f.hint:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, 0)
    f.hint:SetJustifyH("LEFT")

    local inset = CreateFrame("Frame", nil, f, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", 10, -46)
    inset:SetPoint("BOTTOMRIGHT", -10, 36)

    local sf = CreateFrame("ScrollFrame", nil, inset, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 6, -6)
    sf:SetPoint("BOTTOMRIGHT", -26, 6)

    local eb = CreateFrame("EditBox", nil, sf)
    f.eb = eb
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetFontObject(ChatFontNormal)
    eb:SetWidth(460)
    sf:SetScrollChild(eb)
    sf:EnableMouse(true)
    sf:SetScript("OnMouseDown", function() eb:SetFocus() end)
    eb:SetScript("OnEditFocusGained", function(box) box:HighlightText() end)
    eb:SetScript("OnEscapePressed", function(box) box:ClearFocus(); f:Hide() end)
    -- Read-only: typing restores whatever is currently on display
    eb:SetScript("OnTextChanged", function(box, userInput)
        if userInput and f._shown then
            box:SetText(f._shown)
            box:HighlightText()
        end
    end)

    local function Display(text)
        f._shown = text
        eb:SetText(text)
        eb:SetCursorPosition(0)
        eb:SetFocus()
        eb:HighlightText()
    end
    f.Display = Display

    f.allBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.allBtn:SetSize(60, 20)
    f.allBtn:SetPoint("BOTTOMLEFT", 10, 10)
    f.allBtn:SetScript("OnClick", function()
        f._index = nil
        Display(table.concat(f._lines, "\n"))
        f.counter:SetText(BT:L("COPY_ALL_LABEL"))
    end)

    local function ShowLine(i)
        local total = #f._lines
        if total == 0 then return end
        if i < 1 then i = total elseif i > total then i = 1 end
        f._index = i
        Display(f._lines[i])
        f.counter:SetText(i .. " / " .. total)
    end

    f.prevBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.prevBtn:SetSize(24, 20)
    f.prevBtn:SetText("<")
    f.prevBtn:SetPoint("LEFT", f.allBtn, "RIGHT", 8, 0)
    f.prevBtn:SetScript("OnClick", function() ShowLine((f._index or 1) - 1) end)

    f.counter = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.counter:SetPoint("LEFT", f.prevBtn, "RIGHT", 6, 0)
    f.counter:SetWidth(70)
    f.counter:SetJustifyH("CENTER")

    f.nextBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.nextBtn:SetSize(24, 20)
    f.nextBtn:SetText(">")
    f.nextBtn:SetPoint("LEFT", f.counter, "RIGHT", 6, 0)
    f.nextBtn:SetScript("OnClick", function() ShowLine((f._index or 0) + 1) end)

    if Theme then
        Theme:StyleWindow(f)
        Theme:StyleAddonTree(f)
        Theme:StyleTitle(f.title)
    end

    return f
end

--- Show the share text so the player can copy it out by hand.
function C.ShowChatCopyWindow(label, lines)
    copyWindow = copyWindow or BuildCopyWindow()
    local f = copyWindow
    f._lines = lines
    f._index = nil
    f.title:SetText(BT:L("COPY_TITLE") .. ": " .. tostring(label or ""))
    f.hint:SetText(BT:L("COPY_HINT"))
    f.allBtn:SetText(BT:L("COPY_ALL_LABEL"))
    f.counter:SetText(BT:L("COPY_ALL_LABEL"))
    f:Show()
    f.Display(table.concat(lines, "\n"))
end

--- /bosstactics chatdebug — print everything that decides how Share sends, so the
--- permite verificar em jogo as regras de restrição do chat.
function C.ChatDebug()
    local function b(v) if v then return "sim" else return "não" end end
    local RA, T = C_RestrictedActions, Enum and Enum.AddOnRestrictionType
    local inInst, instType = IsInInstance()
    local diff = select(3, GetInstanceInfo())
    print("|cffcc99ffBoss Tactics chatdebug|r")
    print("  versão: " .. tostring(select(4, GetBuildInfo())))
    print("  instância: " .. b(inInst) .. " (" .. tostring(instType) .. ", dificuldade " .. tostring(diff) .. ")")
    print("  grupo: comum=" .. b(IsInGroup(LE_PARTY_CATEGORY_HOME or 1))
        .. " instância=" .. b(IsInGroup(PARTY_CATEGORY_INSTANCE))
        .. " raide=" .. b(IsInRaid()))
    print("  bloqueio de combate: " .. b(InCombatLockdown and InCombatLockdown()))
    if RA and RA.IsAddOnRestrictionActive and T then
        local parts = {}
        for _, key in ipairs({ "Combat", "Encounter", "ChallengeMode", "PvPMatch", "Map", "Chat" }) do
            if T[key] ~= nil then
                parts[#parts + 1] = key .. "=" .. b(RA.IsAddOnRestrictionActive(T[key]))
            else
                parts[#parts + 1] = key .. "=n/a"
            end
        end
        print("  restrições: " .. table.concat(parts, " "))
    else
        print("  restrições: C_RestrictedActions indisponível")
    end
    if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown then
        print("  InChatMessagingLockdown: " .. b(C_ChatInfo.InChatMessagingLockdown()))
    end
    if C_ChatInfo and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted then
        print("  AreOutgoingAddonChatMessagesRestricted (realm): " .. b(C_ChatInfo.AreOutgoingAddonChatMessagesRestricted()))
    end
    print("  canal AUTO -> " .. tostring(C.ResolveChannel("AUTO"))
        .. ", preferência '" .. tostring(BT.db and BT.db.shareChannel or "AUTO")
        .. "' -> " .. tostring(C.ResolveChannel()))
    print("  envio direto bloqueado aqui (persistente): " .. b(directSendBlockedHere))
    print("  método: " .. ((directSendBlockedHere or ChatSendRestricted()) and "janela de cópia (colar manualmente)" or "SendChatMessage direto"))
end

function C.BuildSignedChatLines(label, parts)
    local lines = C.BuildChatLines(label, parts)
    if #lines == 0 then return lines end

    local signature = C.GetShareSignature()
    if signature then
        local candidate = lines[#lines] .. " " .. signature
        if #candidate <= CHAT_SAFE_BYTES then
            lines[#lines] = candidate
        else
            lines[#lines + 1] = "[" .. TrimLabel(label, 60) .. "] " .. signature
        end
    end
    return lines
end

function C.SendChatParts(label, parts, chatType)
    chatType = chatType or C.ResolveChannel()
    local lines = C.BuildSignedChatLines(label, parts)
    if #lines == 0 then return 0 end

    -- Restricted content (12.x): the client refuses addon chat entirely, so
    -- offer the text for manual copy instead of pretending it was sent.
    if directSendBlockedHere or ChatSendRestricted() then
        print(BT:L("MSG_CHAT_RESTRICTED"))
        C.ShowChatCopyWindow(label, lines)
        return 0
    end

    -- Direct sends must stay synchronous with the Share click: SendChatMessage
    -- also needs the originating hardware event, which a C_Timer callback
    -- no longer has.
    local sent = 0
    for i, line in ipairs(lines) do
        if not SendVisibleChatLine(line, chatType) then
            print(BT:L("MSG_CHAT_RESTRICTED"))
            C.ShowChatCopyWindow(label, lines)
            return sent
        end
        sent = sent + 1
    end
    print(string.format(BT:L("FMT_SHARE_LINES"), sent, chatType:lower()))
    return sent
end

-- ─── Boss list widget (shared by editor + journal) ──────────────────────────
-- Search box + dungeon-grouped pooled rows in a native scroll list.
-- Returns { frame, searchBox, selectedKey, Refresh(self), SetSelected(self, key) }.

local LIST_ROW_H = 22

function C.CreateBossList(parent, width, onSelect, getStatus)
    local W = {}
    W.selectedKey = nil
    W.collapsedSections = {}
    W.collapsedDungeons = {}
    W.rowHeight = LIST_ROW_H
    W.sectionFont = GameFontNormalLarge or GameFontNormal
    W.dungeonFont = GameFontNormal or GameFontHighlight
    W.rowFont = GameFontHighlight
    W.statusFont = GameFontDisableSmall

    local frame = CreateFrame("Frame", nil, parent)
    W.frame = frame
    frame:SetWidth(width)

    local search
    local okSearch = pcall(function()
        search = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
    end)
    if not okSearch or not search then
        search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    end
    W.searchBox = search
    search:SetSize(width - 6, 20)
    search:SetPoint("TOPLEFT", 4, 0)
    search:SetAutoFocus(false)
    search:HookScript("OnTextChanged", function() W:Refresh() end)
    search:SetScript("OnEscapePressed", function(e) e:ClearFocus() end)

    local inset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", 0, -26)
    inset:SetPoint("BOTTOMRIGHT", 0, 0)

    local scroll = CreateFrame("ScrollFrame", nil, inset, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -24, 4)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(width - 28, 10)
    scroll:SetScrollChild(content)

    local rowPool = CreateFramePool("Button", content)
    local headerPool = CreateFramePool("Button", content)
    local sectionPool = CreateFramePool("Button", content)

    local function PrepareGroupButton(button, fontObject)
        if not button.label then
            button.label = button:CreateFontString(nil, "ARTWORK")
            button.label:SetPoint("LEFT", 2, 0)
            button.label:SetPoint("RIGHT", -2, 0)
            button.label:SetJustifyH("LEFT")
            button.label:SetWordWrap(false)
            local hl = button:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(0.4, 0.75, 1, 0.08)
        end
        button.label:SetFontObject(fontObject)
    end

    function W:SetSelected(key)
        self.selectedKey = key
        self:Refresh()
    end

    function W:SetWidth(newWidth)
        newWidth = math.max(180, math.floor((newWidth or width) + 0.5))
        if newWidth == width then return end
        width = newWidth
        frame:SetWidth(newWidth)
        search:SetWidth(newWidth - 6)
        content:SetWidth(math.max(120, newWidth - 28))
        self:Refresh()
    end

    function W:SetFontObjects(sectionFont, dungeonFont, rowFont, rowHeight, statusFont)
        self.sectionFont = sectionFont or self.sectionFont
        self.dungeonFont = dungeonFont or self.dungeonFont
        self.rowFont = rowFont or self.rowFont
        self.statusFont = statusFont or self.statusFont
        self.rowHeight = math.max(18, math.floor((rowHeight or LIST_ROW_H) + 0.5))
        self:Refresh()
    end

    function W:Refresh()
        rowPool:ReleaseAll()
        headerPool:ReleaseAll()
        sectionPool:ReleaseAll()

        local filter = strtrim((search:GetText() or ""):lower())
        local customs = (BT.db and BT.db.customBosses) or {}
        local y = 0
        local lastSection = nil
        local lastDungeon = nil
        local sectionCollapsed = false
        local dungeonCollapsed = false
        local w = content:GetWidth()
        local rowHeight = self.rowHeight or LIST_ROW_H

        for _, key in ipairs(C.SortedBossKeys()) do
            local bossData = BT_BossData[key]
            local dn = C.ResolveDungeonName(bossData) or "?"
            local matches = filter == "" or key:lower():find(filter, 1, true)
                or dn:lower():find(filter, 1, true)
            if matches then
                local section = C.ContentSection(bossData)
                if section ~= lastSection then
                    lastSection = section
                    lastDungeon = nil
                    sectionCollapsed = filter == "" and self.collapsedSections[section] or false
                    local sec = sectionPool:Acquire()
                    PrepareGroupButton(sec, self.sectionFont)
                    sec:SetSize(w, rowHeight + 4)
                    sec:SetPoint("TOPLEFT", content, "TOPLEFT", 2, y - 3)
                    sec.label:SetText("|cff66ccff" .. (sectionCollapsed and "+ " or "- ")
                        .. BT:L("LIST_" .. section) .. "|r")
                    local sectionKey = section
                    sec:SetScript("OnClick", function()
                        W.collapsedSections[sectionKey] = not W.collapsedSections[sectionKey]
                        W:Refresh()
                    end)
                    sec:Show()
                    y = y - rowHeight - 6
                end
                if not sectionCollapsed and dn ~= lastDungeon then
                    lastDungeon = dn
                    local dungeonKey = section .. "\031" .. dn
                    dungeonCollapsed = filter == "" and self.collapsedDungeons[dungeonKey] or false
                    local hdr = headerPool:Acquire()
                    PrepareGroupButton(hdr, self.dungeonFont)
                    hdr:SetSize(w, rowHeight)
                    hdr:SetPoint("TOPLEFT", content, "TOPLEFT", 2, y - 3)
                    -- Raid groups stand out in orange (sorted to the bottom)
                    local prefix = dungeonCollapsed and "+ " or "- "
                    if bossData.isRaid then
                        hdr.label:SetText("|cffff8800" .. prefix .. dn .. "|r")
                    else
                        hdr.label:SetText(prefix .. dn)
                    end
                    hdr:SetScript("OnClick", function()
                        W.collapsedDungeons[dungeonKey] = not W.collapsedDungeons[dungeonKey]
                        W:Refresh()
                    end)
                    hdr:Show()
                    y = y - rowHeight - 4
                end

                if not sectionCollapsed and not dungeonCollapsed then
                    local row = rowPool:Acquire()
                    if not row.label then
                        row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
                        row.label:SetPoint("LEFT", 10, 0)
                        row.label:SetJustifyH("LEFT")
                        row.label:SetWordWrap(false)
                        row.status = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
                        row.status:SetPoint("RIGHT", -4, 0)
                        row.status:SetJustifyH("RIGHT")
                        row.label:SetPoint("RIGHT", row.status, "LEFT", -6, 0)
                        local hl = row:CreateTexture(nil, "HIGHLIGHT")
                        hl:SetAllPoints()
                        hl:SetColorTexture(1, 1, 1, 0.08)
                    end
                    row.label:SetFontObject(self.rowFont)
                    row.status:SetFontObject(self.statusFont)
                    row:SetSize(w, rowHeight)
                    row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
                    local marker = customs[key] and "|cffcc66ff*|r " or ""
                    row.label:SetText(marker .. key)
                    local statusText = getStatus and getStatus(key, bossData) or nil
                    row.status:SetText(statusText or "")
                    row.status:SetShown(statusText ~= nil and statusText ~= "")
                    if key == self.selectedKey then
                        row.label:SetTextColor(1, 0.82, 0, 1)
                    else
                        row.label:SetTextColor(0.9, 0.9, 0.9, 1)
                    end
                    local rowKey = key
                    row:SetScript("OnClick", function()
                        local accepted = onSelect and onSelect(rowKey)
                        if accepted ~= false then
                            W.selectedKey = rowKey
                            W:Refresh()
                        end
                    end)
                    row:Show()
                    y = y - rowHeight
                end
            end
        end

        content:SetHeight(math.max(-y, 10))
    end

    return W
end

--- Large white label font for options/editor forms. Named objects only.
function C.ApplyLabelFont(fs)
    if GameFontHighlightLarge then
        fs:SetFontObject(GameFontHighlightLarge)
    else
        fs:SetFontObject(GameFontNormalLarge or GameFontNormal)
        fs:SetTextColor(1, 1, 1, 1)
    end
end

-- ─── User font customization (mini panel) ───────────────────────────────────
-- db.fontFace (path or nil = font object default) + db.fontSize (10–20 or
-- nil). Applied ON TOP of named font objects; Cyrillic-unsafe faces are
-- swapped via NormalizeFontPath on ruRU clients.

C.FONT_FACES = {
    { label = nil,             value = nil },   -- label filled from FONT_DEFAULT at runtime
    { label = "Friz Quadrata", value = "Fonts\\FRIZQT__.TTF" },
    { label = "Arial Narrow",  value = "Fonts\\ARIALN.TTF" },
    { label = "2002",          value = "Fonts\\2002.TTF" },
    { label = "Morpheus",      value = "Fonts\\MORPHEUS.TTF" },
    { label = "Skurri",        value = "Fonts\\SKURRI.TTF" },
}

--- Re-anchor a font string to its base font object, then apply the user's
--- custom face/size when set. kind: "title" (+3px), "body", "small" (-2px).
function C.ApplyPanelFont(fs, kind, baseObject)
    if baseObject then
        fs:SetFontObject(baseObject)
    end
    local db = BT.db or {}
    local face, size = db.fontFace, db.fontSize
    if not face and not size then return end   -- default look untouched
    local curFace, curSize, flags = fs:GetFont()
    face = C:NormalizeFontPath(face or curFace)
    size = size or curSize or 12
    if kind == "title" then
        size = size + 3
    elseif kind == "small" then
        size = math.max(9, size - 2)
    end
    local ok = fs:SetFont(face, size, flags or "")
    if not ok and baseObject then
        fs:SetFontObject(baseObject)
    end
end

-- ─── Font safety (Cyrillic fallback — retained from UIComponents.lua) ───────
-- Named font objects are locale-safe (the ruRU client ships Cyrillic-capable
-- fonts in them), so the mini panel never needs path-based fonts. These
-- helpers are kept for any future path-based font use.

local KNOWN_UNSAFE_CYRILLIC_FONTS = {
    ["FONTS\\FRIZQT__.TTF"] = true,
    ["FONTS\\2002.TTF"]     = true,
    ["FONTS\\2002B.TTF"]    = true,
    ["FONTS\\MORPHEUS.TTF"] = true,
    ["FONTS\\SKURRI.TTF"]   = true,
    ["FONTS\\NIM_____.TTF"] = true,
}

function C:IsCyrillicLocale()
    return BT.CurrentLocale == "ruRU"
end

function C:GetCyrillicSafeFont()
    return STANDARD_TEXT_FONT or "Fonts\\ARIALN.TTF"
end

--- Swap fonts known to lack Cyrillic glyphs for the client's standard font.
function C:NormalizeFontPath(path)
    if not path or path == "" then
        return self:GetCyrillicSafeFont()
    end
    if self:IsCyrillicLocale() and KNOWN_UNSAFE_CYRILLIC_FONTS[string.upper(path)] then
        return self:GetCyrillicSafeFont()
    end
    return path
end
