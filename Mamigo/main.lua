local addon, private = ...
Mamigo = private

local boxWidth = 270
local mamigoButton = nil
local updateEnable = 0

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
	if MamigoGlobal.settings.locked then
		return
	end
	if dragState.dragging then
		dragState.variable.x = x + dragState.dx
		dragState.variable.y = y + dragState.dy
		if not mamigoButton:GetEnabled() then
			dragState.window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", dragState.variable.x, dragState.variable.y)
		end		
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
	frame:SetHeight(20)
	return frame
end

local function menuToggle(align, window)
	if align:GetTop() > UIParent:GetHeight() / 2 then
		window:ClearPoint("TOPCENTER")
		window:SetPoint("BOTTOMCENTER", align, "TOPCENTER", -1 * window:GetWidth(), 20)
	else
		window:ClearPoint("BOTTOMCENTER")
		window:SetPoint("TOPCENTER", align, "BOTTOMCENTER", (-1 * window:GetWidth()) / 2, 0)
	end
	window:SetVisible(not window:GetVisible())
end

local function createText(parent, x, y, text)
	local frame = UI.CreateFrame("Text", "", parent)
	frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	frame:SetFontSize(14)
	frame:SetText(text)
	return frame
end

local function createSubmenu(parent, y, text, cb)
	local frame = createMenuFrame(parent, y)
	createText(frame, 38, 0, text)

	local child = createMenu(frame, cb)
	child:SetVisible(false)
	child:SetPoint("TOPLEFT", frame, "TOPRIGHT", -10, -20)
	frame:EventAttach(Event.UI.Input.Mouse.Cursor.In, function (...)
		if parent.submenu ~= nil then
			parent.submenu:SetVisible(false)
		end
		parent.submenu = child
		child:SetVisible(true)
	end, "submenuCursorIn")
	return y + 20
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
	return y + 20
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
	return y + 20
end

local function createMenuSeparator(parent, y)
	local control = createTexture(parent, 5, y + 10, 190, 5, "img/tooltip-separator.png", "TOPLEFT")
	hideSubmenu(parent, control)
	return y + 20
end

local function createMenuHeader(parent, y, text)
	local frame = createMenuFrame(parent, y)
	createText(frame, 20, 0, text)
	hideSubmenu(parent, frame)
	return y + 20
end

--#################################################################################################################################
			---INIT
--#################################################################################################################################		

