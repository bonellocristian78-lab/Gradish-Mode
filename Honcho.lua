--[[
	HONCHO — entità custom per DOORS · Gradish Mode
	Motore: Roblox · Linguaggio: Luau · Tipo: script client da executor

	Come funziona
	- Corre sui PathfindNodes di tutte le stanze come Rush, con i piedi sul pavimento trovato da un
	  raycast sotto ogni nodo. Prima di partire fa sfarfallare le luci e tremare la camera, poi rompe
	  le luci delle stanze dove passa. Con _G.Rebounds torna indietro come Ambush.
	- Se sei a tiro, fuori da un nascondiglio e senza muri in mezzo, ti salta in faccia e muori.
	- Se hai in mano il crocifisso di PenguinManiack: il rituale. Il crocifisso ti vola davanti, sotto
	  di lui si apre il cerchio di DOORS, un pilastro di luce lo inchioda, le catene lo sollevano e lo
	  trascinano sotto terra mentre perde centinaia di fogli, poi esplode tutto e piovono fogli.
	- Texture, suono del crocifisso e animazioni sono asset di DOORS (LSPLASH): si caricano per ID,
	  senza getcustomasset.

	Lo vedi solo tu: è creato sul tuo client. Con _G.Sync = true aspetta la prossima porta, così chi
	esegue lo script insieme a te lo vede partire nello stesso momento.

	Uso
		loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/Honcho"))()

	Con le impostazioni: le righe _G vanno prima del loadstring (i nomi sono in IMPOSTAZIONI qui
	sotto). Vengono lette e poi cancellate, così il loadstring da solo torna ai valori normali.

	Se qualcosa non va: _G.Debug = true, poi scrivi /console in chat e leggi le righe [Honcho].

	Crediti: modello, animazioni e suoni di Honcho di LSPLASH via il morph di MorthenHubber ·
	texture e suono del rituale di LSPLASH via il Repentance di RegularVynixu · crocifisso di
	PenguinManiack · badge con DOORS Custom Achievements di RegularVynixu
]]

local CurrentRooms = workspace:FindFirstChild("CurrentRooms")
if not CurrentRooms then
	warn("[Honcho] non sei in una partita di DOORS: manca workspace.CurrentRooms")
	return
end

if workspace:FindFirstChild("SeekMovingNewClone") then
	warn("[Honcho] c'è l'inseguimento di Seek in corso: rieseguilo quando è finito")
	return
end

---====== IMPOSTAZIONI (sovrascrivibili con _G) ======---

local DEFAULTS = {
	Speed        = 70,    -- velocità in percentuale: 100 = Rush (65 stud/s), 70 ≈ 45 come il morph
	Delay        = 3,     -- secondi di avviso prima che parta: il tempo per nasconderti
	Size         = 1.2,   -- grandezza del modello
	KillRange    = 40,    -- da quanti stud ti prende
	Rebounds     = 0,     -- 0 = come Rush; 1 o più = torna indietro altrettante volte come Ambush
	Jumpscare    = true,  -- false = muori e basta
	GiveCrucifix = true,  -- ti dà il crocifisso di PenguinManiack se non ne hai già uno
	Papers       = 400,   -- quanti fogli perde quando lo esorcizzi
	Badges       = true,
	Sync         = false, -- true = parte alla prossima porta, nello stesso momento per chi lo esegue
	Debug        = false, -- true = scrive ogni passaggio nella console
}

local SETTINGS = {}
for key, default in pairs(DEFAULTS) do
	local value = _G[key]
	_G[key] = nil
	if value ~= nil and type(value) ~= type(default) then
		warn(("[Honcho] _G.%s deve essere un %s, uso %s"):format(key, type(default), tostring(default)))
		value = nil
	end
	SETTINGS[key] = if value == nil then default else value
end

---====== COSTANTI ======---

local MODEL_ID = 104515922403348

-- Le animazioni di Honcho sono di LSPLASH, quindi dentro DOORS partono
local ANIMATION_IDS = {
	Idle   = 101907348895136,
	Walk   = 100466662502744, -- "Sprint"
	Attack = 91194170893496,  -- "honcho_chase_cutscene_start"
}

local SOUND_IDS = {
	Scream     = 82613796053949,  -- "archives_honcho_cutscenelanding", LSPLASH
	Slam       = 74149238738530,  -- "Ground Slam Impact Shockwave"
	Crucifix   = 6555668806,      -- "usecrucifix", il suono vero del crocifisso di DOORS
	Earthquake = 9114219876,      -- quello del terremoto dello spawner di Vynixu, pubblico
}

-- Texture del rituale vero di DOORS, prese dal Repentance di Vynixu
local TEXTURES = {
	Circle  = { 11523868118, 11523868246, 11523868335, 11523868403 }, -- i quattro anelli del cerchio
	Chain   = 11517174215,
	Glow    = 6555900931,
	Spark   = 4998425421,
	Lines   = 11226108137,
	Twinkle = 134531489,
	Ball    = 12284064159,
	Dust    = 18496232079,
}

-- Le schegge del crocifisso di DOORS
local SHARD_MESHES = {
	6552335606, 6552335764, 6552335680, 6552335832,
	6552335635, 6552335563, 6552335722, 6552335799,
}

local CRUCIFIX_URL     = "https://raw.githubusercontent.com/PenguinManiack/Crucifix/main/Crucifix.lua"
local ACHIEVEMENTS_URL = "https://raw.githubusercontent.com/RegularVynixu/DOORS-Custom-Achievements/main/init.luau"

local RUSH_SPEED       = 65   -- stud/s di Rush, cioè Speed = 100
local MORPH_WALK_SPEED = 45   -- la WalkSpeed che il morph usa con la sua camminata
local TURN_SPEED       = 10
local CRUCIFIX_RANGE   = 40
local ENCOUNTER_RANGE  = 80
local SHAKE_RANGE      = 60
local REBOUND_DELAY    = 2
local JUMPSCARE_TIME   = 1.3  -- secondi che ti resta in faccia prima che tu muoia
local JUMPSCARE_GAP    = 3.2  -- stud tra la camera e la sua faccia
local LUNGE_TIME       = 0.18
local MAX_PAPERS       = 1500 -- oltre, sui telefoni scatta

local GUIDING = Color3.fromRGB(137, 207, 255) -- il blu della luce guida
local WHITE   = Color3.new(1, 1, 1)
local WOOD    = Color3.fromRGB(92, 64, 42)

local DEATH = {
	Cause  = "Honcho",
	Colour = "Blue", -- la schermata di morte: "Blue" come la luce guida o "Yellow"
	Hints  = {
		"You died to who you call Honcho...",
		"He makes the lights flicker and the ground shake before he arrives.",
		"Hide in a closet the moment that happens!",
		"Or hold up a crucifix and show him who is really in charge.",
	},
}

local BADGES = {
	-- La miniatura del modello. Se nel popup non si vede, metti un rbxassetid://
	Image = "rbxthumb://type=Asset&id=" .. MODEL_ID .. "&w=420&h=420",

	-- Identifier è la chiave con cui viene salvato: non cambiarlo dopo averlo usato
	Encounter = {
		Identifier = "Honcho_Encounter",
		Title      = "Big Honcho",
		Desc       = "Something bigger is running this hotel.",
		Reason     = "Encounter Honcho.",
	},
	Survive = {
		Identifier = "Honcho_Survive",
		Title      = "Not Today, Boss",
		Desc       = "You kept your job. And your life.",
		Reason     = "Survive Honcho.",
	},
	Death = {
		Identifier = "Honcho_Death",
		Title      = "You're Fired",
		Desc       = "Honcho does not like slackers.",
		Reason     = "Die to Honcho.",
	},
	Crucify = {
		Identifier = "Honcho_Crucify",
		Title      = "Early Retirement",
		Desc       = "Even the boss answers to someone.",
		Reason     = "Banish Honcho with a crucifix.",
	},
}

SETTINGS.Speed     = math.max(SETTINGS.Speed, 1)
SETTINGS.Size      = math.max(SETTINGS.Size, 0.2)
SETTINGS.Delay     = math.max(SETTINGS.Delay, 0)
SETTINGS.KillRange = math.max(SETTINGS.KillRange, 0)
SETTINGS.Rebounds  = math.max(math.floor(SETTINGS.Rebounds), 0)
SETTINGS.Papers    = math.clamp(math.floor(SETTINGS.Papers), 0, MAX_PAPERS)

---====== SERVIZI ======---

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService      = game:GetService("TweenService")
local ContentProvider   = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer

---====== LOG ======---

local function log(format, ...)
	if SETTINGS.Debug then
		print("[Honcho] " .. string.format(format, ...))
	end
end

local function problem(format, ...)
	warn("[Honcho] " .. string.format(format, ...))
end

-- Un thread per ogni parte: se una si rompe lo scrive in console invece di fermarsi in silenzio
local function spawnSafe(label, fn, ...)
	task.spawn(function(...)
		local ok, err = xpcall(fn, debug.traceback, ...)
		if not ok then
			problem("errore in %s: %s", label, tostring(err))
		end
	end, ...)
