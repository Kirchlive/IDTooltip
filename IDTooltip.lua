-- ItemIDTooltip Extended v4: Shows Item ID, Spell ID, Buff/Debuff ID in tooltips
-- One-time SpellRec scan at load (~250ms), zero-cost lookups on hover
-- Vanilla WoW 1.12 / TurtleWoW | Lua 5.0
-- Original: cyaohiri | Extended: Tetto & Teto

local ID_R, ID_G, ID_B = 1, 1, 0  -- Yellow

-- Global spell lookup: ["Name|Rank"] = spellId
local nameRankMap = {}
-- Fallback: ["Name"] = spellId (highest rank, for when rank is unknown)
local nameOnlyMap = {}

-- === ONE-TIME SpellRec Scan at Addon Load ===
local function BuildSpellMap()
    if not GetSpellRec then return end
    
    local ranges = { {1, 30000}, {40000, 55000} }
    local count = 0
    
    for _, range in ipairs(ranges) do
        for id = range[1], range[2] do
            local ok, rec = pcall(GetSpellRec, id)
            if ok and rec and rec.name and rec.name ~= "" then
                -- Name + Rank key (exact match)
                local rank = rec.rank or ""
                local key = rec.name .. "|" .. rank
                nameRankMap[key] = id
                
                -- Name-only key (last one wins = highest ID = usually highest rank)
                nameOnlyMap[rec.name] = id
                
                count = count + 1
            end
        end
    end
end

-- Build map immediately at load
BuildSpellMap()

-- === Helper: Add ID line to tooltip (avoid duplicates) ===
local function AddIDLine(tooltip, label, id)
    if not id or id == 0 then return end
    local idText = label .. ": " .. tostring(id)
    local numLines = tooltip:NumLines()
    if numLines then
        for i = 1, numLines do
            local line = getglobal(tooltip:GetName() .. "TextLeft" .. i)
            if line and line:GetText() == idText then return end
        end
    end
    tooltip:AddLine(idText, ID_R, ID_G, ID_B)
    tooltip:Show()
end

-- === Helper: Get spell name from tooltip ===
local function GetTooltipName(tooltip)
    local numLines = tooltip:NumLines()
    if numLines and numLines > 0 then
        local nameLine = getglobal(tooltip:GetName() .. "TextLeft1")
        if nameLine then return nameLine:GetText() end
    end
    return nil
end

-- === Helper: Get spell rank from tooltip (usually right side of line 1) ===
local function GetTooltipRank(tooltip)
    local numLines = tooltip:NumLines()
    if numLines and numLines > 0 then
        local rankLine = getglobal(tooltip:GetName() .. "TextRight1")
        if rankLine then
            local text = rankLine:GetText()
            if text and text ~= "" then return text end
        end
    end
    return nil
end

-- === Helper: Lookup spell ID from name + optional rank ===
local function LookupSpellId(name, rank)
    if not name then return nil end
    
    -- Try exact name+rank first
    if rank and rank ~= "" then
        local id = nameRankMap[name .. "|" .. rank]
        if id then return id end
    end
    
    -- Try name with empty rank
    local id = nameRankMap[name .. "|"]
    if id then return id end
    
    -- Fallback: name-only (highest rank)
    return nameOnlyMap[name]
end

-- === Helper: Extract item ID from an item link string ===
local function ExtractItemId(link)
    if not link then return nil end
    local _, _, id = string.find(link, "item:(%d+)")
    return id
end

-- === Helper: Extract quest ID from a quest link string ===
local function ExtractQuestId(link)
    if not link then return nil end
    local _, _, id = string.find(link, "quest:(%d+)")
    return id
end

