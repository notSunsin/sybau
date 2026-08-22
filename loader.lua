
if not game:IsLoaded() then
    game.Loaded:Wait()
end

if identifyexecutor then
    local execName = tostring(identifyexecutor()):lower()
    if execName:find("solara") or execName:find("xeno") then
        game:GetService("Players").LocalPlayer:Kick(
            "EXECUTOR NOT SUPPORTED\n[Script ini membutuhkan executor dengan level environment yang lebih tinggi]"
        )
        return
    end
end

-- 3. Base URL GitHub Anda (Ubah ke repository GitHub Anda sendiri)
local GITHUB_BASE = "https://raw.githubusercontent.com/notSunsin/sybau/main/games/"


local PLACE_GAMES = {
    [133294838637122]  = "soccer-380.lua",      
    [125927821145949]  = "mine-a-mountain.lua",  
    
    [825735094]  = "auto-steal-egg.lua",
    
}

local UNIVERSE_GAMES = {
}

local CREATOR_GAMES = {
}

local currentPlaceId   = game.PlaceId
local currentGameId    = game.GameId
local currentCreatorId = game.CreatorId

print(("[Game Hub] Place ID: %s | Game ID: %s | Creator ID: %s"):format(
    tostring(currentPlaceId),
    tostring(currentGameId),
    tostring(currentCreatorId)
))

local targetScript = PLACE_GAMES[currentPlaceId] 
                  or UNIVERSE_GAMES[currentGameId] 
                  or CREATOR_GAMES[currentCreatorId]

if targetScript then
    task.wait(0.5) 
    
    if type(targetScript) == "string" then
        local finalUrl = ""
        
        if targetScript:match("^https?://") then
            finalUrl = targetScript
        else
            finalUrl = GITHUB_BASE .. targetScript
        end
        
        print("[Game Hub] Memuat script dari: " .. finalUrl)
        
        local success, err = pcall(function()
            loadstring(game:HttpGet(finalUrl))()
        end)
        
        if not success then
            warn("[Game Hub ERROR] Gagal menjalankan script: " .. tostring(err))
        end
        
    elseif type(targetScript) == "function" then
        targetScript()
    end
else
    warn(("[Game Hub] Game ini tidak terdaftar! (Place ID: %s)"):format(tostring(currentPlaceId)))
    
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = "Game Tidak Terdaftar",
            Text     = "PlaceId: " .. tostring(currentPlaceId) .. " belum ada di daftar loader.",
            Duration = 6
        })
    end)
end
