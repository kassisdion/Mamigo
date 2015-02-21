local addon, private = ...

local boxWidth = 270
local frameHeight = 20
local sbireManagerButton = nil
local updateEnable = 0
local DEBUG = true
local fontSize = 14

local statNames = {
	"Air",
	"Artifact",
	"Assassination",
	"Death",
	"Dimension",
	"Diplomacy",
	"Earth",
	"Exploration",
	"Fire",
	"Harvest",
	"Hunting",
	"Life",
	"Water"
}

--#################################################################################################################################
			---UTILS---
--#################################################################################################################################
---------UTILS---------------------------------------------------------------------------------------------------------------------
local function iif(condition, trueExpression, falseExpression)
	if condition then
		return trueExpression
	else
		return falseExpression
	end
end

local function ifnull(expression1, expression2)
	if expression1 == nil then
		return expression2
	else
		return expression1
	end
end

local function startsWith(s, start)
	return string.sub(s, 1, string.len(start)) == start
end

---------LOG-----------------------------------------------------------------------------------------------------------------------
local function displayText(console, suppressPrefix, text, html)
	Command.Console.Display(console, suppressPrefix, text, html)
end

local function printText(text)
	local colorTag = "<font color=\"#00FF00\">"
	displayText("general", false, colorTag .. text, true)
end

local function printDebug(msg)
	local colorTag = "<font color=\"#FF00FF\">"
	if DEBUG then displayText("general", false, colorTag .. msg, true) end
end

---------TEXTURE-------------------------------------------------------------------------------------------------------------------
local function createTexture(parent, x, y, w, h, texture, layout)
	local frame = UI.CreateFrame("Texture", "", parent)
	frame:SetPoint(ifnull(layout, "TOPLEFT"), parent, ifnull(layout, "TOPLEFT"), x, y)
	frame:SetWidth(w)
	frame:SetHeight(h)
	if texture then	frame:SetTexture(addon.identifier, texture) end
	return frame
end

---------DRAG WINDO----------------------------------------------------------------------------------------------------------------
local function dragDown(dragState, frame, event, ...)
	local mouse = Inspect.Mouse()
	dragState.dx = dragState.window:GetLeft() - mouse.x
	dragState.dy = dragState.window:GetTop() - mouse.y
	dragState.dragging = true
end

local function dragUp(dragState, frame, event, ...)
	dragState.dragging = false
end

local function dragMove(dragState, frame, event, x, y)
	if SbireManagerGlobal.settings.locked then
		return
	end
	if dragState.dragging then
		dragState.variable.x = x + dragState.dx
		dragState.variable.y = y + dragState.dy
		dragState.window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", dragState.variable.x, dragState.variable.y)
	end
end

local function dragAttach(window, variable)
	local dragState = { window = window, variable = variable, dragging = false }
	window:EventAttach(Event.UI.Input.Mouse.Left.Down, function(...) dragDown(dragState, ...) end, "dragDown")
	window:EventAttach(Event.UI.Input.Mouse.Left.Up, function(...) dragUp(dragState, ...) end, "dragUp")
	window:EventAttach(Event.UI.Input.Mouse.Left.Upoutside, function(...) dragUp(dragState, ...) end, "dragUpoutside")
	window:EventAttach(Event.UI.Input.Mouse.Cursor.Move, function(...) dragMove(dragState, ...) end, "dragMove")
	window:EventAttach(Event.UI.Input.Mouse.Cursor.Move, function(...) dragMove(dragState, ...) end, "dragMove")
end

---------MENU----------------------------------------------------------------------------------------------------------------------
local function createMenu(parent, cb)
	local window = UI.CreateFrame("Frame", "", parent)
	window:SetWidth(boxWidth)
	createTexture(window, 0, 0, boxWidth, 12, "img/tooltip200-top.png", "TOPLEFT"):SetLayer(-1)
	createTexture(window, 0, 0, boxWidth, 26, "img/tooltip200-bottom.png", "BOTTOMLEFT"):SetLayer(-1)
	local body = createTexture(window, 0, 12, boxWidth, 0, "img/tooltip200-middle.png", "TOPLEFT")
	local y = 10
	y = cb(body, y)
	body:SetHeight(y + 10)
	window:SetHeight(y + 48)

	-- stop clicks on elements behind the menu
	window:EventAttach(Event.UI.Input.Mouse.Left.Click, function (...)
	end, "menuLeftClick")

	return window
