--!strict
-- Locked top-down camera that follows the player's avatar.
-- The camera never rotates, so "up" on the stick/keyboard is always north.
-- Scroll wheel (or pinch on touch screens) zooms in and out.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Modules.Config)

local BIND_NAME = "TopDownCamera"

local TopDownCamera = {}

local targetZoom = 1 -- where the zoom is heading
local currentZoom = 1 -- what's shown now; eases toward targetZoom
local connections: { RBXScriptConnection } = {}

local function setTargetZoom(zoom: number)
	targetZoom = math.clamp(zoom, Config.CameraZoomMin, Config.CameraZoomMax)
end

local function onInputChanged(input: InputObject, gameProcessed: boolean)
	-- Ignore scrolling over UI (e.g. a scrolling list in a menu).
	if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseWheel then
		return
	end
	-- Wheel up (positive Z) zooms in.
	setTargetZoom(targetZoom - input.Position.Z * Config.CameraZoomStep)
end

local pinchStartZoom = 1
local function onTouchPinch(_positions: { Vector2 }, scale: number, _velocity: number, state: Enum.UserInputState, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if state == Enum.UserInputState.Begin then
		pinchStartZoom = targetZoom
	elseif scale > 0 then
		-- Fingers apart (scale > 1) zooms in.
		setTargetZoom(pinchStartZoom / scale)
	end
end

local function update(dt: number)
	local camera = workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not camera or not root then
		return
	end

	-- Roblox's default camera scripts can switch this back on respawn,
	-- so set it every frame.
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = Config.CameraFieldOfView

	-- Ease toward the target zoom so it feels smooth, independent of frame rate.
	local alpha = 1 - math.exp(-Config.CameraZoomSmoothing * dt)
	currentZoom += (targetZoom - currentZoom) * alpha

	local target = root.Position
	camera.CFrame = CFrame.lookAt(target + Config.CameraOffset * currentZoom, target)
end

function TopDownCamera.start()
	RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, update)
	table.insert(connections, UserInputService.InputChanged:Connect(onInputChanged))
	table.insert(connections, UserInputService.TouchPinch:Connect(onTouchPinch))
end

-- Used later by the battle transition (step 3) to take over the camera.
function TopDownCamera.stop()
	RunService:UnbindFromRenderStep(BIND_NAME)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return TopDownCamera
