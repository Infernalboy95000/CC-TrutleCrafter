-- Welcome to Turtle Crafter! [This program is the server]
-- Made by Infernal_Ekoro
-- Github page: https://github.com/Infernalboy95000
-----------------------------------

local modem = peripheral.find("modem") or error("This needs a modem", 0)
local items = peripheral.find("informative_registry") or error ("This needs an informative registry", 0)
local recipies = peripheral.find("recipe_registry") or error ("This needs a recipe registry", 0)

local allCraftableItems = {}

local protocol = "CRAFTER_CC"

function GetAllCraftables()
	print("Loading all craftables...")
	local recipes = {}
	local checks = {}
	local duplicates = {}

	local describedItem = {}
	local duplicatedDisplayNames = false

	for _, item in pairs(items.list("item")) do
		if (item ~= "minecraft:air") then
			recipes = recipies.getRecipesFor(item, "minecraft:crafting")

			if (next(recipes) ~= nil) then
				describedItem = DescribeItemNameSimple(item)
				table.insert(allCraftableItems, describedItem)

				if (checks[describedItem["displayName"]] == nil) then
					checks[describedItem["displayName"]] = #allCraftableItems
				else
					duplicates[checks[describedItem["displayName"]]] = allCraftableItems[checks[describedItem["displayName"]]]
					duplicates[#allCraftableItems] = describedItem
					duplicatedDisplayNames = true
				end
			end
		end
	end

	if (duplicatedDisplayNames) then
		print("Found duplicated display names! Fixing...")

		local fixedDisplayName = ""
		for key, value in pairs(duplicates) do
			fixedDisplayName = value["displayName"] .. " [" .. value["name"] .. "]"
			allCraftableItems[key]["displayName"] = fixedDisplayName
		end
	end
end

function DescribeItemNameSimple(itemName)
	local itemData = {}
	local itemDetails = items.describe("item", itemName)

	itemData["displayName"] = itemDetails["displayName"]
	itemData["name"] = itemName

	return itemData
end

function DescribeItemName(itemName)
	local itemData = DescribeItemNameSimple(itemName)
	itemData["slot"] = {}

	return itemData
end

function DescribeItemTag(itemTag)
	local tagData = {}
	
	tagData["displayName"] = "#" .. itemTag
	tagData["tag"] = itemTag
	tagData["slot"] = {}

	return tagData
end

function ConvertSlot(slotNum, width)
	if width == 1 then
		if slotNum == 1 then return 1
		elseif slotNum == 2 then return 5
		elseif slotNum == 3 then return 9
		end
	elseif width == 2 then
		if slotNum <= 2 then return slotNum
		elseif slotNum == 3 then return 5
		elseif slotNum == 4 then return 6
		elseif slotNum == 5 then return 9
		elseif slotNum == 6 then return 10
		end
	elseif width == 3 then
		if slotNum <= 3 then return slotNum
		elseif slotNum == 4 then return 5
		elseif slotNum == 5 then return 6
		elseif slotNum == 6 then return 7
		elseif slotNum == 7 then return 9
		elseif slotNum == 8 then return 10
		elseif slotNum == 9 then return 11
		end
	end
end

function FillRecipeInput(recipe)
	local inputData = {}
	local inputs = {}
	local width = 1
	local slotNum = 1
	local key = ""

	if (recipe["extra"] == nil) then
		if (#recipe["input"] > 1) then
			width = 3
		end
	else
		width = recipe["extra"]["width"]
	end

	for _,v in pairs(recipe["input"]) do
		if v["type"] == nil or v["type"] ~= "empty" then
			if v["item"] ~= nil then
				key = v["item"]
			elseif v["tag"] ~= nil then
				key = v["tag"]
			end

			if v["item"] ~= nil and inputs[v["item"]] == nil then
				inputs[key] = DescribeItemName(key)
			elseif v["tag"] ~= nil and inputs[v["tag"]] == nil then
				inputs[key] = DescribeItemTag(key)
			end

			table.insert(inputs[key]["slot"], ConvertSlot(slotNum, width))
		end

		slotNum = slotNum + 1
	end

	for _,v in pairs(inputs) do
		table.insert(inputData, v)
	end

	return inputData
end

function FillRecipeOutput(recipe)
	local outputData = {}

	for k,v in pairs(recipe["output"][1]) do
		if k == "name" then outputData["name"] = v
		elseif k == "displayName" then outputData["displayName"] = v
		elseif k == "count" then outputData["count"] = v
		end
	end

	return outputData
end

function TransformRecipe(recipe)
	local newRecipe = {}
	
	newRecipe["input"] = FillRecipeInput(recipe)
	newRecipe["output"] = FillRecipeOutput(recipe)

	return newRecipe
end

function WriteRecipe(recipe, fileName)
	local newRecipe = {}
	
	newRecipe["input"] = FillRecipeInput(recipe)
	newRecipe["output"] = FillRecipeOutput(recipe)

	local file = fs.open(fileName, "w")
	file.write(textutils.serialize(newRecipe, { compact = false, allow_repetitions = true }))
	file.close()
end

function WriteRecipeRaw(recipe, fileName)
	local file = fs.open(fileName, "w")
	file.write(textutils.serialize(recipe, { compact = false, allow_repetitions = true }))
	file.close()
end

function GetRecipies(itemName)
	local itemRecipies = {}
	local itemRecipiesBase = recipies.getRecipesFor(itemName, "minecraft:crafting")

	for _, value in ipairs(itemRecipiesBase) do
		if (next(value["input"]) ~= nil) then
			table.insert(itemRecipies, TransformRecipe(value))
		end
	end
	return itemRecipies
end

function ListenClients()
	print("Listening to computers...")
	while true do
		term.setCursorPos(1, 10)
		local id, message = rednet.receive(protocol)
		term.setCursorPos(1, 5)
		term.clearLine()
		print("Recived message: ")
		print(message)
		print("from computer's id: " .. id)
		os.sleep(0.1)

		if (message == "CONN_REQ") then
			rednet.send(id, "CONN", protocol)
		elseif (message == "CRAFTS_REQ") then
			rednet.send(id, allCraftableItems, protocol)
		elseif (string.find(message, "RECIPE_")) then
			local separatorPos, _ = string.find(message, "_")
			local itemRequested = string.sub(message, separatorPos + 1)
			rednet.send(id, GetRecipies(itemRequested), protocol)
		end
	end
end

term.clear()
term.setCursorPos(1, 1)

GetAllCraftables()

peripheral.find("modem", rednet.open)
parallel.waitForAll(ListenClients)
