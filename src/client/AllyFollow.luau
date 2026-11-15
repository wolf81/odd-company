--!strict
-- Makes a recruited ally walk after a leader: the player, or the ally in
-- front of them in the line. The ally follows the leader's own path (a
-- trail of "breadcrumbs" dropped every stud), so it goes through doorways
-- instead of cutting through walls.
--
-- The ally rig was built by the server; moving it here only changes what
-- this player sees. That's fine while the MVP is single-player.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Modules.Config)

local AllyFollow = {}

local CRUMB_SPACING = 1 -- studs between breadcrumbs

-- Position on the floor plane (Y = 0), so height never matters.
local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function loadWalk(model: Model, animationId: string?): AnimationTrack?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator or not animationId then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not track then
		return nil
	end
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Movement -- on top of the idle
	return track
end

-- Starts `model` following whatever position `leader()` returns (nil =
-- leader not there right now, e.g. while respawning). Returns a function
-- that stops the following.
function AllyFollow.start(model: Model, walkAnimationId: string?, leader: () -> Vector3?): () -> ()
	local walk = loadWalk(model, walkAnimationId)
	local height = model:GetPivot().Position.Y -- floors are flat; keep this height
	local trail: { Vector3 } = {}

	local function placeAt(position: Vector3, facing: Vector3)
		local at = Vector3.new(position.X, height, position.Z)
		if facing.Magnitude > 0.01 then
			model:PivotTo(CFrame.lookAt(at, at + facing))
		else
			model:PivotTo(CFrame.new(at) * model:GetPivot().Rotation)
		end
	end

	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		if not model.Parent then
			connection:Disconnect()
			return
		end
		local leaderPosition = leader()
		if not leaderPosition then
			return
		end
		local target = flat(leaderPosition)
		local here = flat(model:GetPivot().Position)

		-- Drop a breadcrumb each time the leader has moved a stud.
		local last = trail[#trail] or here
		local jump = (target - last).Magnitude
		if jump > Config.AllyTeleportDistance then
			-- Respawned or sent back after a lost battle: pop over.
			table.clear(trail)
			placeAt(target + Vector3.new(0, 0, Config.AllyFollowGap), Vector3.new(0, 0, -1))
			return
		elseif jump >= CRUMB_SPACING then
			table.insert(trail, target)
		end

		-- Walk toward the oldest breadcrumb until we're close enough behind.
		local crumbsToKeep = math.ceil(Config.AllyFollowGap / CRUMB_SPACING)
		local moving = #trail > crumbsToKeep
		if moving then
			-- Walk a bit faster when far behind, so the ally catches up.
			local speed = Config.AllyWalkSpeed * (1 + (#trail - crumbsToKeep) / 10)
			local step = speed * dt
			local toGoal = trail[1] - here
			if toGoal.Magnitude <= step then
				placeAt(trail[1], toGoal)
				table.remove(trail, 1)
			else
				placeAt(here + toGoal.Unit * step, toGoal)
			end
		end

		if walk then
			if moving and not walk.IsPlaying then
				walk:Play(0.1)
			elseif not moving and walk.IsPlaying then
				walk:Stop(0.2)
			end
		end
	end)

	return function()
		connection:Disconnect()
		if walk then
			walk:Stop(0)
		end
	end
end

return AllyFollow
