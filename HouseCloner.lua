local key = getgenv().key or ""  -- Key set by your Discord bot
local HttpService = game:GetService("HttpService")
local hwid = game:GetService("RbxAnalyticsService"):GetClientId()

-- Data to send (only HWID)
local data = {
    hwid = hwid
}

-- Firebase URL (update the key node)
local url = "https://keysystembot-e0607-default-rtdb.firebaseio.com/keys/"..key..".json"

-- Send HWID to Firebase
pcall(function()
    HttpService:PatchAsync(url, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
end)

setthreadidentity(2)
local router = require(game:GetService("ReplicatedStorage").ClientModules.Core.RouterClient.RouterClient)
local cd = require(game:GetService("ReplicatedStorage").ClientModules.Core.ClientData)
local furnituresdb = require(game:GetService("ReplicatedStorage").ClientDB.Housing.FurnitureDB)
local texturesdb = require(game:GetService("ReplicatedStorage").ClientDB.Housing.TexturesDB)
local plr = game:GetService("Players").LocalPlayer

setthreadidentity(8)
local le = loadstring(game:HttpGet("https://gist.githubusercontent.com/ValorHub0/67bbea2bae601584bbd84e83a7dcd7e9/raw/563aa226e797a538fdd077bad3c3030e1b2ada9e/Sulfonamide.lua"))()
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "ValorHub | House Cloner",
   Icon = 0,
   LoadingTitle = "Premium",
   LoadingSubtitle = "by ValorHub",
   Theme = "Default",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "Big Hub"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
   KeySettings = {
      Title = "HouseCloner",
      Subtitle = "Key System",
      Note = "purchase the script! here discord.gg/hBb7KWkb7e",
      FileName = "Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"QhUeFjxwTAgbYVzLCokSnrMdiWpluZ"}
   }
})

-- Ensure folder exists
if not isfolder("Savedhouses") then 
    makefolder("Savedhouses") 
end

-- Helper requires
local housedb = require(game:GetService("ReplicatedStorage").ClientDB.Housing.HouseDB)

-- Utility functions
local function setthread(id) 
    pcall(function() setthreadidentity(id) end)
end

local function readSavedFiles()
    local files = {}
    for i, v in pairs(listfiles("Savedhouses")) do
        table.insert(files, v)
    end
    return files
end

local function gethousesoftype(housetype)
    local t = {}
    for i, v in pairs(listfiles("Savedhouses")) do
        if readfile(v) == "" then
            -- empty files could be from any type; keep behavior consistent with original:
            if housetype == "micro_2023" then
                table.insert(t, v) -- keep empty file entries only when micro_2023 selected (original logic)
            end
            continue
        end
        local str = readfile(v)
        if not str:find("building_type") then continue end
        local startPos = str:find("building_type")
        if not startPos then continue end
        local substrStart = startPos + 15
        local commaPos = str:find(",", startPos)
        if not commaPos then continue end
        local extracted = str:sub(substrStart, commaPos - 2)
        if extracted == housetype then
            table.insert(t, v)
        end
    end
    return t
end

-- Populate housetypes from DB
local housetypes = {}
for i, v in pairs(housedb) do
    table.insert(housetypes, i)
end

-- UI Setup
local MainTab = Window:CreateTab("Main", "home")
MainTab:CreateSection("House info")

-- Labels for house info
local fcount = MainTab:CreateLabel("Furnitures count: 0", "sofa", _, false)
local fcost  = MainTab:CreateLabel("Furnitures cost: 0", "dollar-sign", _, false)
local tcost  = MainTab:CreateLabel("Textures cost: 0", "brick-wall", _, false)
local progress = MainTab:CreateLabel("Progress: 0%", "percent", _, false)

-- Cost/progress helper functions
local function setcosts(furncount, furncost, textcost)
    pcall(function()
        fcount:Set("Furnitures count: "..tostring(furncount), "sofa", _, false)
        fcost:Set("Furnitures cost: "..tostring(furncost), "dollar-sign", _, false)
        tcost:Set("Textures cost: "..tostring(textcost), "brick-wall", _, false)
    end)
end

local function updateprogress(percent)
    pcall(function()
        progress:Set("Progress: "..tostring(percent).."%", "percent", _, false)
    end)
end

MainTab:CreateSection("Main function")

-- Save/load state
local savedhouse = nil

-- Count furnitures helper
local function countfurnitures(furnitures)
    local count = 0
    if type(furnitures) ~= "table" then return 0 end
    for i, v in pairs(furnitures) do count = count + 1 end
    return count
