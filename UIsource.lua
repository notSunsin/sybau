
--==================================================
-- CUSTOM LUA UI TEMPLATE
-- Requires: Library UI framework sudah dimuat
--==================================================

local CONFIG = {
    Name = "My Dashboard",
    Subtitle = "Custom UI",
    Theme = "Rose",
    Font = "ValleySans",
    ToggleKey = "RightControl",
    ConfigFolder = "MyDashboard",
    ConfigFile = "default",
}

--==================================================
-- LIBRARY SETTINGS
--==================================================

Library:LoadFont({
    Name = CONFIG.Font,
})

Library:SetDefaultTheme(CONFIG.Theme)

--==================================================
-- MAIN WINDOW
--==================================================

local Window = Library:CreateWindow({
    Name = CONFIG.Name,
    LoadingSubtitle = CONFIG.Subtitle,
    ToggleUIKeybind = CONFIG.ToggleKey,

    ConfigurationSaving = {
        Enabled = true,
        FolderName = CONFIG.ConfigFolder,
        FileName = CONFIG.ConfigFile,
    },

    ToggleButton = {
        Platform = "Mobile",
    },

    Home = {
        Title = "Welcome to " .. CONFIG.Name,
        Tier = CONFIG.Subtitle,
        Stats = {
            "Players",
            "Session",
            "FPS",
            "Ping",
        },
    },
})

--==================================================
-- TAB NAVIGATION
--==================================================

local HomeTab = Window:CreateTab({
    Name = "Home",
    Icon = "house",
})

local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "layout-dashboard",
})

local VisualTab = Window:CreateTab({
    Name = "Visual",
    Icon = "palette",
})

local SettingsTab = Window:CreateTab({
    Name = "Settings",
    Icon = "settings",
})

--==================================================
-- HOME TAB
--==================================================

local Welcome = HomeTab:AddLeftGroupbox({
    Name = "Welcome",
    Icon = "house",
})

Welcome:CreateButton({
    Name = "Example Button",
    Icon = "mouse-pointer",

    Callback = function()
        print("Example Button clicked")
    end,
})

--==================================================
-- MAIN TAB
--==================================================

local General = MainTab:AddLeftGroupbox({
    Name = "General",
    Icon = "sliders-horizontal",
})

General:CreateToggle({
    Name = "Example Toggle",
    CurrentValue = false,
    Flag = "ExampleToggle",

    Callback = function(value)
        print("Example Toggle:", value)
    end,
})

General:CreateSlider({
    Name = "Example Slider",
    Range = { 1, 100 },
    Increment = 1,
    CurrentValue = 50,
    Flag = "ExampleSlider",

    Callback = function(value)
        print("Example Slider:", value)
    end,
})

local Actions = MainTab:AddRightGroupbox({
    Name = "Actions",
    Icon = "zap",
})

Actions:CreateButton({
    Name = "Run Action",
    Icon = "play",

    Callback = function()
        print("Run Action clicked")
    end,
})

--==================================================
-- VISUAL TAB
--==================================================

local Appearance = VisualTab:AddLeftGroupbox({
    Name = "Appearance",
    Icon = "palette",
})

Appearance:CreateDropdown({
    Name = "Example Dropdown",

    Options = {
        "Option 1",
        "Option 2",
        "Option 3",
    },

    CurrentOption = "Option 1",
    Flag = "ExampleDropdown",

    Callback = function(value)
        print("Selected option:", value)
    end,
})

--==================================================
-- SETTINGS TAB
--==================================================

local Interface = SettingsTab:AddLeftGroupbox({
    Name = "Interface",
    Icon = "monitor",
})

Interface:CreateDropdown({
    Name = "Toggle Button",

    Options = {
        "Mobile only",
        "Mobile & PC",
    },

    CurrentOption = "Mobile only",
    AllowNone = false,
    Flag = "ToggleButtonPlatform",

    Callback = function(value)
        print("Toggle button platform:", value)
    end,
})

Interface:CreateButton({
    Name = "Unload UI",
    Icon = "power",

    Callback = function()
        if Library and type(Library.Destroy) == "function" then
            Library:Destroy()
        else
            warn("Library tidak menyediakan method Destroy()")
        end
    end,
})

print(CONFIG.Name .. " UI loaded")
