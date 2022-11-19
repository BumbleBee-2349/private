-- to do; auto mine ores; auto mine collections;

getgenv().Config = {
    SelectedBlocks = {"Weak Sand"},
    SelectedChests = {"Common Chest"},
    SelectedIsland = "Main Island",
    SelectedEgg = "Basic Egg | 100",
    SellAt = 10,
    CanSell = false,
    CanRebirth = false,
    HasChest = false,
}

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local IslandInfo = require(ReplicatedStorage.Modules.IslandInfo)
local PetItems = require(ReplicatedStorage.Modules.PetItems)
local Shorten = loadstring(game:HttpGet("https://raw.githubusercontent.com/uzu01/public/main/util/shorten.lua"))()

local PosTable = {
	["-X"] = Vector3.new(-1, 0, 0),
	["-Y"] = Vector3.new(0, -1, 0),
	["-Z"] = Vector3.new(0, 0, -1),
	["X"] = Vector3.new(1, 0, 0),
	["Y"] = Vector3.new(0, 1, 0),
	["Z"] = Vector3.new(0, 0, 1),
}

local IslandPos = {
    ["Main Island"] = CFrame.new(693.7, 63.5, 630),
    ["Stranded Island"] = CFrame.new(782.5, 119.5, -871.7),
    ["Jungle Island"] = CFrame.new(2254.86, 64, -864),
    ["Frozen Island"] = CFrame.new(700.8, 72.5, 2119.5),
    ["Pirate Island"] = CFrame.new(2189.75, 59.5, 2138.2),
}

local FolderName = "Kai"
local FileName = "THI - " .. Player.UserId .. ".json"

function Save()
    if writefile then
        if not isfolder(FolderName) then
            makefolder(FolderName)
        end
        writefile(FolderName .. "\\" .. FileName, HttpService:JSONEncode(Config))
    end
end

function Load()
    if readfile and isfile(FolderName .. "\\" .. FileName) then
        getgenv().Config = HttpService:JSONDecode(readfile(FolderName .. "\\" .. FileName))
    end
end

function Teleport(Part)
    local Character = Player.Character

    if Character and Character:FindFirstChild("HumanoidRootPart") then
        Character.HumanoidRootPart.CFrame = Part
    end
end

function CanFarm(Block)
    local Sign = workspace.AreaItems[Config.SelectedIsland]:FindFirstChild("Sign")

    if Sign and Sign:FindFirstChild("SignPart") then
        local Time = Sign.SignPart.SurfaceGui.BlockCount.Text:split(":")
        local Min = tonumber(Time[1])
        local Sec = tonumber(Time[2])
        local RaycastParams = RaycastParams.new()
    
        if Min == 0 and Sec < 5 or Config.CanRebirth or Config.CanSell then
            return false
        end

        RaycastParams.FilterDescendantsInstances = {Block:GetChildren(), Player.Character:GetDescendants()}
        RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
        for i3, v3 in pairs(PosTable) do
            local Result = workspace:Raycast(Block.Position, v3 * 4, RaycastParams)
    
            if not Result then
                return true
            end
        end
    end
    return false
end

function GetEggs()
    local tbl1, tbl2 = {}, {}

    for i, v in pairs(PetItems.Eggs) do
        if v.GemsPrice then
            table.insert(tbl1, {Name = i, Price = v.GemsPrice})
        end
    end

    table.sort(tbl1, function(a,b)
        return a.Price < b.Price
    end)

    for i, v in pairs(tbl1) do
        table.insert(tbl2, v.Name .. " | " .. Shorten(v.Price))
    end

    return tbl2
end

function GetData(Data)  
    return require(Player.PlayerScripts.GUIScript.ClientDataManager).Data[Data]
end

function GetChests()
    local tbl = {}

    for i, v in pairs(IslandInfo.ChestSpawnInfo) do
        table.insert(tbl, "- " .. i .. " -")
        table.insert(tbl, "")
        for i2, v2 in pairs(v) do
            table.insert(tbl, i2)
        end 
        table.insert(tbl, "")
    end
    return tbl
end

