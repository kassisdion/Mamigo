--[[
	-----------------------------------------------------------------
	sbire_manager
	-----------------------------------------------------------------
    Copyright or © or Copr. kassisdion

    https://github.com/kassisdion

    This software is a computer program whose purpose is to make yout minion go on adventure easyli.

    This software is governed by the CeCILL license under French law and abiding by the rules of distribution of free software. You can use, modify and/ or redistribute the software under the terms of the CeCILL license as circulated by CEA, CNRS and INRIA at the following URL "http://www.cecill.info".

    As a counterpart to the access to the source code and rights to copy, modify and redistribute granted by the license, users are provided only with a limited warranty and the software's author, the holder of the economic rights, and the successive licensors have only limited
    liability.

    In this respect, the user's attention is drawn to the risks associated with loading, using, modifying and/or developing or reproducing the software by the user in light of its specific status of free software, that may mean that it is complicated to manipulate, and that also
    therefore means that it is reserved for developers and experienced professionals having in-depth computer knowledge. Users are therefore encouraged to load and test the software's suitability as regards their requirements in conditions enabling the security of their systems and/or data to be ensured and, more generally, to use and operate it in the same conditions as regards security.

    The fact that you are presently reading this means that you have had knowledge of the CeCILL license and that you accept its terms.
	-----------------------------------------------------------------
]]--
local addon, private = ...

local DEBUG = true

local sbireManagerButton = nil
local countdown = 0
local lastRefresh = 0
local countdownFrame = nil


local boxWidth = 270
local frameHeight = 20
local fontSize = 14

local COLOR_GREEN = "<font color=\"#00FF00\">"
local COLOR_RED = "<font color=\"#FF0000\">"
local COLOR_BLUE = "<font color=\"#0000FF\">"
local COLOR_WHITE = "<font color=\"#000000\">"
local COLOR_BLACK = "<font color=\"#000000\">"
local COLOR_PINK = "<font color=\"#FF00FF\">"

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