end

local function createMenuFrame(parent, y)
	local frame = UI.CreateFrame("Frame", "", parent)
	frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
	frame:SetWidth(boxWidth)
	frame:SetHeight(frameHeight)
	return frame
end

local function menuToggle(align, window)
	if align:GetTop() > UIParent:GetHeight() / 2 then
		window:ClearPoint("TOPCENTER")
		window:SetPoint("BOTTOMCENTER", align, "TOPCENTER", -1 * window:GetWidth(), frameHeight)
	else
		window:ClearPoint("BOTTOMCENTER")
		window:SetPoint("TOPCENTER", align, "BOTTOMCENTER", (-1 * window:GetWidth()) / 2, 0)
	end
	window:SetVisible(not window:GetVisible())
end

local function createText(parent, x, y, text)
	local frame = UI.CreateFrame("Text", "", parent)
	frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	frame:SetFontSize(fontSize)
	frame:SetText(text)
	return frame
end

local function createTextWithoutFrame(parent, y, text)
	local frame = createMenuFrame(parent, y)
	createText(frame, 38, 0, text)
	return y + frameHeight
end
	
local function createSubmenu(parent, y, text, cb)
	local frame = createMenuFrame(parent, y)
	createText(frame, 38, 0, text)

	local child = createMenu(frame, cb)
	child:SetVisible(false)
	child:SetPoint("TOPLEFT", frame, "TOPRIGHT", -10, -frameHeight)
	frame:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (...)
		if parent.submenu ~= nil then
			parent.submenu:SetVisible(false)
		end
		parent.submenu = child
		child:SetVisible(true)
	end, "submenuCursorIn")
	return y + frameHeight
end

local function hideSubmenu(menu, menuitem)
	menuitem:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (...)
		if menu.submenu ~= nil then
			menu.submenu:SetVisible(false)
			menu.submenu = nil
		end
	end, "hideSubmenu")
end

local function showSubmenu(menu, menuitem, submenu)
	menuitem:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (...)
		if menu.submenu ~= nil then
			menu.submenu:SetVisible(false)
		end
		menu.submenu = submenu
		submenu:SetVisible(true)
	end, "showSubmenu")
end

local function createCheckbox(parent, x, y, text, value)
	local frame = {}

	frame.checkbox = UI.CreateFrame("RiftCheckbox", "", parent)
	frame.checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y + 2)
	frame.checkbox:SetEnabled(true)
	frame.checkbox:SetChecked(ifnull(value, false))

	frame.text = createText(parent, x + 16, y, text)
	frame.text:EventAttach(Event.UI.Input.Mouse.Left.Click, function (...)
		frame.checkbox:SetChecked(not frame.checkbox:GetChecked())
	end, "checkboxTextClick")

	return frame
end

local function createRadioButton(parent, x, y, text, value)
	local frame = {}

	frame.checkbox = UI.CreateFrame("RiftCheckbox", "", parent)
	frame.checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y + 2)
	frame.checkbox:SetEnabled(true)
	frame.checkbox:SetChecked(ifnull(value, false))

	frame.text = createText(parent, x + 16, y, text)
	frame.text:EventAttach(Event.UI.Input.Mouse.Left.Click, function (...)
		if not frame.checkbox:GetChecked() then
			frame.checkbox:SetChecked(true)
		end
	end, "radioButtonTextClick")

	return frame
end

local function createButton(parent, align, x, y, w, h, text)
	local frame = UI.CreateFrame("RiftButton", "", parent)
	frame:SetPoint("TOPLEFT", align, "TOPLEFT", x, y)
	frame:SetWidth(w)
	frame:SetHeight(h)
	frame:SetText(text)
	return frame
end

local function createMenuCheckbox(parent, y, text, settings, key)
	local frame = createMenuFrame(parent, y)
	local control = createCheckbox(frame, 22, 0, text, settings[key])
	control.checkbox:EventAttach(Event.UI.Checkbox.Change, function (...)
		settings[key] = control.checkbox:GetChecked()
	end, "menuCheckboxChange")
	hideSubmenu(parent, frame)
	hideSubmenu(parent, control.text)
	return y + frameHeight
