--[[
	HONCHO V2 — entità custom per DOORS · Gradish Mode
	Motore: Roblox · Linguaggio: Luau · Tipo: script client da executor

	È Honcho (Honcho.lua resta com'era) con la crocifissione rifatta:
	- Ogni animazione dura due secondi in più ed è più drammatica. La luce lo stacca da terra e lui
	  resta sospeso a braccia aperte; le catene arrivano una alla volta e ondeggiano; dietro al
	  crocifisso gira un'aureola. All'ultimo si tira fuori dal buco e per un attimo tutto si ferma,
	  come se ce la facesse: poi l'ultima tirata.
	- Il fail dura due secondi in più: prima di strappare l'ultima catena raccoglie la forza.
	- Il jumpscare e la sparizione a fine percorso durano due secondi in più.
	- Il crocifisso GLITCH (_G.CrucifixType = "Glitch"): la metà alta è fatta di pixel del Glitch di
	  DOORS che saltano fuori e tornano. Sul rituale fallisce in viola. Honcho si libera e ricade;
	  i pixel del crocifisso gli si schiantano addosso e il Glitch vero di DOORS gli appare sopra.
	  Poi sedici secondi a momenti chiari: il tempo si ferma; in ginocchio lotta mentre il Glitch
	  gli sale dai piedi al petto; si prende la testa mentre gli arriva in faccia, che diventa uno
	  schermo rotto; si alza a braccia aperte e gli si monta sopra una corona di blocchetti; tutto
	  si spegne; urla. Resta un Glitch e torna a cacciarti, più veloce.

	Tutto il resto è come Honcho: corre sui PathfindNodes come Rush, rompe le luci, ti uccide se
	sei a tiro e fuori da un nascondiglio, _G.Rebounds per tornare indietro come Ambush.

	Il rituale (cerchio, catene, buco, colori, glitch) sta in CrucifixRitual con il copione "V2": qui
	c'è solo il corpo di Honcho, cioè pose, fogli, luci e la trasformazione.

	Lo vedi solo tu: è creato sul tuo client. Con _G.Sync = true aspetta la prossima porta, così chi
	esegue lo script insieme a te lo vede partire nello stesso momento.

	Uso
		loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/HonchoV2.lua"))()

	Con le impostazioni: le righe _G vanno prima del loadstring (i nomi sono in IMPOSTAZIONI qui
	sotto). Vengono lette e poi cancellate, così il loadstring da solo torna ai valori normali.

		_G.CrucifixType = "Glitch"
		loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/HonchoV2.lua"))()

	Se qualcosa non va: _G.Debug = true, poi scrivi /console in chat e leggi le righe [Honcho V2].

	Crediti: modello, animazioni e suoni di Honcho di LSPLASH via il morph di MorthenHubber ·
	texture e suono del rituale di LSPLASH via il Repentance di RegularVynixu · texture e suoni del
	Glitch di LSPLASH · crocifisso di PenguinManiack · badge con DOORS Custom Achievements di
	RegularVynixu
]]

local CurrentRooms = workspace:FindFirstChild("CurrentRooms")
if not CurrentRooms then
	warn("[Honcho V2] non sei in una partita di DOORS: manca workspace.CurrentRooms")
	return
end

if workspace:FindFirstChild("SeekMovingNewClone") then
	warn("[Honcho V2] c'è l'inseguimento di Seek in corso: rieseguilo quando è finito")
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
	CrucifixType = "Guiding", -- il crocifisso che ti dà: "Guiding" blu, "Curious" giallo, "Fail" o "Glitch"
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
		warn(("[Honcho V2] _G.%s deve essere un %s, uso %s"):format(key, type(default), tostring(default)))
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
local JUMPSCARE_TIME   = 3.3  -- secondi che ti resta in faccia prima che tu muoia (V1: 1.3)
local JUMPSCARE_GAP    = 3.2  -- stud tra la camera e la sua faccia
local LUNGE_TIME       = 0.18
local MAX_PAPERS       = 1500 -- oltre, sui telefoni scatta
local FAIL_GRACE       = 1.5  -- dopo un crocifisso fallito, secondi prima che torni a cacciarti
local SINK_TIME        = 2.9  -- a fine percorso, quanto ci mette a sprofondare (V1: 0.9)
local TIMELINE         = "V2" -- il copione di CrucifixRitual: due secondi in più, più cinematografico

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
if not table.find({ "Guiding", "Curious", "Fail", "Glitch" }, SETTINGS.CrucifixType) then
	warn(("[Honcho V2] _G.CrucifixType %q sconosciuto, uso Guiding"):format(SETTINGS.CrucifixType))
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
		print("[Honcho V2] " .. string.format(format, ...))
	end
end

local function problem(format, ...)
	warn("[Honcho V2] " .. string.format(format, ...))
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

if _G.HonchoV2Cleanup then
	pcall(_G.HonchoV2Cleanup)
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
	glitched    = false,           -- il crocifisso Glitch l'ha trasformato
	jitter      = nil,             -- da glitchato: uno scatto di qualche centesimo
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
	if state.jitter then
		cframe *= state.jitter
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
	if _G.HonchoV2Cleanup == dismiss then
		_G.HonchoV2Cleanup = nil
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
		-- Dopo il salto resta lì e si avvicina ancora, piano, piegando la testa
		local held = math.clamp((os.clock() - startedAt - LUNGE_TIME) / (JUMPSCARE_TIME - LUNGE_TIME), 0, 1)
		held = held * held * (3 - 2 * held)
		local gap = far + (JUMPSCARE_GAP - far) * (1 - (1 - progress) ^ 3) - JUMPSCARE_GAP * 0.35 * held
		local rotation = CFrame.lookAt(Vector3.zero, -forward) * CFrame.Angles(0, 0, math.rad(16) * held)
		local facePosition = view.Position + forward * gap
		model:PivotTo(CFrame.new(facePosition - rotation:VectorToWorldSpace(headOffset)) * rotation)

		if progress >= 1 and not flashed then
			flashed = true
			flashScreen(if state.glitched then Color3.fromRGB(120, 0, 170) else Color3.fromRGB(150, 0, 0), 0.35, 0.5)
		end
	end)
	table.insert(cleanupTasks, function()
		RunService:UnbindFromRenderStep(stepName)
	end)

	-- A metà la camera trema di nuovo e lui urla più forte
	task.delay(JUMPSCARE_TIME * 0.55, function()
		if state.finished then return end
		shake(6, 16, 0.3, 1)
		pcall(function()
			body.scream.Volume = 3
			body.scream:Play()
		end)
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

---- Le pose nuove di V2 ----

-- Sospeso nella colonna di luce: le braccia si aprono da sole, i palmi in su, la testa rovesciata,
-- le gambe unite che penzolano con le punte in giù
POSE_SPECS.Levitate = {
	Pelvis      = { 4, 0, 0, 0, 0.2, 0 },
	LowerTorso  = { 6, 0, 0 },
	MiddleTorso = { 10, 0, 0 },
	UpperTorso  = { 14, 0, 0, 0, 0.1, 0 },
	Neck        = { 14, 0, 0 },
	Head        = { 38, 0, 0 },
	R = {
		Shoulder   = { 0, -10, -12 },
		UpperArm   = { 0, -4, 4 },
		UpperWrist = { 0, 12, 0 },
		LowerWrist = { 0, 6, 0 },
		Hand       = { -20, 0, 15 },
		UpperLeg   = { -4, 0, 2 },
		MiddleLeg  = { -6, 0, 0 },
		LowerLeg   = { -8, 0, 0 },
		Ankle      = { -55, 0, 0 },
	},
}

-- La speranza: aggrappato al bordo si tira fuori fino al petto, anche il braccio sinistro cerca
-- il bordo, la testa verso la luce
POSE_SPECS.Heave = {
	Pelvis      = { 0, -8, -4, 0, 0.35, 0 },
	LowerTorso  = { 2, -6, -4 },
	MiddleTorso = { 6, -10, -6 },
	UpperTorso  = { 10, -16, -6, 0, 0.1, 0 },
	Neck        = { 14, -8, -8 },
	Head        = { 40, -14, -10 },
	R = {
		Shoulder   = { 0, 46, 72 },
		UpperArm   = { 0, 8, 4 },
		UpperWrist = { 0, 72, -10 },
		LowerWrist = { 0, 14, 0 },
		Hand       = { 0, 0, -45 },
		UpperLeg   = { 40, 0, 6 },
		MiddleLeg  = { -45, 0, 0 },
		LowerLeg   = { -30, 0, 0 },
		Ankle      = { -30, 0, 0 },
	},
	L = {
		Shoulder   = { -20, 30, -20 },
		UpperArm   = { -6, 5, 0 },
		UpperWrist = { 0, 50, 0 },
		LowerWrist = { 0, 15, 0 },
		Hand       = { 30, 0, -20 },
		UpperLeg   = { -6, 0, 4 },
		MiddleLeg  = { -10, 0, 0 },
		LowerLeg   = { -12, 0, 0 },
		Ankle      = { -50, 0, 0 },
	},
}

-- Fail: prima dell'ultimo strappo raccoglie la forza, tutto chiuso su se stesso, le braccia
-- incrociate davanti che tirano le catene verso il petto
POSE_SPECS.Gather = {
	Pelvis      = { -8, 0, 0, 0, -0.2, 0 },
	LowerTorso  = { -10, 0, 0 },
	MiddleTorso = { -14, 0, 0 },
	UpperTorso  = { -18, 0, 0 },
	Neck        = { -6, 0, 0 },
	Head        = { -10, 0, 0 },
	R = {
		Shoulder   = { -20, 55, -30 },
		UpperArm   = { -6, 10, 0 },
		UpperWrist = { 0, 80, 0 },
		LowerWrist = { 0, 25, 0 },
		Hand       = { 40, 0, -40 },
		UpperLeg   = { 35, 0, 14 },
		MiddleLeg  = { -40, 0, 0 },
		LowerLeg   = { -30, 0, 0 },
		Ankle      = { -20, 0, 0 },
	},
}

---- Le pose del GLITCH: a terra, impazzito, ma sempre con i piedi sul pavimento ----

-- Il glitch lo colpisce: inarcato di lato, le braccia sbalzate via, la testa che scatta
POSE_SPECS.GlitchHit = {
	Pelvis      = { 10, 10, -12, 0, 0.3, 0.4 },
	LowerTorso  = { 12, 8, -10 },
	MiddleTorso = { 20, 12, -16 },
	UpperTorso  = { 28, 18, -22 },
	Neck        = { 20, -20, 20 },
	Head        = { 50, -35, 30 },
	R = {
		Shoulder   = { 10, -30, 50 },
		UpperArm   = { 0, -10, 10 },
		UpperWrist = { 0, 10, 0 },
		LowerWrist = { 0, 5, 0 },
		Hand       = { 0, 0, 40 },
		UpperLeg   = { -20, 0, 14 },
		MiddleLeg  = { -20, 0, 0 },
		LowerLeg   = { -15, 0, 0 },
		Ankle      = { -30, 0, 0 },
	},
	L = {
		Shoulder   = { -20, -40, 20 },
		UpperArm   = { 0, -10, 5 },
		UpperWrist = { 0, 30, 0 },
		LowerWrist = { 0, 10, 0 },
		Hand       = { 0, 0, 30 },
		UpperLeg   = { 30, 0, 10 },
		MiddleLeg  = { -40, 0, 0 },
		LowerLeg   = { -30, 0, 0 },
		Ankle      = { -10, 0, 0 },
	},
}

-- Si prende la testa con tutte e due le mani, piegato in avanti sulle ginocchia
POSE_SPECS.Clutch = {
	Pelvis      = { -6, 0, 0, 0, -0.5, 0 },
	LowerTorso  = { -10, 0, 0 },
	MiddleTorso = { -16, 0, 0 },
	UpperTorso  = { -22, 0, 0 },
	Neck        = { -16, 0, 0 },
	Head        = { -30, 0, 0 },
	R = {
		Shoulder   = { 0, 60, 45 },
		UpperArm   = { 0, 15, 10 },
		UpperWrist = { 0, 105, 0 },
		LowerWrist = { 0, 25, 0 },
		Hand       = { 0, 20, -30 },
		UpperLeg   = { 40, 0, 10 },
		MiddleLeg  = { -50, 0, 0 },
		LowerLeg   = { -25, 0, 0 },
		Ankle      = { 20, 0, 0 },
	},
}

-- Una convulsione: il busto si piega da una parte, la testa scatta dall'altra, un braccio va su
-- a caso e una gamba scalcia
POSE_SPECS.ConvulseA = {
	Pelvis      = { 4, 20, -10, 0.3, -0.3, 0 },
	LowerTorso  = { 6, 14, -14 },
	MiddleTorso = { 10, 20, -20 },
	UpperTorso  = { 14, 26, -26 },
	Neck        = { 10, -26, 22 },
	Head        = { 24, -50, 40 },
	R = {
		Shoulder   = { 20, -20, 70 },
		UpperArm   = { 0, -10, 15 },
		UpperWrist = { 0, 70, 0 },
		LowerWrist = { 0, 30, 0 },
		Hand       = { 0, 0, 50 },
		UpperLeg   = { 20, 0, 18 },
		MiddleLeg  = { -40, 0, 0 },
		LowerLeg   = { -20, 0, 0 },
		Ankle      = { 10, 0, 0 },
	},
	L = {
		Shoulder   = { -40, 20, -60 },
		UpperArm   = { -10, 0, -6 },
		UpperWrist = { 0, 90, 0 },
		LowerWrist = { 0, 30, 0 },
		Hand       = { 60, 0, -40 },
		UpperLeg   = { 50, 0, 16 },
		MiddleLeg  = { -60, 0, 0 },
		LowerLeg   = { -30, 0, 0 },
		Ankle      = { -20, 0, 0 },
	},
}

-- Storto come non si potrebbe: il busto girato, la testa piegata quasi sulla spalla, una mano
-- che si torce al contrario
POSE_SPECS.Twist = {
	Pelvis      = { 0, -20, 0 },
	LowerTorso  = { 0, 15, 0 },
	MiddleTorso = { 4, 25, 4 },
	UpperTorso  = { 8, 35, 8 },
	Neck        = { 0, 20, 30 },
	Head        = { 10, 30, 70 },
	R = {
		Shoulder   = { 0, 0, -30 },
		UpperArm   = { 0, 0, 0 },
		UpperWrist = { 0, 20, 0 },
		LowerWrist = { 0, 60, 0 },
		Hand       = { 40, 0, 40 },
		UpperLeg   = { 10, 0, 10 },
		MiddleLeg  = { -20, 0, 0 },
		LowerLeg   = { -10, 0, 0 },
		Ankle      = { 0, 0, 0 },
	},
	L = {
		Shoulder   = { -30, 0, -85 },
		UpperArm   = { 0, 0, -6 },
		UpperWrist = { 0, 5, 0 },
		LowerWrist = { 0, 5, 0 },
		Hand       = { 20, 0, 0 },
		UpperLeg   = { -10, 0, 6 },
		MiddleLeg  = { -10, 0, 0 },
		LowerLeg   = { -6, 0, 0 },
		Ankle      = { 0, 0, 0 },
	},
}

-- Barcolla: un passo storto in avanti, il busto che cade, le braccia a penzoloni
POSE_SPECS.StaggerA = {
	Pelvis      = { -6, 10, 4, 0, -0.3, 0.3 },
	LowerTorso  = { -8, 6, 4 },
	MiddleTorso = { -10, 8, 6 },
	UpperTorso  = { -12, 10, 8 },
	Neck        = { -4, -8, -6 },
	Head        = { -6, -16, -14 },
	R = {
		Shoulder   = { 20, 10, -78 },
		UpperArm   = { 0, 0, -4 },
		UpperWrist = { 0, 25, 0 },
		LowerWrist = { 0, 10, 0 },
		Hand       = { 20, 0, -10 },
		UpperLeg   = { 45, 0, 8 },
		MiddleLeg  = { -35, 0, 0 },
		LowerLeg   = { -10, 0, 0 },
		Ankle      = { 10, 0, 0 },
	},
	L = {
		Shoulder   = { -30, -10, -80 },
		UpperArm   = { 0, 0, -4 },
		UpperWrist = { 0, 15, 0 },
		LowerWrist = { 0, 8, 0 },
		Hand       = { 20, 0, -10 },
		UpperLeg   = { -25, 0, 6 },
		MiddleLeg  = { -15, 0, 0 },
		LowerLeg   = { -10, 0, 0 },
		Ankle      = { -15, 0, 0 },
	},
}

-- In ginocchio: il ginocchio sinistro a terra, il destro davanti, una mano sul ginocchio e una a
-- terra, la testa bassa. Lotta contro quello che gli sale addosso
POSE_SPECS.Kneel = {
	Pelvis      = { -8, 0, 0, 0, -1.3, 0.2 },
	LowerTorso  = { -10, 0, 0 },
	MiddleTorso = { -14, 0, 0 },
	UpperTorso  = { -18, 0, 0 },
	Neck        = { -8, 0, 0 },
	Head        = { -22, 0, 0 },
	R = {
		Shoulder   = { -20, 20, -70 },
		UpperArm   = { -6, 0, -4 },
		UpperWrist = { 0, 45, 0 },
		LowerWrist = { 0, 12, 0 },
		Hand       = { 30, 0, -20 },
		UpperLeg   = { 75, 0, 10 },
		MiddleLeg  = { -80, 0, 0 },
		LowerLeg   = { -15, 0, 0 },
		Ankle      = { 15, 0, 0 },
	},
	L = {
		Shoulder   = { -45, 0, -55 },
		UpperArm   = { -10, 0, -6 },
		UpperWrist = { 0, 20, 0 },
		LowerWrist = { 0, 8, 0 },
		Hand       = { 50, 0, -20 },
		UpperLeg   = { -5, 0, 8 },
		MiddleLeg  = { -85, 0, 0 },
		LowerLeg   = { -10, 0, 0 },
		Ankle      = { 30, 0, 0 },
	},
}

-- In ginocchio ma inarcato all'indietro: le braccia aperte e basse, la testa rovesciata, urla
POSE_SPECS.KneelArch = {
	Pelvis      = { 6, 0, 0, 0, -1.2, 0 },
	LowerTorso  = { 8, 0, 0 },
	MiddleTorso = { 16, 0, 0 },
	UpperTorso  = { 24, 0, 0, 0, 0.1, 0 },
	Neck        = { 18, 0, 0 },
	Head        = { 48, 0, 0 },
	R = {
		Shoulder   = { 0, -25, -25 },
		UpperArm   = { 0, -8, 5 },
		UpperWrist = { 0, 20, 0 },
		LowerWrist = { 0, 8, 0 },
		Hand       = { 0, 0, 30 },
		UpperLeg   = { 70, 0, 10 },
		MiddleLeg  = { -80, 0, 0 },
		LowerLeg   = { -15, 0, 0 },
		Ankle      = { 15, 0, 0 },
	},
	L = {
		Shoulder   = { 0, -25, -25 },
		UpperArm   = { 0, -8, 5 },
		UpperWrist = { 0, 20, 0 },
		LowerWrist = { 0, 8, 0 },
		Hand       = { 0, 0, 30 },
		UpperLeg   = { -5, 0, 8 },
		MiddleLeg  = { -85, 0, 0 },
		LowerLeg   = { -10, 0, 0 },
		Ankle      = { 30, 0, 0 },
	},
}

-- In piedi, dritto e alto: le braccia aperte verso il basso con i palmi in fuori, la testa un po'
-- alzata e storta. Non lotta più: adesso è il Glitch
POSE_SPECS.Rise = {
	Pelvis      = { 2, 0, 0, 0, 0.15, 0 },
	LowerTorso  = { 3, 0, 0 },
	MiddleTorso = { 5, 0, 0 },
	UpperTorso  = { 8, 0, 0, 0, 0.1, 0 },
	Neck        = { 8, 0, 8 },
	Head        = { 20, 0, 14 },
	R = {
		Shoulder   = { 0, -15, -35 },
		UpperArm   = { 0, -5, 4 },
		UpperWrist = { 0, 10, 0 },
		LowerWrist = { 0, 5, 0 },
		Hand       = { -15, 0, 25 },
		UpperLeg   = { 0, 0, 10 },
		MiddleLeg  = { -4, 0, 0 },
		LowerLeg   = { -4, 0, 0 },
		Ankle      = { 0, 0, 0 },
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
POSE_SPECS.ConvulseB = mirrorSpec(POSE_SPECS.ConvulseA)
POSE_SPECS.TwistB = mirrorSpec(POSE_SPECS.Twist)
POSE_SPECS.StaggerB = mirrorSpec(POSE_SPECS.StaggerA)

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

-- Il copione del corpo, allineato al copione V2 di CrucifixRitual: secondo, posa, come ci arriva.
-- Agli strattoni (3.60, 4.40, 5.20, 6.00) la posa di prima tiene fino al colpo, poi scatta in 6
-- centesimi. Rispetto a Honcho V1 ogni momento dura di più: il colpo della luce resta, lui resta
-- sospeso a braccia aperte prima che arrivino le catene, l'urlo si allunga, e prima dell'ultima
-- tirata si tira fuori dal buco fino al petto e tutto si ferma
local BANISH_KEYS = {
	{ 0.00, "Start" },
	{ 0.08, "Whiplash", "Out" },   -- il colpo della luce
	{ 0.34, "Whiplash", "InOut" }, -- e lo tiene
	{ 0.52, "Cower", "Out" },
	{ 0.72, "Cower2", "InOut" },
	{ 0.92, "Cower", "InOut" },
	{ 1.30, "Limp", "InOut" },     -- la luce lo stacca da terra
	{ 1.50, "Levitate", "InOut" }, -- sospeso, le braccia si aprono da sole
	{ 1.62, "Levitate" },
	{ 1.70, "Jerk", "Out" },       -- partono le catene
	{ 1.90, "Seized", "Out" },     -- lo prendono per le mani
	{ 2.12, "Scream", "InOut" },
	{ 2.45, "Scream", "InOut" },   -- l'urlo dura
	{ 2.65, "StruggleA", "InOut" },
	{ 2.85, "StruggleB", "InOut" },
	{ 3.05, "StruggleC", "InOut" },
	{ 3.20, "Spasm", "Out" },
	{ 3.38, "StruggleA", "InOut" },
	{ 3.55, "Strain", "InOut" },
	{ 3.60, "Strain" },
	{ 3.66, "Yank", "Out" },       -- primo strattone
	{ 3.92, "Fight", "InOut" },
	{ 4.12, "StruggleC", "InOut" },
	{ 4.30, "FightB", "InOut" },
	{ 4.40, "FightB" },
	{ 4.46, "Yank", "Out" },       -- secondo
	{ 4.70, "FightB", "InOut" },
	{ 4.88, "StruggleA", "InOut" },
	{ 5.08, "Fight", "InOut" },
	{ 5.20, "Fight" },
	{ 5.26, "Yank", "Out" },       -- terzo
	{ 5.50, "Fight", "InOut" },
	{ 5.70, "StruggleB", "InOut" },
	{ 5.90, "Strain", "InOut" },
	{ 6.00, "Strain" },
	{ 6.06, "Wrench", "Out" },     -- quarto: la catena della mano destra si spezza
	{ 6.22, "Grab", "Out" },       -- si aggrappa al bordo
	{ 6.50, "Pull", "InOut" },
	{ 6.95, "Heave", "InOut" },    -- si tira fuori: sembra che ce la faccia
	{ 7.35, "Heave" },             -- il silenzio
	{ 7.52, "Taken", "Out" },      -- l'ultima tirata
	{ 7.80, "Taken" },
}

-- Le chiavi di un copione fino a un certo secondo compreso: il fail e il glitch partono uguali
local function keysUntil(keys, time)
	local copy = {}
	for _, key in ipairs(keys) do
		if key[1] > time then break end
		table.insert(copy, key)
	end
	return copy
end

--[[ Il copione del FAIL. Uguale fino al secondo strattone (4.40), poi si pianta, strappa le
     catene a coppie (5.20, 5.60, 6.00, i momenti in cui saltano davvero), raccoglie la forza,
     si libera urlando a 6.60, ricade, atterra accovacciato a 7.40 e si rialza. ]]
local FAIL_KEYS = keysUntil(BANISH_KEYS, 4.40)
for _, key in ipairs({
	{ 4.46, "Yank", "Out" },       -- secondo: l'ultimo che gli riesce
	{ 4.80, "Resist", "Out" },     -- si pianta e il cerchio diventa rosso
	{ 5.12, "Resist", "InOut" },
	{ 5.20, "Tear", "Out" },       -- strappa le catene della destra
	{ 5.48, "Resist", "InOut" },
	{ 5.60, "TearB", "Out" },      -- quelle della sinistra
	{ 5.86, "Strain", "InOut" },
	{ 6.00, "Tear", "Out" },       -- quelle del petto
	{ 6.30, "Gather", "InOut" },   -- raccoglie la forza
	{ 6.54, "Gather" },
	{ 6.60, "Roar", "Out" },       -- libero: saltano tutte
	{ 7.00, "Roar", "InOut" },
	{ 7.20, "Drop", "InOut" },     -- ricade
	{ 7.40, "Land", "Out" },       -- atterra
	{ 8.00, "Land", "InOut" },
	{ 8.70, "Loom", "InOut" },     -- si rialza e ti guarda
	{ 9.20, "Loom" },
}) do
	table.insert(FAIL_KEYS, key)
end

--[[ Il copione del GLITCH: il fail fino all'atterraggio, poi a 7.70 il glitch lo colpisce e per
     sedici secondi si trasforma. Non è un dimenarsi a caso: sono cinque momenti, ognuno con la sua
     idea, e si capisce sempre cosa sta succedendo.

       IL COLPO     0 - 1      il colpo lo inarca, e il tempo si ferma per mezzo secondo
       LA RISALITA  1 - 5.4    in ginocchio, lotta; il Glitch gli sale dai piedi al petto
       LA TESTA     5.4 - 10.2 si prende la testa, si torce: il Glitch gli arriva in faccia
       IN PIEDI     10.2 - 13.5 raccoglie la forza e si alza a braccia aperte; sopra la sua testa
                                si monta, un blocchetto alla volta, una corona
       IL SILENZIO  13.5 - 14.3 tutto si spegne e lui è immobile
       L'URLO       14.3 - 16  urla, e tutto riparte

     I secondi qui sotto sono dal colpo. Gli scatti (GLITCH_BEATS) non sono a caso: arrivano a
     tempo, sempre più fitti, come un cuore che accelera. ]]
local GLITCH_STRIKE = 7.7
local GLITCH_SPAN   = 16  -- gli stessi di CrucifixRitual (copione V2)

local GLITCH_PHASES = { Hit = 1, Corrupt = 5.4, Head = 10.2, Rise = 13.5, Hush = 14.3 }
local GLITCH_BEATS = {
	1.6, 2.3, 2.9, 3.4, 3.9, 4.4, 4.9, 5.3,
	5.8, 6.3, 6.7, 7.1, 7.5, 7.85, 8.2, 8.5, 8.8, 9.1, 9.35, 9.6, 9.85, 10.05,
}

local GLITCH_KEYS = keysUntil(FAIL_KEYS, 7.40)
for _, key in ipairs({
	{ 0.00, "Land" },
	{ 0.08, "GlitchHit", "Out" },   -- il colpo
	{ 0.60, "GlitchHit" },          -- (il tempo è fermo)
	{ 1.20, "Kneel", "InOut" },     -- cade in ginocchio
	{ 1.95, "KneelArch", "Out" },   -- si inarca e urla
	{ 2.55, "Kneel", "InOut" },
	{ 3.10, "ConvulseA", "Out" },   -- si rialza a scatti
	{ 3.60, "StaggerA", "InOut" },  -- barcolla
	{ 4.15, "StaggerB", "InOut" },
	{ 4.70, "ConvulseB", "Out" },
	{ 5.40, "Clutch", "InOut" },    -- LA TESTA: se la prende
	{ 6.10, "Twist", "Out" },
	{ 6.70, "Clutch", "InOut" },
	{ 7.30, "TwistB", "Out" },
	{ 7.90, "Clutch", "InOut" },
	{ 8.45, "ConvulseA", "Out" },
	{ 8.90, "Spasm", "Out" },
	{ 9.40, "Clutch", "InOut" },
	{ 10.20, "Gather", "InOut" },   -- IN PIEDI: raccoglie la forza
	{ 11.40, "Rise", "InOut" },     -- si alza a braccia aperte
	{ 14.30, "Rise" },              -- (il silenzio: immobile)
	{ 14.38, "Roar", "Out" },       -- L'URLO
	{ 15.20, "Roar", "InOut" },
	{ 16.00, "Loom", "InOut" },
	{ 16.80, "Loom" },
}) do
	table.insert(GLITCH_KEYS, { GLITCH_STRIKE + key[1], key[2], key[3] })
end

local KEYS = { Banish = BANISH_KEYS, Fail = FAIL_KEYS, Glitch = GLITCH_KEYS }

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

-- Quanto trema, secondo per secondo: poco quando è floscio o sospeso, sempre di più mentre lo
-- tirano giù, quasi niente nel silenzio prima dell'ultima tirata. Nel fail trema di rabbia, al
-- massimo mentre raccoglie la forza; nel glitch sempre di più per sedici secondi
local function trembleAt(elapsed, mode)
	if mode == "Glitch" and elapsed >= GLITCH_STRIKE then
		local g = elapsed - GLITCH_STRIKE
		if g < GLITCH_PHASES.Hit then return 2.2 end
		if g < GLITCH_PHASES.Corrupt then return 1.3 end
		if g < GLITCH_PHASES.Head then return 1.3 + 0.9 * (g - GLITCH_PHASES.Corrupt) / (GLITCH_PHASES.Head - GLITCH_PHASES.Corrupt) end
		if g < GLITCH_PHASES.Rise then return 0.8 - 0.6 * (g - GLITCH_PHASES.Head) / (GLITCH_PHASES.Rise - GLITCH_PHASES.Head) end
		if g < GLITCH_PHASES.Hush then return 0.03 end
		if g < GLITCH_PHASES.Hush + 0.9 then return 2.4 end
		return 0.3
	end
	if mode ~= "Banish" and elapsed >= 4.46 then
		if elapsed < 6.3 then return 1.7 end
		if elapsed < 6.6 then return 2.6 end
		if elapsed < 7.4 then return 2.1 end
		if elapsed < 8.1 then return 0.6 end
		return 0.15
	end
	if elapsed < 0.9 then return 0.7 end
	if elapsed < 1.66 then return 0.3 end
	if elapsed < 3.6 then return 1.1 end
	if elapsed < 6.0 then return 1.4 end
	if elapsed >= 7.1 and elapsed < 7.4 then return 0.35 end
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

local function sampleBanish(poses, jointNames, lags, elapsed, into, mode)
	local keys = KEYS[mode]
	local intensity = trembleAt(elapsed, mode)
	table.clear(cachedFrom)
	for index, name in ipairs(jointNames) do
		local lag = lags[name] or 0
		if not cachedFrom[lag] then
			cachedFrom[lag], cachedTo[lag], cachedAlpha[lag] = keyAt(keys, elapsed - lag)
		end
		local from, to, alpha = cachedFrom[lag], cachedTo[lag], cachedAlpha[lag]
		local cframe = (poses[from[2]][name] or CFrame.identity):Lerp(poses[to[2]][name] or CFrame.identity, alpha)
		local amount = math.rad((TREMBLE_DEGREES[name] or 2.5) * intensity)
		if mode == "Banish" and GRIPPING_ARM[name] and elapsed > 6.15 and elapsed < 7.45 then
			amount *= 0.25
		end
		cframe *= CFrame.Angles(
			math.noise(index * 1.37, elapsed * 12) * 2 * amount,
			math.noise(index * 2.11, elapsed * 12 + 40) * 2 * amount,
			math.noise(index * 3.73, elapsed * 12 + 80) * 2 * amount
		)
		into[name] = cframe
	end

	-- La cravatta sventola, e mentre affonda vola in su. Nel fail ricade quando lui atterra; nel
	-- glitch frusta l'aria mentre impazzisce
	local lift = if mode == "Banish"
		then math.clamp((elapsed - 3.5) / 3.5, 0, 1) * 30
		else math.clamp((elapsed - 3.5) / 1, 0, 1) * 20 * (1 - math.clamp((elapsed - 7.0) / 0.6, 0, 1))
	if mode == "Glitch" and elapsed >= GLITCH_STRIKE then
		lift += 30 * math.abs(math.noise(elapsed * 2.5, 3.7)) * (1 - math.clamp((elapsed - GLITCH_STRIKE - GLITCH_SPAN) / 0.6, 0, 1))
	end
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
-- In V2 arrivano una alla volta, e il corpo scatta a ognuna
local CHAIN_TARGETS = {
	{ part = "RightHand",       angle = 35,   reach = 0.85, at = 1.60 },
	{ part = "LeftHand",        angle = 145,  reach = 0.85, at = 1.76 },
	{ part = "RightFoot",       angle = -60,  reach = 0.45, at = 1.94 },
	{ part = "LeftFoot",        angle = -120, reach = 0.45, at = 2.08 },
	{ part = "UpperTorso",      angle = -20,  reach = 0.9,  at = 2.26, offset = Vector3.new(0.9, 0.2, 0) },
	{ part = "UpperTorso",      angle = -160, reach = 0.9,  at = 2.40, offset = Vector3.new(-0.9, 0.2, 0) },
	{ part = "RightUpperWrist", angle = 5,    reach = 0.95, at = 2.58 },
	{ part = "LeftUpperWrist",  angle = 175,  reach = 0.95, at = 2.72 },
}

---====== IL GLITCH ======---
--[[ Il crocifisso Glitch fallisce, e quello che ne resta lo colpisce a terra. Poi sedici secondi
     che seguono il copione del glitch (GLITCH_PHASES, qui sopra), e ogni cosa ha il suo momento:

     - Il Glitch di DOORS gli sale addosso come un'onda, dai piedi (appena colpito) al petto (a
       5.4) alla testa (a 10.2): il colore scivola nel viola scuro del Glitch e compare la sua
       pelle a quadretti. Solo la fascia dove passa l'onda sfarfalla, e solo da lì si staccano i
       blocchetti: si vede dov'è arrivato.
     - La faccia diventa uno schermo rotto, con l'immagine del Glitch di DOORS, quando l'onda ci
       arriva.
     - Gli scatti arrivano a tempo (GLITCH_BEATS), non a caso: a ogni colpo la posa si ferma per un
       decimo di secondo, una fetta del corpo scivola di lato in rosso e ciano, una parte scatta di
       traverso, lo schermo si strappa appena, l'urlo si inceppa. Tra un colpo e l'altro, calmo.
     - In piedi, i blocchetti gli montano sopra la testa una corona, uno alla volta.
     - Il silenzio: luci quasi spente, niente suoni, immobile. Poi l'urlo, e tutto riparte.

     Finito, resta un Glitch: pelle, faccia rotta, corona che gira a scatti. Ogni tanto, anche
     mentre corre, un colpo di glitch. E corre più forte. ]]

local GLITCH = {
	Main  = Color3.fromRGB(196, 70, 255),  -- il viola del rituale Glitch
	Alt   = Color3.fromRGB(70, 255, 240),  -- il ciano che ci sfarfalla sopra
	Red   = Color3.fromRGB(255, 0, 0),     -- i due colori dei quadrati del Glitch di DOORS
	Cyan  = Color3.fromRGB(0, 255, 213),
	Body  = Color3.fromRGB(58, 52, 103),   -- il colore del corpo del Glitch di DOORS
	Speed = 1.25,                          -- quanto corre più forte dopo
	Band  = 0.14,                          -- quanto è alta la fascia dell'onda che lo trasforma
}

-- A che altezza del corpo è arrivata l'onda (0 i piedi, 1 la testa), g secondi dopo il colpo
local function glitchFront(g)
	if g < 0.6 then return -0.1 end
	if g < GLITCH_PHASES.Corrupt then
		return -0.1 + 0.72 * (g - 0.6) / (GLITCH_PHASES.Corrupt - 0.6)
	end
	if g < GLITCH_PHASES.Head then
		return 0.62 + 0.5 * (g - GLITCH_PHASES.Corrupt) / (GLITCH_PHASES.Head - GLITCH_PHASES.Corrupt)
	end
	return 1.2
end

-- I pezzi dove si accendono i quadrati del Glitch
local STATIC_PARTS = { "UpperTorso", "MiddleTorso", "Pelvis", "Head", "RightUpperArm", "LeftUpperArm",
	"RightUpperLeg", "LeftUpperLeg", "RightLowerWrist", "LeftLowerWrist" }

local function smoothstep(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function randomSigned(amount)
	return (math.random() * 2 - 1) * amount
end

-- stage è il palco di CrucifixRitual (serve per lo schermo che si strappa); Ritual il modulo, che
-- ha la pelle, i quadrati e i blocchetti del Glitch di DOORS
local function glitchBody(model, stage, jointNames, Ritual)
	local fx = { power = 0 }
	local startedAt = os.clock()
	local size = SETTINGS.Size
	local studs = 2 * size -- un riquadro della pelle ogni 2 stud, come il Glitch (3 su 15 di altezza)
	local kit = Ritual.Glitch

	-- Le parti visibili, dal basso in alto, ognuna con la sua pelle ancora invisibile
	local boxCFrame, boxSize = model:GetBoundingBox()
	local bottom = boxCFrame.Position.Y - boxSize.Y / 2
	local parts, allSkins = {}, {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local skin = kit.Skin(part, studs)
			for _, texture in ipairs(skin) do
				table.insert(allSkins, texture)
			end
			table.insert(parts, {
				part   = part,
				from   = part.Color,
				skin   = skin,
				height = math.clamp((part.Position.Y - bottom) / math.max(boxSize.Y, 1), 0, 1),
				done   = false,
			})
		end
	end
	local decals = {}
	for _, decal in ipairs(model:GetDescendants()) do
		if decal:IsA("Decal") then
			table.insert(decals, { decal = decal, from = decal.Color3 })
		end
	end

	local statics = {}
	for _, name in ipairs(STATIC_PARTS) do
		local host = findPart(model, name)
		if host then
			table.insert(statics, kit.Static(host, 0, 1.2 * size))
		end
	end

	local aura = Instance.new("Highlight")
	aura.Name = "GlitchAura"
	aura.DepthMode = Enum.HighlightDepthMode.Occluded
	aura.FillColor = GLITCH.Body
	aura.OutlineColor = GLITCH.Main
	aura.FillTransparency = 1
	aura.OutlineTransparency = 1
	aura.Parent = model

	local lightHost = findPart(model, "UpperTorso") or model.PrimaryPart
	local light = Instance.new("PointLight")
	light.Name = "GlitchLight"
	light.Color = GLITCH.Main
	light.Brightness = 0
	light.Range = 14 * size
	light.Shadows = false
	light.Parent = lightHost

	-- L'urlo si distorce e resta così
	local distortion = Instance.new("DistortionSoundEffect")
	distortion.Level = 0.45
	pcall(function() distortion.Parent = body.scream end)

	-- I blocchetti: si staccano solo dalla fascia dove sta passando l'onda. Più tardi diventano
	-- la corona
	local swarmFolder = Instance.new("Folder")
	swarmFolder.Name = "HonchoGlitchCubes"
	swarmFolder.Parent = workspace
	table.insert(cleanupTasks, function()
		swarmFolder:Destroy()
	end)
	local swarm = Ritual.GlitchSwarm(swarmFolder, 18, 0.4 * size, true, 4)
	swarm.chaos = 0.15
	swarm:shed(function()
		for _ = 1, 6 do
			local entry = parts[math.random(#parts)]
			if entry and entry.band and entry.part.Parent then
				local half = entry.part.Size / 2
				return entry.part.CFrame:PointToWorldSpace(Vector3.new(randomSigned(half.X), randomSigned(half.Y), randomSigned(half.Z)))
			end
		end
		return nil
	end)
	swarm:setVisible(true)

	-- La faccia: uno schermo rotto con l'immagine del Glitch di DOORS, tre copie (rossa, ciano,
	-- viola) che si separano quando è forte
	local head = findPart(model, "Head")
	local faceImages = {}
	if head then
		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local gui = Instance.new("SurfaceGui")
			gui.Name = "GlitchFace"
			gui.Face = face
			gui.LightInfluence = 0
			gui.Brightness = 2
			gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
			gui.CanvasSize = Vector2.new(128, 128)
			gui.ClipsDescendants = true
			gui.Parent = head
			for index, colour in ipairs({ GLITCH.Red, GLITCH.Cyan, GLITCH.Main }) do
				local image = Instance.new("ImageLabel")
				image.BackgroundTransparency = 1
				image.AnchorPoint = Vector2.new(0.5, 0.5)
				image.Position = UDim2.fromScale(0.5, 0.5)
				image.Size = UDim2.fromScale(1.1, 1.1)
				image.Image = "rbxassetid://" .. kit.Screen
				image.ImageColor3 = colour
				image.ImageTransparency = 1
				image.ZIndex = index
				image.Parent = gui
				table.insert(faceImages, { image = image, side = index - 2 })
			end
		end
	end
	local function drawFace(level)
		for _, entry in ipairs(faceImages) do
			entry.image.ImageTransparency = 1 - level * (if entry.side == 0 then 0.9 else 0.55)
			entry.image.Position = UDim2.fromScale(0.5 + entry.side * 0.05 * level * math.random(), 0.5 + randomSigned(0.02) * level)
		end
	end
	local function crownCenter()
		local host = if head and head.Parent then head else lightHost
		return host.CFrame
	end

	-- L'anello che sale: un cerchio di luce ciano, orizzontale, che gli sale lungo il corpo insieme
	-- all'onda e gira piano. Si vede sempre fin dove è arrivato il Glitch
	local ringDiameter = math.max(boxSize.X, boxSize.Z) * 1.3
	local scanRing = newPart("GlitchScanRing", Vector3.new(ringDiameter, 0.02, ringDiameter), CFrame.new(0, 10000, 0),
		GLITCH.Cyan, Enum.Material.SmoothPlastic, 1)
	scanRing.Parent = swarmFolder
	local ringImages = {}
	for _, face in ipairs({ Enum.NormalId.Top, Enum.NormalId.Bottom }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.LightInfluence = 0
		gui.Brightness = 3
		gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		gui.CanvasSize = Vector2.new(256, 256)
		gui.Parent = scanRing
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromScale(1, 1)
		image.Image = "rbxassetid://" .. kit.Ring
		image.ImageColor3 = GLITCH.Cyan
		image.ImageTransparency = 1
		image.Parent = gui
		table.insert(ringImages, image)
	end
	local ringShown = 0

	-- I fantasmi, rosso e ciano: a volte tutto il corpo, a volte solo una fetta, spostati di lato
	local ghostFolder = Instance.new("Folder")
	ghostFolder.Name = "HonchoGlitchGhosts"
	local ghosts = {}
	for index, colour in ipairs({ GLITCH.Red, GLITCH.Cyan }) do
		local ghost = { side = if index == 1 then -1 else 1, list = {}, sources = {}, heights = {}, cframes = {}, shown = false }
		for _, entry in ipairs(parts) do
			entry.part.Archivable = true
			local copy = entry.part:Clone()
			if copy then
				copy:ClearAllChildren()
				copy.Anchored = true
				copy.CanCollide = false
				copy.CanTouch = false
				copy.CanQuery = false
				copy.CastShadow = false
				copy.Material = Enum.Material.Neon
				copy.Color = colour
				copy.Transparency = 1
				copy.Parent = ghostFolder
				table.insert(ghost.list, copy)
				table.insert(ghost.sources, entry.part)
				table.insert(ghost.heights, entry.height)
			end
		end
		ghosts[index] = ghost
	end
	ghostFolder.Parent = workspace
	table.insert(cleanupTasks, function()
		ghostFolder:Destroy()
	end)

	local function showGhosts(chance)
		local camera = workspace.CurrentCamera
		local right = if camera then camera.CFrame.RightVector else Vector3.xAxis
		local visible = math.random() < chance
		-- Metà delle volte solo una fetta orizzontale del corpo
		local low, high = 0, 1
		if visible and math.random() < 0.5 then
			low = math.random() * 0.8
			high = low + 0.12 + math.random() * 0.2
		end
		for _, ghost in ipairs(ghosts) do
			if visible then
				local offset = right * ghost.side * (0.3 + math.random() * 1.6) * size + Vector3.new(0, randomSigned(0.15) * size, 0)
				local transparency = 0.35 + math.random() * 0.35
				table.clear(ghost.cframes)
				for index, copy in ipairs(ghost.list) do
					ghost.cframes[index] = ghost.sources[index].CFrame + offset
					local height = ghost.heights[index]
					copy.Transparency = if height >= low and height <= high then transparency else 1
				end
				workspace:BulkMoveTo(ghost.list, ghost.cframes, Enum.BulkMoveMode.FireCFrameChanged)
				ghost.shown = true
			elseif ghost.shown then
				for _, copy in ipairs(ghost.list) do
					copy.Transparency = 1
				end
				ghost.shown = false
			end
		end
	end

	local nextTick, nextCrawl = 0, 0
	local beatIndex, beatUntil = 1, 0
	local frozenAt, frozenUntil = nil, 0
	local snap = nil
	local blinkUntil, blinkOffset = 0, Vector3.zero
	local hitFrozen, crowned, hushed, released = false, false, false, false
	local headEntry = nil
	for _, entry in ipairs(parts) do
		if entry.part == head then headEntry = entry end
	end
	local lastStep = os.clock()

	-- UN COLPO DI GLITCH: tutto insieme, per un decimo di secondo, poi di nuovo calmo
	local function beat(power)
		local now = os.clock()
		beatUntil = now + 0.1 + 0.06 * power
		frozenUntil = beatUntil
		snap = {
			name     = jointNames[math.random(#jointNames)],
			rotation = CFrame.Angles(randomSigned(0.8), randomSigned(0.8), randomSigned(0.8)),
		}
		showGhosts(1)
		pcall(function() stage:glitchScreen(0.1, 0.25 + 0.3 * power) end)
		aura.OutlineColor = if math.random() < 0.5 then GLITCH.Cyan else GLITCH.Red
		light.Brightness = 3 + 2 * power
		Ritual.Glitch.Crawl(allSkins, 24, studs)
		drawFace(math.min((headEntry and headEntry.reached or 0) + 0.5, 1))
		-- Dal petto in su, a volte sparisce di lato per la durata del colpo
		if power > 0.5 and math.random() < 0.5 then
			blinkOffset = (flatUnit(randomUnit()) or Vector3.xAxis) * (1.2 + math.random()) * size
			blinkUntil = beatUntil
		end
		-- L'urlo si inceppa: riparte da un punto a caso
		pcall(function()
			local scream = body.scream
			scream.PlaybackSpeed = 0.45 + math.random() * 0.4
			scream.TimePosition = math.random() * math.max(scream.TimeLength - 0.3, 0.1)
			scream:Play()
		end)
		pcall(function()
			local loop = stage.glitchLoop
			loop.TimePosition = math.random() * math.max(loop.TimeLength - 0.5, 0.1)
		end)
	end

	-- Trenta volte al secondo; i cubi a ogni frame
	function fx.step()
		local now = os.clock()
		local g = now - startedAt
		local deltaTime = math.min(now - lastStep, 0.1)
		swarm:step(deltaTime, crownCenter())
		lastStep = now

		-- L'anello segue l'onda a ogni frame, e compare e sparisce sfumando
		local ringTarget = if g > 0.6 and g < GLITCH_PHASES.Head + 0.2 then 1 else 0
		ringShown += (ringTarget - ringShown) * (1 - math.exp(-6 * deltaTime))
		if ringShown > 0.01 and model.PrimaryPart then
			local root = model.PrimaryPart.Position
			local height = bottom + math.clamp(glitchFront(g), 0, 1) * boxSize.Y
			scanRing.CFrame = CFrame.new(root.X, height, root.Z) * CFrame.Angles(0, g * 1.5, 0)
			for _, image in ipairs(ringImages) do
				image.ImageTransparency = 1 - 0.85 * ringShown
				image.ImageColor3 = if now < beatUntil then GLITCH.Red else GLITCH.Cyan
			end
		elseif ringImages[1] and ringImages[1].ImageTransparency < 1 then
			for _, image in ipairs(ringImages) do
				image.ImageTransparency = 1
			end
		end

		if now < nextTick then return end
		nextTick = now + 1 / 30

		local front = glitchFront(g)
		local power = math.clamp(front, 0, 1)
		fx.power = power

		-- L'onda: ogni parte cambia quando la fascia passa alla sua altezza
		for _, entry in ipairs(parts) do
			if not entry.done then
				local reached = smoothstep((front - entry.height) / GLITCH.Band + 0.5)
				entry.reached = reached
				entry.band = reached > 0.03 and reached < 0.97
				if reached >= 1 then
					entry.part.Color = GLITCH.Body
					for _, texture in ipairs(entry.skin) do
						texture.Transparency = 0
					end
					entry.done = true
					entry.band = false
				elseif reached > 0 then
					-- Solo la fascia sfarfalla, poco: il resto sfuma liscio
					local edge = entry.band and math.random() < 0.12
					entry.part.Color = if edge
						then (if math.random() < 0.5 then GLITCH.Red else GLITCH.Cyan)
						else entry.from:Lerp(GLITCH.Body, reached)
					for _, texture in ipairs(entry.skin) do
						texture.Transparency = if edge then 0 else 1 - reached
					end
				end
			end
		end
		for _, entry in ipairs(decals) do
			entry.decal.Color3 = entry.from:Lerp(GLITCH.Cyan, power)
		end

		if now >= nextCrawl then
			nextCrawl = now + 0.15
			Ritual.Glitch.Crawl(allSkins, 6 + math.floor(18 * power), studs)
		end
		for _, emitter in ipairs(statics) do
			emitter.Rate = 2 + 10 * power
		end

		-- IL COLPO: mezzo secondo di tempo fermo, appena inarcato
		if not hitFrozen and g >= 0.12 then
			hitFrozen = true
			frozenUntil = now + 0.45
			pcall(function()
				local grade = stage.grade
				grade.Saturation = -1
				task.delay(0.45, function()
					if grade.Parent then tween(grade, 0.2, { Saturation = -0.4 }) end
				end)
			end)
		end

		-- Gli scatti, a tempo
		while beatIndex <= #GLITCH_BEATS and g >= GLITCH_BEATS[beatIndex] do
			beatIndex += 1
			beat(power)
		end
		if beatUntil > 0 and now >= beatUntil then
			beatUntil = 0
			snap = nil
			showGhosts(0)
		end
		if beatUntil == 0 and not hushed then
			aura.OutlineColor = GLITCH.Main
			aura.OutlineTransparency = 1 - 0.6 * power
			light.Brightness = 0.4 + 1.6 * power
			drawFace((headEntry and headEntry.reached or 0) * (0.7 + 0.15 * math.noise(g * 3, 0.7)))
		end

		-- IN PIEDI: i blocchetti vanno a fargli una corona sopra la testa, uno alla volta
		if not crowned and g >= GLITCH_PHASES.Head + 0.8 then
			crowned = true
			swarm:ring(1.7 * size, 1.4 * size, 0.12)
		end

		-- IL SILENZIO: luci quasi spente, niente suoni, immobile
		if not hushed and g >= GLITCH_PHASES.Rise then
			hushed = true
			stage:roomDim(0.92, 0.5)
			pcall(function() tween(stage.glitchLoop, 0.4, { Volume = 0.03 }) end)
			pcall(function() tween(stage.glitchStatic, 0.4, { Volume = 0 }) end)
			pcall(function() body.scream:Stop() end)
			pcall(function() tween(stage.grade, 0.5, { Saturation = -1, Contrast = 0.6 }) end)
			tween(light, 0.5, { Brightness = 0 })
			for _, emitter in ipairs(statics) do
				emitter.Enabled = false
			end
		end

		-- L'URLO: tutto riparte insieme
		if not released and g >= GLITCH_PHASES.Hush then
			released = true
			stage:flash(GLITCH.Main, 0.25, 0.7)
			pcall(function() stage:glitchScreen(0.4, 1) end)
			pcall(function() stage:fovPunch(14, 0.8) end)
			shake(10, 16, 0, 1.2)
			stage:roomBurst(0.3)
			task.delay(0.35, function()
				if not stage.done then stage:roomDim(0.35, 0.8) end
			end)
			pcall(function() tween(stage.glitchLoop, 0.3, { Volume = 0.6 }) end)
			pcall(function() tween(stage.glitchStatic, 0.3, { Volume = 0.3 }) end)
			pcall(function() tween(stage.grade, 0.6, { Saturation = -0.4, Contrast = 0.4 }) end)
			pcall(function()
				local scream = body.scream
				scream.PlaybackSpeed = 0.5
				scream.Volume = 3
				scream.TimePosition = 0
				scream:Play()
			end)
			light.Brightness = 5
			tween(light, 1, { Brightness = 1.5 })
			for _, emitter in ipairs(statics) do
				emitter.Enabled = true
				emitter:Emit(12)
			end
			drawFace(1)
			-- La corona si apre di colpo e si richiude; un'onda corre sul pavimento
			swarm:pulse(3, 0.25)
			pcall(function() stage:ring(2 * size, 30 * size, 0.9, false) end)
		end
	end

	-- Barcolla per la stanza solo mentre lotta in piedi (dopo le ginocchia, prima di alzarsi);
	-- mai in aria. A un colpo può sparire di lato per un attimo
	function fx.offset()
		local now = os.clock()
		local g = now - startedAt
		local envelope = smoothstep((g - 3.0) / 0.8) * (1 - smoothstep((g - 9.0) / 0.8))
		local wander = Vector3.new(math.noise(g * 0.35, 11.3), 0, math.noise(g * 0.35, 27.1)) * 7 * size * envelope
		if now < blinkUntil then
			wander += blinkOffset
		end
		return wander, CFrame.Angles(0, math.noise(g * 0.45, 5.5) * 1.6 * envelope, 0)
	end

	-- Il tempo della posa: si ferma al colpo e a ogni scatto, se no scorre liscio
	function fx.poseTime(elapsed)
		if os.clock() < frozenUntil then
			frozenAt = frozenAt or elapsed
			return frozenAt
		end
		frozenAt = nil
		return elapsed
	end

	-- A ogni scatto una parte del corpo è storta per la durata del colpo
	function fx.snapJoints(frame)
		if snap and frame[snap.name] then
			frame[snap.name] *= snap.rotation
		end
	end

	--[[ Finito: resta un Glitch. Pelle e colore del Glitch, la faccia rotta, la corona che gli gira
	     sopra la testa a scatti, i quadrati che si accendono. Ogni due-quattro secondi e mezzo, anche
	     mentre corre, un colpo di glitch: scatta di lato, una fetta scivola via, la faccia si
	     accende. Tra un colpo e l'altro è calmo, così si vede bene cos'è diventato. ]]
	function fx.settle()
		for _, entry in ipairs(parts) do
			if entry.part.Parent then
				entry.part.Color = GLITCH.Body
				for _, texture in ipairs(entry.skin) do
					texture.Transparency = 0
				end
			end
		end
		for _, entry in ipairs(decals) do
			entry.decal.Color3 = GLITCH.Cyan
		end
		aura.OutlineColor = GLITCH.Main
		aura.OutlineTransparency = 0.45
		for _, emitter in ipairs(statics) do
			emitter.Enabled = true
			emitter.Rate = 5
		end
		showGhosts(0)
		if not crowned then
			crowned = true
			swarm:ring(1.7 * size, 1.4 * size, 0.05)
		end

		local nextIdle, nextBeat, idleBeatUntil = 0, os.clock() + 2, 0
		local lastFrame = os.clock()
		table.insert(connections, RunService.Heartbeat:Connect(function()
			local now = os.clock()
			if model.Parent then
				swarm:step(math.min(now - lastFrame, 0.1), crownCenter())
			end
			lastFrame = now
			if now < nextIdle or not model.Parent then return end
			nextIdle = now + 0.1

			Ritual.Glitch.Crawl(allSkins, 4, studs)
			light.Brightness = 1.3 + 0.4 * math.noise(now, 0.2)

			if now >= nextBeat then
				nextBeat = now + 2.5 + math.random() * 2
				idleBeatUntil = now + 0.12
				aura.OutlineColor = if math.random() < 0.5 then GLITCH.Cyan else GLITCH.Red
				showGhosts(1)
				drawFace(1)
				if not state.paused then
					state.jitter = CFrame.new(randomSigned(1.2) * size, 0, randomSigned(0.6) * size)
						* CFrame.Angles(0, randomSigned(0.5), 0)
				end
			elseif idleBeatUntil > 0 and now >= idleBeatUntil then
				idleBeatUntil = 0
				aura.OutlineColor = GLITCH.Main
				showGhosts(0)
				state.jitter = nil
			else
				drawFace(0.65 + 0.1 * math.noise(now * 3, 0.9))
			end
		end))
	end

	return fx
end

-- Il corpo di Honcho, nella forma che CrucifixRitual si aspetta (vedi Ritual.Run). mode è
-- "Banish", "Fail" o "Glitch"; T è il copione V2 del modulo; Ritual il modulo
local function honchoBody(mode, T, Ritual)
	local fail = mode ~= "Banish"
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
	local streamStart = T.Scream
	local streamEnd = if fail then T.Fail.Break else T.Slam
	local streamLeft = streamBudget
	local streamRate = math.max(streamBudget - joltBurst * 4, 0) / (streamEnd - streamStart)
	local streamCarry = 0
	local lastStream = 0
	local frame = {}
	local glitchFx = nil

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
		-- Il fulmine del glitch lo prende al petto; il Glitch vero che gli appare sopra è alto come lui
		ChestHeight = (state.pivotHeight + state.headHeight * 0.55) / SETTINGS.Size,
		Height      = state.pivotHeight + state.headHeight + 0.8 * SETTINGS.Size,
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
		local wander, turn = Vector3.zero, CFrame.identity
		if glitchFx then
			wander, turn = glitchFx.offset()
		end
		state.position = basePosition + Vector3.new(0, yOffset, 0) + wander
		render(offset * turn)
	end

	function honcho.Pose(elapsed)
		local sampleAt = if glitchFx then glitchFx.poseTime(elapsed) else elapsed
		sampleBanish(poses, jointNames, lags, sampleAt, frame, mode)
		if glitchFx then
			glitchFx.snapJoints(frame)
		end
		applyPose(joints, frame)
	end

	-- Il flusso di fogli esce a lotti ogni decimo di secondo, non un pezzetto per frame: il
	-- conto del box del modello si fa dieci volte al secondo invece che a ogni frame
	function honcho.Step(_, elapsed, deltaTime)
		if glitchFx then
			glitchFx.step()
		end
		if elapsed < streamStart or elapsed > streamEnd or streamLeft <= 0 then return end
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
			body.scream.PlaybackSpeed = if kind == "glitch" then 0.55 elseif kind == "roar" then 0.7 else 0.85
			body.scream.Volume = if kind == "hit" then 2 else 3
			body.scream.TimePosition = 0
			body.scream:Play()
		end)
	end

	-- Il glitch lo colpisce: da qui per sedici secondi si trasforma
	if mode == "Glitch" then
		function honcho.Glitch(stage)
			glitchFx = glitchBody(model, stage, jointNames, Ritual)
		end
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

		-- Dopo il glitch non torna com'era: le sue luci e le sue particelle restano viola e ciano
		if glitchFx then
			for instance in pairs(saved) do
				if instance.Parent then
					if instance:IsA("PointLight") then
						instance.Color = GLITCH.Main
					elseif instance:IsA("ParticleEmitter") then
						instance.Color = ColorSequence.new(GLITCH.Main, GLITCH.Alt)
					end
				end
			end
			pcall(function()
				body.scream.PlaybackSpeed = 0.8
			end)
			glitchFx.settle()
			glitchFx = nil
		end
	end

	return honcho
end

--[[ Il rituale, con il copione V2. Riuscito: Honcho finisce nel buco. Fallito: si libera, ricade e
     dopo FAIL_GRACE secondi torna a cacciarti, e il crocifisso non ce l'hai più. Glitch: come il
     fallito, ma prima si trasforma, e torna a cacciarti glitchato e più veloce. ]]
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

	local T = Ritual.Timelines and Ritual.Timelines[TIMELINE]
	if not (T and Ritual.Glitch and Ritual.GlitchSwarm) then
		-- Un CrucifixRitual rimasto in memoria da prima di V2: le pose non ci starebbero sopra
		problem("CrucifixRitual è una versione vecchia senza il copione %s: riesegui lo script", TIMELINE)
		state.noRitual = true
		state.paused = false
		state.watching = true
		return
	end

	local _, fail, glitch = Ritual.Outcome(tool, false)
	local mode = if glitch then "Glitch" elseif fail then "Fail" else "Banish"
	local result = Ritual.Run({
		Model    = state.model,
		Tool     = tool,
		Timeline = TIMELINE,
		Body     = honchoBody(mode, T, Ritual),
		Alive    = function()
			return not state.finished
		end,
	})

	if result == "Glitched" then
		state.glitched = true
		state.speed *= GLITCH.Speed
		body.walkRate = math.clamp(state.speed / (MORPH_WALK_SPEED * SETTINGS.Size), 0.5, 3)
		body.stepRate = math.pi * state.speed / (7 * SETTINGS.Size)
		log("glitchato: riparte più veloce")
	end

	if result == "Banished" then
		finish("esorcizzato")
	elseif result == "Failed" or result == "Glitched" then
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
		local progress = (os.clock() - startedAt) / SINK_TIME
		if progress >= 1 then break end
		state.position = start - Vector3.new(0, 20 * progress ^ 3, 0)
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

_G.HonchoV2Cleanup = dismiss

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
