function gadget:GetInfo()
	return {
		name = "LLT Commander Crit Text",
		desc = "Small rising Crit+ labels on commander laser impacts",
		author = "BAR contributors",
		layer = 1,
		enabled = true,
	}
end

if gadgetHandler:IsSyncedCode() then return false end

local labels = {}
local font
local TEXT_SIZE = 5
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
	if not font or #labels == 0 then return end
	local _, _, paused = Spring.GetGameSpeed()
	local time = Spring.GetGameFrame() + (paused and 0 or Spring.GetFrameTimeOffset())
	gl.DepthTest(false) -- Keep the small label legible over the impact circles.
	gl.DepthMask(false)
	for _, label in ipairs(labels) do
		local progress = (time - label.born) / label.lifetime
		if progress >= 0 and progress < 1
			and Visible(nil, label.x, label.y, label.z)
			and Spring.IsSphereInView(label.x, label.y, label.z, TEXT_SIZE * 6) then
			-- Rise two text heights before fading, then another two while fading.
			local rise = TEXT_SIZE * 4 * progress
			local alpha = math.min(1, (1 - progress) * 2)
			gl.PushMatrix()
			gl.Translate(label.x, label.y, label.z)
			gl.Billboard()
			gl.Translate(0, TEXT_SIZE + rise, 0)
			font:Begin()
			font:SetTextColor(1, 1, 1, alpha)
			font:SetOutlineColor(0.2, 0.02, 0.12, alpha * 0.85)
			font:Print("Crit+", 0, 0, TEXT_SIZE, "cnO")
			font:End()
			gl.PopMatrix()
		end
	end
	gl.Color(1, 1, 1, 1)
end

function gadget:Initialize()
	font = gl.LoadFont("fonts/" .. Spring.GetConfigString("bar_font2", "Exo2-SemiBold.otf"), 24, 4, 1.3)
	gadgetHandler:AddSyncAction("llt_commander_crit", AddCrit)
end

function gadget:Shutdown()
	gadgetHandler:RemoveSyncAction("llt_commander_crit")
	if font then gl.DeleteFont(font); font = nil end
	labels = {}
end
