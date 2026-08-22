-- ============================================================
--  CROTTT HUB | MINE A MOUNTAIN (TikTok Logo Edition)
-- ============================================================

-- 1. VALIDASI PLACE ID
local TARGET_PLACE_ID = 125927821145949

if game.PlaceId ~= TARGET_PLACE_ID then
    warn("[CROTTT HUB] Game tidak didukung! Script hanya untuk Mine a Mountain (PlaceId: " .. tostring(TARGET_PLACE_ID) .. ")")
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "CROTTT HUB - Akses Ditolak",
            Text = "Script ini HANYA dapat dijalankan pada game Mine a Mountain!",
            Duration = 6
        })
    end)
    return
end

-- 2. LOADER WINDUI DENGAN CLONEREF & MULTI-FALLBACK
local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService        = cloneref(game:GetService("RunService"))
local Players           = cloneref(game:GetService("Players"))
local Workspace         = cloneref(game:GetService("Workspace"))
local UserInputService  = cloneref(game:GetService("UserInputService"))
local StarterGui        = cloneref(game:GetService("StarterGui"))

local WindUI = nil
local loaderUrls = {
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
    "https://github.com/Footagesus/WindUI/releases/latest/download/WindUI.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"
}

for _, url in ipairs(loaderUrls) do
    local ok, res = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if ok and type(res) == "table" and res.CreateWindow then
        WindUI = res
        break
    end
end

if not WindUI then
    warn("[CROTTT HUB] Gagal mengunduh library WindUI!")
    return
end

local LocalPlayer = Players.LocalPlayer
local ScriptStartTime = os.time()

-- 3. TIKTOK LOGO LOADER DENGAN CACHE EXECUTOR
local function getOrDownloadCustomIcon()
    local pngUrl = "https://cdn-icons-png.flaticon.com/512/361/361468.png"
    local fileName = "logo-hub_logo.png"
    
    if writefile and getcustomasset then
        pcall(function()
            if not (isfile and isfile(fileName)) then
                writefile(fileName, game:HttpGet(pngUrl))
            end
        end)
        local ok, assetId = pcall(function()
            return getcustomasset(fileName)
        end)
        if ok and assetId then
            return assetId
        end
    end
    return pngUrl
end

local CUSTOM_LOGO = getOrDownloadCustomIcon()

-- Deteksi Nama Executor
local function getExecutorName()
    if identifyexecutor then return identifyexecutor()
    elseif getexecutorname then return getexecutorname()
    else return "Potassium / Universal" end
end

-- ============================================================
--  GLOBAL STATE & CONFIG
-- ============================================================
local Config = {
    Running         = false,
    MaxStuds        = 50,
    CollectDelay    = 0.001,
    InstantHold     = true,
    ServerRemote    = true,
    AutoTeleport    = false,
    SortByDistance  = true,
    LimitEnabled    = false,
    LimitAmount     = 50,
    EnabledRarities = {
        ["COMMON"]    = true,
        ["UNCOMMON"]  = true,
        ["RARE"]      = true,
        ["EPIC"]      = true,
        ["LEGENDARY"] = true,
        ["MYTHIC"]    = true,
        ["EMPYREAN"]  = true,
        ["PULSAR"]    = true,
        ["QUASAR"]    = true,
        ["BLOOD"]     = true,
        ["SECRET"]    = true,
    }
}

local PlayerConfig = {
    WalkSpeedEnabled = false,
    WalkSpeedValue   = 60,
    DefaultWalkSpeed = 16,
    FlyEnabled       = false,
    FlySpeed         = 50,
}

local DupeState = {
    Running         = false,
    RequestCount    = 0,
    ResetCooldown   = false,
    SelectedRunes   = {
        ["Haste Rune"] = false, ["Storm Rune"] = false, ["Weight Rune"] = false,
        ["Fortune Rune"] = false, ["Detonation Rune"] = false, ["Preservation Rune"] = false,
        ["Warmth Rune"] = false, ["Excavator Rune"] = false, ["Colossus Rune"] = false,
    }
}

local FavConfig = {
    ActionMode       = "⭐ Favorite",
    FilterLuckOnly   = false,
    LuckOperator     = "ABOVE",
    LuckTargetRaw    = 0,
    LuckInputText    = "",
    TargetSize       = "ALL",
    IsProcessing     = false
}

local RuneList = {
    { display = "Haste",        remote = "Haste Rune" },
    { display = "Storm",        remote = "Storm Rune" },
    { display = "Weight",       remote = "Weight Rune" },
    { display = "Fortune",      remote = "Fortune Rune" },
    { display = "Detonation",   remote = "Detonation Rune" },
    { display = "Preservation", remote = "Preservation Rune" },
    { display = "Warmth",       remote = "Warmth Rune" },
    { display = "Excavator",    remote = "Excavator Rune" },
    { display = "Colossus",     remote = "Colossus Rune" }
}

local Stats = {
    TotalCollected      = 0,
    LastCollected       = "-",
    LastRarity          = "-",
    StatusText          = "IDLE (Siap)",
    SessionStartTime    = nil,
    SessionCollected    = 0,
    CollectedByRarity   = {
        ["COMMON"] = 0, ["UNCOMMON"] = 0, ["RARE"] = 0, ["EPIC"] = 0,
        ["LEGENDARY"] = 0, ["MYTHIC"] = 0, ["EMPYREAN"] = 0,
        ["PULSAR"] = 0, ["QUASAR"] = 0, ["BLOOD"] = 0, ["SECRET"] = 0
    }
}

local TierMap = {
    [1] = "COMMON",    [2] = "UNCOMMON", [3] = "RARE",
    [4] = "EPIC",      [5] = "LEGENDARY",[6] = "MYTHIC",
    [7] = "EMPYREAN",  [8] = "PULSAR",   [9] = "QUASAR",
}

local RarityColors = {
    ["COMMON"]      = Color3.fromRGB(220, 195, 140),
    ["UNCOMMON"]    = Color3.fromRGB(110, 190, 240),
    ["RARE"]        = Color3.fromRGB(80, 240, 220),
    ["EPIC"]        = Color3.fromRGB(170, 100, 255),
    ["LEGENDARY"]   = Color3.fromRGB(255, 80, 180),
    ["MYTHIC"]      = Color3.fromRGB(190, 70, 255),
    ["EMPYREAN"]    = Color3.fromRGB(255, 225, 150),
    ["PULSAR"]      = Color3.fromRGB(90, 210, 255),
    ["QUASAR"]      = Color3.fromRGB(255, 90, 220),
    ["BLOOD"]       = Color3.fromRGB(200, 30, 40),
    ["SECRET"]      = Color3.fromRGB(244, 63, 94),
    ["OTHER"]       = Color3.fromRGB(156, 163, 175),
}

