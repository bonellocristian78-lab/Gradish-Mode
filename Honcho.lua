--[[
	HONCHO — entità custom per DOORS · Gradish Mode
	Motore: Roblox · Linguaggio: Luau · Tipo: script client da executor

	Come funziona
	- Corre sui PathfindNodes di tutte le stanze come Rush, con i piedi sul pavimento trovato da un
	  raycast sotto ogni nodo. Prima di partire fa sfarfallare le luci e tremare la camera, poi rompe
	  le luci delle stanze dove passa. Con _G.Rebounds torna indietro come Ambush.
	- Se sei a tiro, fuori da un nascondiglio e senza muri in mezzo, ti salta in faccia e muori.
	- Se hai in mano un crocifisso: il rituale. Il crocifisso ti vola davanti, sotto di lui si apre
	  il cerchio di DOORS, la luce lo stacca da terra, otto catene gli prendono mani, piedi e petto e
	  lo tirano a strattoni dentro un buco al centro del cerchio mentre si divincola e perde
	  centinaia di fogli; all'ultimo si aggrappa al bordo del buco, ma se lo portano giù lo stesso
	  con il braccio alzato, poi esplode tutto.
	- Il rituale (cerchio, catene, buco, colori) sta in CrucifixRitual, lo stesso del crocifisso
	  standalone: qui c'è solo il corpo di Honcho, cioè pose, fogli e luci.
	- Tre tipi di crocifisso, scelti con _G.CrucifixType: "Guiding" blu, "Curious" giallo, "Fail".
	  Con Fail il cerchio diventa rosso, lui strappa le catene, spezza il crocifisso, ricade a terra e
	  riparte: sei senza crocifisso e lui è ancora lì.
	- Per il rituale Honcho ha un'animazione sua, fatta in Studio sul suo rig e scritta qui come pose:
	  lo script la mette nei giunti frame per frame, quindi non va caricata e parte in DOORS. Quella
	  del fail è anche in HonchoCrucifixFail.rbxmx, da aprire nell'Animation Editor.
	- Texture, suono del crocifisso e animazioni sono asset di DOORS (LSPLASH): si caricano per ID,
	  senza getcustomasset.

	Lo vedi solo tu: è creato sul tuo client. Con _G.Sync = true aspetta la prossima porta, così chi
	esegue lo script insieme a te lo vede partire nello stesso momento.

	Uso
		loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/Honcho.lua"))()

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
	GiveCrucifix = true,  -- ti dà il crocifisso (modello di Penguin) se non ne hai già uno
	CrucifixType = "Guiding", -- il crocifisso che ti dà: "Guiding" blu, "Curious" giallo o "Fail"
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

local MODEL_ID = 83984800533456

-- Le animazioni di Honcho sono di LSPLASH, quindi dentro DOORS partono
local ANIMATION_IDS = {
	Idle   = 101907348895136,
	Walk   = 100466662502744, -- "Sprint"
	Attack = 91194170893496,  -- "honcho_chase_cutscene_start"
}

local SOUND_IDS = {
	Scream     = 82613796053949,  -- "archives_honcho_cutscenelanding", LSPLASH
}

local RITUAL_URL       = "https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/CrucifixRitual"
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
local FAIL_GRACE       = 1.5  -- dopo un crocifisso fallito, secondi prima che torni a cacciarti

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
if SETTINGS.CrucifixType ~= "Guiding" and SETTINGS.CrucifixType ~= "Curious" and SETTINGS.CrucifixType ~= "Fail" then
	warn(("[Honcho] _G.CrucifixType %q sconosciuto, uso Guiding"):format(SETTINGS.CrucifixType))
	SETTINGS.CrucifixType = "Guiding"
end

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
local body = {}
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

-- Il rituale del crocifisso è quello di CrucifixRitual, lo stesso del crocifisso standalone.
-- Lo chiedono in due all'avvio (precaricamento e crocifisso): si scarica una volta sola
local RitualModule = nil
local ritualLoading = false

local function ritualModule()
	while ritualLoading do
		task.wait(0.1)
	end
	if RitualModule then return RitualModule end

	ritualLoading = true
	local ok, result = pcall(function()
		return loadstring(game:HttpGet(RITUAL_URL))()
	end)
	ritualLoading = false

	if ok and type(result) == "table" then
		RitualModule = result
		if SETTINGS.Debug then
			result.Debug = true
		end
	else
		problem("CrucifixRitual non si è caricato, niente rituale: %s", tostring(result))
	end
	return RitualModule
end

-- Scarica prima texture e suoni del rituale, così quando serve appare tutto subito
local function preloadRitual()
	local ritual = ritualModule()
	if ritual then
		ritual.Preload()
	end
	pcall(function()
		ContentProvider:PreloadAsync({ "rbxassetid://" .. SOUND_IDS.Scream })
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
		return tonumber(a.Name) < tonumber(b.Name)
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
		return tonumber(a.Name) < tonumber(b.Name)
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

--[[ Solo i fogli in volo vanno nel BulkMoveTo. Prima ci andavano anche quelli già a terra, che
     non si muovono più: con 400 fogli quasi tutti posati erano centinaia di spostamenti a vuoto
     ogni frame. Le due liste si riusano invece di crearne due nuove a ogni frame. ]]
local movingParts, movingCFrames = {}, {}

local function updatePapers(deltaTime)
	table.clear(movingParts)
	table.clear(movingCFrames)
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
					-- Posato: l'ultima volta che si muove
					paper.landed = true
					paper.position = Vector3.new(paper.position.X, paper.floorY, paper.position.Z)
					paper.part.CFrame = CFrame.new(paper.position) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
				else
					table.insert(movingParts, paper.part)
					table.insert(movingCFrames, CFrame.new(paper.position) * CFrame.fromAxisAngle(paper.axis, paper.angle))
				end
			end

			local remaining = paper.life - paper.age
			if remaining < 1 then
				paper.part.Transparency = 1 - remaining
			end
		end
	end

	if #movingParts > 0 then
		workspace:BulkMoveTo(movingParts, movingCFrames, Enum.BulkMoveMode.FireCFrameChanged)
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

-- count fogli da punti a caso dentro il suo corpo, sparati in fuori e un po' in alto. Solo dalla
-- parte sopra il pavimento: quando è quasi tutto giù escono dal buco
local function burstFromBody(count, floorY)
	local model = state.model
	if count <= 0 or not model or not model.Parent then return end

	local boxCFrame, boxSize = model:GetBoundingBox()
	local bottom = math.max(boxCFrame.Position.Y - boxSize.Y / 2, floorY + 0.3)
	local top = math.max(boxCFrame.Position.Y + boxSize.Y / 2, bottom + 0.5)
	for _ = 1, count do
		local offset = Vector3.new((math.random() - 0.5) * boxSize.X, 0, (math.random() - 0.5) * boxSize.Z) * 0.8
		local point = boxCFrame:PointToWorldSpace(offset)
		point = Vector3.new(point.X, bottom + math.random() * (top - bottom), point.Z)
		local direction = (randomUnit() + Vector3.new(0, 0.9, 0)).Unit
		spawnPaper(point, floorY, direction * (8 + math.random() * 16))
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

---====== ANIMAZIONE DELL'ESORCISMO ======---
--[[ In DOORS partono solo le animazioni di LSPLASH, quindi questa non è un'Animation: sono pose
     scritte a mano che ogni frame finiscono nei Motor6D del modello (Transform), dopo l'Animator,
     come fa l'Animation Editor. Ogni valore è in gradi nel sistema del padre del giunto: X piega
     avanti e indietro, Y gira, Z piega di lato; il quarto, quinto e sesto sono uno spostamento in
     stud. Braccia e gambe si scrivono sempre come se fossero il lato destro: il sinistro è lo
     specchio, così R e L si leggono allo stesso modo.
     Sopra le pose: ogni parte arriva un po' dopo il busto (le mani per ultime, come una frusta),
     un tremito che cresce col rituale e la cravatta che sventola. ]]

local LIMB_SEGMENTS = { "Shoulder", "UpperArm", "UpperWrist", "LowerWrist", "Hand", "UpperLeg", "MiddleLeg", "LowerLeg", "Ankle", "Foot" }
local TIE_SEGMENTS  = { "TieTop", "TieUpper", "TieMiddle", "TieLower", "TieBottom" }

local POSE_SPECS = {
	-- Il colpo della luce: la testa scatta indietro, il braccio destro va su d'istinto, il sinistro indietro
	Whiplash = {
		Pelvis      = { -8, 0, 0, 0, 0, 0.5 },
		LowerTorso  = { 10, 0, 0 },
		MiddleTorso = { 14, 0, -4 },
		UpperTorso  = { 18, -6, -6 },
		Neck        = { 16, 0, 0 },
		Head        = { 38, 10, -12 },
		R = {
			Shoulder   = { 0, -30, 10 },
			UpperArm   = { 0, -10, 5 },
			UpperWrist = { 0, 45, 0 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, 20 },
			UpperLeg   = { -25, 0, 6 },
			MiddleLeg  = { -20, 0, 0 },
			LowerLeg   = { -10, 0, 0 },
			Ankle      = { -20, 0, 0 },
		},
		L = {
			Shoulder   = { 0, -50, -55 },
			UpperArm   = { 0, -10, -10 },
			UpperWrist = { 0, 15, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 0, 0, -10 },
			UpperLeg   = { 10, 0, 8 },
			MiddleLeg  = { -8, 0, 0 },
			LowerLeg   = { -8, 0, 0 },
			Ankle      = { 10, 0, 0 },
		},
	},

	-- Si rannicchia e si ripara la faccia col braccio destro, girato dall'altra parte
	Cower = {
		Pelvis      = { 0, -10, 0, 0, -0.9, 0.35 },
		LowerTorso  = { -6, -6, 0 },
		MiddleTorso = { -10, -8, 4 },
		UpperTorso  = { -14, -14, 6 },
		Neck        = { -10, -10, 4 },
		Head        = { -24, -30, 12 },
		R = {
			Shoulder   = { 0, 50, 60 },
			UpperArm   = { 0, 45, 30 },
			UpperWrist = { 0, 30, 0 },
			LowerWrist = { 0, 15, 0 },
			Hand       = { 0, 10, -25 },
			UpperLeg   = { 45, 0, 10 },
			MiddleLeg  = { -35, 0, 0 },
			LowerLeg   = { -40, 0, 0 },
			Ankle      = { 30, 0, 0 },
		},
		L = {
			Shoulder   = { 0, -35, -45 },
			UpperArm   = { 0, -10, -15 },
			UpperWrist = { 0, 35, 0 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, 20 },
			UpperLeg   = { 20, 0, 12 },
			MiddleLeg  = { -25, 0, 0 },
			LowerLeg   = { -30, 0, 0 },
			Ankle      = { 35, 0, 0 },
		},
	},

	-- La luce brucia: si torce ancora di più per scappare, il braccio sinistro cerca dietro
	Cower2 = {
		Pelvis      = { 0, -16, 0, 0, -0.8, 0.45 },
		LowerTorso  = { -4, -10, 2 },
		MiddleTorso = { -8, -14, 8 },
		UpperTorso  = { -8, -24, 12 },
		Neck        = { -6, -14, 8 },
		Head        = { -10, -42, 20 },
		R = {
			Shoulder   = { 0, 48, 64 },
			UpperArm   = { 0, 45, 30 },
			UpperWrist = { 0, 38, 0 },
			LowerWrist = { 0, 20, 0 },
			Hand       = { 0, 15, -30 },
			UpperLeg   = { 40, 0, 12 },
			MiddleLeg  = { -30, 0, 0 },
			LowerLeg   = { -36, 0, 0 },
			Ankle      = { 26, 0, 0 },
		},
		L = {
			Shoulder   = { 0, -55, -35 },
			UpperArm   = { 0, -15, -10 },
			UpperWrist = { 0, 25, 0 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, 30 },
			UpperLeg   = { 24, 0, 14 },
			MiddleLeg  = { -28, 0, 0 },
			LowerLeg   = { -32, 0, 0 },
			Ankle      = { 36, 0, 0 },
		},
	},

	-- La luce lo stacca da terra e lui si affloscia: testa giù, braccia e gambe che penzolano
	Limp = {
		LowerTorso  = { -6, 0, 0 },
		MiddleTorso = { -8, 0, 2 },
		UpperTorso  = { -10, 4, 4 },
		Neck        = { -15, 0, 0 },
		Head        = { -40, 6, 12 },
		R = {
			Shoulder   = { 10, 0, -82 },
			UpperArm   = { 0, 0, -4 },
			UpperWrist = { 0, 15, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 0, 0, -10 },
			UpperLeg   = { 8, 0, 3 },
			MiddleLeg  = { -10, 0, 0 },
			LowerLeg   = { -15, 0, 0 },
			Ankle      = { -45, 0, 0 },
		},
		L = {
			Shoulder   = { 16, 0, -80 },
			UpperArm   = { 0, 0, -4 },
			UpperWrist = { 0, 20, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 0, 0, -10 },
			UpperLeg   = { 3, 0, 2 },
			MiddleLeg  = { -6, 0, 0 },
			LowerLeg   = { -10, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	-- Si risveglia di scatto quando partono le catene: testa su, braccia che annaspano
	Jerk = {
		Pelvis      = { 0, 6, -4 },
		LowerTorso  = { 4, 4, -4 },
		MiddleTorso = { 8, 6, -6 },
		UpperTorso  = { 12, 10, -8 },
		Neck        = { 12, -8, 6 },
		Head        = { 35, -14, 12 },
		R = {
			Shoulder   = { 0, 30, 40 },
			UpperArm   = { 0, 10, 10 },
			UpperWrist = { 0, 40, 0 },
			LowerWrist = { 0, 15, 0 },
			Hand       = { 0, 0, 20 },
			UpperLeg   = { 50, 0, 10 },
			MiddleLeg  = { -45, 0, 0 },
			LowerLeg   = { -50, 0, 0 },
			Ankle      = { -30, 0, 0 },
		},
		L = {
			Shoulder   = { 0, -20, -30 },
			UpperArm   = { 0, -5, -10 },
			UpperWrist = { 0, 30, 0 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, 25 },
			UpperLeg   = { -10, 0, 6 },
			MiddleLeg  = { -12, 0, 0 },
			LowerLeg   = { -14, 0, 0 },
			Ankle      = { -45, 0, 0 },
		},
	},

	-- Le catene lo prendono: braccia strappate giù e indietro, schiena inarcata, testa all'indietro
	Seized = {
		LowerTorso  = { -10, 0, 0 },
		MiddleTorso = { 14, 0, 0 },
		UpperTorso  = { 20, 0, 0 },
		Neck        = { 18, 0, 0 },
		Head        = { 45, 0, 0 },
		R = {
			Shoulder   = { -50, 0, -78 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 45, 0, -15 },
			UpperLeg   = { -12, 0, 6 },
			MiddleLeg  = { -18, 0, 0 },
			LowerLeg   = { -20, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	-- L'urlo: inarcato e storto, un ginocchio su
	Scream = {
		LowerTorso  = { -10, 4, -4 },
		MiddleTorso = { 16, 6, -6 },
		UpperTorso  = { 22, 8, -10 },
		Neck        = { 20, 8, -10 },
		Head        = { 50, 15, -20 },
		R = {
			Shoulder   = { -55, 0, -70 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 15, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 50, 0, -20 },
			UpperLeg   = { 35, 0, 8 },
			MiddleLeg  = { -40, 0, 0 },
			LowerLeg   = { -45, 0, 0 },
			Ankle      = { -30, 0, 0 },
		},
		L = {
			Shoulder   = { -45, 0, -82 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 40, 0, -10 },
			UpperLeg   = { -14, 0, 5 },
			MiddleLeg  = { -16, 0, 0 },
			LowerLeg   = { -18, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	-- Si dimena: si piega a destra e si torce a sinistra, la testa va dall'altra parte, il braccio
	-- destro strattona la catena e il ginocchio destro sale
	StruggleA = {
		Pelvis      = { 0, 14, -10 },
		LowerTorso  = { -6, 10, -10 },
		MiddleTorso = { 8, 16, -16 },
		UpperTorso  = { 14, 20, -22 },
		Neck        = { 10, -20, 18 },
		Head        = { 18, -42, 34 },
		R = {
			Shoulder   = { -20, 0, -45 },
			UpperArm   = { -10, 0, -5 },
			UpperWrist = { 0, 55, 0 },
			LowerWrist = { 0, 20, 0 },
			Hand       = { 60, 0, -30 },
			UpperLeg   = { 70, 0, 12 },
			MiddleLeg  = { -55, 0, 0 },
			LowerLeg   = { -60, 0, 0 },
			Ankle      = { -20, 0, 0 },
		},
		L = {
			Shoulder   = { -50, 0, -84 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 8, 0 },
			LowerWrist = { 0, 4, 0 },
			Hand       = { 30, 0, 0 },
			UpperLeg   = { -15, 0, 5 },
			MiddleLeg  = { -6, 0, 0 },
			LowerLeg   = { -10, 0, 0 },
			Ankle      = { -45, 0, 0 },
		},
	},

	-- Si accartoccia in avanti con le ginocchia al petto e scuote la testa
	StruggleC = {
		Pelvis      = { -6, -6, 6 },
		LowerTorso  = { -8, -4, 6 },
		MiddleTorso = { -12, -6, 10 },
		UpperTorso  = { -18, -10, 14 },
		Neck        = { -12, 14, 10 },
		Head        = { -30, 25, 20 },
		R = {
			Shoulder   = { -10, 0, -55 },
			UpperArm   = { -8, 0, -5 },
			UpperWrist = { 0, 40, 0 },
			LowerWrist = { 0, 15, 0 },
			Hand       = { 40, 0, -20 },
			UpperLeg   = { 55, 0, 10 },
			MiddleLeg  = { -50, 0, 0 },
			LowerLeg   = { -55, 0, 0 },
			Ankle      = { -25, 0, 0 },
		},
		L = {
			Shoulder   = { -15, 0, -60 },
			UpperArm   = { -8, 0, -5 },
			UpperWrist = { 0, 35, 0 },
			LowerWrist = { 0, 15, 0 },
			Hand       = { 40, 0, -20 },
			UpperLeg   = { 40, 0, 8 },
			MiddleLeg  = { -45, 0, 0 },
			LowerLeg   = { -50, 0, 0 },
			Ankle      = { -30, 0, 0 },
		},
	},

	-- Uno spasmo: tutto all'indietro, gambe tirate dietro, testa rovesciata
	Spasm = {
		Pelvis      = { 6, -6, 4 },
		LowerTorso  = { -8, -4, 4 },
		MiddleTorso = { 18, -6, 6 },
		UpperTorso  = { 26, -8, 8 },
		Neck        = { 22, 10, -8 },
		Head        = { 55, -10, 10 },
		R = {
			Shoulder   = { -58, 0, -76 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 50, 0, -20 },
			UpperLeg   = { -30, 0, 6 },
			MiddleLeg  = { -30, 0, 0 },
			LowerLeg   = { -20, 0, 0 },
			Ankle      = { -40, 0, 0 },
		},
		L = {
			Shoulder   = { -52, 0, -80 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 50, 0, -20 },
			UpperLeg   = { -24, 0, 6 },
			MiddleLeg  = { -34, 0, 0 },
			LowerLeg   = { -24, 0, 0 },
			Ankle      = { -45, 0, 0 },
		},
	},

	-- Tira con tutte le forze contro le catene: inarcato, gomiti piegati, ginocchia indietro, testa
	-- verso la luce
	Strain = {
		Pelvis      = { 4, 8, 0 },
		LowerTorso  = { 4, 4, -2 },
		MiddleTorso = { 8, 6, -4 },
		UpperTorso  = { 12, 8, -6, 0, 0.15, 0 },
		Neck        = { 12, -6, 6 },
		Head        = { 40, -12, 15 },
		R = {
			Shoulder   = { -12, 0, -40 },
			UpperArm   = { -8, 0, -5 },
			UpperWrist = { 0, 60, 0 },
			LowerWrist = { 0, 20, 0 },
			Hand       = { 50, 0, -30 },
			UpperLeg   = { -10, 0, 4 },
			MiddleLeg  = { -35, 0, 0 },
			LowerLeg   = { -30, 0, 0 },
			Ankle      = { -45, 0, 0 },
		},
		L = {
			Shoulder   = { -18, 0, -44 },
			UpperArm   = { -8, 0, -5 },
			UpperWrist = { 0, 55, 0 },
			LowerWrist = { 0, 20, 0 },
			Hand       = { 50, 0, -30 },
			UpperLeg   = { -6, 0, 4 },
			MiddleLeg  = { -30, 0, 0 },
			LowerLeg   = { -34, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	-- Lo strattone di ogni tirata verso il basso: si piega in due di colpo
	Yank = {
		Pelvis      = { -10, 0, 0, 0, 0.3, 0 },
		LowerTorso  = { -14, 0, 0 },
		MiddleTorso = { -18, 0, 0 },
		UpperTorso  = { -22, 0, 0 },
		Neck        = { -15, 0, 0 },
		Head        = { -40, 0, 0 },
		R = {
			Shoulder   = { -20, 0, -88 },
			UpperArm   = { -6, 0, -4 },
			UpperWrist = { 0, 6, 0 },
			LowerWrist = { 0, 4, 0 },
			Hand       = { 30, 0, 0 },
			UpperLeg   = { 45, 0, 4 },
			MiddleLeg  = { -40, 0, 0 },
			LowerLeg   = { -45, 0, 0 },
			Ankle      = { -30, 0, 0 },
		},
	},

	-- Tra una tirata e l'altra si rialza e lotta, storto da un lato
	Fight = {
		Pelvis      = { 0, -8, 6 },
		LowerTorso  = { 2, -8, 6 },
		MiddleTorso = { 10, -10, 8 },
		UpperTorso  = { 16, -14, 12 },
		Neck        = { 14, 12, -10 },
		Head        = { 35, 20, -18 },
		R = {
			Shoulder   = { -15, 0, -48 },
			UpperArm   = { -8, 0, -5 },
			UpperWrist = { 0, 50, 0 },
			LowerWrist = { 0, 20, 0 },
			Hand       = { 55, 0, -25 },
			UpperLeg   = { 30, 0, 6 },
			MiddleLeg  = { -32, 0, 0 },
			LowerLeg   = { -36, 0, 0 },
			Ankle      = { -30, 0, 0 },
		},
		L = {
			Shoulder   = { -40, 0, -80 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 12, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 40, 0, -10 },
			UpperLeg   = { -8, 0, 4 },
			MiddleLeg  = { -8, 0, 0 },
			LowerLeg   = { -10, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	-- La catena della mano destra si spezza: il braccio vola su
	Wrench = {
		Pelvis      = { 0, -10, 6 },
		LowerTorso  = { 2, -10, 8 },
		MiddleTorso = { 6, -14, 10 },
		UpperTorso  = { 10, -20, 15 },
		Neck        = { 10, -14, 6 },
		Head        = { 30, -30, 10 },
		R = {
			Shoulder   = { 0, 25, 60 },
			UpperArm   = { 0, 10, 10 },
			UpperWrist = { 0, 30, 0 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, 20 },
			UpperLeg   = { 20, 0, 4 },
			MiddleLeg  = { -20, 0, 0 },
			LowerLeg   = { -24, 0, 0 },
			Ankle      = { -40, 0, 0 },
		},
		L = {
			Shoulder   = { -45, 0, -82 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 40, 0, -10 },
			UpperLeg   = { -6, 0, 4 },
			MiddleLeg  = { -8, 0, 0 },
			LowerLeg   = { -10, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	-- La mano libera sbatte sul bordo del buco e si aggrappa, come chi esce da una piscina
	Grab = {
		Pelvis      = { 0, -10, -4 },
		LowerTorso  = { -2, -8, -4 },
		MiddleTorso = { -3, -12, -6 },
		UpperTorso  = { -5, -20, -6 },
		Neck        = { 4, -8, -6 },
		Head        = { 20, -15, -10 },
		R = {
			Shoulder   = { 0, 58, 62 },
			UpperArm   = { 0, 8, 4 },
			UpperWrist = { 0, 45, -15 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, -45 },
			UpperLeg   = { 10, 0, 2 },
			MiddleLeg  = { -10, 0, 0 },
			LowerLeg   = { -12, 0, 0 },
			Ankle      = { -45, 0, 0 },
		},
		L = {
			Shoulder   = { -45, 0, -80 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 40, 0, -10 },
			UpperLeg   = { -6, 0, 4 },
			MiddleLeg  = { -8, 0, 0 },
			LowerLeg   = { -10, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	-- Si tira su con tutte le forze: gomito piegato, testa verso la luce
	Pull = {
		Pelvis      = { 0, -10, -4 },
		LowerTorso  = { -3, -8, -4 },
		MiddleTorso = { -4.5, -12, -6 },
		UpperTorso  = { -7.5, -20, -6 },
		Neck        = { 10, -10, -8 },
		Head        = { 32, -18, -12 },
		R = {
			Shoulder   = { 0, 50, 68 },
			UpperArm   = { 0, 8, 4 },
			UpperWrist = { 0, 60, -10 },
			LowerWrist = { 0, 10, 0 },
			Hand       = { 0, 0, -45 },
			UpperLeg   = { 20, 0, 4 },
			MiddleLeg  = { -18, 0, 0 },
			LowerLeg   = { -20, 0, 0 },
			Ankle      = { -40, 0, 0 },
		},
		L = {
			Shoulder   = { -40, 0, -76 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 20, 0 },
			LowerWrist = { 0, 8, 0 },
			Hand       = { 50, 0, -15 },
			UpperLeg   = { -4, 0, 4 },
			MiddleLeg  = { -6, 0, 0 },
			LowerLeg   = { -8, 0, 0 },
			Ankle      = { -50, 0, 0 },
		},
	},

	-- L'ultima tirata se lo porta giù: il braccio resta dritto verso l'alto, l'ultimo a sparire
	Taken = {
		Pelvis      = { 0, 0, 4 },
		LowerTorso  = { 4, 0, 4 },
		MiddleTorso = { 8, -4, 8 },
		UpperTorso  = { 12, -6, 12 },
		Neck        = { 16, 6, -6 },
		Head        = { 45, 10, -12 },
		R = {
			Shoulder   = { 0, 10, 80 },
			UpperArm   = { 0, 5, 5 },
			UpperWrist = { 0, 10, 0 },
			LowerWrist = { 0, 5, 0 },
			Hand       = { 0, 0, 10 },
			UpperLeg   = { -6, 0, 2 },
			MiddleLeg  = { -4, 0, 0 },
			LowerLeg   = { -6, 0, 0 },
			Ankle      = { -55, 0, 0 },
		},
		L = {
			Shoulder   = { -40, 0, -84 },
			UpperArm   = { -10, 0, -6 },
			UpperWrist = { 0, 8, 0 },
			LowerWrist = { 0, 4, 0 },
			Hand       = { 35, 0, -5 },
			UpperLeg   = { -6, 0, 2 },
			MiddleLeg  = { -4, 0, 0 },
			LowerLeg   = { -6, 0, 0 },
			Ankle      = { -55, 0, 0 },
		},
	},
}

---- Le pose del FAIL: duplicate da quelle sopra e piegate verso la rabbia invece che la resa ----

-- Si pianta: smette di scendere, busto dritto, gomiti piegati a tirare le catene verso di sé,
-- testa bassa che guarda il crocifisso
POSE_SPECS.Resist = {
	Pelvis      = { 6, 0, 0, 0, 0.1, 0 },
	LowerTorso  = { 6, 0, 0 },
	MiddleTorso = { 4, 0, 0 },
	UpperTorso  = { 2, 0, 0, 0, 0.1, 0 },
	Neck        = { -8, 0, 0 },
	Head        = { -18, 0, 0 },
	R = {
		Shoulder   = { -30, 0, -58 },
		UpperArm   = { -8, 0, -5 },
		UpperWrist = { 0, 75, 0 },
		LowerWrist = { 0, 25, 0 },
		Hand       = { 60, 0, -35 },
		UpperLeg   = { 12, 0, 12 },
		MiddleLeg  = { -22, 0, 0 },
		LowerLeg   = { -18, 0, 0 },
		Ankle      = { -30, 0, 0 },
	},
}

-- Strappa: il braccio destro va su con la catena spezzata, il sinistro tira ancora giù, il busto
-- si torce verso il braccio libero
POSE_SPECS.Tear = {
	Pelvis      = { 0, 12, -6 },
	LowerTorso  = { 4, 10, -6 },
	MiddleTorso = { 10, 14, -10 },
	UpperTorso  = { 16, 18, -14, 0, 0.1, 0 },
	Neck        = { 10, 12, -8 },
	Head        = { 30, 20, -14 },
	R = {
		Shoulder   = { 10, 20, 72 },
		UpperArm   = { 0, 10, 10 },
		UpperWrist = { 0, 20, 0 },
		LowerWrist = { 0, 10, 0 },
		Hand       = { 0, 0, 30 },
		UpperLeg   = { 30, 0, 10 },
		MiddleLeg  = { -30, 0, 0 },
		LowerLeg   = { -34, 0, 0 },
		Ankle      = { -30, 0, 0 },
	},
	L = {
		Shoulder   = { -40, 0, -70 },
		UpperArm   = { -10, 0, -6 },
		UpperWrist = { 0, 60, 0 },
		LowerWrist = { 0, 20, 0 },
		Hand       = { 55, 0, -30 },
		UpperLeg   = { -10, 0, 8 },
		MiddleLeg  = { -14, 0, 0 },
		LowerLeg   = { -16, 0, 0 },
		Ankle      = { -45, 0, 0 },
	},
}

-- Libero: petto in fuori, braccia spalancate verso l'alto, testa rovesciata, gambe aperte
POSE_SPECS.Roar = {
	Pelvis      = { -4, 0, 0, 0, 0.2, 0 },
	LowerTorso  = { 8, 0, 0 },
	MiddleTorso = { 16, 0, 0 },
	UpperTorso  = { 24, 0, 0, 0, 0.15, 0 },
	Neck        = { 18, 0, 0 },
	Head        = { 42, 0, 0 },
	R = {
		Shoulder   = { 5, -15, 45 },
		UpperArm   = { 0, -10, 10 },
		UpperWrist = { 0, 25, 0 },
		LowerWrist = { 0, 10, 0 },
		Hand       = { 0, 0, 35 },
		UpperLeg   = { -8, 0, 22 },
		MiddleLeg  = { -12, 0, 0 },
		LowerLeg   = { -10, 0, 0 },
		Ankle      = { -30, 0, 0 },
	},
}

-- Ricade: ginocchia al petto, braccia ancora su per l'equilibrio
POSE_SPECS.Drop = {
	Pelvis      = { -6, 0, 0 },
	LowerTorso  = { -6, 0, 0 },
	MiddleTorso = { -4, 0, 0 },
	UpperTorso  = { 0, 0, 0 },
	Neck        = { 4, 0, 0 },
	Head        = { 10, 0, 0 },
	R = {
		Shoulder   = { 0, -10, 20 },
		UpperArm   = { 0, -5, 5 },
		UpperWrist = { 0, 30, 0 },
		LowerWrist = { 0, 10, 0 },
		Hand       = { 0, 0, 20 },
		UpperLeg   = { 55, 0, 10 },
		MiddleLeg  = { -55, 0, 0 },
		LowerLeg   = { -40, 0, 0 },
		Ankle      = { -10, 0, 0 },
	},
}

-- Atterra accovacciato: il peso giù, busto in avanti, una mano quasi a terra, testa su verso di te
POSE_SPECS.Land = {
	Pelvis      = { -10, 0, 0, 0, -0.9, 0.2 },
	LowerTorso  = { -14, 0, 0 },
	MiddleTorso = { -14, 0, 0 },
	UpperTorso  = { -12, 0, 0 },
	Neck        = { 14, 0, 0 },
	Head        = { 26, 0, 0 },
	R = {
		Shoulder   = { -25, 0, -50 },
		UpperArm   = { -10, 0, -6 },
		UpperWrist = { 0, 35, 0 },
		LowerWrist = { 0, 10, 0 },
		Hand       = { 40, 0, -20 },
		UpperLeg   = { 60, 0, 14 },
		MiddleLeg  = { -65, 0, 0 },
		LowerLeg   = { -35, 0, 0 },
		Ankle      = { 20, 0, 0 },
	},
	L = {
		Shoulder   = { 10, 0, -70 },
		UpperArm   = { -6, 0, -4 },
		UpperWrist = { 0, 20, 0 },
		LowerWrist = { 0, 8, 0 },
		Hand       = { 20, 0, -10 },
		UpperLeg   = { 45, 0, 14 },
		MiddleLeg  = { -55, 0, 0 },
		LowerLeg   = { -30, 0, 0 },
		Ankle      = { 15, 0, 0 },
	},
}

-- Si rialza e ti guarda: spalle larghe, braccia aperte e basse, testa un po' china
POSE_SPECS.Loom = {
	Pelvis      = { 0, 0, 0 },
	LowerTorso  = { -2, 0, 0 },
	MiddleTorso = { -4, 0, 0 },
	UpperTorso  = { -6, 0, 0, 0, 0.1, 0 },
	Neck        = { -4, 0, 0 },
	Head        = { -8, 0, 0 },
	R = {
		Shoulder   = { 0, 0, -68 },
		UpperArm   = { 0, 0, -4 },
		UpperWrist = { 0, 20, 0 },
		LowerWrist = { 0, 8, 0 },
		Hand       = { 10, 0, -10 },
		UpperLeg   = { 2, 0, 8 },
		MiddleLeg  = { -4, 0, 0 },
		LowerLeg   = { -4, 0, 0 },
		Ankle      = { -2, 0, 0 },
	},
}

-- La stessa posa girata dall'altra parte: R e L si scambiano, il resto cambia verso
local function mirrorSpec(spec)
	local mirrored = { R = spec.L or spec.R, L = spec.R }
	for key, value in pairs(spec) do
		if key ~= "R" and key ~= "L" then
			mirrored[key] = { value[1], -value[2], -value[3], -(value[4] or 0), value[5], value[6] }
		end
	end
	return mirrored
end
POSE_SPECS.StruggleB = mirrorSpec(POSE_SPECS.StruggleA)
POSE_SPECS.FightB = mirrorSpec(POSE_SPECS.Fight)
POSE_SPECS.TearB = mirrorSpec(POSE_SPECS.Tear)

-- Da gradi a CFrame, con lo spostamento scalato come il modello
local function compilePose(spec)
	local pose = {}
	local function put(name, value, mirror)
		local y, z, x = value[2], value[3], value[4] or 0
		if mirror then
			y, z, x = -y, -z, -x
		end
		pose[name] = CFrame.new(Vector3.new(x, value[5] or 0, value[6] or 0) * SETTINGS.Size)
			* CFrame.Angles(math.rad(value[1]), math.rad(y), math.rad(z))
	end
	for key, value in pairs(spec) do
		if key ~= "R" and key ~= "L" then
			put(key, value, false)
		end
	end
	local left = spec.L or spec.R
	for _, segment in ipairs(LIMB_SEGMENTS) do
		if spec.R and spec.R[segment] then put("Right" .. segment, spec.R[segment], false) end
		if left and left[segment] then put("Left" .. segment, left[segment], true) end
	end
	return pose
end

-- Il copione del corpo, allineato al rituale: secondo, posa, come ci arriva. Agli strattoni
-- (2.50, 3.30, 4.05, 4.75) la posa di prima tiene fino al colpo, poi scatta in 6 centesimi
local BANISH_KEYS = {
	{ 0.00, "Start" },
	{ 0.06, "Whiplash", "Out" },   -- il colpo della luce
	{ 0.22, "Cower", "Out" },
	{ 0.40, "Cower2", "InOut" },
	{ 0.55, "Cower", "InOut" },
	{ 0.80, "Limp", "InOut" },     -- la luce lo stacca da terra
	{ 0.97, "Jerk", "Out" },       -- partono le catene
	{ 1.10, "Seized", "Out" },     -- lo prendono per le mani
	{ 1.28, "Scream", "InOut" },
	{ 1.45, "StruggleA", "InOut" },
	{ 1.60, "StruggleB", "InOut" },
	{ 1.76, "StruggleC", "InOut" },
	{ 1.90, "Spasm", "Out" },
	{ 2.06, "StruggleA", "InOut" },
	{ 2.22, "StruggleB", "InOut" },
	{ 2.40, "Strain", "InOut" },
	{ 2.50, "Strain" },
	{ 2.56, "Yank", "Out" },       -- primo strattone
	{ 2.80, "Fight", "InOut" },
	{ 2.98, "StruggleC", "InOut" },
	{ 3.14, "FightB", "InOut" },
	{ 3.30, "FightB" },
	{ 3.36, "Yank", "Out" },       -- secondo
	{ 3.58, "FightB", "InOut" },
	{ 3.74, "StruggleA", "InOut" },
	{ 3.90, "Fight", "InOut" },
	{ 4.05, "Fight" },
	{ 4.11, "Yank", "Out" },       -- terzo
	{ 4.32, "Fight", "InOut" },
	{ 4.50, "StruggleB", "InOut" },
	{ 4.66, "Strain", "InOut" },
	{ 4.75, "Strain" },
	{ 4.81, "Wrench", "Out" },     -- quarto: la catena della mano destra si spezza
	{ 4.95, "Grab", "Out" },       -- si aggrappa al bordo
	{ 5.20, "Pull", "InOut" },
	{ 5.35, "Pull" },
	{ 5.55, "Taken", "Out" },      -- l'ultima tirata
	{ 5.80, "Taken" },
}

--[[ Il copione del FAIL. Uguale fino al secondo strattone, poi va da un'altra parte: si pianta,
     strappa le catene a coppie, si libera urlando, ricade, atterra accovacciato e si rialza.
     I secondi sono quelli di Ritual.FailTimes in CrucifixRitual: gli strappi a 3.95, 4.22 e 4.48
     sono i momenti in cui le catene saltano davvero. ]]
local FAIL_KEYS = {
	{ 0.00, "Start" },
	{ 0.06, "Whiplash", "Out" },
	{ 0.22, "Cower", "Out" },
	{ 0.40, "Cower2", "InOut" },
	{ 0.55, "Cower", "InOut" },
	{ 0.80, "Limp", "InOut" },
	{ 0.97, "Jerk", "Out" },
	{ 1.10, "Seized", "Out" },
	{ 1.28, "Scream", "InOut" },
	{ 1.45, "StruggleA", "InOut" },
	{ 1.60, "StruggleB", "InOut" },
	{ 1.76, "StruggleC", "InOut" },
	{ 1.90, "Spasm", "Out" },
	{ 2.06, "StruggleA", "InOut" },
	{ 2.22, "StruggleB", "InOut" },
	{ 2.40, "Strain", "InOut" },
	{ 2.50, "Strain" },
	{ 2.56, "Yank", "Out" },       -- primo strattone
	{ 2.80, "Fight", "InOut" },
	{ 3.14, "FightB", "InOut" },
	{ 3.30, "FightB" },
	{ 3.36, "Yank", "Out" },       -- secondo: l'ultimo che gli riesce
	{ 3.62, "Resist", "Out" },     -- si pianta e il cerchio diventa rosso
	{ 3.88, "Resist", "InOut" },
	{ 3.95, "Tear", "Out" },       -- strappa le catene della destra
	{ 4.12, "Resist", "InOut" },
	{ 4.22, "TearB", "Out" },      -- quelle della sinistra
	{ 4.40, "Strain", "InOut" },
	{ 4.48, "Tear", "Out" },       -- quelle del petto
	{ 4.72, "Strain", "InOut" },
	{ 4.90, "Roar", "Out" },       -- libero: saltano tutte
	{ 5.25, "Roar", "InOut" },
	{ 5.45, "Drop", "InOut" },     -- ricade
	{ 5.62, "Land", "Out" },       -- atterra
	{ 6.10, "Land", "InOut" },
	{ 6.70, "Loom", "InOut" },     -- si rialza e ti guarda
	{ 7.20, "Loom" },
}

-- Quanto arriva in ritardo ogni parte rispetto al bacino
local JOINT_LAG = {
	Pelvis = 0, LowerTorso = 0.01, MiddleTorso = 0.02, UpperTorso = 0.03, Neck = 0.05, Head = 0.07,
	Shoulder = 0.03, UpperArm = 0.04, UpperWrist = 0.06, LowerWrist = 0.08, Hand = 0.1,
	UpperLeg = 0.02, MiddleLeg = 0.04, LowerLeg = 0.06, Ankle = 0.08, Foot = 0.09,
	TieTop = 0.05, TieUpper = 0.07, TieMiddle = 0.09, TieLower = 0.11, TieBottom = 0.13,
}

local function jointLag(name)
	local segment = string.gsub(string.gsub(name, "^Right", ""), "^Left", "")
	return JOINT_LAG[name] or JOINT_LAG[segment] or 0.04
end

-- Quanto trema, secondo per secondo: poco quando è floscio, sempre di più mentre lo tirano giù.
-- Nel fail trema di rabbia mentre strappa, poi quasi niente quando è di nuovo a terra
local function trembleAt(elapsed, fail)
	if fail and elapsed >= 3.36 then
		if elapsed < 4.9 then return 1.7 end
		if elapsed < 5.62 then return 2.1 end
		if elapsed < 6.3 then return 0.6 end
		return 0.15
	end
	if elapsed < 0.55 then return 0.7 end
	if elapsed < 0.97 then return 0.35 end
	if elapsed < 2.5 then return 1.1 end
	if elapsed < 4.75 then return 1.4 end
	return 1.9
end

local TREMBLE_DEGREES = {
	Head = 7, Neck = 4, UpperTorso = 3, MiddleTorso = 2, LowerTorso = 1.5, Pelvis = 1,
	RightShoulder = 3, LeftShoulder = 3, RightUpperArm = 2, LeftUpperArm = 2,
}

-- Mentre la mano destra è aggrappata al bordo il braccio trema poco, se no entra nel pavimento
local GRIPPING_ARM = { RightShoulder = true, RightUpperArm = true, RightUpperWrist = true, RightLowerWrist = true, RightHand = true }

local EASING = {
	Out   = function(x) return 1 - (1 - x) ^ 3 end,
	InOut = function(x) return (1 - math.cos(x * math.pi)) / 2 end,
}

-- Le due pose tra cui sta una parte in quel momento, e a che punto è
local function keyAt(keys, time)
	if time <= keys[1][1] then
		return keys[1], keys[1], 1
	end
	for index = 2, #keys do
		local key = keys[index]
		if time < key[1] then
			local previous = keys[index - 1]
			local alpha = math.clamp((time - previous[1]) / (key[1] - previous[1]), 0, 1)
			return previous, key, EASING[key[3] or "InOut"](alpha)
		end
	end
	local last = keys[#keys]
	return last, last, 1
end

-- I giunti con lo stesso ritardo cercano la stessa chiave: una ricerca per ritardo, non per
-- giunto. Tre tabelle riusate, niente di nuovo creato a ogni frame
local cachedFrom, cachedTo, cachedAlpha = {}, {}, {}

local function sampleBanish(poses, jointNames, lags, elapsed, into, fail)
	local keys = if fail then FAIL_KEYS else BANISH_KEYS
	local intensity = trembleAt(elapsed, fail)
	table.clear(cachedFrom)
	for index, name in ipairs(jointNames) do
		local lag = lags[name] or 0
		if not cachedFrom[lag] then
			cachedFrom[lag], cachedTo[lag], cachedAlpha[lag] = keyAt(keys, elapsed - lag)
		end
		local from, to, alpha = cachedFrom[lag], cachedTo[lag], cachedAlpha[lag]
		local cframe = (poses[from[2]][name] or CFrame.identity):Lerp(poses[to[2]][name] or CFrame.identity, alpha)
		local amount = math.rad((TREMBLE_DEGREES[name] or 2.5) * intensity)
		if not fail and GRIPPING_ARM[name] and elapsed > 4.9 and elapsed < 5.4 then
			amount *= 0.25
		end
		cframe *= CFrame.Angles(
			math.noise(index * 1.37, elapsed * 12) * 2 * amount,
			math.noise(index * 2.11, elapsed * 12 + 40) * 2 * amount,
			math.noise(index * 3.73, elapsed * 12 + 80) * 2 * amount
		)
		into[name] = cframe
	end

	-- La cravatta sventola, e mentre affonda vola in su. Nel fail ricade quando lui atterra
	local lift = if fail
		then math.clamp((elapsed - 2.5) / 1, 0, 1) * 20 * (1 - math.clamp((elapsed - 5.3) / 0.6, 0, 1))
		else math.clamp((elapsed - 2.5) / 3, 0, 1) * 30
	for index, name in ipairs(TIE_SEGMENTS) do
		if into[name] then
			local wave = math.sin(elapsed * 16 - index * 0.9) * (8 + 7 * intensity)
			into[name] *= CFrame.Angles(math.rad(lift * (if index == 1 then 1.4 else 0.5) + wave), math.rad(math.sin(elapsed * 9 + index) * 8), 0)
		end
	end
	return into
end

-- I Motor6D del modello, col nome della parte che muovono e il loro ritardo
local function collectJoints(model)
	local joints, names, lags = {}, {}, {}
	for _, motor in ipairs(model:GetDescendants()) do
		if motor:IsA("Motor6D") and motor.Part1 then
			local name = motor.Part1.Name
			local rotation = motor.C0.Rotation
			table.insert(joints, { name = name, motor = motor, rotation = rotation, inverse = rotation:Inverse() })
			table.insert(names, name)
			lags[name] = jointLag(name)
		end
	end
	return joints, names, lags
end

-- La posa che ha adesso, portata nel sistema del padre: il copione parte da qui
local function currentPose(joints)
	local pose = {}
	for _, joint in ipairs(joints) do
		pose[joint.name] = joint.rotation * joint.motor.Transform * joint.inverse
	end
	return pose
end

-- Girare nel sistema del padre vuol dire passare dalla rotazione del C0: per quasi tutti i giunti
-- è l'identità, per le spalle no
local function applyPose(joints, pose)
	for _, joint in ipairs(joints) do
		joint.motor.Transform = joint.inverse * (pose[joint.name] or CFrame.identity) * joint.rotation
	end
end

-- Ferma le animazioni di LSPLASH, così nei giunti comanda solo il copione
local function stopTracks()
	for _, track in ipairs({ body.idle, body.walk, body.attack }) do
		pcall(function()
			track:Stop(0)
		end)
	end
	body.moving = false
	if body.footsteps then
		body.footsteps:Stop()
	end
end

---====== RITUALE DEL CROCIFISSO ======---
--[[ Il cerchio, le catene, il buco, i colori e il fail sono in CrucifixRitual, lo stesso rituale
     del crocifisso standalone. Qui c'è solo il corpo di Honcho: dove sta, che posa ha, i fogli
     che perde e le luci che ha addosso. Il modulo lo chiama nei momenti giusti del copione. ]]

-- La parte con quel nome: in questo modello anche i Motor6D si chiamano come la parte che muovono
local function findPart(model, name)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant.Name == name and descendant:IsA("BasePart") then
			return descendant
		end
	end
	return nil
end

-- Le luci e le particelle che il modello di DOORS ha già dentro: il modulo le colora come il
-- rituale. Si ricorda com'erano, perché dopo un fail Honcho resta vivo e deve tornare normale
local BODY_EMITTERS = { Triangles = true, ZoomParticle = true, YellowParticle = true }

local function bodyEffects(model)
	local lights, emitters, saved = {}, {}, {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("PointLight") then
			saved[descendant] = {
				Color = descendant.Color, Brightness = descendant.Brightness,
				Range = descendant.Range, Enabled = descendant.Enabled,
			}
			descendant.Brightness = 0
			descendant.Range = 16 * SETTINGS.Size
			descendant.Enabled = true
			table.insert(lights, descendant)
		elseif descendant:IsA("ParticleEmitter") and BODY_EMITTERS[descendant.Name] then
			saved[descendant] = {
				Color = descendant.Color, LightEmission = descendant.LightEmission,
				LightInfluence = descendant.LightInfluence, Enabled = descendant.Enabled,
			}
			descendant.LightEmission = 1
			descendant.LightInfluence = 0
			table.insert(emitters, descendant)
		end
	end
	return lights, emitters, saved
end

-- Le otto catene: da che punto del bordo del cerchio partono (in gradi attorno a lui: 0 alla sua
-- destra, 90 dietro, -90 davanti), quanto lontano dal centro, cosa prendono e quando partono
local CHAIN_TARGETS = {
	{ part = "RightHand",       angle = 35,   reach = 0.85, at = 0.95 },
	{ part = "LeftHand",        angle = 145,  reach = 0.85, at = 1.00 },
	{ part = "RightFoot",       angle = -60,  reach = 0.45, at = 1.12 },
	{ part = "LeftFoot",        angle = -120, reach = 0.45, at = 1.18 },
	{ part = "UpperTorso",      angle = -20,  reach = 0.9,  at = 1.28, offset = Vector3.new(0.9, 0.2, 0) },
	{ part = "UpperTorso",      angle = -160, reach = 0.9,  at = 1.34, offset = Vector3.new(-0.9, 0.2, 0) },
	{ part = "RightUpperWrist", angle = 5,    reach = 0.95, at = 1.44 },
	{ part = "LeftUpperWrist",  angle = 175,  reach = 0.95, at = 1.50 },
}

-- Il corpo di Honcho, nella forma che CrucifixRitual si aspetta (vedi Ritual.Run)
local function honchoBody(fail, failTimes)
	local model = state.model

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

	-- Da qui il corpo lo muove il copione dell'esorcismo, partendo dalla posa che ha adesso
	local joints, jointNames, lags = collectJoints(model)
	local poses = { Start = currentPose(joints) }
	for name, spec in pairs(POSE_SPECS) do
		poses[name] = compilePose(spec)
	end
	stopTracks()

	local basePosition = state.position
	local floorY = floorAt(state.position, state.position.Y - state.pivotHeight)
	local center = Vector3.new(state.position.X, floorY, state.position.Z)
	local radius = math.clamp(math.max(state.boxSize.X, state.boxSize.Z) / 2 + 4, 6, 16)
	local lights, emitters, saved = bodyEffects(model)

	-- I fogli: un flusso mentre si divincola, un mucchio a ogni strattone, il resto alla fine
	local total = SETTINGS.Papers
	local streamBudget = math.floor(total * 0.4)
	local geyserBudget = math.floor(total * 0.35)
	local rainBudget = total - streamBudget - geyserBudget
	local joltBurst = math.floor(total * 0.025)
	local streamEnd = if fail then failTimes.Break else 5.8
	local streamLeft = streamBudget
	local streamRate = math.max(streamBudget - joltBurst * 4, 0) / (streamEnd - 1)
	local streamCarry = 0
	local lastStream = 0
	local frame = {}

	local honcho = {
		Scale      = SETTINGS.Size,
		Anchor     = center,
		Radius     = radius,
		-- Abbastanza giù da non vedere più neanche la mano alzata
		Depth      = state.pivotHeight + state.headHeight + (5 + 2.2) * SETTINGS.Size,
		Lights     = lights,
		Emitters   = emitters,
		-- Nel rituale riuscito all'ultimo strattone salta la catena della mano destra; nel fail
		-- saltano a coppie: la destra, la sinistra, il petto, poi tutte
		SnapFirst  = "RightHand",
		SnapGroups = { { "RightHand", "RightUpperWrist" }, { "LeftHand", "LeftUpperWrist" }, { "UpperTorso" } },
	}

	function honcho.Chains()
		local chains = {}
		for _, spec in ipairs(CHAIN_TARGETS) do
			local part = findPart(model, spec.part)
			if part then
				table.insert(chains, {
					part   = part,
					name   = spec.part,
					offset = (spec.offset or Vector3.zero) * SETTINGS.Size,
					angle  = spec.angle,
					reach  = spec.reach,
					at     = spec.at,
				})
			end
		end
		return chains
	end

	function honcho.Place(yOffset, offset)
		state.position = basePosition + Vector3.new(0, yOffset, 0)
		render(offset)
	end

	function honcho.Pose(elapsed, isFail)
		applyPose(joints, sampleBanish(poses, jointNames, lags, elapsed, frame, isFail))
	end

	-- Il flusso di fogli esce a lotti ogni decimo di secondo, non un pezzetto per frame: il
	-- conto del box del modello si fa dieci volte al secondo invece che a ogni frame
	function honcho.Step(_, elapsed, deltaTime)
		if elapsed < 1 or elapsed > streamEnd or streamLeft <= 0 then return end
		streamCarry += streamRate * deltaTime
		if elapsed - lastStream < 0.1 then return end
		lastStream = elapsed

		local count = math.min(math.floor(streamCarry), streamLeft)
		if count > 0 then
			streamCarry -= count
			streamLeft -= count
			burstFromBody(count, floorY)
		end
	end

	-- Ogni strattone gliene strappa un mucchio in più
	function honcho.Jolt()
		local burst = math.min(streamLeft, joltBurst)
		streamLeft -= burst
		burstFromBody(burst, floorY)
	end

	function honcho.Scream(_, kind)
		pcall(function()
			body.scream.PlaybackSpeed = if kind == "roar" then 0.7 else 0.85
			body.scream.Volume = if kind == "roar" then 3 else 2
			body.scream:Play()
		end)
	end

	-- Riuscito: al colpo finale sparisce nel buco e i fogli rimasti schizzano su
	function honcho.Vanish()
		if model.Parent then
			model:Destroy()
		end
		geyser(geyserBudget + streamLeft, center, radius, floorY)
		streamLeft = 0
		award("Crucify")
		if playerAlive() then
			award("Survive")
		end
	end

	-- Poi una pioggia di fogli dall'alto
	function honcho.After()
		task.spawn(function()
			local area = radius * 2.4
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
		end)
	end

	-- Fallito: quando si libera, nella rabbia gli volano via i fogli che gli restano
	function honcho.BreakFree()
		burstFromBody(streamLeft + math.floor(geyserBudget * 0.5), floorY)
		streamLeft = 0
	end

	-- Di nuovo a terra e di nuovo lui: luci, particelle e giunti come prima del rituale
	function honcho.Recover()
		for instance, properties in pairs(saved) do
			if instance.Parent then
				for property, value in pairs(properties) do
					pcall(function()
						instance[property] = value
					end)
				end
			end
		end
		pcall(function()
			body.scream.PlaybackSpeed = 1
			body.scream.Volume = 2
		end)
		applyPose(joints, {})
		state.position = basePosition
		render()
	end

	return honcho
end

--[[ Il rituale. Riuscito: Honcho finisce nel buco, come prima. Fallito: si libera, ricade e dopo
     FAIL_GRACE secondi torna a cacciarti, e il crocifisso non ce l'hai più. ]]
local function ritual(tool)
	award("Encounter")
	log("rituale del crocifisso")

	local Ritual = ritualModule()
	if not Ritual then
		-- Senza il modulo il crocifisso non fa niente, e non va riprovato a ogni frame
		state.noRitual = true
		state.paused = false
		state.watching = true
		return
	end

	local _, fail = Ritual.Outcome(tool, false)
	local result = Ritual.Run({
		Model = state.model,
		Tool  = tool,
		Body  = honchoBody(fail, Ritual.FailTimes),
		Alive = function()
			return not state.finished
		end,
	})

	if result == "Banished" then
		finish("esorcizzato")
	elseif result == "Failed" then
		log("il crocifisso si è spezzato: riparte")
		state.paused = false
		if state.running then
			setMoving(true)
		end
		task.delay(FAIL_GRACE, function()
			if not state.finished then
				state.watching = true
			end
		end)
	end
end

---====== IL GIOCATORE ======---

local sightParams = RaycastParams.new()
sightParams.FilterType = Enum.RaycastFilterType.Exclude
sightParams.RespectCanCollide = true

--[[ I nascondigli si leggono quando cambiano, non a ogni frame: prima GetTagged costruiva una
     lista nuova di tutti gli armadi della partita 60 volte al secondo. ]]
local hidingSpots = CollectionService:GetTagged("HidingSpot")
local function refreshHidingSpots()
	hidingSpots = CollectionService:GetTagged("HidingSpot")
end
table.insert(connections, CollectionService:GetInstanceAddedSignal("HidingSpot"):Connect(refreshHidingSpots))
table.insert(connections, CollectionService:GetInstanceRemovedSignal("HidingSpot"):Connect(refreshHidingSpots))

local sightIgnore = {}

local function canSee(origin, target, character)
	-- Come nello spawner di Vynixu: armadi e letti non bloccano la vista, devi esserci dentro
	table.clear(sightIgnore)
	table.move(hidingSpots, 1, #hidingSpots, 1, sightIgnore)
	table.insert(sightIgnore, character)
	table.insert(sightIgnore, state.model)
	sightParams.FilterDescendantsInstances = sightIgnore
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

	-- Il crocifisso conta prima del danno: se lo hai in mano quando arriva, ti salva (se regge)
	local crucifix = not state.noRitual and heldCrucifix(character)
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
	if tonumber(room.Name) < latestRoomNumber() then
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

---====== IL CROCIFISSO ======---

--[[ Il crocifisso di CrucifixRitual: il modello di Penguin, si consuma al primo utilizzo, e il
     suo tipo (_G.CrucifixType) decide il colore del rituale e se regge. ]]
local function giveCrucifix()
	for _, container in ipairs({ LocalPlayer:FindFirstChildOfClass("Backpack"), LocalPlayer.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				-- Ne hai già uno: va bene anche quello vero di DOORS
				if child:IsA("Tool") and (child.Name == "Crucifix" or CollectionService:HasTag(child, "Crucifix")) then
					log("hai già un crocifisso")
					return
				end
			end
		end
	end

	local Ritual = ritualModule()
	if Ritual and Ritual.Give(SETTINGS.CrucifixType, false) then
		log("crocifisso %s nello zaino: tienilo in mano quando arriva", SETTINGS.CrucifixType)
	end
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
