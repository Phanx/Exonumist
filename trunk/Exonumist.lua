--[[--------------------------------------------------------------------
	Exonumist
	Adds information to the tooltips in the currency window showing how
	many of each token your other characters have.

	by Phanx < addons@phanx.net >
	http://www.wowinterface.com/downloads/info13993-Exonumist.html
	http://wow.curse.com/downloads/wow-addons/details/exonumist.aspx
	Copyright © 2010 Alyssa "Phanx" Kinley. All rights reserved.
	See README for license terms and additional information.

	exonumist /ek-suh-NOO-mist/
	–noun
	a person who collects items, as tokens or medals, that resemble
	money but are not intended to circulate as money.
----------------------------------------------------------------------]]

local realmDB, charDB

local realm  = GetRealmName()
local player = UnitName("player")

local playerList = { }
local classColor = { }

------------------------------------------------------------------------

local function UpdateData()
	--print("UpdateData")
	for i = 1, GetCurrencyListSize() do
		local tokenID
		local name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon, itemID = GetCurrencyListInfo(i)
		if not isHeader then
			if extraCurrencyType == 1 then
				tokenID = 1
			elseif extraCurrencyType == 2 then
				tokenID = 2
			elseif itemID > 0 then
				tokenID = itemID
			end
			if tokenID and count > 0 then
				charDB[tokenID] = count
			else
				charDB[tokenID] = nil
			end
		end
	end
end

hooksecurefunc("BackpackTokenFrame_Update", UpdateData)

------------------------------------------------------------------------

local function CurrencyButton_OnEnter(self)
	--print( "CurrencyButton_OnEnter" )
	local tokenID
	if self:GetParent().extraCurrencyType == 1 then
		--print( "extraCurrencyType == 1" )
		tokenID = 1
	elseif self:GetParent().extraCurrencyType == 2 then
		--print( "extraCurrencyType == 2" )
		tokenID = 2
	else
		local i = self:GetParent().index
		local tokenName, _, _, _, _, count, extraCurrencyType, _, itemID = GetCurrencyListInfo(i)
		--print( ("i = %s, itemID = %s"):format( tostring(i), tostring(itemID) ) )
		tokenID = itemID
	end

	local spaced
	for _, name in ipairs(playerList) do
		local n = realmDB[name][tokenID]
		--print(name, n or 0)
		if n then
			if not spaced then
				GameTooltip:AddLine(" ")
				spaced = true
			end
			local r, g, b
			local class = realmDB[name].class
			if class then
				r, g, b = unpack(classColor[class])
			else
				r, g, b = 0, 1, 1
			end
			GameTooltip:AddDoubleLine(name, n, r, g, b, r, g, b)
		end
	end
	if spaced then
		GameTooltip:Show()
	end
end

hooksecurefunc("TokenFrame_Update", function()
	local buttons = TokenFrameContainer.buttons
	for i = 1, #buttons do
		local button = buttons[i]
		if not button.hookedOnEnter then
			--print( ("TokenFrameContainer.buttons[%d] HookScript OnEnter"):format(i) )
			button.LinkButton:HookScript("OnEnter", CurrencyButton_OnEnter)
			button.hookedOnEnter = true
		end
	end
	UpdateData()
end)

------------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		if ... == "Exonumist" then return end

		if not ExonumistDB then ExonumistDB = { } end
		if not ExonumistDB[realm] then ExonumistDB[realm] = { } end
		if not ExonumistDB[realm][player] then ExonumistDB[realm][player] = { } end

		ExonumistDB[realm][player].class = select(2, UnitClass("player"))

		charDB = ExonumistDB[realm][player]
		realmDB = ExonumistDB[realm]

		for name in pairs(realmDB) do
			if name ~= player then
				table.insert(playerList, name)
			end
		end
		table.sort(playerList)

		self:UnregisterEvent("ADDON_LOADED")

		if IsLoggedIn() then
			self:GetScript("OnEvent")(self, "PLAYER_LOGIN")
		else
			self:RegisterEvent("PLAYER_LOGIN")
		end
	elseif event == "PLAYER_LOGIN" then
		for k, v in pairs(CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS) do
			classColor[k] = { (v.r + 1) / 2, (v.g + 1) / 2, (v.b + 1) / 2 }
		end
	end
end)

------------------------------------------------------------------------