local RarityOrder = {
    ["QUASAR"] = 1, ["PULSAR"] = 2, ["EMPYREAN"] = 3,
    ["MYTHIC"] = 4, ["LEGENDARY"] = 5, ["EPIC"] = 6,
    ["RARE"] = 7, ["UNCOMMON"] = 8, ["COMMON"] = 9,
    ["BLOOD"] = 0, ["SECRET"] = 0, ["OTHER"] = 10
}

_G.CrystalCollectLogs = _G.CrystalCollectLogs or {}

-- ============================================================
--  PARSER NUMBER SUFFIX (K, M, B, T, QA, QI)
-- ============================================================
local function parseSuffixNumber(str)
    if not str then return 0 end
    local clean = tostring(str):gsub(",", ""):gsub("%+", ""):gsub("%%", ""):gsub("%$", ""):gsub("%s+", ""):upper()
    local num, suffix = clean:match("^([%d%.]+)([A-Z]*)$")
    if not num then return tonumber(clean) or 0 end
    
    local val = tonumber(num) or 0
    if suffix == "K" then val = val * 1e3
    elseif suffix == "M" then val = val * 1e6
    elseif suffix == "B" then val = val * 1e9
    elseif suffix == "T" then val = val * 1e12
    elseif suffix == "QA" or suffix == "Q" then val = val * 1e15
    elseif suffix == "QI" then val = val * 1e18 end
    return val
end

local function formatSuffixNumber(val)
    local n = tonumber(val) or 0
    if n >= 1e18 then return string.format("%.2fQi", n / 1e18)
    elseif n >= 1e15 then return string.format("%.2fQa", n / 1e15)
    elseif n >= 1e12 then return string.format("%.2fT", n / 1e12)
    elseif n >= 1e9 then return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
    else return tostring(math.floor(n)) end
end

