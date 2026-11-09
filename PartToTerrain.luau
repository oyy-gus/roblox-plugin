--!strict
-- ==============================================================================
-- Part & Union to Terrain & MeshPart Converter Plugin for Roblox Studio
-- Tema Hitam Putih (Monochrome Edition)
-- Mendukung: Part to Terrain, Part to MeshPart (Terpisah & Gabung), Union to MeshPart
-- ==============================================================================

local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local CollectionService = game:GetService("CollectionService")
local Terrain = workspace.Terrain

if not plugin then
	warn("[Part Converter] Script ini dirancang untuk dijalankan sebagai Roblox Studio Plugin.")
	warn("[Part Converter] Cara pakai: Klik kanan script ini di Explorer -> 'Save as Local Plugin...'.")
	return
end

-- ==============================================================================
-- 1. Toolbar & DockWidget Plugin GUI
-- ==============================================================================
local toolbar = plugin:CreateToolbar("Part & Script Studio")
local toggleButton = toolbar:CreateButton(
	"PartStudioTools",
	"Buka Panel Part/Mesh Converter & Script Obfuscator",
	"rbxassetid://6031280882"
)
toggleButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false, -- initially enabled
	false, -- override previous state
	380,   -- default width
	580,   -- default height
	320,   -- min width
	460    -- min height
)

local widget = plugin:CreateDockWidgetPluginGui("PartConverterWidget_v5", widgetInfo)
widget.Title = "Part, Mesh, CSG & Script Studio"
widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ==============================================================================
-- 2. State & Options
-- ==============================================================================
local activeTab = "Terrain" -- "Terrain" | "MeshPart" | "CSG" | "Obfuscator"

local csgOptions = {
	autoSelect = true,        -- Otomatis memilih hasil Union/Negate di Explorer & Viewport
	includeChildren = true,   -- Cari di dalam Model & Folder
	preserveName = true,      -- Beri nama rapi pada Union hasil gabungan
	collisionFidelity = Enum.CollisionFidelity.Default,
	collisionFidelityName = "Default",
	renderFidelity = Enum.RenderFidelity.Automatic,
	renderFidelityName = "Automatic",
}

local obfOptions = {
	preset = "Extreme",       -- "Extreme" (Ekstrem) | "Standard" (Standar) | "Minify" (Minify Saja)
	encryptStrings = true,    -- XOR Multibyte Dynamic Metatable
	mangleVars = true,        -- Barcode Identifiers (_Il11II...)
	mutateNumbers = true,     -- Hexadecimal Arithmetic Mutations
	opaquePredicates = true,  -- Opaque Junk Logic / Tamper Resistance
	minify = true,            -- Strip Comments & Whitespace Compression
	autoBackup = true,        -- Clone original script to Name_Backup
	includeChildren = true,   -- Search inside Models / Folders
}

local terrainOptions = {
	material = "Auto",
	materialName = "Auto (Gunakan Material Part)",
	deleteParts = true,
	includeChildren = true,
	detectShapes = true,
}

local meshOptions = {
	combineMode = "Separate", -- "Separate" (Terpisah) | "Combine" (Gabung jadi 1)
	mode = "Auto",            -- "Auto" | "Custom"
	convertUnions = true,     -- Deconstruct & convert UnionOperations
	customMeshId = "",
	customTextureId = "",
	collisionFidelity = Enum.CollisionFidelity.Default,
	collisionFidelityName = "Default",
	renderFidelity = Enum.RenderFidelity.Automatic,
	renderFidelityName = "Automatic",
	deleteParts = true,
	includeChildren = true,
	transferChildren = true,
	-- Bevel / Sudut Tumpul
	bevelEnabled = false,     -- Terapkan sudut tumpul saat konversi mesh biasa
	bevelRadius = 0.4,        -- Radius kelengkungan sudut (studs)
	bevelSegments = 2,        -- 1 = Chamfer (45°), 2 = Halus, 3 = Sangat Halus
}

local MATERIALS = {
	{ name = "Auto (Gunakan Material Part)", value = "Auto" },
	{ name = "Grass (Rumput)", value = Enum.Material.Grass },
	{ name = "Rock (Batu)", value = Enum.Material.Rock },
	{ name = "Sand (Pasir)", value = Enum.Material.Sand },
	{ name = "Water (Air)", value = Enum.Material.Water },
	{ name = "Mud (Lumpur)", value = Enum.Material.Mud },
	{ name = "Ground (Tanah)", value = Enum.Material.Ground },
	{ name = "Leafy Grass (Rumput Berdaun)", value = Enum.Material.LeafyGrass },
	{ name = "Snow (Salju)", value = Enum.Material.Snow },
	{ name = "Ice (Es)", value = Enum.Material.Ice },
	{ name = "Concrete (Beton)", value = Enum.Material.Concrete },
	{ name = "Brick (Bata)", value = Enum.Material.Brick },
	{ name = "Wood Planks (Papan Kayu)", value = Enum.Material.WoodPlanks },
	{ name = "Cobblestone (Batu Kerikil)", value = Enum.Material.Cobblestone },
	{ name = "Slate (Batu Tulis)", value = Enum.Material.Slate },
	{ name = "Basalt (Basal)", value = Enum.Material.Basalt },
	{ name = "Cracked Lava (Lava)", value = Enum.Material.CrackedLava },
	{ name = "Limestone (Batu Kapur)", value = Enum.Material.Limestone },
	{ name = "Sandstone (Batu Pasir)", value = Enum.Material.Sandstone },
	{ name = "Asphalt (Aspal)", value = Enum.Material.Asphalt },
	{ name = "Pebble (Kerikil Halus)", value = Enum.Material.Pebble },
	{ name = "Glacier (Gletser)", value = Enum.Material.Glacier },
	{ name = "Salt (Garam)", value = Enum.Material.Salt },
}

local COLLISION_OPTIONS = {
	{ name = "Default", value = Enum.CollisionFidelity.Default },
	{ name = "PreciseConvexDecomposition", value = Enum.CollisionFidelity.PreciseConvexDecomposition },
	{ name = "Hull", value = Enum.CollisionFidelity.Hull },
	{ name = "Box", value = Enum.CollisionFidelity.Box },
}

local RENDER_OPTIONS = {
	{ name = "Automatic", value = Enum.RenderFidelity.Automatic },
	{ name = "Performance", value = Enum.RenderFidelity.Performance },
	{ name = "Precise", value = Enum.RenderFidelity.Precise },
}

-- ==============================================================================
-- 3. Black & White (Monochrome) Theme System
-- ==============================================================================
local function isDarkTheme(): boolean
	local ok, theme = pcall(function()
		return settings().Studio.Theme
	end)
	if ok and theme and string.find(string.lower(theme.Name), "light") then
		return false
	end
	return true
end

local function getMonochromePalette()
	if isDarkTheme() then
		return {
			mainBg = Color3.fromRGB(15, 15, 15),
			cardBg = Color3.fromRGB(24, 24, 24),
			cardBorder = Color3.fromRGB(48, 48, 48),
			inputBg = Color3.fromRGB(18, 18, 18),
			inputBorder = Color3.fromRGB(60, 60, 60),
			primaryText = Color3.fromRGB(255, 255, 255),
			secondaryText = Color3.fromRGB(165, 165, 165),
			dimText = Color3.fromRGB(105, 105, 105),
			btnPrimaryBg = Color3.fromRGB(250, 250, 250),
			btnPrimaryText = Color3.fromRGB(15, 15, 15),
			btnSecondaryBg = Color3.fromRGB(32, 32, 32),
			btnSecondaryText = Color3.fromRGB(240, 240, 240),
			btnSecondaryBorder = Color3.fromRGB(70, 70, 70),
			tabActiveBg = Color3.fromRGB(255, 255, 255),
			tabActiveText = Color3.fromRGB(15, 15, 15),
			tabInactiveBg = Color3.fromRGB(26, 26, 26),
			tabInactiveText = Color3.fromRGB(150, 150, 150),
			tabInactiveBorder = Color3.fromRGB(45, 45, 45),
			checkMark = Color3.fromRGB(255, 255, 255),
		}
	else
		return {
			mainBg = Color3.fromRGB(245, 245, 245),
			cardBg = Color3.fromRGB(255, 255, 255),
			cardBorder = Color3.fromRGB(215, 215, 215),
			inputBg = Color3.fromRGB(240, 240, 240),
			inputBorder = Color3.fromRGB(195, 195, 195),
			primaryText = Color3.fromRGB(15, 15, 15),
			secondaryText = Color3.fromRGB(95, 95, 95),
			dimText = Color3.fromRGB(140, 140, 140),
			btnPrimaryBg = Color3.fromRGB(20, 20, 20),
			btnPrimaryText = Color3.fromRGB(255, 255, 255),
			btnSecondaryBg = Color3.fromRGB(240, 240, 240),
			btnSecondaryText = Color3.fromRGB(20, 20, 20),
			btnSecondaryBorder = Color3.fromRGB(180, 180, 180),
			tabActiveBg = Color3.fromRGB(20, 20, 20),
			tabActiveText = Color3.fromRGB(255, 255, 255),
			tabInactiveBg = Color3.fromRGB(235, 235, 235),
			tabInactiveText = Color3.fromRGB(100, 100, 100),
			tabInactiveBorder = Color3.fromRGB(205, 205, 205),
			checkMark = Color3.fromRGB(20, 20, 20),
		}
	end
end

-- ==============================================================================
-- 4. Procedural EditableMesh Geometry Generation & Combination (Flat Normals & UVs)
-- ==============================================================================
local function addFlatQuad(em: EditableMesh, relCF: CFrame, pts: { Vector3 }, norm: Vector3, faceColor: Color3?)
	local v1 = em:AddVertex(relCF * pts[1])
	local v2 = em:AddVertex(relCF * pts[2])
	local v3 = em:AddVertex(relCF * pts[3])
	local v4 = em:AddVertex(relCF * pts[4])

	local fid1 = em:AddTriangle(v1, v2, v3)
	local fid2 = em:AddTriangle(v1, v3, v4)

	local rNorm = (relCF:VectorToWorldSpace(norm)).Unit
	local nid = em:AddNormal(rNorm)
	em:SetFaceNormals(fid1, {nid, nid, nid})
	em:SetFaceNormals(fid2, {nid, nid, nid})

	local uv1 = em:AddUV(Vector2.new(0, 0))
	local uv2 = em:AddUV(Vector2.new(1, 0))
	local uv3 = em:AddUV(Vector2.new(1, 1))
	local uv4 = em:AddUV(Vector2.new(0, 1))
	em:SetFaceUVs(fid1, {uv1, uv2, uv3})
	em:SetFaceUVs(fid2, {uv1, uv3, uv4})

	if faceColor then
		local cid = em:AddColor(faceColor, 1)
		em:SetFaceColors(fid1, {cid, cid, cid})
		em:SetFaceColors(fid2, {cid, cid, cid})
	end
end

local function addFlatTriangle(em: EditableMesh, relCF: CFrame, p1: Vector3, p2: Vector3, p3: Vector3, norm: Vector3, faceColor: Color3?)
	local v1 = em:AddVertex(relCF * p1)
	local v2 = em:AddVertex(relCF * p2)
	local v3 = em:AddVertex(relCF * p3)

	local fid = em:AddTriangle(v1, v2, v3)

	local rNorm = (relCF:VectorToWorldSpace(norm)).Unit
	local nid = em:AddNormal(rNorm)
	em:SetFaceNormals(fid, {nid, nid, nid})

	local uv1 = em:AddUV(Vector2.new(0, 0))
	local uv2 = em:AddUV(Vector2.new(1, 0))
	local uv3 = em:AddUV(Vector2.new(0.5, 1))
	em:SetFaceUVs(fid, {uv1, uv2, uv3})

	if faceColor then
		local cid = em:AddColor(faceColor, 1)
		em:SetFaceColors(fid, {cid, cid, cid})
	end
end

local function appendBoxGeometry(em: EditableMesh, relCF: CFrame, size: Vector3, faceColor: Color3?)
	local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	-- Front (+Z)
	addFlatQuad(em, relCF, { Vector3.new(-hx, -hy, hz), Vector3.new(hx, -hy, hz), Vector3.new(hx, hy, hz), Vector3.new(-hx, hy, hz) }, Vector3.new(0, 0, 1), faceColor)
	-- Back (-Z)
	addFlatQuad(em, relCF, { Vector3.new(hx, -hy, -hz), Vector3.new(-hx, -hy, -hz), Vector3.new(-hx, hy, -hz), Vector3.new(hx, hy, -hz) }, Vector3.new(0, 0, -1), faceColor)
	-- Top (+Y)
	addFlatQuad(em, relCF, { Vector3.new(-hx, hy, hz), Vector3.new(hx, hy, hz), Vector3.new(hx, hy, -hz), Vector3.new(-hx, hy, -hz) }, Vector3.new(0, 1, 0), faceColor)
	-- Bottom (-Y)
	addFlatQuad(em, relCF, { Vector3.new(-hx, -hy, -hz), Vector3.new(hx, -hy, -hz), Vector3.new(hx, -hy, hz), Vector3.new(-hx, -hy, hz) }, Vector3.new(0, -1, 0), faceColor)
	-- Right (+X)
	addFlatQuad(em, relCF, { Vector3.new(hx, -hy, hz), Vector3.new(hx, -hy, -hz), Vector3.new(hx, hy, -hz), Vector3.new(hx, hy, hz) }, Vector3.new(1, 0, 0), faceColor)
	-- Left (-X)
	addFlatQuad(em, relCF, { Vector3.new(-hx, -hy, -hz), Vector3.new(-hx, -hy, hz), Vector3.new(-hx, hy, hz), Vector3.new(-hx, hy, -hz) }, Vector3.new(-1, 0, 0), faceColor)
end

local function appendBeveledBoxGeometry(
	em: EditableMesh,
	relCF: CFrame,
	size: Vector3,
	radius: number?,
	segments: number?,
	faceColor: Color3?
)
	local seg = math.clamp(segments or 2, 1, 5)
	local sx, sy, sz = size.X, size.Y, size.Z
	local r = math.clamp(radius or 0.4, 0.01, math.min(sx, sy, sz) * 0.499)
	local ix = math.max(0, (sx / 2) - r)
	local iy = math.max(0, (sy / 2) - r)
	local iz = math.max(0, (sz / 2) - r)

	local cid = faceColor and em:AddColor(faceColor, 1) or nil
	local defaultUV1 = em:AddUV(Vector2.new(0, 0))
	local defaultUV2 = em:AddUV(Vector2.new(1, 0))
	local defaultUV3 = em:AddUV(Vector2.new(1, 1))

	local function addQuad(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3, n1: Vector3, n2: Vector3, n3: Vector3, n4: Vector3)
		local v1 = em:AddVertex(relCF * p1)
		local v2 = em:AddVertex(relCF * p2)
		local v3 = em:AddVertex(relCF * p3)
		local v4 = em:AddVertex(relCF * p4)

		local wn1 = (relCF:VectorToWorldSpace(n1)).Unit
		local wn2 = (relCF:VectorToWorldSpace(n2)).Unit
		local wn3 = (relCF:VectorToWorldSpace(n3)).Unit
		local wn4 = (relCF:VectorToWorldSpace(n4)).Unit

		local nid1 = em:AddNormal(wn1)
		local nid2 = em:AddNormal(wn2)
		local nid3 = em:AddNormal(wn3)
		local nid4 = em:AddNormal(wn4)

		local avgNorm = (n1 + n2 + n3 + n4).Unit
		local cross = (p2 - p1):Cross(p3 - p1)
		if cross:Dot(avgNorm) < 0 then
			local f1 = em:AddTriangle(v1, v3, v2)
			em:SetFaceNormals(f1, {nid1, nid3, nid2})
			em:SetFaceUVs(f1, {defaultUV1, defaultUV3, defaultUV2})
			if cid then em:SetFaceColors(f1, {cid, cid, cid}) end

			local f2 = em:AddTriangle(v1, v4, v3)
			em:SetFaceNormals(f2, {nid1, nid4, nid3})
			em:SetFaceUVs(f2, {defaultUV1, defaultUV3, defaultUV2})
			if cid then em:SetFaceColors(f2, {cid, cid, cid}) end
		else
			local f1 = em:AddTriangle(v1, v2, v3)
			em:SetFaceNormals(f1, {nid1, nid2, nid3})
			em:SetFaceUVs(f1, {defaultUV1, defaultUV2, defaultUV3})
			if cid then em:SetFaceColors(f1, {cid, cid, cid}) end

			local f2 = em:AddTriangle(v1, v3, v4)
			em:SetFaceNormals(f2, {nid1, nid3, nid4})
			em:SetFaceUVs(f2, {defaultUV1, defaultUV3, defaultUV2})
			if cid then em:SetFaceColors(f2, {cid, cid, cid}) end
		end
	end

	-- 1. 6 Flat Planar Faces (Inset quads)
	addQuad(Vector3.new(-ix, sy/2, -iz), Vector3.new(ix, sy/2, -iz), Vector3.new(ix, sy/2, iz), Vector3.new(-ix, sy/2, iz), Vector3.new(0,1,0), Vector3.new(0,1,0), Vector3.new(0,1,0), Vector3.new(0,1,0))
	addQuad(Vector3.new(-ix, -sy/2, iz), Vector3.new(ix, -sy/2, iz), Vector3.new(ix, -sy/2, -iz), Vector3.new(-ix, -sy/2, -iz), Vector3.new(0,-1,0), Vector3.new(0,-1,0), Vector3.new(0,-1,0), Vector3.new(0,-1,0))
	addQuad(Vector3.new(-ix, -iy, sz/2), Vector3.new(ix, -iy, sz/2), Vector3.new(ix, iy, sz/2), Vector3.new(-ix, iy, sz/2), Vector3.new(0,0,1), Vector3.new(0,0,1), Vector3.new(0,0,1), Vector3.new(0,0,1))
	addQuad(Vector3.new(ix, -iy, -sz/2), Vector3.new(-ix, -iy, -sz/2), Vector3.new(-ix, iy, -sz/2), Vector3.new(ix, iy, -sz/2), Vector3.new(0,0,-1), Vector3.new(0,0,-1), Vector3.new(0,0,-1), Vector3.new(0,0,-1))
	addQuad(Vector3.new(sx/2, -iy, iz), Vector3.new(sx/2, -iy, -iz), Vector3.new(sx/2, iy, -iz), Vector3.new(sx/2, iy, iz), Vector3.new(1,0,0), Vector3.new(1,0,0), Vector3.new(1,0,0), Vector3.new(1,0,0))
	addQuad(Vector3.new(-sx/2, -iy, -iz), Vector3.new(-sx/2, -iy, iz), Vector3.new(-sx/2, iy, iz), Vector3.new(-sx/2, iy, -iz), Vector3.new(-1,0,0), Vector3.new(-1,0,0), Vector3.new(-1,0,0), Vector3.new(-1,0,0))

	-- 2. 12 Cylindrical Edge Bevels
	local function buildEdgeArc(axis: string, c1: number, c2: number, signA: number, signB: number)
		for s = 0, seg - 1 do
			local a1 = (s / seg) * (math.pi / 2)
			local a2 = ((s + 1) / seg) * (math.pi / 2)

			local cos1, sin1 = math.cos(a1), math.sin(a1)
			local cos2, sin2 = math.cos(a2), math.sin(a2)

			if axis == "Z" then
				local offA1, offB1 = signA * (ix + r * cos1), signB * (iy + r * sin1)
				local offA2, offB2 = signA * (ix + r * cos2), signB * (iy + r * sin2)
				local norm1 = Vector3.new(signA * cos1, signB * sin1, 0).Unit
				local norm2 = Vector3.new(signA * cos2, signB * sin2, 0).Unit

				local p1 = Vector3.new(offA1, offB1, -iz)
				local p2 = Vector3.new(offA1, offB1, iz)
				local p3 = Vector3.new(offA2, offB2, iz)
				local p4 = Vector3.new(offA2, offB2, -iz)

				addQuad(p1, p2, p3, p4, norm1, norm1, norm2, norm2)
			elseif axis == "X" then
				local offA1, offB1 = signA * (iy + r * cos1), signB * (iz + r * sin1)
				local offA2, offB2 = signA * (iy + r * cos2), signB * (iz + r * sin2)
				local norm1 = Vector3.new(0, signA * cos1, signB * sin1).Unit
				local norm2 = Vector3.new(0, signA * cos2, signB * sin2).Unit

				local p1 = Vector3.new(-ix, offA1, offB1)
				local p2 = Vector3.new(ix, offA1, offB1)
				local p3 = Vector3.new(ix, offA2, offB2)
				local p4 = Vector3.new(-ix, offA2, offB2)

				addQuad(p1, p2, p3, p4, norm1, norm1, norm2, norm2)
			elseif axis == "Y" then
				local offA1, offB1 = signA * (iz + r * cos1), signB * (ix + r * sin1)
				local offA2, offB2 = signA * (iz + r * cos2), signB * (ix + r * sin2)
				local norm1 = Vector3.new(signB * sin1, 0, signA * cos1).Unit
				local norm2 = Vector3.new(signB * sin2, 0, signA * cos2).Unit

				local p1 = Vector3.new(offB1, -iy, offA1)
				local p2 = Vector3.new(offB1, iy, offA1)
				local p3 = Vector3.new(offB2, iy, offA2)
				local p4 = Vector3.new(offB2, -iy, offA2)

				addQuad(p1, p2, p3, p4, norm1, norm1, norm2, norm2)
			end
		end
	end

	for _, sx_sign in ipairs({1, -1}) do
		for _, sy_sign in ipairs({1, -1}) do
			buildEdgeArc("Z", ix, iy, sx_sign, sy_sign)
		end
	end

	for _, sy_sign in ipairs({1, -1}) do
		for _, sz_sign in ipairs({1, -1}) do
			buildEdgeArc("X", iy, iz, sy_sign, sz_sign)
		end
	end

	for _, sz_sign in ipairs({1, -1}) do
		for _, sx_sign in ipairs({1, -1}) do
			buildEdgeArc("Y", iz, ix, sz_sign, sx_sign)
		end
	end

	-- 3. 8 Spherical Corner Patches
	for _, sx_sign in ipairs({1, -1}) do
		for _, sy_sign in ipairs({1, -1}) do
			for _, sz_sign in ipairs({1, -1}) do
				local center = Vector3.new(sx_sign * ix, sy_sign * iy, sz_sign * iz)

				for i = 0, seg - 1 do
					local theta1 = (i / seg) * (math.pi / 2)
					local theta2 = ((i + 1) / seg) * (math.pi / 2)

					for j = 0, seg - 1 do
						local phi1 = (j / seg) * (math.pi / 2)
						local phi2 = ((j + 1) / seg) * (math.pi / 2)

						local function spherePoint(th: number, ph: number): (Vector3, Vector3)
							local x = sx_sign * math.cos(th) * math.cos(ph)
							local y = sy_sign * math.sin(th)
							local z = sz_sign * math.cos(th) * math.sin(ph)
							local norm = Vector3.new(x, y, z).Unit
							local pt = center + norm * r
							return pt, norm
						end

						local p1, n1 = spherePoint(theta1, phi1)
						local p2, n2 = spherePoint(theta1, phi2)
						local p3, n3 = spherePoint(theta2, phi2)
						local p4, n4 = spherePoint(theta2, phi1)

						addQuad(p1, p2, p3, p4, n1, n2, n3, n4)
					end
				end
			end
		end
	end