function GetIslands()
    local tbl = {}

    for i, v in pairs(workspace.BlockTerrain:GetChildren()) do
        table.insert(tbl, v.Name)
    end
    return tbl
end

function GetChest()
    for i, v in pairs(workspace.BlockTerrain[Config.SelectedIsland]:GetChildren()) do
        for i2, v2 in pairs(v:GetChildren()) do
            if table.find(Config.SelectedChests, v2.Name) and CanFarm(v2) then
                return v2
            end
        end
    end
    return false
end

function MineUnder()
    local RaycastParams, AreasUnlocked = RaycastParams.new(), GetData("AreasUnlocked")

    RaycastParams.FilterDescendantsInstances = {Player.Character:GetDescendants()}
    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local Result = workspace:Raycast(Player.Character.HumanoidRootPart.Position, Vector3.new(0,-99,0), RaycastParams)

    for i, v in pairs(AreasUnlocked) do
        if Result and Result.Instance:FindFirstAncestor(v) then
            local Block = Result.Instance

            task.spawn(function()
                ReplicatedStorage.Events.TerrainToolRequest:InvokeServer(v, Block.Position, Block.Position)
            end) 
        end
    end
end

function AutoMineUnder()
    while task.wait() and Config.AutoMineUnder do
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            local Hum = Player.Character.HumanoidRootPart
            local Pos1 = IslandPos[Config.SelectedIsland]
            local Pos2 = CFrame.new(Pos1.X, Hum.CFrame.Y, Pos1.Z)
    
            if Pos2 ~= Hum.CFrame and not Config.CanRebirth and not Config.CanSell then
                Teleport(Pos2)
            end
    
            MineUnder() 
        end
    end
end

function AutoChest()
    while task.wait(.1) and Config.AutoChest do
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            local Chest = GetChest()
            local Hum = Player.Character.HumanoidRootPart

            if not Chest and not Config.CanRebirth and not Config.CanSell then
                local Pos1 = IslandPos[Config.SelectedIsland]
                local Pos2 = CFrame.new(Pos1.X, Hum.CFrame.Y, Pos1.Z)

                if Pos2 ~= Hum.CFrame then
                    Teleport(Pos2)
                end

                MineUnder()
            end     

            if Chest and CanFarm(Chest) then
                Config.HasChest = true
                repeat task.wait()
                    local Pos = Chest.CFrame
                    Teleport(Pos)

                    task.spawn(function()
                        ReplicatedStorage.Events.TerrainToolRequest:InvokeServer(Chest.Parent.Parent.Name, Pos.p, Pos.p)
                    end)
                until not Chest.Parent or not CanFarm(Chest) or not Config.AutoChest
            end

            Config.HasChest = false

            for i, v in pairs(workspace.ParticleHolder.DropHolder:GetChildren()) do
                v.CFrame = Hum.CFrame
            end
        end
    end
end

function AutoSell()
    while task.wait() and Config.AutoSell do
        local Backpack = GetData("BackpackHolding")

        if Backpack >= Config.SellAt then
            local Part = workspace.AreaItems[Config.SelectedIsland].Sell
            local OldPos = Player.Character.HumanoidRootPart.CFrame

            Config.CanSell = true
            task.wait(.3)
            Teleport(Part.CFrame)
            task.wait(.3)
            Teleport(OldPos)
            task.wait(.3)
            Config.CanSell = false
        end
    end
end

function AutoRebirth()
    while task.wait() and Config.AutoRebirth do
        local MyCoins, MyTools = GetData("Coins"), GetData("ToolsOwned")
        local RebirthCost = 500000000

        if MyCoins >= RebirthCost and MyTools["Jackhammer"] then  
            Config.CanRebirth = true
            Teleport(CFrame.new(753, 78, 2065.5))
            task.wait(2)
            ReplicatedStorage.Events.UIAction:FireServer("Rebirth")
            task.wait(2)
            Options.SelectedIsland:SetValue("Main Island")
            Config.CanRebirth = false
        end
    end
end

