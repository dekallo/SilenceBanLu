local addonName = ...

-- globals
local CreateFrame, C_ChatBubbles, UnitClassBase, C_AddOns, UnitGUID, MuteSoundFile, ChatFrame_AddMessageEventFilter, GetLocale = CreateFrame, C_ChatBubbles, UnitClassBase, C_AddOns, UnitGUID, MuteSoundFile, ChatFrame_AddMessageEventFilter, GetLocale

-- disable the addon for non-Monk players
if UnitClassBase("player") ~= "MONK" then
	C_AddOns.DisableAddOn(addonName, UnitGUID("player"))
	return
end

-- localization
local banLuName
do
	local L = {
		["deDE"] = "Ban-Lu",
		["enUS"] = "Ban-Lu",
		["esES"] = "Ban-Lu",
		["esMX"] = "Ban-Lu",
		["frFR"] = "Ban Lu",
		["itIT"] = "Ban-Lu",
		["koKR"] = "반루",
		["ptBR"] = "Ban-Lu",
		["ruRU"] = "Бань Лу",
		["zhCN"] = "班禄",
		["zhTW"] = "班盧",
	}
	banLuName = L[GetLocale()] or L["enUS"]
end

-- mute Ban-Lu's sound files
MuteSoundFile(1593212)
MuteSoundFile(1593213)
MuteSoundFile(1593214)
MuteSoundFile(1593215)
MuteSoundFile(1593216)
MuteSoundFile(1593217)
MuteSoundFile(1593218)
MuteSoundFile(1593219)
MuteSoundFile(1593220)
MuteSoundFile(1593221)
MuteSoundFile(1593222)
MuteSoundFile(1593223)
MuteSoundFile(1593224)
MuteSoundFile(1593225)
MuteSoundFile(1593226)
MuteSoundFile(1593227)
MuteSoundFile(1593228)
MuteSoundFile(1593229)
MuteSoundFile(1593236)

-- things Ban-Lu says (key: message, value: true)
local banLuMessages = {}

-- a Frame to watch speech bubbles and hide anything said by Ban-Lu
local BubbleWatcher = CreateFrame("Frame")

-- hides the watcher, preventing the OnUpdate function from running until the next BubbleWatcher:Show()
function BubbleWatcher:Reset()
	self:Hide()
	self.elapsed = 0
end
BubbleWatcher:Reset()

-- returns the text contained within a currently displayed chat bubble
function BubbleWatcher:GetChatBubbleText(chatBubble)
	-- get the chat bubble frame (there will only ever be one child)
	local chatBubbleFrame = chatBubble:GetChildren()
	if chatBubbleFrame.String then
		return chatBubbleFrame.String:GetText()
	end
end

-- check an individual bubble to see if Ban-Lu is talking
function BubbleWatcher:CheckChatBubble(chatBubble)
	local message = self:GetChatBubbleText(chatBubble)
	if banLuMessages[message] and not chatBubble.banLu then
		chatBubble.banLu = true
		-- this bubble isn't hidden already and Ban-Lu said the line contained within, hide the frame
		local chatBubbleFrame = chatBubble:GetChildren()
		chatBubbleFrame:Hide()
	elseif not banLuMessages[message] and chatBubble.banLu then
		chatBubble.banLu = nil
		-- the author is not Ban-Lu but the frame is hidden, show the frame
		local chatBubbleFrame = chatBubble:GetChildren()
		chatBubbleFrame:Show()
	end
end

-- timer function to check the bubbles
BubbleWatcher:SetScript("OnUpdate", function(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	-- have to wait because bubbles show up the frame after the chat event
	if self.elapsed > 0 then
		self:Reset()
		-- iterate through all bubbles we're allowed to modify and check each one
		for _, chatBubble in pairs(C_ChatBubbles.GetAllChatBubbles()) do
			if not chatBubble:IsForbidden() then
				self:CheckChatBubble(chatBubble)
			end
		end
	end
end)


-- hook chat events
do
	-- filter Ban-Lu's spam from chat, and any chat bubbles he might produce
	local function maybeBanLuFilter(_, _, message, author, ...)
		if author == banLuName then
			-- store the message to check in BubbleWatcher:CheckChatBubble
			banLuMessages[message] = true
			BubbleWatcher:Show()
			-- returning true filters the message from chat
			return true
		end

		-- a monster who isn't Ban-Lu is talking
		banLuMessages[message] = nil
		BubbleWatcher:Show()
		return false, message, author, ...
	end

	-- we have to make sure to force show all chat bubbles that aren't Ban-Lu
	-- previous chat bubbles get re-used for new chats and they retain their state
	local function notBanLuFilter(_, _, message, ...)
		-- nil out any table entry for this message, in case someone who isn't Ban-Lu wants to say one of his lines, I guess... lol
		banLuMessages[message] = nil
		BubbleWatcher:Show()
		return false, message, ...
	end

	if ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter then -- Midnight
		-- Ban-Lu is a monster so he talks in MONSTER_SAY
		ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", maybeBanLuFilter)

		-- the chat events which can create bubbles which are guaranteed not to be Ban-Lu
		ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_SAY", notBanLuFilter)
		ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_PARTY", notBanLuFilter)
		ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_YELL", notBanLuFilter)
		ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", notBanLuFilter)
	else -- pre-Midnight
		-- Ban-Lu is a monster so he talks in MONSTER_SAY
		ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", maybeBanLuFilter)

		-- the chat events which can create bubbles which are guaranteed not to be Ban-Lu
		ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", notBanLuFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", notBanLuFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", notBanLuFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", notBanLuFilter)
	end
end