end

local function appendWedgeGeometry(em: EditableMesh, relCF: CFrame, size: Vector3, faceColor: Color3?)
	local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	-- Bottom face (-Y)
	addFlatQuad(em, relCF, { Vector3.new(-hx, -hy, -hz), Vector3.new(hx, -hy, -hz), Vector3.new(hx, -hy, hz), Vector3.new(-hx, -hy, hz) }, Vector3.new(0, -1, 0), faceColor)
	-- Back face (-Z)
	addFlatQuad(em, relCF, { Vector3.new(hx, -hy, -hz), Vector3.new(-hx, -hy, -hz), Vector3.new(-hx, hy, -hz), Vector3.new(hx, hy, -hz) }, Vector3.new(0, 0, -1), faceColor)
	-- Slanted face (from -Z, +Y down to +Z, -Y)
	local slantNorm = Vector3.new(0, hz, hy).Unit
	addFlatQuad(em, relCF, { Vector3.new(-hx, -hy, hz), Vector3.new(hx, -hy, hz), Vector3.new(hx, hy, -hz), Vector3.new(-hx, hy, -hz) }, slantNorm, faceColor)
	-- Left face (-X triangle)
	addFlatTriangle(em, relCF, Vector3.new(-hx, -hy, hz), Vector3.new(-hx, hy, -hz), Vector3.new(-hx, -hy, -hz), Vector3.new(-1, 0, 0), faceColor)
	-- Right face (+X triangle)
	addFlatTriangle(em, relCF, Vector3.new(hx, -hy, -hz), Vector3.new(hx, hy, -hz), Vector3.new(hx, -hy, hz), Vector3.new(1, 0, 0), faceColor)
end

local function appendCornerWedgeGeometry(em: EditableMesh, relCF: CFrame, size: Vector3, faceColor: Color3?)
	local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	-- Bottom face (-Y)
	addFlatQuad(em, relCF, { Vector3.new(-hx, -hy, -hz), Vector3.new(hx, -hy, -hz), Vector3.new(hx, -hy, hz), Vector3.new(-hx, -hy, hz) }, Vector3.new(0, -1, 0), faceColor)
	-- Back face (-Z)
	addFlatTriangle(em, relCF, Vector3.new(hx, -hy, -hz), Vector3.new(-hx, -hy, -hz), Vector3.new(-hx, hy, -hz), Vector3.new(0, 0, -1), faceColor)
	-- Left face (-X)
	addFlatTriangle(em, relCF, Vector3.new(-hx, -hy, -hz), Vector3.new(-hx, -hy, hz), Vector3.new(-hx, hy, -hz), Vector3.new(-1, 0, 0), faceColor)
	-- Front-slanted face (meeting at -hx, hy, -hz)
	local fn = Vector3.new(0, hz, hy).Unit
	addFlatTriangle(em, relCF, Vector3.new(-hx, -hy, hz), Vector3.new(hx, -hy, hz), Vector3.new(-hx, hy, -hz), fn, faceColor)
	-- Right-slanted face (meeting at -hx, hy, -hz)
	local rn = Vector3.new(hy, hx, 0).Unit
	addFlatTriangle(em, relCF, Vector3.new(hx, -hy, hz), Vector3.new(hx, -hy, -hz), Vector3.new(-hx, hy, -hz), rn, faceColor)
end

local function appendCylinderGeometry(em: EditableMesh, relCF: CFrame, size: Vector3, segments: number?, faceColor: Color3?)
	local s = segments or 24
	local halfH = size.X / 2
	local radius = math.min(size.Y, size.Z) / 2

	-- Left cap (-X)
	local leftCenter = em:AddVertex(relCF * Vector3.new(-halfH, 0, 0))
	local leftCapNorm = (relCF:VectorToWorldSpace(Vector3.new(-1, 0, 0))).Unit
	local leftCapNid = em:AddNormal(leftCapNorm)
	local leftCapVerts = {}

	-- Right cap (+X)
	local rightCenter = em:AddVertex(relCF * Vector3.new(halfH, 0, 0))
	local rightCapNorm = (relCF:VectorToWorldSpace(Vector3.new(1, 0, 0))).Unit
	local rightCapNid = em:AddNormal(rightCapNorm)
	local rightCapVerts = {}

	for i = 0, s - 1 do
		local angle = i * 2 * math.pi / s
		local y = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		table.insert(leftCapVerts, em:AddVertex(relCF * Vector3.new(-halfH, y, z)))
		table.insert(rightCapVerts, em:AddVertex(relCF * Vector3.new(halfH, y, z)))
	end

	local cid = faceColor and em:AddColor(faceColor, 1) or nil

	for i = 1, s do
		local nextI = (i % s) + 1
		local fidL = em:AddTriangle(leftCenter, leftCapVerts[i], leftCapVerts[nextI])
		local fidR = em:AddTriangle(rightCenter, rightCapVerts[nextI], rightCapVerts[i])
		em:SetFaceNormals(fidL, {leftCapNid, leftCapNid, leftCapNid})
		em:SetFaceNormals(fidR, {rightCapNid, rightCapNid, rightCapNid})
		if cid then
			em:SetFaceColors(fidL, {cid, cid, cid})
			em:SetFaceColors(fidR, {cid, cid, cid})
		end
	end

	-- Barrel (side quads with separate vertices and smooth radial normals)
	for i = 1, s do
		local nextI = (i % s) + 1
		local a1 = (i - 1) * 2 * math.pi / s
		local a2 = (nextI - 1) * 2 * math.pi / s

		local p1 = Vector3.new(-halfH, math.cos(a1) * radius, math.sin(a1) * radius)
		local p2 = Vector3.new( halfH, math.cos(a1) * radius, math.sin(a1) * radius)
		local p3 = Vector3.new( halfH, math.cos(a2) * radius, math.sin(a2) * radius)
		local p4 = Vector3.new(-halfH, math.cos(a2) * radius, math.sin(a2) * radius)

		local n1 = (relCF:VectorToWorldSpace(Vector3.new(0, math.cos(a1), math.sin(a1)))).Unit
		local n2 = (relCF:VectorToWorldSpace(Vector3.new(0, math.cos(a2), math.sin(a2)))).Unit

		local nid1 = em:AddNormal(n1)
		local nid2 = em:AddNormal(n2)

		local v1 = em:AddVertex(relCF * p1)
		local v2 = em:AddVertex(relCF * p2)
		local v3 = em:AddVertex(relCF * p3)
		local v4 = em:AddVertex(relCF * p4)

		local f1 = em:AddTriangle(v1, v2, v3)
		local f2 = em:AddTriangle(v1, v3, v4)

		em:SetFaceNormals(f1, {nid1, nid1, nid2})
		em:SetFaceNormals(f2, {nid1, nid2, nid2})

		local u1 = (i - 1) / s
		local u2 = i / s
		local uv1 = em:AddUV(Vector2.new(u1, 0))
		local uv2 = em:AddUV(Vector2.new(u1, 1))
		local uv3 = em:AddUV(Vector2.new(u2, 1))
		local uv4 = em:AddUV(Vector2.new(u2, 0))

		em:SetFaceUVs(f1, {uv1, uv2, uv3})
		em:SetFaceUVs(f2, {uv1, uv3, uv4})

		if cid then
			em:SetFaceColors(f1, {cid, cid, cid})
			em:SetFaceColors(f2, {cid, cid, cid})
		end
	end
end

local function appendSphereGeometry(em: EditableMesh, relCF: CFrame, size: Vector3, seg: number?, rng: number?, faceColor: Color3?)
	local s = seg or 20
	local r_rings = rng or 20
	local rx, ry, rz = size.X / 2, size.Y / 2, size.Z / 2

	local vertices = {}
	local normals = {}
	local uvs = {}

	for r = 0, r_rings do
		local theta = r * math.pi / r_rings
		local sinTheta = math.sin(theta)
		local cosTheta = math.cos(theta)
		local vCoord = r / r_rings

		vertices[r] = {}
		normals[r] = {}
		uvs[r] = {}

		for sIdx = 0, s do
			local phi = sIdx * 2 * math.pi / s
			local uCoord = sIdx / s
			local nx = math.cos(phi) * sinTheta
			local ny = cosTheta
			local nz = math.sin(phi) * sinTheta

			local p = Vector3.new(nx * rx, ny * ry, nz * rz)
			local n = (relCF:VectorToWorldSpace(Vector3.new(nx, ny, nz))).Unit

			vertices[r][sIdx] = em:AddVertex(relCF * p)
			normals[r][sIdx] = em:AddNormal(n)
			uvs[r][sIdx] = em:AddUV(Vector2.new(uCoord, vCoord))
		end
	end

	local cid = faceColor and em:AddColor(faceColor, 1) or nil

	for r = 0, r_rings - 1 do
		for sIdx = 0, s - 1 do
			local vA = vertices[r][sIdx]
			local vB = vertices[r + 1][sIdx]
			local vC = vertices[r + 1][sIdx + 1]
			local vD = vertices[r][sIdx + 1]

			local nA = normals[r][sIdx]
			local nB = normals[r + 1][sIdx]
			local nC = normals[r + 1][sIdx + 1]
			local nD = normals[r][sIdx + 1]

			local uvA = uvs[r][sIdx]
			local uvB = uvs[r + 1][sIdx]
			local uvC = uvs[r + 1][sIdx + 1]
			local uvD = uvs[r][sIdx + 1]

			if r ~= 0 then
				local f1 = em:AddTriangle(vA, vB, vD)
				em:SetFaceNormals(f1, {nA, nB, nD})
				em:SetFaceUVs(f1, {uvA, uvB, uvD})
				if cid then em:SetFaceColors(f1, {cid, cid, cid}) end
			end
			if r ~= r_rings - 1 then
				local f2 = em:AddTriangle(vB, vC, vD)
				em:SetFaceNormals(f2, {nB, nC, nD})
				em:SetFaceUVs(f2, {uvB, uvC, uvD})
				if cid then em:SetFaceColors(f2, {cid, cid, cid}) end
			end
		end
	end
end

local function appendSpecialMeshGeometry(em: EditableMesh, relCF: CFrame, meshId: string, scale: Vector3?, faceColor: Color3?): boolean
	local s, sourceEm = pcall(function()
		return AssetService:CreateEditableMeshAsync(Content.fromUri(meshId))
	end)
	if not (s and sourceEm) then return false end

	local sc = scale or Vector3.new(1, 1, 1)
	local vertMap = {}
	for _, vid in ipairs(sourceEm:GetVertices()) do
		local p = sourceEm:GetPosition(vid) * sc
		vertMap[vid] = em:AddVertex(relCF * p)
	end

	local normMap = {}
	pcall(function()
		for _, nid in ipairs(sourceEm:GetNormals()) do
			local n = sourceEm:GetNormal(nid)
			local rNorm = (relCF:VectorToWorldSpace(n)).Unit
			normMap[nid] = em:AddNormal(rNorm)
		end
	end)

	local uvMap = {}
	pcall(function()
		for _, uvid in ipairs(sourceEm:GetUVs()) do
			uvMap[uvid] = em:AddUV(sourceEm:GetUV(uvid))
		end
	end)

	local cid = faceColor and em:AddColor(faceColor, 1) or nil

	for _, fid in ipairs(sourceEm:GetFaces()) do
		local triVerts = sourceEm:GetFaceVertices(fid)
		local a = vertMap[triVerts[1]]
		local b = vertMap[triVerts[2]]
		local c = vertMap[triVerts[3]]
		if a and b and c then
			local newFid = em:AddTriangle(a, b, c)

			pcall(function()
				local fn = sourceEm:GetFaceNormals(fid)
				if fn and #fn == 3 and normMap[fn[1]] and normMap[fn[2]] and normMap[fn[3]] then
					em:SetFaceNormals(newFid, {normMap[fn[1]], normMap[fn[2]], normMap[fn[3]]})
				end
			end)

			pcall(function()
				local fuv = sourceEm:GetFaceUVs(fid)
				if fuv and #fuv == 3 and uvMap[fuv[1]] and uvMap[fuv[2]] and uvMap[fuv[3]] then
					em:SetFaceUVs(newFid, {uvMap[fuv[1]], uvMap[fuv[2]], uvMap[fuv[3]]})
				end
			end)

			if cid then
				em:SetFaceColors(newFid, {cid, cid, cid})
			end
		end
	end
	return true
end

local function normalizeAssetId(raw: string): string
	raw = string.gsub(raw, "^%s+", "")
	raw = string.gsub(raw, "%s+$", "")
	if raw == "" then return "" end

	if string.find(raw, "^%d+$") then
		return "rbxassetid://" .. raw
	end

	local num = string.match(raw, "asset/%?id=(%d+)") or string.match(raw, "asset/(%d+)") or string.match(raw, "rbxassetid://(%d+)")
	if num then
		return "rbxassetid://" .. num
	end

	return raw
end

