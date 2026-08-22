-- ============================================================
--  FILE NAME : soccer-380.lua
--  DESKRIPSI : Script Auto Farm, Upgrades, & Multi-Tool Soccer 380
--  UI ENGINE : WindUI (Footagesus)
-- ============================================================

-- 1. CEK SINGLE EXECUTION (Mencegah GUI Tumpuk)
if _G.Soccer380Running then
    pcall(function()
        if _G.Soccer380Window then
            _G.Soccer380Window:Destroy()
        end
    end)
end
_G.Soccer380Running = true

-- 2. CLONEREF SERVICES & INITIALIZATION
local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)

local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService        = cloneref(game:GetService("RunService"))
local Players           = cloneref(game:GetService("Players"))
local Workspace         = cloneref(game:GetService("Workspace"))
local UserInputService  = cloneref(game:GetService("UserInputService"))
local StarterGui        = cloneref(game:GetService("StarterGui"))
local TweenService      = cloneref(game:GetService("TweenService"))

local LocalPlayer = Players.LocalPlayer

-- 3. LOADER WINDUI DENGAN MULTI-FALLBACK
local WindUI = nil
local loaderUrls = {
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
    "https://github.com/Footagesus/WindUI/releases/latest/download/WindUI.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"
}

for _, url in ipairs(loaderUrls) do
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if success and result then
        WindUI = result
        break
    end
end

if not WindUI then
    warn("[Soccer 380] Gagal mengunduh WindUI.")
    return
end