end

local function createMenuRadioButton(parent, y, text, settings, key, value, group)
	local frame = createMenuFrame(parent, y)
	local control = createRadioButton(frame, 22, 0, text, settings[key] == value)
	control.checkbox:EventAttach(Event.UI.Checkbox.Change, function (...)
		if control.checkbox:GetChecked() then
			settings[key] = value
			for k, v in pairs(group) do
				if k ~= value then
					v.checkbox:SetChecked(false)
				end
			end
		end
	end, "menuRadioButtonChange")
	hideSubmenu(parent, frame)
	group[value] = control
	return y + frameHeight
end

local function createMenuSeparator(parent, y)
	local control = createTexture(parent, 5, y + 10, 270, 5, "img/tooltip-separator.png", "TOPLEFT")
	hideSubmenu(parent, control)
	return y + frameHeight
end

local function createMenuHeader(parent, y, text)
	local frame = createMenuFrame(parent, y)
	createText(frame, frameHeight, 0, text)
	hideSubmenu(parent, frame)
	return y + frameHeight
end

--#################################################################################################################################
			---INIT
--#################################################################################################################################		

---------INIT MENU------------------------------------------------------------------------------------------------------------------
local function menuInit(parent, settings)
	local window = createMenu(parent, function (body, y)
	
		--adventure settings
		y = createSubmenu(body, y, "Temps d'aventure : ", function (body, y)
			local adventureTime = {}
			y = createMenuRadioButton(body, y, "-1mn", settings, "adventureTime", "experience", adventureTime)
			y = createMenuRadioButton(body, y, "-5mn/15mn", settings, "adventureTime", "short", adventureTime)
			y = createMenuRadioButton(body, y, "-8 heures", settings, "adventureTime", "long", adventureTime)
			y = createMenuRadioButton(body, y, "-10 heures", settings, "adventureTime", "aventurine", adventureTime)
			y = createMenuSeparator(body, y)
			y = createMenuCheckbox(body, y, "Aventures d'events", settings, "adventureEvent")
			y = createMenuSeparator(body, y)
			y = createMenuCheckbox(body, y, "Accelerer (en aventurine)", settings, "hurry")
			return y
		end)
		
		y = createSubmenu(body, y, "Type d'aventure :", function (body, y)
			y = createMenuCheckbox(body, y, "-Air", settings.adventureTypeWanted, statNames[1])
			y = createMenuCheckbox(body, y, "-Artefact", settings.adventureTypeWanted, statNames[2])
			y = createMenuCheckbox(body, y, "-Assassinat", settings.adventureTypeWanted, statNames[3])
			y = createMenuCheckbox(body, y, "-Death", settings.adventureTypeWanted, statNames[4])
			y = createMenuCheckbox(body, y, "-Dimension", settings.adventureTypeWanted, statNames[5])
			y = createMenuCheckbox(body, y, "-Diplomacy", settings.adventureTypeWanted, statNames[6])
			y = createMenuCheckbox(body, y, "-Terre", settings.adventureTypeWanted, statNames[7])
			y = createMenuCheckbox(body, y, "-Exploration", settings.adventureTypeWanted, statNames[8])
			y = createMenuCheckbox(body, y, "-Feu", settings.adventureTypeWanted, statNames[9])
			y = createMenuCheckbox(body, y, "-Recolte", settings.adventureTypeWanted, statNames[10])
			y = createMenuCheckbox(body, y, "-Chasse", settings.adventureTypeWanted, statNames[11])
			y = createMenuCheckbox(body, y, "-Vue", settings.adventureTypeWanted, statNames[12])
			y = createMenuCheckbox(body, y, "-Eau", settings.adventureTypeWanted, statNames[13])
			y = createMenuSeparator(body, y)
			y = createMenuCheckbox(body, y, "Remanier", settings, "shuffle")
			return y
		end)
		
		--Minion settings
		y = createMenuSeparator(body, y)
		
		y = createSubmenu(body, y, "Prioriser les sbires par :", function (body, y)
			local prio = {}
			y = createMenuRadioButton(body, y, "-Energie", settings, "prio", "energie", prio)
			y = createMenuRadioButton(body, y, "-Affinite", settings, "prio", "stats", prio)
			y = createMenuRadioButton(body, y, "-Level (asc)", settings, "prio", "level_asc", prio)
			y = createMenuRadioButton(body, y, "-Level (desc)", settings, "prio", "level_desc", prio)
			return y
		end)
	
		y = createSubmenu(body, y, "Energie minimal :", function (body, y)
			local energieMin = {}
			y = createMenuRadioButton(body, y, "-Aucune", settings, "energieMin", 0, energieMin)
			y = createMenuRadioButton(body, y, "-Pour faire des 8 heures", settings, "energieMin", 7, energieMin)
			y = createMenuRadioButton(body, y, "-Pour faire des 10 heures", settings, "energieMin", 10, energieMin)
			y = createMenuSeparator(body, y)
			y = createMenuCheckbox(body, y, "-Seulement pour les lvl 25", settings, "energieMinFilter")
			return y
		end)
		
		y = createMenuCheckbox(body, y, "Envoyer des lvl 1", settings, "min")

		--global settings
		y = createMenuSeparator(body, y)
		
		y = createMenuCheckbox(body, y, "Verouiller la fenetre", settings, "locked")
		y = createMenuCheckbox(body, y, "Couleur \"flashy\"", settings, "highLight")
		
		return y
	end)
	return window