-- ============================================================
--  REMOTE & ITEM HELPERS
-- ============================================================
local function getRemote(name)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild(name) then return remotes:FindFirstChild(name) end
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == name and (desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction")) then
            return desc
        end
    end
    return nil
end

local function toggleItemFavoriteRemote(item, setFavState)
    local favRemotes = {
        "FavoriteItem", "ToggleFavorite", "SetFavorite", "CrystalFavorite", 
        "ItemFavorite", "LockItem", "ToggleLock", "FavoriteTool"
    }
    for _, rName in ipairs(favRemotes) do
        local rem = getRemote(rName)
        if rem then
            pcall(function()
                if rem:IsA("RemoteEvent") then rem:FireServer(item, setFavState)
                elseif rem:IsA("RemoteFunction") then rem:InvokeServer(item, setFavState) end
            end)
            return true
        end
    end
    if item then
        pcall(function()
            item:SetAttribute("IsFavorite", setFavState)
            item:SetAttribute("Favorite", setFavState)
        end)
    end
    return false
end

local function getCharacterPosition()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    return hrp and hrp.Position
end

local function isCrystalPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end
    local parent = prompt.Parent
    if not parent then return false end

    local pName = parent.Name:lower()
    local pObjText = prompt.ObjectText:lower()
    local pActText = prompt.ActionText:lower()

    if pActText:find("pickup") or pActText:find("ambil") or pActText:find("collect") or pActText:find("take") then return true end
    if pName:find("crystal") or pName:find("rune") or pName:find("drop") or pObjText:find("crystal") or pObjText:find("rune") then return true end
    if parent:GetAttribute("CrystalName") or parent:GetAttribute("Tier") or parent:GetAttribute("RuneName") or parent:GetAttribute("RuneId") then return true end

    for _, desc in ipairs(parent:GetChildren()) do
        if desc:IsA("BillboardGui") then
            for _, lbl in ipairs(desc:GetDescendants()) do
                if lbl:IsA("TextLabel") and (lbl.Text:lower():find("crystal") or lbl.Text:lower():find("rune") or lbl.Text:lower():find("luck")) then
                    return true
                end
            end
        end
    end
    return false
end

local function getCrystalInfo(prompt)
    local parent = prompt.Parent
    local name = prompt.ObjectText ~= "" and prompt.ObjectText or (parent and parent.Name or "Crystal")
    local rarity = "COMMON"
    local luckValue = 0
    local size = "NORMAL"
    local weight = 0

    if parent then
        local attrName = parent:GetAttribute("CrystalName") or parent:GetAttribute("DisplayName") or parent:GetAttribute("RuneName")
        if attrName and tostring(attrName) ~= "" then name = tostring(attrName) end

        local attrTier = parent:GetAttribute("Tier")
        if attrTier and TierMap[tonumber(attrTier)] then rarity = TierMap[tonumber(attrTier)] end

        local attrRarity = parent:GetAttribute("Rarity") or parent:GetAttribute("TierName")
        if attrRarity and RarityColors[tostring(attrRarity):upper()] then
            rarity = tostring(attrRarity):upper()
        end

        local attrLuck = parent:GetAttribute("Luck") or parent:GetAttribute("LuckBonus")
        if attrLuck then luckValue = parseSuffixNumber(attrLuck) end

        for _, desc in ipairs(parent:GetChildren()) do
            if desc:IsA("BillboardGui") then
                for _, lbl in ipairs(desc:GetDescendants()) do
                    if lbl:IsA("TextLabel") then
                        local t = lbl.Text
                        local ut = t:upper()

                        if ut:find("QUASAR") then rarity = "QUASAR"
                        elseif ut:find("PULSAR") then rarity = "PULSAR"
                        elseif ut:find("EMPYREAN") then rarity = "EMPYREAN"
                        elseif ut:find("MYTHIC") then rarity = "MYTHIC"
                        elseif ut:find("LEGENDARY") or ut:find("LEGENDARIS") then rarity = "LEGENDARY"
                        elseif ut:find("EPIC") then rarity = "EPIC"
                        elseif ut:find("RARE") then rarity = "RARE"
                        elseif ut:find("UNCOMMON") then rarity = "UNCOMMON"
                        elseif ut:find("COMMON") or ut:find("UMUM") then rarity = "COMMON"
                        elseif ut:find("BLOOD") then rarity = "BLOOD"
                        elseif ut:find("SECRET") then rarity = "SECRET" end

                        local parsedLuck = t:match("[Ll]uck:%s*%+?([%d%,%.%a]+)%%?")
                        if parsedLuck then luckValue = parseSuffixNumber(parsedLuck) end

                        local parsedSize = t:match("%[([%a%d]+)%]")
                        if parsedSize and (#parsedSize <= 3 or parsedSize == "XXL" or parsedSize == "XL" or parsedSize == "L" or parsedSize == "M" or parsedSize == "S") then
                            size = parsedSize:upper()
                        end

                        local parsedW = t:match("([%d%,%.]+)%s*kg")
                        if parsedW then weight = parseSuffixNumber(parsedW) end

                        if t ~= "" and not name:find("Crystal") and (lbl.Name == "ObjectText" or lbl.Name == "DisplayName" or lbl.Name:find("Name") or t:find("%(")) then
                            name = t
                        end
                    end
                end
            end
        end
    end

    local uname = (name .. " " .. (prompt.ObjectText or "")):upper()
    if uname:find("QUASAR") then rarity = "QUASAR"
    elseif uname:find("PULSAR") then rarity = "PULSAR"
    elseif uname:find("EMPYREAN") then rarity = "EMPYREAN"
    elseif uname:find("MYTHIC") then rarity = "MYTHIC"
    elseif uname:find("LEGENDARY") or uname:find("LEGENDARIS") then rarity = "LEGENDARY"
    elseif uname:find("EPIC") then rarity = "EPIC"
    elseif uname:find("RARE") then rarity = "RARE"
    elseif uname:find("UNCOMMON") then rarity = "UNCOMMON"
    elseif uname:find("COMMON") or uname:find("UMUM") then rarity = "COMMON"
    elseif uname:find("BLOOD") then rarity = "BLOOD"
    elseif uname:find("SECRET") then rarity = "SECRET" end

    return name, rarity, luckValue, size, weight
end

-- ============================================================
--  BACKPACK SCANNER
-- ============================================================
local function parseItemDetails(itm)
    local rawName = itm.Name
    local displayName = rawName
    local rarity = "COMMON"
    local size = "NORMAL"
    local weight = 0
    local luckValue = 0
    local hasLuck = false
    local isFavorite = false

    local attrName = itm:GetAttribute("CrystalName") or itm:GetAttribute("DisplayName") or itm:GetAttribute("RuneName")
    if attrName and tostring(attrName) ~= "" then displayName = tostring(attrName) end

    local attrTier = itm:GetAttribute("Tier")
    if attrTier and TierMap[tonumber(attrTier)] then rarity = TierMap[tonumber(attrTier)] end

    local attrRarity = itm:GetAttribute("Rarity") or itm:GetAttribute("TierName")
    if attrRarity and RarityColors[tostring(attrRarity):upper()] then
        rarity = tostring(attrRarity):upper()
    end

    if itm:GetAttribute("IsFavorite") == true or itm:GetAttribute("Favorite") == true or itm:GetAttribute("Locked") == true then
        isFavorite = true
    elseif itm:FindFirstChild("Favorite") or itm:FindFirstChild("IsFavorite") or itm:FindFirstChild("Locked") then
        isFavorite = true
    end

    local attrLuck = itm:GetAttribute("Luck") or itm:GetAttribute("LuckBonus") or itm:GetAttribute("BonusLuck") or itm:GetAttribute("Multiplier")
    if attrLuck then
        luckValue = parseSuffixNumber(attrLuck)
        hasLuck = luckValue > 0
    elseif itm:FindFirstChild("Luck") and itm.Luck:IsA("ValueBase") then
        luckValue = parseSuffixNumber(itm.Luck.Value)
        hasLuck = luckValue > 0
    end

    local attrSize = itm:GetAttribute("Size") or itm:GetAttribute("CrystalSize")
    if attrSize then size = tostring(attrSize):upper() end

    local attrWeight = itm:GetAttribute("Weight") or itm:GetAttribute("Mass")
    if attrWeight then weight = parseSuffixNumber(attrWeight) end

    local parsedSize = rawName:match("%[([%a%d]+)%]")
    if parsedSize and (#parsedSize <= 3 or parsedSize == "XXL" or parsedSize == "XL" or parsedSize == "L" or parsedSize == "M" or parsedSize == "S") then
        size = parsedSize:upper()
    end

    local parsedWeight = rawName:match("%[([%d%,%.]+)%s*kg%]") or rawName:match("([%d%,%.]+)%s*kg")
    if parsedWeight then weight = parseSuffixNumber(parsedWeight) end

    local parsedLuck = rawName:match("[Ll]uck:%s*%+?([%d%,%.%a]+)%%?") or rawName:match("%+([%d%,%.%a]+)%%%s*[Ll]uck")
    if parsedLuck then
        luckValue = parseSuffixNumber(parsedLuck)
        hasLuck = luckValue > 0
    end

    for _, desc in ipairs(itm:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Text ~= "" then
            local t = desc.Text
            local pL = t:match("[Ll]uck:%s*%+?([%d%,%.%a]+)%%?")
            if pL then
                luckValue = parseSuffixNumber(pL)
                hasLuck = luckValue > 0
            end
            local pW = t:match("([%d%,%.]+)%s*kg")
            if pW and weight == 0 then weight = parseSuffixNumber(pW) end
        end
    end

    if rarity == "COMMON" then
        local uname = (rawName .. " " .. displayName):upper()
        if uname:find("QUASAR") then rarity = "QUASAR"
        elseif uname:find("PULSAR") then rarity = "PULSAR"
        elseif uname:find("EMPYREAN") then rarity = "EMPYREAN"
        elseif uname:find("MYTHIC") then rarity = "MYTHIC"
        elseif uname:find("LEGENDARY") then rarity = "LEGENDARY"
        elseif uname:find("EPIC") then rarity = "EPIC"
        elseif uname:find("RARE") then rarity = "RARE"
        elseif uname:find("UNCOMMON") then rarity = "UNCOMMON"
        elseif uname:find("BLOOD") then rarity = "BLOOD"
        elseif uname:find("SECRET") then rarity = "SECRET" end
    end

    return {
        Instance    = itm,
        Name        = displayName,
        RawName     = rawName,
        Rarity      = rarity,
        Size        = size,
        Weight      = weight,
        Luck        = luckValue,
        LuckDisplay = hasLuck and ("+" .. formatSuffixNumber(luckValue) .. "%") or "-",
        HasLuck     = hasLuck,
        IsFavorite  = isFavorite,
    }
end

local function scanBackpack()
    local inv = {
        Total = 0,
        TotalLuckItems = 0,
        ByRarity = {
            ["QUASAR"] = 0, ["PULSAR"] = 0, ["EMPYREAN"] = 0,
            ["MYTHIC"] = 0, ["LEGENDARY"] = 0, ["EPIC"] = 0,
            ["RARE"] = 0, ["UNCOMMON"] = 0, ["COMMON"] = 0,
            ["BLOOD"] = 0, ["SECRET"] = 0, ["OTHER"] = 0
        },
        ByItem = {},
        List = {},
        RawItems = {}
    }

    local items = {}
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then for _, itm in ipairs(bp:GetChildren()) do table.insert(items, itm) end end

    local char = LocalPlayer.Character
    if char then
        for _, itm in ipairs(char:GetChildren()) do
            if itm:IsA("Tool") then table.insert(items, itm) end
        end
    end

    for _, itm in ipairs(items) do
        local details = parseItemDetails(itm)
        table.insert(inv.RawItems, details)

        inv.Total = inv.Total + 1
        inv.ByRarity[details.Rarity] = (inv.ByRarity[details.Rarity] or 0) + 1
        if details.HasLuck then inv.TotalLuckItems = inv.TotalLuckItems + 1 end

        local key = details.Rarity .. "::" .. details.Name .. "::" .. details.Size .. "::" .. tostring(details.Luck)
        if not inv.ByItem[key] then 
            inv.ByItem[key] = { 
                Rarity      = details.Rarity, 
                Name        = details.Name, 
                Size        = details.Size,
                Weight      = details.Weight,
                Luck        = details.Luck,
                LuckDisplay = details.LuckDisplay,
                HasLuck     = details.HasLuck,
                Count       = 0,
                Items       = {},
                IsFavorite  = details.IsFavorite
            } 
        end
        inv.ByItem[key].Count = inv.ByItem[key].Count + 1
        table.insert(inv.ByItem[key].Items, details)
    end

    for _, data in pairs(inv.ByItem) do table.insert(inv.List, data) end

    table.sort(inv.List, function(a, b)
        local orderA = RarityOrder[a.Rarity] or 99
        local orderB = RarityOrder[b.Rarity] or 99
        if orderA ~= orderB then return orderA < orderB end
        if a.Luck ~= b.Luck then return a.Luck > b.Luck end
        if a.Count ~= b.Count then return a.Count > b.Count end
        return a.Name < b.Name
    end)

    return inv
end

-- ============================================================
--  AUTO COLLECT CYCLE (HANYA FILTER BY RARITY)
-- ============================================================
local function triggerPickup(prompt, part)
    if not prompt or not prompt.Parent then return false end
    if Config.InstantHold then prompt.HoldDuration = 0 end

    if Config.ServerRemote and part then
        pcall(function()
            local rem = getRemote("CrystalHoldComplete")
            if rem then rem:FireServer(part) end
        end)
    end

    if typeof(fireproximityprompt) == "function" then
        pcall(function() fireproximityprompt(prompt, 0) end)
        return true
    end

    return pcall(function()
        prompt:InputHoldBegin()
        task.wait(Config.InstantHold and 0.01 or (prompt.HoldDuration > 0 and prompt.HoldDuration or 0.01))
        prompt:InputHoldEnd()
    end)
end

local function getNearbyCrystals()
    local charPos = getCharacterPosition()
    if not charPos then return {} end

    local found = {}
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled and isCrystalPrompt(prompt) then
            local part = prompt.Parent
            local pos = nil
            if part:IsA("BasePart") then pos = part.Position
            elseif part:IsA("Model") and part.PrimaryPart then pos = part.PrimaryPart.Position
            elseif part:IsA("Attachment") then pos = part.WorldPosition
            elseif part:IsA("Model") then
                local fp = part:FindFirstChildWhichIsA("BasePart", true)
                if fp then pos = fp.Position end
            end

            if pos then
                local dist = (charPos - pos).Magnitude
                if dist <= Config.MaxStuds then
                    local name, rarity, luck, size, weight = getCrystalInfo(prompt)
                    if Config.EnabledRarities[rarity] == true then
                        table.insert(found, {
                            Prompt   = prompt,
                            Part     = part,
                            Position = pos,
                            Distance = dist,
                            Name     = name,
                            Rarity   = rarity,
                            Luck     = luck,
                            Size     = size,
                            Weight   = weight,
                        })
                    end
                end
            end
        end
    end

    if Config.SortByDistance then
        table.sort(found, function(a, b) return a.Distance < b.Distance end)
    end
    return found
end

local isCollecting = false
local function collectCycle()
    if isCollecting or not Config.Running then return end
    isCollecting = true

    if Config.LimitEnabled and Stats.SessionCollected >= Config.LimitAmount then
        Config.Running = false
        Stats.StatusText = string.format("LIMIT TERCAPAI (%d/%d)", Stats.SessionCollected, Config.LimitAmount)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Auto Collect Selesai!",
                Text = string.format("Limit %d Crystal telah tercapai!", Config.LimitAmount),
                Duration = 4
            })
        end)
        isCollecting = false
        return
    end

    local crystals = getNearbyCrystals()
    if #crystals > 0 then
        Stats.StatusText = string.format("Mengambil %d Crystal di sekitar...", #crystals)
        for _, cData in ipairs(crystals) do
            if not Config.Running then break end
            
            if Config.LimitEnabled and Stats.SessionCollected >= Config.LimitAmount then
                Config.Running = false
                break
            end

            local myPos = getCharacterPosition()
            if myPos and cData.Prompt and cData.Prompt.Parent then
                local curDist = (myPos - cData.Position).Magnitude
                if curDist <= (Config.MaxStuds + 5) then
                    if Config.AutoTeleport and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(cData.Position + Vector3.new(0, 2, 0))
                        task.wait(0.04)
                    end

                    local ok = triggerPickup(cData.Prompt, cData.Part)
                    if ok then
                        Stats.TotalCollected = Stats.TotalCollected + 1
                        Stats.SessionCollected = Stats.SessionCollected + 1
                        Stats.LastCollected = cData.Name
                        Stats.LastRarity = cData.Rarity
                        Stats.CollectedByRarity[cData.Rarity] = (Stats.CollectedByRarity[cData.Rarity] or 0) + 1
                        
                        local logMsg = string.format("[%s] %s", cData.Rarity, cData.Name)
                        if cData.Luck > 0 then
                            logMsg = logMsg .. " 🍀[+" .. formatSuffixNumber(cData.Luck) .. "%]"
                        end
                        logMsg = logMsg .. string.format(" (%.1fm)", curDist)

                        table.insert(_G.CrystalCollectLogs, 1, logMsg)
                        if #_G.CrystalCollectLogs > 60 then table.remove(_G.CrystalCollectLogs) end
                    end

                    if Config.CollectDelay > 0 then task.wait(Config.CollectDelay) end
                end
            end
        end
    else
        Stats.StatusText = string.format("Scanning (%ds)...", Config.MaxStuds)
    end

    isCollecting = false
end

local loopThread = nil
local function startLoop()
    if loopThread then return end
    Stats.SessionStartTime = os.time()
    Stats.SessionCollected = 0
    loopThread = task.spawn(function()
        while Config.Running do
            pcall(collectCycle)
            task.wait(Config.CollectDelay > 0 and Config.CollectDelay or 0.05)
        end
        loopThread = nil
    end)
end

-- ============================================================
--  PLAYER MOVEMENT & DUPE
-- ============================================================
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyConnection = nil
local moveKeys = { Forward = false, Backward = false, Left = false, Right = false, Up = false, Down = false }

local function startFly()
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    if flyBodyGyro then flyBodyGyro:Destroy() end

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Name = "FlyVelocity"
    flyBodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.Parent = hrp

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.Name = "FlyGyro"
    flyBodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyBodyGyro.P = 10000
    flyBodyGyro.CFrame = hrp.CFrame
    flyBodyGyro.Parent = hrp

    hum.PlatformStand = true

    if flyConnection then flyConnection:Disconnect() end
    flyConnection = RunService.RenderStepped:Connect(function()
        if not PlayerConfig.FlyEnabled or not LocalPlayer.Character or not hrp or not flyBodyVelocity then return end
        local cam = Workspace.CurrentCamera
        local moveDir = Vector3.zero
        if moveKeys.Forward  then moveDir = moveDir + cam.CFrame.LookVector end
        if moveKeys.Backward then moveDir = moveDir - cam.CFrame.LookVector end
        if moveKeys.Left     then moveDir = moveDir - cam.CFrame.RightVector end
        if moveKeys.Right    then moveDir = moveDir + cam.CFrame.RightVector end
        if moveKeys.Up       then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if moveKeys.Down     then moveDir = moveDir - Vector3.new(0, 1, 0) end

        if moveDir.Magnitude > 0 then
            flyBodyVelocity.Velocity = moveDir.Unit * PlayerConfig.FlySpeed
        else
            flyBodyVelocity.Velocity = Vector3.zero
        end
        flyBodyGyro.CFrame = cam.CFrame
    end)
end

local function stopFly()
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.W then moveKeys.Forward = true
    elseif input.KeyCode == Enum.KeyCode.S then moveKeys.Backward = true
    elseif input.KeyCode == Enum.KeyCode.A then moveKeys.Left = true
    elseif input.KeyCode == Enum.KeyCode.D then moveKeys.Right = true
    elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.E then moveKeys.Up = true
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.Q then moveKeys.Down = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then moveKeys.Forward = false
    elseif input.KeyCode == Enum.KeyCode.S then moveKeys.Backward = false
    elseif input.KeyCode == Enum.KeyCode.A then moveKeys.Left = false
    elseif input.KeyCode == Enum.KeyCode.D then moveKeys.Right = false
    elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.E then moveKeys.Up = false
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.Q then moveKeys.Down = false end
end)

RunService.Heartbeat:Connect(function()
    if PlayerConfig.WalkSpeedEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= PlayerConfig.WalkSpeedValue then
            hum.WalkSpeed = PlayerConfig.WalkSpeedValue
        end
    end
end)

local dupeThread = nil
local function startDupeLoop()
    if DupeState.Running then return end
    DupeState.Running = true
    dupeThread = task.spawn(function()
        local runeEvent = getRemote("CrystalDropRequest")
        while DupeState.Running do
            if runeEvent then
                for remoteName, isSelected in pairs(DupeState.SelectedRunes) do
                    if isSelected and DupeState.Running then
                        pcall(function() runeEvent:FireServer(remoteName) end)
                        DupeState.RequestCount = DupeState.RequestCount + 1
                    end
                end
            end
            task.wait(0)
        end
        dupeThread = nil
    end)
end

-- ============================================================
--  WINDUI INTERFACE
-- ============================================================
local Window = WindUI:CreateWindow({
    Title = "CROTTT HUB | Mine a Mountain",
    Icon = CUSTOM_LOGO,
    Author = "by CROTTT Team",
    Folder = "crottt_mam",
    Size = UDim2.fromOffset(640, 520),
    HideSearchBar = false,
    OpenButton = {
        Title = "Open CROTTT HUB",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = false, -- Menggunakan Draggable Floating Logo TikTok di bawah
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.8,
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Default",
    },
})

-- ============================================================
--  CUSTOM DRAGGABLE TIKTOK LOGO BUTTON
-- ============================================================
local function createCustomDraggableButton()
    local oldBtnGui = LocalPlayer.PlayerGui:FindFirstChild("CROTTT_FloatingLogoButton")
    if oldBtnGui then oldBtnGui:Destroy() end

    local btnGui = Instance.new("ScreenGui")
    btnGui.Name = "CROTTT_FloatingLogoButton"
    btnGui.ResetOnSpawn = false
    btnGui.Parent = LocalPlayer.PlayerGui

    local floatBtn = Instance.new("ImageButton")
    floatBtn.Name = "DraggableTikTokBtn"
    floatBtn.Size = UDim2.new(0, 56, 0, 56)
    floatBtn.Position = UDim2.new(0, 915, 0, 65)
    floatBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    floatBtn.BackgroundTransparency = 0.1
    floatBtn.BorderSizePixel = 0
    floatBtn.Active = true
    floatBtn.Draggable = true
    floatBtn.AutoButtonColor = true
    floatBtn.Parent = btnGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = floatBtn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(238, 41, 82) -- TikTok Red Accent
    stroke.Thickness = 2
    stroke.Parent = floatBtn

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(1, -12, 1, -12)
    img.Position = UDim2.new(0, 6, 0, 6)
    img.BackgroundTransparency = 1
    img.Image = CUSTOM_LOGO
    img.ScaleType = Enum.ScaleType.Fit
    img.Parent = floatBtn

    floatBtn.MouseButton1Click:Connect(function()
        if Window.Toggle then
            Window:Toggle()
        elseif Window.Holder then
            Window.Holder.Visible = not Window.Holder.Visible
        end
    end)
end
pcall(createCustomDraggableButton)

-- ============================================================
--  TAB 1: INFO (ACCOUNT, GAME INFO, REALTIME CLOCK)
-- ============================================================
local TabInfo = Window:Tab({ Title = "Info", Icon = CUSTOM_LOGO, Border = true })

TabInfo:Section({ Title = "Informasi Akun" })

local AccountPara = TabInfo:Paragraph({
    Title = "👤 Account",
    Desc = string.format("User: %s (@%s)\nStatus: 🟢 Keyless (Active)\nExecutor: %s", LocalPlayer.Name, LocalPlayer.DisplayName, getExecutorName())
})

TabInfo:Section({ Title = "Informasi Game & Server" })

local GameInfoPara = TabInfo:Paragraph({
    Title = "🎮 Game Info",
    Desc = string.format("Game: Mine a Mountain [%d]\nPlace ID: %d\nSession Time: 0m 0s\nJam (Waktu): %s", TARGET_PLACE_ID, TARGET_PLACE_ID, os.date("%X"))
})

TabInfo:Button({
    Title = "📋 Copy Server Job ID",
    Desc = "Salin Job ID server ke clipboard",
    Callback = function()
        local jid = game.JobId ~= "" and game.JobId or "Singleplayer"
        if setclipboard then
            setclipboard(jid)
            WindUI:Notify({ Title = "Job ID Disalin", Content = jid, Duration = 3 })
        end
    end
})

-- SECTION UTAMA
local MainSection = Window:Section({ Title = "Fitur Utama" })

-- ============================================================
--  TAB 2: COLLECTOR (HANYA FILTER BY RARITY)
-- ============================================================
local TabCollect = MainSection:Tab({ Title = "Collector", Icon = "solar:check-square-bold", Border = true })
TabCollect:Section({ Title = "Kontrol Auto Collect" })

local CollectStatusPara = TabCollect:Paragraph({ Title = "Status Pengambilan", Desc = "Status: IDLE (Siap)" })

TabCollect:Toggle({
    Title = "Aktifkan Auto Collect",
    Desc = "Mengambil kristal secara instan di sekitar radius",
    Value = Config.Running,
    Callback = function(state)
        Config.Running = state
        if state then startLoop() end
    end
})

TabCollect:Slider({
    Title = "Radius Jangkauan (Studs)",
    Step = 5,
    Value = { Min = 10, Max = 500, Default = Config.MaxStuds },
    Callback = function(val) Config.MaxStuds = val end
})

TabCollect:Toggle({
    Title = "Auto Teleport ke Crystal",
    Desc = "Teleport langsung ke koordinat batu saat mengambil",
    Value = Config.AutoTeleport,
    Callback = function(state) Config.AutoTeleport = state end
})

TabCollect:Section({ Title = "Limit Pengambilan" })
TabCollect:Toggle({
    Title = "Aktifkan Limit Jumlah",
    Desc = "Otomatis berhenti jika kuota crystal tercapai",
    Value = Config.LimitEnabled,
    Callback = function(state) Config.LimitEnabled = state end
})

TabCollect:Input({
    Title = "Batas Limit (Jumlah Crystal)",
    Value = tostring(Config.LimitAmount),
    Placeholder = "50",
    Callback = function(txt)
        local n = tonumber(txt)
        if n and n > 0 then Config.LimitAmount = math.floor(n) end
    end
})

TabCollect:Section({ Title = "Filter by Rarity" })

TabCollect:Dropdown({
    Title = "Preset Rarity Cepat",
    Desc = "Pilih kombinasi filter rarity secara instan",
    Values = {
        "⭐ Semua Rarity (ON)",
        "🔥 Mythic+ (Mythic, Empyrean, Pulsar, Quasar, Secret)",
        "✨ Legendary+",
        "❌ Semua (OFF)"
    },
    Value = "⭐ Semua Rarity (ON)",
    Callback = function(preset)
        if preset:find("Semua Rarity") then
            for k in pairs(Config.EnabledRarities) do Config.EnabledRarities[k] = true end
        elseif preset:find("Semua %(OFF%)") then
            for k in pairs(Config.EnabledRarities) do Config.EnabledRarities[k] = false end
        elseif preset:find("Mythic%+") then
            for k in pairs(Config.EnabledRarities) do Config.EnabledRarities[k] = false end
            Config.EnabledRarities["MYTHIC"]    = true
            Config.EnabledRarities["EMPYREAN"]  = true
            Config.EnabledRarities["PULSAR"]    = true
            Config.EnabledRarities["QUASAR"]    = true
            Config.EnabledRarities["BLOOD"]     = true
            Config.EnabledRarities["SECRET"]    = true
        elseif preset:find("Legendary%+") then
            for k in pairs(Config.EnabledRarities) do Config.EnabledRarities[k] = false end
            Config.EnabledRarities["LEGENDARY"] = true
            Config.EnabledRarities["MYTHIC"]    = true
            Config.EnabledRarities["EMPYREAN"]  = true
            Config.EnabledRarities["PULSAR"]    = true
            Config.EnabledRarities["QUASAR"]    = true
            Config.EnabledRarities["BLOOD"]     = true
            Config.EnabledRarities["SECRET"]    = true
        end
    end
})

-- Toggle Individual Rarity Lengkap Codebase Mine a Mountain
local CodebaseRarities = {
    { id = "QUASAR",    name = "Quasar (Tier 9)",     desc = "Value: $10.6B | Rarity Tertinggi" },
    { id = "PULSAR",    name = "Pulsar (Tier 8)",     desc = "Value: $660M" },
    { id = "EMPYREAN",  name = "Empyrean (Tier 7)",   desc = "Value: $41M" },
    { id = "MYTHIC",    name = "Mythic (Tier 6)",     desc = "Value: $2.58M" },
    { id = "LEGENDARY", name = "Legendary (Tier 5)",  desc = "Value: $73.2K" },
    { id = "EPIC",      name = "Epic (Tier 4)",       desc = "Value: $4.5K" },
    { id = "RARE",      name = "Rare (Tier 3)",       desc = "Value: $500" },
    { id = "UNCOMMON",  name = "Uncommon (Tier 2)",   desc = "Value: $70" },
    { id = "COMMON",    name = "Common (Tier 1)",     desc = "Value: $10" },
    { id = "SECRET",    name = "Bloodstone / Secret", desc = "Hidden Blood Crystal" }
}

for _, rInfo in ipairs(CodebaseRarities) do
    TabCollect:Toggle({
        Title = rInfo.name,
        Desc = rInfo.desc,
        Value = Config.EnabledRarities[rInfo.id] == true,
        Callback = function(st)
            Config.EnabledRarities[rInfo.id] = st
            if rInfo.id == "SECRET" then Config.EnabledRarities["BLOOD"] = st end
        end
    })
end

-- ============================================================
--  TAB 3: STATS & BACKPACK
-- ============================================================
local TabStats = MainSection:Tab({ Title = "Stats & Tas", Icon = "solar:file-text-bold", Border = true })
TabStats:Section({ Title = "Statistik Sesi Pengambilan" })
local SessionPara = TabStats:Paragraph({ Title = "Waktu Sesi & Rate", Desc = "Durasi: 00:00:00 | 0/mnt" })

TabStats:Section({ Title = "Isi Tas / Backpack (Live)" })
local BpSummaryPara = TabStats:Paragraph({ Title = "Total di Tas", Desc = "Memindai tas..." })

-- ============================================================
--  TAB 4: FAVORITE & LUCK FILTER
-- ============================================================
local TabFav = MainSection:Tab({ Title = "Favorite & Luck", Icon = "solar:cursor-square-bold", Border = true })

TabFav:Section({ Title = "Mode Eksekusi Filter" })

TabFav:Dropdown({
    Title = "Pilih Aksi Eksekusi (Mode)",
    Desc = "Tentukan apakah eksekusi akan me-Favorite atau me-Unfavorite",
    Values = { "⭐ Favorite", "❌ Unfavorite" },
    Value = FavConfig.ActionMode,
    Callback = function(val)
        FavConfig.ActionMode = val
    end
})

TabFav:Section({ Title = "Filter Parameter (Luck & Size)" })

TabFav:Toggle({
    Title = "Hanya Crystal yang Memiliki Luck",
    Desc = "Abaikan crystal tanpa bonus luck",
    Value = FavConfig.FilterLuckOnly,
    Callback = function(state) FavConfig.FilterLuckOnly = state end
})

TabFav:Dropdown({
    Title = "Operator Luck (Above / Below)",
    Desc = "Pilih apakah mencari luck di atas (>=) atau di bawah (<=) target",
    Values = { "▲ Above (>=)", "▼ Below (<=)" },
    Value = "▲ Above (>=)",
    Callback = function(selected)
        FavConfig.LuckOperator = selected:find("Above") and "ABOVE" or "BELOW"
    end
})

TabFav:Input({
    Title = "Target Nilai Luck (K/M/B/T)",
    Desc = "Mendukung penulisan suffix (contoh: 1M, 500k, 3.59M, 788906)",
    Value = FavConfig.LuckInputText,
    Placeholder = "cth: 1M atau 500k",
    Callback = function(txt)
        FavConfig.LuckInputText = txt
        FavConfig.LuckTargetRaw = parseSuffixNumber(txt)
    end
})

TabFav:Dropdown({
    Title = "Filter Ukuran Crystal (Size)",
    Values = { "ALL", "XL", "L", "M", "S" },
    Value = "ALL",
    Callback = function(val) FavConfig.TargetSize = val end
})

local FavStatusPara = TabFav:Paragraph({ Title = "Status Eksekusi", Desc = "Siap memproses." })

TabFav:Button({
    Title = "🚀 JALANKAN EKSEKUSI FILTER",
    Desc = "Eksekusi aksi (Favorite / Unfav) sesuai aturan filter di atas",
    Callback = function()
        if FavConfig.IsProcessing then return end
        FavConfig.IsProcessing = true
        local isFavTarget = (FavConfig.ActionMode == "⭐ Favorite")
        FavStatusPara:SetDesc(string.format("Memproses %s by filter...", isFavTarget and "Favorite" or "Unfavorite"))

        task.spawn(function()
            local inv = scanBackpack()
            local count = 0
            for _, itm in ipairs(inv.RawItems) do
                local pass = true
                if FavConfig.FilterLuckOnly and not itm.HasLuck then pass = false end
                if FavConfig.LuckTargetRaw > 0 then
                    if FavConfig.LuckOperator == "ABOVE" and itm.Luck < FavConfig.LuckTargetRaw then pass = false
                    elseif FavConfig.LuckOperator == "BELOW" and itm.Luck > FavConfig.LuckTargetRaw then pass = false end
                end
                if FavConfig.TargetSize ~= "ALL" and itm.Size ~= FavConfig.TargetSize then pass = false end

                if pass then
                    toggleItemFavoriteRemote(itm.Instance, isFavTarget)
                    count = count + 1
                    task.wait(0.01)
                end
            end
            FavStatusPara:SetDesc(string.format("Selesai! %d crystal berhasil di-%s.", count, isFavTarget and "Favoritkan" or "Unfavoritkan"))
            FavConfig.IsProcessing = false
        end)
    end
})

TabFav:Section({ Title = "Aksi Cepat (Semua Tas)" })

TabFav:Button({
    Title = "⭐ FAVORITE SEMUA DI TAS",
    Desc = "Kunci seluruh kristal yang ada di tas",
    Callback = function()
        local inv = scanBackpack()
        for _, itm in ipairs(inv.RawItems) do
            toggleItemFavoriteRemote(itm.Instance, true)
            task.wait(0.01)
        end
        FavStatusPara:SetDesc("Selesai! Seluruh kristal di tas telah di-Favoritkan.")
    end
})

TabFav:Button({
    Title = "❌ UNFAVORITE SEMUA DI TAS",
    Desc = "Buka kunci seluruh kristal di tas",
    Callback = function()
        local inv = scanBackpack()
        for _, itm in ipairs(inv.RawItems) do
            toggleItemFavoriteRemote(itm.Instance, false)
            task.wait(0.01)
        end
        FavStatusPara:SetDesc("Selesai! Seluruh kristal di tas telah di-Unfavoritkan.")
    end
})

-- ============================================================
--  UTILITIES SECTION (DUPE & PLAYER)
-- ============================================================
local UtilitySection = Window:Section({ Title = "Utilities" })

-- TAB 5: DUPE & RESET
local TabDupe = UtilitySection:Tab({ Title = "Dupe & Reset", Icon = "solar:square-transfer-horizontal-bold", Border = true })
TabDupe:Section({ Title = "Fast Character Reset" })

TabDupe:Button({
    Title = "💀 RESET CHARACTER (BreakJoints)",
    Desc = "Fast die dengan cooldown aman untuk reset crystal",
    Callback = function()
        if DupeState.ResetCooldown then return end
        DupeState.ResetCooldown = true
        if LocalPlayer.Character then pcall(function() LocalPlayer.Character:BreakJoints() end) end
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Crystal Reset",
                Text = "Cooldown 6 detik untuk keamanan...",
                Duration = 3
            })
        end)
        task.spawn(function()
            task.wait(6)
            DupeState.ResetCooldown = false
        end)
    end
})