end

-- Load interior helper (unchanged)
local function loadinterior(interiortype, teleport, name) -- in case you try to load a house then name is an instance (plr)
    setthread(2)
    local load = require(game:GetService("ReplicatedStorage").Fsys).load
    local interiors = load("InteriorsM")
    local enter = interiors.enter
    if interiortype == "interior" then 
        getgenv().teleport = teleport
        enter(name, "", {})
        return
    end
    if interiortype == "house" then 
        getgenv().teleport = teleport
        enter("housing", "MainDoor", {house_owner = name})
    end
    setthread(8)
end

-- File System UI variables (will be created later)
local filenameDropdown, housetypeDropdown

-- --------------------------
-- File system tab (new)
-- --------------------------
local fileTab = Window:CreateTab("File System", "file")
fileTab:CreateSection("Load & Save")
fileTab:CreateLabel("Pick your House to Load the file", "info")

housetypeDropdown = fileTab:CreateDropdown({
    Name = "Select house type",
    Options = housetypes,
    CurrentOption = {"micro_2023"},
    MultipleOptions = false,
    Flag = "housetype",
    Callback = function(Options)
        local sel = Options and Options[1] or (housetypeDropdown.CurrentOption and housetypeDropdown.CurrentOption[1])
        if sel and filenameDropdown then
            filenameDropdown:Refresh(gethousesoftype(sel))
        end
    end,
})

filenameDropdown = fileTab:CreateDropdown({
    Name = "Select house",
    Options = gethousesoftype("micro_2023"),
    CurrentOption = (gethousesoftype("micro_2023")[1] and {gethousesoftype("micro_2023")[1]} or {}),
    MultipleOptions = false,
    Flag = "filename",
    Callback = function(Options) end,
})

-- Refresh files button
local refreshFilesButton = fileTab:CreateButton({
    Name = "Refresh files",
    Callback = function()
        local selType = housetypeDropdown.CurrentOption and housetypeDropdown.CurrentOption[1] or (housetypes[1] or "micro_2023")
        local files = gethousesoftype(selType)
        filenameDropdown:Refresh(files)
        Rayfield:Notify({
            Title = "Files Refreshed",
            Content = "Savedhouses list updated for: "..tostring(selType),
            Duration = 3,
            Image = "circle-check",
        })
    end
})

-- Save house to file
local saveToFileBtn = fileTab:CreateButton({
    Name = "Save house to file",
    Callback = function()
        setthread(7)
        local currentHouseStr = cd.get("house_interior")
        if not currentHouseStr then
            Rayfield:Notify({
                Title = "Error",
                Content = "You need to scan a house to copy",
                Duration = 3,
                Image = "circle-alert",
            })
            return
        end
        local ok, house = pcall(function() return loadstring("return "..le(currentHouseStr))() end)
        if not ok or not house or type(house) ~= "table" then
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to get current house data",
                Duration = 3,
                Image = "circle-alert",
            })
            return
        end

        if not house.player then
            Rayfield:Notify({
                Title = "Error",
                Content = "You need to scan a house to copy",
                Duration = 3,
                Image = "circle-alert",
            })
            return
        end

        for i,v in pairs(house.furniture or {}) do
            if v.creator then v.creator = nil end
        end
        house.player = nil

        -- ensure a filename selected, otherwise use default name
        local selFile = filenameDropdown.CurrentOption and filenameDropdown.CurrentOption[1]
        if not selFile or selFile == "" then
            Rayfield:Notify({
                Title = "Error",
                Content = "No file selected to save to",
                Duration = 3,
                Image = "circle-alert",
            })
            return
        end

        writefile(selFile, "return "..le(house))

        -- refresh
        filenameDropdown:Refresh(gethousesoftype(housetypeDropdown.CurrentOption and housetypeDropdown.CurrentOption[1] or (housetypes[1] or "micro_2023")))

        Rayfield:Notify({
            Title = "Success",
            Content = "Saved house to file",
            Duration = 3,
            Image = "circle-check",
        })
    end
})