-- ==============================================================================
-- 5. Build UI Hierarchy
-- ==============================================================================
local mainContainer = Instance.new("ScrollingFrame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(1, 0, 1, 0)
mainContainer.BorderSizePixel = 0
mainContainer.ScrollBarThickness = 5
mainContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
mainContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
mainContainer.Parent = widget

local mainPad = Instance.new("UIPadding")
mainPad.PaddingTop = UDim.new(0, 12)
mainPad.PaddingBottom = UDim.new(0, 16)
mainPad.PaddingLeft = UDim.new(0, 12)
mainPad.PaddingRight = UDim.new(0, 12)
mainPad.Parent = mainContainer

local mainLayout = Instance.new("UIListLayout")
mainLayout.Padding = UDim.new(0, 10)
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Parent = mainContainer

-- UI Tracking tables for dynamic theme
local allCards = {}
local allStrokes = {}
local allInputs = {}
local allInputStrokes = {}
local allLabels = {}
local allSubLabels = {}
local allButtons = {}
local allButtonStrokes = {}
local allCheckboxes = {}

-- Forward declarations for cross-referencing and dynamic styling
local btnSeg1: TextButton?, btnSeg2: TextButton?, btnSeg3: TextButton?
local bs1Stroke: UIStroke?, bs2Stroke: UIStroke?, bs3Stroke: UIStroke?
local btnBevelAction: TextButton?
local executeNegateParts, executeUnionParts, executeSeparateUnion, executeBevelParts

local function createCard(name: string, order: number, parentInstance: Instance?)
	local card = Instance.new("Frame")
	card.Name = name
	card.LayoutOrder = order
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = card

	local cPad = Instance.new("UIPadding")
	cPad.PaddingTop = UDim.new(0, 10)
	cPad.PaddingBottom = UDim.new(0, 10)
	cPad.PaddingLeft = UDim.new(0, 10)
	cPad.PaddingRight = UDim.new(0, 10)
	cPad.Parent = card

	local cLayout = Instance.new("UIListLayout")
	cLayout.Padding = UDim.new(0, 8)
	cLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cLayout.Parent = card

	card.Parent = parentInstance or mainContainer
	table.insert(allCards, card)
	table.insert(allStrokes, stroke)
	return card, stroke
end

local function createCheckbox(parentCard: Instance, label: string, initialVal: boolean, order: number, callback: (boolean) -> ())
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, 0, 0, 24)
	row.BackgroundTransparency = 1
	row.Text = ""
	row.LayoutOrder = order

	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 18, 0, 18)
	box.Position = UDim2.new(0, 0, 0.5, -9)
	box.BorderSizePixel = 0

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 4)
	bCorner.Parent = box

	local bStroke = Instance.new("UIStroke")
	bStroke.Thickness = 1
	bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	bStroke.Parent = box

	local checkMark = Instance.new("TextLabel")
	checkMark.Size = UDim2.new(1, 0, 1, 0)
	checkMark.BackgroundTransparency = 1
	checkMark.Font = Enum.Font.SourceSansBold
	checkMark.TextSize = 13
	checkMark.Text = initialVal and "✓" or ""
	checkMark.Parent = box
	box.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Position = UDim2.new(0, 26, 0, 0)
	lbl.Size = UDim2.new(1, -26, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.SourceSans
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = label
	lbl.Parent = row

	local state = initialVal
	row.MouseButton1Click:Connect(function()
		state = not state
		checkMark.Text = state and "✓" or ""
		callback(state)
	end)

	row.Parent = parentCard
	table.insert(allCheckboxes, { box = box, stroke = bStroke, mark = checkMark, label = lbl })
	return row, box, bStroke, checkMark, lbl
end

-- --- Top Header: Tab Switcher & App Title ---
local tabCard, _ = createCard("TabSwitcherCard", 1)

local titleRow = Instance.new("Frame")
titleRow.Name = "TitleRow"
titleRow.Size = UDim2.new(1, 0, 0, 20)
titleRow.BackgroundTransparency = 1
titleRow.LayoutOrder = 1
titleRow.Parent = tabCard

local appTitle = Instance.new("TextLabel")
appTitle.Name = "AppTitle"
appTitle.Text = "PART & UNION CONVERTER"
appTitle.Font = Enum.Font.SourceSansBold
appTitle.TextSize = 14
appTitle.TextXAlignment = Enum.TextXAlignment.Left
appTitle.Size = UDim2.new(0.65, 0, 1, 0)
appTitle.BackgroundTransparency = 1
appTitle.Parent = titleRow
table.insert(allLabels, appTitle)

local appBadge = Instance.new("TextLabel")
appBadge.Name = "AppBadge"
appBadge.Text = "MONOCHROME"
appBadge.Font = Enum.Font.SourceSansBold
appBadge.TextSize = 10
appBadge.TextXAlignment = Enum.TextXAlignment.Right
appBadge.Size = UDim2.new(0.35, 0, 1, 0)
appBadge.BackgroundTransparency = 1
appBadge.Parent = titleRow
table.insert(allSubLabels, appBadge)

local tabButtonRow = Instance.new("Frame")
tabButtonRow.Name = "TabButtonRow"
tabButtonRow.Size = UDim2.new(1, 0, 0, 32)
tabButtonRow.BackgroundTransparency = 1
tabButtonRow.LayoutOrder = 2
tabButtonRow.Parent = tabCard

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabButtonRow

local tabTerrainBtn = Instance.new("TextButton")
tabTerrainBtn.Name = "TabTerrainBtn"
tabTerrainBtn.Size = UDim2.new(0.25, -3, 1, 0)
tabTerrainBtn.Font = Enum.Font.SourceSansBold
tabTerrainBtn.TextSize = 11
tabTerrainBtn.Text = "⛰️ Terrain"
tabTerrainBtn.BorderSizePixel = 0
tabTerrainBtn.AutoButtonColor = false

local tabTCorner = Instance.new("UICorner")
tabTCorner.CornerRadius = UDim.new(0, 4)
tabTCorner.Parent = tabTerrainBtn

local tabTStroke = Instance.new("UIStroke")
tabTStroke.Thickness = 1
tabTStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
tabTStroke.Parent = tabTerrainBtn
tabTerrainBtn.Parent = tabButtonRow

local tabMeshBtn = Instance.new("TextButton")
tabMeshBtn.Name = "TabMeshBtn"
tabMeshBtn.Size = UDim2.new(0.25, -3, 1, 0)
tabMeshBtn.Font = Enum.Font.SourceSansBold
tabMeshBtn.TextSize = 11
tabMeshBtn.Text = "🔷 Mesh"
tabMeshBtn.BorderSizePixel = 0
tabMeshBtn.AutoButtonColor = false

local tabMCorner = Instance.new("UICorner")
tabMCorner.CornerRadius = UDim.new(0, 4)
tabMCorner.Parent = tabMeshBtn

local tabMStroke = Instance.new("UIStroke")
tabMStroke.Thickness = 1
tabMStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
tabMStroke.Parent = tabMeshBtn
tabMeshBtn.Parent = tabButtonRow

local tabCSGBtn = Instance.new("TextButton")
tabCSGBtn.Name = "TabCSGBtn"
tabCSGBtn.Size = UDim2.new(0.25, -3, 1, 0)
tabCSGBtn.Font = Enum.Font.SourceSansBold
tabCSGBtn.TextSize = 11
tabCSGBtn.Text = "🧩 CSG"
tabCSGBtn.BorderSizePixel = 0
tabCSGBtn.AutoButtonColor = false

local tabCCorner = Instance.new("UICorner")
tabCCorner.CornerRadius = UDim.new(0, 4)
tabCCorner.Parent = tabCSGBtn

local tabCStroke = Instance.new("UIStroke")
tabCStroke.Thickness = 1
tabCStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
tabCStroke.Parent = tabCSGBtn
tabCSGBtn.Parent = tabButtonRow

local tabObfBtn = Instance.new("TextButton")
tabObfBtn.Name = "TabObfBtn"
tabObfBtn.Size = UDim2.new(0.25, -3, 1, 0)
tabObfBtn.Font = Enum.Font.SourceSansBold
tabObfBtn.TextSize = 11
tabObfBtn.Text = "🔒 Obf"
tabObfBtn.BorderSizePixel = 0
tabObfBtn.AutoButtonColor = false

local tabOCorner = Instance.new("UICorner")
tabOCorner.CornerRadius = UDim.new(0, 4)
tabOCorner.Parent = tabObfBtn

local tabOStroke = Instance.new("UIStroke")
tabOStroke.Thickness = 1
tabOStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
tabOStroke.Parent = tabObfBtn
tabObfBtn.Parent = tabButtonRow

-- --- Selection Card (Shared) ---
local selCard, _ = createCard("SelectionCard", 2)

local selTopRow = Instance.new("Frame")
selTopRow.Name = "TopRow"
selTopRow.Size = UDim2.new(1, 0, 0, 24)
selTopRow.BackgroundTransparency = 1
selTopRow.LayoutOrder = 1
selTopRow.Parent = selCard

local selCountLabel = Instance.new("TextLabel")
selCountLabel.Text = "Part Terpilih: 0"
selCountLabel.Font = Enum.Font.SourceSansBold
selCountLabel.TextSize = 14
selCountLabel.TextXAlignment = Enum.TextXAlignment.Left
selCountLabel.Size = UDim2.new(1, -75, 1, 0)
selCountLabel.BackgroundTransparency = 1
selCountLabel.Parent = selTopRow
table.insert(allLabels, selCountLabel)

local refreshBtn = Instance.new("TextButton")
refreshBtn.Name = "RefreshBtn"
refreshBtn.Size = UDim2.new(0, 70, 0, 24)
refreshBtn.Position = UDim2.new(1, -70, 0, 0)
refreshBtn.Font = Enum.Font.SourceSansSemibold
refreshBtn.TextSize = 12
refreshBtn.Text = "🔄 Refresh"
refreshBtn.BorderSizePixel = 0
refreshBtn.AutoButtonColor = true

local refCorner = Instance.new("UICorner")
refCorner.CornerRadius = UDim.new(0, 4)
refCorner.Parent = refreshBtn

local refStroke = Instance.new("UIStroke")
refStroke.Thickness = 1
refStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
refStroke.Parent = refreshBtn
refreshBtn.Parent = selTopRow
table.insert(allButtons, refreshBtn)
table.insert(allButtonStrokes, refStroke)

local selSubLabel = Instance.new("TextLabel")
selSubLabel.Text = "Pilih part atau union di Viewport atau Explorer."
selSubLabel.Font = Enum.Font.SourceSans
selSubLabel.TextSize = 12
selSubLabel.TextXAlignment = Enum.TextXAlignment.Left
selSubLabel.Size = UDim2.new(1, 0, 0, 14)
selSubLabel.BackgroundTransparency = 1
selSubLabel.LayoutOrder = 2
selSubLabel.Parent = selCard
table.insert(allSubLabels, selSubLabel)

-- ==============================================================================
-- 6. Tab 1: PART TO TERRAIN CONTENT
-- ==============================================================================
local terrainFrame = Instance.new("Frame")
terrainFrame.Name = "TerrainFrame"
terrainFrame.Size = UDim2.new(1, 0, 0, 0)
terrainFrame.AutomaticSize = Enum.AutomaticSize.Y
terrainFrame.BackgroundTransparency = 1
terrainFrame.LayoutOrder = 3
terrainFrame.Parent = mainContainer

local tLayout = Instance.new("UIListLayout")
tLayout.Padding = UDim.new(0, 10)
tLayout.SortOrder = Enum.SortOrder.LayoutOrder
tLayout.Parent = terrainFrame

-- Material Selector Card
local matCard, _ = createCard("MaterialCard", 1, terrainFrame)

local matHeader = Instance.new("TextLabel")
matHeader.Text = "TARGET MATERIAL"
matHeader.Font = Enum.Font.SourceSansBold
matHeader.TextSize = 12
matHeader.TextXAlignment = Enum.TextXAlignment.Left
matHeader.Size = UDim2.new(1, 0, 0, 16)
matHeader.BackgroundTransparency = 1
matHeader.LayoutOrder = 1
matHeader.Parent = matCard
table.insert(allSubLabels, matHeader)

local matDropdownBtn = Instance.new("TextButton")
matDropdownBtn.Name = "MaterialDropdownBtn"
matDropdownBtn.Size = UDim2.new(1, 0, 0, 32)
matDropdownBtn.Font = Enum.Font.SourceSansSemibold
matDropdownBtn.TextSize = 13
matDropdownBtn.Text = "  " .. terrainOptions.materialName .. "  ▼"
matDropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
matDropdownBtn.BorderSizePixel = 0
matDropdownBtn.LayoutOrder = 2
matDropdownBtn.AutoButtonColor = false

local mBtnCorner = Instance.new("UICorner")
mBtnCorner.CornerRadius = UDim.new(0, 4)
mBtnCorner.Parent = matDropdownBtn

local mBtnStroke = Instance.new("UIStroke")
mBtnStroke.Thickness = 1
mBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mBtnStroke.Parent = matDropdownBtn
matDropdownBtn.Parent = matCard
table.insert(allInputs, matDropdownBtn)
table.insert(allInputStrokes, mBtnStroke)

local matListFrame = Instance.new("ScrollingFrame")
matListFrame.Name = "MaterialList"
matListFrame.Size = UDim2.new(1, 0, 0, 160)
matListFrame.BorderSizePixel = 0
matListFrame.ScrollBarThickness = 4
matListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
matListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
matListFrame.Visible = false
matListFrame.LayoutOrder = 3

local mlCorner = Instance.new("UICorner")
mlCorner.CornerRadius = UDim.new(0, 4)
mlCorner.Parent = matListFrame

local mlStroke = Instance.new("UIStroke")
mlStroke.Thickness = 1
mlStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mlStroke.Parent = matListFrame

local mlLayout = Instance.new("UIListLayout")
mlLayout.Padding = UDim.new(0, 2)
mlLayout.SortOrder = Enum.SortOrder.LayoutOrder
mlLayout.Parent = matListFrame

local mlPad = Instance.new("UIPadding")
mlPad.PaddingTop = UDim.new(0, 4)
mlPad.PaddingBottom = UDim.new(0, 4)
mlPad.PaddingLeft = UDim.new(0, 4)
mlPad.PaddingRight = UDim.new(0, 4)
mlPad.Parent = matListFrame
matListFrame.Parent = matCard
table.insert(allInputs, matListFrame)
table.insert(allInputStrokes, mlStroke)

matDropdownBtn.MouseButton1Click:Connect(function()
	matListFrame.Visible = not matListFrame.Visible
	matDropdownBtn.Text = "  " .. terrainOptions.materialName .. (matListFrame.Visible and "  ▲" or "  ▼")
end)

local materialButtons = {}
for i, item in ipairs(MATERIALS) do
	local mBtn = Instance.new("TextButton")
	mBtn.Name = "Mat_" .. tostring(i)
	mBtn.Size = UDim2.new(1, 0, 0, 26)
	mBtn.Font = Enum.Font.SourceSans
	mBtn.TextSize = 13
	mBtn.Text = "  " .. item.name
	mBtn.TextXAlignment = Enum.TextXAlignment.Left
	mBtn.BorderSizePixel = 0
	mBtn.LayoutOrder = i

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 3)
	itemCorner.Parent = mBtn

	mBtn.MouseButton1Click:Connect(function()
		terrainOptions.material = item.value
		terrainOptions.materialName = item.name
		matDropdownBtn.Text = "  " .. terrainOptions.materialName .. "  ▼"
		matListFrame.Visible = false
	end)

	mBtn.Parent = matListFrame
	table.insert(materialButtons, mBtn)
end

-- Terrain Options Card
local tOptCard, _ = createCard("TerrainOptionsCard", 2, terrainFrame)

local tOptHeader = Instance.new("TextLabel")
tOptHeader.Text = "PILIHAN TERRAIN"
tOptHeader.Font = Enum.Font.SourceSansBold
tOptHeader.TextSize = 12
tOptHeader.TextXAlignment = Enum.TextXAlignment.Left
tOptHeader.Size = UDim2.new(1, 0, 0, 16)
tOptHeader.BackgroundTransparency = 1
tOptHeader.LayoutOrder = 1
tOptHeader.Parent = tOptCard
table.insert(allSubLabels, tOptHeader)

createCheckbox(tOptCard, "Hapus part asli setelah konversi", terrainOptions.deleteParts, 2, function(val)
	terrainOptions.deleteParts = val
end)

createCheckbox(tOptCard, "Cari part di dalam Model & Folder", terrainOptions.includeChildren, 3, function(val)
	terrainOptions.includeChildren = val
end)

createCheckbox(tOptCard, "Deteksi bentuk Wedge, Ball & Cylinder", terrainOptions.detectShapes, 4, function(val)
	terrainOptions.detectShapes = val
end)

-- Terrain Action Card
local tActCard, _ = createCard("TerrainActionCard", 3, terrainFrame)

local convertTerrainBtn = Instance.new("TextButton")
convertTerrainBtn.Name = "ConvertTerrainBtn"
convertTerrainBtn.Size = UDim2.new(1, 0, 0, 38)
convertTerrainBtn.Font = Enum.Font.SourceSansBold
convertTerrainBtn.TextSize = 14
convertTerrainBtn.Text = "⚡ KONVERSI KE TERRAIN"
convertTerrainBtn.BorderSizePixel = 0
convertTerrainBtn.LayoutOrder = 1
convertTerrainBtn.AutoButtonColor = true

local ctCorner = Instance.new("UICorner")
ctCorner.CornerRadius = UDim.new(0, 5)
ctCorner.Parent = convertTerrainBtn
convertTerrainBtn.Parent = tActCard

local undoTerrainBtn = Instance.new("TextButton")
undoTerrainBtn.Name = "UndoTerrainBtn"
undoTerrainBtn.Size = UDim2.new(1, 0, 0, 28)
undoTerrainBtn.Font = Enum.Font.SourceSansSemibold
undoTerrainBtn.TextSize = 12
undoTerrainBtn.Text = "↩ Undo (Batalkan Konversi)"
undoTerrainBtn.BorderSizePixel = 0
undoTerrainBtn.LayoutOrder = 2
undoTerrainBtn.AutoButtonColor = true

local utCorner = Instance.new("UICorner")
utCorner.CornerRadius = UDim.new(0, 4)
utCorner.Parent = undoTerrainBtn

local utStroke = Instance.new("UIStroke")
utStroke.Thickness = 1
utStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
utStroke.Parent = undoTerrainBtn
undoTerrainBtn.Parent = tActCard
table.insert(allButtons, undoTerrainBtn)
table.insert(allButtonStrokes, utStroke)

local tStatusLabel = Instance.new("TextLabel")
tStatusLabel.Name = "TerrainStatusLabel"
tStatusLabel.Size = UDim2.new(1, 0, 0, 36)
tStatusLabel.Font = Enum.Font.SourceSans
tStatusLabel.TextSize = 12
tStatusLabel.TextWrapped = true
tStatusLabel.Text = "Siap. Pilih satu atau beberapa part lalu klik Konversi ke Terrain."
tStatusLabel.BackgroundTransparency = 1
tStatusLabel.LayoutOrder = 3
tStatusLabel.Parent = tActCard
table.insert(allSubLabels, tStatusLabel)

-- ==============================================================================
-- 7. Tab 2: PART & UNION TO MESHPART CONTENT
-- ==============================================================================
local meshFrame = Instance.new("Frame")
meshFrame.Name = "MeshFrame"
meshFrame.Size = UDim2.new(1, 0, 0, 0)
meshFrame.AutomaticSize = Enum.AutomaticSize.Y
meshFrame.BackgroundTransparency = 1
meshFrame.Visible = false
meshFrame.LayoutOrder = 4
meshFrame.Parent = mainContainer

local mLayout = Instance.new("UIListLayout")
mLayout.Padding = UDim.new(0, 10)
mLayout.SortOrder = Enum.SortOrder.LayoutOrder
mLayout.Parent = meshFrame

-- Mode Penggabungan Card (Terpisah vs Gabung Jadi 1)
local mModeCard, _ = createCard("MeshCombineCard", 1, meshFrame)

local mModeHeader = Instance.new("TextLabel")
mModeHeader.Text = "HASIL KONVERSI (BANYAK PART / UNION)"
mModeHeader.Font = Enum.Font.SourceSansBold
mModeHeader.TextSize = 12
mModeHeader.TextXAlignment = Enum.TextXAlignment.Left
mModeHeader.Size = UDim2.new(1, 0, 0, 16)
mModeHeader.BackgroundTransparency = 1
mModeHeader.LayoutOrder = 1
mModeHeader.Parent = mModeCard
table.insert(allSubLabels, mModeHeader)

local combineRow = Instance.new("Frame")
combineRow.Name = "CombineRow"
combineRow.Size = UDim2.new(1, 0, 0, 30)
combineRow.BackgroundTransparency = 1
combineRow.LayoutOrder = 2
combineRow.Parent = mModeCard

local cRowLayout = Instance.new("UIListLayout")
cRowLayout.FillDirection = Enum.FillDirection.Horizontal
cRowLayout.Padding = UDim.new(0, 6)
cRowLayout.Parent = combineRow

local btnModeSeparate = Instance.new("TextButton")
btnModeSeparate.Name = "BtnModeSeparate"
btnModeSeparate.Size = UDim2.new(0.5, -3, 1, 0)
btnModeSeparate.Font = Enum.Font.SourceSansBold
btnModeSeparate.TextSize = 12
btnModeSeparate.Text = "🧱 Terpisah (Per Part)"
btnModeSeparate.BorderSizePixel = 0

local bmsCorner = Instance.new("UICorner")
bmsCorner.CornerRadius = UDim.new(0, 4)
bmsCorner.Parent = btnModeSeparate

local bmsStroke = Instance.new("UIStroke")
bmsStroke.Thickness = 1
bmsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
bmsStroke.Parent = btnModeSeparate
btnModeSeparate.Parent = combineRow

local btnModeCombine = Instance.new("TextButton")
btnModeCombine.Name = "BtnModeCombine"
btnModeCombine.Size = UDim2.new(0.5, -3, 1, 0)
btnModeCombine.Font = Enum.Font.SourceSansBold
btnModeCombine.TextSize = 12
btnModeCombine.Text = "🔗 Gabung Jadi 1 MeshPart"
btnModeCombine.BorderSizePixel = 0

local bmcCorner = Instance.new("UICorner")
bmcCorner.CornerRadius = UDim.new(0, 4)
bmcCorner.Parent = btnModeCombine

local bmcStroke = Instance.new("UIStroke")
bmcStroke.Thickness = 1
bmcStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
bmcStroke.Parent = btnModeCombine
btnModeCombine.Parent = combineRow

local combineDescLabel = Instance.new("TextLabel")
combineDescLabel.Name = "CombineDescLabel"
combineDescLabel.Text = "Mode Terpisah: Setiap part yang dipilih menjadi 1 MeshPart sendiri."
combineDescLabel.Font = Enum.Font.SourceSans
combineDescLabel.TextSize = 11
combineDescLabel.TextXAlignment = Enum.TextXAlignment.Left
combineDescLabel.Size = UDim2.new(1, 0, 0, 16)
combineDescLabel.BackgroundTransparency = 1
combineDescLabel.LayoutOrder = 3
combineDescLabel.Parent = mModeCard
table.insert(allSubLabels, combineDescLabel)

-- Mesh Source / Mode Card
local mSourceCard, _ = createCard("MeshSourceCard", 2, meshFrame)

local mSourceHeader = Instance.new("TextLabel")
mSourceHeader.Text = "SUMBER MESH & BENTUK"
mSourceHeader.Font = Enum.Font.SourceSansBold
mSourceHeader.TextSize = 12
mSourceHeader.TextXAlignment = Enum.TextXAlignment.Left
mSourceHeader.Size = UDim2.new(1, 0, 0, 16)
mSourceHeader.BackgroundTransparency = 1
mSourceHeader.LayoutOrder = 1
mSourceHeader.Parent = mSourceCard
table.insert(allSubLabels, mSourceHeader)

-- Mode Switch Buttons (Auto vs Custom)
local modeRow = Instance.new("Frame")
modeRow.Name = "ModeRow"
modeRow.Size = UDim2.new(1, 0, 0, 28)
modeRow.BackgroundTransparency = 1
modeRow.LayoutOrder = 2
modeRow.Parent = mSourceCard

local modeLayout = Instance.new("UIListLayout")
modeLayout.FillDirection = Enum.FillDirection.Horizontal
modeLayout.Padding = UDim.new(0, 6)
modeLayout.Parent = modeRow

local modeAutoBtn = Instance.new("TextButton")
modeAutoBtn.Name = "ModeAutoBtn"
modeAutoBtn.Size = UDim2.new(0.5, -3, 1, 0)
modeAutoBtn.Font = Enum.Font.SourceSansSemibold
modeAutoBtn.TextSize = 12
modeAutoBtn.Text = "● Auto (Part & Union)"
modeAutoBtn.BorderSizePixel = 0

local maCorner = Instance.new("UICorner")
maCorner.CornerRadius = UDim.new(0, 4)
maCorner.Parent = modeAutoBtn

local maStroke = Instance.new("UIStroke")
maStroke.Thickness = 1
maStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
maStroke.Parent = modeAutoBtn
modeAutoBtn.Parent = modeRow

local modeCustomBtn = Instance.new("TextButton")
modeCustomBtn.Name = "ModeCustomBtn"
modeCustomBtn.Size = UDim2.new(0.5, -3, 1, 0)
modeCustomBtn.Font = Enum.Font.SourceSansSemibold
modeCustomBtn.TextSize = 12
modeCustomBtn.Text = "○ Custom Mesh ID"
modeCustomBtn.BorderSizePixel = 0

local mcCorner = Instance.new("UICorner")
mcCorner.CornerRadius = UDim.new(0, 4)
mcCorner.Parent = modeCustomBtn

local mcStroke = Instance.new("UIStroke")
mcStroke.Thickness = 1
mcStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mcStroke.Parent = modeCustomBtn
modeCustomBtn.Parent = modeRow

-- Custom Mesh ID Input Box
local customMeshContainer = Instance.new("Frame")
customMeshContainer.Name = "CustomMeshContainer"
customMeshContainer.Size = UDim2.new(1, 0, 0, 0)
customMeshContainer.AutomaticSize = Enum.AutomaticSize.Y
customMeshContainer.BackgroundTransparency = 1
customMeshContainer.Visible = false
customMeshContainer.LayoutOrder = 3
customMeshContainer.Parent = mSourceCard

local cmLayout = Instance.new("UIListLayout")
cmLayout.Padding = UDim.new(0, 6)
cmLayout.Parent = customMeshContainer

local cmLabel = Instance.new("TextLabel")
cmLabel.Text = "Mesh ID atau URL Asset:"
cmLabel.Font = Enum.Font.SourceSans
cmLabel.TextSize = 12
cmLabel.TextXAlignment = Enum.TextXAlignment.Left
cmLabel.Size = UDim2.new(1, 0, 0, 14)
cmLabel.BackgroundTransparency = 1
cmLabel.Parent = customMeshContainer
table.insert(allSubLabels, cmLabel)

local customMeshInput = Instance.new("TextBox")
customMeshInput.Name = "CustomMeshInput"
customMeshInput.Size = UDim2.new(1, 0, 0, 28)
customMeshInput.Font = Enum.Font.SourceSans
customMeshInput.TextSize = 12
customMeshInput.PlaceholderText = "Contoh: rbxassetid://12345678 atau ID"
customMeshInput.Text = ""
customMeshInput.ClearTextOnFocus = false
customMeshInput.BorderSizePixel = 0
customMeshInput.Parent = customMeshContainer

local cmiCorner = Instance.new("UICorner")
cmiCorner.CornerRadius = UDim.new(0, 4)
cmiCorner.Parent = customMeshInput

local cmiStroke = Instance.new("UIStroke")
cmiStroke.Thickness = 1
cmiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
cmiStroke.Parent = customMeshInput
table.insert(allInputs, customMeshInput)
table.insert(allInputStrokes, cmiStroke)

customMeshInput.FocusLost:Connect(function()
	meshOptions.customMeshId = customMeshInput.Text
end)

local ctLabel = Instance.new("TextLabel")
ctLabel.Text = "Texture ID (Opsional):"
ctLabel.Font = Enum.Font.SourceSans
ctLabel.TextSize = 12
ctLabel.TextXAlignment = Enum.TextXAlignment.Left
ctLabel.Size = UDim2.new(1, 0, 0, 14)
ctLabel.BackgroundTransparency = 1
ctLabel.Parent = customMeshContainer
table.insert(allSubLabels, ctLabel)

local customTexInput = Instance.new("TextBox")
customTexInput.Name = "CustomTextureInput"
customTexInput.Size = UDim2.new(1, 0, 0, 28)
customTexInput.Font = Enum.Font.SourceSans
customTexInput.TextSize = 12
customTexInput.PlaceholderText = "Contoh: rbxassetid://12345678 (kosongkan jika tidak ada)"
customTexInput.Text = ""
customTexInput.ClearTextOnFocus = false
customTexInput.BorderSizePixel = 0
customTexInput.Parent = customMeshContainer

