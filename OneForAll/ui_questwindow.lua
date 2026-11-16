-- OneForAll_Forever/ui_questwindow.lua
local addonName, OFA = ...
OFA = OFA or _G.OFA or {}
_G.OFA = OFA

local lastBroadcastTime = 0
local subzoneQuests = {}   -- { [questID] = { id = ..., name = ..., link = ..., disabled = false } }
local questOrder = {}      -- Ordered list of questIDs for deterministic rendering
local questRows = {}       -- Reusable UI row buttons

-- Generates a shortcode under 5 characters based on the primary quest name
local function GenerateShortCode(questName)
    if not questName then return "OFA" end
    local cleanName = questName:gsub("[^%w]", "")
    if #cleanName > 4 then
        cleanName = cleanName:sub(1, 4)
    end
    return (#cleanName > 0) and cleanName:upper() or "OFA"
end

-- Creates the main floating frame once and caches it
local function GetOrCreateQuestWindow()
    if OFA.QuestWindowFrame then
        return OFA.QuestWindowFrame
    end

    local frame = CreateFrame("Frame", "OFA_QuestWindowFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(320, 220)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -6)
    frame.title:SetText("OneForAll: Sub-Zone")

    frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -28)
    frame.hint:SetText("|cffaaaaaaShift-Click a quest to exclude from yell|r")

    frame.broadcastBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.broadcastBtn:SetSize(180, 26)
    frame.broadcastBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 12)
    frame.broadcastBtn:SetText("Broadcast & Auto-Invite")
    frame.broadcastBtn:SetScript("OnClick", function()
        OFA:ExecuteBroadcast()
    end)

    OFA.QuestWindowFrame = frame
    return frame
end

-- Renders or refreshes the quest list rows inside the floating window
local function RefreshQuestRows(frame)
    for _, row in ipairs(questRows) do
        row:Hide()
    end

    local yOffset = -46
    for index, questID in ipairs(questOrder) do
        local qData = subzoneQuests[questID]
        if qData then
            local row = questRows[index]
            if not row then
                row = CreateFrame("Button", nil, frame)
                row:SetSize(288, 20)
                row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.text:SetPoint("LEFT", row, "LEFT", 4, 0)
                row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                row.text:SetJustifyH("LEFT")
                row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
                questRows[index] = row
            end

            row:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, yOffset)
            row.questID = questID

            if qData.disabled then
                row.text:SetText("|cff666666" .. qData.name .. " (Excluded)|r")
            else
                row.text:SetText("|cffffd100" .. qData.name .. "|r")
            end

            row:SetScript("OnClick", function(self)
                if IsShiftKeyDown() then
                    local entry = subzoneQuests[self.questID]
                    if entry then
                        entry.disabled = not entry.disabled
                        RefreshQuestRows(frame)
                    end
                end
            end)

            row:Show()
            yOffset = yOffset - 22
        end
    end

    -- Dynamically resize frame height to fit active rows cleanly
    local totalHeight = math.max(130, 95 + (#questOrder * 22))
    frame:SetHeight(totalHeight)
end

-- Opens or updates the floating Quest Window for the given sub-zone
function OFA:ShowSubZoneQuestWindow(zoneName, questsInZone)
    if OFA:GetConfig("socialMode") ~= "Quest Window" then return end

    local previousState = subzoneQuests
    subzoneQuests = {}
    questOrder = {}

    for _, q in ipairs(questsInZone) do
        local wasDisabled = previousState[q.id] and previousState[q.id].disabled or false
        subzoneQuests[q.id] = {
            id = q.id,
            name = q.name,
            link = q.link,
            disabled = wasDisabled
        }
        table.insert(questOrder, q.id)
    end

    local frame = GetOrCreateQuestWindow()
    frame.title:SetText("OneForAll: " .. (zone