local function printText(text, colorTag)
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
		
		y = createMenuSeparator(body, y)
		
		--[[y = createSubmenu(body, y, "Element voulus :", function (body, y)
			y = createMenuCheckbox(body, y, "-Air", settings.adventureTypeWanted, statNames[1])
			y = createMenuCheckbox(body, y, "-Artefact", settings.adventureTypeWanted, statNames[2])
			y = createMenuCheckbox(body, y, "-Assassinat", settings.adventureTypeWanted, statNames[3])
			y = createMenuCheckbox(body, y, "-Mort", settings.adventureTypeWanted, statNames[4])
			y = createMenuCheckbox(body, y, "-Dimension", settings.adventureTypeWanted, statNames[5])
			y = createMenuCheckbox(body, y, "-Diplomacy", settings.adventureTypeWanted, statNames[6])
			y = createMenuCheckbox(body, y, "-Terre", settings.adventureTypeWanted, statNames[7])
			y = createMenuCheckbox(body, y, "-Exploration", settings.adventureTypeWanted, statNames[8])
			y = createMenuCheckbox(body, y, "-Feu", settings.adventureTypeWanted, statNames[9])
			y = createMenuCheckbox(body, y, "-Recolte", settings.adventureTypeWanted, statNames[10])
			y = createMenuCheckbox(body, y, "-Chasse", settings.adventureTypeWanted, statNames[11])
			y = createMenuCheckbox(body, y, "-Vie", settings.adventureTypeWanted, statNames[12])
			y = createMenuCheckbox(body, y, "-Eau", settings.adventureTypeWanted, statNames[13])
			return y
		end)]]--
		
		y = createSubmenu(body, y, "Element non voulus :", function (body, y)
			y = createMenuCheckbox(body, y, "-Air", settings.adventureTypeNonWanted, statNames[1])
			y = createMenuCheckbox(body, y, "-Artefact", settings.adventureTypeNonWanted, statNames[2])
			y = createMenuCheckbox(body, y, "-Assassinat", settings.adventureTypeNonWanted, statNames[3])
			y = createMenuCheckbox(body, y, "-Mort", settings.adventureTypeNonWanted, statNames[4])
			y = createMenuCheckbox(body, y, "-Dimension", settings.adventureTypeNonWanted, statNames[5])
			y = createMenuCheckbox(body, y, "-Diplomatie", settings.adventureTypeNonWanted, statNames[6])
			y = createMenuCheckbox(body, y, "-Terre", settings.adventureTypeNonWanted, statNames[7])
			y = createMenuCheckbox(body, y, "-Exploration", settings.adventureTypeNonWanted, statNames[8])
			y = createMenuCheckbox(body, y, "-Feu", settings.adventureTypeNonWanted, statNames[9])
			y = createMenuCheckbox(body, y, "-Collecte", settings.adventureTypeNonWanted, statNames[10])
			y = createMenuCheckbox(body, y, "-Chasse", settings.adventureTypeNonWanted, statNames[11])
			y = createMenuCheckbox(body, y, "-Vie", settings.adventureTypeNonWanted, statNames[12])
			y = createMenuCheckbox(body, y, "-Eau", settings.adventureTypeNonWanted, statNames[13])
			return y
		end)
		
		y = createMenuCheckbox(body, y, "Remanier", settings, "shuffle")
		
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
		
		y = createMenuCheckbox(body, y, "Envoyer des lvl 1", settings, "sendMin")
		y = createMenuCheckbox(body, y, "Envoyer des lvl 25", settings, "sendMax")
		
		--global settings
		y = createMenuSeparator(body, y)
		
		y = createMenuCheckbox(body, y, "Verouiller la fenetre", settings, "locked")
		y = createMenuCheckbox(body, y, "Couleur \"flashy\"", settings, "highLight")
		y = createMenuCheckbox(body, y, "Afficher le compteur", settings, "countdown")
		
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
		if SbireManagerGlobal.settings.highLight then
			texture3:SetAlpha(math.abs(Inspect.Time.Real() * frameHeight % frameHeight - 10) / 10)
		else
			texture3:SetAlpha(0)
		end
	end, "buttonAnimate")

	frame:SetEnabled(false)
	countdownFrame = UI.CreateFrame("Text", "", frame)
	countdownFrame:SetPoint("CENTERLEFT", frame, "CENTERRIGHT", -5, 0)
	countdownFrame:SetFontSize(16)
	countdownFrame:SetText("timer")
	countdownFrame:SetBackgroundColor(0, 0, 0, 0.8)
	countdownFrame:SetLayer(-1)
	countdownFrame:SetVisible(SbireManagerGlobal.settings.countdown)
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
	
	--type d'aventure voulus
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
	
		--type d'aventure non voulus
	if SbireManagerGlobal.settings.adventureTypeNonWanted == nil then
		SbireManagerGlobal.settings.adventureTypeNonWanted = {}
		SbireManagerGlobal.settings.adventureTypeNonWanted["Air"] = false
		SbireManagerGlobal.settings.adventureTypeNonWanted["Artifact"] = false
		SbireManagerGlobal.settings.adventureTypeNonWanted["Assassination"] = false
		SbireManagerGlobal.settings.adventureTypeNonWanted["Death"] = false
		SbireManagerGlobal.settings.adventureTypeNonWanted["Dimension"] = false
		SbireManagerGlobal.settings.adventureTypeNonWanted["Diplomacy"] = false
		SbireManagerGlobal.settings.adventureTypeNonWanted["Earth"] = false
		SbireManagerGlobal.settings.adventureTypeNonWanted["Exploration"] = false
		SbireManagerGlobal.settings.adventureTypeNonWanted["Fire"] = false
		SbireManagerGlobal.settings.adventureTypeNonWanted["Harvest"] = false
		SbireManagerGlobal.settings.adventureTypeNonWanted["Hunting"] = false
		SbireManagerGlobal.settings.adventureTypeNonWanted["Life"] = false
		SbireManagerGlobal.settings.adventureTypeNonWanted["Water"] = false
	end
	
	if SbireManagerGlobal.settings.shuffle == nil then SbireManagerGlobal.settings.shuffle = false end
	
	--priorisation
	--energie / stats / lvl_asc / lvl_desc
	if SbireManagerGlobal.settings.prio == nil then SbireManagerGlobal.settings.prio = "stats" end
	
	--energie minimal
	--0 / 7 / 10
	if SbireManagerGlobal.settings.energieMin == nil then SbireManagerGlobal.settings.energieMin = 0 end
	if SbireManagerGlobal.settings.energieMinFilter == nil then SbireManagerGlobal.settings.energieMinFilter = false end
	
	--envoyer des lvl 1 / 25
	if SbireManagerGlobal.settings.sendMin == nil then SbireManagerGlobal.settings.sendMin = false end
	if SbireManagerGlobal.settings.sendMax == nil then SbireManagerGlobal.settings.sendMax = false end
	
	--afficher le countdown
	if SbireManagerGlobal.settings.countdown == nil then SbireManagerGlobal.settings.countdown = true end
	
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

local function sbireManagerEnable(enable)
	sbireManagerButton:SetEnabled(enable or SbireManagerGlobal.settings.hurry)
end

local function shuffleAdventure(aid, adventure)
	if SbireManagerGlobal.settings.shuffle then
		printText("Remaniement de l'aventure \"" .. adventure.name .. "\"", COLOR_GREEN)
		Command.Minion.Shuffle(aid, "aventurine")
		return true
	end
	return false
end

local function claimMinion(aid)
	Command.Minion.Claim(aid)
end

local function hurryAdventure(aid)
	if SbireManagerGlobal.settings.hurry then
		Command.Minion.Hurry(aid, "aventurine")
		return true
	end
	return false
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
	local adventureStat
	for i, name in ipairs(statNames) do
		adventureStat = adventure["stat" .. name]
		if adventureStat then
			if SbireManagerGlobal.settings.adventureTypeNonWanted[name] then
				return false
			end
		end
	end
	return true
end