-- === Helper: Add any ID found in a hyperlink ===
local function AddHyperlinkID(tooltip, link)
    if not link then return end
    local itemId = ExtractItemId(link)
    if itemId then
        AddIDLine(tooltip, "Item ID", itemId)
        return
    end
    local questId = ExtractQuestId(link)
    if questId then
        AddIDLine(tooltip, "Quest ID", questId)
        return
    end
    -- In Vanilla 1.12, spell links use "enchant:SPELLID" format (not "spell:")
    -- Check "enchant:" and determine if it's a spell via SpellInfo
    local _, _, enchantId = string.find(link, "enchant:(%d+)")
    if enchantId then
        local numId = tonumber(enchantId)
        -- Check if this ID is actually a spell (has a name in SpellInfo)
        local isSpell = false
        if numId and SpellInfo then
            local name = SpellInfo(numId)
            if name then isSpell = true end
        end
        if isSpell then
            AddIDLine(tooltip, "Spell ID", enchantId)
        else
            AddIDLine(tooltip, "Enchant ID", enchantId)
        end
        return
    end
    -- Spell links (retail format, unlikely in 1.12 but safe)
    local _, _, spellId = string.find(link, "spell:(%d+)")
    if spellId then
        AddIDLine(tooltip, "Spell ID", spellId)
    end
end

-- === 1. Item Tooltips: Bag Items ===
-- SetBagItem returns hasCooldown, repairCost - MUST pass through!
local origSetBagItem = GameTooltip.SetBagItem
if origSetBagItem then
    GameTooltip.SetBagItem = function(tooltip, bag, slot)
        local hasCooldown, repairCost = origSetBagItem(tooltip, bag, slot)
        local link = GetContainerItemLink(bag, slot)
        local itemId = ExtractItemId(link)
        if itemId then AddIDLine(tooltip, "Item ID", itemId) end
        return hasCooldown, repairCost
    end
end

-- === 2. Item Tooltips: Equipped Items (Character Frame) ===
-- SetInventoryItem returns hasItem, hasCooldown - MUST pass through!
local origSetInventoryItem = GameTooltip.SetInventoryItem
if origSetInventoryItem then
    GameTooltip.SetInventoryItem = function(tooltip, unit, slot)
        local hasItem, hasCooldown = origSetInventoryItem(tooltip, unit, slot)
        local link = GetInventoryItemLink(unit, slot)
        local itemId = ExtractItemId(link)
        if itemId then AddIDLine(tooltip, "Item ID", itemId) end
        return hasItem, hasCooldown
    end
end

-- === 3. Item Tooltips: Hyperlinks (Chat links, clicked items) ===
local origSetHyperlink = GameTooltip.SetHyperlink
if origSetHyperlink then
    GameTooltip.SetHyperlink = function(tooltip, link)
        origSetHyperlink(tooltip, link)
        AddHyperlinkID(tooltip, link)
    end
end

-- ItemRefTooltip (chat link popup window)
if ItemRefTooltip and ItemRefTooltip.SetHyperlink then
    local origItemRefHL = ItemRefTooltip.SetHyperlink
    ItemRefTooltip.SetHyperlink = function(tooltip, link)
        origItemRefHL(tooltip, link)
        AddHyperlinkID(tooltip, link)
    end
end

-- === 4. Item Tooltips: OnShow fallback (catches remaining cases) ===
local origOnShow = GameTooltip:GetScript("OnShow")
GameTooltip:SetScript("OnShow", function()
    if origOnShow then origOnShow() end
    if GameTooltip.itemLink then
        local itemId = ExtractItemId(GameTooltip.itemLink)
        if itemId then AddIDLine(GameTooltip, "Item ID", itemId) end
    end
end)

-- === 5. Buff Tooltip Hook ===
local origSetUnitBuff = GameTooltip.SetUnitBuff
GameTooltip.SetUnitBuff = function(tooltip, unit, index)
    origSetUnitBuff(tooltip, unit, index)
    
    local spellId = nil
    
    -- Player buffs: GetPlayerBuffID (SuperWoW, 0-based index)
    if unit == "player" and GetPlayerBuffID then
        spellId = GetPlayerBuffID(index - 1)
    end
    
    -- Fallback: name + rank lookup from our map
    if not spellId or spellId == 0 then
        local name = GetTooltipName(tooltip)
        local rank = GetTooltipRank(tooltip)
        spellId = LookupSpellId(name, rank)
    end
    
    if spellId and spellId > 0 then
        AddIDLine(tooltip, "Spell ID", spellId)
    end
end

