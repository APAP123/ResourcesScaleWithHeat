--[[
Mod: Resources Scale With Heat
Author: Freakanoid

	A simple mod that makes resource drops (darkness, gemstones, keys, etc) scale with Heat level.

	Based on the mods "More Darkness for Heat" and "Multiplier Config" by TurboCop and Madd Eye, respectively.
-]]

--[[
    Github location: https://github.com/APAP123/ScaleResourcesWithHeat
]]

ModUtil.RegisterMod("ResourcesScaleWithHeat")

-- Customize values here.
local config = {

	-- Set this value to false to disable bonus display text, and set it to true to enable bonus display text.
	DisplayText = true

	-- Percentages; for example, if Darkness is set to 0.05, then every 1 Heat gives you an extra 5% Darkness.
	Multiplier = {
		Darkness = 0.05,
		Gems = 0.05
	  },

	Divisor = { -- Amount of Heat per extra pick-up; for example, if Keys is set to 8, then you get 1 extra Key every 8 Heat.
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
	return round(heat / divisor)
end

-- Creation test
ModUtil.BaseOverride("CreateConsumableItemFromData", 
function( consumableId, consumableItem, costOverride, args )
	--mine
	local multiplier = ResourcesScaleWithHeat.Config.Multiplier
	local divisor = ResourcesScaleWithHeat.Config.Divisor
	local currentHeat = GetTotalSpentShrinePoints()
	local metaPointsPercentage = multiplier.Darkness * currentHeat
	local gemsPercentage =  multiplier.Gems * currentHeat
	local lockKeyBonus = CalculateBonus(currentHeat, divisor.Keys)
	local giftPointsBonus = CalculateBonus(currentHeat, divisor.Nectar)
	local SuperLockKeyMultiplier = CalculateBonus(currentHeat, divisor.Blood)
	local SuperGiftPointsMultiplier = CalculateBonus(currentHeat, divisor.Ambrosia)
	local SuperGemsMultiplier = CalculateBonus(currentHeat, divisor.Diamond)
	local printString = ""
	local printId = consumableId
	--endmine

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

	-- Standard
	if consumableItem.AddResources ~= nil then
		if consumableItem.AddResources.MetaPoints ~= nil then
			ModUtil.Hades.
		  	consumableItem.AddResources.MetaPoints = round( consumableItem.AddResources.MetaPoints * (CalculateMetaPointMultiplier() + metaPointsPercentage) )
		  	printString = ("+" .. (metaPointsPercentage * 100) .. "% {!Icons.MetaPoint_Small} from {!Icons.ShrinePointSmall_Active} bonus!")
		end
		if consumableItem.AddResources.Gems ~= nil then
			consumableItem.AddResources.Gems = round( consumableItem.AddResources.Gems * ( GetTotalHeroTraitValue( "GemMultiplier", { IsMultiplier = true } ) + gemsPercentage ) )
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
			consumableItem.AddResources.SuperLockKeys = consumableItem.AddResources.SuperLockKeys + SuperLockKeyMultiplier
		  -- Print conditions
		  	if SuperLockKeyMultiplier > 0 then
			 	printString = ("+" .. SuperLockKeyMultiplier .. " {!Icons.SuperLockKeySmall} from {!Icons.ShrinePointSmall_Active} bonus!")
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
			consumableItem.AddResources.SuperGiftPoints = consumableItem.AddResources.SuperGiftPoints + SuperGiftPointsMultiplier
		  -- Print Conditions
		  	if SuperGiftPointsMultiplier > 0 then
			  	printString = ("+" .. SuperGiftPointsMultiplier .. " {!Icons.SuperGiftPointSmall} from {!Icons.ShrinePointSmall_Active} bonus!")
		  	end
		end
		if consumableItem.AddResources.SuperGems ~= nil then
			consumableItem.AddResources.SuperGems = consumableItem.AddResources.SuperGems + SuperGemsMultiplier
			if SuperGemsMultiplier > 0 then
				printString = ("+" .. SuperGemsMultiplier .. " {!Icons.SuperGemSmall} from {!Icons.ShrinePointSmall_Active} bonus!")
			end
		end
	  end

	UpdateCostText( consumableItem )

	ModUtil.Hades.PrintOverhead(printString, 3, Color.White, printId)

	return consumableItem
  end
  )