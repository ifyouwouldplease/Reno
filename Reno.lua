-- Reno - Macro Option Toggler
-- Tuill of Pagle
-- Revisions:
-- 0.10 - Initial version, copy of Mutt (by Tuill) source
-- 0.11 - Update interface for 3.3 and refresh libs
-- 0.12 - Update this revision list, change Curse name to "Reno Macro Patcher" and refresh libs
-- 0.13 - Update interface for 4.0x and refresh libs
-- 0.14 - Update for 4.3 and refresh libs
        -- Updated call to EditMacro, now use nil in texture param to keep existing texture
        -- Updated help text to remove stale Paladin spell examples
-- 0.15 - Update for Mists, bump interface and refresh libs
-- 0.16 - Update for Thunder King, bump interface and refresh libs
-- 0.17 - Bump interface and refresh libs
-- 0.18 - Bump interface and refresh libs
-- 0.19 - Update for Warlords (6.0), bump interface and refresh libs
-- 0.20 - Added 'name' member to Ace3 options table to fix nil error
		-- Added double call to InterfaceOptionsFrame_OpenToCategory to fix
		-- glitch where on 1st call that only ESC > Interface frame is shown
-- 0.21 - Added a UI group to the config page to help with readability
		-- Increased font size to medium on config page
		-- Added button and pop-up for example macro at top of config page for TL;DR
-- 0.22 -- Bump interface for 6.2, refresh libs
-- 0.23 -- Bump interface for 7.0, refresh libs
-- 0.24 -- Bump interface for 7.2, refresh libs
-- 0.25 -- Bump interface for 7.3, refresh libs
-- 0.26 -- Bump interface for 8.0, refresh libs
-- 0.27 -- Bump interface for 8.1, refresh libs, more articulate report of active action
-- 0.28 -- Bump interface for 1.13 Classic, refresh libs
-- 0.29 -- Fix download archive names, added name tag in pkgmeta
-- 0.30 -- Try to correct version # in Twitch client
-- 0.31 -- Ibid.
-- 0.32 -- Bump interface for 1.13.3 Classic, refresh libs
-- 0.33 -- Update example macro, change to markdown changelog, tweak markdown x6
-- 0.34 -- Botched, tag used at Curse repo, but did not update in TOC or source
-- 0.35 -- Reconcile version # in TOC, source and at Curseforge
-- 0.36 -- Bump interface for 1.13.4 Classic, refresh libs
-- 0.37 -- Bump interface for 1.13.5 Classic, refresh libs
-- 0.38 -- Bump interface for 1.13.6 Classic, refresh libs
-- 0.39 -- Tag to prompt package build after contact w/ Overwolf, refresh libs
-- 0.40 -- Migrate to Github from Curse Subversion
-- 0.41 -- Bump to prompt package build back at Curse
-- 0.42 -- Bump interface for 1.13.7 TBC Classic pre-pre-patch, refresh libs
-- 0.43 -- Bump interface for 2.5.2, refresh libs
-- 0.44 -- Bump interface for 2.5.3, refresh libs
-- 0.45 -- Bump interface for 2.5.4, refresh libs
-- 0.46 -- Bump interface for 3.4.1, refresh libs
-- 0.46 -- Bump interface for 3.4.1, refresh libs
-- 0.47 -- Bump interface for 1.14.4 classic, 3.4.3 wrath classic, refresh libs

-- All comments by Tuill
-- I recommend a Lua-aware editor like SciTE that provides syntactic highlighting.

-- No global for now

-- local scope identifier for performance and template-ability
local ourAddon = LibStub("AceAddon-3.0"):NewAddon("Reno", "AceConsole-3.0")

-- local scope identifiers for util functions
local strlower = strlower
local tonumber = tonumber
local string_gsub = string.gsub
local table_insert = table.insert

-- Fetch version & notes from TOC file
local ourVersion = GetAddOnMetadata("Reno", "Version")
local ourNotes = GetAddOnMetadata("Reno", "Notes")