-- === 6. Debuff Tooltip Hook ===
local origSetUnitDebuff = GameTooltip.SetUnitDebuff
GameTooltip.SetUnitDebuff = function(tooltip, unit, index)
    origSetUnitDebuff(tooltip, unit, index)
    
    local name = GetTooltipName(tooltip)
    local rank = GetTooltipRank(tooltip)
    local spellId = LookupSpellId(name, rank)
    if spellId and spellId > 0 then
        AddIDLine(tooltip, "Spell ID", spellId)
    end
end

-- === 7. Spellbook Tooltip Hook ===
local origSetSpell = GameTooltip.SetSpell
GameTooltip.SetSpell = function(tooltip, slot, bookType)
    origSetSpell(tooltip, slot, bookType)
    
    -- Get name + rank directly from spellbook API (most reliable)
    local name, rank = GetSpellName(slot, bookType)
    if name then
        local spellId = LookupSpellId(name, rank)
        if spellId and spellId > 0 then
            AddIDLine(tooltip, "Spell ID", spellId)
        end
    end
end

-- === 8. Action Bar Tooltip Hook ===
local origSetAction = GameTooltip.SetAction
if origSetAction then
    GameTooltip.SetAction = function(tooltip, slot)
        origSetAction(tooltip, slot)
        
        if HasAction(slot) then
            -- SuperWoW GetActionText: returns text, actionType, id
            if GetActionText then
                local _, actionType, actionId = GetActionText(slot)
                if actionType == "ITEM" and actionId then
                    AddIDLine(tooltip, "Item ID", actionId)
                elseif actionType == "SPELL" and actionId then
                    AddIDLine(tooltip, "Spell ID", actionId)
                else
                    -- Fallback: tooltip name lookup
                    local name = GetTooltipName(tooltip)
                    local rank = GetTooltipRank(tooltip)
                    local spellId = LookupSpellId(name, rank)
                    if spellId and spellId > 0 then
                        AddIDLine(tooltip, "Spell ID", spellId)
                    end
                end
            else
                -- No SuperWoW: tooltip name lookup only
                local name = GetTooltipName(tooltip)
                local rank = GetTooltipRank(tooltip)
                local spellId = LookupSpellId(name, rank)
                if spellId and spellId > 0 then
                    AddIDLine(tooltip, "Spell ID", spellId)
                end
            end
        end
    end
end

-- === 9. Player Buff/Debuff Bar (top-right icons) ===
-- SetPlayerBuff is called when hovering the default buff bar icons
local origSetPlayerBuff = GameTooltip.SetPlayerBuff
if origSetPlayerBuff then
    GameTooltip.SetPlayerBuff = function(tooltip, index, filter)
        origSetPlayerBuff(tooltip, index, filter)
        
        local spellId = nil
        
        -- GetPlayerBuffID uses the buff index (0-based for beneficial, offset for harmful)
        if GetPlayerBuffID then
            spellId = GetPlayerBuffID(index)
        end
        
        -- Fallback: name lookup
        if not spellId or spellId == 0 then
            local name = GetTooltipName(tooltip)
            if name then spellId = LookupSpellId(name, nil) end
        end
        
        if spellId and spellId > 0 then
            AddIDLine(tooltip, "Spell ID", spellId)
        end
    end
end

-- === 10. Tracking Spell Tooltip Hook ===
local origSetTrackingSpell = GameTooltip.SetTrackingSpell
if origSetTrackingSpell then
    GameTooltip.SetTrackingSpell = function(tooltip)
        origSetTrackingSpell(tooltip)
        local name = GetTooltipName(tooltip)
        local spellId = LookupSpellId(name, nil)
        if spellId and spellId > 0 then
            AddIDLine(tooltip, "Spell ID", spellId)
        end
    end
end

-- === 10. Merchant Item Tooltip Hook ===
local origSetMerchantItem = GameTooltip.SetMerchantItem
if origSetMerchantItem then
    GameTooltip.SetMerchantItem = function(tooltip, index)
        origSetMerchantItem(tooltip, index)
        local link = GetMerchantItemLink(index)
        local itemId = ExtractItemId(link)
        if itemId then AddIDLine(tooltip, "Item ID", itemId) end
    end