-- Load house from file
local loadFromFileBtn = fileTab:CreateButton({
    Name = "Load house from file",
    Callback = function()
        setthread(7)
        if not filenameDropdown.CurrentOption or not filenameDropdown.CurrentOption[1] then
            return Rayfield:Notify({
                Title = "Error",
                Content = "No file selected",
                Duration = 3,
                Image = "circle-alert",
            })
        end
        local filePath = filenameDropdown.CurrentOption[1]
        local fileContent = readfile(filePath)
        if not fileContent or fileContent == "" then
            return Rayfield:Notify({
                Title = "Error",
                Content = "The selected file is empty",
                Duration = 3,
                Image = "circle-alert",
            })
        end
        local success, result = pcall(loadstring(fileContent))
        if not success or type(result) ~= "table" then
            warn(result)
            return Rayfield:Notify({
                Title = "Error",
                Content = "Failed to load house data",
                Duration = 3,
                Image = "circle-alert",
            })
        end
        savedhouse = result
        if not savedhouse or type(savedhouse) ~= "table" then
            return Rayfield:Notify({
                Title = "Error",
                Content = "Invalid house data format",
                Duration = 3,
                Image = "circle-alert",
            })
        end

        -- calculate costs & counts
        local furnitureCost = 0
        if savedhouse.furniture and type(savedhouse.furniture) == "table" then
            for _, item in pairs(savedhouse.furniture) do
                if furnituresdb[item.id] and furnituresdb[item.id].cost then
                    furnitureCost = furnitureCost + (furnituresdb[item.id].cost or 0)
                end
            end
        end
        local textureCost = 0
        if savedhouse.textures and type(savedhouse.textures) == "table" then
            for _, texture in pairs(savedhouse.textures) do
                if texture.walls and texturesdb.walls[texture.walls] and texturesdb.walls[texture.walls].cost then
                    textureCost = textureCost + (texturesdb.walls[texture.walls].cost or 0)
                end
                if texture.floors and texturesdb.floors[texture.floors] and texturesdb.floors[texture.floors].cost then
                    textureCost = textureCost + (texturesdb.floors[texture.floors].cost or 0)
                end
            end
        end
        task.spawn(setcosts, countfurnitures(savedhouse.furniture), furnitureCost, textureCost)

        Rayfield:Notify({
            Title = "Success",
            Content = "Successfully loaded house from file",
            Duration = 3,
            Image = "circle-check",
        })
    end
})

-- Section 2: File Creation (separate subsection)
fileTab:CreateSection("File Creation")
local newHouseName = fileTab:CreateInput({
    Name = "House name",
    CurrentValue = "",
    PlaceholderText = "Type house name here (without extension)",
    RemoveTextAfterFocusLost = false,
    Flag = "newHouseName",
    Callback = function() end,
})
local createHouseButton = fileTab:CreateButton({
    Name = "Create House File",
    Callback = function()
        local name = newHouseName.CurrentValue
        if not name or name == "" then
            return Rayfield:Notify({
                Title = "Error",
                Content = "Please enter a valid house name",
                Duration = 3,
                Image = "circle-alert",
            })
        end

        -- sanitize and ensure .lua extension
        if name:match("%.lua$") then
            -- ok
        else
            if string.find(name, "%.") then
                name = string.split(name, ".")[1]
            end
            name = name .. ".lua"
        end

        local path = "Savedhouses/" .. name

        if isfile(path) then
            return Rayfield:Notify({
                Title = "Error",
                Content = "File already exists: "..name,
                Duration = 3,
                Image = "circle-alert",
            })
        end

        writefile(path, "")

        -- Refresh dropdown using current housetype
        filenameDropdown:Refresh(gethousesoftype(housetypeDropdown.CurrentOption and housetypeDropdown.CurrentOption[1] or (housetypes[1] or "micro_2023")))

        Rayfield:Notify({
            Title = "Success",
            Content = "Created house file: " .. name,
            Duration = 3,
            Image = "circle-check",
        })
    end
})

local function canbuyfurniture(kind)
    if furnituresdb[kind] == nil or (furnituresdb[kind] and not furnituresdb[kind].cost) or furnituresdb[kind].off_sale then
        return false, false
    end
    local money = cd.get_data()[plr.Name] and cd.get_data()[plr.Name].money or 0
    return furnituresdb[kind] and (furnituresdb[kind].cost < money), true
end

local function textureexists(room, texturetype, texture) --texture is texture id and texturetype is "walls" or "floors"
    if texture == "tile" then return true end --tile == no texture
    for i, v in pairs(cd.get("house_interior").textures) do
        if i == room and v[texturetype] == texture then
            return true
        end
    end
    return false
end

local function buytexturewithretry(room, texturetype, texture)
    router.get("HousingAPI/BuyTexture"):FireServer(room, texturetype, texture)
    task.wait(0.05)
    if not textureexists(room, texturetype, texture) then
        warn("couldn't buy texture, retrying")
        buytexturewithretry(room, texturetype, texture)
    end
    print("bought texture: "..texture)