local function minionReady()
	local aids = Inspect.Minion.Adventure.List()
	if aids == nil then
		sbireManagerEnable(false)
		return
	end
	
	local adventures = Inspect.Minion.Adventure.Detail(aids)
	local slot = Inspect.Minion.Slot()
	for aid, adventure in pairs(adventures) do
		if adventure.mode == "finished" then
			sbireManagerEnable(true)
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

local function refreshCountdown(currentTime)
	local aids = Inspect.Minion.Adventure.List()
	if aids == nil then
		sbireManagerEnable(false)
		return
	end
	
	local adventures = Inspect.Minion.Adventure.Detail(aids)
	local nbAdventure = 0
	for aid, adventure in pairs(adventures) do
		if adventure.mode == "working" then
			nbAdventure = nbAdventure + 1
			local endTime = adventure.completion
			if countdown < currentTime or endTime < countdown then countdown = endTime end
		elseif adventure.mode == "finished" then
			countdown = 0
			return
		end
	end
	if nbAdventure == 0 then countdown = 0 end
end

local function minionReadyTimer()
	local currentTime = Inspect.Time.Server()
	
	if (currentTime >= lastRefresh + 1) then
		countdownFrame:SetVisible(SbireManagerGlobal.settings.countdown)
		
		if SbireManagerGlobal.settings.countdown and countdownFrame then
			refreshCountdown(currentTime)
			local endTimer = countdown - currentTime
			if endTimer > 0 then 
				if (endTimer > 3599) then
					countdownFrame:SetText("  " .. COLOR_GREEN .. tostring(math.floor(endTimer/3600)) .. "h  ", true)
				elseif (endTimer > 59) then
					countdownFrame:SetText("  " .. COLOR_GREEN .. tostring(math.floor(endTimer/60)) .. "mn ", true)
				else
					countdownFrame:SetText("  " .. COLOR_GREEN .. tostring(endTimer) .. "s  ", true)
				end
			else
				countdownFrame:SetText("  " .. COLOR_RED .. "  Terminé  ", true)
			end
		end
	minionReady()
	lastRefresh = currentTime;
	end
end

local function minionMatch(adventure, minion)
	local prio = SbireManagerGlobal.settings.prio
	local sendMin = SbireManagerGlobal.settings.sendMin
	local sendMax = SbireManagerGlobal.settings.sendMax
	
	--verifier si on veux envoyerles sbires lvl 1/25
	if not sendMin and minion.level == 1 then
		return 0
	end
	if not sendMax and minion.level == 25 then
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
		if adventure.costAventurine > 0 then
			Command.Minion.Send(bestid, aid, "aventurine")
		else
			Command.Minion.Send(bestid, aid, "none")
		end
		printText("Envois de " .. bestminion.name, COLOR_GREEN)		
	else
		printText("Aucun minion compatible avec l'aventure\"" .. adventure.name .. "\" trouvé", COLOR_GREEN)
	end
end

local function minionGo()
	if not sbireManagerButton:GetEnabled() then
		return
	end
	
	sbireManagerEnable(false)
	
	local aids = Inspect.Minion.Adventure.List()
	if aids == nil then
		sbireManagerEnable(false)
		return
	end
	
	local adventures = Inspect.Minion.Adventure.Detail(aids)
	local slot = Inspect.Minion.Slot()
	local busy = {}
	
	for aid, adventure in pairs(adventures) do
		if adventure.mode == "finished" then
			claimMinion(aid)
			return
		elseif adventure.mode == "working" and adventure.completion > os.time() then
			if hurryAdventure(aid) then return end
			slot = slot - 1
			busy[adventure.minion] = adventure
		end
	end

	if slot <= 0 then
		printText("Aucun slot de disponible", COLOR_GREEN)
		return
	end

	--on cherche une aventure
	local matchTime
	if SbireManagerGlobal.settings.adventureEvent then
		matchTime = adventureMatchAll[SbireManagerGlobal.settings.adventureTime]
	else
		matchTime = adventureMatch[SbireManagerGlobal.settings.adventureTime]
	end
	
	for aid, adventure in pairs(adventures) do
		if adventure.mode == "available" then
			if matchTime(adventure) then
				if ((SbireManagerGlobal.settings.adventureTime == "experience") or matchStats(adventure)) then
					minionSend(aid, adventure, busy)
					return
				end
				--l'aventure ne corresponds pas en carac
				if shuffleAdventure(aid, adventure) == false then printText("Aucune aventure ne correspond à vos criteres", COLOR_GREEN) end
				return
			end
		end
	end
end

--#################################################################################################################################
			---MAIN----------------------------------------------------------------------------------------------------------------
--#################################################################################################################################

local function initUi()
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

local function init()
	settingsInit()
	initUi()
end

local function main(handle, addonIdentifier)
	if addonIdentifier ~= addon.identifier then
		return
	end
	init()
	printText("Initialisation terminé (V2.3)", COLOR_GREEN)
end

Command.Event.Attach(Event.Addon.Load.End, main, "main")

