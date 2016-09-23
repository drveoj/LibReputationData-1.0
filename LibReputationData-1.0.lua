local MAJOR, MINOR = "LibReputationData-1.0", 1

assert(_G.LibStub, MAJOR .. " requires LibStub")
local lib = _G.LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.callbacks = lib.callbacks or _G.LibStub("CallbackHandler-1.0"):New(lib)

-- local store
local timer
local reputationChanges = {}
local allFactions = {}
local watchedFaction = nil


-- blizzard api
local GetFactionInfo                = _G.GetFactionInfo
local GetFriendshipReputation		= _G.GetFriendshipReputation

-- lua api
local select   = _G.select
local strmatch = _G.string.match
local tonumber = _G.tonumber

local private = {} -- private space for the event handlers

lib.frame = lib.frame or _G.CreateFrame("Frame")
local frame = lib.frame
frame:UnregisterAllEvents() -- deactivate old versions
frame:SetScript("OnEvent", function(_, event, ...) private[event](event, ...) end)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local function CopyTable(tbl)
	if not tbl then return {} end
	local copy = {};
	for k, v in pairs(tbl) do
		if ( type(v) == "table" ) then
			copy[k] = CopyTable(v);
		else
			copy[k] = v;
		end
	end
	return copy;
end


local function GetFactionIndex(factionName)
	for i = 1, #allFactions do
		local name, _, _, _, _, _, _, _, _, _, _, _, _ = GetLocalFactionInfo(i); --added 2 or 3 _, to the end
		if name == factionName then return i end
	end
end

local function GetFLocalFactionInfo(factionIndex)
	return allFactions[factionIndex]
end


-- Refresh the list of known factions
local function RefreshAllFactions()
	local i = 1
	local lastName
	local factions = {}
	--ExpandAllFactionHeaders()
	repeat
		-- name, description, standingId, bottomValue, topValue, earnedValue, atWarWith,
		--  canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID,
		--  hasBonusRepGain, canBeLFGBonus = GetFactionInfo(factionIndex)
		local name, _, standingId, bottomValue, topValue, earnedValue, _,
			_, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID = GetFactionInfo(i)
		if not name or name == lastName and name ~= GUILD then break end

		if isWatched then watchedFaction = factionID

		local friendID, friendRep, friendMaxRep, _, _, _, friendTextLevel, friendThresh = GetFriendshipReputation(factionID)
		if friendID ~= nil then
			bottomValue = friendThresh
			if nextThresh then
				topValue = friendThresh + min( friendMaxRep - friendThresh, 8400 ) -- Magic number! Yay!
			end
			earnedValue = friendRep
		end
		lastName = name
		tinsert(factions, {
			name = name,
			standingId = standingId,
			min = bottomValue,
			max = topValue,
			value = earnedValue,
			isHeader = isHeader,
			isChild = isChild,
			hasRep = hasRep,
			isActive = not IsFactionInactive(i),
			factionID = factionID,
			friendID = friendID
		})
		if isCollapsed then ExpandFactionHeader(i) end
		i = i + 1
	until i > 200

	allFactions = factions
end

------------------------------------------------------------------------------
-- Ensure factions and guild info are loaded
------------------------------------------------------------------------------
local function EnsureFactionsLoaded()
	-- Sometimes it takes a while for faction and guild info
	-- to load when the game boots up so we need to periodically
	-- check whether its loaded before we can display it
	if GetFactionInfo(1) == nil or (IsInGuild() and GetGuildInfo("player") == nil) then
		self:ScheduleTimer("EnsureFactionsLoaded", 0.5)	
	else
		-- Refresh all factions and notify subscribers
		RefreshAllFactions()
		lib.callbacks:Fire("FACTIONS_LOADED")
	end
end

------------------------------------------------------------------------------
-- Update reputation
------------------------------------------------------------------------------
local function UpdateReputationChanges()
	self:RefreshAllFactions()

	-- Build sorted change table
	local changes = {}
	for name, amount in pairs(reputationChanges) do
		-- Skip inactive factions
		local factionIndex = self:GetFactionIndex(name)
		if factionIndex and not IsFactionInactive(factionIndex) then
			tinsert(changes, {
				name = name,
				amount = amount,
				factionIndex = factionIndex
			})
		end
	end

	if #changes > 1 then
		table.sort(changes, function(a, b) return a.amount > b.amount end)
	end

	if #changes > 0 then
		-- Notify subscribers
		InformReputationsChanged(changes)
	end
	
	timer = nil
	reputationChanges = {}
end


local function InformReputationsChanged(changes)
	Debug("REPUTATIONS_CHANGED")
	for _,amount,factionIndex do
		lib.callbacks:Fire("REPUTATIONS_CHANGED", factionIndex,amount)
	end
end

------------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------------
function private.PLAYER_ENTERING_WORLD(event)
	_G.C_Timer.After(5, function()
		EnsureFactionsLoaded()
		frame:RegisterEvent("COMBAT_TEXT_UPDATE")
	end)
end

function private.COMBAT_TEXT_UPDATE(event, type, name, amount)
	if (type == "FACTION") then
		if IsInGuild() then
			-- Check name for guild reputation
			if name == GUILD then
				name = (GetGuildInfo("player"))
				if not name or name == "" then return end
			end
		end
	
		-- Collect all gained reputation before notifying modules
		if not reputationChanges[name] then
			reputationChanges[name] = amount
		else
			reputationChanges[name] = reputationChanges[name] + amount
		end

		if timer then
			self:CancelTimer(timer, true)
		end
		timer = self:ScheduleTimer("UpdateReputationChanges", 0.1)

	end
end

------------------------------------------------------------------------------
-- API
------------------------------------------------------------------------------

function lib.GetWatchedFaction()
	return watchedFaction
end

function lib.GetReputationInfo(_, factionID)
	return reputationID, CopyTable(allFactions[factionID])
end

function lib.GetAllReputationsInfo()
	return CopyTable(allFactions)
end

function lib.GetNumObtainedReputations()
	local numReputations = 0
	for reputation in pairs(allFactions) do
		if tonumber(reputation) then
			numReputations = numReputations + 1
		end
	end
	return numReputations
end

function lib.ForceUpdate()
	RefreshAllFactions()
end
