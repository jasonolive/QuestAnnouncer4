local L = AceLibrary("AceLocale-2.2"):new("QuestAnnouncer2");

local options = {
	type = 'group',
	args = {
		PartyChat = {
			type = 'toggle',
			name = L["OPT_ANNOUNCE_NAME"],
			desc = L["OPT_ANNOUNCE_DESC"],
			get = "GetPartyChat",
			set = "SetPartyChat",
		},
		History = {
			type = 'toggle',
			name = L["OPT_DISPLAY_NAME"],
			desc = L["OPT_DISPLAY_DESC"],
			get = "GetHistory",
			set = "SetHistory",	
		},
	},
};

-- Declare variables used throughout the addon
	QuestAnnouncer2 = AceLibrary("AceAddon-2.0"):new("AceComm-2.0", "AceConsole-2.0", "AceEvent-2.0", "AceDB-2.0");
	QuestAnnouncer2:RegisterChatCommand( {L["SLASHCMD_LONG"], L["SLASHCMD_SHORT"]}, options );
	QuestAnnouncer2:RegisterDB( "QuestAnnouncer2DB", "QuestAnnouncer2DBPC" );
	QuestAnnouncer2:SetCommPrefix(L["ADDON_PREFIX"]);
	QuestAnnouncer2:RegisterDefaults( "profile", {PartyChat = false, History = false});

	local QuestLog = {};
	local QuestAnnouncer2_QuestLogUpdating = false;
	local QuestAnnouncer2_ShowVersionWarning = true;
	local QuestAnnouncer2_UpdateInterval = 15;
	local COLOR_YELLOW = {r=1,g=1,b=0};
	local COLOR_GREEN = {r=0,g=1,b=0};
	local COLOR_RED = {r=1,g=0,b=0};

function QuestAnnouncer2:OnEnable()
	-- Register events and setup communications
	self:Print(string.format(L["WELCOME_NOTE"], L["SLASHCMD_SHORT"]));
	self:RegisterEvent("QUEST_LOG_UPDATE");
	self:RegisterEvent("UI_INFO_MESSAGE");
	self:RegisterComm(L["ADDON_PREFIX"], "GROUP", "ReceiveMessage");
	self:ScheduleRepeatingEvent(self.IntervalUpdate, QuestAnnouncer2_UpdateInterval, self);
end

function QuestAnnouncer2:IntervalUpdate()
	-- Send versioning information to others
	if (GetNumPartyMembers()>0) then
		self:SendCommMessage("GROUP", "VERSION", self.version, 0)
	end
end

function QuestAnnouncer2:ReceiveMessage(prefix, sender, distribution, msgtype, arg1, arg2)
	if (prefix == L["ADDON_PREFIX"]) and (msgtype ~= nil) and (distribution == "GROUP") and (sender ~= UnitName("player")) then
		if msgtype == "ANNOUNCE" then
			UIErrorsFrame:AddMessage(string.format(arg1[1], sender, arg1[2]),arg2.r,arg2.g,arg2.b,1.0,UIERRORS_HOLD_TIME)
			if (self:GetHistory()) then
				self:CustomPrint(arg2.r, arg2.g, arg2.b, nil, nil, nil, string.format(arg1[1], sender, arg1[2]))
			end
		elseif msgtype == "VERSION" then
			if (tonumber(arg1) > tonumber(self.version)) and QuestAnnouncer2_ShowVersionWarning then
				self:Print(string.format(L["OUT_OF_VERSION"], sender, arg1));
				QuestAnnouncer2_ShowVersionWarning = false;
			end
		end
	end
end

function QuestAnnouncer2:SendAnnouncement(message, color)
	if (GetNumPartyMembers()>0) then
		if (self:GetPartyChat()) then
			SendChatMessage(string.format(message[1], UnitName("player"), message[2]),  "PARTY")
		end
		self:SendCommMessage("GROUP", "ANNOUNCE", message, color);
	end
end