local ctiCorner = Instance.new("UICorner")
ctiCorner.CornerRadius = UDim.new(0, 4)
ctiCorner.Parent = customTexInput

local ctiStroke = Instance.new("UIStroke")
ctiStroke.Thickness = 1
ctiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ctiStroke.Parent = customTexInput
table.insert(allInputs, customTexInput)
table.insert(allInputStrokes, ctiStroke)

customTexInput.FocusLost:Connect(function()
	meshOptions.customTextureId = customTexInput.Text
end)

-- MeshPart Fidelity Settings Card
local mFidCard, _ = createCard("MeshFidelityCard", 3, meshFrame)

local mFidHeader = Instance.new("TextLabel")
mFidHeader.Text = "FIDELITY & KUALITAS COLLISION"
mFidHeader.Font = Enum.Font.SourceSansBold
mFidHeader.TextSize = 12
mFidHeader.TextXAlignment = Enum.TextXAlignment.Left
mFidHeader.Size = UDim2.new(1, 0, 0, 16)
mFidHeader.BackgroundTransparency = 1
mFidHeader.LayoutOrder = 1
mFidHeader.Parent = mFidCard
table.insert(allSubLabels, mFidHeader)

-- Collision Fidelity Dropdown
local colBtn = Instance.new("TextButton")
colBtn.Name = "ColFidelityBtn"
colBtn.Size = UDim2.new(1, 0, 0, 30)
colBtn.Font = Enum.Font.SourceSansSemibold
colBtn.TextSize = 12
colBtn.Text = "  Collision: " .. meshOptions.collisionFidelityName .. "  ▼"
colBtn.TextXAlignment = Enum.TextXAlignment.Left
colBtn.BorderSizePixel = 0
colBtn.LayoutOrder = 2

local colCorner = Instance.new("UICorner")
colCorner.CornerRadius = UDim.new(0, 4)
colCorner.Parent = colBtn

local colStroke = Instance.new("UIStroke")
colStroke.Thickness = 1
colStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
colStroke.Parent = colBtn
colBtn.Parent = mFidCard
table.insert(allInputs, colBtn)
table.insert(allInputStrokes, colStroke)

local colListFrame = Instance.new("Frame")
colListFrame.Name = "ColListFrame"
colListFrame.Size = UDim2.new(1, 0, 0, 0)
colListFrame.AutomaticSize = Enum.AutomaticSize.Y
colListFrame.BorderSizePixel = 0
colListFrame.Visible = false
colListFrame.LayoutOrder = 3

local clfCorner = Instance.new("UICorner")
clfCorner.CornerRadius = UDim.new(0, 4)
clfCorner.Parent = colListFrame

local clfStroke = Instance.new("UIStroke")
clfStroke.Thickness = 1
clfStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
clfStroke.Parent = colListFrame

local clfLayout = Instance.new("UIListLayout")
clfLayout.Padding = UDim.new(0, 2)
clfLayout.Parent = colListFrame

local clfPad = Instance.new("UIPadding")
clfPad.PaddingTop = UDim.new(0, 4)
clfPad.PaddingBottom = UDim.new(0, 4)
clfPad.PaddingLeft = UDim.new(0, 4)
clfPad.PaddingRight = UDim.new(0, 4)
clfPad.Parent = colListFrame
colListFrame.Parent = mFidCard
table.insert(allInputs, colListFrame)
table.insert(allInputStrokes, clfStroke)

colBtn.MouseButton1Click:Connect(function()
	colListFrame.Visible = not colListFrame.Visible
	colBtn.Text = "  Collision: " .. meshOptions.collisionFidelityName .. (colListFrame.Visible and "  ▲" or "  ▼")
end)

local colOptionsBtns = {}
for i, item in ipairs(COLLISION_OPTIONS) do
	local cBtn = Instance.new("TextButton")
	cBtn.Size = UDim2.new(1, 0, 0, 24)
	cBtn.Font = Enum.Font.SourceSans
	cBtn.TextSize = 12
	cBtn.Text = "  " .. item.name
	cBtn.TextXAlignment = Enum.TextXAlignment.Left
	cBtn.BorderSizePixel = 0
	cBtn.LayoutOrder = i

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 3)
	cCorner.Parent = cBtn

	cBtn.MouseButton1Click:Connect(function()
		meshOptions.collisionFidelity = item.value
		meshOptions.collisionFidelityName = item.name
		colBtn.Text = "  Collision: " .. meshOptions.collisionFidelityName .. "  ▼"
		colListFrame.Visible = false
	end)

	cBtn.Parent = colListFrame
	table.insert(colOptionsBtns, cBtn)
end

-- Render Fidelity Dropdown
local renBtn = Instance.new("TextButton")
renBtn.Name = "RenFidelityBtn"
renBtn.Size = UDim2.new(1, 0, 0, 30)
renBtn.Font = Enum.Font.SourceSansSemibold
renBtn.TextSize = 12
renBtn.Text = "  Render: " .. meshOptions.renderFidelityName .. "  ▼"
renBtn.TextXAlignment = Enum.TextXAlignment.Left
renBtn.BorderSizePixel = 0
renBtn.LayoutOrder = 4

local renCorner = Instance.new("UICorner")
renCorner.CornerRadius = UDim.new(0, 4)
renCorner.Parent = renBtn

local renStroke = Instance.new("UIStroke")
renStroke.Thickness = 1
renStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
renStroke.Parent = renBtn
renBtn.Parent = mFidCard
table.insert(allInputs, renBtn)
table.insert(allInputStrokes, renStroke)

local renListFrame = Instance.new("Frame")
renListFrame.Name = "RenListFrame"
renListFrame.Size = UDim2.new(1, 0, 0, 0)
renListFrame.AutomaticSize = Enum.AutomaticSize.Y
renListFrame.BorderSizePixel = 0
renListFrame.Visible = false
renListFrame.LayoutOrder = 5

local rlfCorner = Instance.new("UICorner")
rlfCorner.CornerRadius = UDim.new(0, 4)
rlfCorner.Parent = renListFrame

local rlfStroke = Instance.new("UIStroke")
rlfStroke.Thickness = 1
rlfStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
rlfStroke.Parent = renListFrame

local rlfLayout = Instance.new("UIListLayout")
rlfLayout.Padding = UDim.new(0, 2)
rlfLayout.Parent = renListFrame

local rlfPad = Instance.new("UIPadding")
rlfPad.PaddingTop = UDim.new(0, 4)
rlfPad.PaddingBottom = UDim.new(0, 4)
rlfPad.PaddingLeft = UDim.new(0, 4)
rlfPad.PaddingRight = UDim.new(0, 4)
rlfPad.Parent = renListFrame
renListFrame.Parent = mFidCard
table.insert(allInputs, renListFrame)
table.insert(allInputStrokes, rlfStroke)

renBtn.MouseButton1Click:Connect(function()
	renListFrame.Visible = not renListFrame.Visible
	renBtn.Text = "  Render: " .. meshOptions.renderFidelityName .. (renListFrame.Visible and "  ▲" or "  ▼")
end)

local renOptionsBtns = {}
for i, item in ipairs(RENDER_OPTIONS) do
	local rBtn = Instance.new("TextButton")
	rBtn.Size = UDim2.new(1, 0, 0, 24)
	rBtn.Font = Enum.Font.SourceSans
	rBtn.TextSize = 12
	rBtn.Text = "  " .. item.name
	rBtn.TextXAlignment = Enum.TextXAlignment.Left
	rBtn.BorderSizePixel = 0
	rBtn.LayoutOrder = i

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 3)
	rCorner.Parent = rBtn

	rBtn.MouseButton1Click:Connect(function()
		meshOptions.renderFidelity = item.value
		meshOptions.renderFidelityName = item.name
		renBtn.Text = "  Render: " .. meshOptions.renderFidelityName .. "  ▼"
		renListFrame.Visible = false
	end)

	rBtn.Parent = renListFrame
	table.insert(renOptionsBtns, rBtn)
end

-- Mesh Options Checkbox Card
local mOptCard, _ = createCard("MeshOptionsCard", 4, meshFrame)

local mOptHeader = Instance.new("TextLabel")
mOptHeader.Text = "PILIHAN MESHPART & UNION"
mOptHeader.Font = Enum.Font.SourceSansBold
mOptHeader.TextSize = 12
mOptHeader.TextXAlignment = Enum.TextXAlignment.Left
mOptHeader.Size = UDim2.new(1, 0, 0, 16)
mOptHeader.BackgroundTransparency = 1
mOptHeader.LayoutOrder = 1
mOptHeader.Parent = mOptCard
table.insert(allSubLabels, mOptHeader)

createCheckbox(mOptCard, "Dekonstruksi & Konversi UnionOperation", meshOptions.convertUnions, 2, function(val)
	meshOptions.convertUnions = val
end)

createCheckbox(mOptCard, "Hapus part / union asli setelah dikonversi", meshOptions.deleteParts, 3, function(val)
	meshOptions.deleteParts = val
end)

createCheckbox(mOptCard, "Cari di dalam Model & Folder", meshOptions.includeChildren, 4, function(val)
	meshOptions.includeChildren = val
end)

createCheckbox(mOptCard, "Transfer Children, Decal & Attachment", meshOptions.transferChildren, 5, function(val)
	meshOptions.transferChildren = val
end)

-- Bevel / Rounded Part Card
local mBevelCard, _ = createCard("MeshBevelCard", 5, meshFrame)

local mBevelHeader = Instance.new("TextLabel")
mBevelHeader.Text = "🔘 PENUMPUL SUDUT PART (BEVEL / ROUNDED BOX)"
mBevelHeader.Font = Enum.Font.SourceSansBold
mBevelHeader.TextSize = 12
mBevelHeader.TextXAlignment = Enum.TextXAlignment.Left
mBevelHeader.Size = UDim2.new(1, 0, 0, 16)
mBevelHeader.BackgroundTransparency = 1
mBevelHeader.LayoutOrder = 1
mBevelHeader.Parent = mBevelCard
table.insert(allSubLabels, mBevelHeader)

local mBevelDesc = Instance.new("TextLabel")
mBevelDesc.Text = "Tumpulkan sudut balok (Block) menjadi melengkung halus dengan geometri procedural."
mBevelDesc.Font = Enum.Font.SourceSans
mBevelDesc.TextSize = 11
mBevelDesc.TextXAlignment = Enum.TextXAlignment.Left
mBevelDesc.Size = UDim2.new(1, 0, 0, 26)
mBevelDesc.TextWrapped = true
mBevelDesc.BackgroundTransparency = 1
mBevelDesc.LayoutOrder = 2
mBevelDesc.Parent = mBevelCard
table.insert(allSubLabels, mBevelDesc)

-- Radius Setting Row
local bRadRow = Instance.new("Frame")
bRadRow.Name = "BevelRadiusRow"
bRadRow.Size = UDim2.new(1, 0, 0, 28)
bRadRow.BackgroundTransparency = 1
bRadRow.LayoutOrder = 3
bRadRow.Parent = mBevelCard

local brLayout = Instance.new("UIListLayout")
brLayout.FillDirection = Enum.FillDirection.Horizontal
brLayout.VerticalAlignment = Enum.VerticalAlignment.Center
brLayout.Padding = UDim.new(0, 8)
brLayout.Parent = bRadRow

local brLabel = Instance.new("TextLabel")
brLabel.Text = "Radius Tumpul (Studs):"
brLabel.Font = Enum.Font.SourceSansSemibold
brLabel.TextSize = 12
brLabel.Size = UDim2.new(0.6, -4, 1, 0)
brLabel.TextXAlignment = Enum.TextXAlignment.Left
brLabel.BackgroundTransparency = 1
brLabel.Parent = bRadRow
table.insert(allLabels, brLabel)

local bevelRadiusInput = Instance.new("TextBox")
bevelRadiusInput.Name = "BevelRadiusInput"
bevelRadiusInput.Size = UDim2.new(0.4, -4, 1, 0)
bevelRadiusInput.Font = Enum.Font.SourceSans
bevelRadiusInput.TextSize = 12
bevelRadiusInput.Text = tostring(meshOptions.bevelRadius)
bevelRadiusInput.PlaceholderText = "0.4"
bevelRadiusInput.ClearTextOnFocus = false
bevelRadiusInput.BorderSizePixel = 0

local briCorner = Instance.new("UICorner")
briCorner.CornerRadius = UDim.new(0, 4)
briCorner.Parent = bevelRadiusInput

local briStroke = Instance.new("UIStroke")
briStroke.Thickness = 1
briStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
briStroke.Parent = bevelRadiusInput

bevelRadiusInput.Parent = bRadRow
table.insert(allInputs, bevelRadiusInput)
table.insert(allInputStrokes, briStroke)

bevelRadiusInput.FocusLost:Connect(function()
	local num = tonumber(bevelRadiusInput.Text)
	if num and num > 0 then
		meshOptions.bevelRadius = math.clamp(num, 0.05, 50)
		bevelRadiusInput.Text = tostring(meshOptions.bevelRadius)
	else
		bevelRadiusInput.Text = tostring(meshOptions.bevelRadius)
	end
end)

-- Segments Row
local bSegLabel = Instance.new("TextLabel")
bSegLabel.Text = "Kehalusan Lengkungan Sudut:"
bSegLabel.Font = Enum.Font.SourceSansSemibold
bSegLabel.TextSize = 12
bSegLabel.Size = UDim2.new(1, 0, 0, 16)
bSegLabel.TextXAlignment = Enum.TextXAlignment.Left
bSegLabel.BackgroundTransparency = 1
bSegLabel.LayoutOrder = 4
bSegLabel.Parent = mBevelCard
table.insert(allLabels, bSegLabel)

local bSegRow = Instance.new("Frame")
bSegRow.Name = "BevelSegRow"
bSegRow.Size = UDim2.new(1, 0, 0, 26)
bSegRow.BackgroundTransparency = 1
bSegRow.LayoutOrder = 5
bSegRow.Parent = mBevelCard

local bsLayout = Instance.new("UIListLayout")
bsLayout.FillDirection = Enum.FillDirection.Horizontal
bsLayout.Padding = UDim.new(0, 4)
bsLayout.Parent = bSegRow

btnSeg1 = Instance.new("TextButton")
btnSeg1.Name = "BtnSeg1"
btnSeg1.Size = UDim2.new(0.33, -3, 1, 0)
btnSeg1.Font = Enum.Font.SourceSansSemibold
btnSeg1.TextSize = 11
btnSeg1.Text = "1 (Chamfer 45°)"
btnSeg1.BorderSizePixel = 0
local s1Corner = Instance.new("UICorner")
s1Corner.CornerRadius = UDim.new(0, 4)
s1Corner.Parent = btnSeg1
bs1Stroke = Instance.new("UIStroke")
bs1Stroke.Thickness = 1
bs1Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
bs1Stroke.Parent = btnSeg1
btnSeg1.Parent = bSegRow

btnSeg2 = Instance.new("TextButton")
btnSeg2.Name = "BtnSeg2"
btnSeg2.Size = UDim2.new(0.33, -3, 1, 0)
btnSeg2.Font = Enum.Font.SourceSansSemibold
btnSeg2.TextSize = 11
btnSeg2.Text = "2 (Halus)"
btnSeg2.BorderSizePixel = 0
local s2Corner = Instance.new("UICorner")
s2Corner.CornerRadius = UDim.new(0, 4)
s2Corner.Parent = btnSeg2
bs2Stroke = Instance.new("UIStroke")
bs2Stroke.Thickness = 1
bs2Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
bs2Stroke.Parent = btnSeg2
btnSeg2.Parent = bSegRow

btnSeg3 = Instance.new("TextButton")
btnSeg3.Name = "BtnSeg3"
btnSeg3.Size = UDim2.new(0.34, -2, 1, 0)
btnSeg3.Font = Enum.Font.SourceSansSemibold
btnSeg3.TextSize = 11
btnSeg3.Text = "3 (Sangat Halus)"
btnSeg3.BorderSizePixel = 0
local s3Corner = Instance.new("UICorner")
s3Corner.CornerRadius = UDim.new(0, 4)
s3Corner.Parent = btnSeg3
bs3Stroke = Instance.new("UIStroke")
bs3Stroke.Thickness = 1
bs3Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
bs3Stroke.Parent = btnSeg3
btnSeg3.Parent = bSegRow

btnSeg1.MouseButton1Click:Connect(function()
	meshOptions.bevelSegments = 1
	applyMonochromeTheme()
end)

btnSeg2.MouseButton1Click:Connect(function()
	meshOptions.bevelSegments = 2
	applyMonochromeTheme()
end)

btnSeg3.MouseButton1Click:Connect(function()
	meshOptions.bevelSegments = 3
	applyMonochromeTheme()
end)

createCheckbox(mBevelCard, "Terapkan sudut tumpul saat konversi MeshPart biasa", meshOptions.bevelEnabled, 6, function(val)
	meshOptions.bevelEnabled = val
end)

btnBevelAction = Instance.new("TextButton")
btnBevelAction.Name = "BtnBevelAction"
btnBevelAction.Size = UDim2.new(1, 0, 0, 36)
btnBevelAction.Font = Enum.Font.SourceSansBold
btnBevelAction.TextSize = 12
btnBevelAction.Text = "🔘 TUMPULKAN SUDUT PART TERPILIH (BEVEL)"
btnBevelAction.BorderSizePixel = 0
btnBevelAction.LayoutOrder = 7
btnBevelAction.AutoButtonColor = true

local bbaCorner = Instance.new("UICorner")
bbaCorner.CornerRadius = UDim.new(0, 5)
bbaCorner.Parent = btnBevelAction
btnBevelAction.Parent = mBevelCard

btnBevelAction.MouseButton1Click:Connect(function()
	if executeBevelParts then
		executeBevelParts()
	end
end)

-- Mesh Action Card
local mActCard, _ = createCard("MeshActionCard", 6, meshFrame)

local convertMeshBtn = Instance.new("TextButton")
convertMeshBtn.Name = "ConvertMeshBtn"
convertMeshBtn.Size = UDim2.new(1, 0, 0, 38)
convertMeshBtn.Font = Enum.Font.SourceSansBold
convertMeshBtn.TextSize = 13
convertMeshBtn.Text = "⚡ KONVERSI KE MESHPART TERPISAH"
convertMeshBtn.BorderSizePixel = 0
convertMeshBtn.LayoutOrder = 1
convertMeshBtn.AutoButtonColor = true

local cmCorner = Instance.new("UICorner")
cmCorner.CornerRadius = UDim.new(0, 5)
cmCorner.Parent = convertMeshBtn
convertMeshBtn.Parent = mActCard

local undoMeshBtn = Instance.new("TextButton")
undoMeshBtn.Name = "UndoMeshBtn"
undoMeshBtn.Size = UDim2.new(1, 0, 0, 28)
undoMeshBtn.Font = Enum.Font.SourceSansSemibold
undoMeshBtn.TextSize = 12
undoMeshBtn.Text = "↩ Undo (Batalkan Konversi)"
undoMeshBtn.BorderSizePixel = 0
undoMeshBtn.LayoutOrder = 2
undoMeshBtn.AutoButtonColor = true

local umCorner = Instance.new("UICorner")
umCorner.CornerRadius = UDim.new(0, 4)
umCorner.Parent = undoMeshBtn

local umStroke = Instance.new("UIStroke")
umStroke.Thickness = 1
umStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
umStroke.Parent = undoMeshBtn
undoMeshBtn.Parent = mActCard
table.insert(allButtons, undoMeshBtn)
table.insert(allButtonStrokes, umStroke)

-- Quick CSG Row in Mesh Tab
local mQuickCsgRow = Instance.new("Frame")
mQuickCsgRow.Name = "QuickCsgRow"
mQuickCsgRow.Size = UDim2.new(1, 0, 0, 26)
mQuickCsgRow.BackgroundTransparency = 1
mQuickCsgRow.LayoutOrder = 3
mQuickCsgRow.Parent = mActCard

local mqLayout = Instance.new("UIListLayout")
mqLayout.FillDirection = Enum.FillDirection.Horizontal
mqLayout.Padding = UDim.new(0, 6)
mqLayout.Parent = mQuickCsgRow

local qNegateBtn = Instance.new("TextButton")
qNegateBtn.Name = "QNegateBtn"
qNegateBtn.Size = UDim2.new(0.5, -3, 1, 0)
qNegateBtn.Font = Enum.Font.SourceSansSemibold
qNegateBtn.TextSize = 11
qNegateBtn.Text = "➖ Negate Part"
qNegateBtn.BorderSizePixel = 0

local qnCorner = Instance.new("UICorner")
qnCorner.CornerRadius = UDim.new(0, 4)
qnCorner.Parent = qNegateBtn

local qnStroke = Instance.new("UIStroke")
qnStroke.Thickness = 1
qnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
qnStroke.Parent = qNegateBtn
qNegateBtn.Parent = mQuickCsgRow
table.insert(allButtons, qNegateBtn)
table.insert(allButtonStrokes, qnStroke)

local qUnionBtn = Instance.new("TextButton")
qUnionBtn.Name = "QUnionBtn"
qUnionBtn.Size = UDim2.new(0.5, -3, 1, 0)
qUnionBtn.Font = Enum.Font.SourceSansSemibold
qUnionBtn.TextSize = 11
qUnionBtn.Text = "➕ Union Parts"
qUnionBtn.BorderSizePixel = 0

local quCorner = Instance.new("UICorner")
quCorner.CornerRadius = UDim.new(0, 4)
quCorner.Parent = qUnionBtn