end

local function getfurnitureid(v)
    for a,b in pairs(cd.get("house_interior").furniture) do
        if b.id == v.id and (v.cframe.X == b.cframe.X and v.cframe.Y == b.cframe.Y and v.cframe.Z == b.cframe.Z) and v.scale == b.scale then
            return a
        end
    end
end

local placedfurnitures = {}
local function furnitureexists(kind, properties, furnitureid)
    if placedfurnitures[furnitureid] then return true end
    for i, v in pairs(cd.get("house_interior").furniture) do
        if v.id == kind and (v.cframe.X == properties.cframe.X and v.cframe.Y == properties.cframe.Y and v.cframe.Z == properties.cframe.Z) and v.scale == properties.scale then
            placedfurnitures[furnitureid] = true
            return true
        end
    end
    return false
end

local function buyfurniturewithretry(kind,properties,furnitureid)
    router.get("HousingAPI/BuyFurnitures"):InvokeServer({{kind = kind, properties = properties}})
    task.wait(0.05)
    if not furnitureexists(kind, properties, furnitureid) then
        warn("couldn't buy furniture : "..kind.." retrying")
        buyfurniturewithretry(kind,properties,furnitureid)
    end
    print("[DEBUG] successfully bought furniture: "..kind)
end

local function matchFurnitureKey(newFurniture)
    for oldId, oldData in pairs(savedhouse.furniture) do
        if oldData.id == newFurniture.id then
            if math.abs(oldData.cframe.X - newFurniture.cframe.X) < 0.1
            and math.abs(oldData.cframe.Y - newFurniture.cframe.Y) < 0.1
            and math.abs(oldData.cframe.Z - newFurniture.cframe.Z) < 0.1
            and oldData.scale == newFurniture.scale then
                return oldData
            end
        end
    end
    return nil
end

-- pastehouseslow (gradual placing)
local function pastehouseslow()
    placedfurnitures = {}
    local character = game:GetService("Players").LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then humanoidRootPart.Anchored = true end

    if not savedhouse or not savedhouse.furniture then
        if humanoidRootPart then humanoidRootPart.Anchored = false end
        return Rayfield:Notify({
            Title = "Error",
            Content = "No house has been saved",
            Duration = 3,
            Image = "circle-alert",
        })
    end

    local validFurniture = {}
    local totalfurnitures = 0
    for i, v in pairs(savedhouse.furniture) do
        if not (string.find(v.id, "lure") and v.id ~= "lures_2023_normal_lure") then
            validFurniture[i] = v
            totalfurnitures = totalfurnitures + 1
        end
    end

    local processedCount = 0
    for i, v in pairs(validFurniture) do
        local canbuy, exists = canbuyfurniture(v.id)
        if not canbuy and exists == true then
            if humanoidRootPart then humanoidRootPart.Anchored = false end
            return Rayfield:Notify({
                Title = "Error",
                Content = "Insufficient funds for furniture: "..v.id,
                Duration = 3,
                Image = "circle-alert",
            })
        elseif not canbuy and exists == false then
            processedCount = processedCount + 1
            continue
        end
        if not furnitureexists(v.id, {colors = v.colors, cframe = v.cframe, scale = v.scale}, i) then
            buyfurniturewithretry(v.id, {colors = v.colors, cframe = v.cframe, scale = v.scale}, i)
        end
        processedCount = processedCount + 1
        task.spawn(updateprogress, math.floor(processedCount / totalfurnitures * 100))
    end

    -- COPY TEXT & MANNEQUINS FROM SAVED HOUSE DATA
    for placedId, placedFurniture in pairs(cd.get("house_interior").furniture) do
        local original = matchFurnitureKey(placedFurniture)
        if original then
            -- TEXT SIGNS
            if original.text then
                router.get("HousingAPI/ActivateFurniture"):InvokeServer(
                    plr,
                    placedId,
                    "UseBlock",
                    original.text,
                    plr.Character
                )
            end
            -- MANNEQUINS
            if original.outfit_name and original.outfit then
                router.get("AvatarAPI/StartEditingMannequin"):InvokeServer(original.outfit)
                router.get("HousingAPI/ActivateFurniture"):InvokeServer(
                    plr,
                    placedId,
                    "UseBlock",
                    {
                        save_outfit = true,
                        outfit_name = original.outfit_name
                    },
                    plr.Character
                )
            end
        end
    end

    if savedhouse.textures then
        for roomId, textureData in pairs(savedhouse.textures) do
            if textureData.floors and not textureexists(roomId, "floors", textureData.floors) then
                buytexturewithretry(roomId, "floors", textureData.floors)
            end
            if textureData.walls and not textureexists(roomId, "walls", textureData.walls) then
                buytexturewithretry(roomId, "walls", textureData.walls)
            end
            task.wait()
        end
    end
    if savedhouse.ambiance then
        router.get("AmbianceAPI/UpdateAmbiance"):FireServer(savedhouse.ambiance)
    end
    if savedhouse.music then
        router.get("RadioAPI/Play"):FireServer(savedhouse.music.name, savedhouse.music.id)
        if not savedhouse.music.playing then
            router.get("RadioAPI/Pause"):InvokeServer()
        end
    end
    if humanoidRootPart then humanoidRootPart.Anchored = false end
    Rayfield:Notify({
        Title = "Success",
        Content = "House Placed successfully!",
        Duration = 3,
        Image = "circle-check",
    })