end

-- === 11. Quest Item Tooltip Hook ===
local origSetQuestItem = GameTooltip.SetQuestItem
if origSetQuestItem then
    GameTooltip.SetQuestItem = function(tooltip, itemType, index)
        origSetQuestItem(tooltip, itemType, index)
        local link = GetQuestItemLink(itemType, index)
        local itemId = ExtractItemId(link)
        if itemId then AddIDLine(tooltip, "Item ID", itemId) end
    end
end

-- === 12. Loot Item Tooltip Hook ===
local origSetLootItem = GameTooltip.SetLootItem
if origSetLootItem then
    GameTooltip.SetLootItem = function(tooltip, slot)
        origSetLootItem(tooltip, slot)
        local link = GetLootSlotLink(slot)
        local itemId = ExtractItemId(link)
        if itemId then AddIDLine(tooltip, "Item ID", itemId) end
    end
end

-- === 14. Quest Log Item Tooltip Hook ===
local origSetQuestLogItem = GameTooltip.SetQuestLogItem

-- === 15. Quest ID via late-hooked SetItemRef + OnUpdate poller ===
-- Quest links go through SetItemRef (not SetHyperlink!)
-- Link format: "quest:QUESTID:LEVEL"
-- Problem: Other addons (pfUI, pfQuest etc.) hook SetItemRef AFTER us
-- at addon load, overwriting our hook. Our code never fires.
-- Solution: Delay our hook until PLAYER_LOGIN (all addons loaded).
-- Then use an OnUpdate poller to inject after tooltip is built.
local pendingQuestId = nil
local questInjectFrame = CreateFrame("Frame")
questInjectFrame.elapsed = 0
questInjectFrame.retries = 0
questInjectFrame:Hide()
questInjectFrame:SetScript("OnUpdate", function()
    local dt = arg1 or 0
    this.elapsed = this.elapsed + dt
    -- Wait at least 50ms for tooltip to build, retry up to ~500ms
    if this.elapsed < 0.05 then return end
    this.elapsed = 0
    this.retries = this.retries + 1
    if pendingQuestId and ItemRefTooltip:IsVisible() then
        if ItemRefTooltip:NumLines() and ItemRefTooltip:NumLines() > 0 then
            AddIDLine(ItemRefTooltip, "Quest ID", pendingQuestId)
            pendingQuestId = nil
            this:Hide()
            return
        end
    end
    -- Give up after 10 retries (~500ms)
    if this.retries >= 10 then
        pendingQuestId = nil
        this:Hide()
    end
end)

-- Helper: Try to find quest ID by name from quest log
local function LookupQuestIdByName(questName)
    if not questName or questName == "" then return nil end
    local numEntries = GetNumQuestLogEntries()
    for i = 1, numEntries do
        local title, _, _, isHeader, _, _, _, questId = GetQuestLogTitle(i)
        if not isHeader and title == questName and questId and questId > 0 then
            return tostring(questId)
        end
    end
    return nil
end

-- Helper: Extract quest name from chat link text
-- Format: "|cff7f7f7f|Hquest:0:0|h[The Elder's End]|h|r"
local function ExtractQuestNameFromText(text)
    if not text then return nil end
    local _, _, name = string.find(text, "%[(.-)%]")
    return name
end

-- Hook SetItemRef LATE — after all other addons have loaded
-- This ensures we are LAST in the hook chain, so our code always fires
local lateHookFrame = CreateFrame("Frame")
lateHookFrame:RegisterEvent("PLAYER_LOGIN")
lateHookFrame:SetScript("OnEvent", function()
    local origSetItemRef = SetItemRef
    SetItemRef = function(link, text, button)
        if link and type(link) == "string" then
            local _, _, qId = string.find(link, "quest:(%d+)")
            if qId then
                pendingQuestId = qId
            end
        end
        origSetItemRef(link, text, button)
        if pendingQuestId then
            questInjectFrame.elapsed = 0
            questInjectFrame.retries = 0
            questInjectFrame:Show()
        end
    end
    this:UnregisterEvent("PLAYER_LOGIN")
end)
