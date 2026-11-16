-- config.lua
local addonName, OFA = ...
OFA = OFA or _G.OFA or {}
_G.OFA = OFA

-- Initialize saved variables and default settings
OFA_Config = OFA_Config or {}

local defaults = {
    socialMode = "Disabled", -- Options: "Disabled" or "Quest Window"
    spamCooldown = 3,        -- Cooldown in seconds between /yell broadcasts
}

for key, value in pairs(defaults) do
    if OFA_Config[key] == nil then
        OFA_Config[key] = value
    end
end

-- Helper accessors scoped to OFA
function OFA:GetConfig(key)
    return OFA_Config[key]
end

function OFA:SetConfig(key, value)
    OFA_Config[key] = value
end