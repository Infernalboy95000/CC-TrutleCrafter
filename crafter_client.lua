-- Welcome to Turtle Crafter! [This program is the client]
-- Made by Infernal_Ekoro
-- Github page: https://github.com/Infernalboy95000
-----------------------------------

-----------------------------------
-- CRAFTER PROGRAM!
-----------------------------------

local menus = {"itemSelection", "recipeSelection", "recipeConfig", "crafterDisplay"}
local sides = {"right", "left", "front", "back", "top", "bottom"}
local suckSides = {"front", "top", "bottom"}
local statsMode = {"operation", "item", "machine"}
local defaultSettings = { ["reserveOneItem"] = true }
local statsCurrentMode = statsMode[1]

local recipeFile = "recipe.txt"
local statsFile = "stats.txt"
local settingsFile = "settings.txt"
local currentMenu = menus[1]

local invalidSlots = {4, 8, 12, 13, 14, 15}
local selectedRecipe = {}
local selectedSettings = {}

local data = {}
local stats = {}
local crafterSettings = {}

local inputs = {}
local output = {}
local trash = {}
local recipeCraft = 0

local hasModem = false
local crafterRunning, crafterRestart, crafterOn, programOn = false, false, false, false
local crafterStatus = {}

local minutesPerOperation = false
local minutesPerCraft = 0
local craftsPerMinute = 0

local craftTimeStarted = 0
local craftTimeEnded = 0
local crfatTime = 0

local cursorPosY, cursorPosX = 1, 1

-- HOLY MOTHER OF FUNCTION TO COPY A TABLE!
-- Page got it from: https://gist.github.com/cpeosphoros/0aa286c6b39c1e452d9aa15d7537ac95
-- Visit their Github: https://github.com/cpeosphoros
-- And their gist Github: https://gist.github.com/cpeosphoros
local function deepCopy(value, cache, promises, copies)
	cache    = cache    or {}
	promises = promises or {}
	copies   = copies   or {}
	local copy
    if type(value) == 'table' then
		if(cache[value]) then
			copy = cache[value]
		else
			promises[value] = promises[value] or {}
			copy = {}
			for k, v in next, value, nil do
				local nKey   = promises[k] or deepCopy(k, cache, promises, copies)
				local nValue = promises[v] or deepCopy(v, cache, promises, copies)
				copies[nKey]   = type(k) == "table" and k or nil
				copies[nValue] = type(v) == "table" and v or nil
				copy[nKey] = nValue
			end
			local mt = getmetatable(value)
			if mt then
				setmetatable(copy, mt.__immutable and mt or deepCopy(mt, cache, promises, copies))
			end
			cache[value]    = copy
		end
    else -- number, string, boolean, etc
        copy = value
    end
	for k, v in pairs(copies) do
		if k == cache[v] then
			copies[k] = nil
		end
	end
	local function correctRec(tbl)
		if type(tbl) ~= "table" then return tbl end
		if copies[tbl] and cache[copies[tbl]] then
			return cache[copies[tbl]]
		end
		local new = {}
		for k, v in pairs(tbl) do
			local oldK = k
			k, v = correctRec(k), correctRec(v)
			if k ~= oldK then
				tbl[oldK] = nil
				new[k] = v
			else
				tbl[k] = v
			end
		end
		for k, v in pairs(new) do
			tbl[k] = v
		end
		return tbl
	end
	correctRec(copy)
    return copy
end

local function loadFile(name)
	local file = fs.open(name,"r")
	local data = file.readAll()
	file.close()
	return textutils.unserialize(data)
end

local function saveFile(table,name)
	local file = fs.open(name,"w")
	file.write(textutils.serialize(table))
	file.close()
end

