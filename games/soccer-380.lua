-- ============================================================
--  CROTTT HUB | SOCCER 380 (TikTok Logo Edition)
-- ============================================================

-- 1. LOADER WINDUI DENGAN CLONEREF & MULTI-FALLBACK
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

-- 2. TIKTOK LOGO LOADER DENGAN CACHE EXECUTOR
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
--  REMOTES DISCOVERY & SETUP
-- ============================================================
local RemotesFolder = ReplicatedStorage
    :WaitForChild("SharedModules", 10)
    :WaitForChild("Network", 10)
    :WaitForChild("Remotes", 10)

local PickupSlimeRemote     = RemotesFolder and RemotesFolder:FindFirstChild("Pickup Slime")
local PlaceSlimeRemote      = RemotesFolder and RemotesFolder:FindFirstChild("Place Slime")
local BuySpeedUpgrade       = RemotesFolder and RemotesFolder:FindFirstChild("Buy Speed Upgrade")
local CollectEarningsRemote = RemotesFolder and RemotesFolder:FindFirstChild("Collect Earnings")
local UpgradeSlimeRemote    = RemotesFolder and RemotesFolder:FindFirstChild("Upgrade Slime")

-- ============================================================
--  GLOBAL STATE & CONFIG
-- ============================================================
local Config = {
    Running         = false,
    PickupWait      = 0.25,
    PlaceWait       = 0.35,
    CollectDelay    = 0.5,
    LimitEnabled    = false,
    LimitAmount     = 50,
    MaxCarry        = 50,
    EnabledRarities = {
        ["LIMITED"]   = false,
        ["Japan"]     = true,
        ["Icons"]     = true,
        ["Spain"]     = true,
        ["Champions"] = false,
        ["OG"]        = false,
        ["Exclusive"] = false,
        ["Divine"]    = false,
        ["Slime God"] = false,
        ["Secret"]    = false,
        ["Mythic"]    = false,
        ["Legendary"] = false,
        ["Epic"]      = false,
        ["Rare"]      = false,
        ["Common"]    = false,
    }
}

local EarningsConfig = {
    Running           = false,
    MaxPlot           = 50,
    Interval          = 1.5,
    TotalCollectCount = 0,
}

local JumpConfig = {
    Running        = false,
    SelectedTier   = "Auto All",
    Delay          = 0.4,
    CheckCoin      = true,
    UpgradedCount  = 0,
}

local SoccerConfig = {
    Running        = false,
    Mode           = "All Slots",
    SpecificSlot   = 1,
    MaxSlots       = 50,
    Delay          = 0.25,
    TotalUpgrades  = 0,
}

local PlayerConfig = {
    DisableNotifications = false,
    WalkSpeedEnabled     = false,
    WalkSpeedValue       = 60,
    DefaultWalkSpeed     = 16,
    FlyEnabled           = false,
    FlySpeed             = 60,
}

local ResetState = {
    ResetCooldown = false,
}

local Stats = {
    TotalCollected      = 0,
    LastCollected       = "-",
    LastRarity          = "-",
    StatusText          = "IDLE (Siap)",
    SessionStartTime    = nil,
    SessionCollected    = 0,
    CollectedByRarity   = {
        ["LIMITED"] = 0, ["Japan"] = 0, ["Icons"] = 0, ["Spain"] = 0,
        ["Champions"] = 0, ["OG"] = 0, ["Exclusive"] = 0, ["Divine"] = 0,
        ["Slime God"] = 0, ["Secret"] = 0, ["Mythic"] = 0, ["Legendary"] = 0,
        ["Epic"] = 0, ["Rare"] = 0, ["Common"] = 0
    }
}

local RARITY_ORDER = {
    ["Common"]    = 1,
    ["Rare"]      = 2,
    ["Epic"]      = 3,
    ["Legendary"] = 4,
    ["Mythic"]    = 5,
    ["Secret"]    = 6,
    ["Slime God"] = 7,
    ["Divine"]    = 8,
    ["Exclusive"] = 9,
    ["OG"]        = 10,
    ["Champions"] = 11,
    ["Spain"]     = 12,
    ["Icons"]     = 13,
    ["Japan"]     = 14,
    ["LIMITED"]   = 15,
}

local BLOCK_NAME_TO_RARITY = {
    ["Common Lucky Block"]    = "Common",
    ["Water Lucky Block"]     = "Common",
    ["Rare Lucky Block"]      = "Rare",
    ["Volcanic Lucky Block"]  = "Rare",
    ["Epic Lucky Block"]      = "Epic",
    ["Ghost Lucky Block"]     = "Epic",
    ["Legendary Lucky Block"] = "Legendary",
    ["67 Lucky Block"]        = "Legendary",
    ["Mythic Lucky Block"]    = "Mythic",
    ["Poison Lucky Block"]    = "Mythic",
    ["Secret Lucky Block"]    = "Secret",
    ["Cosmic Lucky Block"]    = "Secret",
    ["Slime God Lucky Block"] = "Slime God",
    ["Rainbow Lucky Block"]   = "Slime God",
    ["Exclusive Lucky Block"] = "Exclusive",
    ["US Lucky Block"]        = "Exclusive",
    ["Limited Lucky Block"]   = "LIMITED",
    ["OG Lucky Block"]        = "OG",
    ["Champions Lucky Block"] = "Champions",
    ["Spain Lucky Block"]     = "Spain",
    ["Icons Lucky Block"]     = "Icons",
    ["Japan Lucky Block"]     = "Japan",
}