-- ============================================================
--  REMOTES DISCOVERY
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
--  RARITY DATA & MAPPING
-- ============================================================
local RARITY_LIST = {
    "Japan", "Icons", "Spain", "Champions", "OG", 
    "LIMITED", "Exclusive", "Divine", "Slime God", 
    "Secret", "Mythic", "Legendary", "Epic", "Rare", "Common"
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

-- ============================================================
--  CONFIGURATIONS
-- ============================================================
local FarmConfig = {
    Running       = false,
    LoopDelay     = 0.5,
    PickupWait    = 0.25,
    PlaceWait     = 0.35,
    MaxCarry      = 50,
    EnabledRarities = {
        Icons = true,
        Japan = true,
    },
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
    FlyEnabled           = false,
    FlySpeed             = 60,
    MinSpeed             = 1,
    MaxSpeed             = 500,
}

local sessionPickedCount = 0

-- ============================================================
--  HELPER FUNCTIONS: CASH, JUMP, & MATH
-- ============================================================
local SUFFIXES = {
    k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, q = 1e15, qi = 1e18,
    sx = 1e21, sp = 1e24, oc = 1e27, n = 1e30, dc = 1e33
}

local function parseSuffixedNumber(str)
    if type(str) == "number" then return str end
    if type(str) ~= "string" then return 0 end
    local clean = str:gsub("[$,%s]", ""):lower()
    local numStr, suf = clean:match("^([%d%.]+)%s*([a-z]*)$")
    if not numStr then return 0 end
    local val = tonumber(numStr) or 0
    if suf and suf ~= "" and SUFFIXES[suf] then
        return val * SUFFIXES[suf]
    end
    return val
end

local function formatNumberShort(num)
    if not num or num == 0 then return "$0" end
    if num >= 1e15 then return string.format("$%.2fQa", num / 1e15) end
    if num >= 1e12 then return string.format("$%.2fT",  num / 1e12) end
    if num >= 1e9  then return string.format("$%.2fB",  num / 1e9)  end
    if num >= 1e6  then return string.format("$%.2fM",  num / 1e6)  end
    if num >= 1e3  then return string.format("$%.2fK",  num / 1e3)  end
    return string.format("$%d", math.floor(num))
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
                    local parsed = parseSuffixedNumber(txt)
                    if parsed > 0 then return parsed end
                end
            end
        end
    end
    return 0
end

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
                                return parseSuffixedNumber(txt)
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

-- ============================================================
--  BASE & PLOT FINDER
-- ============================================================
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
--  DISABLE NOTIFICATIONS SYSTEM
-- ============================================================
local notifKeywords = { "notif", "notify", "notification", "alert", "announcement", "banner", "toast", "messagebox", "popup" }

local function isNotificationGui(obj)
    local name = obj.Name:lower()
    for _, kw in ipairs(notifKeywords) do
        if name:find(kw) then
            return true
        end
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

local function stopSoccerUpgradeLoop()
    SoccerConfig.Running = false
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

local function stopEarningsLoop()
    EarningsConfig.Running = false
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
        if not FarmConfig.EnabledRarities[rarityId] then continue end
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

local function runFarmCycle()
    if not isAlive() then
        waitRespawn(15); task.wait(1); return
    end

    local invCount = LocalPlayer.Character
        and LocalPlayer.Character:GetAttribute("LuckyBlockCount") or 0
    if invCount >= FarmConfig.MaxCarry then
        FarmConfig.Running = false
        WindUI:Notify({
            Title = "Inventory Penuh!",
            Content = ("Batas %d Lucky Block tercapai. Auto Farm dinonaktifkan."):format(FarmConfig.MaxCarry),
            Duration = 5
        })
        return
    end

    local blocks = getLuckyBlocks()
    if #blocks == 0 then
        return
    end

    local target = blocks[1]
    local hrp    = getHRP()
    if not hrp then return end

    hrp.CFrame = target.rootPart.CFrame * CFrame.new(0, 0.5, 0)
    pcall(function()
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    task.wait(FarmConfig.PickupWait)

    if not target.model.Parent then return end

    local pickedUp    = false
    local pickupStart = tick()
    while (tick() - pickupStart) < 2.0 and target.model.Parent and FarmConfig.Running do
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

    if not pickedUp then
        task.wait(0.2); return
    end

    task.wait(0.15)
    local baseCF = findPlayerBase()
    if not baseCF then
        resetBaseCache(); return
    end

    hrp.CFrame = baseCF + Vector3.new(0, 3.5, 0)
    pcall(function()
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    task.wait(FarmConfig.PlaceWait)

    local depositStart = tick()
    while (tick() - depositStart) < 1.5 and FarmConfig.Running do
        if PlaceSlimeRemote then
            pcall(function() PlaceSlimeRemote:FireServer() end)
            pcall(function() PlaceSlimeRemote:FireServer(target.model) end)
        end
        task.wait(0.15)
        if not isHoldingSlime() then break end
    end

    sessionPickedCount = sessionPickedCount + 1
end

local farmLoopThread = nil
local function startFarmLoop()
    if farmLoopThread then return end
    farmLoopThread = task.spawn(function()
        while FarmConfig.Running do
            pcall(runFarmCycle)
            task.wait(FarmConfig.LoopDelay)
        end
        farmLoopThread = nil
    end)
end
local function stopFarmLoop() FarmConfig.Running = false end

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

local function stopJumpLoop()
    JumpConfig.Running = false
end

-- ============================================================
--  CORE LOGIC: FLY SYSTEM
-- ============================================================
local flyConn      = nil
local flyBodyVel   = nil
local flyBodyGyro  = nil
local _flyParts    = {}

local function cleanFlyParts()
    for _, p in ipairs(_flyParts) do
        pcall(function() p:Destroy() end)
    end
    _flyParts    = {}
    flyBodyVel   = nil
    flyBodyGyro  = nil
end

local function startFly()
    cleanFlyParts()
    local char = LocalPlayer.Character
    local hrp  = getHRP()
    if not char or not hrp then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end

    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.zero
    bv.MaxForce  = Vector3.new(1e6, 1e6, 1e6)
    bv.P         = 9000
    bv.Parent    = hrp
    flyBodyVel   = bv
    table.insert(_flyParts, bv)

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bg.P         = 9000
    bg.D         = 100
    bg.CFrame    = hrp.CFrame
    bg.Parent    = hrp
    flyBodyGyro  = bg
    table.insert(_flyParts, bg)

    flyConn = RunService.Heartbeat:Connect(function()
        local fhrp = getHRP()
        if not fhrp or not PlayerConfig.FlyEnabled then
            cleanFlyParts()
            local fhum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if fhum then fhum.PlatformStand = false end
            if flyConn then flyConn:Disconnect(); flyConn = nil end
            return
        end

        local cam = Workspace.CurrentCamera
        local cf  = cam.CFrame
        local dir = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
            dir = dir + cf.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
            dir = dir - cf.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
            dir = dir - cf.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
            dir = dir + cf.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            dir = dir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            dir = dir - Vector3.new(0, 1, 0)
        end

        if dir.Magnitude > 0 then
            dir = dir.Unit * PlayerConfig.FlySpeed
        end

        if flyBodyVel  then flyBodyVel.Velocity = dir end
        if flyBodyGyro then flyBodyGyro.CFrame   = cf end
    end)
end

local function stopFly()
    PlayerConfig.FlyEnabled = false
    cleanFlyParts()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if PlayerConfig.FlyEnabled then startFly() end
end)

-- ============================================================
--  WIND UI WINDOW & TABS BUILDER
-- ============================================================
local Window = WindUI:CreateWindow({
    Title        = "AHH CROTT - Soccer 380",
    Icon         = "flame",
    Author       = "Multi-Tool Hub",
    Folder       = "Soccer380Hub",
    Size         = UDim2.fromOffset(580, 460),
    Transparent  = true,
    Theme        = "Dark",
    SideBarWidth = 175,
    HasOutline   = true,
})
_G.Soccer380Window = Window

-- ------------------------------------------------------------
-- [TAB 1] AUTO FARM LUCKY BLOCK
-- ------------------------------------------------------------
local FarmTab = Window:Tab({
    Title = "Auto Farm",
    Icon  = "trees"
})

FarmTab:Section({ Title = "Lucky Block Farming", TextXAlignment = "Left" })

FarmTab:Toggle({
    Title    = "Auto Farm Lucky Block",
    Desc     = "Teleport, ambil lucky block sesuai filter, dan bawa ke base",
    Value    = FarmConfig.Running,
    Callback = function(state)
        FarmConfig.Running = state
        if state then
            resetBaseCache()
            startFarmLoop()
            WindUI:Notify({ Title = "Auto Farm", Content = "Auto Farm Diaktifkan", Duration = 2 })
        else
            stopFarmLoop()
            WindUI:Notify({ Title = "Auto Farm", Content = "Auto Farm Dinonaktifkan", Duration = 2 })
        end
    end
})

local RarityDropdown = FarmTab:Dropdown({
    Title       = "Filter Rarity Lucky Block",
    Desc        = "Pilih rarity yang ingin di-farm (Searchable & Multi-select)",
    Values      = RARITY_LIST,
    Value       = { "Japan", "Icons" },
    Multi       = true,
    AllowNone   = true,
    Callback    = function(selected)
        for _, r in ipairs(RARITY_LIST) do
            FarmConfig.EnabledRarities[r] = false
        end
        if type(selected) == "table" then
            for k, v in pairs(selected) do
                if type(k) == "string" and v == true then
                    FarmConfig.EnabledRarities[k] = true
                elseif type(v) == "string" then
                    FarmConfig.EnabledRarities[v] = true
                end
            end
        elseif type(selected) == "string" then
            FarmConfig.EnabledRarities[selected] = true
        end
    end
})

FarmTab:Button({
    Title    = "Preset: Japan, Icons & Spain",
    Desc     = "Filter cepat khusus rarity bernilai tinggi",
    Callback = function()
        RarityDropdown:Select({ "Japan", "Icons", "Spain" })
        WindUI:Notify({ Title = "Filter Rarity", Content = "Preset diterapkan!", Duration = 2 })
    end
})

FarmTab:Button({
    Title    = "Reset Base Plot Cache",
    Desc     = "Gunakan jika posisi plot player berpindah/error",
    Callback = function()
        resetBaseCache()
        WindUI:Notify({ Title = "Base Cache", Content = "Cache base plot berhasil direset!", Duration = 2 })
    end
})

FarmTab:Section({ Title = "Auto Collect Earnings (Plot 1-50)", TextXAlignment = "Left" })

FarmTab:Toggle({
    Title    = "Auto Collect Earnings",
    Desc     = "Otomatis ambil penghasilan dari Plot 1 sampai 50 secara berkala",
    Value    = EarningsConfig.Running,
    Callback = function(state)
        EarningsConfig.Running = state
        if state then
            startEarningsLoop()
            WindUI:Notify({ Title = "Collect Earnings", Content = "Auto Collect ON", Duration = 2 })
        else
            stopEarningsLoop()
            WindUI:Notify({ Title = "Collect Earnings", Content = "Auto Collect OFF", Duration = 2 })
        end
    end
})

FarmTab:Button({
    Title    = "Collect 1x Instan",
    Desc     = "Klaim cash semua plot (1-50) sekarang juga",
    Callback = function()
        collectEarningsAll(EarningsConfig.MaxPlot)
        WindUI:Notify({ Title = "Collect Earnings", Content = "Semua plot 1-50 berhasil diklaim!", Duration = 2 })
    end
})

-- ------------------------------------------------------------
-- [TAB 2] AUTO UPGRADE JUMP
-- ------------------------------------------------------------
local JumpTab = Window:Tab({
    Title = "Jump Upgrade",
    Icon  = "arrow-up"
})

JumpTab:Section({ Title = "Pengaturan Auto Upgrade Jump", TextXAlignment = "Left" })

JumpTab:Toggle({
    Title    = "Auto Upgrade Jump",
    Desc     = "Otomatis upgrade jump level dengan remote code",
    Value    = JumpConfig.Running,
    Callback = function(state)
        JumpConfig.Running = state
        if state then
            startJumpLoop()
            WindUI:Notify({ Title = "Upgrade Jump", Content = "Auto Upgrade Jump Dimulai", Duration = 2 })
        else
            stopJumpLoop()
            WindUI:Notify({ Title = "Upgrade Jump", Content = "Auto Upgrade Jump Berhenti", Duration = 2 })
        end
    end
})

JumpTab:Dropdown({
    Title     = "Pilih Porsi Upgrade Jump",
    Desc      = "Pilih porsi upgrade (Auto All akan prioritaskan +10 -> +5 -> +1)",
    Values    = { "Auto All", "+10 Jump", "+5 Jump", "+1 Jump" },
    Value     = "Auto All",
    Multi     = false,
    Callback  = function(val)
        JumpConfig.SelectedTier = val
    end
})

JumpTab:Toggle({
    Title    = "Smart Coin Protection",
    Desc     = "Mencegah pembelian jika koin kurang (Anti popup Robux spam)",
    Value    = JumpConfig.CheckCoin,
    Callback = function(state)
        JumpConfig.CheckCoin = state
    end
})

JumpTab:Input({
    Title       = "Jeda Upgrade (Detik)",
    Desc        = "Waktu tunggu per proses upgrade (default: 0.4)",
    Value       = tostring(JumpConfig.Delay),
    Placeholder = "0.4",
    Callback    = function(text)
        local val = tonumber(text)
        if val and val >= 0.05 then
            JumpConfig.Delay = val
        end
    end
})

-- ------------------------------------------------------------
-- [TAB 3] AUTO UPGRADE SOCCER PLAYER (SLIME UPGRADE)
-- ------------------------------------------------------------
local SoccerTab = Window:Tab({
    Title = "Soccer Upgrade",
    Icon  = "circle-dot"
})

SoccerTab:Section({ Title = "Upgrade Soccer Player Plot (1-50)", TextXAlignment = "Left" })

SoccerTab:Toggle({
    Title    = "Auto Upgrade Soccer Player",
    Desc     = "Upgrade pemain soccer di plot base secara terus-menerus",
    Value    = SoccerConfig.Running,
    Callback = function(state)
        SoccerConfig.Running = state
        if state then
            startSoccerUpgradeLoop()
            WindUI:Notify({ Title = "Soccer Upgrade", Content = "Auto Upgrade Soccer Dimulai", Duration = 2 })
        else
            stopSoccerUpgradeLoop()
            WindUI:Notify({ Title = "Soccer Upgrade", Content = "Auto Upgrade Soccer Berhenti", Duration = 2 })
        end
    end
})

SoccerTab:Dropdown({
    Title    = "Target Slot Base Player",
    Desc     = "Pilih cakupan slot yang akan di-upgrade",
    Values   = { "All Slots", "Active Only", "Specific Slot" },
    Value    = "All Slots",
    Multi    = false,
    Callback = function(val)
        SoccerConfig.Mode = val
    end
})

SoccerTab:Slider({
    Title    = "Nomor Slot Spesifik",
    Desc     = "Digunakan saat mode 'Specific Slot' dipilih",
    Value    = SoccerConfig.SpecificSlot,
    Min      = 1,
    Max      = 50,
    Step     = 1,
    Callback = function(val)
        SoccerConfig.SpecificSlot = math.floor(val)
    end
})

SoccerTab:Input({
    Title       = "Jeda Upgrade Slot (Detik)",
    Desc        = "Waktu tunggu per slot upgrade (default: 0.25)",
    Value       = tostring(SoccerConfig.Delay),
    Placeholder = "0.25",
    Callback    = function(text)
        local val = tonumber(text)
        if val and val >= 0.05 then
            SoccerConfig.Delay = val
        end
    end
})

SoccerTab:Button({
    Title    = "Upgrade All Slots 1x",
    Desc     = "Trigger upgrade untuk semua slot 1 s/d 50 sekaligus",
    Callback = function()
        for i = 1, SoccerConfig.MaxSlots do
            upgradeSingleSlot(i)
        end
        WindUI:Notify({ Title = "Soccer Upgrade", Content = "Semua slot 1-50 berhasil diupgrade 1x!", Duration = 2 })
    end
})

-- ------------------------------------------------------------
-- [TAB 4] PLAYER MENU (NOTIFICATIONS & MOVEMENT)
-- ------------------------------------------------------------
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon  = "user"
})