end

log("impostazioni: Speed %s, Delay %s, Size %s, KillRange %s, Rebounds %s, Jumpscare %s, GiveCrucifix %s, Papers %s, Badges %s, Sync %s",
	tostring(SETTINGS.Speed), tostring(SETTINGS.Delay), tostring(SETTINGS.Size), tostring(SETTINGS.KillRange),
	tostring(SETTINGS.Rebounds), tostring(SETTINGS.Jumpscare), tostring(SETTINGS.GiveCrucifix),
	tostring(SETTINGS.Papers), tostring(SETTINGS.Badges), tostring(SETTINGS.Sync))

---====== STATO ======---

if _G.HonchoCleanup then
	pcall(_G.HonchoCleanup)
end

local state = {
	model       = nil,
	position    = Vector3.zero,    -- dove sta il pivot, senza oscillazioni
	rotation    = CFrame.identity, -- verso dove guarda
	speed       = RUSH_SPEED * SETTINGS.Speed / 100,
	pivotHeight = 0,               -- quanto sta il pivot sopra i piedi
	headHeight  = 0,               -- quanto sta la testa sopra il pivot
	boxSize     = Vector3.one,
	running     = false,           -- sta facendo il percorso
	paused      = false,           -- fermo per il jumpscare o il rituale
	watching    = false,           -- controlla il giocatore, dopo l'avviso
	caught      = false,
	finished    = false,
	lastRoom    = nil,
}
local body: { [string]: any } = {}
local connections = {}
local cleanupTasks = {}

---====== UTILITÀ ======---

local function playerAlive()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function flatUnit(vector)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude < 0.05 then
		return nil
	end
	return flat.Unit
end

local function randomUnit()
	local vector = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
	if vector.Magnitude < 0.01 then
		return Vector3.yAxis
	end
	return vector.Unit
end