_G.SoccerCollectLogs = _G.SoccerCollectLogs or {}

-- ============================================================
--  HELPER: CASH & NUMBER PARSER
-- ============================================================
local SUFFIXES = {
    k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, q = 1e15, qi = 1e18,
    sx = 1e21, sp = 1e24, oc = 1e27, n = 1e30, dc = 1e33
}

local function parseSuffixNumber(str)
    if not str then return 0 end
    local clean = tostring(str):gsub(",", ""):gsub("%+", ""):gsub("%%", ""):gsub("%$", ""):gsub("%s+", ""):lower()
    local num, suffix = clean:match("^([%d%.]+)([a-z]*)$")
    if not num then return tonumber(clean) or 0 end
    local val = tonumber(num) or 0
    if suffix and suffix ~= "" and SUFFIXES[suffix] then
        val = val * SUFFIXES[suffix]
    end
    return val
end

local function formatSuffixNumber(val)
    local n = tonumber(val) or 0
    if n >= 1e18 then return string.format("$%.2fQi", n / 1e18)
    elseif n >= 1e15 then return string.format("$%.2fQa", n / 1e15)
    elseif n >= 1e12 then return string.format("$%.2fT", n / 1e12)
    elseif n >= 1e9 then return string.format("$%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("$%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("$%.1fK", n / 1e3)
    else return "$" .. tostring(math.floor(n)) end
end

local function getPlayerCash()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        local c = ls:FindFirstChild("Cash") or ls:FindFirstChild("Coins") or ls:FindFirstChild("Money")
        if c and c.Value then
            local val = tonumber(c.Value)
            if val and val >= 0 then return val end
        end
    end
    local attrCash = LocalPlayer:GetAttribute("Cash") or LocalPlayer:GetAttribute("Coins") or LocalPlayer:GetAttribute("Money")
    if attrCash then
        local val = tonumber(attrCash)
        if val and val >= 0 then return val end
    end
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, obj in ipairs(pGui:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Visible then
                local txt = obj.Text
                if txt:match("^%$%s*[%d%.]+%s*[A-Za-z]*$") then
                    local parsed = parseSuffixNumber(txt)
                    if parsed > 0 then return parsed end
                end
            end
        end
    end
    return 0
end

-- ============================================================
--  JUMP PRICING CALCULATION
-- ============================================================
local BASE_PRICE = 260
local GROWTH_PER_LEVEL = 1.082
local REFERENCE_FIVE_MULTIPLIER = 1.38
local SINGLE_PRICE_SCALE = 5 * REFERENCE_FIVE_MULTIPLIER / (1 + GROWTH_PER_LEVEL^1 + GROWTH_PER_LEVEL^2 + GROWTH_PER_LEVEL^3 + GROWTH_PER_LEVEL^4)

local function calcSinglePrice(level)
    return math.round(BASE_PRICE * (GROWTH_PER_LEVEL ^ level) * SINGLE_PRICE_SCALE)
end

local function calcBulkPrice(currentLevel, amount)
    local total = 0
    for i = 0, amount - 1 do
        total = total + calcSinglePrice(currentLevel + i)
    end
    return total
end

local function getPlayerJumpLevel()
    local attr = LocalPlayer:GetAttribute("Jump") or LocalPlayer:GetAttribute("Speed") or LocalPlayer:GetAttribute("JumpLevel")
    if attr and tonumber(attr) then return tonumber(attr) end

    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, lbl in ipairs(pGui:GetDescendants()) do
            if lbl:IsA("TextLabel") and lbl.Visible and lbl.Text:find("%->") then
                local cur = lbl.Text:match("(%d+)%s*%->")
                if cur and tonumber(cur) then return tonumber(cur) end
            end
        end
    end
    return 0
end

local function getPriceForTier(tierCode)
    local amount = (tierCode == 1 and 1) or (tierCode == 2 and 5) or 10
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, btn in ipairs(pGui:GetDescendants()) do
            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible then
                local txt = (btn:IsA("TextButton") and btn.Text or "")
                if txt == "" then
                    local lbl = btn:FindFirstChildOfClass("TextLabel")
                    if lbl then txt = lbl.Text end
                end
                if txt:match("^%$%s*[%d%.]+%s*[A-Za-z]*$") then
                    local pParent = btn.Parent
                    if pParent then
                        for _, child in ipairs(pParent:GetChildren()) do
                            if child:IsA("TextLabel") and child.Text:find("%+" .. amount) then
                                return parseSuffixNumber(txt)
                            end
                        end
                    end
                end
            end
        end
    end
    local curLevel = getPlayerJumpLevel()
    return calcBulkPrice(curLevel, amount)
end

-- ============================================================
--  CHARACTER & BASE DETECTION
-- ============================================================
local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
end

local function isAlive()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function waitRespawn(timeout)
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if char and hum and hum.Health > 0 then return true end
    local done = false
    local conn = LocalPlayer.CharacterAdded:Connect(function() done = true end)
    local t0   = tick()
    while not done and (tick() - t0) < timeout do task.wait(0.2) end
    conn:Disconnect()
    task.wait(1.2)
    return LocalPlayer.Character ~= nil
end

local function isHoldingSlime()
    local char = LocalPlayer.Character
    if not char then return false end
    if LocalPlayer:GetAttribute("holdingSlime") or char:GetAttribute("holdingSlime") then
        return true
    end
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Model") and (
            c.Name:find("Lucky Block") or c.Name:find("Slime")
            or c:FindFirstChild("Cube") or c:FindFirstChild("RootPart")
        ) then
            return true
        end
    end
    return false
end

local _cachedBaseCF    = nil
local _cachedBaseModel = nil

local function findPlayerBase()
    if _cachedBaseCF and _cachedBaseModel then return _cachedBaseCF, _cachedBaseModel end
    local uid = tostring(LocalPlayer.UserId)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local ownerId = obj:GetAttribute("OwnerId")
                     or obj:GetAttribute("PlotOwner")
                     or obj:GetAttribute("Owner")
        if ownerId and tostring(ownerId) == uid then
            if obj:IsA("BasePart") then
                _cachedBaseCF    = obj.CFrame
                _cachedBaseModel = obj.Parent
                return _cachedBaseCF, _cachedBaseModel
            elseif obj:IsA("Model") then
                local pp = obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
                if pp then
                    _cachedBaseCF    = pp.CFrame
                    _cachedBaseModel = obj
                    return _cachedBaseCF, _cachedBaseModel
                end
            end
        end
    end
    local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then _cachedBaseCF = spawn.CFrame; return _cachedBaseCF, spawn.Parent end
    local hrp = getHRP()
    if hrp then return hrp.CFrame, nil end
    return nil, nil
end

local function resetBaseCache()
    _cachedBaseCF    = nil
    _cachedBaseModel = nil
end

local function getActiveBaseSlots()
    local _, baseModel = findPlayerBase()
    local activeSlots = {}
    if baseModel then
        for _, descendant in ipairs(baseModel:GetDescendants()) do
            local num = tonumber(descendant.Name)
            if num and num >= 1 and num <= SoccerConfig.MaxSlots then
                if not table.find(activeSlots, num) then
                    table.insert(activeSlots, num)
                end
            end
        end
    end
    if #activeSlots == 0 then
        for i = 1, SoccerConfig.MaxSlots do
            table.insert(activeSlots, i)
        end
    else
        table.sort(activeSlots)
    end
    return activeSlots
end

-- ============================================================
--  DISABLE NOTIFICATIONS
-- ============================================================
local notifKeywords = { "notif", "notify", "notification", "alert", "announcement", "banner", "toast", "messagebox", "popup" }

local function isNotificationGui(obj)
    local name = obj.Name:lower()
    for _, kw in ipairs(notifKeywords) do
        if name:find(kw) then return true end
    end
    return false
end

local function applyNotificationState()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return end
    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and isNotificationGui(gui) then
            gui.Enabled = not PlayerConfig.DisableNotifications
        end
    end
end

local pGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if pGui then
    pGui.ChildAdded:Connect(function(child)
        if PlayerConfig.DisableNotifications and child:IsA("ScreenGui") and isNotificationGui(child) then
            task.wait(0.05)
            child.Enabled = false
        end
    end)
end

-- ============================================================
--  CORE LOGIC: SOCCER PLAYER UPGRADE
-- ============================================================
local function upgradeSingleSlot(slotIndex)
    if not UpgradeSlimeRemote and RemotesFolder then
        UpgradeSlimeRemote = RemotesFolder:FindFirstChild("Upgrade Slime")
    end
    if not UpgradeSlimeRemote then return false end

    local slotStr = tostring(slotIndex)
    local ok = pcall(function()
        UpgradeSlimeRemote:FireServer(slotStr)
    end)
    if ok then
        SoccerConfig.TotalUpgrades = SoccerConfig.TotalUpgrades + 1
    end
    return ok
end

local soccerLoopThread = nil
local function startSoccerUpgradeLoop()
    if soccerLoopThread then return end
    soccerLoopThread = task.spawn(function()
        while SoccerConfig.Running do
            if SoccerConfig.Mode == "All Slots" then
                for i = 1, SoccerConfig.MaxSlots do
                    if not SoccerConfig.Running then break end
                    upgradeSingleSlot(i)
                    task.wait(SoccerConfig.Delay)
                end
            elseif SoccerConfig.Mode == "Active Only" then
                local slots = getActiveBaseSlots()
                for _, sIndex in ipairs(slots) do
                    if not SoccerConfig.Running then break end
                    upgradeSingleSlot(sIndex)
                    task.wait(SoccerConfig.Delay)
                end
            elseif SoccerConfig.Mode == "Specific Slot" then
                upgradeSingleSlot(SoccerConfig.SpecificSlot)
                task.wait(SoccerConfig.Delay)
            end
            task.wait(0.2)
        end
        soccerLoopThread = nil
    end)
end

-- ============================================================
--  CORE LOGIC: COLLECT EARNINGS
-- ============================================================
local function collectEarningsAll(maxPlot)
    maxPlot = maxPlot or EarningsConfig.MaxPlot
    if not CollectEarningsRemote and RemotesFolder then
        CollectEarningsRemote = RemotesFolder:FindFirstChild("Collect Earnings")
    end
    if not CollectEarningsRemote then return end

    for i = 1, maxPlot do
        pcall(function()
            CollectEarningsRemote:FireServer(tostring(i))
        end)
    end
    EarningsConfig.TotalCollectCount = EarningsConfig.TotalCollectCount + 1
end

local earningsLoopThread = nil
local function startEarningsLoop()
    if earningsLoopThread then return end
    earningsLoopThread = task.spawn(function()
        while EarningsConfig.Running do
            collectEarningsAll(EarningsConfig.MaxPlot)
            task.wait(EarningsConfig.Interval)
        end
        earningsLoopThread = nil
    end)
end

-- ============================================================
--  CORE LOGIC: AUTO FARM LUCKY BLOCKS
-- ============================================================
local function getLuckyBlocks()
    local hrp   = getHRP()
    local myPos = hrp and hrp.Position or Vector3.zero
    local results = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not obj:IsA("Model") then continue end
        local rarityId = BLOCK_NAME_TO_RARITY[obj.Name]
        if not rarityId then continue end
        if not Config.EnabledRarities[rarityId] then continue end
        local rootPart = obj:FindFirstChild("RootPart")
                      or obj.PrimaryPart
                      or obj:FindFirstChildOfClass("BasePart")
        if not rootPart then continue end
        local pos  = rootPart.Position
        local dist = (pos - myPos).Magnitude
        table.insert(results, {
            model    = obj,
            rarity   = rarityId,
            order    = RARITY_ORDER[rarityId] or 0,
            position = pos,
            distance = dist,
            rootPart = rootPart,
        })
    end
    table.sort(results, function(a, b)
        if a.order ~= b.order then return a.order > b.order end
        return a.distance < b.distance
    end)
    return results
end

local isCollecting = false
local function collectCycle()
    if isCollecting or not Config.Running then return end
    isCollecting = true

    if not isAlive() then
        waitRespawn(15); task.wait(1); isCollecting = false; return
    end

    local invCount = LocalPlayer.Character
        and LocalPlayer.Character:GetAttribute("LuckyBlockCount") or 0
    if invCount >= Config.MaxCarry then
        Config.Running = false
        Stats.StatusText = "INVENTORY PENUH (50/50)"
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Inventory Penuh!",
                Text = "Batas 50 Lucky Block tercapai. Auto Farm berhenti!",
                Duration = 5
            })
        end)
        isCollecting = false
        return
    end

    if Config.LimitEnabled and Stats.SessionCollected >= Config.LimitAmount then
        Config.Running = false
        Stats.StatusText = string.format("LIMIT TERCAPAI (%d/%d)", Stats.SessionCollected, Config.LimitAmount)
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Auto Farm Selesai!",
                Text = string.format("Limit %d Lucky Block tercapai!", Config.LimitAmount),
                Duration = 4
            })
        end)
        isCollecting = false
        return
    end

    local blocks = getLuckyBlocks()
    if #blocks > 0 then
        local target = blocks[1]
        local hrp    = getHRP()
        if hrp then
            Stats.StatusText = ("Teleport ke: %s [%s]"):format(target.model.Name, target.rarity)
            hrp.CFrame = target.rootPart.CFrame * CFrame.new(0, 0.5, 0)
            pcall(function()
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
            task.wait(Config.PickupWait)

            if target.model.Parent then
                local pickedUp    = false
                local pickupStart = tick()
                while (tick() - pickupStart) < 2.0 and target.model.Parent and Config.Running do
                    if PickupSlimeRemote then
                        pcall(function() PickupSlimeRemote:FireServer(target.model) end)
                        pcall(function() PickupSlimeRemote:FireServer(target.rootPart) end)
                        pcall(function() PickupSlimeRemote:FireServer(target.model.Name) end)
                    end
                    for _, p in ipairs(Workspace:GetDescendants()) do
                        if p:IsA("ProximityPrompt") and p.Enabled then
                            local pParent = p.Parent
                            if pParent and (
                                pParent:IsDescendantOf(target.model)
                                or (hrp.Position - pParent.Position).Magnitude <= 10
                            ) then
                                p.HoldDuration           = 0
                                p.MaxActivationDistance  = 999999
                                p.RequiresLineOfSight    = false
                                if typeof(fireproximityprompt) == "function" then
                                    pcall(function() fireproximityprompt(p, 0) end)
                                end
                            end
                        end
                    end
                    task.wait(0.12)
                    if isHoldingSlime() or (not target.model.Parent) then
                        pickedUp = true; break
                    end
                end

                if pickedUp then
                    Stats.StatusText = "Membawa ke Base Plot..."
                    task.wait(0.15)
                    local baseCF = findPlayerBase()
                    if baseCF then
                        hrp.CFrame = baseCF + Vector3.new(0, 3.5, 0)
                        pcall(function()
                            hrp.AssemblyLinearVelocity  = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end)
                        task.wait(Config.PlaceWait)

                        local depositStart = tick()
                        while (tick() - depositStart) < 1.5 and Config.Running do
                            if PlaceSlimeRemote then
                                pcall(function() PlaceSlimeRemote:FireServer() end)
                                pcall(function() PlaceSlimeRemote:FireServer(target.model) end)
                            end
                            task.wait(0.15)
                            if not isHoldingSlime() then break end
                        end

                        Stats.TotalCollected = Stats.TotalCollected + 1
                        Stats.SessionCollected = Stats.SessionCollected + 1
                        Stats.LastCollected = target.model.Name
                        Stats.LastRarity = target.rarity
                        Stats.CollectedByRarity[target.rarity] = (Stats.CollectedByRarity[target.rarity] or 0) + 1

                        local logMsg = string.format("[%s] %s (Total: %d)", target.rarity, target.model.Name, Stats.TotalCollected)
                        table.insert(_G.SoccerCollectLogs, 1, logMsg)
                        if #_G.SoccerCollectLogs > 60 then table.remove(_G.SoccerCollectLogs) end
                    else
                        resetBaseCache()
                    end
                end
            end
        end
    else
        Stats.StatusText = "Scanning Lucky Block..."
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
            task.wait(Config.CollectDelay)
        end
        loopThread = nil
    end)
