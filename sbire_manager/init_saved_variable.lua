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

local function init_saved_variabe()
	if SbireManagerGlobal == nil then SbireManagerGlobal = {} end
	if SbireManagerGlobal.settings == nil then SbireManagerGlobal.settings = {} end
	
	--temps d'aventure
	--experience / short / long / aventurine (1mn / 5mn / 8h / 10h )
	if SbireManagerGlobal.settings.adventureTime == nil then SbireManagerGlobal.settings.adventureTime = "experience" end
	if SbireManagerGlobal.settings.adventureEvent == nil then SbireManagerGlobal.settings.adventureEvent = true end
	if SbireManagerGlobal.settings.hurry == nil then SbireManagerGlobal.settings.hurry = false end

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
	if SbireManagerGlobal.settings.destroyDimensionItem == nil then SbireManagerGlobal.settings.destroyDimensionItem = false end
	
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

init_saved_variabe()