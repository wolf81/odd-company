--!strict
-- Helpers for putting characters (players and enemies) on a floor.

local Placement = {}

-- Moves `model` so it stands with the bottom of its bounding box exactly on
-- `floorPosition` (plus `lift` studs), facing `lookDirection`.
-- A model's pivot is usually its HumanoidRootPart, which is NOT the middle
-- of the body (R6 and R15 differ, and so do avatar sizes), so we place it,
-- measure where its feet ended up, and correct the height.
function Placement.standOnFloor(model: Model, floorPosition: Vector3, lookDirection: Vector3, lift: number?)
	model:PivotTo(CFrame.lookAt(floorPosition, floorPosition + lookDirection))
	local boxCFrame, boxSize = model:GetBoundingBox()
	local bottomY = boxCFrame.Position.Y - boxSize.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(0, floorPosition.Y - bottomY + (lift or 0), 0))
end

return Placement
