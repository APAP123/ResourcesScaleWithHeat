--[[
Mod: Resources Scale With Heat 1.0.4b
Author: Freakanoid

	A simple mod that makes resource drops (darkness, gemstones, keys, etc) scale with Heat level.

	Based on the mods "More Darkness for Heat" and "Multiplier Config" by TurboCop and Madd Eye, respectively.
-]]

--[[
    Github: https://github.com/APAP123/ResourcesScaleWithHeat
]]

ModUtil.RegisterMod("ResourcesScaleWithHeat")

-- Customize values here.
local config = {

	-- true: displays text above resources
	-- false: does not display text above resources
	DisplayText = true,

	-- Percentage bonuses; for example, if Darkness is set to 0.05, then every 1 Heat gives you an extra 5% Darkness.
	Percentage = {
		Darkness = 0.05,
		Gems = 0.05
	  },

	-- Amount of Heat per extra pick-up; for example, if Keys is set to 8, then you get 1 extra Key every 8 Heat.
	Divisor = {
		Keys = 8,
		Nectar = 8,
		Blood = 16,
		Ambrosia = 16,
		Diamond = 16
	}
}

ResourcesScaleWithHeat.Config = config

-- Sets bonus to 0 if divisor is 0 to prevent divide-by-zero inf
function CalculateBonus( heat, divisor )
	if divisor == 0 then
		return 0
	end
	return math.floor(heat / divisor)
end

