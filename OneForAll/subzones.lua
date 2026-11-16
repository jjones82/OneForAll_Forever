-- OneForAll_Forever/subzones.lua
local addonName, OFA = ...
OFA = OFA or _G.OFA or {}
_G.OFA = OFA

-- Scans the active Quest Log for quests belonging to the player's current zone
function OFA:GetActiveZoneQuests(targetZone)
    local matchingQuests = {}
    if not targetZone or targetZone == "" then return matchingQuests end

    local numEntries = GetNumQuestLogEntries()
    local currentHeader = nil

    for i = 1, numEntries do
        local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)
        if isHeader then
            currentHeader = title
        elseif currentHeader == targetZone and questID then
            local link = GetQuestLink(i)
            if link then
                table.insert(matchingQuests, {
                    id = questID,
                    name = title,
                    link = link
                })
            end
        end
    end

    return matchingQuests
end

-- Evaluates current zone/sub-zone and opens or updates the Quest Window
function OFA:EvaluateSubZoneQuests()
    if OFA:GetConfig("socialMode") ~= "Quest Window" then
        if OFA.HideSubZoneQuestWindow then
            OFA:HideSubZoneQuestWindow()
        end
        return
    end

    local zone = GetZoneText()
    local subZone = GetSubZoneText()
    local displayZone = (subZone and subZone ~= "") and subZone or zone

    local activeQuests = OFA:GetActiveZoneQuests(zone)
    if #activeQuests > 0 then
        if OFA.ShowSubZoneQuestWindow then
            OFA:ShowSubZoneQuestWindow(displayZone, activeQuests)
        end
    else
        if OFA.HideSubZoneQuestWindow then
            OFA:HideSubZoneQuestWindow()
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")

eventFrame:SetScript("OnEvent", function()
    OFA:EvaluateSubZoneQuests()
end)