---------INIT MENU------------------------------------------------------------------------------------------------------------------
local function menuInit(parent, settings)
	local window = createMenu(parent, function (body, y)
		y = createSubmenu(body, y, "Temps d'aventure : ", function (body, y)
			local adventure = {}
			y = createMenuRadioButton(body, y, "-1mn", settings, "adventure", "experience", adventure)
			y = createMenuRadioButton(body, y, "-5mn/15mn", settings, "adventure", "short", adventure)
			y = createMenuRadioButton(body, y, "-8 heures", settings, "adventure", "long", adventure)
			y = createMenuRadioButton(body, y, "-10 heures", settings, "adventure", "aventurine", adventure)
			y = createMenuSeparator(body, y)
			y = createMenuCheckbox(body, y, "Aventures d'events", settings, "adventure_all")
			return y
		end)
		
		y = createSubmenu(body, y, "Trier par :", function (body, y)
			local sort = {}
			y = createMenuRadioButton(body, y, "-Energie", settings, "sort", "stamina", sort)
			y = createMenuRadioButton(body, y, "-Affinite", settings, "sort", "stat", sort)
			y = createMenuRadioButton(body, y, "-Level (desc)", settings, "sort", "level", sort)
			y = createMenuRadioButton(body, y, "-Level (asc)", settings, "sort", "levelasc", sort)
			return y
		end)

		y = createMenuSeparator(body, y)
		
		y = createSubmenu(body, y, "Reserver de l'energie pour :", function (body, y)
			local stamina = {}
			y = createMenuRadioButton(body, y, "-Rien", settings, "stamina", 0, stamina)
			y = createMenuRadioButton(body, y, "-Faire des 8 heures", settings, "stamina", 7, stamina)
			y = createMenuRadioButton(body, y, "-Faire des 10 heures", settings, "stamina", 10, stamina)
			y = createMenuSeparator(body, y)
			y = createMenuCheckbox(body, y, "-Seulement pour les lvl 25", settings, "stamina_max_only")
			return y
		end)

		y = createMenuSeparator(body, y)
		
		y = createSubmenu(body, y, "Utiliser lvl 25 pour recuperer :", function (body, y)
			y = createMenuCheckbox(body, y, "-Artefact", settings.max, "artifact")
			y = createMenuCheckbox(body, y, "-Dimension", settings.max, "dimension")
			y = createMenuCheckbox(body, y, "-Diplomacie", settings.max, "diplomacy")
			y = createMenuCheckbox(body, y, "-Recolte", settings.max, "harvest")
			y = createMenuCheckbox(body, y, "-Chasse", settings.max, "hunt")
			y = createMenuCheckbox(body, y, "-Materiel", settings.max, "material")
			return y
		end)

		y = createMenuSeparator(body, y)
		
		y = createMenuCheckbox(body, y, "Flash", settings, "flash")
		y = createMenuCheckbox(body, y, "Envoyer des lvl 1", settings, "min")
		
		y = createMenuSeparator(body, y)
		y = createMenuCheckbox(body, y, "Verouiller", settings, "locked")
		
		
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
		if MamigoGlobal.settings.flash then
			texture3:SetAlpha(math.abs(Inspect.Time.Real() * 20 % 20 - 10) / 10)
		else
			texture3:SetAlpha(0)
		end
	end, "buttonAnimate")

	frame:SetEnabled(false)
	return frame
end

---------INIT SAVED VARIABLE-------------------------------------------------------------------------------------------------------
local function settingsInit()
	if MamigoGlobal == nil then MamigoGlobal = {} end
	if MamigoGlobal.settings == nil then MamigoGlobal.settings = {} end
	if MamigoGlobal.settings.adventure == nil then MamigoGlobal.settings.adventure = "experience" end
	if MamigoGlobal.settings.sort == nil then MamigoGlobal.settings.sort = "stat" end
	if MamigoGlobal.settings.stamina == nil then MamigoGlobal.settings.stamina = 0 end
	if MamigoGlobal.settings.max == nil then MamigoGlobal.settings.max = {} end
	if MamigoGlobal.settings.flash == nil then MamigoGlobal.settings.flash = false end
	if MamigoGlobal.settings.locked == nil then MamigoGlobal.settings.locked = false end
	
	if MamigoSettings == nil then MamigoSettings = {} end
	if MamigoSettings.window == nil then
		MamigoSettings.window = {
			x = math.floor(UIParent:GetWidth() / 4),
			y = math.floor(UIParent:GetHeight() / 4)
		}
	end
end

--#################################################################################################################################
			---CORE----
--#################################################################################################################################

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

local function minionMatch(adventure, minion)
	local sort = MamigoGlobal.settings.sort
	local max = MamigoGlobal.settings.max[adventure.reward]
	local min = MamigoGlobal.settings.min

	if not min and minion.level == 1 then
		return 0
	end

	if not max and minion.experienceNeeded == nil then
		return 0
	end

	local stamina = adventure.costStamina
	if (minion.experienceNeeded == nil or not MamigoGlobal.settings.stamina_max_only) and stamina < MamigoGlobal.settings.stamina then
		stamina = stamina + MamigoGlobal.settings.stamina
	end
	if minion.stamina < stamina then
		return 0
	end

	local stat = 1
	for i, name in ipairs(statNames) do
		if adventure["stat" .. name] and minion["stat" .. name] ~= nil then
			if sort == "stamina" then
				stat = minion.stamina
			elseif sort == "stat" then
				stat = stat + minion["stat" .. name]
			elseif sort == "level" then
				stat = minion.level
			elseif sort == "levelasc" then
				stat = 1000 - minion.level
			end
			
			--common = blanc / uncommon = vert / rare = bleu / epic = violet
			if adventure.reward == "experience" then
				if minion.rarity == "common" then
					stat = stat * 2 * 2
				elseif minion.rarity == "uncommon" then
					stat = stat * 1
				elseif minion.rarity == "rare" then
					stat = stat * 3
				elseif minion.rarity == "epic" then
					stat = stat * 50
				end
			end
			
		end
	end
	return stat