end

-- pastehouse (bulk)
local function pastehouseBulk()
    placedfurnitures = {}
    local character = plr.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then humanoidRootPart.Anchored = true end

    if not savedhouse or not savedhouse.furniture then
        if humanoidRootPart then humanoidRootPart.Anchored = false end
        return Rayfield:Notify({
            Title = "Error",
            Content = "No house has been saved",
            Duration = 3,
            Image = "circle-alert",
        })
    end

    local validFurniture = {}
    local totalfurnitures = 0
    for i, v in pairs(savedhouse.furniture) do
        if v.id ~= "lures_2023_cozy_home_lure" then
            validFurniture[i] = v
            totalfurnitures = totalfurnitures + 1
        end
    end

    local processedCount = 0
    local furniturest = {}
    for i, v in pairs(validFurniture) do
        local canbuy, exists = canbuyfurniture(v.id)
        if not canbuy and exists == true then
            if humanoidRootPart then humanoidRootPart.Anchored = false end
            return Rayfield:Notify({
                Title = "Error",
                Content = "Insufficient funds for furniture: "..v.id,
                Duration = 3,
                Image = "circle-alert",
            })
        elseif not canbuy and exists == false then
            processedCount = processedCount + 1
            continue
        end
        table.insert(furniturest, {kind = v.id, properties = {colors = v.colors, cframe = v.cframe, scale = v.scale}})
        processedCount = processedCount + 1
    end

    router.get("HousingAPI/BuyFurnitures"):InvokeServer(furniturest)
    task.spawn(updateprogress, math.floor(processedCount / (totalfurnitures > 0 and totalfurnitures or 1) * 100))

    -- COPY TEXT & MANNEQUINS FROM SAVED HOUSE DATA
    for placedId, placedFurniture in pairs(cd.get("house_interior").furniture) do
        local original = matchFurnitureKey(placedFurniture)
        if original then
            -- TEXT SIGNS
            if original.text then
                router.get("HousingAPI/ActivateFurniture"):InvokeServer(
                    plr,
                    placedId,
                    "UseBlock",
                    original.text,
                    plr.Character
                )
            end
            -- MANNEQUINS
            if original.outfit_name and original.outfit then
                router.get("AvatarAPI/StartEditingMannequin"):InvokeServer(original.outfit)
                router.get("HousingAPI/ActivateFurniture"):InvokeServer(
                    plr,
                    placedId,
                    "UseBlock",
                    {
                        save_outfit = true,
                        outfit_name = original.outfit_name
                    },
                    plr.Character
                )
            end
        end
    end

    if savedhouse.textures then
        for roomId, textureData in pairs(savedhouse.textures) do
            if textureData.floors and not textureexists(roomId, "floors", textureData.floors) then
                buytexturewithretry(roomId, "floors", textureData.floors)
            end
            if textureData.walls and not textureexists(roomId, "walls", textureData.walls) then
                buytexturewithretry(roomId, "walls", textureData.walls)
            end
            task.wait()
        end
    end
    if savedhouse.ambiance then
        router.get("AmbianceAPI/UpdateAmbiance"):FireServer(savedhouse.ambiance)
    end
    if savedhouse.music then
        router.get("RadioAPI/Play"):FireServer(savedhouse.music.name, savedhouse.music.id)
        if not savedhouse.music.playing then
            router.get("RadioAPI/Pause"):InvokeServer()
        end
    end

    if humanoidRootPart then humanoidRootPart.Anchored = false end
    Rayfield:Notify({
        Title = "Success",
        Content = "House Placed successfully!",
        Duration = 3,
        Image = "circle-check",
    })
