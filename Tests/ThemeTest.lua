BossTactics = {}
dofile("Theme.lua")

local Theme = BossTactics.Theme

local function MockButton(textWidth, textHeight)
    local fontString = {
        width = 0,
        SetWordWrap = function() end,
        SetNonSpaceWrap = function() end,
        GetStringWidth = function() return textWidth end,
        GetStringHeight = function() return textHeight end,
        SetWidth = function(self, width) self.width = width end,
        GetWidth = function(self) return self.width end,
    }
    return {
        GetFontString = function() return fontString end,
        SetSize = function(self, width, height) self.width, self.height = width, height end,
        GetSize = function(self) return self.width, self.height end,
        IsShown = function() return true end,
        ClearAllPoints = function() end,
        SetPoint = function(self, ...) self.point = { ... } end,
    }
end

local button = MockButton(80, 14)
local width, height = Theme:FitButton(button)
assert(width == 104, "botão não recebeu 12 unidades de margem por lado")
assert(height == 26, "altura mínima do botão comum não foi respeitada")

local compact = MockButton(20, 10)
local compactWidth, compactHeight = Theme:FitButton(compact, { compact = true })
assert(compactWidth == 44 and compactHeight == 22, "dimensões compactas incorretas")

local bar = {
    SetHeight = function(self, value) self.height = value end,
    GetWidth = function() return 150 end,
}
local first, second = MockButton(80, 14), MockButton(80, 14)
local barHeight, rows = Theme:LayoutButtonBar(bar, { first, second }, 150)
assert(rows == 2 and barHeight == 58, "barra não quebrou os botões em duas linhas")

local function MockTexture()
    return {
        SetAllPoints = function() end,
        SetPoint = function() end,
        SetHeight = function() end,
        SetWidth = function() end,
        SetTexture = function() end,
        SetColorTexture = function() end,
        SetDesaturated = function() end,
        SetAlpha = function(self, alpha) self.alpha = alpha end,
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false end,
        SetShown = function(self, shown) self.shown = shown end,
    }
end

local native = MockTexture()
local themed = MockButton(60, 14)
themed.GetNormalTexture = function() return native end
themed.GetPushedTexture = function() return nil end
themed.GetHighlightTexture = function() return nil end
themed.GetDisabledTexture = function() return nil end
themed.SetNormalTexture = function() error("SetNormalTexture não deveria ser chamado") end
themed.CreateTexture = function() return MockTexture() end
themed.HookScript = function() end
themed.IsEnabled = function() return true end
themed.GetFontString().SetTextColor = function() end
Theme:StyleButton(themed)
assert(native.alpha == 0, "arte nativa do botão não foi ocultada")

print("OK: medidas e quebra de linha do tema")