-- Multi-line string for the help text, color codes inline
local helpUsing = [[
More specifically, when given a slash command like this:

/reno "macro name" enabled_option

...Reno searches the chosen macro for all occurances of
the base macro option of the provided "enabled" option,
and edits the macro so that the next occurance of the
option is enabled. Most simply: Reno adds and removes "no"
from the front of the relevant macro options. Murky enough?
Let's try some examples...

Examples:

|cff999999# Assuming you have a macro named "curse" that looks like:|r
/cast [noflying]  Curse of Weakness
/cast [flying]  Curse of Tongues
/cast [flying]  Curse of Exhaustion

|cff999999# By using a Reno command like:|r
/reno "curse" noflying

|cff999999# ...you would patch the curse macro to look like:|r
/cast [flying]  Curse of Weakness
/cast [noflying]  Curse of Tongues
/cast [flying]  Curse of Exhaustion

|cff999999# Reno observes macro options, so you can even do:|r
/reno [button:3] "curse" noflying
/stopmacro [button:3]
/cast [noflying]  Curse of Weakness
/cast [flying]  Curse of Tongues
/cast [flying]  Curse of Exhaustion

|cff999999# ...to have a macro patch itself(!)|r

|cffCC8888# WARNING!|r
|cff999999
# Be advised! If you try this macro-patching-itself trick,
# make absolutely certain that the Reno slash-command is the
# first line of the macro, and that you use macro options to
# make it mutually-exclusive from the rest of your macro
# or else your results will be unpredictable.|r

Details:
|cff999999
# With successive calls, Reno will rotate through the relevant
# options in a round-robin fashion, with the enabled option
# being moved later in the macro with each call. With only two
# appearances of the option Reno will alternate which option
# would be enabled. With more than two appearances Reno will
# move the enabled option from earlier appearances to later,
# and then "wrap around" to enabling the first again.

# Note that what option would be enabled is highly situational,
# but still can be chosen with confidence for most macros. As
# in the example above, I generally use |rnoflying|cff999999 for the enabled
# option for raid-duty macros, since there's no combat flying in
# any of the raids I attend. |rgroup|cff999999/|rnogroup|cff999999 should also be an
# excellent enabled/disabled option pair for raid macros.
|r

Caveats:

* Reno works by editing macros, and macros can't be edited in
combat.

* The default WoW macro editing window doesn't understand
anything about Reno, so if you run Reno commands with the
WoW macro window open you won't see any changes to your
macro and WoW will overwrite any of Reno's changes when the
window closes.

* Reno outputs what it sees to be the enabled macro command
based on the enabled option you give it, but understand
that it's your environment at macro use-time that determines
which commands are truly enabled.

* Reno does no checking to verify the options that you
provide are valid WoW macro options.
|r
]]

ourAddon.renoExampleText = [[
#showtooltip
/reno [btn:3] pcurse noflying
/stopmacro [btn:3]
/assist [@mouseover,nodead]
/target [@mouseover,harm,nodead,exists]
/cast [flying] Curse of Agony()
/cast [flying] Curse of the Elements()
/cast [noflying] Curse of Shadow()
]]

StaticPopupDialogs["RENO_EXAMPLE"] = {
  text = "Example Macro:",
  button1 = "OK",
  OnShow = function (self, data)
    self.editBox:SetMultiLine(true)
	self.editBox:SetHeight(150)
	--self.editBox:GetParent():SetBackdrop(nil) -- Works for entire Dialog
	self.editBox:DisableDrawLayer("BACKGROUND")
    self.editBox:SetText(ourAddon.renoExampleText)
	self.editBox:HighlightText()
	self:Show()
  end,
  hasEditBox = true,
  hasWideEditBox = true,
  editBoxWidth = 220,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

-- Ace3 options table
-- RegisterOptionsTable can take a function ref for the options arg
-- Taking advantage of this in case we decide to dynamically adjust
-- at use-time
local function ourOptions()
  local options = {
   name = "Reno",
   type = 'group',
   args = {
	general = {
	  type = 'group',
	  name = "Settings",
	  args = {
			header1 =
			{
				order = 1,
				type = "header",
				name = "",
			},
			version =
			{
				order = 2,
				type = "description",
				name = "Version " .. ourVersion .. "\n",
			},
			usage =
			{
				type = "group",
				name = "Usage",
				desc = "Usage",
				guiInline = true,
				order = 3,
				args =
				{
					example =
					{
						order = 4,
						type = "execute",
						name = "Show Example Macro",
						desc = "",
						descStyle = "inline",
						func = function() StaticPopup_Show("RENO_EXAMPLE") end,
					},
					about =
					{
						order = 5,
						type = "description",
						name = ourNotes.."\n",
						fontSize = "medium",
					},
					about2 =
					{
						order = 6,
						type = "description",
						name = helpUsing,
						fontSize = "medium",
					},
				},
			},
		},
	}, -- end using
   }, -- top args
  } -- end table
 return options
end

function ourAddon:OnInitialize()

	local ourConfig = LibStub("AceConfig-3.0")
	local ourConfigDialog = LibStub("AceConfigDialog-3.0") -- For snapping into the ESC menu addons list

	ourConfig:RegisterOptionsTable("Reno", ourOptions)

	self.optionsFrames = {}
	self.optionsFrames.general = ourConfigDialog:AddToBlizOptions("Reno", "Reno", nil, "general")

	-- Create slash commands
	self:RegisterChatCommand("reno", "SlashHandler")
end


function ourAddon:SlashHandler(input)
  -- Show addon config dialog as help if no args, we verify we're not in combat
  -- so it should be too annoying (better than just a blurt in the chat pane...)
  if input == "" then
    if InCombatLockdown() then
	  self:Print("In combat, declining to show Reno help dialog.")
	else
	  -- Cheeseball fix for issue that 1st call to display Interface > Reno
	  -- frame only showing ESC > Interface menu, so call twice-in-a-row
	  InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.general)
	  InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.general)
	end
  else
    self:RenoHandler(input)
  end
