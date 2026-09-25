--[[
	HONCHO — entità custom per DOORS · Gradish Mode
	Motore: Roblox · Linguaggio: Luau · Tipo: script client da executor, lo vedi solo tu

	Come funziona
	- Corre sui PathfindNodes di tutte le stanze come Rush, con i piedi sul pavimento trovato da un
	  raycast sotto ogni nodo. Prima di partire fa sfarfallare le luci e tremare la camera, poi rompe
	  le luci delle stanze dove passa. Con _G.Rebounds torna indietro come Ambush.
	- Se sei a tiro, fuori da un nascondiglio e senza muri in mezzo, ti salta in faccia e muori.
	- Se invece hai in mano il crocifisso di PenguinManiack, il crocifisso ti vola davanti, sotto di
	  lui si apre un cerchio con il pentagramma, le catene di luce lo trascinano sotto terra e mentre
	  sprofonda perde centinaia di fogli.
	- È tutto costruito con Instance.new: non scarica modelli o immagini con getcustomasset.

	Uso
		loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/Honcho"))()

	Con le impostazioni, mettile prima del loadstring (sono tutte facoltative, i nomi sono in
	IMPOSTAZIONI qui sotto). Vengono lette e poi cancellate, così il loadstring da solo torna
	sempre ai valori normali.

	Se qualcosa non va: _G.Debug = true, poi scrivi /console in chat e leggi le righe [Honcho].

	Crediti: modello e animazioni dal morph di MorthenHubber · crocifisso di PenguinManiack ·
	badge con DOORS Custom Achievements di RegularVynixu
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
	Papers       = 300,   -- quanti fogli perde quando lo esorcizzi
	Badges       = true,
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

local ANIMATION_IDS = {
	Idle   = 101907348895136,
	Walk   = 100466662502744,
	Attack = 91194170893496,
}

local SOUND_IDS = {
	Scream = 82613796053949, -- il salto del morph: jumpscare e rituale
	Thud   = 74149238738530, -- l'atterraggio del morph: quando sparisce sotto terra
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

local Players                  = game:GetService("Players")
local RunService               = game:GetService("RunService")
local ReplicatedStorage        = game:GetService("ReplicatedStorage")
local CollectionService        = game:GetService("CollectionService")
local TweenService             = game:GetService("TweenService")
local AnimationClipProvider    = game:GetService("AnimationClipProvider")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

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

log("impostazioni: Speed %s, Delay %s, Size %s, KillRange %s, Rebounds %s, Jumpscare %s, GiveCrucifix %s, Papers %s, Badges %s",
	tostring(SETTINGS.Speed), tostring(SETTINGS.Delay), tostring(SETTINGS.Size), tostring(SETTINGS.KillRange),
	tostring(SETTINGS.Rebounds), tostring(SETTINGS.Jumpscare), tostring(SETTINGS.GiveCrucifix),
	tostring(SETTINGS.Papers), tostring(SETTINGS.Badges))

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

local function latestRoomNumber()
	local ok, value = pcall(function()
		return ReplicatedStorage.GameData.LatestRoom.Value
	end)
	return ok and tonumber(value) or math.huge
end

local function playerRoom()
	local number = LocalPlayer:GetAttribute("CurrentRoom")
	return number and CurrentRooms:FindFirstChild(tostring(number))
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

---====== CORPO (animazioni e rotazione) ======---

--[[ Le animazioni di un altro creatore spesso non partono dentro DOORS. Se l'executor riesce a
     scaricarne i fotogrammi con GetObjects, vengono registrate in locale e partono comunque;
     se no si usa l'ID diretto. ]]
local function registerAnimation(animationId)
	local ok, clip = pcall(function()
		return game:GetObjects("rbxassetid://" .. animationId)[1]
	end)
	if not ok or typeof(clip) ~= "Instance" or not clip:IsA("AnimationClip") then
		return nil
	end

	local registered, content = pcall(function()
		return AnimationClipProvider:RegisterAnimationClip(clip)
	end)
	if registered and content then
		return content
	end

	if clip:IsA("KeyframeSequence") then
		registered, content = pcall(function()
			return KeyframeSequenceProvider:RegisterKeyframeSequence(clip)
		end)
		if registered and content then
			return content
		end
	end
	return nil
end

-- Va fatto prima di mettere il modello in workspace: scarica, e intanto Honcho non è ancora apparso
local function prepareAnimations()
	body.contents = {}
	for name, animationId in pairs(ANIMATION_IDS) do
		body.contents[name] = registerAnimation(animationId)
		log("animazione %s: %s", name, if body.contents[name] then "registrata in locale" else "ID diretto")
	end
end

local function loadTrack(animator, name, looped, priority)
	local animation = Instance.new("Animation")
	local content = body.contents[name]
	local registered = content ~= nil and pcall(function()
		animation.AnimationId = content
	end)
	if not registered then
		animation.AnimationId = "rbxassetid://" .. ANIMATION_IDS[name]
	end

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

	body.sounds = {}
	for name, soundId in pairs(SOUND_IDS) do
		local sound = Instance.new("Sound")
		sound.Name = "Honcho" .. name
		sound.SoundId = "rbxassetid://" .. soundId
		sound.Volume = 2
		sound.RollOffMinDistance = 20
		sound.Parent = model.PrimaryPart
		body.sounds[name] = sound
	end

	-- Dopo qualche secondo si sa cosa non ha caricato. Se manca la camminata, ondeggia a mano
	task.delay(4, function()
		if state.finished then return end
		for name, track in pairs({ Idle = body.idle, Walk = body.walk, Attack = body.attack }) do
			if track.Length == 0 then
				problem("l'animazione %s non si è caricata", name)
			end
		end
		for name, sound in pairs(body.sounds) do
			if not sound.IsLoaded then
				problem("il suono %s non si è caricato (forse è privato)", name)
			end
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

local function spawnPaper(position, floorY, velocity)
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
		life          = 5 + math.random() * 3,
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
		local direction = (Vector3.new(math.cos(angle) * 0.4, 1, math.sin(angle) * 0.4) + randomUnit() * 0.3).Unit
		spawnPaper(origin, floorY, direction * (14 + math.random() * 16))
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
		body.sounds.Scream:Play()
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
		local wood = Color3.fromRGB(92, 64, 42)
		primary = newPart("Handle", Vector3.new(0.22, 1.7, 0.22), startCFrame, wood, Enum.Material.Wood, 0)
		primary.Parent = crucifix
		newPart("Crossbar", Vector3.new(0.95, 0.22, 0.22), startCFrame * CFrame.new(0, 0.42, 0), wood, Enum.Material.Wood, 0).Parent = crucifix
	end

	crucifix.PrimaryPart = primary :: BasePart
	crucifix:PivotTo(startCFrame)
	crucifix.Parent = folder
	return crucifix, startCFrame
end

-- Il cerchio di luce sul pavimento con il buco scuro dentro e il pentagramma sopra
local function ritualCircle(folder, center, radius)
	-- Il cilindro di Roblox ha l'asse su X: girato di 90 gradi sta sdraiato
	local flat = CFrame.Angles(0, 0, math.rad(90))
	local diameter = radius * 2

	local ring = newPart("Ring", Vector3.new(0.05, 0.1, 0.1), CFrame.new(center + Vector3.new(0, 0.03, 0)) * flat, GUIDING, Enum.Material.Neon, 0.15)
	ring.Shape = Enum.PartType.Cylinder
	ring.Parent = folder

	local pit = newPart("Pit", Vector3.new(0.05, 0.1, 0.1), CFrame.new(center + Vector3.new(0, 0.05, 0)) * flat, Color3.fromRGB(6, 10, 18), Enum.Material.SmoothPlastic, 0.05)
	pit.Shape = Enum.PartType.Cylinder
	pit.Parent = folder

	tween(ring, 0.7, { Size = Vector3.new(0.05, diameter, diameter) }, Enum.EasingStyle.Back)
	tween(pit, 0.7, { Size = Vector3.new(0.05, diameter - 0.9, diameter - 0.9) }, Enum.EasingStyle.Back)

	-- Il pentagramma: ogni punta si collega a quella due posti più avanti
	local corners = {}
	for index = 0, 4 do
		local angle = math.rad(90 + 72 * index)
		corners[index] = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * (radius - 0.7) + Vector3.new(0, 0.08, 0)
	end

	local lines = {}
	for index = 0, 4 do
		local from, to = corners[index], corners[(index + 2) % 5]
		local line = newPart("Star", Vector3.new(0.14, 0.03, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), GUIDING, Enum.Material.Neon, 1)
		line.Parent = folder
		table.insert(lines, line)
	end

	local lamp = newPart("Lamp", Vector3.one * 0.2, CFrame.new(center + Vector3.new(0, 2.5, 0)), GUIDING, Enum.Material.SmoothPlastic, 1)
	local light = Instance.new("PointLight")
	light.Color = GUIDING
	light.Brightness = 0
	light.Range = math.min(radius * 3, 60)
	light.Parent = lamp
	lamp.Parent = folder

	return { ring = ring, pit = pit, lines = lines, light = light }
end

-- Catene di luce dal bordo del cerchio al suo corpo. Seguono lui mentre sprofonda
local function chains(folder, center, radius, count)
	local anchor = newPart("ChainAnchor", Vector3.one * 0.2, CFrame.new(center), GUIDING, Enum.Material.SmoothPlastic, 1)
	anchor.Parent = folder

	local root = state.model.PrimaryPart
	local beams = {}
	for index = 1, count do
		local angle = index / count * math.pi * 2 + math.random() * 0.4

		local bottom = Instance.new("Attachment")
		bottom.Position = Vector3.new(math.cos(angle) * radius, 0.1, math.sin(angle) * radius)
		bottom.Parent = anchor

		local top = Instance.new("Attachment")
		top.Position = Vector3.new(
			(math.random() - 0.5) * 1.6,
			(math.random() - 0.2) * state.headHeight * 0.8,
			(math.random() - 0.5) * 1.6
		)
		top.Parent = root

		local beam = Instance.new("Beam")
		beam.Attachment0 = bottom
		beam.Attachment1 = top
		beam.Color = ColorSequence.new(GUIDING, Color3.new(1, 1, 1))
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Width0 = 0.45
		beam.Width1 = 0.2
		beam.FaceCamera = true
		beam.Segments = 12
		beam.CurveSize0 = (math.random() - 0.5) * 5
		beam.CurveSize1 = (math.random() - 0.5) * 5
		beam.Transparency = NumberSequence.new(0.1)
		beam.Enabled = false
		beam.Parent = anchor
		table.insert(beams, beam)
	end
	return beams
end

local function ritual(tool)
	local model = state.model
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
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		local toPlayer = flatUnit(root.Position - state.position)
		if toPlayer then
			state.rotation = CFrame.lookAt(Vector3.zero, toPlayer)
		end
	end
	render()

	local floorY = floorAt(state.position, state.position.Y - state.pivotHeight)
	local center = Vector3.new(state.position.X, floorY, state.position.Z)
	local radius = math.clamp(math.max(state.boxSize.X, state.boxSize.Z) / 2 + 2.5, 4, 12)
	local total = SETTINGS.Papers
	local firstBurst = math.floor(total * 0.3)
	local streamTarget = math.floor(total * 0.35)

	-- 1. Il crocifisso ti lascia la mano e ti vola davanti, girando e brillando
	local crucifix, fromCFrame = floatingCrucifix(tool, folder)

	local crucifixLight = Instance.new("PointLight")
	crucifixLight.Color = GUIDING
	crucifixLight.Brightness = 0
	crucifixLight.Range = 14
	crucifixLight.Parent = crucifix.PrimaryPart
	tween(crucifixLight, 0.6, { Brightness = 3 })

	local crucifixGlow = Instance.new("Highlight")
	crucifixGlow.FillColor = GUIDING
	crucifixGlow.FillTransparency = 0.6
	crucifixGlow.OutlineColor = Color3.new(1, 1, 1)
	crucifixGlow.OutlineTransparency = 0.2
	crucifixGlow.Parent = crucifix

	local floatAt = fromCFrame.Position + Vector3.new(0, 1.2, 0)
	if root then
		local toHoncho = flatUnit(state.position - root.Position) or Vector3.new(0, 0, -1)
		floatAt = root.Position + toHoncho * 3 + Vector3.new(0, 1.6, 0)
	end

	local floatStart = os.clock()
	table.insert(connections, RunService.RenderStepped:Connect(function()
		if not crucifix.Parent then return end
		local elapsed = os.clock() - floatStart
		local rise = 1 - (1 - math.clamp(elapsed / 0.6, 0, 1)) ^ 3
		local position = fromCFrame.Position:Lerp(floatAt, rise) + Vector3.new(0, math.sin(elapsed * 2.2) * 0.15 * rise, 0)
		crucifix:PivotTo(CFrame.new(position) * CFrame.Angles(0, elapsed * 1.6, 0) * fromCFrame.Rotation)
	end))

	-- 2. Sotto di lui si apre il cerchio e lui urla
	local circle = ritualCircle(folder, center, radius)
	tween(circle.light, 0.8, { Brightness = 3 })
	shake(3, 10, 0.2, 1.5)
	pcall(function()
		body.attack:Play(0.1)
		body.sounds.Scream.PlaybackSpeed = 0.8
		body.sounds.Scream:Play()
	end)

	local glow = Instance.new("Highlight")
	glow.FillColor = GUIDING
	glow.FillTransparency = 0.85
	glow.OutlineColor = GUIDING
	glow.OutlineTransparency = 0.3
	glow.Parent = model
	tween(glow, 1.5, { FillTransparency = 0.55 })
	task.wait(0.7)

	-- 3. Il pentagramma si accende una linea alla volta, poi partono le catene
	for _, line in ipairs(circle.lines) do
		tween(line, 0.25, { Transparency = 0.05 })
		task.wait(0.08)
	end
	local beams = chains(folder, center, radius, 6)
	for _, beam in ipairs(beams) do
		beam.Enabled = true
		task.wait(0.07)
	end

	-- 4. Si dimena e comincia a perdere fogli, poi continua a perderne mentre sprofonda
	burstFromBody(firstBurst, floorY)
	local streamed = 0
	local streamTime = 2.8
	local function stream(elapsed)
		local due = math.floor(streamTarget * math.clamp(elapsed / streamTime, 0, 1))
		if due > streamed then
			burstFromBody(due - streamed, floorY)
			streamed = due
		end
	end

	local basePosition = state.position
	local struggleStart = os.clock()
	while os.clock() - struggleStart < 1.4 do
		RunService.Heartbeat:Wait()
		stream(os.clock() - struggleStart)
		render(CFrame.new((math.random() - 0.5) * 0.5, (math.random() - 0.5) * 0.3, (math.random() - 0.5) * 0.5)
			* CFrame.Angles((math.random() - 0.5) * 0.1, (math.random() - 0.5) * 0.16, (math.random() - 0.5) * 0.1))
	end

	-- 5. Le catene lo trascinano sotto terra: prima si alza un po', poi giù di colpo
	shake(8, 14, 0.1, 1.2)
	tween(circle.light, 0.3, { Brightness = 6 })
	local depth = state.pivotHeight + state.headHeight + 4
	local pullStart = os.clock()
	while os.clock() - pullStart < 1.4 do
		RunService.Heartbeat:Wait()
		local elapsed = os.clock() - pullStart
		local progress = math.clamp(elapsed / 1.4, 0, 1)
		local eased = 2.70158 * progress ^ 3 - 1.70158 * progress ^ 2
		stream(1.4 + elapsed)
		state.position = basePosition - Vector3.new(0, depth * eased, 0)
		render(CFrame.new((math.random() - 0.5) * 0.25, 0, (math.random() - 0.5) * 0.25))
	end

	-- 6. Sparito: le catene si spezzano e i fogli rimasti schizzano fuori dal buco
	pcall(function()
		-- Spostato fuori da lui, se no il suono sparisce insieme al modello
		body.sounds.Thud.Parent = folder
		body.sounds.Thud:Play()
	end)
	model:Destroy()
	for _, beam in ipairs(beams) do
		beam:Destroy()
	end
	geyser(total - firstBurst - streamed, center, radius, floorY)
	flashScreen(GUIDING, 0.55, 0.6)
	shake(6, 10, 0, 1.5)

	-- 7. Il crocifisso brilla un'ultima volta e si spegne insieme al cerchio
	tween(crucifixLight, 0.15, { Brightness = 10 })
	task.wait(0.15)
	tween(crucifixLight, 1, { Brightness = 0 })
	tween(crucifixGlow, 1, { FillTransparency = 1, OutlineTransparency = 1 })
	for _, part in ipairs(crucifix:GetDescendants()) do
		if part:IsA("BasePart") then
			tween(part, 1, { Transparency = 1 })
		end
	end
	for _, part in ipairs({ circle.ring, circle.pit, table.unpack(circle.lines) }) do
		tween(part, 1.2, { Transparency = 1 })
	end
	tween(circle.light, 1.2, { Brightness = 0 })

	award("Crucify")
	if playerAlive() then
		award("Survive")
	end
	task.wait(1.4)
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
	local events = moduleEvents()
	if events and events.shatter and (tonumber(room.Name) :: number) < latestRoomNumber() then
		pcall(events.shatter, room)
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
	local room = playerRoom()
	local events = moduleEvents()
	if room and events and events.flicker then
		pcall(events.flicker, room, 1.5)
	end
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

local function main()
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

spawnSafe("percorso", function()
	prepareAnimations()
	main()
end)
