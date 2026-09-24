BossTactics = {
    L = function(_, key) return key end,
}

function strtrim(value)
    return (tostring(value):gsub("^%s+", ""):gsub("%s+$", ""))
end

dofile("ImportExport.lua")

local payload = {
    type = "all",
    bosses = {
        ["Meu Chefe"] = {
            name = "Meu Chefe",
            dungeonName = "Cavernas Ígneas",
            tldr = { "TANQUE: ação", "CURADOR: proteção", "DPS: Pederneiro" },
        },
    },
}

local atual = BossTactics.ImportExport:ExportString(payload)
assert(atual:sub(1, 5) == "!BT1!", "prefixo atual incorreto")

for _, prefixo in ipairs({ "!BT1!", "!BM1!", "!BM2!" }) do
    local pacote = prefixo .. atual:sub(6)
    local lido, erro = BossTactics.ImportExport:DecodeString(pacote)
    assert(lido, erro or "falha sem mensagem")
    assert(lido.bosses["Meu Chefe"].dungeonName == "Cavernas Ígneas", "acentuação alterada")
    assert(lido.bosses["Meu Chefe"].tldr[1] == "TANQUE: ação", "conteúdo alterado")
end

local invalido = BossTactics.ImportExport:DecodeString("!BT!abc")
assert(invalido == nil, "prefixo obsoleto não documentado foi aceito")

print("OK: !BT1!, !BM1!, !BM2! e UTF-8")
