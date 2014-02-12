local RL = AceLibrary("RosterLib-2.0")
local BS = AceLibrary("Babble-Spell-2.2")

sRaidFramesHeals = sRaidFrames:NewModule("sRaidFramesHeals", "AceComm-2.0", "AceHook-2.0", "AceEvent-2.0")
sRaidFramesHeals.ver = GetAddOnMetadata("sRaidFrames", "Version")


local watchSpells = {
	[BS["Holy Light"]] = true,
	[BS["Flash of Light"]] = true,
	[BS["Flash Heal"]] = true,
	[BS["Greater Heal"]] = true,
	[BS["Heal"]] = true,
	[BS["Healing Touch"]] = true,
	[BS["Lesser Healing Wave"]] = true,
	[BS["Healing Wave"]] = true,
	[BS["Regrowth"]] = true,
	[BS["Prayer of Healing"]] = true,
}


	function sRaidFramesHeals:OnInitialize()
		if not Grid then  --need to check if Grid active othervise error 
			self:SetCommPrefix("Grid")
		end	
	end

	function sRaidFramesHeals:OnEnable()

		if not self.tooltip then
			self.tooltip = CreateFrame("GameTooltip", "sRaidFramesHeals_Tooltip", UIParent, "GameTooltipTemplate")
			self.tooltip:SetScript("OnLoad",function() this:SetOwner(WorldFrame, "ANCHOR_NONE") end)
		end
		
		self:Hook("CastSpell") --blocked
		self:Hook("CastSpellByName") --blocked
		--self:Hook("UseAction") --blocked
		self:Hook("SpellTargetUnit")
		self:Hook("SpellStopTargeting")
		--self:Hook("TargetUnit")  -- blocked
		self:HookScript(WorldFrame,"OnMouseDown","sRaidFramesHealsOnMouseDown")
		-- register events
		self:RegisterEvent("SPELLCAST_START")
		self:RegisterEvent("SPELLCAST_STOP")
		--self:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF","CombatLogHeal")
		--self:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF","CombatLogHeal")
		-- AceComm

		self:RegisterComm("Grid", "GROUP", "OnCommReceive")

	end
	
	function sRaidFramesHeals:OnCommReceive(prefix, sender, distribution, what, who, spell, sufix)

	    if sender == UnitName("player") then return end
		if not RL:GetUnitIDFromName(sender) then return end

		if what == "HN" then
			self:UnitIsHealed(who)
		elseif what == "HG" then
			self:GroupHeal(sender)
		end
		
		--DEFAULT_CHAT_FRAME:AddMessage("xxx")
	end
	
	
	function sRaidFramesHeals:GroupHeal(healer)
		-- TO DO
	end
	
	function sRaidFramesHeals:UnitIsHealed(name)
		-- TO DO
	end

	
	function sRaidFramesHeals:SPELLCAST_START()
		
		
		if not self.target and UnitExists("target") and UnitIsFriend("target", "player") then
			self.target = GetUnitName("target")
		end

		if watchSpells[arg1] and self.target then
			--DEFAULT_CHAT_FRAME:AddMessage("sRaidFramesHeals:SPELLCAST_START");

			if self.spell == BS["Prayer of Healing"] then
				self:GroupHeal(playerName)
				if GridStatusHeals then
					GridStatusHeals:SendCommMessage("GROUP", "HG")
				else
					self:SendCommMessage("GROUP", "HG")
				end	
			else
				if RL:GetUnitIDFromName(self.target) then
					if GridStatusHeals then
						GridStatusHeals:SendCommMessage("GROUP", "HN", self.target, arg1, GetTime(), nil, "SRF_"..self.ver)
					else
						self:SendCommMessage("GROUP", "HN", self.target, arg1, GetTime(), nil, "SRF_"..self.ver)
					end	
				end
			end
		end
	end


	function sRaidFramesHeals:SPELLCAST_STOP()
		self.target = nil
	end


	--{{{ hooks 
	
	-- we need to replace these in TBC by a different logic

	function sRaidFramesHeals:CastSpell(spellId, spellbookTabNum)
		--DEFAULT_CHAT_FRAME:AddMessage("CastSpell");
		self.hooks["CastSpell"](spellId, spellbookTabNum)
		sRaidFramesHeals_Tooltip:SetSpell(spellId, spellbookTabNum)
		local spellName = sRaidFramesHeals_TooltipTextLeft1:GetText()
		if SpellIsTargeting() then 
			self.spell = spellName
		elseif UnitExists("target") then
			self.spell = spellName
			--self.target = UnitName("target")
		end
	end


	function sRaidFramesHeals:CastSpellByName(a1, a2)
		--DEFAULT_CHAT_FRAME:AddMessage("CastSpellByName");
		self.hooks["CastSpellByName"](a1, a2)
		local _, _, spellName = string.find(a1, "^([^%(]+)");
		if spellName then
			if SpellIsTargeting() then
				self.spell = spellName
			else
				self.spell = spellName
				--self.target = UnitName("target") -------------------------------------------------------------------------------
			end
		end
	end


	function sRaidFramesHeals:UseAction(a1, a2, a3)
		sRaidFramesHeals_Tooltip:SetAction(a1)
		local spellName = sRaidFramesHeals_TooltipTextLeft1:GetText()
		self.spell = spellName
		self.hooks["UseAction"](a1, a2, a3)
		if GetActionText(a1) or not self.spell then return end
		if SpellIsTargeting() then return
		elseif a3 then
			self.target = UnitName("player")
		elseif UnitExists("target") then
			self.target = UnitName("target")
		end
	end


	function sRaidFramesHeals:SpellTargetUnit(a1)
		--DEFAULT_CHAT_FRAME:AddMessage("sRaidFramesHeals:SpellTargetUnit")
		local shallTargetUnit
		if SpellIsTargeting() then
			shallTargetUnit = true
		end
		self.hooks["SpellTargetUnit"](a1)
		if shallTargetUnit and self.spell and not SpellIsTargeting() then
			self.target = UnitName(a1)
			--DEFAULT_CHAT_FRAME:AddMessage("sRaidFramesHeals:SpellTargetUnit - "..self.target)
		end
	end


	function sRaidFramesHeals:SpellStopTargeting()
		self.hooks["SpellStopTargeting"]()
		self.spell = nil
		self.target = nil
	end


	function sRaidFramesHeals:TargetUnit(a1)
		self.hooks["TargetUnit"](a1)
		if self.spell and UnitExists(a1) then
			self.target = UnitName(a1)
			--DEFAULT_CHAT_FRAME:AddMessage("sRaidFramesHeals:TargetUnit");
		end
	end


	function sRaidFramesHeals:sRaidFramesHealsOnMouseDown()
		if self.spell and UnitName("mouseover") then
			self.target = UnitName("mouseover")
		elseif self.spell and GameTooltipTextLeft1:IsVisible() then
			local _, _, name = string.find(GameTooltipTextLeft1:GetText(), "^Corpse of (.+)$")
			if ( name ) then
				self.target = name;
			end
		end
		--DEFAULT_CHAT_FRAME:AddMessage("sRaidFramesHeals:sRaidFramesHealsOnMouseDown");
		self.hooks[WorldFrame]["OnMouseDown"]()
	end

	--}}}

--}}}

-- life , aggro, confirm
-- combatLog orange
-- Spellcastctart green
-- latency detection events vs on_comm  bedzie x2


--}}}
	
	