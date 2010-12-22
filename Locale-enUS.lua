local AceLocale = AceLibrary("AceLocale-2.2"):new("QuestAnnouncer2")

AceLocale:RegisterTranslations("enUS", function()
	return {
		["ADDON_PREFIX"] = "QuestAnnouncer",
		["SLASHCMD_LONG"] = "/questannouncer2",
		["SLASHCMD_SHORT"] = "/qa2",
		["WELCOME_NOTE"] = "QuestAnnouncer2, use %s for options",
		
		["OPT_ANNOUNCE_NAME"] = "Send announcements through party chat",
		["OPT_ANNOUNCE_DESC"] = "Toggles whether announcements should also be sent through party chat allowing non-QA2 users to get updates",
		["OPT_ANNOUNCE_ON"] = "Announcements WILL be sent through Party Chat",
		["OPT_ANNOUNCE_OFF"] = "Announcements WILL NOT be sent through Party Chat",
		["OPT_DISPLAY_NAME"] = "Log announcements to the chatframe",
		["OPT_DISPLAY_DESC"] = "Toggles whether announcements will be logged in the chatframe",
		["OPT_DISPLAY_ON"] = "Announcements WILL be shown in the chatframe",
		["OPT_DISPLAY_OFF"] = "Announcements WILL NOT be shown in the chatframe",
				
		["DISPLAY_UI_UPDATE"] = "%s\'s quest progress... %s", 
		["DISPLAY_UI_COMPLETE"] = "%s has completed %s",
		["DISPLAY_UI_FAILED"] = "%s has failed %s",

		["DISPLAY_UI_MYCOMPLETE"] = "You have completed %s", 
		["DISPLAY_UI_MYFAILED"] = "You have failed %s",
		["DISPLAY_UI_MYUPDATE"] = "My quest progress... %s",
		
		["OUT_OF_VERSION"] = "%s is using a newer version (rev. %s) of QuestAnnouncer2. Please visit wowui.worldofwar.net to update.",
		["UI_SCHEMA"] = "(.*):%s*([-%d]+)%s*/%s*([-%d]+)%s*$",
	}
end)