function AutoBuyTools()
    while task.wait() and Config.AutoBuyTools do
        local Tool, Island, Lowest = nil, nil, math.huge
        local MyTools, MyCoins = GetData("ToolsOwned"), GetData("Coins")

        for i, v in pairs(IslandInfo.UpgradeShopItems) do
            for i2, v2 in pairs(v.Tools) do
                if not MyTools[i2] and MyCoins >= v2.CoinsPrice and v2.CoinsPrice < Lowest then
                    Lowest = v2.CoinsPrice
                    Tool = i2
                    Island = i
                end
            end
        end
    
        if Tool and Island then
            ReplicatedStorage.Events.UIAction:FireServer("PurchaseUpgradeShopItem", "Tools", Tool, Island)    
        end
    end
end

function AutoBuyBackpacks()
    while task.wait() and Config.AutoBuyBackpacks do
        local Backpack, Island, Lowest = nil, nil, math.huge
        local MyBackpacks, MyCoins = GetData("BackpacksOwned"), GetData("Coins")

        for i, v in pairs(IslandInfo.UpgradeShopItems) do
            for i2, v2 in pairs(v.Backpacks) do
                if not MyBackpacks[i2] and v2.CoinsPrice and MyCoins >= v2.CoinsPrice and v2.CoinsPrice < Lowest then
                    Lowest = v2.CoinsPrice
                    Backpack = i2
                    Island = i
                end
            end
        end
    
        if Backpack and Island then
            ReplicatedStorage.Events.UIAction:FireServer("PurchaseUpgradeShopItem", "Backpacks", Backpack, Island)    
        end
    end
end

function AutoBuyIslands()
    while task.wait() and Config.AutoBuyIslands do
        local AreasUnlocked, MyCoins, MyTools = GetData("AreasUnlocked"), GetData("Coins"), GetData("ToolsOwned")

        for i, v in pairs(IslandInfo.OtherInfo) do
            if not table.find(AreasUnlocked,i) and MyCoins >= v.UnlockCost.Coins and MyTools[v.ToolNeededToUnlock] then
                ReplicatedStorage.Events.UIAction:FireServer("UnlockIsland", i)

                Teleport(IslandPos[i])
                Options.SelectedIsland:SetValue(i)
            end
        end
    end
end

function AutoOpenEgg()
    while task.wait() and Config.AutoOpenEgg do
        local Egg = Config.SelectedEgg:split(" |")[1]

        ReplicatedStorage.Events.RequestEggHatch:FireServer(Egg, 3)
    end
end

for i, v in pairs(game.CoreGui:GetChildren()) do
    if v.Name == "ScreenGui" then
        v:Destroy()
    end
end

Load()

local Linoria = loadstring(game:HttpGet("https://raw.githubusercontent.com/uzu01/public/main/ui/linoria"))()
local Window = Linoria:CreateWindow({Title = "Treasure Hunt Islands | Inferior Hub", Center = true, AutoShow = true})

local MainTab = Window:AddTab("Main")

local FarmingBox = MainTab:AddLeftTabbox()
local ShopBox = MainTab:AddLeftTabbox()
local EggBox = MainTab:AddLeftTabbox()
local SettingsBox = MainTab:AddRightTabbox()
local MiscBox = MainTab:AddRightTabbox()

local FarmingTab = FarmingBox:AddTab("Farming")
local ShopTab = ShopBox:AddTab("Shop")
local EggTab = EggBox:AddTab("Egg")
local SettingsTab = SettingsBox:AddTab("Settings")
local MiscTab = MiscBox:AddTab("Misc")