PlayerTab:Section({ Title = "Game UI & Notifications", TextXAlignment = "Left" })

PlayerTab:Toggle({
    Title    = "Disable Game Notifications",
    Desc     = "Sembunyikan semua popup notifikasi, banner, dan announcement dalam game",
    Value    = PlayerConfig.DisableNotifications,
    Callback = function(state)
        PlayerConfig.DisableNotifications = state
        applyNotificationState()
        WindUI:Notify({
            Title   = "Game Notifications",
            Content = state and "Notifikasi Game Dinonaktifkan" or "Notifikasi Game Diaktifkan",
            Duration = 2
        })
    end
})

PlayerTab:Section({ Title = "Fly System", TextXAlignment = "Left" })

PlayerTab:Toggle({
    Title    = "Aktifkan Fly",
    Desc     = "Gunakan WASD untuk arah, Spacebar (Naik), Left Ctrl (Turun)",
    Value    = PlayerConfig.FlyEnabled,
    Callback = function(state)
        PlayerConfig.FlyEnabled = state
        if state then
            startFly()
            WindUI:Notify({ Title = "Fly System", Content = "Fly Mode: ON", Duration = 2 })
        else
            stopFly()
            WindUI:Notify({ Title = "Fly System", Content = "Fly Mode: OFF", Duration = 2 })
        end
    end
})

