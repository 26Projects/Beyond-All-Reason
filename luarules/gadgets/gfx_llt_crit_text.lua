function gadget:GetInfo()
	return {
		name = "LLT Commander Crit Icon",
		desc = "Small rising shield-break icons on commander laser impacts",
		author = "BAR contributors",
		layer = 1,
		enabled = true,
	}
end

if gadgetHandler:IsSyncedCode() then return false end

local labels = {}
local ICON_TEXTURE = "luarules/images/llt_commander_crit.png"
local ICON_SIZE = 10
local MAX_LABELS = 512

local function Visible(unitID, x, y, z)
	local _, fullView = Spring.GetSpectatingState()
	if fullView then return true end
	local allyTeam = Spring.GetLocalAllyTeamID()
	return (not unitID or Spring.IsUnitInLos(unitID, allyTeam))
		and Spring.IsPosInLos(x, y, z, allyTeam)
end

local function AddCrit(_, unitID, x, y, z, frame, lifetime)
	if #labels >= MAX_LABELS or not Visible(unitID, x, y, z) then return end
	labels[#labels + 1] = {x = x, y = y, z = z, born = frame, lifetime = lifetime}
end

function gadget:GameFrame(frame)
	for i = #labels, 1, -1 do
		if frame - labels[i].born >= labels[i].lifetime then
			labels[i] = labels[#labels]
			labels[#labels] = nil
		end
	end
end

function gadget:DrawWorld()
	if #labels == 0 then return end
	local _, _, paused = Spring.GetGameSpeed()
	local time = Spring.GetGameFrame() + (paused and 0 or Spring.GetFrameTimeOffset())
	gl.DepthTest(false) -- Keep the icon legible over the impact circles.
	gl.DepthMask(false)
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.Texture(ICON_TEXTURE)
	for _, label in ipairs(labels) do
		local progress = (time - label.born) / label.lifetime
		if progress >= 0 and progress < 1
			and Visible(nil, label.x, label.y, label.z)
			and Spring.IsSphereInView(label.x, label.y, label.z, ICON_SIZE * 6) then
			-- Rise two icon heights before fading, then another two while fading.
			local rise = ICON_SIZE * 4 * progress
			local alpha = math.min(1, (1 - progress) * 2)
			gl.PushMatrix()
			gl.Translate(label.x, label.y, label.z)
			gl.Billboard()
			gl.Translate(0, ICON_SIZE + rise, 0)
			gl.Color(1, 1, 1, alpha)
			local halfSize = ICON_SIZE * 0.5
			gl.TexRect(-halfSize, -halfSize, halfSize, halfSize)
			gl.PopMatrix()
		end
	end
	gl.Texture(false)
	gl.Color(1, 1, 1, 1)
	gl.DepthMask(true)
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction("llt_commander_crit", AddCrit)
end

function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction("llt_commander_crit")
	gl.DeleteTexture(ICON_TEXTURE)
	labels = {}
end