-- Una Part ancorata che non tocca, non blocca e non fa ombra
local function newPart(name, size, cframe, colour, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = colour
	part.Material = material
	part.Transparency = transparency
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function tween(instance, duration, goals, style, direction)
	local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
	local playing = TweenService:Create(instance, info, goals)
	playing:Play()
	return playing
end

local function flashScreen(colour, startTransparency, duration)
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "HonchoFlash"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = colour
	frame.BackgroundTransparency = startTransparency
	frame.Parent = gui

	gui.Parent = playerGui
	tween(frame, duration, { BackgroundTransparency = 1 })
	task.delay(duration + 0.1, function()
		gui:Destroy()
	end)
end

-- Un suono senza posizione, si sente uguale ovunque sei
local function playSound(soundId, volume, speed, parent)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundId
	sound.Volume = volume
	sound.PlaybackSpeed = speed or 1
	sound.Parent = parent
	sound:Play()
	task.delay(15, function()
		sound:Destroy()
	end)
	return sound
end

---====== DOORS ======---

local moduleEventsCache

-- Il modulo con cui DOORS fa sfarfallare e rompere le luci
local function moduleEvents()
	if moduleEventsCache == nil then
		local ok, result = pcall(function()
			return require(ReplicatedStorage:WaitForChild("ModulesClient", 5):WaitForChild("Module_Events", 5))
		end)
		moduleEventsCache = if ok then result else false
		if not ok then
			problem("Module_Events di DOORS non trovato, niente luci: %s", tostring(result))
		end
	end
	return moduleEventsCache or nil
end

-- Il camShaker di DOORS. Main_Game rinasce con te, quindi si prende ogni volta
local function shake(magnitude, roughness, fadeIn, fadeOut)
	pcall(function()
		local mainGame = require(LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game)
		mainGame.camShaker:ShakeOnce(magnitude, roughness, fadeIn, fadeOut)
	end)
end

local function latestRoomValue()
	local gameData = ReplicatedStorage:FindFirstChild("GameData")
	return gameData and gameData:FindFirstChild("LatestRoom")
end

local function latestRoomNumber()
	local value = latestRoomValue()
	return value and tonumber(value.Value) or math.huge
end

local function playerRoom()
	local number = LocalPlayer:GetAttribute("CurrentRoom")
	return number and CurrentRooms:FindFirstChild(tostring(number))
end

local function flickerRoom(room, duration)
	local events = moduleEvents()
	if room and events and events.flicker then
		pcall(events.flicker, room, duration)
	end
end

local function shatterRoom(room)
	local events = moduleEvents()
	if room and events and events.shatter then
		pcall(events.shatter, room)
	end
end

---====== BADGE (DOORS Custom Achievements di Vynixu) ======---

local badges = {
	library  = nil,
	queue    = {},
	draining = false,
	awarded  = {},
	retryAt  = 0,
}

local function loadBadgeLibrary()
	if badges.library then return badges.library end
	if os.clock() < badges.retryAt then return nil end

	local ok, library = pcall(function()
		return loadstring(game:HttpGet(ACHIEVEMENTS_URL))()
	end)
	if ok and library then
		badges.library = library
		log("badge di Vynixu caricati")
	else
		badges.retryAt = os.clock() + 5
		problem("non riesco a caricare i badge di Vynixu, riprovo: %s", tostring(library))
	end
	return badges.library
end

local function drainBadges()
	if badges.draining then return end
	badges.draining = true

	spawnSafe("badge", function()
		while #badges.queue > 0 do
			local library = loadBadgeLibrary()
			if library then
				local entry = table.remove(badges.queue, 1)
				pcall(function()
					library:Grant(entry, { CheckOwned = false, Remember = true })
				end)
				log("badge: %s", entry.Title)
				-- Due popup nello stesso momento si sovrascrivono
				task.wait(2.6)
			else
				task.wait(5)
			end
		end
		badges.draining = false
	end)
end

-- slot: "Encounter", "Survive", "Death" o "Crucify". Ognuno al massimo una volta per Honcho
local function award(slot)
	local badge = BADGES[slot]
	if not SETTINGS.Badges or badges.awarded[slot] then return end
	badges.awarded[slot] = true

	table.insert(badges.queue, {
		Identifier = badge.Identifier,
		Title      = badge.Title,
		Desc       = badge.Desc,
		Reason     = badge.Reason,
		Image      = BADGES.Image,
	})
	drainBadges()
end

---====== MORTE ======---

local function fireDeathHints()
	if not firesignal then
		problem("l'executor non ha firesignal: niente messaggi sulla schermata di morte")
		return
	end

	spawnSafe("messaggi di morte", function()
		-- DOORS ascolta i messaggi solo quando la schermata di morte è visibile
		local screen = LocalPlayer.PlayerGui:WaitForChild("MainUI"):WaitForChild("Death")
		if not screen.Visible then
			screen:GetPropertyChangedSignal("Visible"):Wait()
		end
		firesignal(ReplicatedStorage.RemotesFolder.DeathHint.OnClientEvent, DEATH.Hints, DEATH.Colour)
	end)
end

local function killPlayer(humanoid)
	state.caught = true
	pcall(function()
		ReplicatedStorage.GameStats["Player_" .. LocalPlayer.Name].Total.DeathCause.Value = DEATH.Cause
	end)
	humanoid.Health = 0
	award("Death")
	fireDeathHints()
	log("ti ha ucciso")
end

---====== MODELLO ======---

local function prepareModel()
	local ok, model = pcall(function()
		return game:GetObjects("rbxassetid://" .. MODEL_ID)[1]
	end)
	if not ok or typeof(model) ~= "Instance" or not model:IsA("Model") then
		return nil
	end

	local humanoid = model:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid then
		humanoid:Destroy()
	end

	local root = model:FindFirstChild("HumanoidRootPart", true)
		or model:FindFirstChild("RootPart", true)
		or model.PrimaryPart
		or model:FindFirstChildWhichIsA("BasePart", true)
	if not (root and root:IsA("BasePart")) then
		return nil
	end
	model.PrimaryPart = root
	model.Name = "Honcho"

	-- Solo il root ancorato, così i Motor6D si animano. È un fantasma: non tocca e non blocca niente
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = part == root
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end

	model:ScaleTo(SETTINGS.Size)

	local pivot = model:GetPivot().Position
	local boxCFrame, boxSize = model:GetBoundingBox()
	state.pivotHeight = pivot.Y - (boxCFrame.Position.Y - boxSize.Y / 2)
	state.boxSize = boxSize

	local head = model:FindFirstChild("Head", true)
	if head and head:IsA("BasePart") then
		state.headHeight = head.Position.Y - pivot.Y
	else
		state.headHeight = (boxCFrame.Position.Y + boxSize.Y / 2 - pivot.Y) * 0.9
	end

	return model
end

-- Scarica prima texture e suoni del rituale, così quando serve appare tutto subito
local function preloadRitual()
	local ids = {}
	for _, textureId in ipairs(TEXTURES.Circle) do
		table.insert(ids, "rbxassetid://" .. textureId)
	end
	for _, key in ipairs({ "Chain", "Glow", "Spark", "Lines", "Twinkle", "Ball", "Dust" }) do
		table.insert(ids, "rbxassetid://" .. TEXTURES[key])
	end
	for _, soundId in pairs(SOUND_IDS) do
		table.insert(ids, "rbxassetid://" .. soundId)
	end
	pcall(function()
		ContentProvider:PreloadAsync(ids)
	end)
	log("rituale precaricato")
end

---====== CORPO (animazioni e rotazione) ======---

local function loadTrack(animator, name, looped, priority)
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. ANIMATION_IDS[name]
	local track = animator:LoadAnimation(animation)
	track.Looped = looped
	track.Priority = priority
	return track
end

-- Va chiamata con il modello già in workspace, altrimenti LoadAnimation fallisce
local function setupBody()
	local model = state.model
	local controller = model:FindFirstChildWhichIsA("AnimationController")
		or model:FindFirstChildWhichIsA("AnimationController", true)
	if not controller then
		controller = Instance.new("AnimationController")
		controller.Parent = model
	end

	local animator = controller:FindFirstChildWhichIsA("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = controller
	end

	body.idle   = loadTrack(animator, "Idle", true, Enum.AnimationPriority.Idle)
	body.walk   = loadTrack(animator, "Walk", true, Enum.AnimationPriority.Movement)
	body.attack = loadTrack(animator, "Attack", false, Enum.AnimationPriority.Action)

	-- Più è grande più il passo è lungo, quindi la camminata rallenta della stessa scala
	body.walkRate = math.clamp(state.speed / (MORPH_WALK_SPEED * SETTINGS.Size), 0.5, 3)
	body.stepRate = math.pi * state.speed / (7 * SETTINGS.Size)

	local footsteps = model:FindFirstChild("Footsteps", true)
	if footsteps and footsteps:IsA("Sound") then
		footsteps.Looped = true
		body.footsteps = footsteps
	end

	local scream = Instance.new("Sound")
	scream.Name = "HonchoScream"
	scream.SoundId = "rbxassetid://" .. SOUND_IDS.Scream
	scream.Volume = 2
	scream.RollOffMinDistance = 20
	scream.Parent = model.PrimaryPart
	body.scream = scream

	-- Dopo qualche secondo si sa cosa non ha caricato. Se manca la camminata, ondeggia a mano
	task.delay(4, function()
		if state.finished then return end
		for name, track in pairs({ Idle = body.idle, Walk = body.walk, Attack = body.attack }) do
			if track.Length == 0 then
				problem("l'animazione %s non si è caricata", name)
			end
		end
		if not scream.IsLoaded then
			problem("il suono di Honcho non si è caricato")
		end
		body.walkBroken = body.walk.Length == 0
	end)
end

local function setMoving(moving)
	if not body.walk or body.moving == moving then return end
	-- Durante jumpscare e rituale comandano loro
	if moving and state.paused then return end
	body.moving = moving

	if moving then
		body.idle:Stop(0.25)
		body.walk:Play(0.25, 1, body.walkRate)
		if body.footsteps then body.footsteps:Play() end
	else
		body.walk:Stop(0.25)
		body.idle:Play(0.25)
		if body.footsteps then body.footsteps:Stop() end
	end
end

local function render(offset)
	local cframe = CFrame.new(state.position) * state.rotation
	if offset then
		cframe *= offset
	end
	state.model:PivotTo(cframe)
end

-- Se la camminata non parte, almeno ondeggia a ogni passo invece di scivolare
local function walkBob()
	if not body.walkBroken or not body.moving then
		return nil
	end
	local phase = os.clock() * body.stepRate
	return CFrame.new(0, math.abs(math.sin(phase)) * 0.35 * SETTINGS.Size, 0)
		* CFrame.Angles(0, 0, math.sin(phase) * math.rad(4))
end

---====== PERCORSO ======---

local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Exclude
floorParams.RespectCanCollide = true

local function characters()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	return list
end

-- L'altezza del pavimento sotto un punto; fallbackY se il raycast non trova niente
local function floorAt(point, fallbackY)
	floorParams.FilterDescendantsInstances = characters()
	local hit = workspace:Raycast(point + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), floorParams)
	return if hit then hit.Position.Y else fallbackY
end

local function sortedNodePositions(folder)
	local nodes = {}
	for _, node in ipairs(folder:GetChildren()) do
		if node:IsA("BasePart") and tonumber(node.Name) then
			table.insert(nodes, node)
		end
	end
	table.sort(nodes, function(a, b)
		return (tonumber(a.Name) :: number) < (tonumber(b.Name) :: number)
	end)

	local positions = {}
	for index, node in ipairs(nodes) do
		positions[index] = node.Position
	end
	return positions
end

-- DOORS toglie le cartelle PathfindNodes dalle stanze durante la partita. Questo listener, uno
-- solo per partita, ne salva le posizioni prima che spariscano
local nodeCache = _G.HonchoNodeCache or setmetatable({}, { __mode = "k" })
_G.HonchoNodeCache = nodeCache
if not _G.HonchoNodeWatcher then
	_G.HonchoNodeWatcher = CurrentRooms.DescendantRemoving:Connect(function(instance)
		local room = instance.Parent
		if instance.Name == "PathfindNodes" and room and room.Parent == CurrentRooms then
			nodeCache[room] = sortedNodePositions(instance)
		end
	end)
end

-- Entrata, nodi e uscita di ogni stanza in ordine, ognuno appoggiato al pavimento
local function buildPath()
	local rooms = {}
	for _, room in ipairs(CurrentRooms:GetChildren()) do
		if tonumber(room.Name) then
			table.insert(rooms, room)
		end
	end
	table.sort(rooms, function(a, b)
		return (tonumber(a.Name) :: number) < (tonumber(b.Name) :: number)
	end)

	local path = {}
	local function add(room, position, fallbackY)
		local floorY = floorAt(position, fallbackY)
		table.insert(path, { room = room, position = Vector3.new(position.X, floorY, position.Z) })
	end

	for _, room in ipairs(rooms) do
		-- Entrata e uscita stanno circa 3 stud sopra il pavimento, come le tratta lo spawner di Vynixu
		local entrance = room:FindFirstChild("RoomEntrance")
		if entrance and entrance:IsA("BasePart") then
			add(room, entrance.Position, entrance.Position.Y - 3)
		end

		local folder = room:FindFirstChild("PathfindNodes")
		local nodes = (folder and sortedNodePositions(folder)) or nodeCache[room] or {}
		for _, position in ipairs(nodes) do
			add(room, position, position.Y)
		end

		local exit = room:FindFirstChild("RoomExit")
		if exit and exit:IsA("BasePart") then
			add(room, exit.Position, exit.Position.Y - 3)
		end
	end
	return path
end

local function reversed(list)
	local copy = {}
	for index = #list, 1, -1 do
		table.insert(copy, list[index])
	end
	return copy
end

---====== FOGLI ======---
--[[ Ogni foglio è una Part sottile e ancorata, e si muovono tutti insieme con BulkMoveTo, che per
     centinaia di parti costa molto meno che muoverle una per una. Esce di corsa, l'aria lo
     frena, scende ondeggiando e girando, si posa sul pavimento e sparisce piano. ]]

local PAPER_COLOURS = {
	Color3.fromRGB(246, 243, 235),
	Color3.fromRGB(236, 229, 212),
	Color3.fromRGB(226, 226, 226),
	Color3.fromRGB(242, 232, 204),
}
local PAPER_GRAVITY = 14
local PAPER_DRAG    = 2.2  -- con la gravità dà una caduta massima di circa 6 stud/s, da foglio

local papers = { list = {}, folder = nil, connection = nil }

local function updatePapers(deltaTime)
	local parts, cframes = {}, {}
	local list = papers.list

	-- Al contrario, così togliere un foglio scambiandolo con l'ultimo non ne salta nessuno
	for index = #list, 1, -1 do
		local paper = list[index]
		paper.age += deltaTime

		if paper.age >= paper.life then
			paper.part:Destroy()
			list[index] = list[#list]
			list[#list] = nil
		else
			if not paper.landed then
				paper.velocity += Vector3.new(0, -PAPER_GRAVITY * deltaTime, 0)
				paper.velocity *= math.max(0, 1 - PAPER_DRAG * deltaTime)
				local sway = paper.swayDirection * (math.sin(paper.age * paper.swaySpeed + paper.swayPhase) * 2.5)
				paper.position += (paper.velocity + sway) * deltaTime
				paper.angle += paper.spin * deltaTime

				if paper.position.Y <= paper.floorY then
					paper.landed = true
					paper.position = Vector3.new(paper.position.X, paper.floorY, paper.position.Z)
					paper.cframe = CFrame.new(paper.position) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
				else
					paper.cframe = CFrame.new(paper.position) * CFrame.fromAxisAngle(paper.axis, paper.angle)
				end
			end

			local remaining = paper.life - paper.age
			if remaining < 1 then
				paper.part.Transparency = 1 - remaining
			end
			table.insert(parts, paper.part)
			table.insert(cframes, paper.cframe)
		end
	end

	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end

	if #list == 0 and papers.connection then
		papers.connection:Disconnect()
		papers.connection = nil
		papers.folder:Destroy()
		papers.folder = nil
	end
end

local function spawnPaper(position, floorY, velocity, life)
	if not papers.folder then
		papers.folder = Instance.new("Folder")
		papers.folder.Name = "HonchoPapers"
		papers.folder.Parent = workspace
	end

	local length = 0.7 + math.random() * 0.5
	local colour = PAPER_COLOURS[math.random(#PAPER_COLOURS)]
	local part = newPart("Paper", Vector3.new(length * 0.78, 0.02, length), CFrame.new(position), colour, Enum.Material.SmoothPlastic, 0)
	part.Parent = papers.folder

	table.insert(papers.list, {
		part          = part,
		position      = position,
		velocity      = velocity,
		cframe        = part.CFrame,
		axis          = randomUnit(),
		angle         = math.random() * math.pi * 2,
		spin          = (math.random() * 2 - 1) * 7,
		swayDirection = flatUnit(randomUnit()) or Vector3.xAxis,
		swaySpeed     = 3 + math.random() * 3,
		swayPhase     = math.random() * math.pi * 2,
		age           = 0,
		life          = life or (5 + math.random() * 3),
		floorY        = floorY + 0.03,
		landed        = false,
	})

	if not papers.connection then
		papers.connection = RunService.Heartbeat:Connect(updatePapers)
	end
end

-- count fogli da punti a caso dentro il suo corpo, sparati in fuori e un po' in alto
local function burstFromBody(count, floorY)
	local model = state.model
	if count <= 0 or not model or not model.Parent then return end

	local boxCFrame, boxSize = model:GetBoundingBox()
	for _ = 1, count do
		local offset = Vector3.new(
			(math.random() - 0.5) * boxSize.X,
			(math.random() - 0.5) * boxSize.Y,
			(math.random() - 0.5) * boxSize.Z
		) * 0.8
		local direction = (randomUnit() + Vector3.new(0, 0.9, 0)).Unit
		spawnPaper(boxCFrame:PointToWorldSpace(offset), floorY, direction * (8 + math.random() * 16))
	end
end

-- count fogli che schizzano su dal buco dove è sparito
local function geyser(count, center, radius, floorY)
	for _ = 1, count do
		local angle = math.random() * math.pi * 2
		local distance = math.random() * radius * 0.5
		local origin = center + Vector3.new(math.cos(angle) * distance, 0.5, math.sin(angle) * distance)
		local direction = (Vector3.new(math.cos(angle) * 0.5, 1, math.sin(angle) * 0.5) + randomUnit() * 0.35).Unit
		spawnPaper(origin, floorY, direction * (16 + math.random() * 22))
	end
end

---====== FINE ======---

local dismiss

local function finish(reason)
	if state.finished then return end
	state.finished = true
	state.running = false
	state.watching = false
	log("fine: %s", reason)

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)

	for _, cleanup in ipairs(cleanupTasks) do
		pcall(cleanup)
	end
	table.clear(cleanupTasks)

	if state.model then
		state.model:Destroy()
	end
	if _G.HonchoCleanup == dismiss then
		_G.HonchoCleanup = nil
	end
end

dismiss = function()
	finish("tolto da una nuova esecuzione")
end

---====== JUMPSCARE ======---

local function jumpscare(humanoid)
	award("Encounter")
	log("ti ha preso")

	if not SETTINGS.Jumpscare then
		killPlayer(humanoid)
		finish("ti ha preso")
		return
	end

	local model = state.model

	-- Dove sta la testa rispetto al pivot, così è proprio la faccia a finire davanti alla camera
	local headOffset = Vector3.new(0, state.headHeight, 0)
	local head = model:FindFirstChild("Head", true)
	if head and head:IsA("BasePart") then
		headOffset = model:GetPivot():PointToObjectSpace(head.Position)
	end

	pcall(function()
		body.walk:Stop(0.05)
		if body.footsteps then body.footsteps:Stop() end
		-- L'idle resta sotto l'attacco, così quando l'attacco finisce non resta in posa rigida
		if not body.idle.IsPlaying then body.idle:Play(0.05) end
		body.attack:Play(0.05)
		body.scream:Play()
	end)
	shake(10, 12, 0.05, 1.5)

	-- Parte da più lontano e ti salta addosso in LUNGE_TIME, poi resta davanti alla camera
	-- ovunque guardi, con la faccia all'altezza dei tuoi occhi
	local startedAt = os.clock()
	local far = JUMPSCARE_GAP * 2.5
	local flashed = false
	local stepName = "HonchoJumpscare" .. tostring(startedAt)

	RunService:BindToRenderStep(stepName, Enum.RenderPriority.Camera.Value + 1, function()
		local view = workspace.CurrentCamera.CFrame
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local forward = flatUnit(view.LookVector)
			or (root and flatUnit(root.CFrame.LookVector))
			or Vector3.new(0, 0, -1)

		local progress = math.clamp((os.clock() - startedAt) / LUNGE_TIME, 0, 1)
		local gap = far + (JUMPSCARE_GAP - far) * (1 - (1 - progress) ^ 3)
		local rotation = CFrame.lookAt(Vector3.zero, -forward)
		local facePosition = view.Position + forward * gap
		model:PivotTo(CFrame.new(facePosition - rotation:VectorToWorldSpace(headOffset)) * rotation)

		if progress >= 1 and not flashed then
			flashed = true
			flashScreen(Color3.fromRGB(150, 0, 0), 0.35, 0.5)
		end
	end)
	table.insert(cleanupTasks, function()
		RunService:UnbindFromRenderStep(stepName)
	end)

	task.wait(JUMPSCARE_TIME)
	if humanoid.Parent and humanoid.Health > 0 then
		killPlayer(humanoid)
	end

	-- Resta in faccia mentre cadi, poi sparisce
	task.wait(1)
	finish("jumpscare")
end

---====== VFX ======---

-- Il cilindro di Roblox ha l'asse su X: girato di 90 gradi sta in piedi
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

local function sequence(points)
	local keypoints = {}
	for _, point in ipairs(points) do
		table.insert(keypoints, NumberSequenceKeypoint.new(point[1], point[2]))
	end
	return NumberSequence.new(keypoints)
end

local function elasticOut(x)
	if x <= 0 or x >= 1 then
		return math.clamp(x, 0, 1)
	end
	return 2 ^ (-10 * x) * math.sin((x * 10 - 0.75) * (2 * math.pi / 3)) + 1
end

local function backIn(x)
	return 2.70158 * x ^ 3 - 1.70158 * x ^ 2
end

local function makeEmitter(parent, textureId)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://" .. textureId
	emitter.Color = ColorSequence.new(GUIDING)
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Rate = 0
	emitter.Parent = parent
	return emitter
end

-- Un disco piatto con un'immagine di DOORS che brilla da sola: SurfaceGui che ignora la luce
local function glowDisc(folder, name, center, diameter, textureId, colour, height)
	local disc = newPart(name, Vector3.new(diameter, 0.02, diameter), CFrame.new(center + Vector3.new(0, height, 0)), colour, Enum.Material.SmoothPlastic, 1)
	disc.Parent = folder

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.LightInfluence = 0
	gui.Brightness = 4
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 32
	gui.Parent = disc

	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Image = "rbxassetid://" .. textureId
	image.ImageColor3 = colour
	image.ImageTransparency = 1
	image.Parent = gui

	return disc, image
end

-- Un anello di DOORS che si allarga sul pavimento e sparisce
local function ringWave(folder, center, fromDiameter, toDiameter, duration, colour)
	local disc, image = glowDisc(folder, "RingWave", center, fromDiameter, TEXTURES.Circle[1], colour, 0.2)
	image.ImageTransparency = 0
	tween(disc, duration, { Size = Vector3.new(toDiameter, 0.02, toDiameter) }, Enum.EasingStyle.Quart)
	tween(image, duration, { ImageTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(duration + 0.05, function()
		disc:Destroy()
	end)
end

-- Una sfera di energia che si gonfia e svanisce
local function sphereWave(folder, position, toSize, duration, colour)
	local ball = newPart("SphereWave", Vector3.one, CFrame.new(position), colour, Enum.Material.ForceField, 0)
	ball.Shape = Enum.PartType.Ball
	ball.Parent = folder
	tween(ball, duration, { Size = Vector3.one * toSize, Transparency = 1 }, Enum.EasingStyle.Quart)
	task.delay(duration + 0.05, function()
		ball:Destroy()
	end)
end

-- Una fiammata di scintille rotonde, quelle che DOORS usa quando il crocifisso esplode
local function sparkBurst(parent, count, speed)
	local burst = makeEmitter(parent, TEXTURES.Ball)
	burst.Brightness = 3
	burst.Lifetime = NumberRange.new(0.4, 1.8)
	burst.Speed = NumberRange.new(speed * 0.3, speed)
	burst.Drag = 3
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Size = sequence({ { 0, 0.7 }, { 0.12, 0.35 }, { 0.4, 0.1 }, { 1, 0 } })
	burst.Transparency = sequence({ { 0, 0 }, { 0.9, 0 }, { 1, 1 } })
	burst:Emit(count)
	task.delay(2, function()
		burst:Destroy()
	end)
end

-- Colore, contrasto e bloom solo sul tuo schermo, finché dura il rituale
local function postEffects()
	local camera = workspace.CurrentCamera
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "HonchoGrade"
	grade.Parent = camera

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "HonchoBloom"
	bloom.Intensity = 0
	bloom.Size = 30
	bloom.Threshold = 2
	bloom.Parent = camera

	table.insert(cleanupTasks, function()
		grade:Destroy()
		bloom:Destroy()
	end)
	return grade, bloom
end

-- Un calcio al campo visivo che torna piano. Se DOORS rimette il suo FOV ogni frame, non si vede
local function fovPunch(amount, duration)
	local camera = workspace.CurrentCamera
	local base = camera.FieldOfView
	local startedAt = os.clock()
	local stepName = "HonchoFov" .. tostring(startedAt)

	RunService:BindToRenderStep(stepName, Enum.RenderPriority.Last.Value, function()
		local progress = (os.clock() - startedAt) / duration
		if progress >= 1 then
			camera.FieldOfView = base
			RunService:UnbindFromRenderStep(stepName)
			return
		end
		camera.FieldOfView = base + amount * (1 - progress) ^ 3
	end)
	table.insert(cleanupTasks, function()
		pcall(function()
			RunService:UnbindFromRenderStep(stepName)
		end)
		camera.FieldOfView = base
	end)
end

-- Il terremoto di Vynixu rifatto senza asset: polvere da tutti i soffitti vicini
local function ceilingDust(center)
	for _, ceiling in ipairs(CollectionService:GetTagged("PartCeiling")) do
		if ceiling:IsA("BasePart") and (ceiling.Position - center).Magnitude < 90 then
			local dust = makeEmitter(ceiling, TEXTURES.Dust)
			dust.Color = ColorSequence.new(Color3.fromRGB(165, 160, 150))
			dust.LightEmission = 0
			dust.LightInfluence = 1
			dust.EmissionDirection = Enum.NormalId.Bottom
			dust.Acceleration = Vector3.new(0, -10, 0)
			dust.Lifetime = NumberRange.new(1, 3)
			dust.Speed = NumberRange.new(3, 12)
			dust.SpreadAngle = Vector2.new(60, 60)
			dust.Size = sequence({ { 0, 2.1 }, { 1, 1.3 } })
			dust.Transparency = sequence({ { 0, 1 }, { 0.23, 0.86 }, { 0.8, 0.89 }, { 1, 1 } })
			dust.RotSpeed = NumberRange.new(-35, 35)
			dust.Rotation = NumberRange.new(-360, 360)
			dust:Emit(math.clamp(math.floor(ceiling.Size.Magnitude * 0.07), 3, 15))
			task.delay(4, function()
				dust:Destroy()
			end)
		end
	end
end

---====== RITUALE DEL CROCIFISSO ======---

-- Il crocifisso di PenguinManiack esce dalla tua mano e diventa un modello che fluttua
local function floatingCrucifix(tool, folder)
	local handle = tool:FindFirstChild("Handle")
	local startCFrame = if handle and handle:IsA("BasePart")
		then handle.CFrame
		else workspace.CurrentCamera.CFrame * CFrame.new(0.8, -0.8, -2)

	tool.Archivable = true
	local copy = tool:Clone()
	-- Si consuma, come quello vero di DOORS
	tool:Destroy()

	local crucifix = Instance.new("Model")
	crucifix.Name = "HonchoCrucifix"
	if copy then
		for _, child in ipairs(copy:GetChildren()) do
			child.Parent = crucifix
		end
		copy:Destroy()
	end

	for _, descendant in ipairs(crucifix:GetDescendants()) do
		if descendant:IsA("LuaSourceContainer") or descendant:IsA("TouchTransmitter") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	local primary = crucifix:FindFirstChild("Handle") or crucifix:FindFirstChildWhichIsA("BasePart", true)
	if not (primary and primary:IsA("BasePart")) then
		-- Il tool non aveva parti: due assi di legno, come il buildCrucifix di GradishCore
		crucifix:ClearAllChildren()
		primary = newPart("Handle", Vector3.new(0.22, 1.7, 0.22), startCFrame, WOOD, Enum.Material.Wood, 0)
		primary.Parent = crucifix
		newPart("Crossbar", Vector3.new(0.95, 0.22, 0.22), startCFrame * CFrame.new(0, 0.42, 0), WOOD, Enum.Material.Wood, 0).Parent = crucifix
	end

	crucifix.PrimaryPart = primary :: BasePart
	crucifix:PivotTo(startCFrame)
	crucifix.Parent = folder
	return crucifix, startCFrame
end

-- Alla fine il crocifisso si spezza nelle schegge del crocifisso di DOORS, che cadono davvero
local function shatterCrucifix(crucifix, folder)
	local at = crucifix:GetPivot().Position
	for _, descendant in ipairs(crucifix:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
		end
	end

	for _, meshId in ipairs(SHARD_MESHES) do
		local spin = CFrame.Angles(math.random() * 6.28, math.random() * 6.28, math.random() * 6.28)
		local shard = newPart("Shard", Vector3.one * 0.3, CFrame.new(at + randomUnit() * 0.3) * spin, WOOD, Enum.Material.Wood, 0)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId = "rbxassetid://" .. meshId
		mesh.Parent = shard
		shard.Anchored = false
		shard.CanCollide = true
		shard.Parent = folder
		shard.AssemblyLinearVelocity = randomUnit() * 16 + Vector3.new(0, 12, 0)
		shard.AssemblyAngularVelocity = randomUnit() * 25
		task.delay(2.4, function()
			tween(shard, 0.6, { Transparency = 1 })
		end)
	end
end

-- Una catena di DOORS: la texture scorre come nel rituale vero
local function chainBeam(parent, from, to)
	local beam = Instance.new("Beam")
	beam.Attachment0 = from
	beam.Attachment1 = to
	beam.Texture = "rbxassetid://" .. TEXTURES.Chain
	beam.TextureMode = Enum.TextureMode.Static
	beam.TextureLength = 1
	beam.TextureSpeed = -2
	beam.FaceCamera = true
	beam.Width0 = 1
	beam.Width1 = 0.75
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Color = ColorSequence.new(GUIDING)
	beam.Transparency = NumberSequence.new(0)
	beam.Segments = 1
	beam.Parent = parent
	return beam
end

-- Un raggio di luce dall'alto
local function lightRay(parent, from, to)
	local beam = Instance.new("Beam")
	beam.Attachment0 = from
	beam.Attachment1 = to
	beam.Texture = "rbxassetid://" .. TEXTURES.Glow
	beam.TextureSpeed = 0.44
	beam.FaceCamera = true
	beam.Width0 = 3
	beam.Width1 = 0.8
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Color = ColorSequence.new(WHITE, GUIDING)
	beam.Transparency = sequence({ { 0, 1 }, { 0.2, 0.45 }, { 1, 0.15 } })
	beam.Segments = 1
	beam.Parent = parent
	return beam
end

local function attachmentAt(parent, worldPosition)
	local attachment = Instance.new("Attachment")
	attachment.Position = parent.CFrame:PointToObjectSpace(worldPosition)
	attachment.Parent = parent
	return attachment
end

--[[ Il rituale dura circa 9 secondi e segue il suono vero del crocifisso di DOORS: alla parte
     che sale lui viene sollevato e incatenato, al colpo finale sparisce e scoppia tutto.
     Un solo ciclo per frame muove cerchio, crocifisso, lui e i fogli; il resto sono momenti
     fissi del copione qui sotto. ]]
local function ritual(tool)
	local model = state.model
	local root = model.PrimaryPart
	award("Encounter")
	log("rituale del crocifisso")

	local folder = Instance.new("Folder")
	folder.Name = "HonchoRitual"
	folder.Parent = workspace
	table.insert(cleanupTasks, function()
		folder:Destroy()
	end)

	-- Si ferma e si gira verso di te
	setMoving(false)
	local character = LocalPlayer.Character
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	if playerRoot then
		local toPlayer = flatUnit(playerRoot.Position - state.position)
		if toPlayer then
			state.rotation = CFrame.lookAt(Vector3.zero, toPlayer)
		end
	end
	render()

	local basePosition = state.position
	local floorY = floorAt(state.position, state.position.Y - state.pivotHeight)
	local center = Vector3.new(state.position.X, floorY, state.position.Z)
	local radius = math.clamp(math.max(state.boxSize.X, state.boxSize.Z) / 2 + 4, 6, 16)
	local depth = state.pivotHeight + state.headHeight + 5
	local headLocal = Vector3.new(0, state.headHeight, 0)

	local total = SETTINGS.Papers
	local streamBudget = math.floor(total * 0.4)
	local geyserBudget = math.floor(total * 0.35)
	local rainBudget = total - streamBudget - geyserBudget

	local startedAt = os.clock()
	local function at(seconds)
		local wait = startedAt + seconds - os.clock()
		if wait > 0 then
			task.wait(wait)
		end
	end

	-- Cosa comanda il ciclo per frame
	local show = {
		layers      = {},
		layerSpeeds = { 24, -38, 55, -14 }, -- gradi al secondo, ognuno per conto suo
		spinBoost   = 1,
		lift        = 0,
		jitter      = 0,
		streamLeft  = streamBudget,
		streamRate  = 0,
		streamCarry = 0,
		crucifixSpin = 1.6,
	}

	---- 0. IL COLPO: flash, calcio al FOV, camera, il suono vero del crocifisso ----
	local grade, bloom = postEffects()
	flashScreen(WHITE, 0.15, 0.35)
	fovPunch(12, 0.6)
	shake(7, 10, 0, 0.8)
	playSound(SOUND_IDS.Crucifix, 1, 1, folder)
	flickerRoom(playerRoom(), 2)
	tween(grade, 0.4, { TintColor = Color3.fromRGB(205, 228, 255), Contrast = 0.25, Saturation = -0.35 })
	tween(bloom, 0.4, { Intensity = 1.2, Threshold = 0.9 })

	-- Il crocifisso ti lascia la mano e ti vola davanti, girando sempre più forte
	local crucifix, fromCFrame = floatingCrucifix(tool, folder)
	local crucifixPart = crucifix.PrimaryPart :: BasePart

	local crucifixLight = Instance.new("PointLight")
	crucifixLight.Color = GUIDING
	crucifixLight.Brightness = 0
	crucifixLight.Range = 16
	crucifixLight.Parent = crucifixPart
	tween(crucifixLight, 0.5, { Brightness = 4 })

	local crucifixGlow = Instance.new("Highlight")
	crucifixGlow.FillColor = GUIDING
	crucifixGlow.FillTransparency = 0.5
	crucifixGlow.OutlineColor = WHITE
	crucifixGlow.OutlineTransparency = 0
	crucifixGlow.Parent = crucifix

	local twinkles = makeEmitter(crucifixPart, TEXTURES.Twinkle)
	twinkles.Rate = 25
	twinkles.Lifetime = NumberRange.new(0.4, 1)
	twinkles.SpreadAngle = Vector2.new(180, 180)
	twinkles.Speed = NumberRange.new(1, 3)
	twinkles.Size = sequence({ { 0, 0.5 }, { 0.3, 1.8 }, { 0.35, 0.45 }, { 1, 0.3 } })
	twinkles.Transparency = sequence({ { 0, 0.3 }, { 1, 1 } })
	twinkles.RotSpeed = NumberRange.new(-10, 10)

	local floatAt = fromCFrame.Position + Vector3.new(0, 1.2, 0)
	if playerRoot then
		local toHoncho = flatUnit(state.position - playerRoot.Position) or Vector3.new(0, 0, -1)
		floatAt = playerRoot.Position + toHoncho * 3 + Vector3.new(0, 1.8, 0)
	end
	sphereWave(folder, floatAt, 14, 0.6, WHITE)

	local crucifixAngle = 0
	table.insert(connections, RunService.RenderStepped:Connect(function(deltaTime)
		local elapsed = os.clock() - startedAt

		-- crocifisso
		if crucifix.Parent then
			crucifixAngle += show.crucifixSpin * deltaTime
			local rise = 1 - (1 - math.clamp(elapsed / 0.6, 0, 1)) ^ 3
			local position = fromCFrame.Position:Lerp(floatAt, rise) + Vector3.new(0, math.sin(elapsed * 2.2) * 0.15 * rise, 0)
			crucifix:PivotTo(CFrame.new(position) * CFrame.Angles(0, crucifixAngle, 0) * fromCFrame.Rotation)
		end

		-- cerchio
		for index, image in ipairs(show.layers) do
			image.Rotation = (image.Rotation + show.layerSpeeds[index] * show.spinBoost * deltaTime) % 360
		end

		-- lui: sollevato dalle catene, poi trascinato giù, sempre scosso
		if model.Parent then
			local drag = depth * backIn(math.clamp((elapsed - 2.5) / 3.3, 0, 1))
			state.position = basePosition + Vector3.new(0, show.lift - drag, 0)
			local j = show.jitter
			render(CFrame.new((math.random() - 0.5) * j, (math.random() - 0.5) * j * 0.6, (math.random() - 0.5) * j)
				* CFrame.Angles((math.random() - 0.5) * j * 0.2, (math.random() - 0.5) * j * 0.3, (math.random() - 0.5) * j * 0.2))

			-- fogli che perde di continuo
			if show.streamRate > 0 and show.streamLeft > 0 then
				show.streamCarry += show.streamRate * deltaTime
				local count = math.min(math.floor(show.streamCarry), show.streamLeft)
				if count > 0 then
					show.streamCarry -= count
					show.streamLeft -= count
					burstFromBody(count, floorY)
				end
			end
		end
	end))

	---- 0.25 IL CERCHIO: i quattro anelli di DOORS si aprono sotto di lui ----
	at(0.25)
	local diameter = radius * 2
	local circleParts = {}
	for index, textureId in ipairs(TEXTURES.Circle) do
		local disc, image = glowDisc(folder, "CircleLayer", center, 0.2, textureId, GUIDING, 0.04 + index * 0.02)
		image.Rotation = math.random(0, 359)
		tween(disc, 0.8, { Size = Vector3.new(diameter, 0.02, diameter) }, Enum.EasingStyle.Back)
		tween(image, 0.5, { ImageTransparency = 0 })
		table.insert(show.layers, image)
		table.insert(circleParts, disc)
		task.wait(0.06)
	end

	local lamp = newPart("Lamp", Vector3.one * 0.2, CFrame.new(center + Vector3.new(0, 3, 0)), GUIDING, Enum.Material.SmoothPlastic, 1)
	lamp.Parent = folder
	local circleLight = Instance.new("PointLight")
	circleLight.Color = GUIDING
	circleLight.Brightness = 0
	circleLight.Range = math.min(radius * 3.5, 60)
	circleLight.Parent = lamp
	tween(circleLight, 0.5, { Brightness = 5 })

	-- Scintille e linee di luce che salgono dal cerchio, come nel rituale di DOORS
	local emitterBase = newPart("CircleEmitters", Vector3.new(diameter * 0.9, 0.5, diameter * 0.9), CFrame.new(center + Vector3.new(0, 0.3, 0)), GUIDING, Enum.Material.SmoothPlastic, 1)
	emitterBase.Parent = folder

	local sparks = makeEmitter(emitterBase, TEXTURES.Spark)
	sparks.Rate = 45
	sparks.EmissionDirection = Enum.NormalId.Top
	sparks.Lifetime = NumberRange.new(0.6, 2.2)
	sparks.Speed = NumberRange.new(2, 9)
	sparks.Acceleration = Vector3.new(0, 6, 0)
	sparks.Drag = 1
	sparks.SpreadAngle = Vector2.new(12, 12)
	sparks.Size = sequence({ { 0, 1.4 }, { 1, 0.2 } })
	sparks.Transparency = sequence({ { 0, 1 }, { 0.2, 0.25 }, { 1, 1 } })
	sparks.RotSpeed = NumberRange.new(35, 100)

	local lines = makeEmitter(emitterBase, TEXTURES.Lines)
	lines.Rate = 35
	lines.EmissionDirection = Enum.NormalId.Top
	lines.Orientation = Enum.ParticleOrientation.VelocityParallel
	lines.Lifetime = NumberRange.new(0.8, 1.2)
	lines.Speed = NumberRange.new(4, 10)
	lines.Acceleration = Vector3.new(0, 14, 0)
	lines.Size = sequence({ { 0, 1.5 }, { 1, 1.3 } })
	lines.Squash = sequence({ { 0, -1.2 }, { 1, 1 } })
	lines.Transparency = sequence({ { 0, 1 }, { 0.5, 0.35 }, { 1, 1 } })

	---- 0.6 IL PILASTRO: una colonna di luce gli piomba addosso dal soffitto ----
	at(0.6)
	local pillarHeight = 60
	local pillars = {}
	for index, spec in ipairs({ { 1.2, 0.05, Enum.Material.Neon, WHITE }, { radius * 0.55, 0.35, Enum.Material.ForceField, GUIDING }, { radius * 0.9, 0.7, Enum.Material.ForceField, GUIDING } }) do
		local pillarDiameter, transparency, material, colour = spec[1], spec[2], spec[3], spec[4]
		local pillar = newPart("Pillar" .. index, Vector3.new(pillarHeight, pillarDiameter, pillarDiameter),
			CFrame.new(center + Vector3.new(0, pillarHeight * 1.5, 0)) * UPRIGHT, colour, material, transparency)
		pillar.Parent = folder
		tween(pillar, 0.22, { CFrame = CFrame.new(center + Vector3.new(0, pillarHeight / 2, 0)) * UPRIGHT }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		table.insert(pillars, pillar)
	end
	task.wait(0.22)
	flashScreen(WHITE, 0.45, 0.4)
	shake(6, 12, 0, 0.9)
	ringWave(folder, center, diameter * 0.5, diameter * 2.4, 0.7, WHITE)
	sparkBurst(emitterBase, 60, 30)

	---- 0.85 I RAGGI: fasci di luce dall'alto convergono sulla sua testa ----
	at(0.85)
	local sky = newPart("Sky", Vector3.one * 0.2, CFrame.new(center + Vector3.new(0, 18, 0)), GUIDING, Enum.Material.SmoothPlastic, 1)
	sky.Parent = folder
	local headAttachment = Instance.new("Attachment")
	headAttachment.Position = headLocal
	headAttachment.Parent = root
	for index = 1, 6 do
		local angle = index / 6 * math.pi * 2
		local from = attachmentAt(sky, sky.Position + Vector3.new(math.cos(angle), 0, math.sin(angle)) * radius * 0.7)
		lightRay(folder, from, headAttachment)
	end

	---- 1.0 LE CATENE: partono dal cerchio e dall'alto, lo agganciano e lo sollevano ----
	at(1.0)
	pcall(function()
		body.attack:Play(0.1)
		body.scream.PlaybackSpeed = 0.85
		body.scream:Play()
	end)
	show.jitter = 0.35
	show.streamRate = streamBudget / 4.8

	local glow = Instance.new("Highlight")
	glow.FillColor = WHITE
	glow.FillTransparency = 0.8
	glow.OutlineColor = GUIDING
	glow.OutlineTransparency = 0
	glow.Parent = model
	TweenService:Create(glow, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { FillTransparency = 0.35 }):Play()

	local liftStart = os.clock()
	table.insert(connections, RunService.Heartbeat:Connect(function()
		show.lift = 2.5 * elasticOut(math.clamp((os.clock() - liftStart) / 1.2, 0, 1))
	end))

	local anchor = newPart("ChainAnchor", Vector3.one * 0.2, CFrame.new(center), GUIDING, Enum.Material.SmoothPlastic, 1)
	anchor.Parent = folder
	local chainEnds = {}
	local function shootChain(originPart, originWorld, targetLocal)
		local from = attachmentAt(originPart, originWorld)
		local to = Instance.new("Attachment")
		to.Position = root.CFrame:PointToObjectSpace(originWorld)
		to.Parent = root
		local beam = chainBeam(folder, from, to)
		-- La punta della catena vola fino a lui
		tween(to, 0.14, { Position = targetLocal }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.14, function()
			if model.Parent then
				sparkBurst(to, 14, 14)
				shake(1.5, 8, 0, 0.3)
			end
		end)
		table.insert(chainEnds, { beam = beam, tip = to })
	end

	for index = 1, 8 do
		local angle = index / 8 * math.pi * 2 + math.random() * 0.3
		local originWorld = center + Vector3.new(math.cos(angle) * radius * 0.92, 0.2, math.sin(angle) * radius * 0.92)
		local targetLocal = Vector3.new((math.random() - 0.5) * 1.6, -state.pivotHeight * 0.4 + math.random() * state.headHeight, (math.random() - 0.5) * 1.6)
		shootChain(anchor, originWorld, targetLocal)
		task.wait(0.09)
	end
	for index = 1, 4 do
		local angle = index / 4 * math.pi * 2 + 0.4
		local originWorld = sky.Position + Vector3.new(math.cos(angle) * radius * 0.5, 0, math.sin(angle) * radius * 0.5)
		local targetLocal = Vector3.new((math.random() - 0.5) * 1.2, state.headHeight * 0.7, (math.random() - 0.5) * 1.2)
		shootChain(sky, originWorld, targetLocal)
		task.wait(0.09)
	end

	---- 2.5 GIÙ: le catene lo trascinano nel cerchio, trema tutto, perde sempre più fogli ----
	at(2.5)
	show.jitter = 0.55
	playSound(SOUND_IDS.Earthquake, 0.9, 0.5, folder)
	ceilingDust(center)
	tween(bloom, 3.3, { Intensity = 2.2, Size = 40 })
	tween(grade, 3.3, { Contrast = 0.45, Saturation = -0.5 })
	tween(circleLight, 3.3, { Brightness = 9 })
	spawnSafe("terremoto del rituale", function()
		while os.clock() - startedAt < 5.8 and not state.finished do
			local progress = math.clamp((os.clock() - startedAt - 2.5) / 3.3, 0, 1)
			show.spinBoost = 1 + 3 * progress
			show.crucifixSpin = 1.6 + 10 * progress
			shake(2 + 5 * progress, 10, 0.1, 0.5)
			task.wait(0.35)
		end
	end)

	---- 5.8 IL COLPO FINALE: sparisce, e scoppia tutto ----
	at(5.8)
	show.streamRate = 0
	show.jitter = 0
	if model.Parent then
		model:Destroy()
	end
	geyser(geyserBudget + show.streamLeft, center, radius, floorY)
	show.streamLeft = 0

	playSound(SOUND_IDS.Slam, 2, 0.9, folder)
	flashScreen(WHITE, 0.05, 1)
	fovPunch(18, 0.8)
	shake(12, 16, 0, 1.6)
	sparkBurst(emitterBase, 220, 45)
	sphereWave(folder, center + Vector3.new(0, 2, 0), radius * 3.2, 0.9, GUIDING)
	for index = 0, 2 do
		task.delay(index * 0.12, function()
			ringWave(folder, center, diameter * 0.3, diameter * (3 - index * 0.6), 0.9, if index == 0 then WHITE else GUIDING)
		end)
	end
	shatterRoom(playerRoom())
	shatterCrucifix(crucifix, folder)
	sparkBurst(crucifixPart, 60, 25)
	tween(crucifixLight, 0.15, { Brightness = 12 })
	for _, chain in ipairs(chainEnds) do
		chain.beam:Destroy()
	end
	tween(bloom, 0.08, { Intensity = 3.5 })
	tween(circleLight, 0.08, { Brightness = 14 })
	for _, pillar in ipairs(pillars) do
		tween(pillar, 0.7, { Size = Vector3.new(pillarHeight, 0.05, 0.05), Transparency = 1 }, Enum.EasingStyle.Quart)
	end
	sparks.Enabled = false
	lines.Enabled = false
	award("Crucify")
	if playerAlive() then
		award("Survive")
	end

	---- 6.0 IL CERCHIO SI RICHIUDE su se stesso girando a tutta velocità ----
	at(6.0)
	show.spinBoost = 8
	for index, disc in ipairs(circleParts) do
		tween(disc, 0.6, { Size = Vector3.new(0.1, 0.02, 0.1) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		tween(show.layers[index], 0.6, { ImageTransparency = 1 })
	end
	tween(crucifixLight, 1, { Brightness = 0 })
	tween(crucifixGlow, 1, { FillTransparency = 1, OutlineTransparency = 1 })
	twinkles.Enabled = false
	tween(bloom, 1.5, { Intensity = 1 })

	---- 6.2 PIOGGIA DI FOGLI e braci che scendono piano ----
	at(6.2)
	tween(circleLight, 1.5, { Brightness = 0 })
	local area = radius * 2.4
	local embersBase = newPart("Embers", Vector3.new(area * 2, 0.5, area * 2), CFrame.new(center + Vector3.new(0, 11, 0)), GUIDING, Enum.Material.SmoothPlastic, 1)
	embersBase.Parent = folder
	local embers = makeEmitter(embersBase, TEXTURES.Spark)
	embers.Rate = 30
	embers.EmissionDirection = Enum.NormalId.Bottom
	embers.Lifetime = NumberRange.new(3, 5)
	embers.Speed = NumberRange.new(0.5, 1.5)
	embers.Acceleration = Vector3.new(0, -1.5, 0)
	embers.SpreadAngle = Vector2.new(40, 40)
	embers.Size = sequence({ { 0, 0.45 }, { 1, 0 } })
	embers.Transparency = sequence({ { 0, 1 }, { 0.1, 0.2 }, { 1, 1 } })
	task.delay(2.5, function()
		embers.Enabled = false
	end)

	local rainStart = os.clock()
	local rained = 0
	while rained < rainBudget and not state.finished do
		RunService.Heartbeat:Wait()
		local due = math.floor(rainBudget * math.clamp((os.clock() - rainStart) / 2.5, 0, 1))
		for _ = rained + 1, due do
			local angle = math.random() * math.pi * 2
			local distance = math.sqrt(math.random()) * area
			local origin = center + Vector3.new(math.cos(angle) * distance, 10 + math.random() * 4, math.sin(angle) * distance)
			spawnPaper(origin, floorY, Vector3.new((math.random() - 0.5) * 2, -1 - math.random() * 2, (math.random() - 0.5) * 2), 6 + math.random() * 2)
		end
		rained = math.max(rained, due)
	end

	---- 8.7 Il mondo torna normale ----
	at(8.7)
	tween(grade, 2, { TintColor = WHITE, Contrast = 0, Saturation = 0 })
	tween(bloom, 2, { Intensity = 0 })
	task.wait(2.1)
	finish("esorcizzato")
end

---====== IL GIOCATORE ======---

local sightParams = RaycastParams.new()
sightParams.FilterType = Enum.RaycastFilterType.Exclude
sightParams.RespectCanCollide = true

local function canSee(origin, target, character)
	-- Come nello spawner di Vynixu: armadi e letti non bloccano la vista, devi esserci dentro
	local ignore = CollectionService:GetTagged("HidingSpot")
	table.insert(ignore, character)
	table.insert(ignore, state.model)
	sightParams.FilterDescendantsInstances = ignore
	return workspace:Raycast(origin, target - origin, sightParams) == nil
end

local function heldCrucifix(character)
	local tool = character:FindFirstChildOfClass("Tool")
	if tool and (tool.Name == "Crucifix" or CollectionService:HasTag(tool, "Crucifix")) then
		return tool
	end
	return nil
end

local lastShake = 0

local function watchPlayer()
	if not state.watching or state.paused then return end

	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then return end

	local head = character:FindFirstChild("Head")
	local target = (head or root).Position
	local distance = (target - state.position).Magnitude
	if distance > ENCOUNTER_RANGE then return end

	-- Più è vicino più la camera trema, anche con i muri in mezzo
	if distance <= SHAKE_RANGE and os.clock() - lastShake > 0.1 then
		lastShake = os.clock()
		local closeness = 1 - distance / SHAKE_RANGE
		shake(1.5 * closeness, 20 * closeness, 0.1, 1)
	end

	if not canSee(state.position, target, character) then return end

	local _, onScreen = workspace.CurrentCamera:WorldToViewportPoint(state.position)
	if onScreen then
		award("Encounter")
	end

	-- Il crocifisso conta prima del danno: se lo hai in mano quando arriva, ti salva
	local crucifix = heldCrucifix(character)
	if crucifix and distance <= CRUCIFIX_RANGE then
		state.paused = true
		state.watching = false
		spawnSafe("rituale", ritual, crucifix)
		return
	end

	if distance <= SETTINGS.KillRange and not character:GetAttribute("Hiding") then
		state.paused = true
		state.watching = false
		state.caught = true
		spawnSafe("jumpscare", jumpscare, humanoid)
	end
end

---====== MOVIMENTO ======---

local function moveTo(target)
	while state.running do
		local deltaTime = RunService.Heartbeat:Wait()
		if not state.running then return end

		if not state.paused then
			local offset = target - state.position
			local distance = offset.Magnitude
			if distance < 0.1 then return end

			state.position += offset.Unit * math.min(state.speed * deltaTime, distance)
			local direction = flatUnit(offset)
			if direction then
				local facing = CFrame.lookAt(Vector3.zero, direction)
				state.rotation = state.rotation:Lerp(facing, 1 - math.exp(-TURN_SPEED * deltaTime))
			end
			render(walkBob())
		end
	end
end

-- Rompe le luci delle stanze dove passa, tranne l'ultima, come lo spawner di Vynixu
local function onEnterRoom(room)
	log("entra nella stanza %s", room.Name)
	if (tonumber(room.Name) :: number) < latestRoomNumber() then
		shatterRoom(room)
	end
end

local function walk(points)
	local lift = Vector3.new(0, state.pivotHeight, 0)
	for _, point in ipairs(points) do
		if not state.running then return end
		if point.room ~= state.lastRoom then
			state.lastRoom = point.room
			onEnterRoom(point.room)
		end
		moveTo(point.position + lift)
	end
end

local function waitWhileRunning(seconds)
	local deadline = os.clock() + seconds
	while state.running and os.clock() < deadline do
		RunService.Heartbeat:Wait()
	end
end

-- L'avviso: le luci della tua stanza sfarfallano e la camera trema come nel terremoto di Vynixu
local function warnPlayer()
	flickerRoom(playerRoom(), 1.5)
	shake(4, 12, 1, 5)
	shake(10, 2, 3, 3)
end

-- A fine percorso sprofonda e sparisce
local function sinkAway()
	setMoving(false)
	local start = state.position
	local startedAt = os.clock()
	while state.running do
		local progress = (os.clock() - startedAt) / 0.9
		if progress >= 1 then break end
		state.position = start - Vector3.new(0, 20 * progress ^ 2, 0)
		render()
		RunService.Heartbeat:Wait()
	end
end

-- Con _G.Sync aspetta che qualcuno apra la prossima porta: tutti quelli che hanno eseguito lo
-- script vedono cambiare LatestRoom nello stesso istante, quindi Honcho parte insieme per tutti
local function waitForSync()
	local latest = latestRoomValue()
	if not latest then
		problem("non trovo GameData.LatestRoom, parto subito senza sincronizzarmi")
		return
	end
	log("sincronizzato: parto alla prossima porta (ora %s)", tostring(latest.Value))
	latest.Changed:Wait()
	-- La stanza nuova arriva un attimo dopo il numero
	task.wait(0.5)
end

local function main()
	if SETTINGS.Sync then
		waitForSync()
		if state.finished then return end
	end

	local path = buildPath()
	log("percorso: %d punti", #path)
	if #path < 2 then
		problem("non trovo i nodi delle stanze in workspace.CurrentRooms")
		finish("nessun nodo")
		return
	end

	state.position = path[1].position + Vector3.new(0, state.pivotHeight, 0)
	local firstStep = flatUnit(path[2].position - path[1].position)
	if firstStep then
		state.rotation = CFrame.lookAt(Vector3.zero, firstStep)
	end
	render()
	state.model.Parent = workspace
	state.running = true

	setupBody()
	setMoving(false)

	warnPlayer()
	waitWhileRunning(SETTINGS.Delay)
	if not state.running then return end

	state.watching = true
	setMoving(true)
	walk(path)

	for _ = 1, SETTINGS.Rebounds do
		if not state.running then return end
		setMoving(false)
		waitWhileRunning(REBOUND_DELAY)
		setMoving(true)
		walk(reversed(path))

		if not state.running then return end
		setMoving(false)
		waitWhileRunning(REBOUND_DELAY)
		-- Nel frattempo possono essersi aperte stanze nuove
		path = buildPath()
		setMoving(true)
		walk(path)
	end
	if not state.running then return end

	state.watching = false
	sinkAway()
	if not state.caught and playerAlive() then
		award("Survive")
	end
	finish("percorso finito")
end

---====== CROCIFISSO DI PENGUINMANIACK ======---

local function listTools()
	local tools = {}
	local containers = { LocalPlayer:FindFirstChildOfClass("Backpack"), LocalPlayer.Character }
	for index = 1, 2 do
		local container = containers[index]
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") then
					table.insert(tools, child)
				end
			end
		end
	end
	return tools
end

-- Come il tuo CrucifixGiver: esegue il loader di PenguinManiack e sistema il tool che crea
local function giveCrucifix()
	local before = {}
	for _, tool in ipairs(listTools()) do
		-- Ne hai già uno: va bene anche quello vero di DOORS
		if tool.Name == "Crucifix" or CollectionService:HasTag(tool, "Crucifix") then
			log("hai già un crocifisso")
			return
		end
		before[tool] = true
	end

	_G.Uses = 1
	_G.Range = 30
	-- Se un altro script l'ha lasciato a true, il suo crocifisso vale su qualsiasi cosa
	_G.OnAnything = nil

	local ok, err = pcall(function()
		loadstring(game:HttpGet(CRUCIFIX_URL))()
	end)
	if not ok then
		problem("il crocifisso di PenguinManiack non si è caricato: %s", tostring(err))
		return
	end

	-- Il loader può creare il tool qualche frame dopo
	local tool
	local deadline = os.clock() + 12
	repeat
		for _, candidate in ipairs(listTools()) do
			if not before[candidate] then
				tool = candidate
				break
			end
		end
		if not tool then
			task.wait(0.15)
		end
	until tool or os.clock() > deadline

	if not tool then
		problem("il loader del crocifisso non ha dato nessun tool")
		return
	end

	-- Honcho riconosce un Tool in mano che si chiama o ha il tag "Crucifix"
	tool.Name = "Crucifix"
	CollectionService:AddTag(tool, "Crucifix")
	log("crocifisso nello zaino: tienilo in mano quando arriva")
end

---====== AVVIO ======---

local model = prepareModel()
if not model then
	problem("non riesco a caricare il modello %d", MODEL_ID)
	return
end
state.model = model
log("modello pronto: pivot %.1f stud sopra i piedi, testa %.1f sopra il pivot", state.pivotHeight, state.headHeight)

_G.HonchoCleanup = dismiss

local reportedWatchError = false
table.insert(connections, RunService.Heartbeat:Connect(function()
	local ok, err = pcall(watchPlayer)
	if not ok and not reportedWatchError then
		reportedWatchError = true
		problem("errore nel controllo del giocatore: %s", tostring(err))
	end
end))

if SETTINGS.GiveCrucifix then
	spawnSafe("crocifisso", giveCrucifix)
end
if SETTINGS.Badges then
	spawnSafe("badge", loadBadgeLibrary)
end
spawnSafe("precaricamento", preloadRitual)
spawnSafe("percorso", main)