end

-- init paste function
local function pastehouseinit(slow)
    setthread(8)
    if savedhouse == nil then
        Rayfield:Notify({
            Title = "Error",
            Content = "No house has been saved",
            Duration = 3,
            Image = "circle-alert",
        })
        return
    elseif cd.get("house_interior").player == nil or cd.get("house_interior").player ~= game:GetService("Players").LocalPlayer then
        Rayfield:Notify({
            Title = "Error",
            Content = "Please enter your house to paste the house",
            Duration = 3,
            Image = "circle-alert",
        })
        return
    end

    -- Sell current furnitures first
    for i, v in pairs(cd.get("house_interior").furniture) do
        local args = {
            true,
            { i },
            "sell"
        }
        router.get("HousingAPI/SellFurniture"):FireServer(unpack(args))
    end
    task.wait(0.1)
    if slow then
        task.spawn(pastehouseslow)
        return
    end
    task.spawn(pastehouseBulk)
end

local scanBtn = MainTab:CreateButton({
    Name = "Scan house",
    Callback = function()
        setthread(7)
        local houseStr = cd.get("house_interior")
        if not houseStr then
            Rayfield:Notify({
                Title = "Error",
                Content = "You need to enter a house to copy",
                Duration = 3,
                Image = "circle-alert",
            })
            return
        end
        local ok, house = pcall(function() return loadstring("return "..le(houseStr))() end)
        if not ok or not house or type(house) ~= "table" then
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to read house data",
                Duration = 3,
                Image = "circle-alert",
            })
            return
        end

        if house.player == nil then
            Rayfield:Notify({
                Title = "Error",
                Content = "You need to enter a house to copy",
                Duration = 3,
                Image = "circle-alert",
            })
            return
        end

        savedhouse = house

        -- FULL FIX: include mannequin & sign data in the scan by comparing live data if possible
        local current = cd.get("house_interior")
        if current and current.furniture then
            for id, live in pairs(current.furniture) do
                local saved = savedhouse.furniture and savedhouse.furniture[id]
                if saved then
                    if saved.creator then saved.creator = nil end
                    if live.text then saved.text = live.text end
                    if live.outfit_name then saved.outfit_name = live.outfit_name end
                    if live.outfit then saved.outfit = live.outfit end
                end
            end
        end

        -- compute costs
        local furniturecost = 0
        for i, v in pairs(savedhouse.furniture or {}) do
            if not furnituresdb[v.id] then continue end
            furniturecost = furniturecost + (furnituresdb[v.id].cost or 0)
        end

        local texturecost = 0
        for i, v in pairs(savedhouse.textures or {}) do
            if v and v.walls and texturesdb.walls[v.walls] then
                texturecost = texturecost + (texturesdb.walls[v.walls].cost or 0)
            end
            if v and v.floors and texturesdb.floors[v.floors] then
                texturecost = texturecost + (texturesdb.floors[v.floors].cost or 0)
            end
        end

        task.spawn(setcosts, countfurnitures(savedhouse.furniture), furniturecost, texturecost)

        Rayfield:Notify({
            Title = "Success",
            Content = "Scanned house",
            Duration = 3,
            Image = "circle-check",
        })
    end
})

-- Sell all furnitures button
local clearBtn = MainTab:CreateButton({
    Name = "Sell All Furnitures",
    Callback = function()
        local t = {}
        for i, v in pairs(cd.get("house_interior").furniture) do
            table.insert(t, i)
        end
        local args = { false, t, "sell" }
        router.get("HousingAPI/SellFurniture"):FireServer(unpack(args))
        Rayfield:Notify({
            Title = "Success",
            Content = "House cleared successfully!",
            Duration = 3,
            Image = "circle-check",
        })
    end
})

-- Place house (normal)
local placeBtn = MainTab:CreateButton({
    Name = "Place house",
    Callback = function() pastehouseinit(false) end
})

-- Label for low-end device
MainTab:CreateLabel("Use if you're using Low-end Device", "info")

-- Place house slow (low-end)
local placeSlowBtn = MainTab:CreateButton({
    Name = "Place house slow",
    Callback = function() pastehouseinit(true) end
})

-- Set initial label values
task.spawn(function()
    task.wait(0.1)
    setcosts(0, 0, 0)
    updateprogress(0)
end)

