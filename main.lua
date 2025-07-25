-- Layanan
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- Pastikan PlayerGui siap
local playerGui = player:WaitForChild("PlayerGui")

-- Variabel state
local state = {
    autoFarm = false,
    locations = { Sand = {}, River = nil },
    farmingThread = nil
}

-- Ambil UI asli untuk baca progress
local miniGameBar = playerGui:WaitForChild("MiniGameBar")
local panProgressUI = playerGui:WaitForChild("PanProgress")

-- Fungsi klik tombol (gunakan VirtualInputManager)
local function triggerAction()
    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(math.random(50,150)/1000)
    vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

-- Ambil progress panci
local function getPanProgress()
    local text = panProgressUI.Text or "0/10"
    local cur,max = text:match("(%d+)/(%d+)")
    return tonumber(cur) or 0, tonumber(max) or 10
end

-- Jalan ke titik
local function smartWalkTo(pos)
    if not pos then return end
    local target = pos + Vector3.new(math.random(-2,2),0,math.random(-2,2))
    humanoid:MoveTo(target)
    repeat RunService.Heartbeat:Wait() until (hrp.Position - target).Magnitude < 4
end

-- Main mini-game
local function handleMiniGame()
    if miniGameBar.Bar.Visible and miniGameBar.Bar.FillColor == Color3.fromRGB(0,255,0) then
        task.wait(math.random(80,150)/1000)
        triggerAction()
    end
end

-- Isi panci
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

-- Kosongkan panci
local function emptyPan()
    local cur,max = getPanProgress()
    while cur > 0 do
        triggerAction()
        cur,max = getPanProgress()
        task.wait(math.random(120,250)/1000)
    end
end

-- Loop farming
local function farmLoop()
    while state.autoFarm do
        if #state.locations.Sand > 0 and state.locations.River then
            local sand = state.locations.Sand[math.random(1,#state.locations.Sand)]
            smartWalkTo(sand)
            fillPan()

            smartWalkTo(state.locations.River)
            emptyPan()

            if math.random() < 0.3 then
                task.wait(math.random(1,3))
            end
        else
            task.wait(1)
        end
    end
end

-- Toggle farming
local function toggleFarm()
    state.autoFarm = not state.autoFarm
    if state.autoFarm and not state.farmingThread then
        state.farmingThread = coroutine.wrap(farmLoop)
        state.farmingThread()
    end
end

-- Buat UI
local function createUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "FarmControlUI"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local function createButton(text, yPos, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 120, 0, 30)
        btn.Position = UDim2.new(0, 15, 0.4, yPos) -- kiri-tengah
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Text = text
        btn.Parent = gui
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    createButton("Save Sand 1", -40, function() state.locations.Sand[1] = hrp.Position end)
    createButton("Save Sand 2", 0, function() state.locations.Sand[2] = hrp.Position end)
    createButton("Save River", 40, function() state.locations.River = hrp.Position end)
    createButton("Toggle AutoFarm", 80, toggleFarm)
end

createUI()