end

---------INIT BUTTON---------------------------------------------------------------------------------------------------------------
local function createButton(context)
	local frame = UI.CreateFrame("Frame", "", context)
	frame:SetWidth(32)
	frame:SetHeight(32)

	local texture1 = createTexture(frame, 0, 0, 64, 64, nil, "CENTER")
	local texture2 = createTexture(frame, 0, 0, 24, 24, nil, "CENTER")
	texture2:SetLayer(1)
	local texture3 = createTexture(frame, -4, -4, 64, 64, nil, "TOPLEFT")
	texture3:SetTexture("Rift", "death_icon_(glow).png.dds")
	texture3:SetLayer(3)

	frame:EventAttach(Event.UI.Input.Mouse.Left.Down, function (...)
		if frame.state then
			texture1:SetTexture("Rift", "btn_zoomout_(click).png.dds")
			texture2:SetTexture("Rift", "icon_menu_minion_(select).png.dds")
			texture2:SetPoint("CENTER", frame, "CENTER", 0, 2)
		end
	end, "buttonLeftDown")

	frame:EventAttach(Event.UI.Input.Mouse.Left.Up, function (...)
		if frame.state then
			texture1:SetTexture("Rift", "btn_zoomout_(over).png.dds")
			texture2:SetTexture("Rift", "icon_menu_minion_(select).png.dds")
			texture2:SetPoint("CENTER", frame, "CENTER", 0, 0)
		end
	end, "buttonLeftUp")

	frame:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (...)
		if frame.state then
			texture1:SetTexture("Rift", "btn_zoomout_(over).png.dds")
			texture2:SetTexture("Rift", "icon_menu_minion_(select).png.dds")
			texture2:SetPoint("CENTER", frame, "CENTER", 0, 0)
		end
	end, "buttonCursorIn")


	frame:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function (...)
		if frame.state then
			texture1:SetTexture("Rift", "btn_zoomout_(normal).png.dds")
			texture2:SetTexture("Rift", "icon_menu_minion.png.dds")
			texture2:SetPoint("CENTER", frame, "CENTER", 0, 0)
		end
	end, "buttonCursorOut")

	function frame:SetEnabled(enabled)
		if frame.state ~= enabled then
			frame.state = enabled
			if frame.state then
				texture1:SetTexture("Rift", "btn_zoomout_(normal).png.dds")
				texture2:SetTexture("Rift", "icon_menu_minion.png.dds")
				texture2:SetPoint("CENTER", frame, "CENTER", 0, 0)
			else
				texture1:SetTexture("Rift", "btn_zoomout_(disable).png.dds")
				texture2:SetTexture("Rift", "icon_menu_minion_(disabled).png.dds")
				texture2:SetPoint("CENTER", frame, "CENTER", 0, 0)
			end
			texture3:SetVisible(frame.state)
		end
	end

	function frame:GetEnabled(enabled)
		return frame.state
	end

	Command.Event.Attach(Event.System.Update.Begin, function ()
		if SbireManagerGlobal.settings.flash then
			texture3:SetAlpha(math.abs(Inspect.Time.Real() * frameHeight % frameHeight - 10) / 10)
		else
			texture3:SetAlpha(0)
		end
	end, "buttonAnimate")

	frame:SetEnabled(false)
	return frame
