--!strict
-- Server entry point. The MVP battle runs on the client; the server only
-- handles things that must be shared or trusted (none yet).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)

print(`[{Config.GameName}] server running`)