local function tableCount(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

local function firstToUpper(str)
	return (str:gsub("^%l", string.upper))
end

local function round(num, decimalPlaces)
    local mult = 10^(decimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function isType(side, ...)
	local typeFound = false
	local args = {...}
	local sidePeripheral = nil
	
	if (type(side) == "table") then
		sidePeripheral = peripheral.getName(side)
	else
		sidePeripheral = side
	end
	
	if (peripheral.isPresent(sidePeripheral)) then
		for _, argType in pairs(args) do
			local type1, type2 = peripheral.getType(sidePeripheral)
			
			if ((type1 == argType) or (type2 == argType)) then
				typeFound = true
			end
		end
	end
	
	return typeFound
end

local function findItemSlotFrom(name, chest)
	local inputSlot = -1
	
	if (isType(chest, "inventory")) then
		for slot, item in pairs(chest.list()) do
			if (inputSlot == -1 and item.name == name) then
				inputSlot = slot
			end
		end
	end
	
	return inputSlot
end

local function itemHasTag(itemInfo, tag)
	local hasTag = false
	if (itemInfo["tags"] ~= nil) then
		for itemTag, _ in pairs(itemInfo["tags"]) do
			if (not hasTag and itemTag == tag) then
				hasTag = true
			end
		end
	end

	return hasTag
end

local function slotHasTag(slot, tag, chest)
	local slotDetail = chest.getItemDetail(slot)

	return itemHasTag(slotDetail, tag)
end

local function findItemTagSlotFrom(tag, chest)
	local inputSlot = -1
	
	if (isType(chest, "inventory")) then
		for slot, _ in pairs(chest.list()) do
			if (inputSlot == -1 and slotHasTag(slot, tag, chest)) then
				inputSlot = slot
			end
		end
	end
	
	return inputSlot
end

local function searchItemWithTag(tag, storage)
	local item = "minecraft:air"

	if (isType(storage "item_storage")) then
		local allItems = storage.items()

		for _, value in pairs(allItems) do
			if (itemHasTag(value, tag)) then
				return value["name"]
			end
		end
	end

	return item
end

local function searchItemInfo(name, storage)
	local itemInfo = {}

	if (isType(storage "item_storage")) then
		local allItems = storage.items()

		for _, value in pairs(allItems) do
			if (value["name"] == name) then
				return value
			end
		end
	end

	return itemInfo
end

local function transferItem(item, inputStorage, outputStorage, ammount, reserveOne)
	local transfered = 0
	local slot = -1
	local itemName = ""
	local itemsStored = 0
	local inputName = peripheral.getName(inputStorage)
	local outputName = peripheral.getName(outputStorage)
	
	if (isType(inputStorage, "inventory")) then
		if (item["name"] ~= nil) then
			slot = findItemSlotFrom(item["name"], inputStorage)
		elseif (item["tag"] ~= nil) then
			slot = findItemTagSlotFrom(item["tag"], inputStorage)
		end

		if (slot > -1 and reserveOne) then
			itemsStored = inputStorage.getItemDetail(slot).count
			if (itemsStored < ammount + 1) then
				ammount = itemsStored - 1
			end
		end
		
		if (slot > -1) then
			if (isType(outputStorage, "inventory")) then
				transfered = inputStorage.pushItems(outputName, slot, ammount)
			else
				if (item["tag"] ~= nil) then
					itemName = searchItemWithTag(item["tag"], inputStorage)
				else
					itemName = item["name"]
				end
				transfered = outputStorage.pullItem(inputName, itemName, ammount)
			end
		end
	else
		if (item["tag"] ~= nil) then
			itemName = searchItemWithTag(item["tag"], inputStorage)
		else
			itemName = item["name"]
		end

		if (reserveOne) then
			local itemInfo = searchItemInfo(itemName, inputStorage)
			if (itemInfo["count"] ~= nil) then
				itemsStored = itemInfo["count"]
				if (itemsStored < ammount + 1) then
					ammount = itemsStored - 1
				end
			end
		end

		transfered = inputStorage.pushItem(outputName, itemName, ammount)
	end
	
	return transfered
end

local function transferInventory(input, output)
	local itemsList = {}
	
	if (isType(input, "inventory")) then
		itemsList = input.list()
	else
		itemsList = input.items()
	end
	
	for _, item in pairs(itemsList) do
		transferItem(item, input, output, 64, false)
	end
end

local function getItem(item)
	local input = inputs[item["side"]]
	local ammount = tableCount(item["slot"])
	local totalNeeded = ammount
	local totalTransfered = 0
	local transfered = 0

	while (ammount > 0) do
		transfered = transferItem(item, input, output, ammount, crafterSettings["reserveOneItem"])

		ammount = ammount - transfered
		totalTransfered = totalTransfered + transfered

		if (transfered <= 0) then
			crafterStatus[1] = "Item not found! Waiting..."
			crafterStatus[3] = "Progress: [" .. totalTransfered .. "/" .. totalNeeded ..  "]"
			sleep(1)
		else
			crafterStatus[1] = "Getting item..."
			crafterStatus[3] = "Progress: [" .. totalTransfered .. "/" .. totalNeeded ..  "]"
		end
	end
end

local function hasStuff(chest)
	local hasItems = false
	local itemsList = {}
	
	if (isType(chest, "inventory")) then
		itemsList = chest.list()
	else
		itemsList = chest.items()
	end
	
	for _, item in pairs(itemsList) do
		hasItems = true
	end
	
	return hasItems
end

local function dropSelectedToTrash()
	if (data["trash"]["side"] == "front") then
		turtle.drop()
	elseif (data["trash"]["side"] == "bottom") then
		turtle.dropDown()
	elseif (data["trash"]["side"] == "top") then
		turtle.dropUp()
	end
end

local function dropSelectedToOutput()
	if (data["output"]["side"] == "front") then
		turtle.drop()
	elseif (data["output"]["side"] == "bottom") then
		turtle.dropDown()
	elseif (data["output"]["side"] == "top") then
		turtle.dropUp()
	end
end

local function placeItemToGrid(item)
	local ammount = tableCount(item["slot"])
	local currentAmmount = 0
	local itemsSucked = 0
	local itemsTransfered = 0
	local turtleItem = {}

	while currentAmmount < ammount do
		turtle.select(16)
		turtle.suck()
		itemsSucked = turtle.getItemCount()

		crafterStatus[1] = "Placing item to crafting grid..."
		crafterStatus[3] = "Progress: [" .. itemsTransfered .. "/" .. ammount ..  "]"

		if (itemsSucked > 0) then
			currentAmmount = currentAmmount + itemsSucked

			if (item["name"] ~= nil) then
				turtleItem = turtle.getItemDetail(16)
			elseif (item["tag"] ~= nil) then
				turtleItem = turtle.getItemDetail(16, true)
			end
		else
			turtleItem = {name = "empty", tag = "empty"}
		end

		if (item["name"] ~= nil) then
			if (turtleItem["name"] == item["name"]) then
				for i = 1, currentAmmount, 1 do
					turtle.transferTo(item["slot"][i], 1)
					itemsTransfered = itemsTransfered + 1
					crafterStatus[3] = "Progress: [" .. itemsTransfered .. "/" .. ammount ..  "]"
				end
			end
		elseif (item["tag"] ~= nil) then
			if (itemHasTag(turtleItem, item["tag"])) then
				for i = 1, currentAmmount, 1 do
					turtle.transferTo(item["slot"][i], 1)
					itemsTransfered = itemsTransfered + 1
					crafterStatus[3] = "Progress: [" .. itemsTransfered .. "/" .. ammount ..  "]"
				end
			end
		end

		if (turtle.getItemCount() > 0) then
			crafterStatus[1] = "Got unknown item. Placing in the trash."
			dropSelectedToTrash()
		end
	end
end

local function increaseStats(craftedItems)
	for i = 1, #statsMode, 1 do
		if stats[statsMode[i]] == nil or next(stats[statsMode[i]]) == nil then
			stats[statsMode[i]] = {}
		end

		if statsMode[i] == statsMode[2] then
			if stats[statsMode[i]][data["output"]["name"]] == nil then
				stats[statsMode[i]][data["output"]["name"]] = {}
				stats[statsMode[i]][data["output"]["name"]]["Crafts"] = 1
			elseif stats[statsMode[i]][data["output"]["name"]]["Crafts"] == nil then
				stats[statsMode[i]][data["output"]["name"]]["Crafts"] = 1
			else
				stats[statsMode[i]][data["output"]["name"]]["Crafts"] = stats[statsMode[i]][data["output"]["name"]]["Crafts"] + 1
			end
	
			if stats[statsMode[i]][data["output"]["name"]] == nil then
				stats[statsMode[i]][data["output"]["name"]] = {}
				stats[statsMode[i]][data["output"]["name"]]["Items"] = craftedItems
			elseif stats[statsMode[i]][data["output"]["name"]]["Items"] == nil then
				stats[statsMode[i]][data["output"]["name"]]["Items"] = craftedItems
			else
				stats[statsMode[i]][data["output"]["name"]]["Items"] = stats[statsMode[i]][data["output"]["name"]]["Items"] + craftedItems
			end
		else
			if stats[statsMode[i]]["Crafts"] == nil then
				stats[statsMode[i]]["Crafts"] = 1
			else
				stats[statsMode[i]]["Crafts"] = stats[statsMode[i]]["Crafts"] + 1
			end
	
			if stats[statsMode[i]]["Items"] == nil then
				stats[statsMode[i]]["Items"] = craftedItems
			else
				stats[statsMode[i]]["Items"] = stats[statsMode[i]]["Items"] + craftedItems
			end
		end
	end
	saveFile(stats, statsFile)
end

local function checkStatsFile()
	if stats == nil or next(stats) == nil then
		stats = {}
	end

	for i = 1, #statsMode, 1 do
		if stats[statsMode[i]] == nil or next(stats[statsMode[i]]) == nil then
			stats[statsMode[i]] = {}
		end

		if statsMode[i] == statsMode[2] then
			if stats[statsMode[i]][data["output"]["name"]] == nil then
				stats[statsMode[i]][data["output"]["name"]] = {}
			end

			if stats[statsMode[i]][data["output"]["name"]]["Crafts"] == nil then
				stats[statsMode[i]][data["output"]["name"]]["Crafts"] = 0
			end

			if stats[statsMode[i]][data["output"]["name"]]["Items"] == nil then
				stats[statsMode[i]][data["output"]["name"]]["Items"] = 0
			end
		else
			if stats[statsMode[i]]["Crafts"] == nil then
				stats[statsMode[i]]["Crafts"] = 0
			end
	
			if stats[statsMode[i]]["Items"] == nil then
				stats[statsMode[i]]["Items"] = 0
			end
		end
	end
	saveFile(stats, statsFile)
end

local function calculateCraftsPerMinute()
	crfatTime = (craftTimeEnded - craftTimeStarted) / 1000
	craftsPerMinute = 60 / crfatTime

	if craftsPerMinute < 1 then
		minutesPerCraft = crfatTime / 60
		minutesPerOperation = true
	else
		minutesPerOperation = false
	end
end

local function craftItem()
	local success = false
	local failReason = ""
	local craftedItems = 0

	turtle.select(16)
	if (turtle.getItemCount() > 0) then
		dropSelectedToTrash()
	end

	success, failReason = turtle.craft()

	if (success) then
		craftTimeEnded = os.epoch("utc")
		calculateCraftsPerMinute()
		craftTimeStarted = os.epoch("utc")
		craftedItems = turtle.getItemCount()
		if (recipeCraft == 0) then
			recipeCraft = craftedItems
		end

		increaseStats(craftedItems)
		dropSelectedToOutput()
	else
		crafterStatus[1] = "Unable to craft the item!"
		crafterStatus[2] = "Failed crafting!"
		crafterStatus[3] = failReason
	end

	return success
end

local function dumbAll()
	crafterStatus[1] = "Dumbing items to the trash"
	local turtleItem = {}
	for i = 1, 16, 1 do
		turtle.select(i)
		if (turtle.getItemCount() > 0) then
			turtleItem = turtle.getItemDetail()
			if (turtleItem["name"] == data["output"]["name"]) then
				dropSelectedToOutput()
			else
				dropSelectedToTrash()
			end
		end
	end
end

local function drawCrafterBottomMenu()
	term.setBackgroundColor(colors.blue)
	term.setCursorPos(1, 13)
	term.clearLine()

	if cursorPosY == 1 and cursorPosX == 2 and not hasModem then
		cursorPosX = 1
	end

	if cursorPosY == 1 and cursorPosX == 3 and not hasModem then
		cursorPosX = 4
	end

	if cursorPosY == 1 and cursorPosX == 1 then
		term.setBackgroundColor(colors.purple)
	else
		term.setBackgroundColor(colors.blue)
	end
	
	if crafterRunning then
		term.write("STOP!!")
	else
		term.write("RESUME")
	end

	if cursorPosY == 1 and cursorPosX == 2 then
		term.setBackgroundColor(colors.purple)
	else
		term.setBackgroundColor(colors.blue)
	end

	if hasModem then
		term.setTextColor(colors.white)
	else
		term.setTextColor(colors.gray)
	end

	term.setCursorPos(9, 13)
	term.write("SET ITEM")

	if cursorPosY == 1 and cursorPosX == 3 then
		term.setBackgroundColor(colors.purple)
	else
		term.setBackgroundColor(colors.blue)
	end
	
	if hasModem then
		term.setTextColor(colors.white)
	else
		term.setTextColor(colors.gray)
	end
	term.setCursorPos(20, 13)
	term.write("SET RECIPE")

	if cursorPosY == 1 and cursorPosX == 4 then
		term.setBackgroundColor(colors.purple)
	else
		term.setBackgroundColor(colors.blue)
	end
	
	term.setTextColor(colors.white)
	term.setCursorPos(32, 13)
	term.write("SETTINGS")

	if cursorPosY == 2 then
		term.setBackgroundColor(colors.purple)
	else
		term.setBackgroundColor(colors.blue)
	end
	term.setCursorPos(24, 12)
	term.write("CYCLE STATS MODE")
end

local function drawCrafterMenu()
	while crafterOn do
		term.setBackgroundColor(colors.gray)
		term.setTextColor(colors.black)
		term.clear()
		
		term.setBackgroundColor(colors.lightBlue)
		term.setCursorPos(1, 1)
		term.clearLine()
		term.write("Crafting: " .. data["output"]["displayName"])

		term.setCursorPos(1, 2)
		term.clearLine()
		term.write("From: " .. string.sub(data["output"]["name"], 1, string.find(data["output"]["name"], ':', 1, true) - 1))

		term.setBackgroundColor(colors.gray)
		term.setTextColor(colors.white)
		term.setCursorPos(1, 3)
		if crafterRunning then
			term.write("Status: Operational")
		else
			term.write("Status: Stopped!")
		end

		for i = 1, #crafterStatus, 1 do
			term.setCursorPos(1, i + 3)
			term.write(crafterStatus[i])
		end

		term.setTextColor(colors.white)
		term.setCursorPos(1, 8)
		if minutesPerOperation then
			term.write("Minutes/Craft: " .. round(minutesPerCraft, 2))
		else
			term.write("Crafts/Min: " .. round(craftsPerMinute, 2))
		end

		term.setBackgroundColor(colors.green)
		term.setTextColor(colors.black)
		term.setCursorPos(1, 9)
		term.write(firstToUpper(statsCurrentMode) .. " stats")

		term.setBackgroundColor(colors.gray)
		term.setTextColor(colors.lightBlue)
		term.setCursorPos(1, 10)
		if statsCurrentMode == statsMode[2] then
			term.write("Crafts: " .. stats[statsCurrentMode][data["output"]["name"]]["Crafts"])
		else
			term.write("Crafts: " .. stats[statsCurrentMode]["Crafts"])
		end

		term.setCursorPos(1, 11)
		if statsCurrentMode == statsMode[2] then
			term.write("Items crafted: " .. stats[statsCurrentMode][data["output"]["name"]]["Items"])
		else
			term.write("Items crafted: " .. stats[statsCurrentMode]["Items"])
		end

		term.setTextColor(colors.white)
		drawCrafterBottomMenu()
		sleep(0.05)
	end
end

local function turnOnCrafter()
	while crafterOn and crafterRunning do
		dumbAll()

		craftTimeStarted = os.epoch("utc")
		crafterStatus[2] = nil
		while (findItemSlotFrom(data["output"]["name"], output) > 0) do
			crafterStatus[1] = "Some crafted items piled up"
			crafterStatus[2] = "Waiting..."
			sleep(1)
		end

		if (hasStuff(output)) then
			crafterStatus[1] = "Some items found on output chest"
			crafterStatus[2] = "Dumping in trash..."
			transferInventory(output, trash)
		end

		for _,item in pairs(data["input"]) do
			crafterStatus[1] = "Getting item..."
			crafterStatus[2] = item["displayName"]
			getItem(item)
			placeItemToGrid(item)
		end
		crafterStatus[1] = "Crafting item..."
		crafterStatus[2] = nil
		crafterStatus[3] = nil

		if not craftItem() then
			dumbAll()
		end
	end
end


-----------------------------------
-- RECIPE SELECTOR!
-----------------------------------
local protocol = "CRAFTER_CC"
local modem = {}
local sendPort = nil

local maxRetrires = 10
local timeWait = 3

local slotColors =
{
	colors.orange,
	colors.magenta,
	colors.lime,
	colors.pink,
	colors.brown,
	colors.lightGray,
	colors.cyan,
	colors.blue,
	colors.red,
}

local slotSymbols =
{
	'.',
	':',
	'"',
	'~',
	'-',
	'|',
	'^',
	'*',
	'='
}

local bottomMenu =
{
	"RETURN",
	"<- PREV",
	"NEXT ->",
	"SELECT"
}

local printPosition, currentPosition = 1, 1
local changedSelection, searchChanged, confirmSelection, lockedUp = false, false, false, false
local showCrafterMenu, oneRecipeMessageRequest = false, false
local keyPressed, charPressed = nil, nil
local writtenSearch = ""
local selectedItemRecipes = {}
local craftableItemsList = {}
local searchedItemsList = {}
local listLimit = 0
local recipesAmmount = 1
local onScreenItemsList = {}
local lastXPos = 1


local function messageTheServer(message, expectedAnswer)
	local success = false
	local retries = 0
	local id, messageReceived

	while retries < maxRetrires and not success do
		if (sendPort == nil) then
			rednet.broadcast(message, protocol)
		else
			rednet.send(sendPort, message, protocol)
		end
		id, messageReceived = rednet.receive(timeWait)

		if (id ~= nil and (expectedAnswer == nil or messageReceived == expectedAnswer)) then
			success = true
		else
			retries = retries + 1
		end
	end

	return success, id, messageReceived
end

local function peripheralDeatatchListen()
	_, _ = os.pullEvent("peripheral_detach")
end

local function peripheralAttachListen()
	_, _ = os.pullEvent("peripheral")
end

local function keyboardListen()
	keyPressed = nil
	_, keyPressed, _ = os.pullEvent("key")
end

local function characterListen()
	charPressed = nil
	_, charPressed, _ = os.pullEvent("char")
end

local function configTopMenu(message)
	term.setBackgroundColor(colors.lightBlue)
	term.setTextColor(colors.black)
	term.clearLine()
	term.write(message)
	term.setTextColor(colors.white)
end

local function recipeConfigMenu()
	term.setCursorPos(1, 2)
	lockedUp = false

	if (cursorPosY == 2) then
		term.setBackgroundColor(colors.purple)
	else
		term.setBackgroundColor(colors.gray)
	end
	term.clearLine()
	term.write("Reserve one item on each slot -> " .. firstToUpper(tostring(selectedSettings["reserveOneItem"])))

	term.setBackgroundColor(colors.gray)
	term.setCursorPos(1, 3)
	term.clearLine()
	local sharing = false
	local noWorkbench = false
	local sharingWithWorkbench = false
	local sharingWithTrash = false
	local sharingWithOutput = false
	local outputNoStorage = false
	local trashNoStorage = false
	local notStorage = false
	local oneRecipeMessageShowUp = false

	if selectedRecipe["output"]["side"] == selectedRecipe["trash"]["side"] then
		sharing = true
		lockedUp = true
	elseif not isType(selectedRecipe["output"]["side"], "inventory", "item_storage") then
		outputNoStorage = true
		lockedUp = true
	end

	if (cursorPosY == 3 and cursorPosX == 1) then
		term.setBackgroundColor(colors.purple)
	elseif sharing or outputNoStorage then
		term.setBackgroundColor(colors.red)
	else
		term.setBackgroundColor(colors.gray)
	end

	if sharing or outputNoStorage then
		term.setTextColor(colors.black)
	else
		term.setTextColor(colors.white)
	end

	term.write("Output -> " .. firstToUpper(selectedRecipe["output"]["side"]))
	term.setCursorPos(25, 3)

	if not isType(selectedRecipe["trash"]["side"], "inventory", "item_storage") then
		trashNoStorage = true
		lockedUp = true
	end

	if (cursorPosY == 3 and cursorPosX == 2) then
		term.setBackgroundColor(colors.purple)
	elseif sharing or trashNoStorage then
		term.setBackgroundColor(colors.red)
	else
		term.setBackgroundColor(colors.gray)
	end

	if sharing or trashNoStorage then
		term.setTextColor(colors.black)
	else
		term.setTextColor(colors.white)
	end

	term.write("Trash -> " .. firstToUpper(selectedRecipe["trash"]["side"]))
	term.setTextColor(colors.white)
	
	if not isType("right", "workbench") and not isType("left", "workbench") then
		noWorkbench = true
		lockedUp = true
	end

	for key, value in ipairs(selectedRecipe["input"]) do
		
		term.setCursorPos(1, key + 3)
		local trashShare = false
		local outputShare = false
		local workbenchShare = false
		local storageLack = false
		local messedUp = false

		if selectedRecipe["input"][key]["side"] == selectedRecipe["trash"]["side"] then
			sharingWithTrash = true
			trashShare = true
			lockedUp = true
			messedUp = true
		elseif selectedRecipe["input"][key]["side"] == selectedRecipe["output"]["side"] then
			sharingWithOutput = true
			outputShare = true
			lockedUp = true
			messedUp = true
		elseif isType(selectedRecipe["input"][key]["side"], "workbench") then
			sharingWithWorkbench = true
			workbenchShare = true
			lockedUp = true
			messedUp = true
		elseif (not isType(selectedRecipe["input"][key]["side"], "inventory", "item_storage")) then
			notStorage = true
			storageLack = true
			lockedUp = true
			messedUp = true
		end

		if (cursorPosY == key + 3) then
			term.setBackgroundColor(colors.purple)
		elseif messedUp then
			term.setBackgroundColor(colors.red)
		else
			term.setBackgroundColor(colors.gray)
		end

		term.clearLine()
		term.write("Item " .. key .. " ")
		term.setCursorPos(8, key + 3)
		if trashShare then
			term.setTextColor(colors.black)
			term.write("Sharing with trash!")
		elseif outputShare then
			term.setTextColor(colors.black)
			term.write("Sharing with output!")
		elseif workbenchShare then
			term.setTextColor(colors.black)
			term.write("Sharing with workbench!")
		elseif storageLack then
			term.setTextColor(colors.black)
			term.write("Side without storage!")
		else
			term.setTextColor(colors.white)
			term.write(value["displayName"])
		end
		term.setTextColor(colors.white)
		term.setCursorPos(30, key + 3)
		term.write(" -> " .. firstToUpper(selectedRecipe["input"][key]["side"]))
	end

	term.setCursorPos(1, 1)
	if lockedUp then
		term.setBackgroundColor(colors.red)
		term.setTextColor(colors.black)
		term.clearLine()
		if sharing then
			term.write("Sharing output side with trash side!")
		elseif sharingWithTrash then
			term.write("Sharing input sides with trash side!")
		elseif sharingWithOutput then
			term.write("Sharing input sides with output side!")
		elseif outputNoStorage then
			term.write("Output side has no storage!")
		elseif trashNoStorage then
			term.write("Trash side has no storage!")
		elseif noWorkbench then
			term.write("No workbench found!")
		elseif sharingWithWorkbench then
			term.write("Sharing input sides with the workbench!")
		elseif notStorage then
			term.write("Some sides have no storage!")
		end
		term.setTextColor(colors.white)
	elseif oneRecipeMessageRequest and not oneRecipeMessageShowUp then
		oneRecipeMessageRequest = false
		oneRecipeMessageShowUp = false
		term.setBackgroundColor(colors.green)
		term.setTextColor(colors.black)
		term.clearLine()
		term.write("This item has only one recipe")
		term.setTextColor(colors.white)
	else
		configTopMenu("Configure inputs/outputs")
	end
end

local function configBottomMenu()
	term.setBackgroundColor(colors.blue)
	term.setCursorPos(1, 13)
	term.clearLine()

	if (cursorPosY == 13 and cursorPosX == 1) then
		term.setBackgroundColor(colors.purple)
	else
		term.setBackgroundColor(colors.blue)
	end
	term.write("<- RETURN")
	term.setCursorPos(30, 13)

	if (cursorPosY == 13 and cursorPosX == 2) then
		term.setBackgroundColor(colors.purple)
	else
		term.setBackgroundColor(colors.blue)
	end

	if lockedUp then
		term.setTextColor(colors.gray)
	end

	term.write("CONFIRM ->")
	term.setTextColor(colors.white)
end

local function configKeysListener()
	local actioned = false
	parallel.waitForAny(keyboardListen, peripheralAttachListen, peripheralDeatatchListen)
	
	if (keyPressed == keys.left and cursorPosX > 1) and (cursorPosY == 3 or cursorPosY == 13) then
		cursorPosX = cursorPosX - 1
		lastXPos = cursorPosX
	elseif (keyPressed == keys.right and cursorPosX < 2) and (cursorPosY == 3 or cursorPosY == 13) then
		cursorPosX = cursorPosX + 1
		lastXPos = cursorPosX
	elseif keyPressed == keys.up and cursorPosY > 2 then
		if (cursorPosY == 13) then
			cursorPosX = lastXPos
			cursorPosY = #selectedRecipe["input"] + 3
		else
			cursorPosY = cursorPosY - 1
		end
	elseif keyPressed == keys.down and cursorPosY < 13 then
		if (cursorPosY == 3) then
			cursorPosX = lastXPos
		end

		if (cursorPosY == #selectedRecipe["input"] + 3) then
			cursorPosY = 13
		else
			cursorPosY = cursorPosY + 1
		end
	elseif keyPressed == keys.enter then
		actioned = true
	end

	return actioned
end

local function nextArrayPosition(array, element)
	local position = 1

	for key, value in ipairs(array) do
		if array[key] == element then
			position = key
			position = position + 1

			if position > #array then
				position = 1
			end
			return position
		end
	end

	return 0
end

local function changeRecipeSettings()
	if cursorPosY == 2 then
		selectedSettings["reserveOneItem"] = not selectedSettings["reserveOneItem"]
	elseif cursorPosY == 3 then
		if cursorPosX == 1 then
			selectedRecipe["output"]["side"] = suckSides[nextArrayPosition(suckSides, selectedRecipe["output"]["side"])]
		elseif cursorPosX == 2 then
			selectedRecipe["trash"]["side"] = suckSides[nextArrayPosition(suckSides, selectedRecipe["trash"]["side"])]
		end
	elseif cursorPosY == 13 then
		if cursorPosX == 1 then
			if recipesAmmount <= 1 then
				currentMenu = menus[1]
			else
				currentMenu = menus[2]
			end
			confirmSelection = true
		elseif cursorPosX == 2 and not lockedUp then
			currentMenu = menus[4]
			confirmSelection = true
		end
	else
		selectedRecipe["input"][cursorPosY - 3]["side"] = sides[nextArrayPosition(sides, selectedRecipe["input"][cursorPosY - 3]["side"])]
	end
end

local function displayRecipeConfigMenu()
	cursorPosX = 2
	cursorPosY = 13
	confirmSelection = false

	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.setCursorPos(1, 1)
	term.clear()

	while not confirmSelection do
		recipeConfigMenu()
		configBottomMenu()

		if configKeysListener() then
			changeRecipeSettings()
		end
	end

	if cursorPosX == 2 then
		return true
	else
		return false
	end
end

local function setupDefaultSides(recipe)
	recipe["trash"] = {}
	recipe["trash"]["side"] = "bottom"
	recipe["output"]["side"] = "front"

	for _, value in pairs(recipe["input"]) do
		value["side"] = "back"
	end

	return recipe
end

local function printBottomMenu()
	term.setBackgroundColor(colors.blue)
	term.setCursorPos(1, 13)
	term.clearLine()

	for i = 1, #bottomMenu, 1 do
		term.setTextColor(colors.white)
		if i == 1 then
			term.setBackgroundColor(colors.red)
		end

		if i == cursorPosX then
			term.setBackgroundColor(colors.purple)
		elseif i > 1 then
			term.setBackgroundColor(colors.blue)
		end
		
		if (i == 2 and currentPosition <= 1) then
			term.setTextColor(colors.gray)
		end
		if (i == 3 and currentPosition >= recipesAmmount) then
			term.setTextColor(colors.gray)
		end

		term.write(bottomMenu[i])
		term.setBackgroundColor(colors.blue)
		term.write(" ")
	end

	term.write("[" .. currentPosition .. "/" .. recipesAmmount .. "]")
end

local function displayRecipeSlotBox(inputId, slot)
	term.setBackgroundColor(slotColors[inputId])
	if (slot < 4) then
		term.setCursorPos(slot, 1)
	elseif (slot < 8) then
		term.setCursorPos(slot - 4, 2)
	elseif (slot <= 12) then
		term.setCursorPos(slot - 8, 3)
	end
	term.write(slotSymbols[inputId])
end

local function displayRecipeOutput(output)
	term.setCursorPos(5, 1)
	configTopMenu("Select a recipe")

	term.setBackgroundColor(colors.gray)
	term.setCursorPos(1, 2)
	term.clearLine();
	term.setCursorPos(1, 3)
	term.clearLine();

	term.setCursorPos(5, 2)
	term.write("Output [x" .. output["count"] .. "]: " .. output["displayName"])
	term.setCursorPos(5, 3)
	term.write("From: " .. string.sub(output["name"], 1, string.find(output["name"], ':', 1, true) - 1))
end

local function displayRecipe(recipe)
	term.setBackgroundColor(colors.black)
	term.clear()
	displayRecipeOutput(recipe["output"])

	term.setBackgroundColor(colors.black)
	term.setCursorPos(1, 1)
	term.write("   ")
	term.setCursorPos(1, 2)
	term.write("   ")
	term.setCursorPos(1, 3)
	term.write("   ")

	for key, input in pairs(recipe["input"]) do
		for _, slot in pairs(input["slot"]) do
			displayRecipeSlotBox(key, slot)
		end
		term.setCursorPos(1, key + 3)
		term.clearLine()
		term.write(slotSymbols[key] .. " " .. input["displayName"])
	end
end

local function moveMenuByKeys()
	local newRecipe = false
	keyboardListen()

	if (keyPressed == keys.left and cursorPosX > 1) then
		cursorPosX = cursorPosX - 1
	elseif (keyPressed == keys.right and cursorPosX < 4) then
		cursorPosX = cursorPosX + 1
	elseif (keyPressed == keys.enter) then
		if (cursorPosX == 2 and currentPosition > 1) then
			currentPosition = currentPosition - 1
			newRecipe = true
		elseif (cursorPosX == 3 and currentPosition < recipesAmmount) then
			currentPosition = currentPosition + 1
			newRecipe = true
		elseif (cursorPosX == 1 or cursorPosX == 4) then
			confirmSelection = true
		end
	end

	return newRecipe
end

local function displayRecipes(recipes)
	local updateRecipe = true
	selectedItemRecipes = recipes
	recipesAmmount = #recipes

	cursorPosX = 3
	currentPosition = 1
	confirmSelection = false

	if recipesAmmount == 1 then
		confirmSelection = true
	end

	while not confirmSelection do
		if (updateRecipe) then
			displayRecipe(recipes[currentPosition])
			updateRecipe = false
		end
		printBottomMenu()
		updateRecipe = moveMenuByKeys()
	end

	if cursorPosX == 1 then
		selectedItemRecipes = {}
		currentMenu = menus[1]
	else
		selectedRecipe = recipes[currentPosition]
		selectedRecipe = setupDefaultSides(selectedRecipe)
		currentMenu = menus[3]
	end
end

local function getItemRecipies(item)
	modem = peripheral.find("modem")
	if (modem == nil) then
		printError(">_< No router found!")
		programOn = false
	else
		peripheral.find("modem", rednet.open)

		print("> Getting recipies for:")
		print(item["displayName"])
		local sendMessage = "RECIPE_" .. item["name"]

		local success, _, message = messageTheServer(sendMessage)

		if (success) then
			term.clear()
			term.setCursorPos(1, 1)
			displayRecipes(message)
		else
			printError(">_< Can't connect to the server!")
			programOn = false
		end
	end
	rednet.close()
end

local function printListSection(itemList, from, max)
	local selection = {}
	local cursorY = 2
	term.setBackgroundColor(colors.gray)
	for i = from, from + max - 1, 1 do
		term.setCursorPos(1, cursorY)
		term.clearLine()
		if (itemList[i] ~= nil) then
			term.write(itemList[i]["displayName"])
			table.insert(selection, itemList[i]["displayName"])
		end

		cursorY = cursorY + 1
	end
	term.setBackgroundColor(colors.black)
	return selection
end

local function highlightItemSelected()
	term.setCursorPos(1, cursorPosY)
	term.setBackgroundColor(colors.purple)
	term.clearLine()
	term.write(onScreenItemsList[cursorPosY - 1])
	term.setCursorPos(cursorPosX, 13)
end

local function highlightItemSelectionCutted(cuttedSelection)
	term.setCursorPos(1, cursorPosY)
	term.setBackgroundColor(colors.purple)
	term.clearLine()
	term.write(cuttedSelection)
	term.setCursorPos(cursorPosX, 13)
end

local function filterList(list, filter)
	local filteredList = {}

	for _, value in ipairs(list) do
		if (string.find(value["displayName"]:lower(), filter:lower(), 1, true)) then
			table.insert(filteredList, value)
		end
	end

	return filteredList
end

local function itemSelectionWidePrinter()
	local printPosition = 1
	local searchLength = 1
	searchLength = 0

	while not confirmSelection do
		if (searchLength > 39 and not changedSelection) then
			printPosition = printPosition + 1
			highlightItemSelectionCutted(string.sub(onScreenItemsList[cursorPosY - 1], printPosition))
			if (searchLength - (printPosition - 1) <= 39) then
				os.sleep(1)
				printPosition = 1
				highlightItemSelectionCutted(string.sub(onScreenItemsList[cursorPosY - 1], printPosition))
				os.sleep(0.3)
			end
			sleep(0.1)
		elseif (changedSelection and onScreenItemsList[cursorPosY - 1] ~= nil) then
			searchLength = string.len(onScreenItemsList[cursorPosY - 1])
			printPosition = 1
			changedSelection = false
			os.sleep(0.3)
		else
			sleep(0.05)
		end
	end
end

local function itemSelectionUpdater()
	local searchTimeoutTime = 0.3
	local searchTimer = 0.0

	while not confirmSelection do
		if (string.len(writtenSearch) <= 0) then
			searchedItemsList = craftableItemsList
			listLimit = #craftableItemsList
		else
			searchedItemsList = filterList(craftableItemsList, writtenSearch)
			listLimit = #searchedItemsList
			printPosition = 1
		end
		onScreenItemsList = printListSection(searchedItemsList, printPosition, 11)
		currentPosition = 1
		cursorPosY = 2
		highlightItemSelected()
		changedSelection = true

		while not searchChanged do
			sleep(0.05)
		end

		while searchTimer < searchTimeoutTime do
			sleep(0.05)
			if (searchChanged) then
				searchChanged = false
				searchTimer = 0.0
			else
				searchTimer = searchTimer + 0.05
			end
		end
		searchTimer = 0.0
	end
end

local function itemSelectionSearcher()
	term.clear()
	term.setCursorPos(1, 1)

	local printedSearch, searchStart, searchEnd  = "", "", ""
	local writtenPos = 1
	local searchLength = 0
	local writeStart = 1
	local write, movedSelection = false, false

	configTopMenu("Select an item to craft")
	onScreenItemsList = printListSection(craftableItemsList, printPosition, 11)
	term.setCursorPos(1, cursorPosY)
	term.setBackgroundColor(colors.cyan)
	term.clearLine()
	term.write(onScreenItemsList[cursorPosY - 1])

	term.setCursorPos(1, 13)
	term.setBackgroundColor(colors.blue)
	term.clearLine()

	while not confirmSelection do
		term.setCursorBlink(true)
		parallel.waitForAny(keyboardListen, characterListen)

		if (charPressed ~= nil) then
			searchStart = string.sub(writtenSearch, 1, writtenPos - 1)
			searchEnd = string.sub(writtenSearch, writtenPos)

			writtenSearch = searchStart .. charPressed .. searchEnd
			writtenPos = writtenPos + 1
			if (searchLength < 38) then
				cursorPosX = cursorPosX + 1
			else
				writeStart = writeStart + 1
			end
			write = true
		elseif (keyPressed ~= nil) then
			if (keyPressed == keys.backspace and writtenPos > 1) then
				searchStart = string.sub(writtenSearch, 1, writtenPos - 1)
				searchEnd = string.sub(writtenSearch, writtenPos)

				searchStart = string.sub(searchStart, 1, string.len(searchStart) - 1)
				writtenSearch = searchStart .. searchEnd

				writtenPos = writtenPos - 1
				if (searchLength < 39) then
					cursorPosX = cursorPosX - 1
				else
					writeStart = writeStart - 1
				end
				write = true
			elseif (keyPressed == keys.left and writtenPos > 1) then
				writtenPos = writtenPos - 1
				cursorPosX = cursorPosX - 1
			elseif (keyPressed == keys.right and writtenPos <= searchLength) then
				writtenPos = writtenPos + 1
				cursorPosX = cursorPosX + 1
			elseif (keyPressed == keys.down and (currentPosition < listLimit)) then
				cursorPosY = cursorPosY + 1
				currentPosition = currentPosition + 1
				movedSelection = true
			elseif (keyPressed == keys.up and (currentPosition > 1)) then
				cursorPosY = cursorPosY - 1
				currentPosition = currentPosition - 1
				movedSelection = true
			elseif (keyPressed == keys.pageUp and currentPosition > 1) then
				cursorPosY = 2
				currentPosition = currentPosition - 21
				if (currentPosition < 1) then
					currentPosition = 1
				end
				printPosition = currentPosition
				movedSelection = true
			elseif (keyPressed == keys.pageDown and currentPosition < listLimit) then
				cursorPosY = 12
				currentPosition = currentPosition + 21
				if (currentPosition > listLimit) then
					currentPosition = listLimit
				end
				printPosition = currentPosition - 10
				if (printPosition < 1) then
					printPosition = 1
					cursorPosY = listLimit
				end
				movedSelection = true
			elseif (keyPressed == keys.home and currentPosition > 1) then
				cursorPosY = 2
				currentPosition = 1
				printPosition = 1
				movedSelection = true
			elseif (keys.getName(keyPressed) == "end" and currentPosition < listLimit) then
				cursorPosY = 12
				currentPosition = listLimit
				printPosition = listLimit - 11
				if (printPosition < 1) then
					printPosition = 1
					cursorPosY = listLimit
				end
				movedSelection = true
			elseif(keyPressed == keys.enter and onScreenItemsList[cursorPosY - 1] ~= nil) then
				confirmSelection = true
			end
		end

		if (cursorPosX < 1) then
			cursorPosX = 1
			writeStart = writeStart - 1
		elseif (cursorPosX > 39) then
			cursorPosX = 39
			writeStart = writeStart + 1
		end

		if (writeStart < 1) then
			writeStart = 1
		end

		if (cursorPosY < 2) then
			cursorPosY = 2
			printPosition = printPosition - 1
		elseif (cursorPosY > 12) then
			cursorPosY = 12
			printPosition = printPosition + 1
		end

		if (movedSelection) then
			onScreenItemsList = printListSection(searchedItemsList, printPosition, 11)
			highlightItemSelected()
			changedSelection = true
			movedSelection = false
		end

		if (write) then
			searchLength = string.len(writtenSearch)
			searchChanged = true
			if (searchLength >= 37) then
				printedSearch = string.sub(writtenSearch, writeStart)
			else
				printedSearch = writtenSearch
			end

			term.setCursorPos(1, 13)
			term.setBackgroundColor(colors.blue)
			term.clearLine()
			term.write(printedSearch)
			term.setCursorPos(cursorPosX, 13)
			write = false
		else
			term.setCursorPos(cursorPosX, 13)
		end
	end
end

local function executeItemSelection()
	term.clear()
	term.setCursorPos(1, 1)
	printPosition, currentPosition, cursorPosY, cursorPosX = 1, 1, 2, 1
	changedSelection, searchChanged, confirmSelection = false, false, false
	writtenSearch = ""

	parallel.waitForAny(itemSelectionSearcher, itemSelectionUpdater, itemSelectionWidePrinter)

	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.setCursorBlink(false)
	term.setCursorPos(1, 1)
	term.clear()

	currentMenu = menus[2]
end

local function isRecipeUsable()
	if data == nil or next(data) == nil then
		return false
	end

	if data["input"] == nil or next(data["input"]) == nil then
		return false
	end

	for _, v in pairs(data["input"]) do
		if type(v) == "table" then
			for key, v2 in pairs(v) do
				if key == "slot" then
					for _, slot in pairs(v2) do
						if type(slot) == "number" then
							if slot < 1 then
								return false
							elseif slot > 12 then
								return false
							else
								for _, discard in pairs(invalidSlots) do
									if slot == discard then
										return false
									end
								end
							end
						end
					end
				elseif key == "tag" or key == "name" or key == "displayName" or key == "side" then
					if type(v2) ~= "string" then
						return false
					end
				end
			end
		else
			return false
		end
	end

	if data["output"] == nil or next(data["output"]) == nil then
		return false
	end

	for k, v in pairs(data["output"]) do
		if k == "name" or k == "displayName" then
			if type(v) ~= "string" then
				return false
			end
		elseif k == "count" then
			if type(v) ~= "number" then
				return false
			end
		end
	end

	if data["trash"] == nil or next(data["trash"]) == nil then
		return false
	end

	if type(data["trash"]["side"]) ~= "string" then
		return false
	end

	return true
end

local function checkRecipeSides()
	local success = true
	local outputSide = data["output"]["side"]

	if (outputSide == "front" or outputSide == "bottom" or outputSide == "top") then
		if (isType(outputSide, "inventory", "item_storage")) then
			output = peripheral.wrap(outputSide)
		else
			success = false
			--printError(">_< Missing output storage on " .. outputSide .. " side!")
		end
	else
		success = false
		--printError(">_< Output side is invalid!")
	end

	local trashSide = data["trash"]["side"]
	if (trashSide == "front" or trashSide == "bottom" or trashSide == "top") then
		if (isType(trashSide, "inventory", "item_storage")) then
			trash = peripheral.wrap(trashSide)
		else
			success = false
			--printError(">_< Missing trash storage on " .. trashSide .. " side!")
		end
	else
		success = false
		--printError(">_< Trash side is invalid!")
	end

	for _,item in pairs(data["input"]) do
		if (item["side"] == outputSide) then
			success = false
			--printError(">_< An input is sharing the output side!")
		elseif (data["trash"]["side"] == item["side"]) then
			success = false
			--printError(">_< An input is sharing the trash side!")
		elseif (isType(item["side"], "inventory", "item_storage")) then
			inputs[item["side"]] = peripheral.wrap(item["side"])
		elseif (isType(item["side"], "workbench")) then
			success = false
			--printError(">_< An input is sharing the workbench side!")
		else
			success = false
			--printError(">_< Missing input chest on " .. item["side"] .. " side!")
		end
	end
	
	if (tableCount(inputs) < 1) then
		success = false
		--printError(">_< Needs at least one input storage block!")
	end

	return success
end

local function connectForRecipesList()
	modem = peripheral.find("modem")
	if (modem == nil) then
		printError(">_< No router found!")
		return false
	else
		peripheral.find("modem", rednet.open)
		print("> Connecting to a server...")

		local success, id, _ = messageTheServer("CONN_REQ", "CONN")
		if (success) then
			print("> Getting craftable list...")
			sendPort = id

			local success, _, message = messageTheServer("CRAFTS_REQ")
			if (success) then
				craftableItemsList = message
				return true
			else
				printError(">_< Can't connect to the server!")
				return false
			end
		else
			printError(">_< Can't connect to the server!")
			return false
		end
	end
	rednet.close()
end

local function recipeFileExists()
	if (fs.exists(recipeFile)) then
		data = loadFile(recipeFile)
		selectedRecipe = deepCopy(data)
		return true
	else
		return false
	end
end

local function initialCheck()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.clear()
	term.setCursorPos(1, 1)
	
	print("> Doing some checks...")
	
	if fs.exists(settingsFile) then
		crafterSettings = loadFile(settingsFile)
		if crafterSettings["reserveOneItem"] == nil or type(crafterSettings["reserveOneItem"]) ~= "boolean" then
			crafterSettings = defaultSettings
			saveFile(crafterSettings, settingsFile)
		end
	else
		crafterSettings = defaultSettings
		saveFile(crafterSettings, settingsFile)
	end
	selectedSettings = deepCopy(crafterSettings)

	if (fs.exists(statsFile)) then
		stats = loadFile(statsFile)
	end

	if turtle == nil then
		printError(">_< This program only works on turles!")
		return false
	end

	if (not isType("left", "workbench")) and (not isType("right", "workbench")) then
		printError(">_< Missing crafing table upgrade!")
		return false
	end

	return true
end

local function crafterMenuAction()
	if cursorPosY == 1 then
		if cursorPosX == 1 then
			crafterRunning = not crafterRunning
			crafterRestart = true
		elseif cursorPosX == 2 then
			crafterRunning = false
			crafterOn = false
			if fs.exists(recipeFile) then
				fs.delete(recipeFile)
			end

			stats[statsMode[1]]["Crafts"] = 0
			stats[statsMode[1]]["Items"] = 0
			saveFile(stats, statsFile)

			selectedItemRecipes = {}
			selectedRecipe = {}
			data = {}
			currentMenu = menus[1]
		elseif cursorPosX == 3 then
			crafterRunning = false
			crafterOn = false

			stats[statsMode[1]]["Crafts"] = 0
			stats[statsMode[1]]["Items"] = 0
			saveFile(stats, statsFile)

			currentMenu = menus[2]
			oneRecipeMessageRequest = true
		elseif cursorPosX == 4 then
			showCrafterMenu = true
		end
	elseif cursorPosY == 2 then
		statsCurrentMode = statsMode[nextArrayPosition(statsMode, statsCurrentMode)]
	end
end

local function crafterMenuMover()
	local actioned = false

	if keyPressed == keys.left and cursorPosY == 1 and cursorPosX > 1 then
		cursorPosX = cursorPosX - 1
		if not hasModem and cursorPosX > 1 then
			cursorPosX = 1
		end
	elseif keyPressed == keys.right and cursorPosY == 1 and cursorPosX < 4 then
		cursorPosX = cursorPosX + 1
		if not hasModem and cursorPosX < 4 then
			cursorPosX = 4
		end
	elseif keyPressed == keys.up and cursorPosY == 1 then
		cursorPosY = cursorPosY + 1
		if not hasModem then
			if cursorPosX == 2 then
				cursorPosX = 1
			elseif cursorPosX == 3 then
				cursorPosX = 4
			end
		end
	elseif keyPressed == keys.down and cursorPosY == 2 then
		cursorPosY = cursorPosY - 1
		if not hasModem then
			if cursorPosX == 2 then
				cursorPosX = 1
			elseif cursorPosX == 3 then
				cursorPosX = 4
			end
		end
	elseif keyPressed == keys.enter then
		actioned = true
	end

	return actioned
end

local function crafterKeyboardListener()
	cursorPosX, cursorPosY = 4, 2
	while not showCrafterMenu do
		drawCrafterBottomMenu()
		keyboardListen()

		if crafterMenuMover() then
			crafterMenuAction()
		end
	end
end

local function crafterMenuDrawer()
	while crafterOn do
		parallel.waitForAny(drawCrafterMenu, crafterKeyboardListener)

		if showCrafterMenu then
			if displayRecipeConfigMenu() then
				crafterRestart = true
				saveFile(selectedRecipe, recipeFile)
				saveFile(selectedSettings, settingsFile)
				data = deepCopy(selectedRecipe)
				crafterSettings = deepCopy(selectedSettings)
				checkRecipeSides()
			else
				selectedRecipe = deepCopy(data)
				selectedSettings = deepCopy(crafterSettings)
			end
			showCrafterMenu = false
		end
	end
end

local function anomalyListener()
	local crafterMissing = false
	while not crafterRestart or not crafterOn do
		modem = peripheral.find("modem")
		if modem == nil then
			hasModem = false
		else
			hasModem = true
		end

		parallel.waitForAny(peripheralAttachListen, peripheralDeatatchListen)

		if (not isType("left", "workbench")) and (not isType("right", "workbench")) then
			crafterMissing = true
		end

		if crafterMissing or not checkRecipeSides() then
			crafterRunning = false
			crafterOn = false

			stats[statsMode[1]]["Crafts"] = 0
			stats[statsMode[1]]["Items"] = 0
			saveFile(stats, statsFile)

			currentMenu = menus[3]

			stats[statsMode[1]]["Crafts"] = 0
			stats[statsMode[1]]["Items"] = 0
			saveFile(stats, statsFile)
		end
	end
end

local function crafterRestartListener()
	while not crafterRestart or not crafterOn do
		sleep(0.05)
	end
	crafterRestart = false
end

local function crafterExternalController()
	while crafterOn do
		if crafterRunning then
			parallel.waitForAny(turnOnCrafter, crafterRestartListener, anomalyListener)
			crafterStatus[1] = nil
			crafterStatus[2] = nil
			crafterStatus[3] = nil
		else
			sleep(0.05)
		end
	end
end

local function mainGraphicalMode(startingMenu)
	programOn = true

	if startingMenu ~= nil then
		currentMenu = startingMenu
	end

	while programOn do
		if currentMenu == menus[1] then
			selectedItemRecipes = {}
			selectedRecipe = {}
			data = {}
			if next(searchedItemsList) == nil then
				if connectForRecipesList() then
					executeItemSelection()
				else
					programOn = false
				end
			else
				executeItemSelection()
			end
		elseif currentMenu == menus[2] then
			if next(selectedItemRecipes) == nil then
				if next(data) ~= nil then
					getItemRecipies(data["output"])
				else
					getItemRecipies(searchedItemsList[currentPosition])
				end
			else
				displayRecipes(selectedItemRecipes)
			end
		elseif currentMenu == menus[3] then
			if displayRecipeConfigMenu() then
				saveFile(selectedRecipe, recipeFile)
				saveFile(selectedSettings, settingsFile)
				data = deepCopy(selectedRecipe)
				crafterSettings = deepCopy(selectedSettings)
				checkRecipeSides()
			else
				selectedSettings = deepCopy(crafterSettings)
			end
		elseif currentMenu == menus[4] then
			crafterOn = true
			crafterRunning = true
			checkStatsFile()
			parallel.waitForAny(crafterExternalController, crafterMenuDrawer)
		else
			programOn = false
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			term.clear()
			printError(">_< How on earth you got here?!!")
			print("You know... congrats for trying to break my program. It probably didn't work as you expected.")
		end

		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)
		term.clear()
		term.setCursorPos(1, 1)
	end

	rednet.close()
end

local function main()
	if initialCheck() then
		if recipeFileExists() then
			if isRecipeUsable() then
				if checkRecipeSides() then
					mainGraphicalMode(menus[4])
				else
					mainGraphicalMode(menus[3])
				end
			else
				printError(">_< Recipe is UNUSABLE!")
				local _, cursorY = term.getCursorPos()
				for i = 5, 1, -1 do
					term.clearLine()
					term.setCursorPos(1, cursorY)
					term.write("Removing in.. " .. i)
					os.sleep(1)
				end
				fs.delete(recipeFile)
				term.setCursorPos(1, cursorY + 1)
				print("> Recipie removed!")
				mainGraphicalMode(menus[1])
			end
		else
			print("> No recipe set!")
			mainGraphicalMode(menus[1])
		end
	end
end

main()