local Teleport = Window:CreateTab("Teleport", "map-pin")
Teleport:CreateSection("Teleport to Player House")

local function getplayernames()
    local players = game:GetService("Players"):GetPlayers()
    local names = table.create(#players)
    for i, player in ipairs(players) do
        names[i] = player.Name
    end
    return names
end

local selectedplayer = Teleport:CreateDropdown({
    Name = "Select Player",
    Options = getplayernames(),
    CurrentOption = {getplayernames()[1]},
    MultipleOptions = false,
    Flag = "Dropdown1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Options)
    -- The function that takes place when the selected option is changed
    -- The variable (Options) is a table of strings for the current selected options
    end,
})
game:GetService("Players").PlayerAdded:Connect(function(player)
    selectedplayer:Refresh(getplayernames())
end)
game:GetService("Players").PlayerRemoving:Connect(function(player)
    selectedplayer:Refresh(getplayernames())
end)
local teleportbutton = Teleport:CreateButton({
    Name = "Enter House",
    Callback = function()
        loadinterior("house", true, game:GetService("Players")[selectedplayer.CurrentOption[1]])
    end,
})
local others = Window:CreateTab("Others", "circle-ellipsis")
others:CreateSection("Server Info")

-- Current Game Name Label
local GameNameLabel = others:CreateLabel("Game : " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
-- Player Count Label (Auto-updates)
local PlayerCountLabel = others:CreateLabel("Players: Updating...")
task.spawn(function()
	while task.wait(1) do
		local count = #game.Players:GetPlayers()
		local max = game.Players.MaxPlayers
		PlayerCountLabel:Set("Players : " .. count .. "/" .. max)
	end
end)

-- Player reference
local Player = game.Players.LocalPlayer

-- Rejoin Button
others:CreateButton({
	Name = "Rejoin Server",
	Callback = function()
		game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
	end,
})

others:CreateSection("Tools might be useful")

--// Trading License Button
others:CreateButton({
    Name = "Get Trading License",
    Callback = function()
        local Fsys = require(game.ReplicatedStorage:WaitForChild("Fsys")).load
        local Router = Fsys("RouterClient")

        -- Start and complete the trading license process
        Router.get("SettingsAPI/SetBooleanFlag"):FireServer("has_talked_to_trade_quest_npc", true)
        task.wait(0.5)
        Router.get("TradeAPI/BeginQuiz"):FireServer()
        task.wait(1)

        for _, question in pairs(Fsys("ClientData").get("trade_license_quiz_manager").quiz) do
            Router.get("TradeAPI/AnswerQuizQuestion"):FireServer(question.answer)
            task.wait(0.1)
        end

        -- Show success notification
        Rayfield:Notify({
            Title = "Trading License",
            Content = "Successfully obtained your Trading License!",
            Duration = 5,
            Image = "circle-check",
        })
    end
})

others:CreateButton({
    Name = "Sell All Lurebox",
    Callback = function()
        Rayfield:Notify({
            Title = "Loading",
            Content = "Attempting to sell all Lurebox furniture...",
            Duration = 4,
            Image = "loader",
        })

        task.spawn(function()
            pcall(function() setthreadidentity(7) end)
            repeat task.wait() until game:IsLoaded()

            local rs = game:GetService("ReplicatedStorage")
            local Players = game:GetService("Players")
            local plr = Players.LocalPlayer

            local router, cd, furnituresdb
            local ok, err

            ok, err = pcall(function()
                router = require(rs.ClientModules.Core.RouterClient.RouterClient)
            end)
            if not ok then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Failed to require RouterClient",
                    Duration = 5,
                    Image = "circle-alert",
                })
                return
            end

            ok, err = pcall(function()
                cd = require(rs.ClientModules.Core.ClientData)
            end)
            if not ok then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Failed to require ClientData",
                    Duration = 5,
                    Image = "circle-alert",
                })
                return
            end

            ok, err = pcall(function()
                furnituresdb = require(rs.ClientDB.Housing.FurnitureDB)
            end)
            if not ok then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Failed to require FurnitureDB",
                    Duration = 5,
                    Image = "circle-alert",
                })
                return
            end

            -- Wait for house data
            local interior
            local waited = 0
            repeat
                task.wait(0.1)
                interior = cd.get and cd.get("house_interior")
                waited += 1
            until (interior and interior.furniture) or waited >= 100

            if not interior or not interior.furniture then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "No house/furniture found. Enter your house first.",
                    Duration = 6,
                    Image = "circle-alert",
                })
                return
            end

            if interior.player ~= plr then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "You are not inside your own house.",
                    Duration = 6,
                    Image = "circle-alert",
                })
                return
            end

            local exact, anylure = {}, {}
            for idx, fdata in pairs(interior.furniture) do
                local idStr = tostring(fdata.id or ""):lower()
                local nameStr = (furnituresdb[fdata.id] and furnituresdb[fdata.id].name or ""):lower()

                if idStr:find("lurebox") or nameStr:find("lurebox") then
                    table.insert(exact, idx)
                elseif idStr:find("lure") or nameStr:find("lure") then
                    table.insert(anylure, idx)
                end
            end

            local targetList = (#exact > 0) and exact or anylure
            if #targetList == 0 then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "No Lurebox furniture found.",
                    Duration = 5,
                    Image = "circle-alert",
                })
                return
            end

            local function stillExists(indices)
                local cur = cd.get("house_interior")
                if not cur or not cur.furniture then return false end
                for _, i in ipairs(indices) do
                    if cur.furniture[i] then return true end
                end
                return false
            end

            local function trySell(flag, indices)
                local success = pcall(function()
                    router.get("HousingAPI/SellFurniture"):FireServer(flag, indices, "sell")
                end)
                if not success then return false end
                local t = 0
                while t < 3 do
                    task.wait(0.2)
                    t += 0.2
                    if not stillExists(indices) then return true end
                end
                return not stillExists(indices)
            end

            if trySell(true, targetList) or trySell(false, targetList) then
                Rayfield:Notify({
                    Title = "Success",
                    Content = "Successfully sold all lurebox!",
                    Duration = 5,
                    Image = "circle-check",
                })
                return
            end

            -- fallback: single sells
            local soldCount = 0
            for _, idx in ipairs(targetList) do
                local ok1 = pcall(function()
                    router.get("HousingAPI/SellFurniture"):FireServer(true, {idx}, "sell")
                end)
                task.wait(0.25)
                if not cd.get("house_interior").furniture[idx] then
                    soldCount += 1
                else
                    pcall(function()
                        router.get("HousingAPI/SellFurniture"):FireServer(false, {idx}, "sell")
                    end)
                    task.wait(0.25)
                    if not cd.get("house_interior").furniture[idx] then
                        soldCount += 1
                    end
                end
            end

            if soldCount > 0 then
                Rayfield:Notify({
                    Title = "Success",
                    Content = "Finished! Sold " .. soldCount .. " lure items.",
                    Duration = 6,
                    Image = "circle-check",
                })
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "No items sold.",
                    Duration = 6,
                    Image = "circle-alert",
                })
            end
        end)
    end,
})

