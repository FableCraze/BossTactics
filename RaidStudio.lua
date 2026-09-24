-- RaidStudio.lua  (Boss Tactics)
-- Raid Lead Studio MVP: turn shipped boss tactics into a saved, ordered pull
-- briefing with custom assignments/notes and WoW/Discord/plain-text output.
-- Source-linked blocks resolve from BT_BossData at render time, so they follow
-- the selected addon language and future tactic corrections until edited.

local BT = BossTactics
local C = BT.Components
local D = BT.Detection
local Theme = BT.Theme

local RS = {}
BT.RaidStudio = RS

RS.selectedKey = nil
RS.difficulty = nil
RS.outputFormat = "WOW"
RS.outputScope = "BOSS"
RS.editorKind = "MECHANIC"
RS.selectedBlock = nil
RS.validatedPlans = setmetatable({}, { __mode = "k" })
RS.undoStacks = {}                         -- session-only, per boss+difficulty

local DIFF_CYCLE = { "NORMAL", "HEROIC", "MYTHIC" }
local OUTPUT_CYCLE = { "WOW", "DISCORD", "PLAIN" }
local BLOCK_KINDS = { "PHASE", "MECHANIC", "ASSIGNMENT", "NOTE", "MARKER", "COOLDOWN" }
local PRESET_CYCLE = { "QUICK_PUG", "DETAILED_PUG", "GUILD_PROGRESSION" }
local VALID_KIND = {}
for _, kind in ipairs(BLOCK_KINDS) do VALID_KIND[kind] = true end
local VALID_PRESET = { CUSTOM = true }
for _, preset in ipairs(PRESET_CYCLE) do VALID_PRESET[preset] = true end

local PRESET_LABEL_KEYS = {
    QUICK_PUG = "RL_PRESET_QUICK",
    DETAILED_PUG = "RL_PRESET_DETAILED",
    GUILD_PROGRESSION = "RL_PRESET_GUILD",
    CUSTOM = "RL_PRESET_CUSTOM",
}

local ASSIGNMENT_SLOTS = {
    { id = "TANK_PAIR", kind = "ASSIGNMENT", textKey = "RL_SLOT_TANK_PAIR" },
    { id = "HEALERS", kind = "ASSIGNMENT", textKey = "RL_SLOT_HEALERS" },
    { id = "MELEE_RANGED", kind = "ASSIGNMENT", textKey = "RL_SLOT_MELEE_RANGED" },
    { id = "GROUPS", kind = "ASSIGNMENT", textKey = "RL_SLOT_GROUPS" },
    { id = "SIDES", kind = "ASSIGNMENT", textKey = "RL_SLOT_SIDES" },
    { id = "ODD_EVEN", kind = "ASSIGNMENT", textKey = "RL_SLOT_ODD_EVEN" },
    { id = "MARKERS", kind = "MARKER", textKey = "RL_SLOT_MARKERS" },
    { id = "COOLDOWNS", kind = "COOLDOWN", textKey = "RL_SLOT_COOLDOWNS" },
}

local VALID_TEXT_KEYS = { RL_CORE_MECHANICS = true, RL_DETAILED_NOTES = true,
    RL_GUILD_ASSIGNMENTS = true }
for _, slot in ipairs(ASSIGNMENT_SLOTS) do VALID_TEXT_KEYS[slot.textKey] = true end

local KIND_LABEL_KEYS = {
    PHASE = "RL_KIND_PHASE",
    MECHANIC = "RL_KIND_MECHANIC",
    ASSIGNMENT = "RL_KIND_ASSIGNMENT",
    NOTE = "RL_KIND_NOTE",
    MARKER = "RL_KIND_MARKER",
    COOLDOWN = "RL_KIND_COOLDOWN",
}

local KIND_COLORS = {
    PHASE = "|cff66ccff", MECHANIC = "|cffffffff", ASSIGNMENT = "|cffffcc00",
    NOTE = "|cffbbbbbb", MARKER = "|cffff8844", COOLDOWN = "|cff55dd88",
}

local ROLE_PREFIX_KEYS = {
    tank = "RL_ROLE_TANK", healer = "RL_ROLE_HEAL", dps = "RL_ROLE_DPS",
    interrupt = "RL_ROLE_KICK",
}

local SOURCE_LABEL_KEYS = {
    TLDR = "RL_SOURCE_TLDR", ABILITY = "RL_SOURCE_ABILITY",
    TIP = "RL_SOURCE_TIP", NOTE = "RL_SOURCE_PERSONAL",
    AFFIX = "RL_SOURCE_AFFIX",
}

local MAX_BLOCKS = 80
local MAX_BLOCK_TEXT = 2000
local PANE_GAP = 12
local TOOLBAR_H = 34
local FOOTER_H = 32

local PANE_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function Clamp(value, low, high)
    value = tonumber(value) or low
    return math.max(low, math.min(high, value))
end

local function DeepCopy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, item in pairs(value) do out[DeepCopy(key)] = DeepCopy(item) end
    return out
end

local function TrimText(value, limit)
    local text = strtrim(tostring(value or ""))
    limit = limit or MAX_BLOCK_TEXT
    if #text > limit then text = text:sub(1, limit) end
    return text
end

local function StringHeight(fs, fallback)
    local height = fs:GetStringHeight()
    if not height or height < 1 then height = fallback end
    return height
end

local function SetButtonEnabled(button, enabled)
    if enabled then button:Enable() else button:Disable() end
end

local function DifficultyLabel(diff)
    local key = C.DIFF_LABEL_KEYS[diff]
    return key and BT:L(key) or tostring(diff or "MYTHIC")
end

local function SourceSignature(source)
    if type(source) ~= "table" then return nil end
    return table.concat({
        tostring(source.kind or ""), tostring(source.index or ""),
        tostring(source.group or ""), tostring(source.tipIndex or ""),
    }, "\031")
end

function RS:GetContextKey()
    if not self.selectedKey then return nil end
    return tostring(self.selectedKey) .. "\030" .. tostring(self.difficulty or "MYTHIC")
end

local function PlanContextKey(bossKey, difficulty)
    if not bossKey then return nil end
    return tostring(bossKey) .. "\030" .. tostring(difficulty or "MYTHIC")
end

function RS:GetUndoStack(bossKey, difficulty, create)
    local context = PlanContextKey(bossKey or self.selectedKey, difficulty or self.difficulty)
    if not context then return nil end
    local stack = self.undoStacks[context]
    if not stack and create then
        stack = {}
        self.undoStacks[context] = stack
    end
    return stack
end

