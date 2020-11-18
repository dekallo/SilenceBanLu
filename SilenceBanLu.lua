-- disable the addon for non-Monk players
if select(2, UnitClass('player')) ~= "MONK" then
  DisableAddOn("SilenceBanLu")
  return
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

-- things Ban-Lu says
local banLuMessages = {}

-- returns the text contained within a currently displayed chat bubble
local function getChatBubbleText(chatBubble)
  -- get chat bubble frame
	local chatBubbleFrame = select(1, chatBubble:GetChildren())
	for i = 1, chatBubbleFrame:GetNumRegions() do
    local region = select(i, chatBubbleFrame:GetRegions())
    -- only the bubble region with text will have ObjectType == FontString
    if region:GetObjectType() == "FontString" then
			return region:GetText()
		end
	end
end

-- check an individual bubble to see if Ban-Lu is talking
local function checkChatBubble(chatBubble)
  local message = getChatBubbleText(chatBubble)

  -- only Ban-Lu's messages will be in this table (author will always be Ban-Lu)
  local author = banLuMessages[message]

  if author == "Ban-Lu" and not chatBubble.banlu then
    -- this bubble isn't hidden already, and Ban-Lu said the line contained within, hide the frame
    local chatBubbleFrame = select(1, chatBubble:GetChildren())
    chatBubbleFrame:Hide()
	  chatBubble.banlu = true
  elseif author ~= "Ban-Lu" and chatBubble.banlu then
    -- the author is not Ban-Lu but the frame is hidden, show the frame
    local chatBubbleFrame = select(1, chatBubble:GetChildren())
    chatBubbleFrame:Show()
    chatBubble.banlu = nil
	end
end

-- iterate through all bubbles we're allowed to modify and check each one
local function checkChatBubbles(chatBubbles)
	for _, chatBubble in pairs(chatBubbles) do
		if not chatBubble:IsForbidden() then
      checkChatBubble(chatBubble)
		end
	end
end

-- a Frame to watch speech bubbles and hide anything said by Ban-Lu
local BubbleWatcher = CreateFrame("Frame", nil, WorldFrame)
BubbleWatcher:SetFrameStrata("TOOLTIP")
-- function to reset the watcher
BubbleWatcher.Reset = function(self)
	self:Hide()
	self.elapsed = 0
end
-- init
BubbleWatcher:Reset()

-- timer function to check the bubbles
BubbleWatcher:SetScript("OnUpdate", function(self, elapsed)
  self.elapsed = self.elapsed + elapsed
  -- have to wait because bubbles show up the frame after the chat event
  if self.elapsed > 0.01 then
		self:Reset()
		checkChatBubbles(C_ChatBubbles:GetAllChatBubbles())
	end
end)

-- filter Ban-Lu's spam from chat, and any chat bubbles he might produce
local function maybeBanLuFilter(_, _, message, author, ...)
  if author == "Ban-Lu" then
    banLuMessages[message] = author
    BubbleWatcher:Show()
    -- returning true filters the message from chat
    return true
  end

  -- a monster who isn't Ban-Lu is talking
  banLuMessages[message] = nil
  BubbleWatcher:Show()
  return false, message, author, ...
end

-- Ban-Lu is a monster so he talks in MONSTER_SAY
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_SAY", maybeBanLuFilter)

-- we have to make sure to force show all chat bubbles that aren't Ban-Lu
-- previous chat bubbles get re-used for new chats and they retain their state
local function notBanLuFilter(_, _, message, ...)
  -- nil out any table entry for this message, in case someone who isn't Ban-Lu wants to say one of his lines, I guess... lol
  banLuMessages[message] = nil
  BubbleWatcher:Show()
  return false, message, ...
end

-- the chat events which can create bubbles which are guaranteed not to be Ban-Lu
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", notBanLuFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", notBanLuFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", notBanLuFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_MONSTER_YELL", notBanLuFilter)