local FlySpeedSlider = PlayerTab:Slider({
    Title    = "Fly Speed",
    Desc     = "Kecepatan pergerakan terbang (studs/detik)",
    Value    = PlayerConfig.FlySpeed,
    Min      = 1,
    Max      = 500,
    Step     = 1,
    Callback = function(val)
        PlayerConfig.FlySpeed = val
    end
})

PlayerTab:Section({ Title = "Fly Speed Presets", TextXAlignment = "Left" })

PlayerTab:Button({
    Title    = "Speed 30 (Slow)",
    Callback = function()
        FlySpeedSlider:Set(30)
    end
})

PlayerTab:Button({
    Title    = "Speed 60 (Normal)",
    Callback = function()
        FlySpeedSlider:Set(60)
    end
})

PlayerTab:Button({
    Title    = "Speed 150 (Fast)",
    Callback = function()
        FlySpeedSlider:Set(150)
    end
})

PlayerTab:Button({
    Title    = "Speed 300 (Ultra)",
    Callback = function()
        FlySpeedSlider:Set(300)
    end
})

-- ============================================================
--  NOTIFICATION LOADED
-- ============================================================
WindUI:Notify({
    Title    = "Soccer 380 Hub",
    Content  = "Soccer 380 Script Berhasil Dimuat via Loader!",
    Duration = 4
})