local quStroke = Instance.new("UIStroke")
quStroke.Thickness = 1
quStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
quStroke.Parent = qUnionBtn
qUnionBtn.Parent = mQuickCsgRow
table.insert(allButtons, qUnionBtn)
table.insert(allButtonStrokes, quStroke)

qNegateBtn.MouseButton1Click:Connect(function()
	if executeNegateParts then
		executeNegateParts()
	end
end)

qUnionBtn.MouseButton1Click:Connect(function()
	if executeUnionParts then
		executeUnionParts()
	end
end)

local mStatusLabel = Instance.new("TextLabel")
mStatusLabel.Name = "MeshStatusLabel"
mStatusLabel.Size = UDim2.new(1, 0, 0, 36)
mStatusLabel.Font = Enum.Font.SourceSans
mStatusLabel.TextSize = 12
mStatusLabel.TextWrapped = true
mStatusLabel.Text = "Siap. Pilih satu atau beberapa part/union lalu klik Konversi."
mStatusLabel.BackgroundTransparency = 1
mStatusLabel.LayoutOrder = 4
mStatusLabel.Parent = mActCard
table.insert(allSubLabels, mStatusLabel)

-- ==============================================================================
-- 7.3. Tab 3: CSG TOOLS CONTENT (UNION & NEGATE)
-- ==============================================================================
local csgFrame = Instance.new("Frame")
csgFrame.Name = "CsgFrame"
csgFrame.Size = UDim2.new(1, 0, 0, 0)
csgFrame.AutomaticSize = Enum.AutomaticSize.Y
csgFrame.BackgroundTransparency = 1
csgFrame.LayoutOrder = 5
csgFrame.Visible = false
csgFrame.Parent = mainContainer

local csgLayout = Instance.new("UIListLayout")
csgLayout.Padding = UDim.new(0, 10)
csgLayout.SortOrder = Enum.SortOrder.LayoutOrder
csgLayout.Parent = csgFrame

-- 1. Main Action Card
local csgActCard, _ = createCard("CsgActionCard", 1, csgFrame)

local csgActHeader = Instance.new("TextLabel")
csgActHeader.Text = "OPERASI UTAMA CSG (UNION & NEGATE)"
csgActHeader.Font = Enum.Font.SourceSansBold
csgActHeader.TextSize = 12
csgActHeader.TextXAlignment = Enum.TextXAlignment.Left
csgActHeader.Size = UDim2.new(1, 0, 0, 16)
csgActHeader.BackgroundTransparency = 1
csgActHeader.LayoutOrder = 1
csgActHeader.Parent = csgActCard
table.insert(allSubLabels, csgActHeader)

-- Negate Button
local btnNegate = Instance.new("TextButton")
btnNegate.Name = "BtnNegate"
btnNegate.Size = UDim2.new(1, 0, 0, 36)
btnNegate.Font = Enum.Font.SourceSansBold
btnNegate.TextSize = 13
btnNegate.Text = "➖ NEGATE PART (UBAH KE NEGATIF / POSITIF)"
btnNegate.BorderSizePixel = 0
btnNegate.AutoButtonColor = true
btnNegate.LayoutOrder = 2

local bnCorner = Instance.new("UICorner")
bnCorner.CornerRadius = UDim.new(0, 5)
bnCorner.Parent = btnNegate
btnNegate.Parent = csgActCard

local negateDescLabel = Instance.new("TextLabel")
negateDescLabel.Name = "NegateDesc"
negateDescLabel.Size = UDim2.new(1, 0, 0, 26)
negateDescLabel.Font = Enum.Font.SourceSans
negateDescLabel.TextSize = 11
negateDescLabel.TextWrapped = true
negateDescLabel.TextXAlignment = Enum.TextXAlignment.Left
negateDescLabel.Text = "Ubah part menjadi NegateOperation transparan kemerahan untuk memotong/melubangi objek lain (klik lagi untuk mengembalikan)."
negateDescLabel.BackgroundTransparency = 1
negateDescLabel.LayoutOrder = 3
negateDescLabel.Parent = csgActCard
table.insert(allSubLabels, negateDescLabel)

-- Union Button
local btnUnion = Instance.new("TextButton")
btnUnion.Name = "BtnUnion"
btnUnion.Size = UDim2.new(1, 0, 0, 36)
btnUnion.Font = Enum.Font.SourceSansBold
btnUnion.TextSize = 13
btnUnion.Text = "➕ UNION PARTS (GABUNG JADI 1 UNION)"
btnUnion.BorderSizePixel = 0
btnUnion.AutoButtonColor = true
btnUnion.LayoutOrder = 4

local buCorner = Instance.new("UICorner")
buCorner.CornerRadius = UDim.new(0, 5)
buCorner.Parent = btnUnion
btnUnion.Parent = csgActCard

local unionDescLabel = Instance.new("TextLabel")
unionDescLabel.Name = "UnionDesc"
unionDescLabel.Size = UDim2.new(1, 0, 0, 26)
unionDescLabel.Font = Enum.Font.SourceSans
unionDescLabel.TextSize = 11
unionDescLabel.TextWrapped = true
unionDescLabel.TextXAlignment = Enum.TextXAlignment.Left
unionDescLabel.Text = "Gabungkan part terpilih (dan part negatif pemotong) menjadi 1 UnionOperation solid."
unionDescLabel.BackgroundTransparency = 1
unionDescLabel.LayoutOrder = 5
unionDescLabel.Parent = csgActCard
table.insert(allSubLabels, unionDescLabel)

-- Secondary Action Row (Separate & Convert to MeshPart)
local csgSecRow = Instance.new("Frame")
csgSecRow.Name = "CsgSecRow"
csgSecRow.Size = UDim2.new(1, 0, 0, 28)
csgSecRow.BackgroundTransparency = 1
csgSecRow.LayoutOrder = 6
csgSecRow.Parent = csgActCard

local csrLayout = Instance.new("UIListLayout")
csrLayout.FillDirection = Enum.FillDirection.Horizontal
csrLayout.Padding = UDim.new(0, 6)
csrLayout.Parent = csgSecRow

local btnSeparate = Instance.new("TextButton")
btnSeparate.Name = "BtnSeparate"
btnSeparate.Size = UDim2.new(0.5, -3, 1, 0)
btnSeparate.Font = Enum.Font.SourceSansSemibold
btnSeparate.TextSize = 11
btnSeparate.Text = "✂️ Pisahkan (Separate)"
btnSeparate.BorderSizePixel = 0
btnSeparate.AutoButtonColor = true

local sepCorner = Instance.new("UICorner")
sepCorner.CornerRadius = UDim.new(0, 4)
sepCorner.Parent = btnSeparate

local sepStroke = Instance.new("UIStroke")
sepStroke.Thickness = 1
sepStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
sepStroke.Parent = btnSeparate
btnSeparate.Parent = csgSecRow
table.insert(allButtons, btnSeparate)
table.insert(allButtonStrokes, sepStroke)

local btnUnionToMesh = Instance.new("TextButton")
btnUnionToMesh.Name = "BtnUnionToMesh"
btnUnionToMesh.Size = UDim2.new(0.5, -3, 1, 0)
btnUnionToMesh.Font = Enum.Font.SourceSansSemibold
btnUnionToMesh.TextSize = 11
btnUnionToMesh.Text = "🔷 Convert ke MeshPart"
btnUnionToMesh.BorderSizePixel = 0
btnUnionToMesh.AutoButtonColor = true

local utmCorner = Instance.new("UICorner")
utmCorner.CornerRadius = UDim.new(0, 4)
utmCorner.Parent = btnUnionToMesh

local utmStroke = Instance.new("UIStroke")
utmStroke.Thickness = 1
utmStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
utmStroke.Parent = btnUnionToMesh
btnUnionToMesh.Parent = csgSecRow
table.insert(allButtons, btnUnionToMesh)
table.insert(allButtonStrokes, utmStroke)

local csgStatusLabel = Instance.new("TextLabel")
csgStatusLabel.Name = "CsgStatusLabel"
csgStatusLabel.Size = UDim2.new(1, 0, 0, 36)
csgStatusLabel.Font = Enum.Font.SourceSans
csgStatusLabel.TextSize = 12
csgStatusLabel.TextWrapped = true
csgStatusLabel.Text = "Siap. Pilih part lalu klik Negate atau Union."
csgStatusLabel.BackgroundTransparency = 1
csgStatusLabel.LayoutOrder = 7
csgStatusLabel.Parent = csgActCard
table.insert(allSubLabels, csgStatusLabel)

-- 2. CSG Options Card
local csgOptCard, _ = createCard("CsgOptionsCard", 2, csgFrame)

local csgOptHeader = Instance.new("TextLabel")
csgOptHeader.Text = "PILIHAN CSG & FIDELITY"
csgOptHeader.Font = Enum.Font.SourceSansBold
csgOptHeader.TextSize = 12
csgOptHeader.TextXAlignment = Enum.TextXAlignment.Left
csgOptHeader.Size = UDim2.new(1, 0, 0, 16)
csgOptHeader.BackgroundTransparency = 1
csgOptHeader.LayoutOrder = 1
csgOptHeader.Parent = csgOptCard
table.insert(allSubLabels, csgOptHeader)

createCheckbox(csgOptCard, "Pilih otomatis hasil Union / Negate di Explorer", csgOptions.autoSelect, 2, function(val)
	csgOptions.autoSelect = val
end)

createCheckbox(csgOptCard, "Cari di dalam Model & Folder", csgOptions.includeChildren, 3, function(val)
	csgOptions.includeChildren = val
	if updateSelectionCounter then
		updateSelectionCounter()
	end
end)

createCheckbox(csgOptCard, "Beri nama rapi pada Union hasil (_Union)", csgOptions.preserveName, 4, function(val)
	csgOptions.preserveName = val
end)

-- 3. CSG Quick Guide Card
local csgGuideCard, _ = createCard("CsgGuideCard", 3, csgFrame)

local csgGuideHeader = Instance.new("TextLabel")
csgGuideHeader.Text = "💡 PANDUAN CEPAT MEMBUAT LUBANG / POTONGAN"
csgGuideHeader.Font = Enum.Font.SourceSansBold
csgGuideHeader.TextSize = 12
csgGuideHeader.TextXAlignment = Enum.TextXAlignment.Left
csgGuideHeader.Size = UDim2.new(1, 0, 0, 16)
csgGuideHeader.BackgroundTransparency = 1
csgGuideHeader.LayoutOrder = 1
csgGuideHeader.Parent = csgGuideCard
table.insert(allSubLabels, csgGuideHeader)

local csgGuideText = Instance.new("TextLabel")
csgGuideText.Name = "CsgGuideText"
csgGuideText.Size = UDim2.new(1, 0, 0, 68)
csgGuideText.Font = Enum.Font.SourceSans
csgGuideText.TextSize = 12
csgGuideText.TextWrapped = true
csgGuideText.TextXAlignment = Enum.TextXAlignment.Left
csgGuideText.Text = "1. Buat Part pemotong (misal Cylinder), posisikan menembus Part utama.\n2. Pilih Part pemotong lalu klik '➖ Negate Part'.\n3. Pilih Part utama bersamaan dengan Part negatif tadi.\n4. Klik '➕ Union Parts' untuk menghasilkan potongan/lubang solid!"
csgGuideText.BackgroundTransparency = 1
csgGuideText.LayoutOrder = 2
csgGuideText.Parent = csgGuideCard
table.insert(allSubLabels, csgGuideText)

-- ==============================================================================
-- 7.5. Tab 4: SCRIPT OBFUSCATOR CONTENT
-- ==============================================================================
local obfFrame = Instance.new("Frame")
obfFrame.Name = "ObfFrame"
obfFrame.Size = UDim2.new(1, 0, 0, 0)
obfFrame.AutomaticSize = Enum.AutomaticSize.Y
obfFrame.BackgroundTransparency = 1
obfFrame.LayoutOrder = 6
obfFrame.Visible = false
obfFrame.Parent = mainContainer

local obfLayout = Instance.new("UIListLayout")
obfLayout.Padding = UDim.new(0, 10)
obfLayout.SortOrder = Enum.SortOrder.LayoutOrder
obfLayout.Parent = obfFrame

-- 1. Preset Card
local oPresetCard, _ = createCard("ObfPresetCard", 1, obfFrame)

local oPresetHeader = Instance.new("TextLabel")
oPresetHeader.Text = "LEVEL OBFUSKASI (PRESET)"
oPresetHeader.Font = Enum.Font.SourceSansBold
oPresetHeader.TextSize = 12
oPresetHeader.TextXAlignment = Enum.TextXAlignment.Left
oPresetHeader.Size = UDim2.new(1, 0, 0, 16)
oPresetHeader.BackgroundTransparency = 1
oPresetHeader.LayoutOrder = 1
oPresetHeader.Parent = oPresetCard
table.insert(allSubLabels, oPresetHeader)

local oPresetRow = Instance.new("Frame")
oPresetRow.Name = "PresetRow"
oPresetRow.Size = UDim2.new(1, 0, 0, 28)
oPresetRow.BackgroundTransparency = 1
oPresetRow.LayoutOrder = 2
oPresetRow.Parent = oPresetCard

local oprLayout = Instance.new("UIListLayout")
oprLayout.FillDirection = Enum.FillDirection.Horizontal
oprLayout.Padding = UDim.new(0, 4)
oprLayout.Parent = oPresetRow

local function createPresetButton(name, text, widthFrac)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(widthFrac, -3, 1, 0)
	btn.Font = Enum.Font.SourceSansSemibold
	btn.TextSize = 11
	btn.Text = text
	btn.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = btn
	btn.Parent = oPresetRow

	return btn, stroke
end

local btnPresetExtreme, bpeStroke = createPresetButton("BtnPresetExtreme", "● Ekstrem", 0.35)
local btnPresetStandard, bpsStroke = createPresetButton("BtnPresetStandard", "○ Standar", 0.33)
local btnPresetMinify, bpmStroke = createPresetButton("BtnPresetMinify", "○ Minify Saja", 0.32)

local oPresetDescLabel = Instance.new("TextLabel")
oPresetDescLabel.Name = "PresetDescLabel"
oPresetDescLabel.Size = UDim2.new(1, 0, 0, 32)
oPresetDescLabel.Font = Enum.Font.SourceSans
oPresetDescLabel.TextSize = 11
oPresetDescLabel.TextWrapped = true
oPresetDescLabel.TextXAlignment = Enum.TextXAlignment.Left
oPresetDescLabel.Text = "Ekstrem: Enkripsi String XOR Multibyte, Barcode Mangling (_Il11..), Mutasi Angka Hex & Junk Logic (Anti-Baca)."
oPresetDescLabel.BackgroundTransparency = 1
oPresetDescLabel.LayoutOrder = 3
oPresetDescLabel.Parent = oPresetCard
table.insert(allSubLabels, oPresetDescLabel)

-- 2. Protection Features Card
local oFeatCard, _ = createCard("ObfFeaturesCard", 2, obfFrame)

local oFeatHeader = Instance.new("TextLabel")
oFeatHeader.Text = "PILIHAN & FITUR PROTEKSI"
oFeatHeader.Font = Enum.Font.SourceSansBold
oFeatHeader.TextSize = 12
oFeatHeader.TextXAlignment = Enum.TextXAlignment.Left
oFeatHeader.Size = UDim2.new(1, 0, 0, 16)
oFeatHeader.BackgroundTransparency = 1
oFeatHeader.LayoutOrder = 1
oFeatHeader.Parent = oFeatCard
table.insert(allSubLabels, oFeatHeader)

local updateSelectionCounter -- forward declaration

local _, _, _, mStr, _ = createCheckbox(oFeatCard, "Enkripsi String (XOR Multibyte Table)", obfOptions.encryptStrings, 2, function(val)
	obfOptions.encryptStrings = val
end)

local _, _, _, mMangle, _ = createCheckbox(oFeatCard, "Barcode Mangling (_Il11II... Identifiers)", obfOptions.mangleVars, 3, function(val)
	obfOptions.mangleVars = val
end)

local _, _, _, mNum, _ = createCheckbox(oFeatCard, "Mutasi Angka (Hexadecimal Arithmetic)", obfOptions.mutateNumbers, 4, function(val)
	obfOptions.mutateNumbers = val
end)

local _, _, _, mOpaque, _ = createCheckbox(oFeatCard, "Opaque Predicates (Junk Logic Anti-Read)", obfOptions.opaquePredicates, 5, function(val)
	obfOptions.opaquePredicates = val
end)

local _, _, _, mMin, _ = createCheckbox(oFeatCard, "Minify & Hapus Semua Komentar", obfOptions.minify, 6, function(val)
	obfOptions.minify = val
end)

local _, _, _, mBak, _ = createCheckbox(oFeatCard, "Auto-Backup Script Asli Sebelum Obfuscate", obfOptions.autoBackup, 7, function(val)
	obfOptions.autoBackup = val
end)

local _, _, _, mInc, _ = createCheckbox(oFeatCard, "Cari Script di dalam Model & Folder", obfOptions.includeChildren, 8, function(val)
	obfOptions.includeChildren = val
	if updateSelectionCounter then
		updateSelectionCounter()
	end
end)

-- 3. Obfuscation Action Card
local oActCard, _ = createCard("ObfActionCard", 3, obfFrame)

local convertObfBtn = Instance.new("TextButton")
convertObfBtn.Name = "ConvertObfBtn"
convertObfBtn.Size = UDim2.new(1, 0, 0, 38)
convertObfBtn.Font = Enum.Font.SourceSansBold
convertObfBtn.TextSize = 13
convertObfBtn.Text = "⚡ OBFUSCATE SCRIPT TERPILIH"
convertObfBtn.BorderSizePixel = 0
convertObfBtn.AutoButtonColor = true
convertObfBtn.LayoutOrder = 1

local cobCorner = Instance.new("UICorner")
cobCorner.CornerRadius = UDim.new(0, 5)
cobCorner.Parent = convertObfBtn
convertObfBtn.Parent = oActCard

-- Secondary action row (Restore Backup & Preview)
local oSecRow = Instance.new("Frame")
oSecRow.Name = "SecRow"
oSecRow.Size = UDim2.new(1, 0, 0, 26)
oSecRow.BackgroundTransparency = 1
oSecRow.LayoutOrder = 2
oSecRow.Parent = oActCard

local oSecLayout = Instance.new("UIListLayout")
oSecLayout.FillDirection = Enum.FillDirection.Horizontal
oSecLayout.Padding = UDim.new(0, 6)
oSecLayout.Parent = oSecRow

local restoreBackupBtn = Instance.new("TextButton")
restoreBackupBtn.Name = "RestoreBackupBtn"
restoreBackupBtn.Size = UDim2.new(0.5, -3, 1, 0)
restoreBackupBtn.Font = Enum.Font.SourceSansSemibold
restoreBackupBtn.TextSize = 11
restoreBackupBtn.Text = "↩ Pulihkan Backup"
restoreBackupBtn.BorderSizePixel = 0
restoreBackupBtn.AutoButtonColor = true

local rbbCorner = Instance.new("UICorner")
rbbCorner.CornerRadius = UDim.new(0, 4)
rbbCorner.Parent = restoreBackupBtn

local rbbStroke = Instance.new("UIStroke")
rbbStroke.Thickness = 1
rbbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
rbbStroke.Parent = restoreBackupBtn
restoreBackupBtn.Parent = oSecRow
table.insert(allButtons, restoreBackupBtn)
table.insert(allButtonStrokes, rbbStroke)

local previewObfBtn = Instance.new("TextButton")
previewObfBtn.Name = "PreviewObfBtn"
previewObfBtn.Size = UDim2.new(0.5, -3, 1, 0)
previewObfBtn.Font = Enum.Font.SourceSansSemibold
previewObfBtn.TextSize = 11
previewObfBtn.Text = "📋 Pratinjau di Output"
previewObfBtn.BorderSizePixel = 0
previewObfBtn.AutoButtonColor = true

local pobCorner = Instance.new("UICorner")
pobCorner.CornerRadius = UDim.new(0, 4)
pobCorner.Parent = previewObfBtn

local pobStroke = Instance.new("UIStroke")
pobStroke.Thickness = 1
pobStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
pobStroke.Parent = previewObfBtn
previewObfBtn.Parent = oSecRow
table.insert(allButtons, previewObfBtn)
table.insert(allButtonStrokes, pobStroke)

local oStatusLabel = Instance.new("TextLabel")
oStatusLabel.Name = "ObfStatusLabel"
oStatusLabel.Size = UDim2.new(1, 0, 0, 36)
oStatusLabel.Font = Enum.Font.SourceSans
oStatusLabel.TextSize = 12
oStatusLabel.TextWrapped = true
oStatusLabel.Text = "Siap. Pilih Script, LocalScript, atau ModuleScript lalu klik Obfuscate."
oStatusLabel.BackgroundTransparency = 1
oStatusLabel.LayoutOrder = 3
oStatusLabel.Parent = oActCard
table.insert(allSubLabels, oStatusLabel)

