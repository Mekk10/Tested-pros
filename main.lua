-- LAYER 1: Setup UI & State
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local state = {
    autoFarm = false,
    locations = { Sand = {}, River = nil },
    farmingThread = nil
}

-- Fungsi buat button UI
local function createButton(parent, text, yOffset, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 28)
    btn.Position = UDim2.new(0, 15, 0.45, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = text
    btn.Parent = parent
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Buat UI
local gui = Instance.new("ScreenGui")
gui.Name = "FarmControlUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

createButton(gui, "Save Sand 1", -50, function()
    state.locations.Sand[1] = player.Character.HumanoidRootPart.Position
end)

createButton(gui, "Save Sand 2", -15, function()
    state.locations.Sand[2] = player.Character.HumanoidRootPart.Position
end)

createButton(gui, "Save River", 20, function()
    state.locations.River = player.Character.HumanoidRootPart.Position
end)

createButton(gui, "Toggle AutoFarm", 55, function()
    state.autoFarm = not state.autoFarm
    if state.autoFarm and not state.farmingThread then
        -- Mulai farming thread
        state.farmingThread = coroutine.wrap(function()
            while state.autoFarm do
                pcall(function()
                    -- LAYER 2: Farming Logic
                    local hrp = player.Character:WaitForChild("HumanoidRootPart")
                    local hum = player.Character:WaitForChild("Humanoid")
                    local vim = game:GetService("VirtualInputManager")

                    -- UI mini-game
                    local miniGameBar = playerGui:WaitForChild("MiniGameBar")
                    local panProgressUI = playerGui:WaitForChild("PanProgress")

                    local function triggerAction()
                        vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.wait(math.random(50, 150) / 1000)
                        vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    end

                    local function getPanProgress()
                        local text = panProgressUI.Text or "0/10"
                        local cur, max = text:match("(%d+)/(%d+)")
                        return tonumber(cur) or 0, tonumber(max) or 10
                    end

                    local function smartWalkTo(pos)
                        if not pos then return end
                        local target = pos + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
                        hum:MoveTo(target)
                        repeat task.wait(0.1) until (hrp.Position - target).Magnitude < 4
                    end

                    local function handleMiniGame()
                        if miniGameBar.Bar.Visible and miniGameBar.Bar.FillColor == Color3.fromRGB(0, 255, 0) then
                            if math.random() < 0.8 then
                                task.wait(math.random(70, 130) / 1000)
                            else
                                task.wait(math.random(150, 250) / 1000)
                            end
                            triggerAction()
                        end
                    end

                    local function fillPan()
                        local cur, max = getPanProgress()
                        while cur < max do
                            triggerAction()
                            repeat
                                handleMiniGame()
                                task.wait(0.05)
                            until not miniGameBar.Bar.Visible
                            cur, max = getPanProgress()
                            task.wait(math.random(120, 300) / 1000)
                        end
                    end

                    local function emptyPan()
                        local cur, max = getPanProgress()
                        while cur > 0 do
                            triggerAction()
                            cur, max = getPanProgress()
                            task.wait(math.random(120, 250) / 1000)
                        end
                    end

                    -- Loop utama farming
                    if #state.locations.Sand > 0 and state.locations.River then
                        local sand = state.locations.Sand[math.random(1, #state.locations.Sand)]
                        smartWalkTo(sand)
                        fillPan()

                        smartWalkTo(state.locations.River)
                        emptyPan()

                        if math.random() < 0.3 then
                            task.wait(math.random(1, 3))
                        end
                    else
                        task.wait(1)
                    end
                end)
            end
            state.farmingThread = nil
        end)
        state.farmingThread()
    end
end)