-- Override
ModUtil.BaseOverride("CreateConsumableItemFromData", 
  function( consumableId, consumableItem, costOverride, args )
	--DEBUG
	ModUtil.Hades.PrintStack("CreateConsumableItemFromData called!", 20, Color.Blue)
	-- mod variables
	local percentage = ResourcesScaleWithHeat.Config.Percentage
	local divisor = ResourcesScaleWithHeat.Config.Divisor
	local currentHeat = GetTotalSpentShrinePoints()
	local metaPointsPercentage = percentage.Darkness * currentHeat
	local gemsPercentage =  percentage.Gems * currentHeat
	local lockKeyBonus = CalculateBonus(currentHeat, divisor.Keys)
	local giftPointsBonus = CalculateBonus(currentHeat, divisor.Nectar)
	local superLockKeyBonus = CalculateBonus(currentHeat, divisor.Blood)
	local superGiftPointsBonus = CalculateBonus(currentHeat, divisor.Ambrosia)
	local superGemsBonus = CalculateBonus(currentHeat, divisor.Diamond)
	local printString = ""
	local printId = consumableId

	args = args or {}
	consumableItem.ObjectId = consumableId
	AttachLua({ Id = consumableId, Table = consumableItem })
	AddToGroup({ Id = consumableId, Name = "ConsumableItems" })

	if args ~= nil and args.HideWorldTextOverride ~= nil then
		consumableItem.HideWorldText = args.HideWorldTextOverride
	end

	if not consumableItem.HideWorldText then
		CreateTextBox({ Id = consumableId, Text = consumableItem.Name, FontSize = 20, OffsetY = 50, Color = Color.White, Justification = "CENTER" })
	end

	if costOverride then
		consumableItem.Cost = costOverride
	end

	local costMultiplier = 1 + ( GetNumMetaUpgrades( "ShopPricesShrineUpgrade" ) * ( MetaUpgradeData.ShopPricesShrineUpgrade.ChangeValue - 1 ) )
	costMultiplier = costMultiplier * GetTotalHeroTraitValue("StoreCostMultiplier", {IsMultiplier = true})
	if costMultiplier ~= 1 and ( consumableItem.IgnoreCostIncrease == nil or costMultiplier < 1 ) then
		consumableItem.Cost = round( consumableItem.Cost * costMultiplier )
	end

	-- Apply bonuses
	if consumableItem.AddResources ~= nil then
		if consumableItem.AddResources.MetaPoints ~= nil then
			-- DEBUG
			local metaBonus = CalculateMetaPointMultiplier() + metaPointsPercentage
			local metaTotal = round(consumableItem.AddResources.MetaPoints * metaBonus)
			local initialMeta = consumableItem.AddResources.MetaPoints
			  --consumableItem.AddResources.MetaPoints = round( consumableItem.AddResources.MetaPoints * (CalculateMetaPointMultiplier() + metaPointsPercentage) )
			  consumableItem.AddResources.MetaPoints = metaTotal
			  printString = ("+" .. (metaPointsPercentage * 100) .. "% {!Icons.MetaPoint_Small} from {!Icons.ShrinePointSmall_Active} bonus!")
			  ModUtil.Hades.PrintStack("CalculateMetaPointMultipler: " .. CalculateMetaPointMultiplier() .. " MetaPointPercentage: " .. metaPointsPercentage, 20, Color.White)
			  ModUtil.Hades.PrintStack("InitialMeta: " .. initialMeta .. " MetaBonus: " .. metaBonus .. " MetaTotal: " .. metaTotal, 20, Color.White)
			  ModUtil.Hades.PrintStack("MetapointRewardBonus: " .. GetTotalHeroTraitValue("MetapointRewardBonus", { IsMultiplier = true }) .. " MetaPointMultiplier: " .. GetTotalHeroTraitValue("MetaPointMultiplier", {IsMultiplier = true}), 20, Color.White)
		end
		if consumableItem.AddResources.Gems ~= nil then
			-- DEBUG
			local gemBonus = (GetTotalHeroTraitValue( "GemMultiplier", { IsMultiplier = true } ) + gemsPercentage)
			local gemTotal = round(consumableItem.AddResources.Gems * gemBonus)
			local initialGems = consumableItem.AddResources.Gems
			--consumableItem.AddResources.Gems = round( consumableItem.AddResources.Gems * (GetTotalHeroTraitValue( "GemMultiplier", { IsMultiplier = true } ) + gemsPercentage) )
			consumableItem.AddResources.Gems = gemTotal
			ModUtil.Hades.PrintStack("InitialGems: " .. initialGems .. " GemBonus: " .. gemBonus .. " GemTotal: " .. gemTotal, 20, Color.White)
			  ModUtil.Hades.PrintStack("GemRewardBonus: " .. GetTotalHeroTraitValue("GemRewardBonus", { IsMultiplier = true }) .. " GemMultiplier: " .. GetTotalHeroTraitValue("GemMultiplier", {IsMultiplier = true}), 20, Color.White)
			printString = ("+" .. (gemsPercentage * 100) .. "% {!Icons.GemSmall} from {!Icons.ShrinePointSmall_Active} bonus!")
		end
		if consumableItem.AddResources.LockKeys ~= nil then
			consumableItem.AddResources.LockKeys = consumableItem.AddResources.LockKeys + lockKeyBonus
		  -- Print conditions
		  	if lockKeyBonus > 0 then
			  	printString = ("+" .. lockKeyBonus .. " {!Icons.LockKeySmall} from {!Icons.ShrinePointSmall_Active} bonus!")
		  	end
		end
		if consumableItem.AddResources.SuperLockKeys ~= nil then
			consumableItem.AddResources.SuperLockKeys = consumableItem.AddResources.SuperLockKeys + superLockKeyBonus
		  -- Print conditions
		  	if superLockKeyBonus > 0 then
			 	printString = ("+" .. superLockKeyBonus .. " {!Icons.SuperLockKeySmall} from {!Icons.ShrinePointSmall_Active} bonus!")
		  	end
		end
		if consumableItem.AddResources.GiftPoints ~= nil then
			consumableItem.AddResources.GiftPoints = consumableItem.AddResources.GiftPoints + giftPointsBonus
		  -- Print Conditions
		  	if giftPointsBonus > 0 then
			 	printString = ("+" .. giftPointsBonus .. " {!Icons.GiftPointSmall} from {!Icons.ShrinePointSmall_Active} bonus!")
		  	end
		end
		if consumableItem.AddResources.SuperGiftPoints ~= nil then
			consumableItem.AddResources.SuperGiftPoints = consumableItem.AddResources.SuperGiftPoints + superGiftPointsBonus
		  -- Print Conditions
		  	if superGiftPointsBonus > 0 then
			  	printString = ("+" .. superGiftPointsBonus .. " {!Icons.SuperGiftPointSmall} from {!Icons.ShrinePointSmall_Active} bonus!")
		  	end
		end
		if consumableItem.AddResources.SuperGems ~= nil then
			consumableItem.AddResources.SuperGems = consumableItem.AddResources.SuperGems + superGemsBonus
			if superGemsBonus > 0 then
				printString = ("+" .. superGemsBonus .. " {!Icons.SuperGemSmall} from {!Icons.ShrinePointSmall_Active} bonus!")
			end
		end
	end

	UpdateCostText( consumableItem )

	if ResourcesScaleWithHeat.Config.DisplayText and currentHeat > 0 then 
		ModUtil.Hades.PrintOverhead(printString, 3, Color.White, printId)
		
	end

	return consumableItem
  end
)