function RS:PushUndo(bossKey, difficulty, plan)
    bossKey = bossKey or self.selectedKey
    difficulty = difficulty or self.difficulty or "MYTHIC"
    if plan == nil and bossKey == self.selectedKey and difficulty == self.difficulty then
        plan = self:GetStoredPlan(false)
    end
    if type(plan) ~= "table" then return end
    local stack = self:GetUndoStack(bossKey, difficulty, true)
    stack[#stack + 1] = DeepCopy(plan)
    if #stack > 20 then table.remove(stack, 1) end
    self:UpdateActionButtons()
end

function RS:Undo()
    local stack = self:GetUndoStack(nil, nil, false)
    if not stack or #stack == 0 then return end
    local snapshot = table.remove(stack)
    local plan = self:SanitizePlan(snapshot, self.selectedKey)
    local bossPlans = BT.db and BT.db.raidPlans and BT.db.raidPlans[self.selectedKey]
    if not bossPlans or not plan then return end
    bossPlans[self.difficulty or "MYTHIC"] = plan
    self.validatedPlans[plan] = true
    self.selectedBlock = nil
    self:ClearBlockEditor()
    self:SetStatus(BT:L("RL_UNDO_DONE"))
    self:RefreshAfterMutation(true)
    self:UpdateActionButtons()
end

function RS:GetPlanForBoss(bossKey, difficulty, create)
    if not BT.db or not bossKey then return nil end
    if type(BT.db.raidPlans) ~= "table" then BT.db.raidPlans = {} end
    local bossPlans = BT.db.raidPlans[bossKey]
    if type(bossPlans) ~= "table" then
        if not create then return nil end
        bossPlans = {}
        BT.db.raidPlans[bossKey] = bossPlans
    end
    local diff = difficulty or self.difficulty or "MYTHIC"
    local plan = bossPlans[diff]
    if type(plan) == "table" and not self.validatedPlans[plan] then
        plan = self:SanitizePlan(plan, bossKey)
        bossPlans[diff] = plan
        self.validatedPlans[plan] = true
    end
    if type(plan) ~= "table" and create then
        plan = { version = 1, preset = "QUICK_PUG",
            blocks = self:BuildPresetBlocks("QUICK_PUG", bossKey, diff) }
        bossPlans[diff] = plan
        self.validatedPlans[plan] = true
    end
    return plan
end

function RS:GetStoredPlan(create)
    return self:GetPlanForBoss(self.selectedKey, self.difficulty, create)
end

function RS:ResolveBlockText(block, bossKey)
    if type(block) ~= "table" then return "" end
    local direct = type(block.text) == "string" and TrimText(block.text) or ""
    if direct ~= "" then return direct end
    if VALID_TEXT_KEYS[block.textKey] then return BT:L(block.textKey) end

    local source = block.source
    local data = BT_BossData and BT_BossData[bossKey or self.selectedKey]
    if type(source) == "table" and data then
        local index = tonumber(source.index)
        if source.kind == "TLDR" and index and data.tldr and data.tldr[index] then
            local text = C.ResolveTLDRBullet(data.tldr[index])
            local role, clean = C.ParseTLDRRole(text)
            local prefixKey = ROLE_PREFIX_KEYS[role]
            return (prefixKey and (BT:L(prefixKey) .. ": ") or "") .. clean
        elseif source.kind == "ABILITY" and index and data.abilities and data.abilities[index] then
            local ability = data.abilities[index]
            local title = BT:Localize(ability.title) or ""
            local description = BT:Localize(ability.description) or ""
            if title ~= "" and description ~= "" then return title .. " — " .. description end
            return title ~= "" and title or description
        elseif source.kind == "TIP" and index and data.tips and data.tips[index] then
            local tip = data.tips[index]
            return type(tip) == "table" and (BT:Localize(tip.text) or "")
                or (BT:Localize(tip) or "")
        end
    end
    return type(block.fallback) == "string" and TrimText(block.fallback) or ""
end

local function BlockKindForRole(role)
    if role == "interrupt" or role == "tank" or role == "healer" or role == "dps" then
        return "ASSIGNMENT"
    end
    return "MECHANIC"
end

local function BlockKindForAbility(ability)
    local abilityType = ability and ability.type
    if abilityType == "INTERRUPT" then return "ASSIGNMENT" end
    if abilityType == "TANK_CD" or abilityType == "HEALER_CD" then return "COOLDOWN" end
    return "MECHANIC"
end

function RS:BuildQuickPugBlocks(bossKey, difficulty)
    bossKey = bossKey or self.selectedKey
    difficulty = difficulty or self.difficulty or "MYTHIC"
    local data = bossKey and BT_BossData and BT_BossData[bossKey]
    local blocks = {
        { kind = "PHASE", textKey = "RL_CORE_MECHANICS" },
    }
    if not data then return blocks end

    local bullets = C.FilterTLDRBullets(data.tldr, difficulty, "ALL")
    for _, entry in ipairs(bullets) do
        local block = {
            kind = BlockKindForRole(entry.role),
            source = { kind = "TLDR", index = entry.sourceIndex },
        }
        block.fallback = self:ResolveBlockText(block, bossKey)
        blocks[#blocks + 1] = block
    end

    -- Sparse custom data still gets a useful plan instead of an empty shell.
    if #blocks < 4 then
        local abilities, indices = C.FilterAbilities(data.abilities, difficulty, "ALL")
        for i, ability in ipairs(abilities) do
            if #blocks >= 6 then break end
            local block = {
                kind = BlockKindForAbility(ability),
                source = { kind = "ABILITY", index = indices[i] },
            }
            block.fallback = self:ResolveBlockText(block, bossKey)
            blocks[#blocks + 1] = block
        end
    end
    return blocks
end


function RS:BuildDetailedPugBlocks(bossKey, difficulty)
    bossKey = bossKey or self.selectedKey
    difficulty = difficulty or self.difficulty or "MYTHIC"
    local data = bossKey and BT_BossData and BT_BossData[bossKey]
    local blocks = self:BuildQuickPugBlocks(bossKey, difficulty)
    if not data then return blocks end

    local seen = {}
    for _, block in ipairs(blocks) do
        local signature = SourceSignature(block.source)
        if signature then seen[signature] = true end
    end

    local abilities, indices = C.FilterAbilities(data.abilities, difficulty, "ALL")
    local lastPhase = nil
    for i, ability in ipairs(abilities) do
        if ability.phase and ability.phase ~= lastPhase then
            lastPhase = ability.phase
            blocks[#blocks + 1] = { kind = "PHASE", text = string.format("%s %s",
                BT:L("RL_KIND_PHASE"), tostring(lastPhase)) }
        end
        local block = { kind = BlockKindForAbility(ability),
            source = { kind = "ABILITY", index = indices[i] } }
        local signature = SourceSignature(block.source)
        if not seen[signature] then
            block.fallback = self:ResolveBlockText(block, bossKey)
            blocks[#blocks + 1] = block
            seen[signature] = true
        end
    end

    if data.tips and #data.tips > 0 then
        blocks[#blocks + 1] = { kind = "PHASE", textKey = "RL_DETAILED_NOTES" }
        for index in ipairs(data.tips) do
            local block = { kind = "NOTE", source = { kind = "TIP", index = index } }
            block.fallback = self:ResolveBlockText(block, bossKey)
            if block.fallback ~= "" then blocks[#blocks + 1] = block end
        end
    end
    return blocks
end

function RS:BuildGuildProgressionBlocks(bossKey, difficulty)
    local blocks = self:BuildDetailedPugBlocks(bossKey, difficulty)
    blocks[#blocks + 1] = { kind = "PHASE", textKey = "RL_GUILD_ASSIGNMENTS" }
    for _, slot in ipairs(ASSIGNMENT_SLOTS) do
        blocks[#blocks + 1] = {
            kind = slot.kind, slot = slot.id, textKey = slot.textKey,
        }
    end
    return blocks
end

function RS:BuildPresetBlocks(preset, bossKey, difficulty)
    if preset == "DETAILED_PUG" then
        return self:BuildDetailedPugBlocks(bossKey, difficulty)
    elseif preset == "GUILD_PROGRESSION" then
        return self:BuildGuildProgressionBlocks(bossKey, difficulty)
    end
    return self:BuildQuickPugBlocks(bossKey, difficulty)
end

function RS:BuildSourceRecords()
    local records = {}
    local data = self.selectedKey and BT_BossData and BT_BossData[self.selectedKey]
    if not data then return records end
    local diff = self.difficulty or "MYTHIC"

    for _, entry in ipairs(C.FilterTLDRBullets(data.tldr, diff, "ALL")) do
        local block = {
            kind = BlockKindForRole(entry.role),
            source = { kind = "TLDR", index = entry.sourceIndex },
        }
        records[#records + 1] = {
            category = "TLDR", block = block, text = self:ResolveBlockText(block),
        }
    end

    local abilities, indices = C.FilterAbilities(data.abilities, diff, "ALL")
    for i, ability in ipairs(abilities) do
        local block = {
            kind = BlockKindForAbility(ability),
            source = { kind = "ABILITY", index = indices[i] },
        }
        records[#records + 1] = {
            category = "ABILITY", block = block, text = self:ResolveBlockText(block),
        }
    end

    for sourceIndex, tip in ipairs(data.tips or {}) do
        local block = { kind = "NOTE", source = { kind = "TIP", index = sourceIndex } }
        local text = self:ResolveBlockText(block)
        if text ~= "" then
            records[#records + 1] = { category = "TIP", block = block, text = text }
        end
    end

    local notes = BT.db and BT.db.journalNotes
    local bossNotes = type(notes) == "table" and notes[self.selectedKey]
    local note = type(bossNotes) == "table" and bossNotes[diff] or ""
    note = type(note) == "string" and TrimText(note) or ""
    if note ~= "" then
        records[#records + 1] = {
            category = "NOTE", block = { kind = "NOTE", text = note }, text = note,
        }
    end

    for _, affix in ipairs(D:GetActiveAffixTips(data)) do
        local name = affix.name or ("Affix#" .. tostring(affix.id or "?"))
        for _, tip in ipairs(affix.tips or {}) do
            local text = BT:Localize(tip) or ""
            if text ~= "" then
                text = name .. ": " .. text
                records[#records + 1] = {
                    category = "AFFIX", block = { kind = "MECHANIC", text = text }, text = text,
                }
            end
        end
    end
    return records
end

function RS:SanitizePlan(input, bossKey)
    if type(input) ~= "table" then return nil end
    local preset = VALID_PRESET[input.preset] and input.preset or "CUSTOM"
    local plan = { version = 1, preset = preset, blocks = {} }
    for _, raw in ipairs(type(input.blocks) == "table" and input.blocks or {}) do
        if #plan.blocks >= MAX_BLOCKS then break end
        if type(raw) == "table" and VALID_KIND[raw.kind] then
            local block = { kind = raw.kind }
            local text = type(raw.text) == "string" and TrimText(raw.text) or ""
            if text ~= "" then block.text = text end
            if VALID_TEXT_KEYS[raw.textKey] then block.textKey = raw.textKey end
            if type(raw.slot) == "string" and #raw.slot <= 40 then block.slot = raw.slot end
            local fallback = type(raw.fallback) == "string" and TrimText(raw.fallback) or ""
            if fallback ~= "" then block.fallback = fallback end
            if type(raw.source) == "table" then
                local sourceKind = raw.source.kind
                local sourceIndex = tonumber(raw.source.index)
                if (sourceKind == "TLDR" or sourceKind == "ABILITY" or sourceKind == "TIP")
                    and sourceIndex and sourceIndex >= 1 then
                    block.source = { kind = sourceKind, index = math.floor(sourceIndex) }
                end
            end
            if self:ResolveBlockText(block, bossKey) ~= "" then
                plan.blocks[#plan.blocks + 1] = block
            end
        end
    end
    return plan
end

function RS:GetPlanLabel()
    return string.format(BT:L("RL_PLAN_LABEL"), tostring(self.selectedKey or "?"))
end

function RS:GetSelectedDungeonName()
    local data = self.selectedKey and BT_BossData and BT_BossData[self.selectedKey]
    return C.ResolveDungeonName(data)
end

function RS:GetInstanceBossKeys()
    local dungeonName = self:GetSelectedDungeonName()
    return dungeonName and D:GetBossesForDungeon(dungeonName) or {}
end

function RS:GetBossPosition()
    local keys = self:GetInstanceBossKeys()
    for index, key in ipairs(keys) do
        if key == self.selectedKey then return index, #keys, keys end
    end
    return 0, #keys, keys
end

function RS:GetPlanStatusText(bossKey)
    local plan = self:GetPlanForBoss(bossKey, self.difficulty, false)
    if not plan then return "|cff777777—|r" end
    local key = PRESET_LABEL_KEYS[plan.preset] or PRESET_LABEL_KEYS.CUSTOM
    local color = plan.preset == "GUILD_PROGRESSION" and "|cff55dd88"
        or plan.preset == "DETAILED_PUG" and "|cff66ccff"
        or plan.preset == "QUICK_PUG" and "|cffffcc00" or "|cffcc99ff"
    return color .. BT:L(key) .. "|r"
end

function RS:SelectBoss(bossKey)
    if not bossKey or not (BT_BossData and BT_BossData[bossKey]) then return false end
    self.selectedKey = bossKey
    self.difficulty = C.ResolveContentDifficulty(BT_BossData[bossKey],
        self.requestedDifficulty or self.difficulty or "NORMAL")
    self.selectedBlock = nil
    self.armedAction = nil
    self:ClearBlockEditor()
    self:GetStoredPlan(true)
    if self.bossList then self.bossList:SetSelected(bossKey) end
    if self.bossPicker then self.bossPicker:Hide() end
    self:RefreshAll()
    return true
end

function RS:SelectRelativeBoss(delta)
    local index, total, keys = self:GetBossPosition()
    local target = index + (tonumber(delta) or 0)
    if index > 0 and target >= 1 and target <= total then self:SelectBoss(keys[target]) end
end

function RS:BuildPlanParts(bossKey, plan)
    plan = plan or self:GetPlanForBoss(bossKey, self.difficulty, true)
    local parts = {}
    for _, block in ipairs(plan and plan.blocks or {}) do
        local text = self:ResolveBlockText(block, bossKey)
        if text ~= "" then
            if block.kind == "PHASE" then
                parts[#parts + 1] = "== " .. text .. " =="
            else
                local label = BT:L(KIND_LABEL_KEYS[block.kind])
                parts[#parts + 1] = label .. ": " .. text
            end
        end
    end
    return parts
end

function RS:BuildChatParts()
    return self:BuildPlanParts(self.selectedKey, self:GetStoredPlan(true))
end

local function AppendPlanPreview(lines, format, bossKey, difficulty, plan)
    lines[#lines + 1] = format == "DISCORD" and ("### " .. tostring(bossKey))
        or ("== " .. tostring(bossKey) .. " ==")
    for _, block in ipairs(plan and plan.blocks or {}) do
        local text = RS:ResolveBlockText(block, bossKey)
        if text ~= "" then
            local label = BT:L(KIND_LABEL_KEYS[block.kind])
            if block.kind == "PHASE" then
                lines[#lines + 1] = format == "DISCORD" and ("#### " .. text)
                    or ("-- " .. text .. " --")
            elseif format == "DISCORD" then
                lines[#lines + 1] = "- **" .. label .. ":** " .. text
            else
                lines[#lines + 1] = "- [" .. label .. "] " .. text
            end
        end
    end
    lines[#lines + 1] = ""
end

function RS:BuildInstancePreview(format)
    format = format or self.outputFormat or "WOW"
    local dungeonName = self:GetSelectedDungeonName() or "?"
    local keys = self:GetInstanceBossKeys()
    if format == "WOW" then
        local chatLines = {}
        for _, bossKey in ipairs(keys) do
            local plan = self:GetPlanForBoss(bossKey, self.difficulty, true)
            local built = C.BuildChatLines(tostring(bossKey), self:BuildPlanParts(bossKey, plan))
            for _, line in ipairs(built) do chatLines[#chatLines + 1] = line end
        end
        local signature = C.GetShareSignature()
        if signature then chatLines[#chatLines + 1] = signature end
        return table.concat(chatLines, "\n")
    end

    local title = dungeonName .. " — " .. DifficultyLabel(self.difficulty)
    local lines = { format == "DISCORD" and ("## " .. title) or title, "" }
    for _, bossKey in ipairs(keys) do
        local plan = self:GetPlanForBoss(bossKey, self.difficulty, true)
        AppendPlanPreview(lines, format, bossKey, self.difficulty, plan)
    end
    local signature = C.GetShareSignature()
    if signature then lines[#lines + 1] = signature end
    return table.concat(lines, "\n")
end

function RS:BuildPreview(format)
    format = format or self.outputFormat or "WOW"
    if self.outputScope == "INSTANCE" then return self:BuildInstancePreview(format) end
    local parts = self:BuildChatParts()
    if format == "WOW" then
        return table.concat(C.BuildSignedChatLines(self:GetPlanLabel(), parts), "\n")
    end

    local lines = {}
    local title = tostring(self.selectedKey or "?") .. " — " .. DifficultyLabel(self.difficulty)
    lines[#lines + 1] = format == "DISCORD" and ("## " .. title) or title
    lines[#lines + 1] = ""
    local plan = self:GetStoredPlan(true)
    for _, block in ipairs(plan and plan.blocks or {}) do
        local text = self:ResolveBlockText(block)
        if text ~= "" then
            local label = BT:L(KIND_LABEL_KEYS[block.kind])
            if block.kind == "PHASE" then
                lines[#lines + 1] = format == "DISCORD" and ("### " .. text)
                    or ("== " .. text .. " ==")
            elseif format == "DISCORD" then
                lines[#lines + 1] = "- **" .. label .. ":** " .. text
            else
                lines[#lines + 1] = "- [" .. label .. "] " .. text
            end
        end
    end
    local signature = C.GetShareSignature()
    if signature then
        lines[#lines + 1] = ""
        lines[#lines + 1] = signature
    end
    return table.concat(lines, "\n")
end

function RS:ExportPackage()
    if not BT.ImportExport then return nil end
    if self.outputScope == "INSTANCE" then
        local plans = {}
        for _, bossKey in ipairs(self:GetInstanceBossKeys()) do
            local plan = self:GetPlanForBoss(bossKey, self.difficulty, true)
            local exported = DeepCopy(plan)
            for _, block in ipairs(exported.blocks or {}) do
                if block.source and not block.fallback then
                    block.fallback = self:ResolveBlockText(block, bossKey)
                end
            end
            plans[bossKey] = exported
        end
        return BT.ImportExport:ExportString({
            type = "raidplan_instance", dungeonName = self:GetSelectedDungeonName(),
            difficulty = self.difficulty or "MYTHIC", plans = plans,
        })
    end

    local plan = self:GetStoredPlan(true)
    if not plan then return nil end
    local exported = DeepCopy(plan)
    for _, block in ipairs(exported.blocks or {}) do
        if block.source and not block.fallback then
            block.fallback = self:ResolveBlockText(block)
        end
    end
    return BT.ImportExport:ExportString({
        type = "raidplan", bossKey = self.selectedKey,
        difficulty = self.difficulty or "MYTHIC", plan = exported,
    })
end

function RS:SetStatus(text, isError)
    if not self.statusFS then return end
    self.statusFS:SetText((isError and "|cffff5555" or "|cff66dd88") .. tostring(text or "") .. "|r")
end

function RS:RefreshAfterMutation(keepEditor)
    if not keepEditor then
        self.selectedBlock = nil
        self:ClearBlockEditor()
    end
    self:RefreshPlanRows()
    self:RefreshSourceRows()
    self:UpdatePreview()
    self:UpdateActionButtons()
    if self.bossList then self.bossList:Refresh() end
end

function RS:AddSourceRecord(record)
    if type(record) ~= "table" or type(record.block) ~= "table" then return end
    local plan = self:GetStoredPlan(true)
    if not plan or #plan.blocks >= MAX_BLOCKS then
        self:SetStatus(BT:L("RL_ERR_BLOCK_LIMIT"), true)
        return
    end
    local signature = SourceSignature(record.block.source)
    if signature then
        for index, block in ipairs(plan.blocks) do
            if SourceSignature(block.source) == signature then
                self:SelectBlock(index)
                self:SetStatus(BT:L("RL_SOURCE_ALREADY_ADDED"), true)
                return
            end
        end
    end
    local block = DeepCopy(record.block)
    block.fallback = record.text
    self:PushUndo()
    plan.blocks[#plan.blocks + 1] = block
    plan.preset = "CUSTOM"
    self.selectedBlock = #plan.blocks
    self:LoadBlockEditor(self.selectedBlock)
    self:SetStatus(BT:L("RL_SOURCE_ADDED"))
    self:RefreshAfterMutation(true)
end

function RS:SelectBlock(index)
    local plan = self:GetStoredPlan(true)
    if not plan or not plan.blocks[index] then return end
    self.selectedBlock = index
    self:LoadBlockEditor(index)
    self:RefreshPlanRows()
end

function RS:ClearBlockEditor()
    self.editorKind = "MECHANIC"
    if self.kindBtn then self.kindBtn:SetText(BT:L(KIND_LABEL_KEYS[self.editorKind])) end
    if self.blockEdit then
        self.loadingEditor = true
        self.blockEdit:SetText("")
        self.blockEdit:SetCursorPosition(0)
        self.loadingEditor = false
    end
    if self.saveBlockBtn then self.saveBlockBtn:SetText(BT:L("RL_BTN_ADD_BLOCK")) end
end

function RS:LoadBlockEditor(index)
    local plan = self:GetStoredPlan(true)
    local block = plan and plan.blocks[index]
    if not block or not self.blockEdit then return end
    self.editorKind = block.kind
    self.kindBtn:SetText(BT:L(KIND_LABEL_KEYS[self.editorKind]))
    self.loadingEditor = true
    self.blockEdit:SetText(self:ResolveBlockText(block))
    self.blockEdit:SetCursorPosition(0)
    self.loadingEditor = false
    self.saveBlockBtn:SetText(BT:L("RL_BTN_UPDATE_BLOCK"))
end

function RS:CycleEditorKind()
    local index = 1
    for i, kind in ipairs(BLOCK_KINDS) do
        if kind == self.editorKind then index = i break end
    end
    self.editorKind = BLOCK_KINDS[(index % #BLOCK_KINDS) + 1]
    self.kindBtn:SetText(BT:L(KIND_LABEL_KEYS[self.editorKind]))
end

function RS:SaveEditorBlock()
    local text = TrimText(self.blockEdit and self.blockEdit:GetText())
    if text == "" then
        self:SetStatus(BT:L("RL_ERR_EMPTY_BLOCK"), true)
        return
    end
    local plan = self:GetStoredPlan(true)
    if not plan then return end
    if self.selectedBlock and plan.blocks[self.selectedBlock] then
        self:PushUndo()
        -- Editing intentionally detaches this block from shipped source data.
        plan.blocks[self.selectedBlock] = { kind = self.editorKind, text = text }
        plan.preset = "CUSTOM"
        self:SetStatus(BT:L("RL_BLOCK_UPDATED"))
    else
        if #plan.blocks >= MAX_BLOCKS then
            self:SetStatus(BT:L("RL_ERR_BLOCK_LIMIT"), true)
            return
        end
        self:PushUndo()
        plan.blocks[#plan.blocks + 1] = { kind = self.editorKind, text = text }
        plan.preset = "CUSTOM"
        self.selectedBlock = #plan.blocks
        self:SetStatus(BT:L("RL_BLOCK_ADDED"))
    end
    self:LoadBlockEditor(self.selectedBlock)
    self:RefreshAfterMutation(true)
end

function RS:MoveSelected(delta)
    local plan = self:GetStoredPlan(true)
    local index = self.selectedBlock
    if not plan or not index or not plan.blocks[index] then return end
    local target = index + delta
    if target < 1 or target > #plan.blocks then return end
    self:PushUndo()
    plan.blocks[index], plan.blocks[target] = plan.blocks[target], plan.blocks[index]
    plan.preset = "CUSTOM"
    self.selectedBlock = target
    self:RefreshAfterMutation(true)
end

function RS:DeleteSelected()
    local plan = self:GetStoredPlan(true)
    local index = self.selectedBlock
    if not plan or not index or not plan.blocks[index] then return end
    self:PushUndo()
    table.remove(plan.blocks, index)
    plan.preset = "CUSTOM"
    self.selectedBlock = nil
    self:ClearBlockEditor()
    self:SetStatus(BT:L("RL_BLOCK_DELETED"))
    self:RefreshAfterMutation(true)
end

function RS:ArmAction(action)
    self.armedAction = action
    self.armedToken = (self.armedToken or 0) + 1
    local token = self.armedToken
    C_Timer.After(4, function()
        if RS.armedToken == token then
            RS.armedAction = nil
            RS:UpdateActionButtons()
        end
    end)
    self:UpdateActionButtons()
end

function RS:ClearPlan()
    if self.armedAction ~= "CLEAR" then
        self:ArmAction("CLEAR")
        self:SetStatus(BT:L("RL_CONFIRM_CLEAR"), true)
        return
    end
    self.armedAction = nil
    local plan = self:GetStoredPlan(true)
    self:PushUndo()
    plan.blocks = {}
    plan.preset = "CUSTOM"
    self:SetStatus(BT:L("RL_PLAN_CLEARED"))
    self:RefreshAfterMutation()
    self:UpdateActionButtons()
end

function RS:LoadPreset(preset)
    if not VALID_PRESET[preset] or preset == "CUSTOM" then return end
    local plan = self:GetStoredPlan(true)
    local action = "PRESET_" .. preset
    if plan and #plan.blocks > 0 and self.armedAction ~= action then
        self:ArmAction(action)
        self.pendingPreset = preset
        self:SetStatus(string.format(BT:L("RL_CONFIRM_PRESET"),
            BT:L(PRESET_LABEL_KEYS[preset])), true)
        return
    end
    self.armedAction = nil
    self.pendingPreset = nil
    self:PushUndo()
    plan.blocks = self:BuildPresetBlocks(preset, self.selectedKey, self.difficulty)
    plan.preset = preset
    self:SetStatus(string.format(BT:L("RL_PRESET_LOADED"), BT:L(PRESET_LABEL_KEYS[preset])))
    self:RefreshAfterMutation()
    self:UpdateActionButtons()
end

function RS:LoadQuickPug()
    self:LoadPreset("QUICK_PUG")
end

function RS:UseAssignmentSlot(slotID)
    local selected
    for _, slot in ipairs(ASSIGNMENT_SLOTS) do
        if slot.id == slotID then selected = slot break end
    end
    if not selected or not self.blockEdit then return end
    self.selectedBlock = nil
    self.editorKind = selected.kind
    self.kindBtn:SetText(BT:L(KIND_LABEL_KEYS[selected.kind]))
    self.loadingEditor = true
    self.blockEdit:SetText(BT:L(selected.textKey))
    self.blockEdit:SetCursorPosition(0)
    self.loadingEditor = false
    self.saveBlockBtn:SetText(BT:L("RL_BTN_ADD_BLOCK"))
    if self.slotPicker then self.slotPicker:Hide() end
    self:SetStatus(BT:L("RL_SLOT_READY"))
    self:RefreshPlanRows()
end

function RS:UpdateActionButtons()
    if self.presetBtn then
        local plan = self:GetStoredPlan(true)
        local preset = (plan and plan.preset) or "CUSTOM"
        if self.armedAction and self.armedAction:find("^PRESET_") then
            self.presetBtn:SetText(BT:L("RL_BTN_CONFIRM_REPLACE"))
        else
            self.presetBtn:SetText(BT:L(PRESET_LABEL_KEYS[preset] or PRESET_LABEL_KEYS.CUSTOM))
        end
    end
    if self.clearPlanBtn then
        self.clearPlanBtn:SetText(BT:L(self.armedAction == "CLEAR" and "RL_BTN_CONFIRM_CLEAR" or "RL_BTN_CLEAR_PLAN"))
    end
    if Theme then
        Theme:FitButton(self.presetBtn, { compact = true, iconWidth = 18,
            maxWidth = 190, wrap = true })
        Theme:FitButton(self.clearPlanBtn, { compact = true })
    end
    if self.undoBtn then
        local stack = self:GetUndoStack(nil, nil, false)
        SetButtonEnabled(self.undoBtn, stack ~= nil and #stack > 0)
    end
end

function RS:SharePlan()
    if self.outputScope == "INSTANCE" then
        self:SetStatus(BT:L("RL_INSTANCE_SHARE_HINT"), true)
        return
    end
    local parts = self:BuildChatParts()
    if #parts == 0 then
        self:SetStatus(BT:L("RL_ERR_EMPTY_PLAN"), true)
        return
    end
    C.SendChatParts(self:GetPlanLabel(), parts, C.ResolveChannel())
end

function RS:CopyPreview()
    if not self.outputEdit then return end
    self.outputEdit:SetFocus()
    self.outputEdit:HighlightText()
    self:SetStatus(BT:L("RL_COPY_HINT"))
end

function RS:SetOutputFormat(format)
    self.outputFormat = format
    self:UpdatePreview()
end

function RS:SetOutputScope(scope)
    if scope ~= "INSTANCE" then scope = "BOSS" end
    self.outputScope = scope
    self:UpdatePreview()
    self:UpdateScopeButtons()
end

function RS:CycleDifficulty()
    local data = self.selectedKey and BT_BossData and BT_BossData[self.selectedKey]
    if not C.ShouldShowDifficultySelector(data) then return end
    local index = 1
    for i, diff in ipairs(DIFF_CYCLE) do
        if diff == (self.requestedDifficulty or self.difficulty) then index = i break end
    end
    self.requestedDifficulty = DIFF_CYCLE[(index % #DIFF_CYCLE) + 1]
    self.difficulty = C.ResolveContentDifficulty(data, self.requestedDifficulty)
    self.selectedBlock = nil
    self:ClearBlockEditor()
    self:RefreshAll()
end

local function CreatePane(parent, title)
    local pane = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    pane:SetBackdrop(PANE_BACKDROP)
    pane:SetBackdropColor(0.018, 0.018, 0.025, 0.97)
    pane:SetBackdropBorderColor(0.3, 0.3, 0.36, 0.9)
    pane.title = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    pane.title:SetPoint("TOPLEFT", 12, -12)
    pane.title:SetText(title)
    return pane
end

local function CreateScrollBody(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    local body = CreateFrame("Frame", nil, scroll)
    body:SetSize(200, 10)
    scroll:SetScrollChild(body)
    return scroll, body
end

local function CreateMultilineEdit(parent, fontObject)
    local inset = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    local scroll = CreateFrame("ScrollFrame", nil, inset, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 7, -7)
    scroll:SetPoint("BOTTOMRIGHT", -25, 7)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(20000)
    edit:SetFontObject(fontObject or GameFontHighlightSmall)
    if edit.SetSpacing then edit:SetSpacing(2) end
    edit:SetWidth(260)
    scroll:SetScrollChild(edit)
    scroll:EnableMouse(true)
    scroll:SetScript("OnMouseDown", function() edit:SetFocus() end)
    edit:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    return inset, scroll, edit
end

local function CreateChoicePicker(parent, width, choices, onChoose)
    local picker = CreateFrame("Frame", nil, parent, "TooltipBackdropTemplate")
    picker:SetFrameStrata("DIALOG")
    picker:SetClampedToScreen(true)
    picker:SetSize(width, #choices * 25 + 12)
    for index, choice in ipairs(choices) do
        local button = CreateFrame("Button", nil, picker)
        button:SetPoint("TOPLEFT", 6, -6 - (index - 1) * 25)
        button:SetPoint("TOPRIGHT", -6, -6 - (index - 1) * 25)
        button:SetHeight(23)
        button.label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        button.label:SetPoint("LEFT", 8, 0)
        button.label:SetPoint("RIGHT", -8, 0)
        button.label:SetJustifyH("LEFT")
        button.label:SetWordWrap(false)
        local label = BT:L(choice.labelKey or choice.textKey)
        button.label:SetText(label)
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(0.3, 0.65, 1, 0.14)
        local value = choice.id
        button:SetScript("OnClick", function()
            picker:Hide()
            onChoose(value)
        end)
        button:SetScript("OnEnter", function(target)
            GameTooltip:SetOwner(target, "ANCHOR_RIGHT")
            -- WoW 12.x expects the modern SetText(text [, color, alpha, wrap])
            -- signature; the old r/g/b/wrap form treats the fifth argument as
            -- a number and raises an error.
            GameTooltip:SetText(label)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    picker:Hide()
    return picker
end

local function AddDropdownArrow(button)
    local arrow = button:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    arrow:SetSize(18, 18)
    arrow:SetPoint("RIGHT", -3, 0)
    button.dropdownArrow = arrow
    button._btIconWidth = 18

    local label = button:GetFontString()
    if label then
        label:ClearAllPoints()
        label:SetPoint("LEFT", 6, 0)
        label:SetPoint("RIGHT", arrow, "LEFT", -1, 0)
        label:SetJustifyH("CENTER")
    end
end

function RS:ToggleBossPicker()
    if not self.bossPicker then return end
    if self.bossPicker:IsShown() then
        self.bossPicker:Hide()
    else
        self.bossList:SetSelected(self.selectedKey)
        self.bossPicker:Show()
        self.bossList.searchBox:SetFocus()
    end
end

function RS:RefreshNavigator()
    if not self.window then return end
    local index, total = self:GetBossPosition()
    local dungeonName = self:GetSelectedDungeonName() or BT:L("RL_SELECT_BOSS")
    self.instanceBtn:SetText(dungeonName)
    if Theme then Theme:FitButton(self.instanceBtn, { compact = true, iconWidth = 18 }) end
    self.bossCountFS:SetText(string.format("%d/%d", index, total))
    SetButtonEnabled(self.prevBossBtn, index > 1)
    SetButtonEnabled(self.nextBossBtn, index > 0 and index < total)
    if self.bossList then self.bossList:SetSelected(self.selectedKey) end
end

function RS:UpdateScopeButtons()
    if not self.scopeButtons then return end
    for scope, button in pairs(self.scopeButtons) do
        if scope == self.outputScope then button:LockHighlight() else button:UnlockHighlight() end
        if Theme then Theme:SetSelected(button, scope == self.outputScope) end
    end
    if self.shareBtn then
        self.shareBtn:SetText(BT:L(self.outputScope == "INSTANCE"
            and "RL_BTN_SHARE_BOSS_ONLY" or "RL_BTN_SHARE_WOW"))
        if Theme then Theme:FitButton(self.shareBtn) end
    end
end

function RS:GetFontObject(kind)
    local journal = BT.Journal
    if journal and journal.fonts and journal.fonts[kind] then return journal.fonts[kind] end
    if kind == "section" or kind == "title" then return GameFontNormalLarge end
    if kind == "small" then return GameFontHighlightSmall end
    return GameFontHighlight
end

function RS:GetFontScale()
    return BT.Journal and BT.Journal:GetFontScale()
        or C.DEFAULT_WORKSPACE_FONT_SCALE or 1.2
end

function RS:GetWindow()
    if self.window then return self.window end

    -- Reuse the Journal's named accessibility font objects and scale.
    local journal = BT.Journal
    if journal and not journal.window then journal:GetWindow() end
    if journal then journal:ApplyAccessibilityFonts() end

    local frame = CreateFrame("Frame", "BossTacticsRaidStudioFrame", UIParent, "ButtonFrameTemplate")
    self.window = frame
    local screenW = (UIParent and UIParent:GetWidth()) or 1280
    local screenH = (UIParent and UIParent:GetHeight()) or 720
    local maxW = math.max(760, screenW - 40)
    local maxH = math.max(560, screenH - 40)
    local minW = math.min(980, maxW)
    local minH = math.min(620, maxH)
    local db = BT.db or {}
    frame:SetSize(Clamp(db.raidStudioWidth, minW, math.min(1500, maxW)),
        Clamp(db.raidStudioHeight, minH, math.min(900, maxH)))
    local pos = db.raidStudioPosition or { point = "CENTER", x = 0, y = 0 }
    frame:SetPoint(pos.point or "CENTER", UIParent, pos.point or "CENTER", pos.x or 0, pos.y or 0)
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(minW, minH, math.min(1500, maxW), math.min(900, maxH))
    elseif frame.SetMinResize and frame.SetMaxResize then
        frame:SetMinResize(minW, minH)
        frame:SetMaxResize(math.min(1500, maxW), math.min(900, maxH))
    end
    if frame.SetTitle then frame:SetTitle(BT:L("RL_TITLE"))
    elseif frame.TitleText then frame.TitleText:SetText(BT:L("RL_TITLE")) end
    if frame.SetPortraitToAsset then
        frame:SetPortraitToAsset("Interface\\Icons\\INV_Misc_Note_06")
    end

    local drag = CreateFrame("Frame", nil, frame)
    drag:SetPoint("TOPLEFT", 8, 0)
    drag:SetPoint("TOPRIGHT", -28, 0)
    drag:SetHeight(24)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() frame:StartMoving() end)
    drag:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, _, x, y = frame:GetPoint(1)
        BT.db.raidStudioPosition = { point = point or "CENTER", x = x or 0, y = y or 0 }
    end)
    tinsert(UISpecialFrames, "BossTacticsRaidStudioFrame")

    local content = CreateFrame("Frame", nil, frame)
    self.content = content
    if frame.Inset then
        content:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 10, -10)
        content:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -10, 10)
    else
        content:SetPoint("TOPLEFT", 14, -64)
        content:SetPoint("BOTTOMRIGHT", -14, 30)
    end

    -- Top context/accessibility toolbar.
    local toolbar = CreateFrame("Frame", nil, content)
    self.toolbar = toolbar
    toolbar:SetHeight(TOOLBAR_H)
    self.instanceBtn = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    self.instanceBtn:SetSize(220, 22)
    self.instanceBtn:SetPoint("LEFT", 0, 0)
    AddDropdownArrow(self.instanceBtn)
    self.instanceBtn:SetScript("OnClick", function() RS:ToggleBossPicker() end)

    self.prevBossBtn = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    self.prevBossBtn:SetSize(28, 22)
    self.prevBossBtn:SetPoint("LEFT", self.instanceBtn, "RIGHT", 5, 0)
    self.prevBossBtn:SetText("<")
    self.prevBossBtn:SetScript("OnClick", function() RS:SelectRelativeBoss(-1) end)

    self.bossCountFS = toolbar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.bossCountFS:SetSize(46, 22)
    self.bossCountFS:SetPoint("LEFT", self.prevBossBtn, "RIGHT", 2, 0)
    self.bossCountFS:SetJustifyH("CENTER")

    self.nextBossBtn = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    self.nextBossBtn:SetSize(28, 22)
    self.nextBossBtn:SetPoint("LEFT", self.bossCountFS, "RIGHT", 2, 0)
    self.nextBossBtn:SetText(">")
    self.nextBossBtn:SetScript("OnClick", function() RS:SelectRelativeBoss(1) end)

    self.bossTitle = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.bossTitle:SetPoint("LEFT", self.nextBossBtn, "RIGHT", 10, 0)
    self.bossTitle:SetPoint("RIGHT", -260, 0)
    self.bossTitle:SetJustifyH("LEFT")

    self.bossPicker = CreateFrame("Frame", nil, frame, "TooltipBackdropTemplate")
    self.bossPicker:SetFrameStrata("DIALOG")
    self.bossPicker:SetClampedToScreen(true)
    self.bossPicker:SetSize(360, math.min(520, maxH - 100))
    self.bossPicker:SetPoint("TOPLEFT", self.instanceBtn, "BOTTOMLEFT", 0, -4)
    self.bossList = C.CreateBossList(self.bossPicker, 340,
        function(key) return RS:SelectBoss(key) end,
        function(key) return RS:GetPlanStatusText(key) end)
    self.bossList.frame:SetPoint("TOPLEFT", 10, -10)
    self.bossList.frame:SetPoint("BOTTOMRIGHT", -10, 10)
    self.bossPicker:Hide()

    self.diffBtn = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    self.diffBtn:SetSize(96, 22)
    self.diffBtn:SetPoint("RIGHT", -152, 0)
    self.diffBtn:SetScript("OnClick", function() RS:CycleDifficulty() end)
    self.diffBtn:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:SetText(BT:L("TOOLTIP_DIFFICULTY_FILTER"))
        GameTooltip:Show()
    end)
    self.diffBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    self.fontPlusBtn = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    self.fontPlusBtn:SetSize(38, 22)
    self.fontPlusBtn:SetPoint("RIGHT", 0, 0)
    self.fontPlusBtn:SetText("A+")
    self.fontPlusBtn:SetScript("OnClick", function()
        BT.Journal:AdjustFontScale(0.1)
        RS:ApplyFonts()
        RS:RefreshAll()
    end)
    self.fontValueBtn = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    self.fontValueBtn:SetSize(62, 22)
    self.fontValueBtn:SetPoint("RIGHT", self.fontPlusBtn, "LEFT", -3, 0)
    self.fontValueBtn:SetScript("OnClick", function()
        BT.Journal:SetFontScale(C.DEFAULT_WORKSPACE_FONT_SCALE or 1.2)
        RS:ApplyFonts()
        RS:RefreshAll()
    end)
    self.fontMinusBtn = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    self.fontMinusBtn:SetSize(38, 22)
    self.fontMinusBtn:SetPoint("RIGHT", self.fontValueBtn, "LEFT", -3, 0)
    self.fontMinusBtn:SetText("A-")
    self.fontMinusBtn:SetScript("OnClick", function()
        BT.Journal:AdjustFontScale(-0.1)
        RS:ApplyFonts()
        RS:RefreshAll()
    end)

    -- Three work panes.
    self.sourcePane = CreatePane(content, BT:L("RL_SOURCES"))
    self.planPane = CreatePane(content, BT:L("RL_PLAN"))
    self.outputPane = CreatePane(content, BT:L("RL_OUTPUT"))

    self.sourceHint = self.sourcePane:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.sourceHint:SetPoint("TOPLEFT", 12, -34)
    self.sourceHint:SetPoint("RIGHT", -12, 0)
    self.sourceHint:SetJustifyH("LEFT")
    self.sourceHint:SetText(BT:L("RL_SOURCES_HINT"))
    self.sourceScroll, self.sourceBody = CreateScrollBody(self.sourcePane)
    self.sourceScroll:SetPoint("TOPLEFT", 10, -54)
    self.sourceScroll:SetPoint("BOTTOMRIGHT", -28, 10)
    self.sourceRowPool = CreateFramePool("Button", self.sourceBody)

    self.presetBtn = CreateFrame("Button", nil, self.planPane, "UIPanelButtonTemplate")
    self.presetBtn:SetSize(150, 22)
    self.presetBtn:SetPoint("TOPRIGHT", -10, -8)
    AddDropdownArrow(self.presetBtn)
    self.planPane.title:SetPoint("RIGHT", self.presetBtn, "LEFT", -6, 0)
    self.planPane.title:SetWordWrap(false)
    self.presetBtn:SetScript("OnClick", function()
        if RS.armedAction and RS.armedAction:find("^PRESET_") and RS.pendingPreset then
            RS:LoadPreset(RS.pendingPreset)
        elseif RS.presetPicker:IsShown() then RS.presetPicker:Hide()
        else RS.presetPicker:Show() end
    end)
    self.presetBtn:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:SetText(BT:L("RL_TOOLTIP_PRESETS"), 1, 1, 1)
        GameTooltip:Show()
    end)
    self.presetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.presetPicker = CreateChoicePicker(self.planPane, 190, {
        { id = "QUICK_PUG", labelKey = "RL_PRESET_QUICK" },
        { id = "DETAILED_PUG", labelKey = "RL_PRESET_DETAILED" },
        { id = "GUILD_PROGRESSION", labelKey = "RL_PRESET_GUILD" },
    }, function(preset) RS:LoadPreset(preset) end)
    self.presetPicker:SetPoint("TOPRIGHT", self.presetBtn, "BOTTOMRIGHT", 0, -2)

    local controls = CreateFrame("Frame", nil, self.planPane)
    self.planControls = controls
    controls:SetPoint("TOPLEFT", 10, -38)
    controls:SetPoint("TOPRIGHT", -10, -38)
    controls:SetHeight(24)
    local function ControlButton(labelKey, width, previous, handler)
        local button = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
        button:SetSize(width, 22)
        if previous then button:SetPoint("LEFT", previous, "RIGHT", 4, 0)
        else button:SetPoint("LEFT", 0, 0) end
        button:SetText(BT:L(labelKey))
        button:SetScript("OnClick", handler)
        return button
    end
    self.upBtn = ControlButton("RL_BTN_UP", 44, nil, function() RS:MoveSelected(-1) end)
    self.downBtn = ControlButton("RL_BTN_DOWN", 50, self.upBtn, function() RS:MoveSelected(1) end)
    self.deleteBtn = ControlButton("RL_BTN_DELETE", 58, self.downBtn, function() RS:DeleteSelected() end)
    self.undoBtn = ControlButton("RL_BTN_UNDO", 58, self.deleteBtn, function() RS:Undo() end)
    self.clearPlanBtn = ControlButton("RL_BTN_CLEAR_PLAN", 68, self.undoBtn, function() RS:ClearPlan() end)

    self.planScroll, self.planBody = CreateScrollBody(self.planPane)
    self.planScroll:SetPoint("TOPLEFT", 10, -66)
    self.planScroll:SetPoint("BOTTOMRIGHT", -28, 176)
    self.planRowPool = CreateFramePool("Button", self.planBody)

    self.blockEditorLabel = self.planPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.blockEditorLabel:SetPoint("BOTTOMLEFT", 12, 151)
    self.blockEditorLabel:SetText(BT:L("RL_BLOCK_EDITOR"))
    self.kindBtn = CreateFrame("Button", nil, self.planPane, "UIPanelButtonTemplate")
    self.kindBtn:SetSize(112, 22)
    self.kindBtn:SetPoint("BOTTOMRIGHT", -12, 145)
    self.kindBtn:SetScript("OnClick", function() RS:CycleEditorKind() end)

    self.slotBtn = CreateFrame("Button", nil, self.planPane, "UIPanelButtonTemplate")
    self.slotBtn:SetSize(132, 22)
    self.slotBtn:SetPoint("RIGHT", self.kindBtn, "LEFT", -6, 0)
    self.slotBtn:SetText(BT:L("RL_ASSIGNMENT_SLOTS"))
    AddDropdownArrow(self.slotBtn)
    self.slotBtn:SetScript("OnClick", function()
        if RS.slotPicker:IsShown() then RS.slotPicker:Hide() else RS.slotPicker:Show() end
    end)
    self.slotPicker = CreateChoicePicker(self.planPane, 260, ASSIGNMENT_SLOTS,
        function(slotID) RS:UseAssignmentSlot(slotID) end)
    self.slotPicker:SetPoint("BOTTOMRIGHT", self.slotBtn, "TOPRIGHT", 0, 2)

    self.blockInset, self.blockScroll, self.blockEdit = CreateMultilineEdit(
        self.planPane, self:GetFontObject("small"))
    self.blockInset:SetPoint("BOTTOMLEFT", 10, 44)
    self.blockInset:SetPoint("BOTTOMRIGHT", -10, 44)
    self.blockInset:SetHeight(94)
    self.blockEdit:SetMaxLetters(MAX_BLOCK_TEXT)

    self.newBlockBtn = CreateFrame("Button", nil, self.planPane, "UIPanelButtonTemplate")
    self.newBlockBtn:SetSize(82, 24)
    self.newBlockBtn:SetPoint("BOTTOMLEFT", 10, 12)
    self.newBlockBtn:SetText(BT:L("RL_BTN_NEW_BLOCK"))
    self.newBlockBtn:SetScript("OnClick", function()
        RS.selectedBlock = nil
        RS:ClearBlockEditor()
        RS:RefreshPlanRows()
    end)
    self.saveBlockBtn = CreateFrame("Button", nil, self.planPane, "UIPanelButtonTemplate")
    self.saveBlockBtn:SetSize(100, 24)
    self.saveBlockBtn:SetPoint("LEFT", self.newBlockBtn, "RIGHT", 6, 0)
    self.saveBlockBtn:SetScript("OnClick", function() RS:SaveEditorBlock() end)

    self.deleteBlockBtn = CreateFrame("Button", nil, self.planPane, "UIPanelButtonTemplate")
    self.deleteBlockBtn:SetSize(100, 24)
    self.deleteBlockBtn:SetPoint("LEFT", self.saveBlockBtn, "RIGHT", 6, 0)
    self.deleteBlockBtn:SetText(BT:L("RL_BTN_DELETE_BLOCK"))
    self.deleteBlockBtn:SetScript("OnClick", function() RS:DeleteSelected() end)
    self.deleteBlockBtn:Disable()

    self.planStateFS = self.planPane:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.planStateFS:SetPoint("BOTTOMLEFT", self.deleteBlockBtn, "RIGHT", 6, 0)
    self.planStateFS:SetPoint("BOTTOMRIGHT", -10, 18)
    self.planStateFS:SetJustifyH("RIGHT")

    local previousFormat = nil
    self.outputButtons = {}
    for _, format in ipairs(OUTPUT_CYCLE) do
        local button = CreateFrame("Button", nil, self.outputPane, "UIPanelButtonTemplate")
        button:SetSize(format == "DISCORD" and 82 or 62, 22)
        if previousFormat then button:SetPoint("LEFT", previousFormat, "RIGHT", 4, 0)
        else button:SetPoint("TOPLEFT", 10, -38) end
        button:SetText(BT:L("RL_FORMAT_" .. format))
        button:SetScript("OnClick", function() RS:SetOutputFormat(format) end)
        self.outputButtons[format] = button
        previousFormat = button
    end

    self.scopeButtons = {}
    self.scopeButtons.BOSS = CreateFrame("Button", nil, self.outputPane, "UIPanelButtonTemplate")
    self.scopeButtons.BOSS:SetSize(82, 22)
    self.scopeButtons.BOSS:SetPoint("TOPLEFT", 10, -65)
    self.scopeButtons.BOSS:SetText(BT:L("RL_SCOPE_BOSS"))
    self.scopeButtons.BOSS:SetScript("OnClick", function() RS:SetOutputScope("BOSS") end)
    self.scopeButtons.INSTANCE = CreateFrame("Button", nil, self.outputPane, "UIPanelButtonTemplate")
    self.scopeButtons.INSTANCE:SetSize(112, 22)
    self.scopeButtons.INSTANCE:SetPoint("LEFT", self.scopeButtons.BOSS, "RIGHT", 4, 0)
    self.scopeButtons.INSTANCE:SetText(BT:L("RL_SCOPE_INSTANCE"))
    self.scopeButtons.INSTANCE:SetScript("OnClick", function() RS:SetOutputScope("INSTANCE") end)

    self.outputInset, self.outputScroll, self.outputEdit = CreateMultilineEdit(
        self.outputPane, self:GetFontObject("small"))
    self.outputEdit:SetMaxLetters(100000)
    self.outputInset:SetPoint("TOPLEFT", 10, -94)
    self.outputInset:SetPoint("BOTTOMRIGHT", -10, 48)
    self.outputEdit:SetScript("OnEditFocusGained", function(box) box:HighlightText() end)
    self.outputEdit:SetScript("OnTextChanged", function(box, userInput)
        if userInput and not RS.loadingOutput then
            RS.loadingOutput = true
            box:SetText(RS.previewText or "")
            box:HighlightText()
            RS.loadingOutput = false
        end
    end)

    self.outputActions = CreateFrame("Frame", nil, self.outputPane)
    self.outputActions:SetPoint("BOTTOMLEFT", 10, 10)
    self.outputActions:SetPoint("BOTTOMRIGHT", -10, 10)
    self.outputActions:SetHeight(26)

    self.shareBtn = CreateFrame("Button", nil, self.outputPane, "UIPanelButtonTemplate")
    self.shareBtn:SetSize(80, 24)
    self.shareBtn:SetPoint("BOTTOMLEFT", 10, 14)
    self.shareBtn:SetText(BT:L("RL_BTN_SHARE_WOW"))
    self.shareBtn:SetScript("OnClick", function() RS:SharePlan() end)
    self.copyBtn = CreateFrame("Button", nil, self.outputPane, "UIPanelButtonTemplate")
    self.copyBtn:SetSize(65, 24)
    self.copyBtn:SetPoint("LEFT", self.shareBtn, "RIGHT", 5, 0)
    self.copyBtn:SetText(BT:L("RL_BTN_COPY"))
    self.copyBtn:SetScript("OnClick", function() RS:CopyPreview() end)
    self.exportBtn = CreateFrame("Button", nil, self.outputPane, "UIPanelButtonTemplate")
    self.exportBtn:SetSize(60, 24)
    self.exportBtn:SetPoint("LEFT", self.copyBtn, "RIGHT", 5, 0)
    self.exportBtn:SetText(BT:L("RL_BTN_EXPORT"))
    self.exportBtn:SetScript("OnClick", function() RS:ShowExportDialog() end)
    self.importBtn = CreateFrame("Button", nil, self.outputPane, "UIPanelButtonTemplate")
    self.importBtn:SetSize(60, 24)
    self.importBtn:SetPoint("LEFT", self.exportBtn, "RIGHT", 5, 0)
    self.importBtn:SetText(BT:L("RL_BTN_IMPORT"))
    self.importBtn:SetScript("OnClick", function() RS:ShowImportDialog() end)

    -- Footer status + navigation.
    local footer = CreateFrame("Frame", nil, content)
    self.footer = footer
    footer:SetHeight(FOOTER_H)
    self.journalBtn = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    self.journalBtn:SetSize(110, 24)
    self.journalBtn:SetPoint("LEFT", 0, 0)
    self.journalBtn:SetText(BT:L("BTN_JOURNAL"))
    self.journalBtn:SetScript("OnClick", function()
        frame:Hide()
        BT.Journal.difficulty = RS.difficulty
        BT:OpenJournal(RS.selectedKey)
    end)
    self.statusFS = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.statusFS:SetPoint("LEFT", self.journalBtn, "RIGHT", 12, 0)
    self.statusFS:SetPoint("RIGHT", -102, 0)
    self.statusFS:SetJustifyH("LEFT")
    self.closeBtn = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    self.closeBtn:SetSize(90, 24)
    self.closeBtn:SetPoint("RIGHT", 0, 0)
    self.closeBtn:SetText(BT:L("BTN_CLOSE"))
    self.closeBtn:SetScript("OnClick", function() frame:Hide() end)

    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(24, 24)
    grip:SetPoint("BOTTOMRIGHT", -5, 5)
    local gripTexture = grip:CreateTexture(nil, "ARTWORK")
    gripTexture:SetAllPoints()
    gripTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
    end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        BT.db.raidStudioWidth = math.floor(frame:GetWidth() + 0.5)
        BT.db.raidStudioHeight = math.floor(frame:GetHeight() + 0.5)
        RS:Layout()
    end)

    frame:SetScript("OnShow", function()
        RS:ApplyFonts()
        RS:Layout()
        RS:RefreshAll()
    end)
    frame:SetScript("OnHide", function()
        RS.bossPicker:Hide()
        RS.presetPicker:Hide()
        RS.slotPicker:Hide()
    end)
    frame:SetScript("OnSizeChanged", function()
        if not RS.layouting then RS:ScheduleLayout() end
    end)
    if Theme then
        Theme:StyleWindow(frame)
        Theme:StyleAddonTree(frame)
        Theme:StyleTitle(self.bossTitle)
        Theme:StyleTitle(self.sourcePane.title)
        Theme:StyleTitle(self.planPane.title)
        Theme:StyleTitle(self.outputPane.title)
    end
    frame:Hide()
    self:ClearBlockEditor()
    self:UpdateActionButtons()
    return frame
end

function RS:ApplyFonts()
    if not self.window then return end
    if BT.Journal then BT.Journal:ApplyAccessibilityFonts() end
    local section = self:GetFontObject("section")
    local body = self:GetFontObject("body")
    local small = self:GetFontObject("small")
    self.bossTitle:SetFontObject(section)
    self.bossCountFS:SetFontObject(small)
    self.sourcePane.title:SetFontObject(section)
    self.planPane.title:SetFontObject(section)
    self.outputPane.title:SetFontObject(section)
    self.sourceHint:SetFontObject(small)
    self.blockEditorLabel:SetFontObject(body)
    self.blockEdit:SetFontObject(small)
    self.outputEdit:SetFontObject(small)
    self.planStateFS:SetFontObject(small)
    self.statusFS:SetFontObject(small)
    self.fontValueBtn:SetText(string.format("%d%%", math.floor(self:GetFontScale() * 100 + 0.5)))
    if self.bossList then
        self.bossList:SetFontObjects(section, body, body,
            math.floor(22 * self:GetFontScale() + 0.5), small)
    end
end

function RS:ScheduleLayout()
    self.layoutToken = (self.layoutToken or 0) + 1
    local token = self.layoutToken
    C_Timer.After(0.03, function()
        if RS.window and token == RS.layoutToken then RS:Layout() end
    end)
end

function RS:Layout()
    if not self.window or not self.content or self.layouting then return end
    self.layouting = true
    local width = self.content:GetWidth()
    if not width or width < 700 then width = math.max(900, self.window:GetWidth() - 50) end
    local sourceW = Clamp(math.floor(width * 0.28 + 0.5), 250, 340)
    local planW = Clamp(math.floor(width * 0.35 + 0.5), 320, 450)
    local outputW = width - sourceW - planW - PANE_GAP * 2
    if outputW < 300 then
        local missing = 300 - outputW
        local takeSource = math.min(missing, math.max(0, sourceW - 240))
        sourceW = sourceW - takeSource
        missing = missing - takeSource
        planW = planW - math.min(missing, math.max(0, planW - 300))
        outputW = width - sourceW - planW - PANE_GAP * 2
    end

    self.toolbar:ClearAllPoints()
    self.toolbar:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
    self.toolbar:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, 0)
    self.footer:ClearAllPoints()
    self.footer:SetPoint("BOTTOMLEFT", self.content, "BOTTOMLEFT", 0, 0)
    self.footer:SetPoint("BOTTOMRIGHT", self.content, "BOTTOMRIGHT", 0, 0)

    self.sourcePane:ClearAllPoints()
    self.sourcePane:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -TOOLBAR_H)
    self.sourcePane:SetPoint("BOTTOMLEFT", self.content, "BOTTOMLEFT", 0, FOOTER_H)
    self.sourcePane:SetWidth(sourceW)
    self.planPane:ClearAllPoints()
    self.planPane:SetPoint("TOPLEFT", self.sourcePane, "TOPRIGHT", PANE_GAP, 0)
    self.planPane:SetPoint("BOTTOMLEFT", self.sourcePane, "BOTTOMRIGHT", PANE_GAP, 0)
    self.planPane:SetWidth(planW)
    self.outputPane:ClearAllPoints()
    self.outputPane:SetPoint("TOPLEFT", self.planPane, "TOPRIGHT", PANE_GAP, 0)
    self.outputPane:SetPoint("BOTTOMRIGHT", self.content, "BOTTOMRIGHT", 0, FOOTER_H)

    if Theme then
        local planControlHeight = Theme:LayoutButtonBar(self.planControls,
            { self.upBtn, self.downBtn, self.deleteBtn, self.undoBtn, self.clearPlanBtn },
            math.max(180, planW - 20), { buttonOptions = { compact = true } })
        self.planScroll:ClearAllPoints()
        self.planScroll:SetPoint("TOPLEFT", 10, -42 - planControlHeight)
        self.planScroll:SetPoint("BOTTOMRIGHT", -28, 176)

        local outputActionHeight = Theme:LayoutButtonBar(self.outputActions,
            { self.shareBtn, self.copyBtn, self.exportBtn, self.importBtn },
            math.max(180, outputW - 20), { buttonOptions = { compact = false } })
        self.outputInset:ClearAllPoints()
        self.outputInset:SetPoint("TOPLEFT", 10, -94)
        self.outputInset:SetPoint("BOTTOMRIGHT", -10, 16 + outputActionHeight)
    end

    self.sourceBody:SetWidth(math.max(180, self.sourceScroll:GetWidth() - 8))
    self.planBody:SetWidth(math.max(220, self.planScroll:GetWidth() - 8))
    self.blockEdit:SetWidth(math.max(180, self.blockScroll:GetWidth() - 8))
    self.outputEdit:SetWidth(math.max(180, self.outputScroll:GetWidth() - 8))
    if BT.db and self.window:IsShown() then
        BT.db.raidStudioWidth = math.floor(self.window:GetWidth() + 0.5)
        BT.db.raidStudioHeight = math.floor(self.window:GetHeight() + 0.5)
    end
    self.layouting = false
    self:RefreshSourceRows()
    self:RefreshPlanRows()
    self:UpdatePreview()
end

function RS:IsSourceAdded(record)
    local signature = record and record.block and SourceSignature(record.block.source)
    if not signature then return false end
    local plan = self:GetStoredPlan(true)
    for _, block in ipairs(plan and plan.blocks or {}) do
        if SourceSignature(block.source) == signature then return true end
    end
    return false
end

function RS:RefreshSourceRows()
    if not self.sourceRowPool then return end
    self.sourceRowPool:ReleaseAll()
    local width = self.sourceScroll:GetWidth() - 8
    if not width or width < 120 then width = 230 end
    self.sourceBody:SetWidth(width)
    local y = 0
    local scale = self:GetFontScale()
    for _, record in ipairs(self:BuildSourceRecords()) do
        local row = self.sourceRowPool:Acquire()
        if not row.category then
            row.category = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            row.category:SetPoint("TOPLEFT", 5, -4)
            row.category:SetJustifyH("LEFT")
            row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            row.text:SetPoint("TOPLEFT", 5, -20)
            row.text:SetJustifyH("LEFT")
            row.text:SetJustifyV("TOP")
            row.text:SetWordWrap(true)
            row.text:SetNonSpaceWrap(true)
            row.add = row:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            row.add:SetPoint("TOPRIGHT", -5, -5)
            row.added = row:CreateTexture(nil, "ARTWORK")
            row.added:SetPoint("TOPRIGHT", -6, -6)
            row.added:SetSize(16, 16)
            row.added:SetAtlas("checkmark-minimal")
            row.added:SetVertexColor(0.3, 1, 0.45, 1)
            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(0.894, 0.776, 0.459, 0.12)
            row:SetScript("OnClick", function(button) RS:AddSourceRecord(button._record) end)
            row:SetScript("OnEnter", function(button)
                GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
                GameTooltip:SetText(BT:L("RL_TOOLTIP_ADD_SOURCE"), 1, 1, 1)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        row._record = record
        row.category:SetFontObject(self:GetFontObject("small"))
        row.category:SetText("|ffc9a44c" .. BT:L(SOURCE_LABEL_KEYS[record.category]) .. "|r")
        row.text:SetFontObject(self:GetFontObject("small"))
        row.text:SetWidth(width - 28)
        row.text:SetText(record.text)
        local added = self:IsSourceAdded(record)
        row.add:SetFontObject(self:GetFontObject("section"))
        row.add:SetText("|cffffcc00+|r")
        row.add:SetShown(not added)
        row.added:SetShown(added)
        local height = math.max(46, 24 + StringHeight(row.text, 12 * scale))
        row:SetSize(width, height)
        row:SetPoint("TOPLEFT", self.sourceBody, "TOPLEFT", 0, y)
        row:Show()
        y = y - height - 3
    end
    self.sourceBody:SetHeight(math.max(10, -y))
end

function RS:RefreshPlanRows()
    if not self.planRowPool then return end
    self.planRowPool:ReleaseAll()
    local plan = self:GetStoredPlan(true)
    local width = self.planScroll:GetWidth() - 8
    if not width or width < 160 then width = 290 end
    self.planBody:SetWidth(width)
    local y = 0
    local scale = self:GetFontScale()
    for index, block in ipairs(plan and plan.blocks or {}) do
        local row = self.planRowPool:Acquire()
        if not row.kind then
            row.number = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            row.number:SetPoint("TOPLEFT", 5, -5)
            row.number:SetWidth(24)
            row.number:SetJustifyH("RIGHT")
            row.kind = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            row.kind:SetPoint("TOPLEFT", 36, -5)
            row.kind:SetJustifyH("LEFT")
            row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            row.text:SetPoint("TOPLEFT", 36, -21)
            row.text:SetJustifyH("LEFT")
            row.text:SetJustifyV("TOP")
            row.text:SetWordWrap(true)
            row.text:SetNonSpaceWrap(true)
            row.selected = row:CreateTexture(nil, "BACKGROUND")
            row.selected:SetAllPoints()
            row.selected:SetColorTexture(0.788, 0.643, 0.298, 0.28)
            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(0.894, 0.776, 0.459, 0.12)
            row:SetScript("OnClick", function(button) RS:SelectBlock(button._index) end)
        end
        row._index = index
        row.number:SetFontObject(self:GetFontObject("small"))
        row.number:SetText(tostring(index) .. ".")
        row.kind:SetFontObject(self:GetFontObject("small"))
        row.kind:SetText((KIND_COLORS[block.kind] or "|cffffffff")
            .. BT:L(KIND_LABEL_KEYS[block.kind]) .. "|r")
        row.text:SetFontObject(self:GetFontObject("small"))
        row.text:SetWidth(width - 42)
        row.text:SetText(self:ResolveBlockText(block))
        row.selected:SetShown(index == self.selectedBlock)
        local height = math.max(46, 25 + StringHeight(row.text, 12 * scale))
        row:SetSize(width, height)
        row:SetPoint("TOPLEFT", self.planBody, "TOPLEFT", 0, y)
        row:Show()
        y = y - height - 3
    end
    self.planBody:SetHeight(math.max(10, -y))
    if self.planStateFS then
        self.planStateFS:SetText("|cff55dd88" .. string.format(BT:L("RL_AUTOSAVED_COUNT"),
            plan and #plan.blocks or 0) .. "|r")
    end
    local selected = self.selectedBlock
    SetButtonEnabled(self.upBtn, selected ~= nil and selected > 1)
    SetButtonEnabled(self.downBtn, selected ~= nil and plan ~= nil and selected < #plan.blocks)
    SetButtonEnabled(self.deleteBtn,
        selected ~= nil and plan ~= nil and plan.blocks[selected] ~= nil)
    SetButtonEnabled(self.deleteBlockBtn,
        selected ~= nil and plan ~= nil and plan.blocks[selected] ~= nil)
end

function RS:UpdatePreview()
    if not self.outputEdit then return end
    for format, button in pairs(self.outputButtons) do
        if format == self.outputFormat then button:LockHighlight()
        else button:UnlockHighlight() end
        if Theme then Theme:SetSelected(button, format == self.outputFormat) end
    end
    self:UpdateScopeButtons()
    self.previewText = self:BuildPreview(self.outputFormat)
    self.loadingOutput = true
    self.outputEdit:SetText(self.previewText)
    self.outputEdit:SetCursorPosition(0)
    self.loadingOutput = false
end

function RS:RefreshAll()
    if not self.window then return end
    if not self.selectedKey or not (BT_BossData and BT_BossData[self.selectedKey]) then
        self.selectedKey = C.SortedBossKeys()[1]
    end
    local data = self.selectedKey and BT_BossData and BT_BossData[self.selectedKey]
    self.difficulty = C.ResolveContentDifficulty(data,
        self.requestedDifficulty or self.difficulty or D.activeDifficulty or "NORMAL")
    self:GetStoredPlan(true)
    self.bossTitle:SetText(tostring(self.selectedKey))
    local diff = self.difficulty
    local color = C.DIFF_COLORS[diff]
    self.diffBtn:SetText((color or "") .. DifficultyLabel(diff) .. (color and "|r" or ""))
    self.diffBtn:SetShown(C.ShouldShowDifficultySelector(data))
    self.bossTitle:ClearAllPoints()
    self.bossTitle:SetPoint("LEFT", self.nextBossBtn, "RIGHT", 10, 0)
    self.bossTitle:SetPoint("RIGHT", self.diffBtn:IsShown() and -260 or -152, 0)
    if Theme then
        if self.diffBtn:IsShown() then Theme:FitButton(self.diffBtn, { compact = true }) end
        Theme:StyleAddonTree(self.window)
    end
    self:RefreshNavigator()
    self:UpdateActionButtons()
    self:RefreshSourceRows()
    self:RefreshPlanRows()
    self:UpdatePreview()
end

local function CreateStudioDialog(titleKey, height)
    local dialog = CreateFrame("Frame", nil, RS.window or UIParent, "TooltipBackdropTemplate")
    dialog:SetSize(560, height or 360)
    dialog:SetPoint("CENTER", RS.window or UIParent, "CENTER", 0, 0)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetToplevel(true)
    dialog:SetClampedToScreen(true)
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
    dialog:SetScript("OnDragStop", function(frame) frame:StopMovingOrSizing() end)
    local close = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dialog.title:SetPoint("TOPLEFT", 12, -10)
    dialog.title:SetText(BT:L(titleKey))
    dialog.hint = dialog:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    dialog.hint:SetPoint("TOPLEFT", dialog.title, "BOTTOMLEFT", 0, -4)
    dialog.hint:SetPoint("RIGHT", -12, 0)
    dialog.hint:SetJustifyH("LEFT")
    if Theme then
        Theme:StyleWindow(dialog)
        Theme:StyleTitle(dialog.title)
    end
    return dialog
end

function RS:ShowExportDialog()
    local exportString = self:ExportPackage()
    if not exportString then return end
    if not self.exportDialog then
        local dialog = CreateStudioDialog("RL_EXPORT_TITLE", 360)
        self.exportDialog = dialog
        dialog.hint:SetText(BT:L("RL_EXPORT_HINT"))
        dialog.inset, dialog.scroll, dialog.edit = CreateMultilineEdit(dialog, GameFontHighlightSmall)
        dialog.edit:SetMaxLetters(250000)
        dialog.inset:SetPoint("TOPLEFT", 10, -52)
        dialog.inset:SetPoint("BOTTOMRIGHT", -10, 10)
        dialog.edit:SetScript("OnEditFocusGained", function(box) box:HighlightText() end)
        dialog.edit:SetScript("OnTextChanged", function(box, userInput)
            if userInput and dialog.exportString then
                box:SetText(dialog.exportString)
                box:HighlightText()
            end
        end)
        if Theme then Theme:StyleAddonTree(dialog) end
    end
    local dialog = self.exportDialog
    dialog.exportString = exportString
    dialog.edit:SetText(exportString)
    dialog.edit:SetCursorPosition(0)
    dialog:Show()
    C_Timer.After(0.05, function()
        if dialog.edit:IsVisible() then
            dialog.edit:SetFocus()
            dialog.edit:HighlightText()
        end
    end)
end

function RS:ApplyImportedPayload(payload)
    if type(payload) ~= "table"
        or (payload.type ~= "raidplan" and payload.type ~= "raidplan_instance") then
        return false, BT:L("RL_IMPORT_INVALID")
    end
    local diff = tostring(payload.difficulty or "MYTHIC"):upper()
    if diff ~= "NORMAL" and diff ~= "HEROIC" and diff ~= "MYTHIC" then diff = "MYTHIC" end

    if payload.type == "raidplan_instance" then
        if type(payload.plans) ~= "table" then return false, BT:L("RL_IMPORT_INVALID") end
        local validPlans = {}
        local dungeonName = type(payload.dungeonName) == "string" and payload.dungeonName or nil
        for bossKey, rawPlan in pairs(payload.plans) do
            local data = type(bossKey) == "string" and BT_BossData and BT_BossData[bossKey]
            local plan = data and self:SanitizePlan(rawPlan, bossKey) or nil
            if plan and #plan.blocks > 0
                and (not dungeonName or C.ResolveDungeonName(data) == dungeonName) then
                validPlans[bossKey] = plan
                dungeonName = dungeonName or C.ResolveDungeonName(data)
            end
        end
        if not dungeonName or not next(validPlans) then return false, BT:L("RL_IMPORT_INVALID") end
        if type(BT.db.raidPlans) ~= "table" then BT.db.raidPlans = {} end
        local count = 0
        local firstImported
        for _, bossKey in ipairs(D:GetBossesForDungeon(dungeonName)) do
            local plan = validPlans[bossKey]
            if plan then
                if type(BT.db.raidPlans[bossKey]) ~= "table" then BT.db.raidPlans[bossKey] = {} end
                local previous = BT.db.raidPlans[bossKey][diff]
                if type(previous) == "table" then self:PushUndo(bossKey, diff, previous) end
                BT.db.raidPlans[bossKey][diff] = plan
                self.validatedPlans[plan] = true
                firstImported = firstImported or bossKey
                count = count + 1
            end
        end
        if firstImported then self.selectedKey = firstImported end
        self.requestedDifficulty = diff
        self.difficulty = C.ResolveContentDifficulty(
            self.selectedKey and BT_BossData[self.selectedKey], diff)
        self.outputScope = "INSTANCE"
        self.selectedBlock = nil
        self:ClearBlockEditor()
        self:RefreshAll()
        return true, string.format(BT:L("RL_IMPORT_INSTANCE_SUCCESS"), dungeonName, count)
    end

    local bossKey = type(payload.bossKey) == "string" and payload.bossKey or nil
    if not bossKey or not (BT_BossData and BT_BossData[bossKey]) then
        return false, BT:L("RL_IMPORT_BOSS_MISSING")
    end
    local plan = self:SanitizePlan(payload.plan, bossKey)
    if not plan or #plan.blocks == 0 then return false, BT:L("RL_IMPORT_INVALID") end
    if type(BT.db.raidPlans) ~= "table" then BT.db.raidPlans = {} end
    if type(BT.db.raidPlans[bossKey]) ~= "table" then BT.db.raidPlans[bossKey] = {} end
    local previous = BT.db.raidPlans[bossKey][diff]
    if type(previous) == "table" then self:PushUndo(bossKey, diff, previous) end
    BT.db.raidPlans[bossKey][diff] = plan
    self.validatedPlans[plan] = true
    self.selectedKey = bossKey
    self.requestedDifficulty = diff
    self.difficulty = C.ResolveContentDifficulty(
        self.selectedKey and BT_BossData[self.selectedKey], diff)
    self.selectedBlock = nil
    self:ClearBlockEditor()
    self:RefreshAll()
    return true, string.format(BT:L("RL_IMPORT_SUCCESS"), bossKey, DifficultyLabel(diff), #plan.blocks)
end

function RS:ShowImportDialog()
    if not self.importDialog then
        local dialog = CreateStudioDialog("RL_IMPORT_TITLE", 420)
        self.importDialog = dialog
        dialog.hint:SetText(BT:L("RL_IMPORT_HINT"))
        dialog.inset, dialog.scroll, dialog.edit = CreateMultilineEdit(dialog, GameFontHighlightSmall)
        dialog.edit:SetMaxLetters(250000)
        dialog.inset:SetPoint("TOPLEFT", 10, -52)
        dialog.inset:SetPoint("BOTTOMRIGHT", -10, 76)
        dialog.preview = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        dialog.preview:SetPoint("BOTTOMLEFT", 12, 42)
        dialog.preview:SetPoint("BOTTOMRIGHT", -12, 42)
        dialog.preview:SetHeight(28)
        dialog.preview:SetJustifyH("LEFT")
        dialog.preview:SetJustifyV("BOTTOM")
        dialog.readBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.readBtn:SetSize(118, 24)
        dialog.readBtn:SetPoint("BOTTOMLEFT", 12, 12)
        dialog.readBtn:SetText(BT:L("RL_BTN_READ_PLAN"))
        dialog.confirmBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        dialog.confirmBtn:SetSize(128, 24)
        dialog.confirmBtn:SetPoint("LEFT", dialog.readBtn, "RIGHT", 8, 0)
        dialog.confirmBtn:SetText(BT:L("RL_BTN_CONFIRM_IMPORT"))
        dialog.confirmBtn:Hide()
        dialog.readBtn:SetScript("OnClick", function()
            local payload, err = BT.ImportExport:DecodeString(dialog.edit:GetText())
            if not payload or (payload.type ~= "raidplan" and payload.type ~= "raidplan_instance") then
                dialog.pending = nil
                dialog.confirmBtn:Hide()
                dialog.preview:SetText("|cffff5555" .. (err or BT:L("RL_IMPORT_INVALID")) .. "|r")
                return
            end
            if payload.type == "raidplan_instance" then
                local count = 0
                for bossKey, rawPlan in pairs(type(payload.plans) == "table" and payload.plans or {}) do
                    local plan = BT_BossData[bossKey] and RS:SanitizePlan(rawPlan, bossKey)
                    if plan and #plan.blocks > 0 then count = count + 1 end
                end
                if count == 0 then
                    dialog.pending = nil
                    dialog.confirmBtn:Hide()
                    dialog.preview:SetText("|cffff5555" .. BT:L("RL_IMPORT_INVALID") .. "|r")
                    return
                end
                dialog.pending = payload
                dialog.preview:SetText(string.format(BT:L("RL_IMPORT_INSTANCE_PREVIEW"),
                    tostring(payload.dungeonName or "?"), DifficultyLabel(payload.difficulty), count))
                dialog.confirmBtn:Show()
                return
            end
            local bossKey = type(payload.bossKey) == "string" and payload.bossKey or "?"
            local plan = RS:SanitizePlan(payload.plan, bossKey)
            if not BT_BossData[bossKey] or not plan or #plan.blocks == 0 then
                dialog.pending = nil
                dialog.confirmBtn:Hide()
                dialog.preview:SetText("|cffff5555" .. BT:L("RL_IMPORT_INVALID") .. "|r")
                return
            end
            dialog.pending = payload
            dialog.preview:SetText(string.format(BT:L("RL_IMPORT_PREVIEW"),
                bossKey, DifficultyLabel(payload.difficulty), #plan.blocks))
            dialog.confirmBtn:Show()
        end)
        dialog.confirmBtn:SetScript("OnClick", function()
            if not dialog.pending then return end
            local ok, message = RS:ApplyImportedPayload(dialog.pending)
            RS:SetStatus(message, not ok)
            if ok then
                dialog.pending = nil
                dialog:Hide()
            end
        end)
        dialog.edit:SetScript("OnTextChanged", function(_, userInput)
            if userInput then
                dialog.pending = nil
                dialog.confirmBtn:Hide()
                dialog.preview:SetText("")
            end
        end)
        if Theme then Theme:StyleAddonTree(dialog) end
    end
    local dialog = self.importDialog
    dialog.pending = nil
    dialog.confirmBtn:Hide()
    dialog.preview:SetText("")
    dialog.edit:SetText("")
    dialog:Show()
    C_Timer.After(0.05, function()
        if dialog.edit:IsVisible() then dialog.edit:SetFocus() end
    end)
end

local function DefaultDifficulty()
    local diff = D.activeDifficulty
    if diff == "LFR" then diff = "NORMAL" end
    for _, candidate in ipairs(DIFF_CYCLE) do
        if candidate == diff then return diff end
    end
    return "NORMAL"
end

function BT:OpenRaidStudio(bossKey, difficulty)
    local studio = self.RaidStudio
    local toggleOnly = bossKey == nil and difficulty == nil
    if not bossKey then
        bossKey = (self.Journal and self.Journal.selectedKey)
            or (self.db and self.db.lastBossKey)
            or C.SortedBossKeys()[1]
    end
    if bossKey and BT_BossData and BT_BossData[bossKey] then
        studio.selectedKey = bossKey
    end
    local selectedData = studio.selectedKey and BT_BossData and BT_BossData[studio.selectedKey]
    if C.IsRaidData(selectedData) or C.IsDungeonDifficultySelectionEnabled() then
        studio.requestedDifficulty = difficulty or studio.requestedDifficulty
            or studio.difficulty or DefaultDifficulty()
    else
        studio.requestedDifficulty = studio.requestedDifficulty
            or difficulty or studio.difficulty or DefaultDifficulty()
    end
    studio.difficulty = C.ResolveContentDifficulty(
        selectedData, studio.requestedDifficulty)
    local window = studio:GetWindow()
    if window:IsShown() and toggleOnly then
        window:Hide()
        return
    end
    if self.Journal and self.Journal.window and self.Journal.window:IsShown() then
        self.Journal.window:Hide()
    end
    window:Show()
    studio:ApplyFonts()
    studio:Layout()
    studio:RefreshAll()
end
