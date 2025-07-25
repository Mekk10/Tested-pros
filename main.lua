-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- UI asli game
local playerGui = player:WaitForChild("PlayerGui")
local miniGameBar = playerGui:WaitForChild("MiniGameBar")
local panProgressUI = playerGui:WaitForChild("PanProgress")

-- Data
local locations = { Sand = {}, River = nil }
local autoFarm = false
local farmingThread

-- Input handler
local function triggerAction()
    local vim = game:GetService("VirtualInputManager")
    if vim then
        vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(math.random(50,150)/1000)
        vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    elseif getgenv().keypress then
        -- fallback executor function
        getgenv().keypress(Enum.KeyCode.E)
    end
end

-- Ambil progress panci (contoh format "6/10")
local function getPanProgress()
    local text = panProgressUI.Text or "0/10"
    local cur,max = text:match("(%d+)/(%d+)")
    return tonumber(cur) or 0, tonumber(max) or 10
end

-- Jalan ke target + random offset + anti stuck
local function smartWalkTo(pos)
    if not pos then return end
    local target = pos + Vector3.new(math.random(-2,2),0,math.random(-2,2))
    humanoid:MoveTo(target)
    local startTime = tick()

    while (hrp.Position - target).Magnitude > 4 do
        RunService.Heartbeat:Wait()
        if tick() - startTime > 5 then
            humanoid.Jump = true
            humanoid:MoveTo(target + Vector3.new(math.random(-3,3),0,math.random(-3,3)))
            startTime = tick()
        end
    end
end

-- Mini game timing
local function handleMiniGame()
    if miniGameBar.Bar.Visible and miniGameBar.Bar.FillColor == Color3.fromRGB(0,255,0) then
        if math.random() < 0.8 then
            task.wait(math.random(70,130)/1000) -- perfect
        else
            task.wait(math.random(150,250)/1000) -- miss
        end
        triggerAction()
    end
end

-- Isi panci sampai penuh
local function fillPan()
    local cur,max = getPanProgress()
    while cur < max do
        triggerAction()
        repeat
            handleMiniGame()
            task.wait(0.05)
        until not miniGameBar.Bar.Visible
        cur,max = getPanProgress()
        task.wait(math.random(120,300)/1000)
    end
end

-- Kosongkan panci di sungai
local function emptyPan()
    local cur,max = getPanProgress()
    while cur > 0 do
        triggerAction()
        cur,max = getPanProgress()
        task.wait(math.random(120,250)/1000)
    end
end

-- Respawn handling
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    hrp = newChar:WaitForChild("HumanoidRootPart")
end)

-- Farming loop
local function farmLoop()
    while autoFarm do
        if #locations.Sand > 0 and locations.River then
            local sand = locations.Sand[math.random(1,#locations.Sand)]
            smartWalkTo(sand)
            fillPan()

            smartWalkTo(locations.River)
            emptyPan()

            if math.random() < 0.3 then
                task.wait(math.random(1,3))
            end
        else
            task.wait(1)
        end
    end
end

local function toggleFarm()
    autoFarm = not autoFarm
    if autoFarm and not farmingThread then
        farmingThread = spawn(farmLoop)
    elseif not autoFarm then
        farmingThread = nil
    end
end

-- ================= UI =================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmUI_"..math.random(1000,9999)
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

-- Posisi kiri tengah
local screenHeight = workspace.CurrentCamera.ViewportSize.Y
local centerY = (screenHeight/2) - 80

local function createButton(text, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(120, 28)
    btn.Position = UDim2.fromOffset(20, centerY + (order * 35))
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = gui
    btn.MouseButton1Click:Connect(callback)
    return btn
end

createButton("Save Sand 1", 0, function() locations.Sand[1] = hrp.Position end)
createButton("Save Sand 2", 1, function() locations.Sand[2] = hrp.Position end)
createButton("Save River", 2, function() locations.River = hrp.Position end)
createButton("Toggle AutoFarm", 3, toggleFarm)