end

-- ============================================================
--  CORE LOGIC: AUTO UPGRADE JUMP
-- ============================================================
local function executeJumpBuy(tierCode)
    if not BuySpeedUpgrade and RemotesFolder then
        BuySpeedUpgrade = RemotesFolder:FindFirstChild("Buy Speed Upgrade")
    end
    if not BuySpeedUpgrade then return false end

    if JumpConfig.CheckCoin then
        local myCash = getPlayerCash()
        local cost = getPriceForTier(tierCode)
        if myCash > 0 and cost > 0 and myCash < cost then
            return false, cost, myCash
        end
    end

    local success = pcall(function()
        BuySpeedUpgrade:FireServer(tierCode)
    end)

    if success then
        JumpConfig.UpgradedCount = JumpConfig.UpgradedCount + 1
    end
    return true
end

local jumpLoopThread = nil
local function startJumpLoop()
    if jumpLoopThread then return end
    jumpLoopThread = task.spawn(function()
        while JumpConfig.Running do
            local myCash = getPlayerCash()

            if JumpConfig.SelectedTier == "Auto All" then
                local bought = false
                local price10 = getPriceForTier(3)
                local price5  = getPriceForTier(2)
                local price1  = getPriceForTier(1)

                if myCash == 0 or myCash >= price10 then
                    bought = executeJumpBuy(3)
                end
                if not bought and (myCash == 0 or myCash >= price5) then
                    bought = executeJumpBuy(2)
                end
                if not bought and (myCash == 0 or myCash >= price1) then
                    executeJumpBuy(1)
                end
            elseif JumpConfig.SelectedTier == "+10 Jump" then
                executeJumpBuy(3)
            elseif JumpConfig.SelectedTier == "+5 Jump" then
                executeJumpBuy(2)
            elseif JumpConfig.SelectedTier == "+1 Jump" then
                executeJumpBuy(1)
            end

            task.wait(JumpConfig.Delay)
        end
        jumpLoopThread = nil
    end)