-- ==============================================================================
-- 8. Dynamic Theme Application (Hitam Putih / Monochrome)
-- ==============================================================================
local function applyMonochromeTheme()
	local pal = getMonochromePalette()

	mainContainer.BackgroundColor3 = pal.mainBg

	for _, c in ipairs(allCards) do
		c.BackgroundColor3 = pal.cardBg
	end
	for _, s in ipairs(allStrokes) do
		s.Color = pal.cardBorder
	end

	for _, l in ipairs(allLabels) do
		l.TextColor3 = pal.primaryText
	end
	for _, sl in ipairs(allSubLabels) do
		sl.TextColor3 = pal.secondaryText
	end

	for _, inp in ipairs(allInputs) do
		inp.BackgroundColor3 = pal.inputBg
		if inp:IsA("TextBox") or inp:IsA("TextButton") then
			inp.TextColor3 = pal.primaryText
		end
		if inp:IsA("TextBox") then
			inp.PlaceholderColor3 = pal.dimText
		end
	end
	for _, is in ipairs(allInputStrokes) do
		is.Color = pal.inputBorder
	end

	for _, b in ipairs(allButtons) do
		b.BackgroundColor3 = pal.btnSecondaryBg
		b.TextColor3 = pal.btnSecondaryText
	end
	for _, bs in ipairs(allButtonStrokes) do
		bs.Color = pal.btnSecondaryBorder
	end

	for _, mBtn in ipairs(materialButtons) do
		mBtn.BackgroundColor3 = pal.inputBg
		mBtn.TextColor3 = pal.primaryText
	end
	for _, cBtn in ipairs(colOptionsBtns) do
		cBtn.BackgroundColor3 = pal.inputBg
		cBtn.TextColor3 = pal.primaryText
	end
	for _, rBtn in ipairs(renOptionsBtns) do
		rBtn.BackgroundColor3 = pal.inputBg
		rBtn.TextColor3 = pal.primaryText
	end

	for _, cb in ipairs(allCheckboxes) do
		cb.box.BackgroundColor3 = pal.inputBg
		cb.stroke.Color = pal.inputBorder
		cb.mark.TextColor3 = pal.checkMark
		cb.label.TextColor3 = pal.primaryText
	end

	-- Primary Action Buttons: High-Contrast Pure Inversion
	convertTerrainBtn.BackgroundColor3 = pal.btnPrimaryBg
	convertTerrainBtn.TextColor3 = pal.btnPrimaryText
	convertMeshBtn.BackgroundColor3 = pal.btnPrimaryBg
	convertMeshBtn.TextColor3 = pal.btnPrimaryText
	convertObfBtn.BackgroundColor3 = pal.btnPrimaryBg
	convertObfBtn.TextColor3 = pal.btnPrimaryText
	btnNegate.BackgroundColor3 = pal.btnPrimaryBg
	btnNegate.TextColor3 = pal.btnPrimaryText
	btnUnion.BackgroundColor3 = pal.btnPrimaryBg
	btnUnion.TextColor3 = pal.btnPrimaryText
	if btnBevelAction then
		btnBevelAction.BackgroundColor3 = pal.btnPrimaryBg
		btnBevelAction.TextColor3 = pal.btnPrimaryText
	end

	-- Tab Buttons Styling (4 Tabs: Terrain, MeshPart, CSG, Obfuscator)
	local tabList = {
		{ name = "Terrain", btn = tabTerrainBtn, str = tabTStroke },
		{ name = "MeshPart", btn = tabMeshBtn, str = tabMStroke },
		{ name = "CSG", btn = tabCSGBtn, str = tabCStroke },
		{ name = "Obfuscator", btn = tabObfBtn, str = tabOStroke },
	}
	for _, t in ipairs(tabList) do
		if activeTab == t.name then
			t.btn.BackgroundColor3 = pal.tabActiveBg
			t.btn.TextColor3 = pal.tabActiveText
			t.str.Color = pal.tabActiveBg
		else
			t.btn.BackgroundColor3 = pal.tabInactiveBg
			t.btn.TextColor3 = pal.tabInactiveText
			t.str.Color = pal.tabInactiveBorder
		end
	end

	-- Obfuscator Preset Buttons
	if obfOptions.preset == "Extreme" then
		btnPresetExtreme.BackgroundColor3 = pal.tabActiveBg
		btnPresetExtreme.TextColor3 = pal.tabActiveText
		bpeStroke.Color = pal.tabActiveBg

		btnPresetStandard.BackgroundColor3 = pal.tabInactiveBg
		btnPresetStandard.TextColor3 = pal.tabInactiveText
		bpsStroke.Color = pal.tabInactiveBorder

		btnPresetMinify.BackgroundColor3 = pal.tabInactiveBg
		btnPresetMinify.TextColor3 = pal.tabInactiveText
		bpmStroke.Color = pal.tabInactiveBorder

		btnPresetExtreme.Text = "● Ekstrem"
		btnPresetStandard.Text = "○ Standar"
		btnPresetMinify.Text = "○ Minify Saja"
	elseif obfOptions.preset == "Standard" then
		btnPresetStandard.BackgroundColor3 = pal.tabActiveBg
		btnPresetStandard.TextColor3 = pal.tabActiveText
		bpsStroke.Color = pal.tabActiveBg

		btnPresetExtreme.BackgroundColor3 = pal.tabInactiveBg
		btnPresetExtreme.TextColor3 = pal.tabInactiveText
		bpeStroke.Color = pal.tabInactiveBorder

		btnPresetMinify.BackgroundColor3 = pal.tabInactiveBg
		btnPresetMinify.TextColor3 = pal.tabInactiveText
		bpmStroke.Color = pal.tabInactiveBorder

		btnPresetExtreme.Text = "○ Ekstrem"
		btnPresetStandard.Text = "● Standar"
		btnPresetMinify.Text = "○ Minify Saja"
	else
		btnPresetMinify.BackgroundColor3 = pal.tabActiveBg
		btnPresetMinify.TextColor3 = pal.tabActiveText
		bpmStroke.Color = pal.tabActiveBg

		btnPresetExtreme.BackgroundColor3 = pal.tabInactiveBg
		btnPresetExtreme.TextColor3 = pal.tabInactiveText
		bpeStroke.Color = pal.tabInactiveBorder

		btnPresetStandard.BackgroundColor3 = pal.tabInactiveBg
		btnPresetStandard.TextColor3 = pal.tabInactiveText
		bpsStroke.Color = pal.tabInactiveBorder

		btnPresetExtreme.Text = "○ Ekstrem"
		btnPresetStandard.Text = "○ Standar"
		btnPresetMinify.Text = "● Minify Saja"
	end

	-- Combine Mode Buttons (Separate vs Combine)
	if meshOptions.combineMode == "Separate" then
		btnModeSeparate.BackgroundColor3 = pal.tabActiveBg
		btnModeSeparate.TextColor3 = pal.tabActiveText
		bmsStroke.Color = pal.tabActiveBg

		btnModeCombine.BackgroundColor3 = pal.tabInactiveBg
		btnModeCombine.TextColor3 = pal.tabInactiveText
		bmcStroke.Color = pal.tabInactiveBorder
		convertMeshBtn.Text = "⚡ KONVERSI KE MESHPART TERPISAH"
		combineDescLabel.Text = "Mode Terpisah: Setiap part yang dipilih menjadi 1 MeshPart sendiri."
	else
		btnModeCombine.BackgroundColor3 = pal.tabActiveBg
		btnModeCombine.TextColor3 = pal.tabActiveText
		bmcStroke.Color = pal.tabActiveBg

		btnModeSeparate.BackgroundColor3 = pal.tabInactiveBg
		btnModeSeparate.TextColor3 = pal.tabInactiveText
		bmsStroke.Color = pal.tabInactiveBorder
		convertMeshBtn.Text = "⚡ GABUNG SEMUA JADI 1 MESHPART"
		combineDescLabel.Text = "Mode Gabung: Semua part/union yang dipilih disatukan jadi 1 MeshPart utuh."
	end

	-- Mode Buttons (Auto vs Custom)
	if meshOptions.mode == "Auto" then
		modeAutoBtn.BackgroundColor3 = pal.tabActiveBg
		modeAutoBtn.TextColor3 = pal.tabActiveText
		maStroke.Color = pal.tabActiveBg

		modeCustomBtn.BackgroundColor3 = pal.tabInactiveBg
		modeCustomBtn.TextColor3 = pal.tabInactiveText
		mcStroke.Color = pal.tabInactiveBorder
	else
		modeCustomBtn.BackgroundColor3 = pal.tabActiveBg
		modeCustomBtn.TextColor3 = pal.tabActiveText
		mcStroke.Color = pal.tabActiveBg

		modeAutoBtn.BackgroundColor3 = pal.tabInactiveBg
		modeAutoBtn.TextColor3 = pal.tabInactiveText
		maStroke.Color = pal.tabInactiveBorder
	end

	-- Bevel Segment Buttons
	if btnSeg1 and btnSeg2 and btnSeg3 and bs1Stroke and bs2Stroke and bs3Stroke then
		local segList = { { btnSeg1, bs1Stroke, 1 }, { btnSeg2, bs2Stroke, 2 }, { btnSeg3, bs3Stroke, 3 } }
		for _, item in ipairs(segList) do
			local b, s, val = item[1], item[2], item[3]
			if meshOptions.bevelSegments == val then
				b.BackgroundColor3 = pal.tabActiveBg
				b.TextColor3 = pal.tabActiveText
				s.Color = pal.tabActiveBg
			else
				b.BackgroundColor3 = pal.tabInactiveBg
				b.TextColor3 = pal.tabInactiveText
				s.Color = pal.tabInactiveBorder
			end
		end
	end
end

local function setPreset(presetName: string)
	obfOptions.preset = presetName
	if presetName == "Extreme" then
		obfOptions.encryptStrings = true
		obfOptions.mangleVars = true
		obfOptions.mutateNumbers = true
		obfOptions.opaquePredicates = true
		obfOptions.minify = true
		oPresetDescLabel.Text = "Ekstrem: Enkripsi String XOR Multibyte, Barcode Mangling (_Il11..), Mutasi Angka Hex & Junk Logic (Anti-Baca)."
	elseif presetName == "Standard" then
		obfOptions.encryptStrings = true
		obfOptions.mangleVars = true
		obfOptions.mutateNumbers = true
		obfOptions.opaquePredicates = false
		obfOptions.minify = true
		oPresetDescLabel.Text = "Standar: Enkripsi String XOR Multibyte, Barcode Mangling, & Mutasi Angka Hex."
	elseif presetName == "Minify" then
		obfOptions.encryptStrings = false
		obfOptions.mangleVars = false
		obfOptions.mutateNumbers = false
		obfOptions.opaquePredicates = false
		obfOptions.minify = true
		oPresetDescLabel.Text = "Minify: Hapus komentar & kompresi spasi tanpa enkripsi / pengubahan nama variable."
	end
	mStr.Text = obfOptions.encryptStrings and "✓" or ""
	mMangle.Text = obfOptions.mangleVars and "✓" or ""
	mNum.Text = obfOptions.mutateNumbers and "✓" or ""
	mOpaque.Text = obfOptions.opaquePredicates and "✓" or ""
	mMin.Text = obfOptions.minify and "✓" or ""
	applyMonochromeTheme()
end

btnPresetExtreme.MouseButton1Click:Connect(function()
	setPreset("Extreme")
end)

btnPresetStandard.MouseButton1Click:Connect(function()
	setPreset("Standard")
end)

btnPresetMinify.MouseButton1Click:Connect(function()
	setPreset("Minify")
end)

local function setTab(tabName: string)
	activeTab = tabName
	terrainFrame.Visible = (tabName == "Terrain")
	meshFrame.Visible = (tabName == "MeshPart")
	csgFrame.Visible = (tabName == "CSG")
	obfFrame.Visible = (tabName == "Obfuscator")
	applyMonochromeTheme()
	if updateSelectionCounter then
		updateSelectionCounter()
	end
end

tabTerrainBtn.MouseButton1Click:Connect(function()
	setTab("Terrain")
end)

tabMeshBtn.MouseButton1Click:Connect(function()
	setTab("MeshPart")
end)

tabCSGBtn.MouseButton1Click:Connect(function()
	setTab("CSG")
end)

tabObfBtn.MouseButton1Click:Connect(function()
	setTab("Obfuscator")
end)

btnModeSeparate.MouseButton1Click:Connect(function()
	meshOptions.combineMode = "Separate"
	applyMonochromeTheme()
end)

btnModeCombine.MouseButton1Click:Connect(function()
	meshOptions.combineMode = "Combine"
	applyMonochromeTheme()
end)

modeAutoBtn.MouseButton1Click:Connect(function()
	meshOptions.mode = "Auto"
	modeAutoBtn.Text = "● Auto (Part & Union)"
	modeCustomBtn.Text = "○ Custom Mesh ID"
	customMeshContainer.Visible = false
	applyMonochromeTheme()
end)

modeCustomBtn.MouseButton1Click:Connect(function()
	meshOptions.mode = "Custom"
	modeAutoBtn.Text = "○ Auto (Part & Union)"
	modeCustomBtn.Text = "● Custom Mesh ID"
	customMeshContainer.Visible = true
	applyMonochromeTheme()
end)

pcall(function()
	settings().Studio.ThemeChanged:Connect(applyMonochromeTheme)
end)
applyMonochromeTheme()

-- ==============================================================================
-- 9. Selection Collectors (Part, Union, & Scripts)
-- ==============================================================================
local function getTargetParts(includeChildren: boolean): ({ BasePart }, number)
	local selected = Selection:Get()
	local parts: { BasePart } = {}
	local seen = {}
	local unionCount = 0

	local function scan(list: { Instance })
		for _, item in ipairs(list) do
			if item:IsA("BasePart") and not item:IsA("Terrain") and not item:IsA("NegateOperation") then
				if not seen[item] then
					seen[item] = true
					table.insert(parts, item)
					if item:IsA("UnionOperation") then
						unionCount += 1
					end
				end
			end
			if includeChildren and (item:IsA("Model") or item:IsA("Folder") or item:IsA("Configuration") or item:IsA("Workspace")) then
				scan(item:GetChildren())
			end
		end
	end

	scan(selected)
	return parts, unionCount
end

local function getTargetCSGParts(includeChildren: boolean): ({ BasePart }, number, number, number)
	local selected = Selection:Get()
	local parts: { BasePart } = {}
	local seen = {}
	local normalCount = 0
	local unionCount = 0
	local negateCount = 0

	local function scan(list: { Instance })
		for _, item in ipairs(list) do
			if item:IsA("BasePart") and not item:IsA("Terrain") then
				if not seen[item] then
					seen[item] = true
					table.insert(parts, item)
					if item:IsA("NegateOperation") then
						negateCount += 1
					elseif item:IsA("UnionOperation") then
						unionCount += 1
					else
						normalCount += 1
					end
				end
			end
			if includeChildren and (item:IsA("Model") or item:IsA("Folder") or item:IsA("Configuration") or item:IsA("Workspace")) then
				scan(item:GetChildren())
			end
		end
	end

	scan(selected)
	return parts, normalCount, unionCount, negateCount
end

local function getTargetScripts(includeChildren: boolean): ({ LuaSourceContainer }, { Script: number, LocalScript: number, ModuleScript: number })
	local selected = Selection:Get()
	local scripts: { LuaSourceContainer } = {}
	local seen = {}
	local counts = { Script = 0, LocalScript = 0, ModuleScript = 0 }

	local function checkItem(inst: Instance)
		if (inst:IsA("Script") or inst:IsA("LocalScript") or inst:IsA("ModuleScript")) and not seen[inst] then
			local isBackup = inst:GetAttribute("IsObfuscatorBackup") or string.find(inst.Name, "_Backup$")
			if not isBackup or #selected == 1 then
				seen[inst] = true
				table.insert(scripts, inst :: LuaSourceContainer)
				if inst:IsA("LocalScript") then
					counts.LocalScript += 1
				elseif inst:IsA("ModuleScript") then
					counts.ModuleScript += 1
				elseif inst:IsA("Script") then
					counts.Script += 1
				end
			end
		end
	end

	for _, root in ipairs(selected) do
		checkItem(root)
		if includeChildren and root:IsA("Instance") then
			for _, desc in ipairs(root:GetDescendants()) do
				checkItem(desc)
			end
		end
	end

	return scripts, counts
end

function updateSelectionCounter()
	if activeTab == "Obfuscator" then
		local scripts, counts = getTargetScripts(obfOptions.includeChildren)
		local count = #scripts
		selCountLabel.Text = string.format("Script Terpilih: %d", count)
		if count == 0 then
			selSubLabel.Text = "Pilih Script, LocalScript, atau ModuleScript di Explorer."
		else
			selSubLabel.Text = string.format("Siap diobfuscate (%d Script, %d LocalScript, %d ModuleScript).",
				counts.Script, counts.LocalScript, counts.ModuleScript)
		end
		return
	elseif activeTab == "CSG" then
		local parts, normalCount, unionCount, negateCount = getTargetCSGParts(csgOptions.includeChildren)
		local count = #parts
		if negateCount > 0 or unionCount > 0 then
			selCountLabel.Text = string.format("Part Terpilih: %d (%d Union, %d Negatif)", count, unionCount, negateCount)
		else
			selCountLabel.Text = string.format("Part Terpilih: %d", count)
		end

		if count == 0 then
			selSubLabel.Text = "Pilih Part untuk dijadikan Negatif, atau gabungkan Part & Negatif menjadi Union."
		else
			selSubLabel.Text = string.format("Siap memproses CSG: %d Part biasa, %d Negatif, %d Union.",
				normalCount, negateCount, unionCount)
		end
		return
	end

	local currentInclude = if activeTab == "Terrain" then terrainOptions.includeChildren else meshOptions.includeChildren
	local parts, unionCount = getTargetParts(currentInclude)
	local count = #parts
	if unionCount > 0 then
		selCountLabel.Text = string.format("Part Terpilih: %d (%d Union)", count, unionCount)
	else
		selCountLabel.Text = string.format("Part Terpilih: %d", count)
	end

	if count == 0 then
		selSubLabel.Text = "Pilih part atau union di Viewport atau Explorer."
	else
		selSubLabel.Text = string.format("Siap memproses %d item (%s).", count, meshOptions.combineMode == "Combine" and "Digabung Jadi 1" or "Terpisah")
	end
end

Selection.SelectionChanged:Connect(updateSelectionCounter)
refreshBtn.MouseButton1Click:Connect(updateSelectionCounter)

-- ==============================================================================
-- 10. Part to Terrain Conversion
-- ==============================================================================
local function convertPartsToTerrain()
	local parts, _ = getTargetParts(terrainOptions.includeChildren)
	local total = #parts
	if total == 0 then
		tStatusLabel.Text = "⚠️ Tidak ada part yang dipilih! Silakan pilih part terlebih dahulu."
		return
	end

	convertTerrainBtn.Text = "⏳ MEMPROSES TERRAIN..."
	convertTerrainBtn.AutoButtonColor = false

	local recordSuccess, recordId = pcall(function()
		return ChangeHistoryService:TryBeginRecording("Convert Parts to Terrain")
	end)

	local count = 0
	local failed = 0

	for i, part in ipairs(parts) do
		local mat = terrainOptions.material
		if mat == "Auto" then
			local success, _ = pcall(function()
				Terrain:FillBlock(part.CFrame, Vector3.new(0.1, 0.1, 0.1), part.Material)
			end)
			if success then
				mat = part.Material
			else
				mat = Enum.Material.Grass
			end
		end

		local ok, _ = pcall(function()
			if terrainOptions.detectShapes and part:IsA("WedgePart") then
				Terrain:FillWedge(part.CFrame, part.Size, mat)
			elseif terrainOptions.detectShapes and part:IsA("Part") and part.Shape == Enum.PartType.Ball then
				local radius = math.min(part.Size.X, part.Size.Y, part.Size.Z) / 2
				Terrain:FillBall(part.Position, radius, mat)
			elseif terrainOptions.detectShapes and part:IsA("Part") and part.Shape == Enum.PartType.Cylinder then
				local cf = part.CFrame * CFrame.Angles(0, 0, math.rad(90))
				local height = part.Size.X
				local radius = math.min(part.Size.Y, part.Size.Z) / 2
				Terrain:FillCylinder(cf, height, radius, mat)
			else
				Terrain:FillBlock(part.CFrame, part.Size, mat)
			end
		end)

		if ok then
			count += 1
			if terrainOptions.deleteParts then
				part:Destroy()
			end
		else
			failed += 1
		end

		if i % 100 == 0 then
			tStatusLabel.Text = string.format("Proses: %d / %d part...", i, total)
			task.wait()
		end
	end

	if recordSuccess and recordId then
		pcall(function()
			ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
		end)
	else
		pcall(function()
			ChangeHistoryService:SetWaypoint("Convert Parts to Terrain")
		end)
	end

	convertTerrainBtn.Text = "⚡ KONVERSI KE TERRAIN"
	convertTerrainBtn.AutoButtonColor = true

	if failed > 0 then
		tStatusLabel.Text = string.format("✓ Selesai: %d berhasil (%d gagal).", count, failed)
	else
		tStatusLabel.Text = string.format("✓ Sukses mengonversi %d part menjadi Terrain!", count)
	end

	updateSelectionCounter()
end

convertTerrainBtn.MouseButton1Click:Connect(convertPartsToTerrain)

undoTerrainBtn.MouseButton1Click:Connect(function()
	local s, _ = pcall(function()
		ChangeHistoryService:Undo()
	end)
	if s then
		tStatusLabel.Text = "↩ Konversi Terrain terakhir telah dibatalkan (Undo)."
		updateSelectionCounter()
	end
end)