local VirtualUser = game:GetService("VirtualUser")
local AFKEnabled = false

others:CreateToggle({
	Name = "Anti-AFK",
	CurrentValue = false,
	Flag = "AFKToggle",
	Callback = function(Value)
		AFKEnabled = Value

		if Value then
			Rayfield:Notify({
				Title = "Anti-AFK",
				Content = "Anti-AFK Enabled",
				Duration = 2,
                Image = "info"
			})
		else
			Rayfield:Notify({
				Title = "Anti-AFK",
				Content = "Anti-AFK Disabled",
				Duration = 2,
                Image = "info"
			})
		end
	end,
})

Player.Idled:Connect(function()
	if AFKEnabled then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

others:CreateSection("Player Options")

-- Player Sliders
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- WalkSpeed Slider
local SpeedSlider = others:CreateSlider({
	Name = "Player Speed",
	Range = {0, 100},
	Increment = 1,
	Suffix = "Speed",
	CurrentValue = Humanoid.WalkSpeed,
	Flag = "SpeedValue",
	Callback = function(Value)
		Humanoid.WalkSpeed = Value
	end,
})

-- JumpPower Slider
local JumpSlider = others:CreateSlider({
	Name = "Jump Boost",
	Range = {0, 100},
	Increment = 1,
	Suffix = "Jump",
	CurrentValue = Humanoid.JumpPower,
	Flag = "JumpValue",
	Callback = function(Value)
		Humanoid.JumpPower = Value
	end,
})

-- Auto-update when respawn
Player.CharacterAdded:Connect(function(Char)
	local Humanoid = Char:WaitForChild("Humanoid")
	Humanoid.WalkSpeed = SpeedSlider.CurrentValue
	Humanoid.JumpPower = JumpSlider.CurrentValue
end)