end

-- ============================================================
--  PLAYER MOVEMENT (WALKSPEED & FLY)
-- ============================================================
local flyBodyVelocity = nil
local flyBodyGyro     = nil
local flyConnection   = nil
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

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if PlayerConfig.FlyEnabled then startFly() end
end)

-- ============================================================
--  WINDUI INTERFACE (IDENTIK DENGAN MINE A MOUNTAIN)
-- ============================================================
local Window = WindUI:CreateWindow({
    Title         = "CROTTT HUB | Soccer 380",
    Icon          = CUSTOM_LOGO,
    Author        = "by CROTTT Team",
    Folder        = "crottt_soccer380",
    Size          = UDim2.fromOffset(640, 520),
    HideSearchBar = false,
    OpenButton    = {
        Title           = "Open CROTTT HUB",
        CornerRadius    = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled         = false,
        Draggable       = true,
        OnlyMobile      = false,
        Scale           = 0.8,
    },
    Topbar = {
        Height      = 44,
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
    Desc  = string.format("User: %s (@%s)\nStatus: 🟢 Keyless (Active)\nExecutor: %s", LocalPlayer.Name, LocalPlayer.DisplayName, getExecutorName())
})

TabInfo:Section({ Title = "Informasi Game & Server" })

local GameInfoPara = TabInfo:Paragraph({
    Title = "🎮 Game Info",
    Desc  = string.format("Game: Soccer 380\nPlace ID: %d\nSession Time: 0m 0s\nJam (Waktu): %s", game.PlaceId, os.date("%X"))
})

TabInfo:Button({
    Title = "📋 Copy Server Job ID",
    Desc  = "Salin Job ID server ke clipboard",
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
--  TAB 2: COLLECTOR (AUTO FARM & FILTER RARITY)
-- ============================================================
local TabCollect = MainSection:Tab({ Title = "Collector", Icon = "solar:check-square-bold", Border = true })

TabCollect:Section({ Title = "Kontrol Auto Farm Lucky Block" })

local CollectStatusPara = TabCollect:Paragraph({ Title = "Status Pengambilan", Desc = "Status: IDLE (Siap)" })

TabCollect:Toggle({
    Title    = "Aktifkan Auto Collect",
    Desc     = "Mengambil lucky block secara instan di map dan bawa ke base",
    Value    = Config.Running,
    Callback = function(state)
        Config.Running = state
        if state then
            resetBaseCache()
            startLoop()
        end
    end
})

TabCollect:Toggle({
    Title    = "Auto Collect Earnings (Plot 1-50)",
    Desc     = "Otomatis ambil penghasilan plot 1 sampai 50 secara berkala",
    Value    = EarningsConfig.Running,
    Callback = function(state)
        EarningsConfig.Running = state
        if state then startEarningsLoop() end
    end
})

TabCollect:Button({
    Title    = "💰 Collect 1x Instan (Plot 1-50)",
    Desc     = "Klaim cash semua plot sekarang juga",
    Callback = function()
        collectEarningsAll(EarningsConfig.MaxPlot)
        WindUI:Notify({ Title = "Earnings", Content = "Semua plot 1-50 berhasil diklaim!", Duration = 2 })
    end
})

TabCollect:Section({ Title = "Limit Pengambilan" })

TabCollect:Toggle({
    Title    = "Aktifkan Limit Jumlah",
    Desc     = "Otomatis berhenti jika kuota lucky block tercapai",
    Value    = Config.LimitEnabled,
    Callback = function(state) Config.LimitEnabled = state end
})

TabCollect:Input({
    Title       = "Batas Limit (Jumlah Lucky Block)",
    Value       = tostring(Config.LimitAmount),
    Placeholder = "50",
    Callback    = function(txt)
        local n = tonumber(txt)
        if n and n > 0 then Config.LimitAmount = math.floor(n) end
    end
})

TabCollect:Section({ Title = "Filter by Rarity (Soccer 380 Codebase)" })

TabCollect:Dropdown({
    Title  = "Preset Rarity Cepat",
    Desc   = "Pilih kombinasi filter rarity secara instan",
    Values = {
        "⭐ Semua Rarity (ON)",
        "🔥 High Tier (Japan, Icons, Spain, Champions, OG, LIMITED)",
        "✨ Japan & Icons Only",
        "❌ Semua (OFF)"
    },
    Value  = "⭐ Semua Rarity (ON)",
    Callback = function(preset)
        if preset:find("Semua Rarity") then
            for k in pairs(Config.EnabledRarities) do Config.EnabledRarities[k] = true end
        elseif preset:find("Semua %(OFF%)") then
            for k in pairs(Config.EnabledRarities) do Config.EnabledRarities[k] = false end
        elseif preset:find("High Tier") then
            for k in pairs(Config.EnabledRarities) do Config.EnabledRarities[k] = false end
            Config.EnabledRarities["Japan"]     = true
            Config.EnabledRarities["Icons"]     = true
            Config.EnabledRarities["Spain"]     = true
            Config.EnabledRarities["Champions"] = true
            Config.EnabledRarities["OG"]        = true
            Config.EnabledRarities["LIMITED"]   = true
            Config.EnabledRarities["Exclusive"] = true
        elseif preset:find("Japan & Icons") then
            for k in pairs(Config.EnabledRarities) do Config.EnabledRarities[k] = false end
            Config.EnabledRarities["Japan"] = true
            Config.EnabledRarities["Icons"] = true
            Config.EnabledRarities["Spain"] = true
        end
    end
})

-- Toggle Individual Rarity Lengkap Codebase Soccer 380
local SoccerRarities = {
    { id = "LIMITED",   name = "LIMITED Lucky Block",   desc = "Tier 15 | Limited Edition" },
    { id = "Japan",     name = "Japan Lucky Block",     desc = "Tier 14 | Sangat Langka" },
    { id = "Icons",     name = "Icons Lucky Block",     desc = "Tier 13 | Golden Icon" },
    { id = "Spain",     name = "Spain Lucky Block",     desc = "Tier 12 | Champions Tier" },
    { id = "Champions", name = "Champions Lucky Block", desc = "Tier 11 | World Class" },
    { id = "OG",        name = "OG Lucky Block",        desc = "Tier 10 | Original Block" },
    { id = "Exclusive", name = "Exclusive Lucky Block", desc = "Tier 9 | US & Exclusive" },
    { id = "Divine",    name = "Divine Lucky Block",    desc = "Tier 8 | Divine Slime" },
    { id = "Slime God", name = "Slime God Lucky Block", desc = "Tier 7 | Godly Slime" },
    { id = "Secret",    name = "Secret Lucky Block",    desc = "Tier 6 | Cosmic Block" },
    { id = "Mythic",    name = "Mythic Lucky Block",    desc = "Tier 5 | Poison Block" },
    { id = "Legendary", name = "Legendary Lucky Block", desc = "Tier 4 | 67 Block" },
    { id = "Epic",      name = "Epic Lucky Block",      desc = "Tier 3 | Ghost Block" },
    { id = "Rare",      name = "Rare Lucky Block",      desc = "Tier 2 | Volcanic Block" },
    { id = "Common",    name = "Common Lucky Block",    desc = "Tier 1 | Water Block" },
}

for _, rInfo in ipairs(SoccerRarities) do
    TabCollect:Toggle({
        Title    = rInfo.name,
        Desc     = rInfo.desc,
        Value    = Config.EnabledRarities[rInfo.id] == true,
        Callback = function(st)
            Config.EnabledRarities[rInfo.id] = st
        end
    })
end

-- ============================================================
--  TAB 3: STATS & SESI
-- ============================================================
local TabStats = MainSection:Tab({ Title = "Stats & Sesi", Icon = "solar:file-text-bold", Border = true })

TabStats:Section({ Title = "Statistik Sesi Pengambilan" })
local SessionPara = TabStats:Paragraph({ Title = "Waktu Sesi & Rate", Desc = "Durasi: 00:00:00 | 0/mnt" })

TabStats:Section({ Title = "Status Upgrade & Base" })
local UpgradesSummaryPara = TabStats:Paragraph({ Title = "Total Upgrade", Desc = "Memuat data upgrade..." })

-- ============================================================
--  TAB 4: UPGRADES (JUMP & SOCCER PLAYER)
-- ============================================================
local TabUpgrades = MainSection:Tab({ Title = "Upgrades", Icon = "solar:cursor-square-bold", Border = true })

TabUpgrades:Section({ Title = "Jump Upgrade (+1, +5, +10, Auto)" })

TabUpgrades:Toggle({
    Title    = "Aktifkan Auto Upgrade Jump",
    Desc     = "Otomatis upgrade jump level dengan remote",
    Value    = JumpConfig.Running,
    Callback = function(state)
        JumpConfig.Running = state
        if state then startJumpLoop() end
    end
})

TabUpgrades:Dropdown({
    Title    = "Pilih Porsi Upgrade Jump",
    Desc     = "Auto All akan prioritaskan +10 -> +5 -> +1 sesuai koin",
    Values   = { "Auto All", "+10 Jump", "+5 Jump", "+1 Jump" },
    Value    = "Auto All",
    Multi    = false,
    Callback = function(val)
        JumpConfig.SelectedTier = val
    end
})

TabUpgrades:Toggle({
    Title    = "Smart Coin Protection",
    Desc     = "Mencegah pembelian jika koin kurang (Anti popup Robux spam)",
    Value    = JumpConfig.CheckCoin,
    Callback = function(state) JumpConfig.CheckCoin = state end
})

TabUpgrades:Input({
    Title       = "Jeda Upgrade Jump (Detik)",
    Desc        = "Waktu tunggu per loop (default: 0.4)",
    Value       = tostring(JumpConfig.Delay),
    Placeholder = "0.4",
    Callback    = function(txt)
        local val = tonumber(txt)
        if val and val >= 0.05 then JumpConfig.Delay = val end
    end
})

TabUpgrades:Section({ Title = "Soccer Player Upgrade (Slot 1-50)" })

TabUpgrades:Toggle({
    Title    = "Aktifkan Auto Upgrade Soccer Player",
    Desc     = "Upgrade pemain soccer di plot base secara terus-menerus",
    Value    = SoccerConfig.Running,
    Callback = function(state)
        SoccerConfig.Running = state
        if state then startSoccerUpgradeLoop() end
    end
})

TabUpgrades:Dropdown({
    Title    = "Target Slot Base Player",
    Desc     = "Pilih cakupan slot plot yang akan di-upgrade",
    Values   = { "All Slots", "Active Only", "Specific Slot" },
    Value    = "All Slots",
    Multi    = false,
    Callback = function(val) SoccerConfig.Mode = val end
})

TabUpgrades:Slider({
    Title    = "Nomor Slot Spesifik",
    Desc     = "Digunakan jika mode 'Specific Slot' dipilih",
    Step     = 1,
    Value    = { Min = 1, Max = 50, Default = SoccerConfig.SpecificSlot },
    Callback = function(val) SoccerConfig.SpecificSlot = math.floor(val) end
})

TabUpgrades:Input({
    Title       = "Jeda Upgrade Slot (Detik)",
    Desc        = "Waktu tunggu per proses upgrade slot (default: 0.25)",
    Value       = tostring(SoccerConfig.Delay),
    Placeholder = "0.25",
    Callback    = function(txt)
        local val = tonumber(txt)
        if val and val >= 0.05 then SoccerConfig.Delay = val end
    end
})

TabUpgrades:Button({
    Title    = "⚡ UPGRADE ALL SLOTS 1X (1 s/d 50)",
    Desc     = "Trigger upgrade untuk semua slot 1 s/d 50 sekaligus",
    Callback = function()
        for i = 1, SoccerConfig.MaxSlots do
            upgradeSingleSlot(i)
        end
        WindUI:Notify({ Title = "Soccer Upgrade", Content = "Semua slot 1-50 berhasil diupgrade 1x!", Duration = 2 })
    end
})

-- ============================================================
--  UTILITIES SECTION (RESET & PLAYER)
-- ============================================================
local UtilitySection = Window:Section({ Title = "Utilities" })

-- TAB 5: RESET & CACHE
local TabReset = UtilitySection:Tab({ Title = "Reset & Cache", Icon = "solar:square-transfer-horizontal-bold", Border = true })

TabReset:Section({ Title = "Fast Character Reset" })

TabReset:Button({
    Title    = "💀 RESET CHARACTER (BreakJoints)",
    Desc     = "Fast die dengan cooldown aman untuk respawn",
    Callback = function()
        if ResetState.ResetCooldown then return end
        ResetState.ResetCooldown = true
        if LocalPlayer.Character then pcall(function() LocalPlayer.Character:BreakJoints() end) end
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title    = "Character Reset",
                Text     = "Cooldown 6 detik untuk keamanan...",
                Duration = 3
            })
        end)
        task.spawn(function()
            task.wait(6)
            ResetState.ResetCooldown = false
        end)
    end
})

