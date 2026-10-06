function gadget:GetInfo()
	return {
		name = "Team-colored Paradrop Jets",
		desc = "White-hot foot jets fading into the displayed team color",
		author = "BAR contributors",
		layer = 0,
		enabled = true,
	}
end

if gadgetHandler:IsSyncedCode() then return false end

-- Reuse the established plume tuning; only the blue color ramp is replaced.
local jet = VFS.Include("effects/paradrop.lua")["paradrop-blue-jumpjet"]
local layers = {
	{properties = jet.vapor.properties, texture = "bitmaps/atmos/smoke_puff2.tga", particles = {}},
	{properties = jet.glow.properties, texture = "bitmaps/projectiletextures/glow2.tga", particles = {}},
}
local MAX_PARTICLES_PER_LAYER = 4096
local random, sqrt, sin, cos = math.random, math.sqrt, math.sin, math.cos

local function Numbers(text)
	local values = {}
	for value in text:gmatch("[%d%.%-]+") do values[#values + 1] = tonumber(value) end
	return values
end

for _, layer in ipairs(layers) do
	local props = layer.properties
	layer.gravity = Numbers(props.gravity)
	layer.colors = {}
	local colors = Numbers(props.colormap)
	for i = 1, #colors, 4 do
		-- Preserve white highlights and brightness, replace the colored portion.
		local white = math.min(colors[i], colors[i + 1], colors[i + 2])
		local tint = math.max(colors[i], colors[i + 1], colors[i + 2]) - white
		layer.colors[#layer.colors + 1] = {white, tint, colors[i + 3]}
	end
end

local function ViewState()
	local _, fullView = Spring.GetSpectatingState()
	return Spring.GetLocalAllyTeamID(), fullView
end

local function SpawnJet(_, unitID, teamID, x, y, z, dx, dy, dz)
	local allyTeam, fullView = ViewState()
	if not fullView and (not Spring.IsUnitInLos(unitID, allyTeam) or not Spring.IsPosInLos(x, y, z, allyTeam)) then
		return
	end
	local length = sqrt(dx * dx + dy * dy + dz * dz)
	if length < 0.0001 or not teamID then return end
	dx, dy, dz = dx / length, dy / length, dz / length
	-- Construct a stable perpendicular basis, including straight-down jets.
	local rx, ry, rz = -dz, 0, dx
	local rightLength = sqrt(rx * rx + rz * rz)
	if rightLength < 0.0001 then rx, ry, rz = 1, 0, 0 else rx, rz = rx / rightLength, rz / rightLength end
	local fx, fy, fz = dy * rz - dz * ry, dz * rx - dx * rz, dx * ry - dy * rx
	local frame = Spring.GetGameFrame()
	for _, layer in ipairs(layers) do
		local props, particles = layer.properties, layer.particles
		if #particles < MAX_PARTICLES_PER_LAYER then
			local angle = math.rad(props.emitrotspread) * random()
			local azimuth = random() * math.pi * 2
			local along, side, forward = cos(angle), sin(angle) * cos(azimuth), sin(angle) * sin(azimuth)
			local speed = props.particlespeed + random() * props.particlespeedspread
			particles[#particles + 1] = {
				x = x, y = y, z = z,
				vx = (dx * along + rx * side + fx * forward) * speed,
				vy = (dy * along + ry * side + fy * forward) * speed,
				vz = (dz * along + rz * side + fz * forward) * speed,
				size = props.particlesize + random() * props.particlesizespread,
				life = props.particlelife + random() * props.particlelifespread,
				born = frame, updated = frame, team = teamID,
			}
		end
	end
end

function gadget:GameFrame(frame)
	for _, layer in ipairs(layers) do
		local props, gravity, particles = layer.properties, layer.gravity, layer.particles
		for i = #particles, 1, -1 do
			local p = particles[i]
			if frame - p.born >= p.life then
				particles[i] = particles[#particles]
				particles[#particles] = nil
			else
				for _ = p.updated + 1, frame do
					p.vx = p.vx * props.airdrag + gravity[1]
					p.vy = p.vy * props.airdrag + gravity[2]
					p.vz = p.vz * props.airdrag + gravity[3]
					p.x, p.y, p.z = p.x + p.vx, p.y + p.vy, p.z + p.vz
					p.size = p.size * props.sizemod + props.sizegrowth
				end
				p.updated = frame
			end
		end
	end
end

function gadget:DrawWorld()
	if #layers[1].particles + #layers[2].particles == 0 then return end
	local frame = Spring.GetGameFrame()
	local _, _, paused = Spring.GetGameSpeed()
	local fraction = paused and 0 or Spring.GetFrameTimeOffset()
	local allyTeam, fullView = ViewState()
	local teamColors = {}
	gl.DepthTest(true)
	gl.DepthMask(false)
	gl.Blending(GL.ONE, GL.ONE_MINUS_SRC_ALPHA)
	for _, layer in ipairs(layers) do
		gl.Texture(layer.texture)
		for _, p in ipairs(layer.particles) do
			local age = (frame + fraction - p.born) / p.life
			local x, y, z = p.x + p.vx * fraction, p.y + p.vy * fraction, p.z + p.vz * fraction
			if age >= 0 and age < 1 and p.size > 0
				and (fullView or Spring.IsPosInLos(x, y, z, allyTeam))
				and Spring.IsSphereInView(x, y, z, p.size) then
				local color = teamColors[p.team]
				if not color then
					color = {Spring.GetTeamColor(p.team)}
					teamColors[p.team] = color
				end
				local ramp = age * (#layer.colors - 1)
				local index = math.floor(ramp) + 1
				local a, b, blend = layer.colors[index], layer.colors[index + 1], ramp % 1
				local white = a[1] + (b[1] - a[1]) * blend
				local tint = a[2] + (b[2] - a[2]) * blend
				local alpha = a[3] + (b[3] - a[3]) * blend
				gl.Color((white + tint * color[1]) * alpha, (white + tint * color[2]) * alpha, (white + tint * color[3]) * alpha, alpha)
				gl.PushMatrix()
				gl.Translate(x, y, z)
				gl.Billboard()
				gl.TexRect(-p.size, -p.size, p.size, p.size)
				gl.PopMatrix()
			end
		end
	end
	gl.Texture(false)
	gl.Color(1, 1, 1, 1)
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.DepthTest(false)
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction("paradrop_team_jet", SpawnJet)
end

function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction("paradrop_team_jet")
end
