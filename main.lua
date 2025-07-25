--=== AUTO FARM WITH UI + LOGGER ===--

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Player refs
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local playerGui = player:WaitForChild("PlayerGui")

--=== Logger ===--
local function debugLog(msg)
    print("[AUTO FARM DEBUG]: " .. msg)
end

local function errorLog(context, err)
    warn("[AUTO FARM ERROR][" .. context .. "]: " .. err)
end

--=== State ===--
local state = {
    locations = { Sand = {}, River = nil },
    autoFarm = false,
    coroutine = nil,
}

--=== UI Element Check ===--
local miniGameBar
local panProgressUI

-- Tunggu UI, kalau tidak ada beri warning
pcall(function()
    miniGameBar = playerGui:WaitForChild("MiniGameBar", 5)
end)
pcall(function()
    panProgressUI = playerGui:WaitForChild("PanProgress", 5)
end)

if not miniGameBar or not panProgressUI then
    warn("MiniGameBar atau PanProgress tidak ditemukan. Pastikan nama sesuai.")
end

--=== Helper Functions ===--

-- Tekan tombol gunakan
local function triggerAction()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(math.random(50, 120) / 1000)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

-- Ambil progress panci (contoh "6/10")
local function getPanProgress()
    local text = panProgressUI and panProgressUI.Text or "0/10"
    local cur, max = text:match("(%d+)/(%d+)")
    return tonumber(cur) or 0, tonumber(max) or 10
end

-- Jalan ke target dengan random offset
local function smartWalkTo(pos)
    if not pos then return end
    local target = pos + Vector3.new(math.random(-2,2),0,math.random(-2,2))
    humanoid:MoveTo(target)
    repeat
        task.wait(0.1)
    until (hrp.Position - target).Magnitude < 4
end

-- Main mini-game timing
local function handleMiniGame()
    if miniGameBar and miniGameBar.Bar.Visible and miniGameBar.Bar.FillColor == Color3.fromRGB(0,255,0) then
        if math.random() < 0.8 then
            task.wait(math.random(70,130)/1000)
        else
            task.wait(math.random(150,250)/1000)
        end
        triggerAction()
    end
end

-- Isi panci hingga penuh
local function fillPan()
    local cur, max = getPanProgress()
    while cur < max do
        triggerAction() -- scoop
        repeat
            handleMiniGame()
            task.wait(0.05)
        until not (miniGameBar and miniGameBar.Bar.Visible)
        cur, max = getPanProgress()
        task.wait(math.random(120,300)/1000)
    end
end

-- Kosongkan panci di sungai
local function emptyPan()
    local cur, max = getPanProgress()
    while cur > 0 do
        triggerAction()
        cur, max = getPanProgress()
        task.wait(math.random(120,250)/1000)
    end
end

-- Farming loop
local function farmLoop()
    while state.autoFarm do
        if #state.locations.Sand > 0 and state.locations.River then
            local sand = state.locations.Sand[math.random(1,#state.locations.Sand)]
            debugLog("Pindah ke lokasi Sand")
            smartWalkTo(sand)
            safeCall(fillPan, "fillPan")

            debugLog("Pindah ke lokasi River")
            smartWalkTo(state.locations.River)
            safeCall(emptyPan, "emptyPan")

            -- Random idle
            if math.random() < 0.3 then
                task.wait(math.random(1,3))
            end
        else
            debugLog("Lokasi belum disimpan. Tunggu...")
            task.wait(1)
        end
    end
end

-- Jalankan coroutine farming
local function toggleFarm()
    state.autoFarm = not state.autoFarm
    if state.autoFarm and not state.coroutine then
        debugLog("AutoFarm dimulai")
        state.coroutine = coroutine.wrap(farmLoop)
        state.coroutine()
    else
        debugLog("AutoFarm berhenti")
        state.coroutine = nil
    end
end

--=== UI ===--
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = playerGui

local function createButton(text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,120,0,30)
    btn.Position = UDim2.new(0,10,0.5,y) -- Tengah kiri
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Parent = screenGui
    btn.MouseButton1Click:Connect(callback)
end

createButton("Save Sand 1", -60, function()
    state.locations.Sand[1] = hrp.Position
    debugLog("Sand 1 tersimpan")
end)
createButton("Save Sand 2", -20, function()
    state.locations.Sand[2] = hrp.Position
    debugLog("Sand 2 tersimpan")
end)
createButton("Save River", 20, function()
    state.locations.River = hrp.Position
    debugLog("River tersimpan")
end)
createButton("Toggle AutoFarm", 60, toggleFarm)

--=== SafeCall Wrapper ===--
function safeCall(func, context)
    local ok, err = pcall(func)
    if not ok then
        errorLog(context or "unknown", err)
    end
end