end

-- Functions defined in a do block so we could have pseudo-static variables
do

  function ourAddon:RenoHandler(input)

    input, ourTarget = SecureCmdOptionParse(input)
	if not input then
	  -- No macro, so stop here
	  -- If we're calling /Reno with macro options, ourArgs will
	  -- be nil in cases where there's no "true" option, so correct
	  -- behavior here is to silently return (do nothing).
	  return
	end

    if InCombatLockdown() then
	  self:Print("Can't adjust macros in combat.")
 	  return
    end

    local slashMacro, slashOpt, slashSuccess, slashOccur

    if input:find('"') then
      _, _, slashMacro, slashSuccess = input:find('(%b"")%s+(%S+)')
    else
      _, _, slashMacro, slashSuccess = input:find('(%S+)%s+(%S+)')
    end

    if not (slashMacro and slashSuccess) then
      self:Print('Usage: /reno "macro name" successoption')
	  return
    end

    slashMacro = slashMacro:gsub('"', "")

	_, _, slashOpt = slashSuccess:find('^no(%w+)')
	if not slashOpt then
	  slashOpt = slashSuccess
	  --slashSuccess = "no"..slashSuccess
	end

	local macroIndex = GetMacroIndexByName(slashMacro)
	if macroIndex == 0 then
	  -- Not a WoW macro, so we can't deal with it...
	  self:Print("Can't find macro "..slashMacro.." (is it an add-on macro not a WoW macro..?)")
	  return
	end

	-- Get current info from provided macro
	local ourName, ourTexture, ourMacroBody, isLocal  = GetMacroInfo(macroIndex)
	--self:Print("|cffccccccDEBUG: We got >>|r"..ourTexture.."|cffcccccc<< for the texture of the macro as-was.\n|r")
	_, slashOccur = ourMacroBody:gsub("[%[,]%s*"..slashSuccess.."[^%]]*%]", "")
	if slashOccur > 1 then
	  self:Print("|cffffff00Warning|cffcccccc - There is more than one occurance of your success option (|r"..slashSuccess.."|cffcccccc) in macro |r"..slashMacro.."|cffcccccc, Reno's results |rmay not be what you expect.|r")
	elseif slashOccur == 0 then
	  self:Print("|cffccccccCouldn't find an occurance of base option |r"..slashOpt.."|cffcccccc in macro |r"..slashMacro..' |cffcccccc(Remember to use |r"|cffccccccdouble quotes|r"|cffcccccc if your macro name contains spaces).|r')
	  return
	end

    renoCall = {allRenos = {}, ourOpt = "", noCount = 0, innerLoop = false, mt = {}}
    setmetatable(renoCall, renoCall.mt)
    renoCall.mt.__index = ourAddon.optBodies

    renoCall.ourOpt = slashOpt

    ourMacroBody = ourMacroBody:gsub("%[([^%]]+)%]", renoCall)

    table.insert(renoCall.allRenos, 1, table.remove(renoCall.allRenos))

    renoCall.mt.__index = ourAddon.popNos

    ourMacroBody = ourMacroBody:gsub("###(%d+)", renoCall)
    local _, _, activeSlashCmd, activeAction = ourMacroBody:find("(/%w*)%s*[%[,]%s*"..slashSuccess.."[^%]]*%]%s*([^;\n]*)")
    --self:Print("activeSlashCmd of the active action was: "..activeSlashCmd)
    self:Print("|cffccccccPatched macro |r"..ourName.."|cffcccccc, looks like active action will be:\n|r"..activeSlashCmd.." "..activeAction)

	EditMacro(macroIndex, ourName, nil, ourMacroBody, isLocal)
	--EditMacro(macroIndex, ourName, "INV_MISC_QUESTIONMARK", ourMacroBody, isLocal)
  end

  function ourAddon.optBodies(ourCall, ourMatch)
    if ourCall.innerLoop then
	  ourCall.noCount = ourCall.noCount + 1
	  ourCall.allRenos[ourCall.noCount] = ourMatch
	  ourCall.innerLoop = false
	  return "###"..ourCall.noCount
    else
      local _, _, caught = ourMatch:find("(%w*"..ourCall.ourOpt..")")
      if caught then
	    ourCall.innerLoop = true
	    return "["..ourMatch:gsub("(%w*"..ourCall.ourOpt..")", ourCall).."]"
      else
	    return nil
      end
    end
  end

  function ourAddon.popNos(ourCall, ourMatch)
    return ourCall.allRenos[tonumber(ourMatch)]
  end

end
