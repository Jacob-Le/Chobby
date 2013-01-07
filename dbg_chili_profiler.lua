--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "ChiliProfiler",
    desc      = "",
    author    = "",
    date      = "2013",
    license   = "GPLv2",
    layer     = 2,
    enabled   = false  --  loaded by default?
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local window0
local tree0
local label0
local Chili
local profiling = false

local profile_tree = {}
local samples = 0
local samples2 = 0

local min_usage = 0.03

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local n = 0
local function trace(event, line)
	n = n + 1
	if (n < 50) then
		return
	end
	n = 0

	samples = samples + 1

	if (samples % 10 == 0) then
		label0:SetCaption("Samples: " .. samples)
	end
	
	local j = 2
	local i = 666
	local top = true

	while (i) do
		repeat 
			i = debug.getinfo(j)
			j = j + 1
			if (not i) then return end
		until not(i.source:find("\n") or i.source:find("(tail call)") or (not i.name) or i.what == "C" or i.what == "main")
		local s = i.source or "???"
		local n = i.name or "???"
		--local l = i.linedefined or "???"

		profile_tree[s] = profile_tree[s] or {}
		profile_tree[s][n] = profile_tree[s][n] or {0,0}
		profile_tree[s][n][1] = profile_tree[s][n][1] + 1
		if top then
			profile_tree[s][n][2] = profile_tree[s][n][2] + 1
			top = false
		end

		samples2 = samples2 + 1
	end
end

local function rendertree()
	tree0.root:ClearChildren()
	for s,t in pairs(profile_tree) do
		local node_file
		for f,c in pairs(t) do
			if (c[1]/samples2 > min_usage)or(c[2]/samples > min_usage) then
				local cap = ("%.1f%% (%.1f%%): %s"):format(100 * (c[1]/samples2), 100 * (c[2]/samples), f)
				if not(node_file) then node_file = tree0.root:Add(s) end
				local nf = node_file:Add(cap)
			end
		end
	end
end

local function AddProfiler()
	if profiling then return end
	profiling = true
	debug.sethook(trace, "l", 16000000)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	Chili = WG.Chili

	if (not Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	window0 = Chili.Window:New{
		name = "wnd_profiler",
		caption = "Profiler";
		x = 200,
		y = 450,
		width  = 400,
		height = 400,
		parent = Chili.Screen0,
		layer = 1,

		children = {
			Chili.Label:New{
				name = "lbl_profiler_samples",
				x=0, right=0,
				y=0, bottom=-20,
				align = "right", valign = "bottom",
				caption = "Samples: 0",
			},
			Chili.ScrollPanel:New{
				x=0, right=0,
				y=20, bottom=20,
				children = {
					Chili.TreeView:New{
						name = "tree_profiler",
						x=0, right=0,
						y=0, bottom=0,
						defaultExpanded = true,
					},
				},
			},
			Chili.Button:New{
				x=0, right="50%",
				y=-20, bottom=0,
				caption="start",
				OnMouseUp = {AddProfiler},
			},
			Chili.Button:New{
				x="50%", right=0,
				y=-20, bottom=0,
				caption = "stop",
				OnMouseUp = {function() debug.sethook( nil ); profiling = false; rendertree() end},
			},
		},
	}

	tree0  = window0:GetObjectByName("tree_profiler")
	label0 = window0:GetObjectByName("lbl_profiler_samples")
end

function widget:Shutdown()
	debug.sethook( nil )
	window0:Dispose()
end