-- Needed to handle chamber reward overrides
ModUtil.BaseOverride("ApplyConsumableItemResourceMultiplier", 
  function(currentRoom, reward )
	-- mod variables
	local percentage = ResourcesScaleWithHeat.Config.Percentage
	local divisor = ResourcesScaleWithHeat.Config.Divisor
	local currentHeat = GetTotalSpentShrinePoints()
	local metaPointsPercentage = percentage.Darkness * currentHeat
	local gemsPercentage =  percentage.Gems * currentHeat
	local lockKeyBonus = CalculateBonus(currentHeat, divisor.Keys)
	local giftPointsBonus = CalculateBonus(currentHeat, divisor.Nectar)
	local superLockKeyBonus = CalculateBonus(currentHeat, divisor.Blood)
	local superGiftPointsBonus = CalculateBonus(currentHeat, divisor.Ambrosia)
	local superGemsBonus = CalculateBonus(currentHeat, divisor.Diamond)

	local gemRewardMultiplier = GetTotalHeroTraitValue("GemRewardBonus", { IsMultiplier = true })
	local metapointRewardMultiplier = GetTotalHeroTraitValue("MetapointRewardBonus", { IsMultiplier = true })
	local coinRewardMultiplier = GetTotalHeroTraitValue("MoneyRewardBonus", { IsMultiplier = true })
	local healthRewardMultiplier = GetTotalHeroTraitValue("HealthRewardBonus", { IsMultiplier = true })
	if reward.AddResources ~= nil then
		if reward.AddResources.Gems ~= nil then
			reward.AddResources.Gems = round( reward.AddResources.Gems * gemRewardMultiplier )
			ModUtil.Hades.PrintStack("Multiplier Gem PreOverride:" .. reward.AddResources.Gems, 20, Color.Green)
		end
		if reward.AddResources.MetaPoints ~= nil then
			reward.AddResources.MetaPoints = round( reward.AddResources.MetaPoints * metapointRewardMultiplier )
			ModUtil.Hades.PrintStack("Multiplier Meta PreOverride:" .. reward.AddResources.MetaPoints, 20, Color.Green)
		end
	end
	if reward.AddMaxHealth ~= nil then
		reward.AddMaxHealth = round( reward.AddMaxHealth * healthRewardMultiplier )
	end
	
	local rewardOverrides = currentRoom.RewardConsumableOverrides or currentRoom.RewardOverrides
	if rewardOverrides ~= nil and ( rewardOverrides.ValidRewardNames == nil or Contains( rewardOverrides.ValidRewardNames, reward.Name )) then
		for key, value in pairs( rewardOverrides ) do
			if reward[key] ~= nil then
				reward[key] = value
				if key == "AddResources"  then
					--if reward.AddResources.MetaPoints ~= nil and not currentRoom.IgnoreMetaPointMultiplier then
					if reward.AddResources.MetaPoints ~= nil then
						ModUtil.Hades.PrintStack("Multiplier Meta PostOverride (Initial value):" .. reward.AddResources.MetaPoints, 20, Color.Green)
						reward.AddResources.MetaPoints = round( reward.AddResources.MetaPoints * (CalculateMetaPointMultiplier() + metaPointsPercentage) )
						reward.AddResources.MetaPoints = round( reward.AddResources.MetaPoints * metapointRewardMultiplier )
						--reward.AddResources.MetaPoints = round( reward.AddResources.MetaPoints * ( 1 + (  CalculateMetaPointMultiplier() - 1 ) + ( metapointRewardMultiplier - 1 )))
						ModUtil.Hades.PrintStack("Multiplier Meta PostOverride (after calc):" .. reward.AddResources.MetaPoints, 20, Color.Green)
					end
					if reward.AddResources.Gems ~= nil then
						-- For some reason, the original script by SGG has the GemRewardMultiplier applied twice here?? This is why Gem amounts with my mod kept getting
						-- abnormally high - it was applying GemRewardMultiplier (which is used for Ocean's Bounty) twice. Not sure if this was intentional by SGG, but
						-- I'm commenting it out for now.
						--reward.AddResources.Gems = round( reward.AddResources.Gems * gemRewardMultiplier )
						reward.AddResources.Gems = round( consumableItem.AddResources.Gems * (GetTotalHeroTraitValue( "GemMultiplier", { IsMultiplier = true } ) + gemsPercentage) )
						reward.AddResources.Gems = round(reward.AddResources.Gems * gemRewardMultiplier)
						-- local gemMultiplier = GetTotalHeroTraitValue( "GemMultiplier", { IsMultiplier = true } )
						-- reward.AddResources.Gems = round( reward.AddResources.Gems * ( 1 + ( gemMultiplier - 1 ) + ( gemRewardMultiplier - 1 )))
						ModUtil.Hades.PrintStack("Multiplier Gem PostOverride:" .. reward.AddResources.Gems, 20, Color.Green)
					end
					if reward.AddResources.LockKeys ~= nil then
						reward.AddResources.LockKeys = reward.AddResources.LockKeys + lockKeyBonus
					end
					if reward.AddResources.SuperLockKeys ~= nil then
						reward.AddResources.SuperLockKeys = reward.AddResources.SuperLockKeys + superLockKeyBonus
					end
					if reward.AddResources.GiftPoints ~= nil then
						reward.AddResources.GiftPoints = reward.AddResources.GiftPoints + giftPointsBonus
					end
					if reward.AddResources.SuperGiftPoints ~= nil then
						reward.AddResources.SuperGiftPoints = reward.AddResources.SuperGiftPoints + superGiftPointsBonus
					end
					if reward.AddResources.SuperGems ~= nil then
						reward.AddResources.SuperGems = reward.AddResources.SuperGems + superGemsBonus
					end
				elseif key == "AddMaxHealth" and reward.AddMaxHealth ~= nil then
					reward.AddMaxHealth = round( reward.AddMaxHealth * healthRewardMultiplier )
					ExtractValues( CurrentRun.Hero, reward, reward )
				end
			end
		end
	end

	if reward.DropMoney ~= nil then
		local moneyMultiplier = GetTotalHeroTraitValue( "MoneyMultiplier", { IsMultiplier = true } )
		reward.DropMoney = round( reward.DropMoney * ( 1 + ( moneyMultiplier - 1 ) + ( coinRewardMultiplier - 1 )))
	end
  end
)

-- Needed for trove rewards
ModUtil.BaseOverride("HandleChallengeLoot",
  function( challengeSwitch, challengeEncounter )
	-- mod variables
	local percentage = ResourcesScaleWithHeat.Config.Percentage
	local currentHeat = GetTotalSpentShrinePoints()
	local metaPointsPercentage = percentage.Darkness * currentHeat
	local gemsPercentage =  percentage.Gems * currentHeat

	if challengeEncounter ~= nil then
		Destroy({ Id = challengeSwitch.ValueTextAnchor })
		SetAnimation({ DestinationId = challengeSwitch.ObjectId, Name = "ChallengeSwitchOpen" })

		-- presentation
		PlaySound({ Name = "/Leftovers/World Sounds/Caravan Interior/ChestOpen", Id = challengeSwitch.ObjectId })
		PlaySound({ Name = "/Leftovers/Menu Sounds/EmoteAffection" })
		local healingMultiplier = CalculateHealingMultiplier()
		if ( challengeSwitch.RewardType == "Health" and healingMultiplier == 0 ) or (challengeSwitch.RewardType == "Money" and HasHeroTraitValue("BlockMoney")) then
			thread( PlayVoiceLines, GlobalVoiceLines.ChallengeSwitchEmptyVoiceLines, true )
		else
			thread( PlayVoiceLines, GlobalVoiceLines.ChallengeSwitchOpenedVoiceLines, true )
		end

		UseableOff({ Id = challengeSwitch.ObjectId })

		local lootPointId = CurrentRun.Hero.ObjectId
		--local angle = GetAngleBetween({ Id = challengeSwitch.ObjectId, DestinationId = lootPointId })
		local angle = GetAngleBetween({ Id = challengeSwitch.ObjectId, DestinationId = CurrentRun.Hero.ObjectId })
		local distance = GetDistance({ Id = challengeSwitch.ObjectId, DestinationId = CurrentRun.Hero.ObjectId })
		local dropOffset = CalcOffset(math.rad(angle), distance/2)

		for lootName, lootData in pairs(challengeEncounter.LootDrops) do
			if lootData.DropChance == nil or RandomChance(lootData.DropChance) then
				local minDrop = lootData.MinDrop or 1
				local maxDrop = lootData.MaxDrop or 1
				local dropCount = lootData.DropCount or RandomInt(minDrop, maxDrop)
				for index = 1, dropCount, 1 do
					local consumableId = SpawnObstacle({ Name = lootName, DestinationId = CurrentRun.Hero.ObjectId, Group = "Standing", ForceToValidLocation = true, })
					local cost = 0 -- All challenge loot is free
					CreateConsumableItem( consumableId, lootName, cost )
					ApplyUpwardForce({ Id = consumableId, Speed = RandomFloat( 500, 700 ) })
					ApplyForce({ Id = consumableId, Speed = RandomFloat( 50, 100 ), Angle = angle, SelfApplied = true })
				end
			end
		end
		if challengeSwitch.RewardType == "Money" then
			local moneyMultiplier = GetTotalHeroTraitValue( "MoneyMultiplier", { IsMultiplier = true } )
			local amount = round( challengeSwitch.CurrentValue * moneyMultiplier )
			thread( GushMoney, { Amount = amount, LocationId = challengeSwitch.ObjectId, Radius = 50, Source = challengeSwitch.Name, Offset = dropOffset } )
		elseif challengeSwitch.RewardType == "Health" then
			Heal( CurrentRun.Hero, { HealAmount = challengeSwitch.CurrentValue, Name = "HealthChallengeSwitch" } )
		elseif challengeSwitch.RewardType == "MetaPoints" then
			local consumableId = SpawnObstacle({ Name = "RoomRewardMetaPointDrop", DestinationId = CurrentRun.Hero.ObjectId, Group = "Standing", ForceToValidLocation = true, })
			local cost = 0
			local consumable = CreateConsumableItem( consumableId, "RoomRewardMetaPointDrop", cost )
			consumable.AddResources = consumable.AddResources or {}
			consumable.AddResources.MetaPoints = round( challengeSwitch.CurrentValue * (CalculateMetaPointMultiplier() + metaPointsPercentage) )
			ApplyUpwardForce({ Id = consumableId, Speed = RandomFloat( 500, 700 ) })
			ApplyForce({ Id = consumableId, Speed = RandomFloat( 50, 100 ), Angle = angle, SelfApplied = true })
		elseif challengeSwitch.RewardType == "Gems" then
			local gemMultiplier = GetTotalHeroTraitValue( "GemMultiplier", { IsMultiplier = true } )
			local consumableId = SpawnObstacle({ Name = "GemDrop", DestinationId = CurrentRun.Hero.ObjectId, Group = "Standing", ForceToValidLocation = true, })
			local cost = 0
			local consumable = CreateConsumableItem( consumableId, "GemDrop", cost )
			consumable.AddResources = consumable.AddResources or {}
			consumable.AddResources.Gems = round(challengeSwitch.CurrentValue * (gemMultiplier + gemsPercentage) )
			ApplyUpwardForce({ Id = consumableId, Speed = RandomFloat( 500, 700 ) })
			ApplyForce({ Id = consumableId, Speed = RandomFloat( 50, 100 ), Angle = angle, SelfApplied = true })
		end
	end
  end
)

-- Needed for Sisyphus Darkness reward (if the function name didn't make it obvious)
ModUtil.BaseOverride("SisyphusMetaPoints",
function( source, args )
	-- mod variables
	local percentage = ResourcesScaleWithHeat.Config.Percentage
	local currentHeat = GetTotalSpentShrinePoints()
	local metaPointsPercentage = percentage.Darkness * currentHeat

	local consumableId = SpawnObstacle({ Name = "RoomRewardMetaPointDrop", DestinationId = source.ObjectId, Group = "Standing" })
	local cost = 0
	local consumable = CreateConsumableItem( consumableId, "RoomRewardMetaPointDrop", cost )
	local amount = RandomInt( source.MetaPointMin, source.MetaPointMax )
	ModUtil.Hades.PrintStack("Sisyphus Amount:" .. amount, 20, Color.Green)
	consumable.AddResources = { MetaPoints = round( amount * (CalculateMetaPointMultiplier() + metaPointsPercentage) ) }
	SetAnimation({ DestinationId = source.ObjectId, Name = "SisyphusElbowing" })
	ApplyUpwardForce({ Id = consumableId, Speed = 700 })
	local forceAngle = GetAngleBetween({ Id = source.ObjectId, DestinationId = CurrentRun.Hero.ObjectId })
	ApplyForce({ Id = consumableId, Speed = 100, Angle = forceAngle, SelfApplied = true })
end
)