TabReset:Section({ Title = "Base Plot Cache" })

TabReset:Button({
    Title    = "🔄 Reset Base Plot Cache",
    Desc     = "Gunakan jika posisi plot player berpindah / error",
    Callback = function()
        resetBaseCache()
        WindUI:Notify({ Title = "Base Cache", Content = "Cache base plot berhasil direset!", Duration = 2 })
    end
})

-- TAB 6: PLAYER MODIFIERS
local TabPlayer = UtilitySection:Tab({ Title = "Player", Icon = "solar:password-minimalistic-input-bold", Border = true })

TabPlayer:Section({ Title = "Game UI & Notifications" })

TabPlayer:Toggle({
    Title    = "Disable Game Notifications",
    Desc     = "Sembunyikan semua popup notifikasi, banner, dan announcement dalam game",
    Value    = PlayerConfig.DisableNotifications,
    Callback = function(state)
        PlayerConfig.DisableNotifications = state
        applyNotificationState()
        WindUI:Notify({
            Title    = "Game Notifications",
            Content  = state and "Notifikasi Game Dinonaktifkan" or "Notifikasi Game Diaktifkan",
            Duration = 2
        })
    end
})

TabPlayer:Section({ Title = "WalkSpeed Modifier" })

TabPlayer:Toggle({
    Title    = "Aktifkan WalkSpeed",
    Desc     = "Ubah kecepatan berjalan karakter",
    Value    = PlayerConfig.WalkSpeedEnabled,
    Callback = function(st)
        PlayerConfig.WalkSpeedEnabled = st
        if not st and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = PlayerConfig.DefaultWalkSpeed
        end
    end
})