-- ==============================================================================
-- 11. Helper: Append any BasePart / Union geometry to an EditableMesh
-- ==============================================================================
local function appendPartToMesh(em: EditableMesh, baseCF: CFrame, part: BasePart, faceColor: Color3?)
	local relCF = baseCF:Inverse() * part.CFrame

	-- 1. Check if SpecialMesh / FileMesh
	local sp = part:FindFirstChildOfClass("SpecialMesh")
	if sp and sp.MeshId ~= "" then
		local ok = appendSpecialMeshGeometry(em, relCF, normalizeAssetId(sp.MeshId), sp.Scale, faceColor)
		if ok then return end
	end

	-- 2. Check if UnionOperation (Deconstruct if possible)
	if part:IsA("UnionOperation") and meshOptions.convertUnions then
		local s, sep = pcall(function()
			return plugin:Separate({part})
		end)
		if s and sep and #sep > 0 then
			for _, subPart in ipairs(sep) do
				if subPart:IsA("BasePart") and not subPart:IsA("NegateOperation") then
					appendPartToMesh(em, baseCF, subPart, faceColor or subPart.Color)
				end
				subPart:Destroy()
			end
			return
		end
	end

	-- 3. Standard Shapes with flat normals & faceColor
	if part:IsA("WedgePart") then
		appendWedgeGeometry(em, relCF, part.Size, faceColor)
	elseif part:IsA("CornerWedgePart") then
		appendCornerWedgeGeometry(em, relCF, part.Size, faceColor)
	elseif part:IsA("Part") and part.Shape == Enum.PartType.Ball then
		appendSphereGeometry(em, relCF, part.Size, 20, 20, faceColor)
	elseif part:IsA("Part") and part.Shape == Enum.PartType.Cylinder then
		appendCylinderGeometry(em, relCF, part.Size, 24, faceColor)
	else
		if meshOptions.bevelEnabled and (part:IsA("Part") and (part.Shape == Enum.PartType.Block or part.Shape == nil)) then
			appendBeveledBoxGeometry(em, relCF, part.Size, meshOptions.bevelRadius, meshOptions.bevelSegments, faceColor)
		else
			appendBoxGeometry(em, relCF, part.Size, faceColor)
		end
	end
end

-- ==============================================================================
-- 12. Part & Union to MeshPart Implementation (Terpisah vs Gabung Jadi 1)
-- ==============================================================================
local function convertSinglePartToMeshPart(part: BasePart): (MeshPart?, string?)
	local meshId = ""
	local textureId = ""

	local sp = part:FindFirstChildOfClass("SpecialMesh")
	if sp then
		meshId = normalizeAssetId(sp.MeshId)
		textureId = normalizeAssetId(sp.TextureId)
	end

	if meshOptions.mode == "Custom" and meshOptions.customMeshId ~= "" then
		meshId = normalizeAssetId(meshOptions.customMeshId)
		if meshOptions.customTextureId ~= "" then
			textureId = normalizeAssetId(meshOptions.customTextureId)
		end
	end

	local newMeshPart: MeshPart? = nil

	-- A. Custom / SpecialMesh ID Creation
	if meshId ~= "" then
		local s1, r1 = pcall(function()
			return AssetService:CreateMeshPartAsync(Content.fromUri(meshId), {
				CollisionFidelity = meshOptions.collisionFidelity,
				RenderFidelity = meshOptions.renderFidelity,
			})
		end)
		if s1 and r1 and r1:IsA("MeshPart") then
			newMeshPart = r1
		else
			local s2, r2 = pcall(function()
				return InsertService:CreateMeshPartAsync(
					meshId,
					meshOptions.collisionFidelity,
					meshOptions.renderFidelity
				)
			end)
			if s2 and r2 and r2:IsA("MeshPart") then
				newMeshPart = r2
			end
		end
	end

	-- B. Union Operation Deconstruct & Bake
	if not newMeshPart and part:IsA("UnionOperation") and meshOptions.convertUnions then
		local s, sep = pcall(function()
			return plugin:Separate({part})
		end)
		if s and sep and #sep > 0 then
			local em = AssetService:CreateEditableMesh()
			local baseCF = part.CFrame
			for _, subPart in ipairs(sep) do
				if subPart:IsA("BasePart") and not subPart:IsA("NegateOperation") then
					appendPartToMesh(em, baseCF, subPart, nil)
				end
				subPart:Destroy()
			end

			local sc, mp = pcall(function()
				return AssetService:CreateMeshPartAsync(Content.fromObject(em), {
					CollisionFidelity = meshOptions.collisionFidelity,
					RenderFidelity = meshOptions.renderFidelity,
				})
			end)
			if sc and mp and mp:IsA("MeshPart") then
				newMeshPart = mp
			end
		end
	end

	-- C. Procedural Native Shapes
	if not newMeshPart then
		local em = AssetService:CreateEditableMesh()
		appendPartToMesh(em, part.CFrame, part, nil)

		local s, r = pcall(function()
			return AssetService:CreateMeshPartAsync(Content.fromObject(em), {
				CollisionFidelity = meshOptions.collisionFidelity,
				RenderFidelity = meshOptions.renderFidelity,
			})
		end)
		if s and r and r:IsA("MeshPart") then
			newMeshPart = r
		end
	end

	if not newMeshPart then
		return nil, "Gagal membuat MeshPart untuk: " .. part.Name
	end

	-- Copy properties
	newMeshPart.Name = part.Name
	newMeshPart.Size = part.Size
	newMeshPart.CFrame = part.CFrame
	newMeshPart.Color = part.Color
	newMeshPart.Material = part.Material
	pcall(function()
		newMeshPart.MaterialVariant = part.MaterialVariant
	end)
	newMeshPart.Transparency = part.Transparency
	newMeshPart.Reflectance = part.Reflectance
	newMeshPart.CastShadow = part.CastShadow
	newMeshPart.CanCollide = part.CanCollide
	newMeshPart.CanTouch = part.CanTouch
	newMeshPart.CanQuery = part.CanQuery
	newMeshPart.Anchored = part.Anchored
	pcall(function()
		newMeshPart.CollisionGroup = part.CollisionGroup
	end)

	if textureId ~= "" then
		pcall(function()
			newMeshPart.TextureID = textureId
		end)
	end

	for k, v in pairs(part:GetAttributes()) do
		newMeshPart:SetAttribute(k, v)
	end
	for _, tag in ipairs(CollectionService:GetTags(part)) do
		CollectionService:AddTag(newMeshPart, tag)
	end

	if meshOptions.transferChildren then
		for _, child in ipairs(part:GetChildren()) do
			if not child:IsA("SpecialMesh") and not child:IsA("FileMesh") then
				child.Parent = newMeshPart
			end
		end
	end

	newMeshPart.Parent = part.Parent

	if meshOptions.deleteParts then
		part:Destroy()
	end

	return newMeshPart, nil
end

-- --- Convert All Selected Parts into ONE Single Combined MeshPart ---
local function convertPartsToCombinedMeshPart(parts: { BasePart }): (MeshPart?, string?)
	if #parts == 0 then return nil, "Tidak ada part" end

	-- Check if all parts have the same color and material
	local allSameColor = true
	local firstColor = parts[1].Color
	local allSameMaterial = true
	local firstMaterial = parts[1].Material

	for i = 2, #parts do
		if parts[i].Color ~= firstColor then
			allSameColor = false
		end
		if parts[i].Material ~= firstMaterial then
			allSameMaterial = false
		end
	end

	-- Calculate Global AABB Bounding Box
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)

	for _, p in ipairs(parts) do
		local cf, sz = p.CFrame, p.Size
		local h = sz / 2
		for dx = -1, 1, 2 do
			for dy = -1, 1, 2 do
				for dz = -1, 1, 2 do
					local w = cf:PointToWorldSpace(Vector3.new(dx * h.X, dy * h.Y, dz * h.Z))
					minV = Vector3.new(math.min(minV.X, w.X), math.min(minV.Y, w.Y), math.min(minV.Z, w.Z))
					maxV = Vector3.new(math.max(maxV.X, w.X), math.max(maxV.Y, w.Y), math.max(maxV.Z, w.Z))
				end
			end
		end
	end

	local center = (minV + maxV) / 2
	local baseCF = CFrame.new(center)
	local totalSize = maxV - minV

	local em = AssetService:CreateEditableMesh()

	for i, part in ipairs(parts) do
		local fColor = allSameColor and nil or part.Color
		appendPartToMesh(em, baseCF, part, fColor)
		if i % 30 == 0 then
			task.wait()
		end
	end

	local s, mp = pcall(function()
		return AssetService:CreateMeshPartAsync(Content.fromObject(em), {
			CollisionFidelity = meshOptions.collisionFidelity,
			RenderFidelity = meshOptions.renderFidelity,
		})
	end)

	if not (s and mp and mp:IsA("MeshPart")) then
		return nil, "Gagal mengompilasi mesh gabungan!"
	end

	local firstPart = parts[1]
	mp.Name = #parts > 1 and (firstPart.Name .. "_CombinedMesh") or firstPart.Name
	mp.CFrame = baseCF
	mp.Size = totalSize
	
	if allSameColor then
		mp.Color = firstColor
	else
		-- Multi-colored mesh: White base allows baked face colors to render 1:1 without tint
		mp.Color = Color3.new(1, 1, 1)
	end

	mp.Material = allSameMaterial and firstMaterial or Enum.Material.SmoothPlastic
	pcall(function()
		mp.MaterialVariant = firstPart.MaterialVariant
	end)
	mp.Transparency = firstPart.Transparency
	mp.Reflectance = firstPart.Reflectance
	mp.CastShadow = firstPart.CastShadow
	mp.CanCollide = firstPart.CanCollide
	mp.Anchored = firstPart.Anchored

	if meshOptions.transferChildren then
		for _, p in ipairs(parts) do
			for _, child in ipairs(p:GetChildren()) do
				if not child:IsA("SpecialMesh") and not child:IsA("FileMesh") then
					child.Parent = mp
				end
			end
		end
	end

	mp.Parent = firstPart.Parent

	if meshOptions.deleteParts then
		for _, p in ipairs(parts) do
			p:Destroy()
		end
	end

	return mp, nil
end

-- Main MeshPart Conversion Execution Dispatcher
local function executeMeshConversion()
	local parts, unionCount = getTargetParts(meshOptions.includeChildren)
	local total = #parts
	if total == 0 then
		mStatusLabel.Text = "⚠️ Tidak ada part atau union yang dipilih!"
		return
	end

	local recordSuccess, recordId = pcall(function()
		return ChangeHistoryService:TryBeginRecording(
			meshOptions.combineMode == "Combine" and "Combine Parts to MeshPart" or "Convert Parts to MeshPart"
		)
	end)

	if meshOptions.combineMode == "Combine" then
		-- GABUNG MENJADI 1 MESHPART
		convertMeshBtn.Text = "⏳ MENGGABUNGKAN MENJADI 1..."
		convertMeshBtn.AutoButtonColor = false

		local combinedMp, err = convertPartsToCombinedMeshPart(parts)
		if combinedMp then
			pcall(function()
				Selection:Set({ combinedMp })
			end)
			mStatusLabel.Text = string.format("✓ Sukses menggabungkan %d item (%d Union) menjadi 1 MeshPart!", total, unionCount)
		else
			mStatusLabel.Text = "❌ " .. (err or "Gagal menggabungkan part.")
		end
	else
		-- TERPISAH (INDIVIDUAL MESHPART)
		convertMeshBtn.Text = "⏳ MEMPROSES MESHPART TERPISAH..."
		convertMeshBtn.AutoButtonColor = false

		local count = 0
		local failed = 0
		local newSelection = {}

		for i, part in ipairs(parts) do
			if part:IsA("MeshPart") and meshOptions.mode ~= "Custom" then
				table.insert(newSelection, part)
				continue
			end

			local mp, _ = convertSinglePartToMeshPart(part)
			if mp then
				count += 1
				table.insert(newSelection, mp)
			else
				failed += 1
			end

			if i % 50 == 0 then
				mStatusLabel.Text = string.format("Proses: %d / %d item...", i, total)
				task.wait()
			end
		end

		if #newSelection > 0 then
			pcall(function()
				Selection:Set(newSelection)
			end)
		end

		if failed > 0 then
			mStatusLabel.Text = string.format("✓ Selesai: %d berhasil (%d gagal).", count, failed)
		else
			mStatusLabel.Text = string.format("✓ Sukses mengonversi %d item (%d Union) ke MeshPart terpisah!", count, unionCount)
		end
	end

	if recordSuccess and recordId then
		pcall(function()
			ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
		end)
	else
		pcall(function()
			ChangeHistoryService:SetWaypoint("Convert to MeshPart")
		end)
	end

	convertMeshBtn.AutoButtonColor = true
	applyMonochromeTheme()
	updateSelectionCounter()
end

convertMeshBtn.MouseButton1Click:Connect(executeMeshConversion)

undoMeshBtn.MouseButton1Click:Connect(function()
	local s, _ = pcall(function()
		ChangeHistoryService:Undo()
	end)
	if s then
		mStatusLabel.Text = "↩ Konversi MeshPart terakhir telah dibatalkan (Undo)."
		updateSelectionCounter()
	end
end)