end

---------INIT SAVED VARIABLE-------------------------------------------------------------------------------------------------------
local function settingsInit()
	if SbireManagerGlobal == nil then SbireManagerGlobal = {} end
	if SbireManagerGlobal.settings == nil then SbireManagerGlobal.settings = {} end
	
	--temps d'aventure
	--experience / short / long / aventurine (1mn / 5mn / 8h / 10h )
	if SbireManagerGlobal.settings.adventureTime == nil then SbireManagerGlobal.settings.adventureTime = "experience" end
	if SbireManagerGlobal.settings.adventureEvent == nil then SbireManagerGlobal.settings.adventureEvent = true end
	if SbireManagerGlobal.settings.hurry == nil then SbireManagerGlobal.settings.hurry = false end
	
	--type d'aventure
	if SbireManagerGlobal.settings.adventureTypeWanted == nil then
		SbireManagerGlobal.settings.adventureTypeWanted = {}
		SbireManagerGlobal.settings.adventureTypeWanted["Air"] = true
		SbireManagerGlobal.settings.adventureTypeWanted["Artifact"] = true
		SbireManagerGlobal.settings.adventureTypeWanted["Assassination"] = true
		SbireManagerGlobal.settings.adventureTypeWanted["Death"] = true
		SbireManagerGlobal.settings.adventureTypeWanted["Dimension"] = true
		SbireManagerGlobal.settings.adventureTypeWanted["Diplomacy"] = true
		SbireManagerGlobal.settings.adventureTypeWanted["Earth"] = true
		SbireManagerGlobal.settings.adventureTypeWanted["Exploration"] = true
		SbireManagerGlobal.settings.adventureTypeWanted["Fire"] = true
		SbireManagerGlobal.settings.adventureTypeWanted["Harvest"] = true
		SbireManagerGlobal.settings.adventureTypeWanted["Hunting"] = true
		SbireManagerGlobal.settings.adventureTypeWanted["Life"] = true
		SbireManagerGlobal.settings.adventureTypeWanted["Water"] = true
	end
	if SbireManagerGlobal.settings.shuffle == nil then SbireManagerGlobal.settings.shuffle = false end
	
	--priorisation
	--energie / stats / lvl_asc / lvl_desc
	if SbireManagerGlobal.settings.prio == nil then SbireManagerGlobal.settings.prio = "stats" end
	
	--energie minimal
	--0 / 7 / 10
	if SbireManagerGlobal.settings.energieMin == nil then SbireManagerGlobal.settings.energieMin = 0 end
	if SbireManagerGlobal.settings.energieMinFilter == nil then SbireManagerGlobal.settings.energieMinFilter = false end
	
	--envoyer des lvl
	if SbireManagerGlobal.settings.sendMin == nil then SbireManagerGlobal.settings.sendMin = false end
	
	--parametre
	if SbireManagerGlobal.settings.highLight == nil then SbireManagerGlobal.settings.hightLight = false end
	if SbireManagerGlobal.settings.locked == nil then SbireManagerGlobal.settings.locked = false end
	
	
	if SbireManagerSettings == nil then SbireManagerSettings = {} end
	if SbireManagerSettings.window == nil then
		SbireManagerSettings.window = {
			x = math.floor(UIParent:GetWidth() / 4),
			y = math.floor(UIParent:GetHeight() / 4)
		}
	end
end

--#################################################################################################################################
			---CORE----
--#################################################################################################################################