TabDupe:Section({ Title = "Rune Drop Request Spammer" })
TabDupe:Toggle({
    Title = "Spam Rune Drop Request",
    Value = DupeState.Running,
    Callback = function(state)
        if state then startDupeLoop() else DupeState.Running = false end
    end
})

for _, rData in ipairs(RuneList) do
    TabDupe:Toggle({
        Title = "Rune: " .. rData.display,
        Value = false,
        Callback = function(st) DupeState.SelectedRunes[rData.remote] = st end
    })
end

-- TAB 6: PLAYER MODIFIERS
local TabPlayer = UtilitySection:Tab({ Title = "Player", Icon = "solar:password-minimalistic-input-bold", Border = true })
TabPlayer:Section({ Title = "WalkSpeed Modifier" })

TabPlayer:Toggle({
    Title = "Aktifkan WalkSpeed",
    Value = PlayerConfig.WalkSpeedEnabled,
    Callback = function(st)
        PlayerConfig.WalkSpeedEnabled = st
        if not st and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = PlayerConfig.DefaultWalkSpeed
        end
    end
})

TabPlayer:Slider({
    Title = "Kecepatan Lari",
    Step = 5,
    Value = { Min = 16, Max = 250, Default = PlayerConfig.WalkSpeedValue },
    Callback = function(v) PlayerConfig.WalkSpeedValue = v end
})

