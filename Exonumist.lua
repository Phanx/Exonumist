--[[--------------------------------------------------------------------
	Exonumist
	Tracks your currency tokens across multiple characters.
	by Phanx <addons@phanx.net>
	http://www.wowinterface.com/downloads/info13993-Exonumist.html
	http://www.curse.com/addons/wow/exonumist
----------------------------------------------------------------------]]

local realmDB, charDB

local realm  = GetRealmName()
local player = UnitName("player")

local playerList = {}
local classColor = {}

------------------------------------------------------------------------

local function UpdateData()
	-- print("UpdateData")
	for i = 1, GetCurrencyListSize() do
		local tokenID
		local name, isHeader, isExpanded, isUnused, isWatched, count = GetCurrencyListInfo(i)
		if name and not isHeader then
			if count > 0 then
				charDB[name] = count
			else
				charDB[name] = nil
			end
		end
	end
end

hooksecurefunc("BackpackTokenFrame_Update", UpdateData)

------------------------------------------------------------------------

local function CurrencyButton_OnEnter(self)
	-- print( "CurrencyButton_OnEnter" )
	local i = self:GetParent().index
	local currency, isHeader, _, _, _, count = GetCurrencyListInfo(i)
	if isHeader then return end

	local spaced
	for _, name in ipairs(playerList) do
		local n = realmDB[name][currency]
		-- print(name, n or 0)
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
	local i = 1
	while true do
		local button = _G["TokenFrameContainerButton" .. i]
		if not button then return end

		if not button.hookedOnEnter then
			-- print("TokenFrameContainerButton" .. i ..":HookScript(\"OnEnter\")")
			button.LinkButton:HookScript("OnEnter", CurrencyButton_OnEnter)
			button.hookedOnEnter = true
		end

		i = i + 1
	end
	UpdateData()
end)

------------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
	if event == "ADDON_LOADED" then
		if addon == "Exonumist" then return end

		if not ExonumistDB then ExonumistDB = { } end
		if not ExonumistDB[realm] then ExonumistDB[realm] = { } end
		if not ExonumistDB[realm][player] then ExonumistDB[realm][player] = { } end

		local now = time()

		ExonumistDB[realm][player].class = select(2, UnitClass("player"))
		ExonumistDB[realm][player].lastSeen = now

		charDB = ExonumistDB[realm][player]
		realmDB = ExonumistDB[realm]

		-- remove numbered entries from old versions
		for k, v in pairs(charDB) do
			if type(k) == "number" then
				charDB[k] = nil
			end
		end

		local cutoff = now - (60 * 60 * 24 * 30)
		for name, data in pairs(realmDB) do
			if (data.lastSeen or now) > cutoff and name ~= player then
				tinsert(playerList, name)
			end
		end
		sort(playerList)

		self:UnregisterEvent("ADDON_LOADED")

		if IsLoggedIn() then
			self:GetScript("OnEvent")(self, "PLAYER_LOGIN")
		else
			self:RegisterEvent("PLAYER_LOGIN")
		end
	elseif event == "PLAYER_LOGIN" then
		for k, v in pairs(CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS) do
			classColor[k] = { v.r, v.g, v.b }
		end
		if CUSTOM_CLASS_COLORS then
			CUSTOM_CLASS_COLORS:RegisterCallback(function()
				for k, v in pairs(CUSTOM_CLASS_COLORS) do
					classColor[k][1] = v.r
					classColor[k][2] = v.g
					classColor[k][3] = v.b
				end
			end)
		end

		self:UnregisterEvent("PLAYER_LOGIN")
	end
end)