local function minionMatch(adventure, minion)
	local prio = SbireManagerGlobal.settings.prio
	local sendMin = SbireManagerGlobal.settings.sendMin

	--verifier si on veux xp les sbires lvl 1
	if not sendMin and minion.level == 1 then
		return 0
	end
	
	--ne pas xp les sbire les 25
	if (SbireManagerGlobal.settings.adventureTime == "experience") and (not minion.experienceNeeded) then
		return 0
	end
		
	--verifier qu'on a assé d'energie
	local energiePostAdventure = minion.stamina - adventure.costStamina
	if ((SbireManagerGlobal.settings.energieMinFilter) == false or (minion.level == 25)) then
		energiePostAdventure = energiePostAdventure - SbireManagerGlobal.settings.energieMin
	end
	if (energiePostAdventure < 0) then
		return 0
	end

	local minionWeight = 0
	for i, name in ipairs(statNames) do
		if adventure["stat" .. name] and minion["stat" .. name] ~= nil then
			if prio == "energie" then
				minionWeight = minion.stamina
			elseif prio == "stats" then
				minionWeight = minionWeight + minion["stat" .. name]
			elseif prio == "level_desc" then
				minionWeight = minion.level
			elseif prio == "level_asc" then
				minionWeight = 1000 - minion.level
			end
		end
	end

	--common = blanc / uncommon = vert / rare = bleu / epic = violet
	if SbireManagerGlobal.settings.adventureTime == "experience" then
		if minionWeight == 0 then
			minionWeight = 1
		elseif minion.rarity == "common" then
			minionWeight = minionWeight * 2 * 2
		elseif minion.rarity == "uncommon" then
			minionWeight = minionWeight * 1
		elseif minion.rarity == "rare" then
			minionWeight = minionWeight * 3
		elseif minion.rarity == "epic" then
			minionWeight = minionWeight * 50
		end
	end
	
	return minionWeight
end

local function sbireManagerEnable(enable)
	sbireManagerButton:SetEnabled(enable or SbireManagerGlobal.settings.hurry)
	updateEnable = Inspect.Time.Real()
end

local function minionReady()
	local aids = Inspect.Minion.Adventure.List()
	if aids == nil then
		-- This can happen when logging in
		sbireManagerEnable(false)
		return
	end
	local adventures = Inspect.Minion.Adventure.Detail(aids)
	local slot = Inspect.Minion.Slot()
	for aid, adventure in pairs(adventures) do
		if adventure.mode == "finished" then
			if not sbireManagerButton:GetEnabled() then
				printText("Aventure terminé")
				sbireManagerEnable(true)
			end
			return
		elseif adventure.mode == "working" then
			slot = slot - 1
		end
	end
	if slot > 0 then
		sbireManagerEnable(true)
		return
	end
	sbireManagerEnable(false)
end

local function minionReadyTimer()
	if (Inspect.Time.Real() >= updateEnable + 1) then
		minionReady()
	end
end

local function minionSend(aid, adventure, busy)
	local mids = Inspect.Minion.Minion.List()
	local minions = Inspect.Minion.Minion.Detail(mids)
	local best = 0
	local bestid = false
	local bestminion = nil
	for mid, minion in pairs(minions) do
		if busy[mid] == nil then
			local stat = minionMatch(adventure, minion)
			if bestminion == nil or best < stat or best == stat and bestminion.stamina < minion.stamina then
				best = stat
				bestid = mid
				bestminion = minion
			end
		end
	end
	
	local test
	
	if bestid ~= false and best > 0 then
		if adventure.costAventurine > 0 then
			test = Command.Minion.Send(bestid, aid, "aventurine")
		else
			test = Command.Minion.Send(bestid, aid, "none")
		end
		printText("Envois de \"" .. bestminion.name .. "\"".. " pour " .. tonumber(adventure.duration / 60) .. "mn")
	else
		printText("Aucun minion compatible avec l'aventure\"" .. adventure.name .. "\" trouvé")
	end
end