TabPlayer:Section({ Title = "FlyHigh (Terbang Bebas)" })
TabPlayer:Toggle({
    Title = "Aktifkan FlyHigh",
    Desc = "Gunakan W,A,S,D, Space (Naik), Shift/Ctrl (Turun)",
    Value = PlayerConfig.FlyEnabled,
    Callback = function(st)
        PlayerConfig.FlyEnabled = st
        if st then startFly() else stopFly() end
    end
})

TabPlayer:Slider({
    Title = "Kecepatan Terbang",
    Step = 5,
    Value = { Min = 20, Max = 200, Default = PlayerConfig.FlySpeed },
    Callback = function(v) PlayerConfig.FlySpeed = v end
})

-- ============================================================
--  BACKGROUND STATS & LIVE TICKER (JAM REALTIME & SESSION)
-- ============================================================
task.spawn(function()
    while true do
        local elapsed = os.time() - ScriptStartTime
        local h = math.floor(elapsed / 3600); local m = math.floor((elapsed % 3600) / 60); local s = elapsed % 60
        local timeString = os.date("%X")

        GameInfoPara:SetDesc(string.format("Game: Mine a Mountain [%d]\nPlace ID: %d\nSession Time: %dm %ds\nJam (Waktu): %s", TARGET_PLACE_ID, TARGET_PLACE_ID, math.floor(elapsed / 60), s, timeString))

        if Config.Running then
            CollectStatusPara:SetDesc(string.format("Mengambil... | Total Diambil: %d Crystal", Stats.SessionCollected))
        else
            CollectStatusPara:SetDesc("Status: IDLE (Dihentikan)")
        end

        if Stats.SessionStartTime and Config.Running then
            local cElapsed = os.time() - Stats.SessionStartTime
            local ch = math.floor(cElapsed / 3600); local cm = math.floor((cElapsed % 3600) / 60); local cs = cElapsed % 60
            local rate = (cElapsed > 0) and math.floor((Stats.SessionCollected / (cElapsed / 60)) * 10) / 10 or 0
            SessionPara:SetDesc(string.format("Durasi: %02d:%02d:%02d | Kecepatan: %.1f/mnt | Diambil: %d", ch, cm, cs, rate, Stats.SessionCollected))
        end

        local inv = scanBackpack()
        local sumParts = {}
        for _, rk in ipairs({"QUASAR", "PULSAR", "EMPYREAN", "MYTHIC", "LEGENDARY"}) do
            local c = inv.ByRarity[rk] or 0
            if c > 0 then table.insert(sumParts, string.format("%s: %d", rk, c)) end
        end
        BpSummaryPara:SetDesc(string.format("Total di Tas: %d Crystal\n(%s)", inv.Total, #sumParts > 0 and table.concat(sumParts, " | ") or "Kosong / Common"))

        task.wait(1)
    end
end)

WindUI:Notify({
    Title = "CROTTT HUB Dimuat!",
    Content = "Klik tombol TikTok mengambang untuk buka/tutup menu.",
    Duration = 4,
    Icon = CUSTOM_LOGO
})