function QuestAnnouncer2:DisplayMyAnnouncements(message, color)
	UIErrorsFrame:AddMessage(message,color.r, color.g, color.b,1.0,UIERRORS_HOLD_TIME);
	if (self:GetHistory()) then
		self:CustomPrint(color.r, color.g, color.b, nil, nil, nil, message)
	end
end

function QuestAnnouncer2:UI_INFO_MESSAGE( message )
	-- does the message fits our schema?
	local questUpdateText = gsub(message,L["UI_SCHEMA"],"%1",1);
	if (questUpdateText ~= message) then
		if (self:GetHistory()) then
			self:CustomPrint(COLOR_YELLOW.r, COLOR_YELLOW.g, COLOR_YELLOW.b, nil, nil, nil, string.format(L["DISPLAY_UI_MYUPDATE"], message))
		end
		self:SendAnnouncement({L["DISPLAY_UI_UPDATE"], message}, COLOR_YELLOW);
	end
end

function QuestAnnouncer2:QUEST_LOG_UPDATE()
	local new_QuestLog = {};
	local questCRC = 0;
	-- Check to see if thread is already running. If so, exit.
	if ( QuestAnnouncer2_QuestLogUpdating ) then
		return true;
	end

	-- Lock the thread
	QuestAnnouncer2_QuestLogUpdating = true;

	--Scan Quest Log
	local QuestID=0;
	while (GetQuestLogTitle(QuestID+1) ~= nil) do
		QuestID = QuestID + 1;
		local questTitle, _, _, _, isHeader, _, isComplete = GetQuestLogTitle(QuestID);
		if (not isHeader) then
			SelectQuestLogEntry(QuestID);

			-- Get CRC value of current quest's description.  This allows for better tracking of quests with the same name.
			local questDescription, questObjectives = GetQuestLogQuestText();
			if (questDescription) then
				questCRC = CRCLib.crc(questDescription);

				local status = 'active'
				if isComplete == 1 then
					status = 'complete'
				elseif isComplete == -1 then
					status = 'failed'
				end
				new_QuestLog[questCRC] = status

				-- Check for Quest changes
				if not QuestLog[questCRC] or QuestLog[questCRC] ~= new_QuestLog[questCRC] then
					if QuestLog[questCRC] == 'active' and new_QuestLog[questCRC] == 'complete' then
						self:DisplayMyAnnouncements(string.format(L["DISPLAY_UI_MYCOMPLETE"], questTitle), COLOR_GREEN);
						self:SendAnnouncement({L["DISPLAY_UI_COMPLETE"], questTitle}, COLOR_GREEN);
					elseif (QuestLog[questCRC] == 'active' or QuestLog[questCRC] == 'complete') and new_QuestLog[questCRC] == 'failed' then
						self:DisplayMyAnnouncements(string.format(L["DISPLAY_UI_MYFAILED"], questTitle), COLOR_RED);
						self:SendAnnouncement({L["DISPLAY_UI_FAILED"], questTitle}, COLOR_RED);
					end
				end

				QuestLog[questCRC] = nil
			end
		end
	end

	-- Switch the two tables, so that new_QuestLog becomes QuestLog
	--new_QuestLog, QuestLog = QuestLog, new_QuestLog
	--self.QuestLog = QuestLog
	QuestLog = new_QuestLog;
	
	-- Unlock the thread
	QuestAnnouncer2_QuestLogUpdating = false;

end

function QuestAnnouncer2:GetPartyChat()
	return self.db.profile.PartyChat
end

function QuestAnnouncer2:SetPartyChat(name)
self.db.profile.PartyChat = not self.db.profile.PartyChat
	if self.db.profile.PartyChat then
		self:Print(L["OPT_ANNOUNCE_ON"])
	else
		self:Print(L["OPT_ANNOUNCE_OFF"])
	end
end

function QuestAnnouncer2:GetHistory()
	return self.db.profile.History
end

function QuestAnnouncer2:SetHistory(name)
	self.db.profile.History = not self.db.profile.History
	if self.db.profile.History then
		self:Print(L["OPT_DISPLAY_ON"])
	else
		self:Print(L["OPT_DISPLAY_OFF"])
	end
end