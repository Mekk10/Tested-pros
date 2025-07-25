-- // Service & Player Setup
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- // Ambil remote dari Plastic Pan
local pan = character:WaitForChild("Plastic Pan")
local scripts = pan:WaitForChild("Scripts")
local Toggle = scripts:WaitForChild("ToggleShovelActive")
local Collect = scripts:WaitForChild("Collect")

-- // Variabel AutoFarm
local savedPositions = { Sand = {}, River = nil }
local autoFarm = false
local farmingCoroutine

-- // Fungsi Remote
local function startDig() Toggle:FireServer(true) end
local function stopDig() Toggle:FireServer(false) end

local function collectSand()
    -- Call Collect tanpa argumen
    Collect:InvokeServer()
    -- Jika perlu versi argumen: Collect:InvokeServer(1)
end

-- // Fungsi Movement
local function smartWalkTo(target)
    if not target then return end
    local humanoid = character:WaitForChild("Humanoid")
    humanoid:MoveTo(target)
    repeat task.wait(0.1) until (hrp.Position - target).Magnitude < 4
end

-- // Loop Farming
local function farmLoop()
    while autoFarm do
        if #savedPositions.Sand > 0 and savedPositions.River then
            -- Ambil salah satu posisi pasir random
            local sandPos = savedPositions.Sand[math.random(1,#savedPositions.Sand)]
            smartWalkTo(sandPos)

            startDig()
            for i=1,10 do
                collectSand()
                task.wait(math.random(150,250)/1000)
            end
            stopDig()

            smartWalkTo(savedPositions.River)
            for i=1,10 do
                collectSand()
                task.wait(math.random(120,200)/1000)
            end
        else
            task.wait(1)
        end
    end
end

-- // Toggle Farming
local function toggleAutoFarm()
    autoFarm = not autoFarm
    if autoFarm and not farmingCoroutine then
        farmingCoroutine = coroutine.wrap(farmLoop)
        farmingCoroutine()
    end
end

-- // UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 140, 0, 180)
frame.Position = UDim2.new(0, 20, 0.5, -90) -- kiri tengah
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.Parent = screenGui

local function createButton(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 30)
    btn.Position = UDim2.new(0.5, -60, 0, y)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Parent = frame
    btn.MouseButton1Click:Connect(callback)
end

-- Tombol Save Posisi Pasir 1
createButton("Save Sand 1", 20, function()
    savedPositions.Sand[1] = hrp.Position
    print("Sand 1 saved:", hrp.Position)
end)

-- Tombol Save Posisi Pasir 2
createButton("Save Sand 2", 60, function()
    savedPositions.Sand[2] = hrp.Position
    print("Sand 2 saved:", hrp.Position)
end)

-- Tombol Save Posisi River
createButton("Save River", 100, function()
    savedPositions.River = hrp.Position
    print("River saved:", hrp.Position)
end)

-- Tombol Toggle AutoFarm
createButton("Toggle AutoFarm", 140, toggleAutoFarm)
