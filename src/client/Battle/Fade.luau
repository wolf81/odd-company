--!strict
-- Full-screen fade to and from black, used when entering/leaving battles.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Modules.Config)

local Fade = {}

local frame: Frame? = nil

local function getFrame(): Frame
	if frame and frame.Parent then
		return frame
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "Fade"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 100 -- above everything else
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Parent = gui
	frame = f
	return f
end

local function tweenTo(transparency: number)
	local f = getFrame()
	local tween = TweenService:Create(f, TweenInfo.new(Config.BattleFadeTime), { BackgroundTransparency = transparency })
	tween:Play()
	tween.Completed:Wait()
end

-- Both functions wait until the fade has finished.
function Fade.toBlack()
	tweenTo(0)
end

function Fade.fromBlack()
	tweenTo(1)
end

return Fade