FarmingTab:AddToggle("AutoMineUnder", {Text = "Auto Mine (Under)", Default = Config.AutoMineUnder})
FarmingTab:AddToggle("AutoChest", {Text = "Auto Chest", Default = Config.AutoChest})
FarmingTab:AddToggle("AutoSell", {Text = "Auto Sell", Default = Config.AutoSell})
FarmingTab:AddToggle("AutoRebirth", {Text = "Auto Rebirth", Default = Config.AutoRebirth})
ShopTab:AddToggle("AutoBuyTools", {Text = "Auto Buy Tools", Default = Config.AutoBuyTools})
ShopTab:AddToggle("AutoBuyBackpacks", {Text = "Auto Buy Backpacks", Default = Config.AutoBuyBackpacks})
ShopTab:AddToggle("AutoBuyIslands", {Text = "Auto Buy Islands", Default = Config.AutoBuyIslands})
EggTab:AddToggle("AutoOpenEgg", {Text = "Auto Open Egg", Default = Config.AutoOpenEgg})
SettingsTab:AddDropdown("SelectedIsland", {Values = GetIslands(), Default = Config.SelectedIsland, Multi = false, Text = "Selected Island"})
SettingsTab:AddDropdown("SelectedChests", {Values = GetChests(), Default = Config.SelectedChests, Multi = true, Text = "Selected Chests"})
SettingsTab:AddDropdown("SelectedEgg", {Values = GetEggs(), Default = Config.SelectedEgg, Multi = false, Text = "Selected Egg"})
SettingsTab:AddInput("SellAt", {Default = Config.SellAt, Numeric = true, Finished = true, Text = "Sell At", Placeholder = Config.SellAt})
MiscTab:AddLabel("Keybind"):AddKeyPicker("Keybind", { Default = "LeftControl", NoUI = true, Text = "Keybind"}) 
MiscTab:AddButton("Discord", function() setclipboard(Discord or "No Discord Link Found") end)

Toggles.AutoMineUnder:OnChanged(function()
    Config.AutoMineUnder = Toggles.AutoMineUnder.Value

    Save()
    task.spawn(AutoMineUnder)
end)

Toggles.AutoChest:OnChanged(function()
    Config.AutoChest = Toggles.AutoChest.Value

    Save()
    task.spawn(AutoChest)
end)

Toggles.AutoSell:OnChanged(function()
    Config.AutoSell = Toggles.AutoSell.Value

    Save()
    task.spawn(AutoSell)
end)

Toggles.AutoRebirth:OnChanged(function()
    Config.AutoRebirth = Toggles.AutoRebirth.Value

    Save()
    task.spawn(AutoRebirth)
end)

Toggles.AutoBuyTools:OnChanged(function()
    Config.AutoBuyTools = Toggles.AutoBuyTools.Value

    Save()
    task.spawn(AutoBuyTools)
end)

Toggles.AutoBuyBackpacks:OnChanged(function()
    Config.AutoBuyBackpacks = Toggles.AutoBuyBackpacks.Value

    Save()
    task.spawn(AutoBuyBackpacks)
end)

Toggles.AutoBuyIslands:OnChanged(function()
    Config.AutoBuyIslands = Toggles.AutoBuyIslands.Value

    Save()
    task.spawn(AutoBuyIslands)
end)

Toggles.AutoOpenEgg:OnChanged(function()
    Config.AutoOpenEgg = Toggles.AutoOpenEgg.Value

    Save()
    task.spawn(AutoOpenEgg)
end)

Options.SelectedIsland:OnChanged(function()
    Config.SelectedIsland = Options.SelectedIsland.Value
    
    Save()
    Teleport(IslandPos[Config.SelectedIsland])
end)

Options.SelectedEgg:OnChanged(function()
    Config.SelectedEgg = Options.SelectedEgg.Value

    Save()
end)

Options.SellAt:OnChanged(function()
    Config.SellAt = tonumber(Options.SellAt.Value)

    Save()
end)    

Options.SelectedChests:OnChanged(function()
    Config.SelectedChests = {}

    for i, v in pairs(Options.SelectedChests.Value) do
        table.insert(Config.SelectedChests, i)
    end
    Save()
end)

Options.Keybind:OnClick(function()
    task.spawn(Linoria.Toggle)
end)

for i, v in pairs(CoreGui.RobloxPromptGui.promptOverlay:GetChildren()) do
    if v.Name == "ErrorPrompt" then
        Player:Kick("Rejoining")
        TeleportService:Teleport(game.PlaceId, Player)
    end
end

CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(v)
    if v.Name == "ErrorPrompt" then
        Player:Kick("Rejoining")
        TeleportService:Teleport(game.PlaceId, Player)
    end
end)