local adventureMatch = {
	experience = function (a) return a.reward == "experience" and a.costAventurine == 0 end,
	short = function (a) return (a.duration == 5*60 or a.duration == 15*60) and a.reward ~= "experience" and a.costAventurine == 0 end,
	long = function (a) return a.duration == 8*60*60 and a.reward ~= "experience" and a.costAventurine == 0 end,
	aventurine = function (a) return a.duration == 10*60*60 and a.reward ~= "experience" and a.costAventurine > 0 end
}
local adventureMatchAll = {
	experience = function (a) return a.reward == "experience" and a.costAventurine == 0 end,
	short = function (a) return a.duration < 2*60*60 and a.reward ~= "experience" and a.costAventurine == 0 end,
	long = function (a) return a.duration >= 2*60*60 and a.reward ~= "experience" and a.costAventurine == 0 end,
	aventurine = function (a) return a.duration >= 2*60*60 and a.reward ~= "experience" and a.costAventurine > 0 end
}

local function matchStats(adventure)
	for i, name in ipairs(statNames) do
		tmp = adventure["stat" .. name] and SbireManagerGlobal.settings.adventureTypeWanted[name]
		if tmp then return true end
	end
	return false
end

local function shuffleAdventure(aid, adventure)
	if SbireManagerGlobal.settings.shuffle then
		printText("Remaniement de l'aventure \"" .. adventure.name .. "\"")
		Command.Minion.Shuffle(aid, "aventurine")
	end
	printText("Aucune aventure ne correspond à vos criteres")
end

local function minionGo()
	if not sbireManagerButton:GetEnabled() then
		return
	end
	
	local aids = Inspect.Minion.Adventure.List()
	local adventures = Inspect.Minion.Adventure.Detail(aids)
	local slot = Inspect.Minion.Slot()
	local busy = {}
	for aid, adventure in pairs(adventures) do
		if adventure.mode == "finished" then
			printText("Récupération du sbire...")
			Command.Minion.Claim(aid)
			return
		elseif adventure.mode == "working" and adventure.completion > os.time() then
			if SbireManagerGlobal.settings.hurry then
				Command.Minion.Hurry(aid, "aventurine")
				return
			end
			slot = slot - 1
			busy[adventure.minion] = adventure
		end
	end

	if slot <= 0 then
		printText("Aucun slot de disponible")
		return
	end

	--on cherche une aventure
	local match
	if SbireManagerGlobal.settings.adventureEvent then
		matchTime = adventureMatchAll[SbireManagerGlobal.settings.adventureTime]
	else
		matchTime = adventureMatch[SbireManagerGlobal.settings.adventureTime]
	end
	
	local _matchStats
	for aid, adventure in pairs(adventures) do
		_matchStats = (SbireManagerGlobal.settings.adventureTime == "experience") or matchStats(adventure)
		
		if (adventure.mode == "available" and matchTime(adventure)) then
			if (_matchStats) then
				minionSend(aid, adventure, busy)
				return
			end
			--l'aventure ne corresponds pas en carac
			shuffleAdventure(aid, adventure)
			return
		end
	end
end

--#################################################################################################################################
			---MAIN----------------------------------------------------------------------------------------------------------------
--#################################################################################################################################

local function init()
	settingsInit()
	local context = UI.CreateContext(addon.identifier)

	sbireManagerButton = createButton(context)
	sbireManagerButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", SbireManagerSettings.window.x, SbireManagerSettings.window.y)
	dragAttach(sbireManagerButton, SbireManagerSettings.window)
	sbireManagerButton:EventAttach(Event.UI.Input.Mouse.Left.Click, minionGo, "minionGo")

	local sbireManagerMenu = menuInit(context, SbireManagerGlobal.settings)
	sbireManagerMenu:SetVisible(false)
	sbireManagerButton:EventAttach(Event.UI.Input.Mouse.Right.Click, function ()
		menuToggle(sbireManagerButton, sbireManagerMenu)
	end, "menuRightClick");

	Command.Event.Attach(Event.System.Update.Begin, minionReadyTimer, "minionReadyTimer")
	Command.Event.Attach(Event.Minion.Adventure.Change, minionReady, "minionReady")
	Command.Event.Attach(Event.Queue.Status, minionReady, "minionReady")
end

local function main(handle, addonIdentifier)
	if addonIdentifier ~= addon.identifier then
		return
	end
	
	init()
	printText("Initialisation terminé")
end

Command.Event.Attach(Event.Addon.Load.End, main, "main")