function executeBevelParts()
	local parts, unionCount = getTargetParts(meshOptions.includeChildren)
	local total = #parts
	if total == 0 then
		mStatusLabel.Text = "⚠️ Pilih minimal 1 balok Part di Workspace untuk ditumpulkan sudutnya."
		return
	end

	local targetParts = {}
	for _, p in ipairs(parts) do
		if p:IsA("Part") and (p.Shape == Enum.PartType.Block or p.Shape == nil) then
			table.insert(targetParts, p)
		end
	end

	if #targetParts == 0 then
		mStatusLabel.Text = "⚠️ Dari " .. total .. " item yang dipilih, tidak ada balok Part (Block) untuk ditumpulkan."
		return
	end

	local recordSuccess, recordId = pcall(function()
		return ChangeHistoryService:TryBeginRecording("Bevel Part Corners")
	end)

	if btnBevelAction then
		btnBevelAction.Text = "⏳ MEMPROSES TUMPUL SUDUT..."
		btnBevelAction.AutoButtonColor = false
	end

	local count = 0
	local failed = 0
	local newSelection = {}

	for i, part in ipairs(targetParts) do
		local em = AssetService:CreateEditableMesh()
		appendBeveledBoxGeometry(em, CFrame.identity, part.Size, meshOptions.bevelRadius, meshOptions.bevelSegments, nil)

		local s, mp = pcall(function()
			return AssetService:CreateMeshPartAsync(Content.fromObject(em), {
				CollisionFidelity = meshOptions.collisionFidelity,
				RenderFidelity = meshOptions.renderFidelity,
			})
		end)

		if s and mp and mp:IsA("MeshPart") then
			count += 1
			mp.Name = part.Name .. "_Rounded"
			mp.Size = part.Size
			mp.CFrame = part.CFrame
			mp.Color = part.Color
			mp.Material = part.Material
			pcall(function()
				mp.MaterialVariant = part.MaterialVariant
			end)
			mp.Transparency = part.Transparency
			mp.Reflectance = part.Reflectance
			mp.CastShadow = part.CastShadow
			mp.CanCollide = part.CanCollide
			mp.CanTouch = part.CanTouch
			mp.CanQuery = part.CanQuery
			mp.Anchored = part.Anchored
			pcall(function()
				mp.CollisionGroup = part.CollisionGroup
			end)

			for k, v in pairs(part:GetAttributes()) do
				mp:SetAttribute(k, v)
			end
			for _, tag in ipairs(CollectionService:GetTags(part)) do
				CollectionService:AddTag(mp, tag)
			end

			if meshOptions.transferChildren then
				for _, child in ipairs(part:GetChildren()) do
					if not child:IsA("SpecialMesh") and not child:IsA("FileMesh") then
						child.Parent = mp
					end
				end
			end

			mp.Parent = part.Parent

			if meshOptions.deleteParts then
				part:Destroy()
			end

			table.insert(newSelection, mp)
		else
			failed += 1
		end

		if i % 10 == 0 then
			mStatusLabel.Text = string.format("Memproses bevel: %d / %d...", i, #targetParts)
			task.wait()
		end
	end

	if #newSelection > 0 then
		pcall(function()
			Selection:Set(newSelection)
		end)
	end

	if failed > 0 then
		mStatusLabel.Text = string.format("✓ Selesai Bevel: %d berhasil (%d gagal). Radius: %.2f studs.", count, failed, meshOptions.bevelRadius)
	else
		mStatusLabel.Text = string.format("✓ Sukses menumpulkan %d Part! (Radius: %.2f studs, Segmen: %d)", count, meshOptions.bevelRadius, meshOptions.bevelSegments)
	end

	if recordSuccess and recordId then
		pcall(function()
			ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
		end)
	else
		pcall(function()
			ChangeHistoryService:SetWaypoint("Bevel Part Corners")
		end)
	end

	if btnBevelAction then
		btnBevelAction.Text = "🔘 TUMPULKAN SUDUT PART TERPILIH (BEVEL)"
		btnBevelAction.AutoButtonColor = true
	end
	applyMonochromeTheme()
	updateSelectionCounter()
end

-- ==============================================================================
-- 12.3. CSG Operations Implementation (Negate, Union, & Separate)
-- ==============================================================================
function executeNegateParts()
	local parts, normalCount, unionCount, negateCount = getTargetCSGParts(csgOptions.includeChildren)
	local total = #parts
	if total == 0 then
		csgStatusLabel.Text = "⚠️ Pilih minimal 1 Part atau NegateOperation untuk di-Negate."
		return
	end

	local recordSuccess, recordId = pcall(function()
		return ChangeHistoryService:TryBeginRecording("Negate Part(s)")
	end)

	local ok, newItems = pcall(function()
		return plugin:Negate(parts)
	end)

	if recordSuccess and recordId then
		pcall(function()
			ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
		end)
	end

	if ok and newItems and #newItems > 0 then
		if csgOptions.autoSelect then
			pcall(function()
				Selection:Set(newItems)
			end)
		end
		local isNeg = newItems[1]:IsA("NegateOperation")
		csgStatusLabel.Text = string.format("✓ Berhasil mengubah %d part menjadi %s!",
			#newItems, isNeg and "Negatif (NegateOperation)" or "Part biasa")
	else
		csgStatusLabel.Text = "❌ Gagal melakukan operasi Negate: " .. tostring(newItems)
	end

	updateSelectionCounter()
end

function executeUnionParts()
	local parts, normalCount, unionCount, negateCount = getTargetCSGParts(csgOptions.includeChildren)
	local total = #parts
	if total == 0 then
		csgStatusLabel.Text = "⚠️ Pilih minimal 1 part untuk diubah menjadi UnionOperation."
		return
	end

	btnUnion.Text = "⏳ MEMPROSES UNION..."
	btnUnion.AutoButtonColor = false

	local recordSuccess, recordId = pcall(function()
		return ChangeHistoryService:TryBeginRecording("Union Parts")
	end)

	local ok, unionRes = pcall(function()
		return plugin:Union(parts)
	end)

	if recordSuccess and recordId then
		pcall(function()
			ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
		end)
	end

	btnUnion.Text = "➕ UNION PARTS (GABUNG JADI 1 UNION)"
	btnUnion.AutoButtonColor = true
	applyMonochromeTheme()

	if ok and unionRes and unionRes:IsA("UnionOperation") then
		pcall(function()
			unionRes.CollisionFidelity = csgOptions.collisionFidelity
			unionRes.RenderFidelity = csgOptions.renderFidelity
			if csgOptions.preserveName and parts[1] then
				unionRes.Name = parts[1].Name .. "_Union"
			end
			if csgOptions.autoSelect then
				Selection:Set({ unionRes })
			end
		end)

		if negateCount > 0 then
			csgStatusLabel.Text = string.format("✓ Sukses memotong & menggabungkan %d part (%d Negatif) menjadi 1 UnionOperation!", total, negateCount)
		else
			csgStatusLabel.Text = string.format("✓ Sukses menggabungkan %d part menjadi 1 UnionOperation (%s)!", total, unionRes.Name)
		end
	else
		csgStatusLabel.Text = "❌ Gagal menggabungkan menjadi Union: " .. tostring(unionRes)
	end

	updateSelectionCounter()
end

function executeSeparateUnion()
	local selected = Selection:Get()
	local unions: { UnionOperation } = {}

	local function scan(list: { Instance })
		for _, item in ipairs(list) do
			if item:IsA("UnionOperation") then
				table.insert(unions, item)
			elseif csgOptions.includeChildren and (item:IsA("Model") or item:IsA("Folder")) then
				scan(item:GetChildren())
			end
		end
	end
	scan(selected)

	if #unions == 0 then
		csgStatusLabel.Text = "⚠️ Pilih minimal 1 UnionOperation untuk dipisahkan (Separate)."
		return
	end

	local recordSuccess, recordId = pcall(function()
		return ChangeHistoryService:TryBeginRecording("Separate Union(s)")
	end)

	local ok, separated = pcall(function()
		return plugin:Separate(unions)
	end)

	if recordSuccess and recordId then
		pcall(function()
			ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
		end)
	end

	if ok and separated and #separated > 0 then
		if csgOptions.autoSelect then
			pcall(function()
				Selection:Set(separated)
			end)
		end
		csgStatusLabel.Text = string.format("✓ Sukses memisahkan %d Union menjadi %d part konstituen!", #unions, #separated)
	else
		csgStatusLabel.Text = "❌ Gagal memisahkan Union: " .. tostring(separated)
	end

	updateSelectionCounter()
end

btnNegate.MouseButton1Click:Connect(executeNegateParts)
btnUnion.MouseButton1Click:Connect(executeUnionParts)
btnSeparate.MouseButton1Click:Connect(executeSeparateUnion)
btnUnionToMesh.MouseButton1Click:Connect(function()
	setTab("MeshPart")
	executeMeshConversion()
end)

-- ==============================================================================
-- 12.5. Lua Source-to-Source Obfuscator Engine & Execution (Native Luau)
-- ==============================================================================
local OBF_RESERVED = {
	-- Luau / Lua keywords
	["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true, ["elseif"] = true,
	["end"] = true, ["false"] = true, ["for"] = true, ["function"] = true, ["if"] = true,
	["in"] = true, ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
	["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
	["while"] = true, ["continue"] = true, ["type"] = true, ["export"] = true,

	-- Roblox globals & core singletons
	["game"] = true, ["workspace"] = true, ["script"] = true, ["math"] = true, ["table"] = true,
	["string"] = true, ["task"] = true, ["os"] = true, ["debug"] = true, ["utf8"] = true,
	["coroutine"] = true, ["bit32"] = true, ["buffer"] = true, ["Vector3"] = true, ["CFrame"] = true,
	["Color3"] = true, ["UDim2"] = true, ["UDim"] = true, ["Instance"] = true, ["Enum"] = true,
	["RaycastParams"] = true, ["Ray"] = true, ["BrickColor"] = true, ["TweenInfo"] = true,
	["print"] = true, ["warn"] = true, ["error"] = true, ["pcall"] = true, ["xpcall"] = true,
	["pairs"] = true, ["ipairs"] = true, ["next"] = true, ["tostring"] = true, ["tonumber"] = true,
	["typeof"] = true, ["select"] = true, ["unpack"] = true, ["setmetatable"] = true,
	["getmetatable"] = true, ["rawget"] = true, ["rawset"] = true, ["rawequal"] = true,
	["tick"] = true, ["time"] = true, ["wait"] = true, ["delay"] = true, ["spawn"] = true,
	["_G"] = true, ["shared"] = true, ["assert"] = true, ["self"] = true, ["PluginManager"] = true,
	["newproxy"] = true, ["collectgarbage"] = true,
}

local function obfTokenize(src: string)
	local tokens = {}
	local len = #src
	local i = 1

	while i <= len do
		local b = string.byte(src, i)
		local c = string.sub(src, i, i)

		-- Comments
		if c == "-" and string.sub(src, i + 1, i + 1) == "-" then
			local start = i
			i = i + 2
			if string.sub(src, i, i) == "[" then
				local eqCount = 0
				local p = i + 1
				while string.sub(src, p, p) == "=" do
					eqCount += 1
					p += 1
				end
				if string.sub(src, p, p) == "[" then
					local closePattern = "]" .. string.rep("=", eqCount) .. "]"
					local sEnd, eEnd = string.find(src, closePattern, p + 1, true)
					i = eEnd and (eEnd + 1) or (len + 1)
					table.insert(tokens, { type = "comment", value = string.sub(src, start, i - 1) })
					continue
				end
			end
			local nl = string.find(src, "\n", i, true)
			i = nl and (nl + 1) or (len + 1)
			table.insert(tokens, { type = "comment", value = string.sub(src, start, i - 1) })
			continue
		end

		-- Whitespace
		if c == " " or c == "\t" or c == "\r" or c == "\n" then
			local start = i
			while i <= len and string.find(string.sub(src, i, i), "%s") do
				i += 1
			end
			table.insert(tokens, { type = "space", value = string.sub(src, start, i - 1) })
			continue
		end

		-- String Literals (Single & Double Quotes)
		if c == "'" or c == '"' then
			local quote = c
			local start = i
			i += 1
			while i <= len do
				local ch = string.sub(src, i, i)
				if ch == "\\" then
					i += 2
				elseif ch == quote then
					i += 1
					break
				else
					i += 1
				end
			end
			table.insert(tokens, { type = "string", value = string.sub(src, start, i - 1), quote = quote })
			continue
		end

		-- Multi-line String Literals [=[ ... ]=]
		if c == "[" and (string.sub(src, i + 1, i + 1) == "[" or string.sub(src, i + 1, i + 1) == "=") then
			local eqCount = 0
			local p = i + 1
			while string.sub(src, p, p) == "=" do
				eqCount += 1
				p += 1
			end
			if string.sub(src, p, p) == "[" then
				local start = i
				local closePattern = "]" .. string.rep("=", eqCount) .. "]"
				local sEnd, eEnd = string.find(src, closePattern, p + 1, true)
				i = eEnd and (eEnd + 1) or (len + 1)
				table.insert(tokens, { type = "string", value = string.sub(src, start, i - 1), isMulti = true })
				continue
			end
		end

		-- Numbers (Hexadecimal, Binary, Decimal, Float, Scientific)
		if (b >= 48 and b <= 57) or (c == "." and i + 1 <= len and string.byte(src, i + 1) >= 48 and string.byte(src, i + 1) <= 57) then
			local start = i
			if c == "0" and (string.sub(src, i + 1, i + 1) == "x" or string.sub(src, i + 1, i + 1) == "X") then
				i += 2
				while i <= len and string.find(string.sub(src, i, i), "[0-9a-fA-F_]") do
					i += 1
				end
			elseif c == "0" and (string.sub(src, i + 1, i + 1) == "b" or string.sub(src, i + 1, i + 1) == "B") then
				i += 2
				while i <= len and string.find(string.sub(src, i, i), "[01_]") do
					i += 1
				end
			else
				while i <= len and string.find(string.sub(src, i, i), "[0-9%.eE%_%-%+]") do
					local cur = string.sub(src, i, i)
					if (cur == "+" or cur == "-") and not string.find(string.sub(src, i - 1, i - 1), "[eE]") then
						break
					end
					i += 1
				end
			end
			table.insert(tokens, { type = "number", value = string.sub(src, start, i - 1) })
			continue
		end

		-- Identifiers
		if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or c == "_" then
			local start = i
			while i <= len do
				local cb = string.byte(src, i)
				if (cb >= 65 and cb <= 90) or (cb >= 97 and cb <= 122) or (cb >= 48 and cb <= 57) or cb == 95 then
					i += 1
				else
					break
				end
			end
			table.insert(tokens, { type = "ident", value = string.sub(src, start, i - 1) })
			continue
		end

		-- Operators & Symbols
		local three = string.sub(src, i, i + 2)
		local two = string.sub(src, i, i + 1)
		if three == "..." or three == "..=" then
			table.insert(tokens, { type = "symbol", value = three })
			i += 3
		elseif two == "==" or two == "~=" or two == "<=" or two == ">=" or two == ".." or two == "::"
			or two == "+=" or two == "-=" or two == "*=" or two == "/=" or two == "%=" or two == "^="
			or two == "//" or two == "->" then
			table.insert(tokens, { type = "symbol", value = two })
			i += 2
		else
			table.insert(tokens, { type = "symbol", value = c })
			i += 1
		end
	end
	return tokens
end

local function obfParseStrLiteral(raw: string): string
	local first = string.sub(raw, 1, 1)
	if first == "[" then
		local content = string.match(raw, "^%[=*%[(.*)%]=*%]$")
		if content then
			if string.sub(content, 1, 1) == "\n" then
				content = string.sub(content, 2)
			end
			return content
		end
		return string.sub(raw, 3, -3)
	end

	local inner = string.sub(raw, 2, -2)
	local res = {}
	local i = 1
	local len = #inner
	while i <= len do
		local c = string.sub(inner, i, i)
		if c == "\\" and i < len then
			local nxt = string.sub(inner, i + 1, i + 1)
			if nxt == "n" then
				table.insert(res, "\n")
				i += 2
			elseif nxt == "t" then
				table.insert(res, "\t")
				i += 2
			elseif nxt == "r" then
				table.insert(res, "\r")
				i += 2
			elseif nxt == "\\" then
				table.insert(res, "\\")
				i += 2
			elseif nxt == "\"" then
				table.insert(res, "\"")
				i += 2
			elseif nxt == "'" then
				table.insert(res, "'")
				i += 2
			elseif nxt == "a" then
				table.insert(res, "\a")
				i += 2
			elseif nxt == "b" then
				table.insert(res, "\b")
				i += 2
			elseif nxt == "f" then
				table.insert(res, "\f")
				i += 2
			elseif nxt == "v" then
				table.insert(res, "\v")
				i += 2
			elseif nxt == "x" then
				local hexStr = string.sub(inner, i + 2, i + 3)
				local bVal = tonumber(hexStr, 16) or 0
				table.insert(res, string.char(bVal))
				i += 4
			elseif string.find(nxt, "[0-9]") then
				local numStr = string.match(string.sub(inner, i + 1, i + 3), "^%d%d?%d?") or "0"
				local bVal = tonumber(numStr) or 0
				table.insert(res, string.char(bVal))
				i = i + 1 + #numStr
			else
				table.insert(res, nxt)
				i += 2
			end
		else
			table.insert(res, c)
			i += 1
		end
	end
	return table.concat(res)
end

local function obfGenerateBarcode(index: number): string
	local chars = { "l", "I", "1" }
	local res = { "_" }
	local n = index + 100
	while n > 0 do
		local rem = (n % 3) + 1
		table.insert(res, chars[rem])
		n = math.floor(n / 3)
	end
	while #res < 12 do
		table.insert(res, (index % 2 == 0) and "I" or "l")
	end
	return table.concat(res)
end

local function obfMutateNum(numStr: string): string
	local n = tonumber(numStr)
	if not n then
		return numStr
	end
	if math.floor(n) == n and math.abs(n) < 1000000 then
		local off = math.random(32, 255)
		if n >= 0 then
			return string.format("(0x%X - 0x%X)", n + off, off)
		else
			return string.format("(0x%X - 0x%X)", off, off - n)
		end
	else
		local off = math.random(10, 100)
		return string.format("((%f + 0x%X) - 0x%X)", n, off, off)
	end
end

local function obfuscateLuauScript(src: string, opts: typeof(obfOptions)): string
	local rawTokens = obfTokenize(src)
	local tokens = {}

	for _, t in ipairs(rawTokens) do
		if opts.minify then
			if t.type ~= "comment" and t.type ~= "space" then
				table.insert(tokens, t)
			end
		else
			if t.type ~= "comment" then
				table.insert(tokens, t)
			end
		end
	end

	-- Pass 1: Identify local declarations to safely mangle
	local localNames = {}
	if opts.mangleVars then
		for idx, t in ipairs(tokens) do
			if t.type == "ident" and t.value == "local" then
				local nextTok = tokens[idx + 1]
				if nextTok and nextTok.type == "ident" and nextTok.value == "function" then
					local fnName = tokens[idx + 2]
					if fnName and fnName.type == "ident" and not OBF_RESERVED[fnName.value] then
						localNames[fnName.value] = true
					end
				else
					local p = idx + 1
					while p <= #tokens do
						local cur = tokens[p]
						if cur.type == "ident" and not OBF_RESERVED[cur.value] then
							localNames[cur.value] = true
						end
						local nxt = tokens[p + 1]
						if nxt and nxt.value == "," then
							p += 2
						else
							break
						end
					end
				end
			elseif t.type == "ident" and t.value == "function" then
				local p = idx + 1
				while p <= #tokens and tokens[p].value ~= "(" do
					p += 1
				end
				if p <= #tokens and tokens[p].value == "(" then
					p += 1
					while p <= #tokens and tokens[p].value ~= ")" do
						local cur = tokens[p]
						if cur.type == "ident" and not OBF_RESERVED[cur.value] then
							localNames[cur.value] = true
						end
						if tokens[p + 1] and tokens[p + 1].value == "," then
							p += 2
						else
							p += 1
						end
					end
				end
			elseif t.type == "ident" and t.value == "for" then
				local p = idx + 1
				while p <= #tokens and tokens[p].value ~= "in" and tokens[p].value ~= "=" and tokens[p].value ~= "do" do
					local cur = tokens[p]
					if cur.type == "ident" and not OBF_RESERVED[cur.value] then
						localNames[cur.value] = true
					end
					if tokens[p + 1] and tokens[p + 1].value == "," then
						p += 2
					else
						p += 1
					end
				end
			end
		end
	end

	local barcodeMap = {}
	local bIndex = 1
	for name, _ in pairs(localNames) do
		barcodeMap[name] = obfGenerateBarcode(bIndex)
		bIndex += 1
	end

	-- Pass 2: Encrypt string table with rotating 4-byte XOR key
	local stringPool = {}
	local stringIndexMap = {}
	local encKey = { math.random(1, 255), math.random(1, 255), math.random(1, 255), math.random(1, 255) }

	local function registerString(raw: string): number
		local strVal = obfParseStrLiteral(raw)
		if stringIndexMap[strVal] then
			return stringIndexMap[strVal]
		end
		local sIdx = #stringPool + 1
		stringIndexMap[strVal] = sIdx

		local encBytes = {}
		for j = 1, #strVal do
			local b = string.byte(strVal, j)
			local k = encKey[((j - 1) % #encKey) + 1]
			table.insert(encBytes, bit32.bxor(b, k))
		end

		local encParts = {}
		for _, b in ipairs(encBytes) do
			table.insert(encParts, string.format("\\x%02X", b))
		end
		table.insert(stringPool, table.concat(encParts))
		return sIdx
	end

	local varStrTable = obfGenerateBarcode(bIndex); bIndex += 1
	local varRawTable = obfGenerateBarcode(bIndex); bIndex += 1
	local varKeyTable = obfGenerateBarcode(bIndex); bIndex += 1

	-- Pass 3: Reassemble tokens
	local outputParts = {}
	local prevTok = nil

	for idx, tok in ipairs(tokens) do
		local nxtTok = tokens[idx + 1]
		local rendered = tok.value

		if tok.type == "string" and opts.encryptStrings then
			local sIdx = registerString(tok.value)
			local off = math.random(20, 100)
			rendered = string.format("%s[(0x%X - 0x%X)]", varStrTable, sIdx + off, off)
		elseif tok.type == "number" and opts.mutateNumbers then
			rendered = obfMutateNum(tok.value)
		elseif tok.type == "ident" and opts.mangleVars then
			local isMember = prevTok and (prevTok.value == "." or prevTok.value == ":")
			local isTableKey = nxtTok and nxtTok.value == "=" and (not prevTok or prevTok.value == "{" or prevTok.value == ",")
			if not isMember and not isTableKey and barcodeMap[tok.value] then
				rendered = barcodeMap[tok.value]
			end
		end

		if prevTok then
			local pt = prevTok.type
			local pv = prevTok.value
			local tt = tok.type
			local tv = tok.value

			if (pt == "ident" or pt == "number") and (tt == "ident" or tt == "number") then
				table.insert(outputParts, " ")
			elseif pt == "number" and string.sub(tv, 1, 1) == "." then
				table.insert(outputParts, " ")
			elseif pv == "return" or pv == "local" or pv == "then" or pv == "do" or pv == "else" or pv == "elseif"
				or pv == "function" or pv == "end" or pv == "in" or pv == "and" or pv == "or" or pv == "not"
				or pv == "repeat" or pv == "until" or pv == "for" or pv == "while" then
				table.insert(outputParts, " ")
			elseif tv == "and" or tv == "or" or tv == "not" or tv == "in" then
				table.insert(outputParts, " ")
			end
		end

		table.insert(outputParts, rendered)
		prevTok = tok
	end

	-- Build Header (Runtime Decryptor & Opaque Predicates)
	local headerLines = {}
	if #stringPool > 0 and opts.encryptStrings then
		table.insert(headerLines, string.format("local %s = { %d, %d, %d, %d }", varKeyTable, encKey[1], encKey[2], encKey[3], encKey[4]))
		table.insert(headerLines, string.format("local %s = {", varRawTable))
		for i, encStr in ipairs(stringPool) do
			table.insert(headerLines, string.format('  [(0x%X - 0x%X)] = "%s",', i + 50, 50, encStr))
		end
		table.insert(headerLines, "}")
		table.insert(headerLines, string.format([[
local %s = setmetatable({}, {
	__index = function(t, k)
		local r = %s[k]
		if not r then return nil end
		local o = {}
		for i = 1, #r do
			table.insert(o, string.char(bit32.bxor(string.byte(r, i), %s[((i - 1) %% 4) + 1])))
		end
		local d = table.concat(o)
		rawset(t, k, d)
		return d
	end
})]], varStrTable, varRawTable, varKeyTable))
	end

	if opts.opaquePredicates then
		local decoyFn = obfGenerateBarcode(bIndex); bIndex += 1
		local decoyVar = obfGenerateBarcode(bIndex); bIndex += 1
		table.insert(headerLines, string.format([[
local %s = (function(%s)
	local _c = bit32.bxor(0x5A, 0x5A)
	if _c ~= 0 then return nil end
	return true
end)()]], decoyFn, decoyVar))
	end

	local assembled = table.concat(outputParts)
	if #headerLines > 0 then
		return table.concat(headerLines, "\n") .. "\n" .. assembled
	else
		return assembled
	end
end

local function executeScriptObfuscation()
	local scripts, counts = getTargetScripts(obfOptions.includeChildren)
	local total = #scripts
	if total == 0 then
		oStatusLabel.Text = "⚠️ Tidak ada script yang dipilih! Silakan pilih Script, LocalScript, atau ModuleScript di Explorer."
		return
	end

	convertObfBtn.Text = "⏳ MEMPROSES OBFUSKASI..."
	convertObfBtn.AutoButtonColor = false

	local recordSuccess, recordId = pcall(function()
		return ChangeHistoryService:TryBeginRecording("Obfuscate Luau Scripts")
	end)

	local successCount = 0
	local failCount = 0

	for i, scriptInst in ipairs(scripts) do
		-- Safety Auto-Backup
		if obfOptions.autoBackup and scriptInst.Parent then
			pcall(function()
				local backupName = scriptInst.Name .. "_Backup"
				local existing = scriptInst.Parent:FindFirstChild(backupName)
				if not existing then
					local bak = scriptInst:Clone()
					bak.Name = backupName
					bak:SetAttribute("IsObfuscatorBackup", true)
					bak:SetAttribute("OriginalScript", scriptInst.Name)
					bak.Parent = scriptInst.Parent
				end
			end)
		end

		local ok, newSrc = pcall(function()
			return obfuscateLuauScript(scriptInst.Source, obfOptions)
		end)

		if ok and newSrc and #newSrc > 0 then
			scriptInst.Source = newSrc
			successCount += 1
		else
			failCount += 1
			warn(string.format("[Obfuscator] Gagal mengobfuscate script %s: %s", scriptInst.Name, tostring(newSrc)))
		end

		if i % 10 == 0 then
			oStatusLabel.Text = string.format("Memproses: %d / %d script...", i, total)
			task.wait()
		end
	end

	if recordSuccess and recordId then
		pcall(function()
			ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
		end)
	else
		pcall(function()
			ChangeHistoryService:SetWaypoint("Obfuscate Luau Scripts")
		end)
	end

	convertObfBtn.Text = "⚡ OBFUSCATE SCRIPT TERPILIH"
	convertObfBtn.AutoButtonColor = true
	applyMonochromeTheme()
	updateSelectionCounter()

	if failCount > 0 then
		oStatusLabel.Text = string.format("✓ Selesai: %d script berhasil di-obfuscate (%d gagal).", successCount, failCount)
	else
		oStatusLabel.Text = string.format("✓ Sukses mengobfuscate %d script!%s",
			successCount, obfOptions.autoBackup and " Backup otomatis tersimpan dengan akhiran _Backup." or "")
	end
end

local function executeRestoreBackup()
	local selected = Selection:Get()
	if #selected == 0 then
		oStatusLabel.Text = "⚠️ Pilih script yang ingin dipulihkan dari backup di Explorer."
		return
	end

	local recordSuccess, recordId = pcall(function()
		return ChangeHistoryService:TryBeginRecording("Restore Script from Backup")
	end)

	local restoredCount = 0

	for _, item in ipairs(selected) do
		if item:IsA("LuaSourceContainer") and item.Parent then
			local targetScript = nil
			local backupScript = nil

			if string.find(item.Name, "_Backup$") or item:GetAttribute("IsObfuscatorBackup") then
				backupScript = item
				local originalName = item:GetAttribute("OriginalScript") or string.gsub(item.Name, "_Backup$", "")
				targetScript = item.Parent:FindFirstChild(originalName)
			else
				targetScript = item
				backupScript = item.Parent:FindFirstChild(item.Name .. "_Backup")
			end

			if targetScript and backupScript and targetScript:IsA("LuaSourceContainer") and backupScript:IsA("LuaSourceContainer") then
				targetScript.Source = backupScript.Source
				restoredCount += 1
			end
		end
	end

	if recordSuccess and recordId then
		pcall(function()
			ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
		end)
	end

	if restoredCount > 0 then
		oStatusLabel.Text = string.format("✓ Sukses memulihkan %d script dari file backup!", restoredCount)
	else
		oStatusLabel.Text = "⚠️ Tidak menemukan backup yang cocok untuk item yang dipilih."
	end
	updateSelectionCounter()
end

local function previewObfuscation()
	local scripts, _ = getTargetScripts(obfOptions.includeChildren)
	if #scripts == 0 then
		oStatusLabel.Text = "⚠️ Pilih minimal 1 script di Explorer untuk melihat pratinjau."
		return
	end

	local target = scripts[1]
	local ok, res = pcall(function()
		return obfuscateLuauScript(target.Source, obfOptions)
	end)

	if not ok or not res then
		oStatusLabel.Text = "❌ Gagal menghasilkan pratinjau: " .. tostring(res)
		return
	end

	print("================================================================================")
	print(string.format("🔒 PRATINJAU OBFUSKASI: %s (%s)", target.Name, target.ClassName))
	print(string.format("Ukuran Asli: %d karakter | Ukuran Obfuscated: %d karakter", #target.Source, #res))
	print("--------------------------------------------------------------------------------")
	print(string.sub(res, 1, 600) .. (#res > 600 and "\n... [Output dipotong, total " .. #res .. " karakter]" or ""))
	print("================================================================================")

	oStatusLabel.Text = string.format("📋 Pratinjau script '%s' (%d karakter) telah dicetak ke Output console.", target.Name, #res)
end

convertObfBtn.MouseButton1Click:Connect(executeScriptObfuscation)
restoreBackupBtn.MouseButton1Click:Connect(executeRestoreBackup)
previewObfBtn.MouseButton1Click:Connect(previewObfuscation)

-- ==============================================================================
-- 13. Plugin Activation & Widget Lifecycle
-- ==============================================================================
toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	toggleButton:SetActive(widget.Enabled)
	if widget.Enabled then
		updateSelectionCounter()
	end
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	toggleButton:SetActive(widget.Enabled)
	if widget.Enabled then
		updateSelectionCounter()
	end
end)

updateSelectionCounter()