TabPlayer:Slider({
    Title    = "Kecepatan Lari",
    Step     = 5,
    Value    = { Min = 16, Max = 250, Default = PlayerConfig.WalkSpeedValue },
    Callback = function(v) PlayerConfig.WalkSpeedValue = v end
})

TabPlayer:Section({ Title = "FlyHigh (Terbang Bebas)" })

TabPlayer:Toggle({
    Title    = "Aktifkan FlyHigh",
    Desc     = "Gunakan WASD, Space (Naik), Shift/Ctrl (Turun)",
    Value    = PlayerConfig.FlyEnabled,
    Callback = function(st)
        PlayerConfig.FlyEnabled = st
        if st then startFly() else stopFly() end
    end
})

TabPlayer:Slider({
    Title    = "Kecepatan Terbang",
    Step     = 5,
    Value    = { Min = 20, Max = 200, Default = PlayerConfig.FlySpeed },
    Callback = function(v) PlayerConfig.FlySpeed = v end
})

-- ============================================================
--  BACKGROUND STATS & LIVE TICKER
-- ============================================================
task.spawn(function()
    while true do
        local elapsed = os.time() - ScriptStartTime
        local h = math.floor(elapsed / 3600); local m = math.floor((elapsed % 3600) / 60); local s = elapsed % 60
        local timeString = os.date("%X")

        -- Update Info Tab
        GameInfoPara:SetDesc(string.format(
            "Game: Soccer 380\nPlace ID: %d\nSession Time: %dm %ds\nJam (Waktu): %s\nKoin Player: %s",
            game.PlaceId,
            math.floor(elapsed / 60),
            s,
            timeString,
            formatSuffixNumber(getPlayerCash())
        ))

        -- Update Collector Status
        if Config.Running then
            CollectStatusPara:SetDesc(string.format("Mengambil... | Total Diambil: %d Block", Stats.SessionCollected))
        else
            CollectStatusPara:SetDesc("Status: IDLE (Dihentikan)")
        end

        -- Update Session Stats
        if Stats.SessionStartTime and Config.Running then
            local cElapsed = os.time() - Stats.SessionStartTime
            local ch = math.floor(cElapsed / 3600); local cm = math.floor((cElapsed % 3600) / 60); local cs = cElapsed % 60
            local rate = (cElapsed > 0) and math.floor((Stats.SessionCollected / (cElapsed / 60)) * 10) / 10 or 0
            SessionPara:SetDesc(string.format("Durasi: %02d:%02d:%02d | Kecepatan: %.1f/mnt | Diambil: %d", ch, cm, cs, rate, Stats.SessionCollected))
        else
            SessionPara:SetDesc(string.format("Durasi: %02d:%02d:%02d | Total Diambil: %d Block", h, m, s, Stats.TotalCollected))
        end

        -- Update Upgrades Summary
        UpgradesSummaryPara:SetDesc(string.format(
            "Jump Upgrades: %d Kali (Level: %d)\nSoccer Upgrades: %d Kali\nEarnings Collected: %d Kali",
            JumpConfig.UpgradedCount,
            getPlayerJumpLevel(),
            SoccerConfig.TotalUpgrades,
            EarningsConfig.TotalCollectCount
        ))

        task.wait(1)
    end
end)

WindUI:Notify({
    Title    = "CROTTT HUB Dimuat!",
    Content  = "Klik tombol TikTok mengambang untuk buka/tutup menu.",
    Duration = 4,
    Icon     = CUSTOM_LOGO
})
