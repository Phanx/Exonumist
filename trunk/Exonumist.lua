--[[--------------------------------------------------------------------
	Exonumist
	Tracks your currency tokens across multiple characters.
	by Phanx <addons@phanx.net>
	http://www.wowinterface.com/downloads/info13993-Exonumist.html
	http://www.curse.com/addons/wow/exonumist
----------------------------------------------------------------------]]

local realmDB, charDB

local realm   = GetRealmName()
local faction = UnitFactionGroup("player")
local player  = UnitName("player")

local playerList = {}
local classColor = {}

local nameToID = {}

------------------------------------------------------------------------

local collapsed = {}
local function UpdateData()
	if TokenFrame:IsVisible() then
		return
	end
	local i, limit = 1, GetCurrencyListSize()
	while i <= limit do
		local name, isHeader, isExpanded, isUnused, isWatched, count, icon = GetCurrencyListInfo(i)
		if isHeader then
			if not isExpanded then
				collapsed[name] = true
				ExpandCurrencyList(i, 1)
				limit = GetCurrencyListSize()
			end
		else
			local link = GetCurrencyListLink(i)
			local id = tonumber(strmatch(link, "currency:(%d+)"))
			nameToID[name] = id
			if count > 0 then
				charDB[id] = count
			else
				charDB[id] = nil
			end
		end
		i = i + 1
	end
	while i > 0 do
		local name, isHeader, isExpanded, isUnused, isWatched, count, icon = GetCurrencyListInfo(i)
		if isHeader and isExpanded and collapsed[name] then
			ExpandCurrencyList(i, 0)
		end
		i = i - 1
	end
	wipe(collapsed)
end

hooksecurefunc("BackpackTokenFrame_Update", UpdateData)
hooksecurefunc("TokenFrame_Update", UpdateData)

------------------------------------------------------------------------

local function AddTooltipInfo(tooltip, currency)
	local spaced
	for _, player in ipairs(playerList) do
		local n = realmDB[player][currency]
		if n then
			if not spaced then
				tooltip:AddLine(" ")
				spaced = true
			end
			local r, g, b
			local class = realmDB[player].class
			if class then
				r, g, b = unpack(classColor[class])
			else
				r, g, b = 0.5, 0.5, 0.5
			end
			tooltip:AddDoubleLine(player, n, r, g, b, r, g, b)
		end
	end
	if spaced then
		tooltip:Show()
	end
end

hooksecurefunc(GameTooltip, "SetCurrencyByID", function(tooltip, id)
	AddTooltipInfo(tooltip, id)
end)

hooksecurefunc(GameTooltip, "SetCurrencyToken", function(tooltip, i)
	local name, isHeader, isExpanded, isUnused, isWatched, count, icon = GetCurrencyListInfo(i)
	AddTooltipInfo(GameTooltip, nameToID[name])
end)

hooksecurefunc(GameTooltip, "SetMerchantCostItem", function(tooltip, item, currency)
	local icon, _, _, name = GetMerchantItemCostItem(item, currency)
	AddTooltipInfo(tooltip, nameToID[name])
end)

------------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
	if event == "ADDON_LOADED" then
		if addon ~= "Exonumist" then return end

		if not ExonumistDB then ExonumistDB = { } end
		if not ExonumistDB[realm] then ExonumistDB[realm] = { } end
		if not ExonumistDB[realm][faction] then ExonumistDB[realm][faction] = { } end
		if not ExonumistDB[realm][faction][player] then ExonumistDB[realm][faction][player] = { } end

		for k,v in pairs(ExonumistDB[realm]) do
			if k ~= "Alliance" and k ~= "Horde" then
				ExonumistDB[realm][k] = nil
			end
		end

		local now = time()

		realmDB = ExonumistDB[realm][faction]
		charDB = realmDB[player]

		charDB.class = select(2, UnitClass("player"))
		charDB.lastSeen = now

		local cutoff = now - (60 * 60 * 24 * 30)
		for name, data in pairs(realmDB) do
			if data.lastSeen and data.lastSeen < cutoff then
				realmDB[name] = nil
			elseif name ~= player then
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