end

local function mamigoEnable(enable)
	mamigoButton:SetEnabled(enable)
	updateEnable = Inspect.Time.Real()
end

local function minionReady()
	local aids = Inspect.Minion.Adventure.List()
	if aids == nil then
		-- This can happen when logging in
		mamigoEnable(false)
		return
	end
	local adventures = Inspect.Minion.Adventure.Detail(aids)
	local slot = Inspect.Minion.Slot()
	for aid, adventure in pairs(adventures) do
		if adventure.mode == "finished" then
			mamigoEnable(true)
			return
		elseif adventure.mode == "working" then
			slot = slot - 1
		end
	end
	if slot > 0 then
		mamigoEnable(true)
		return
	end
	mamigoEnable(false)
end

local function minionReadyTimer()
	if (Inspect.Time.Real() >= updateEnable + 1) then
		minionReady()
	end
end

local function itemReady()
	minionReady()
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
	if bestid ~= false and best > 0 then
		print("Sending " .. bestminion.name .. " on " .. adventure.name)
		if adventure.costAventurine > 0 then
			Command.Minion.Send(bestid, aid, "aventurine")
		else
			Command.Minion.Send(bestid, aid, "none")
		end
	else
		print("No available minions")
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

local function minionGo()
	if not mamigoButton:GetEnabled() then
		return
	end
	mamigoEnable(false)

	local aids = Inspect.Minion.Adventure.List()
	local adventures = Inspect.Minion.Adventure.Detail(aids)
	local slot = Inspect.Minion.Slot()
	local busy = {}
	for aid, adventure in pairs(adventures) do
		if adventure.mode == "finished" then
			print("Claiming " .. adventure.name)
			Command.Minion.Claim(aid)
			return
		elseif adventure.mode == "working" and adventure.completion > os.time() then
			slot = slot - 1
			busy[adventure.minion] = adventure
		end
	end

	if slot <= 0 then
		print("No available slots")
		return
	end

	local match
	if MamigoGlobal.settings.adventure_all then
		match = adventureMatchAll[MamigoGlobal.settings.adventure]
	else
		match = adventureMatch[MamigoGlobal.settings.adventure]
	end
	for aid, adventure in pairs(adventures) do
		if adventure.mode == "available" and match(adventure) then
			minionSend(aid, adventure, busy)
			return
		end
	end
	print("No available adventures")
end

--#################################################################################################################################
			---MAIN----------------------------------------------------------------------------------------------------------------
--#################################################################################################################################

local function main(handle, addonIdentifier)
	if addonIdentifier ~= addon.identifier then
		return
	end

	settingsInit()

	local context = UI.CreateContext(addon.identifier)

	mamigoButton = createButton(context)
	mamigoButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", MamigoSettings.window.x, MamigoSettings.window.y)
	dragAttach(mamigoButton, MamigoSettings.window)
	mamigoButton:EventAttach(Event.UI.Input.Mouse.Left.Click, minionGo, "minionGo")

	local mamigoMenu = menuInit(context, MamigoGlobal.settings)
	mamigoMenu:SetVisible(false)
	mamigoButton:EventAttach(Event.UI.Input.Mouse.Right.Click, function ()
		menuToggle(mamigoButton, mamigoMenu)
	end, "menuRightClick");

	Command.Event.Attach(Event.System.Update.Begin, minionReadyTimer, "minionReadyTimer")
	Command.Event.Attach(Event.Minion.Adventure.Change, minionReady, "minionReady")
	Command.Event.Attach(Event.Item.Slot, itemReady, "itemReady")
	Command.Event.Attach(Event.Queue.Status, minionReady, "minionReady")
end

Command.Event.Attach(Event.Addon.Load.End, main, "main")
