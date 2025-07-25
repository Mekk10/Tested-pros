local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- Pastikan UI muncul di PlayerGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FarmUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Buat Frame UI
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 140, 0, 180)
frame.Position = UDim2.new(0, 20, 0.5, -90) -- kiri-tengah
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.Parent = screenGui

-- Fungsi buat tombol
local function createButton(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 30)
    btn.Position = UDim2.new(0.5, -60, 0, y)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Parent = frame
    btn.MouseButton1Click:Connect(callback)
end

-- Logic AutoFarm
local savedPositions = { Sand = {}, River = nil }
local autoFarm = false

local function smartWalkTo(pos)
    if not pos then return end
    local humanoid = character:WaitForChild("Humanoid")
    humanoid:MoveTo(pos)
    repeat task.wait(0.1) until (hrp.Position - pos).Magnitude < 4
end

-- Ambil remote
local pan = character:WaitForChild("Plastic Pan")
local scripts = pan:WaitForChild("Scripts")
local Toggle = scripts:WaitForChild("ToggleShovelActive")
local Collect = scripts:WaitForChild("Collect")

local function startDig() Toggle:FireServer(true) end
local function stopDig() Toggle:FireServer(false) end
local function collectSand() Collect:InvokeServer() end

-- Farming loop
local function farmLoop()
    while autoFarm do
        if #savedPositions.Sand > 0 and savedPositions.River then
            local sandPos = savedPositions.Sand[math.random(1,#savedPositions.Sand)]
            smartWalkTo(sandPos)
            startDig()
            for i = 1, 10 do
                collectSand()
                task.wait(math.random(150, 250)/1000)
            end
            stopDig()

            smartWalkTo(savedPositions.River)
            for i = 1, 10 do
                collectSand()
                task.wait(math.random(120, 200)/1000)
            end
        else
            task.wait(1)
        end
    end
end

local function toggleAutoFarm()
    autoFarm = not autoFarm
    if autoFarm then
        coroutine.wrap(farmLoop)()
    end
end

-- Tombol UI
createButton("Save Sand 1", 20, function() savedPositions.Sand[1] = hrp.Position end)
createButton("Save Sand 2", 60, function() savedPositions.Sand[2] = hrp.Position end)
createButton("Save River", 100, function() savedPositions.River = hrp.Position end)
createButton("Toggle AutoFarm", 140, toggleAutoFarm)

-- Pastikan UI tetap muncul setelah respawn
player.CharacterAdded:Connect(function()
    task.wait(1)
    if not screenGui.Parent then
        screenGui.Parent = player:WaitForChild("PlayerGui")
    end
end)
