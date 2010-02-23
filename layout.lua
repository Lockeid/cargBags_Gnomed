--[[
TODO
	-- One empty icon]]--

-- Install the config
local db = cargBags_Gnomed.Config
cargBags_Gnomed.Frames = {}

-- Localization
-- Esaier than requesting every localization
local L = {}
L.Weapon, L.Armor, L.Container, L.Consumables, L.Glyph, L.Trades, L.Projectile, L.Quiver, L.Recipe, L.Gem, L.Misc, L.Quest = GetAuctionItemClasses()


-- This function is only used inside the layout, so the cargBags-core doesn't care about it
-- It creates the border for glowing process in UpdateButton()
local createGlow = function(button)
	local glow = button:CreateTexture(nil, "OVERLAY")
	glow:SetTexture"Interface\\Buttons\\UI-ActionButton-Border"
	glow:SetBlendMode"ADD"
	glow:SetAlpha(.8)
	glow:SetWidth(70)
	glow:SetHeight(70)
	glow:SetPoint("CENTER", button)
	button.Glow = glow
end

-- Hide empty bags
local function CollapseEmpty(frame) 
	if(frame.ContainerHeight == 0) then
		frame:Hide()
	end
end

-- The main function for updating an item button,
-- the item-table holds all data known about the item the button is holding, e.g.
--   bagID, slotID, texture, count, locked, quality - from GetContainerItemInfo()
--   link - well, from GetContainerItemLink() ofcourse ;)
--   name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc - from GetItemInfo()
-- if you need cooldown item data, use self:RequestCooldownData()
local UpdateButton = function(self, button, item)
	button.Icon:SetTexture(item.texture)
	if IsAddOnLoaded("Tabard-O-Matic") then
		local slot = button:GetID()
		--local bag = button:GetBag()
		
		--local link = self.GetHandler().GetContainerItemLink(item.bagID, slot)
		link = item.link
		if (link) then
			local ItemID = tonumber(link:match("item:(%d+)"))
			local TabardValue = TabardTextures[ItemID]
		
				if TabardValue then
					Tabard_O_Matic:SetTheButtons(button, TabardValue.ItemName)
				end
		end
	end	
	SetItemButtonCount(button, item.count)
	SetItemButtonDesaturated(button, item.locked, 0.5, 0.5, 0.5)

	-- Color the button's border based on the item's rarity / quality!
	if db.ButtonGlow == true then
		if(item.rarity and item.rarity > 1) then
			if(not button.Glow) then createGlow(button) end
			button.Glow:SetVertexColor(GetItemQualityColor(item.rarity))
			button.Glow:Show()
		else
			if(button.Glow) then button.Glow:Hide() end
		end
	end
end

-- Updates if the item is locked (currently moved by user)
--   bagID, slotID, texture, count, locked, quality - from GetContainerItemInfo()
-- if you need all item data, use self:RequestItemData()
local UpdateButtonLock = function(self, button, item)
	SetItemButtonDesaturated(button, item.locked, 0.5, 0.5, 0.5)
end

-- Updates the item's cooldown
--   cdStart, cdFinish, cdEnable - from GetContainerItemCooldown()
-- if you need all item data, use self:RequestItemData()
local UpdateButtonCooldown = function(self, button, item)
	if(button.Cooldown) then
		CooldownFrame_SetTimer(button.Cooldown, item.cdStart, item.cdFinish, item.cdEnable) 
	end
end

-- The function for positioning the item buttons in the bag object
local UpdateButtonPositions = function(self)
	local button
	local col, row = 0, 0
	local empty = false
	for i, button in self:IterateButtons() do
		button:ClearAllPoints()

		local xPos = col * 38
		local yPos = -1 * row * 38
		if(self.Caption) then yPos = yPos - 20 end	-- Spacing for the caption

		button:SetPoint("TOPLEFT", self, "TOPLEFT", xPos, yPos)	 
		if(col >= self.Columns-1) then	 
			col = 0	 
			row = row + 1	 
		else	 
			col = col + 1	 
		end
	end
	-- Hide if empty
	--if(empty) then self:Hide() else self:Show() end

	-- This variable stores the size of the item button container
	
	self.ContainerHeight = (row + (col>0 and 1 or 0)) * 38
	
	-- checks if our bag is empty. If yes then hide it
	if(self.ContainerHeight == 0) then empty = true end 
	
	if(empty) then 
		self:Hide() 
	else 
		if(self.Name ~= "cB_Gnomed_Bag" and self.Name ~= "cB_Gnomed_Bank") then
			self:Show()
		end
	end
	
	if(self.UpdateDimensions) then self:UpdateDimensions() end -- Update the bag's height
end

-- Function is called after a button was added to an object
-- We color the borders of the button to see if it is an ammo bag or else
-- Please note that the buttons are in most cases recycled and not new created
local PostAddButton = function(self, button, bag)
	if(not button.NormalTexture) then return end

	local bagType = cargBags.Bags[button.bagID].bagType
	if(button.bagID == KEYRING_CONTAINER) then
		button.NormalTexture:SetVertexColor(1, 0.7, 0)	-- Key ring
	elseif(bagType and bagType > 0 and bagType < 8) then
		button.NormalTexture:SetVertexColor(1, 1, 0)		-- Ammo bag
	elseif(bagType and bagType > 4) then
		button.NormalTexture:SetVertexColor(0, 1, 0)		-- Profession bags
	else
		button.NormalTexture:SetVertexColor(1, 1, 1)		-- Normal bags
	end
end

-- More slot buttons -> more space!
local UpdateDimensions = function(self)
	local height = 0			-- Normal margin space
	if(self.Space) then
		height = height + 16	-- additional info display space
	end
	if(self.Caption) then	-- Space for captions
		height = height + 20
	end
	self:SetHeight(self.ContainerHeight + height)
end



local function createSmallButton(name, parent, ...)
	local button = CreateFrame("Button", nil, parent)
	button:SetPoint(...)
	button:SetNormalFontObject(GameFontHighlight)
	button:SetText(name)
	button:SetPoint"CENTER"
	button:SetWidth(20)
	button:SetHeight(20)
	button:SetScript("OnEnter", buttonEnter)
	button:SetScript("OnLeave", buttonLeave)
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	button:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	})
	button:SetBackdropColor(0, 0, 0, 1)
	button:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.7)
	return button
end


-- Blizzard Equipement manager part
-- This table will hold information about all items which are part of a set:
local item2setEM = {}

-- This function will extract the item set data, so it can be 
-- efficiently checked in the filter later:
local function cacheSetsEM()
    for k in pairs(item2setEM) do item2setEM[k] = nil end
    for k = 1, GetNumEquipmentSets() do
        local sName = GetEquipmentSetInfo(k)
        local set = GetEquipmentSetItemIDs(sName)
        for _,item in next, set do
            -- "item" is simply the item ID here:
            if item then item2setEM[item] = true end
        end
    end
    cargBags:UpdateBags()
end

-- This creates an invisible frame to hold the required event handlers:
local EQ_Event = CreateFrame("Frame")
EQ_Event:RegisterEvent("PLAYER_LOGIN")
EQ_Event:RegisterEvent("EQUIPMENT_SETS_CHANGED")
EQ_Event:SetScript("OnEvent", cacheSetsEM)

local OF = IsAddOnLoaded('Outfitter')
local item2setOF = {}
local pLevel = UnitLevel("player")
-- Outfitter doesn't use item strings or links to identify items by default, 
-- so this is the function to create an item string:
local function createItemString(i) return "item:"..i.Code..":"..i.EnchantCode..":"..i.JewelCode1..":"..i.JewelCode2..":"..i.JewelCode3..":"..i.JewelCode4..":"..i.SubCode..":"..i.UniqueID..":"..pLevel end

local function cacheSetsOF()
    for k in pairs(item2setOF) do item2setOF[k] = nil end
    -- Outfitter grants access to sets via categories,
    -- so there are two loops here:
    for _,id in ipairs(Outfitter_GetCategoryOrder()) do
        local OFsets = Outfitter_GetOutfitsByCategoryID(id)
        for _,vSet in pairs(OFsets) do
            for _,item in pairs(vSet.Items) do
                -- "item" is a table here, and since I don't want to save 
                -- the whole table, I'll create an itemstring out of it:
                if item then item2setOF[createItemString(item)] = true end
            end
        end
    end
    cargBags:UpdateBags()
end

if OF then
    -- Outfitter supports the needed callbacks by itself:
    Outfitter_RegisterOutfitEvent("ADD_OUTFIT", cacheSetsOF)
    Outfitter_RegisterOutfitEvent("DELETE_OUTFIT", cacheSetsOF)
    Outfitter_RegisterOutfitEvent("EDIT_OUTFIT", cacheSetsOF)
    if Outfitter:IsInitialized() then
        cacheSetsOF()
    else
        Outfitter_RegisterOutfitEvent('OUTFITTER_INIT', cacheSetsOF)
    end
end

local IR = IsAddOnLoaded('ItemRack')
local item2setIR = {}
local function cacheSetsIR()
    for k in pairs(item2setIR) do item2setIR[k] = nil end
    local IRsets = ItemRackUser.Sets
    for i in next, IRsets do
        -- Some internal sets and queues start with one of these 
        -- characters, so let's exclude them:
	if not string.find(i, "^~") then 
            for _,item in pairs(IRsets[i].equip) do
                -- "item" is a custom itemstring here:
                if item then item2setIR[item] = true end
	    end
	end
    end
end

if IR then
    cacheSetsIR()
    -- ItemRack doesn't support any callbacks by itself, so we're going to
    -- hook into the functions we need manually:
    local function ItemRackOpt_CreateHooks()
        -- Those are the actual hooks for adding, updating and deleting sets:
        local IRsaveSet = ItemRackOpt.SaveSet
        function ItemRackOpt.SaveSet(...) IRsaveSet(...); cacheSetsIR(); cargBags:UpdateBags() end
        local IRdeleteSet = ItemRackOpt.DeleteSet
        function ItemRackOpt.DeleteSet(...) IRdeleteSet(...); cacheSetsIR(); cargBags:UpdateBags() end
    end
    -- Amusingly, ItemRack puts its set updating functions into a 
    -- load-on-demand module, so we need to hook into the LoD-function first:
    local IRtoggleOpts = ItemRack.ToggleOptions
    function ItemRack.ToggleOptions(...) IRtoggleOpts(...) ItemRackOpt_CreateHooks() end
end



-- Style of the bag and its contents
local func = function(settings, self, name)
	self:EnableMouse(true)


	self.UpdateDimensions = UpdateDimensions
	self.UpdateButtonPositions = UpdateButtonPositions
	self.UpdateButton = UpdateButton
	self.UpdateButtonLock = UpdateButtonLock
	self.UpdateButtonCooldown = UpdateButtonCooldown
	self.PostAddButton = PostAddButton
	
	self:SetFrameStrata("HIGH")
	tinsert(UISpecialFrames, self:GetName()) -- Close on "Esc"
	
	-- Make main frames movable
	 if(self.Name == "cB_Gnomed_Bag" or self.Name == "cB_Gnomed_Bank") then
		self:SetMovable(true)
	
		self:RegisterForClicks("LeftButton", "RightButton");
	    self:SetScript("OnMouseDown", function() 
	            self:ClearAllPoints() 
	            self:StartMoving() 
	    end)
	    self:SetScript("OnMouseUp",  self.StopMovingOrSizing)
	end

	if(self.Name =="cB_Gnomed_Keyring") then
		self:SetScale(db.KeyringScale)	-- Make key ring a bit smaller
		self.Columns = db.KeyringColumns
	elseif(strfind(self.Name, "Bank")) then
		self.Columns = db.BankColumns
	else 
		self.Columns = db.DefaultColumns
	end

	if (self.Name ~= "cB_Gnomed_Bag" or self.Name ~= "cB_Gnomed_Bank" or self.Name ~= "cB_Gnomed_Keyring") then
		self:SetScale(db.DefaultScale)
	end

	self.ContainerHeight = 0
	self:UpdateDimensions()
	self:SetWidth(38*self.Columns)	-- Set the frame's width based on the columns


	-- Caption and close button
	local caption = self:CreateFontString(nil, "OVERLAY")
	caption:SetFont(db.Font, db.FSize, db.FOutline)
	if(caption) then
		for captionText in string.gmatch(self.Name,"cB_Gnomed_([%w ]+)") do 
				caption:SetText(captionText)
		end
		caption:SetPoint("TOPLEFT", 0, 0)
		self.Caption = caption
			
		local close = CreateFrame("Button", nil, self, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", 5, 8)
		close:SetScript("OnClick", function(self) self:GetParent():Hide() end)
		
	end

		-- New feature: right click dropdown for filters
	--
	local menu = {}
	local tinsert = tinsert
	local dd = CreateFrame('Frame', 'cargBags_GnomedMenu', UIParent, 'UIDropDownMenuTemplate')
	
	local function dropdown()
		menu = wipe(menu)
		
		local title = {text = 'cargBags Filters\n ', isTitle = true}
		tinsert(menu, title)
		for _, f in pairs(cargBags_Gnomed.Frames) do
			local t = {}
			str = f:GetName()
			name = strmatch(str, "cB_Gnomed_([%w ]+)")
			if (not strfind(name,"Bank")) then
				local t = {text = name, func = function() ToggleFrame(f) end}
				tinsert(menu, t)
			end			
		end
	end
	
	local function showDropdown(self)
		local y = self:GetBottom() >= GetScreenHeight()/2 and "TOP" or "BOTTOM"
		local x = self:GetRight() >= GetScreenWidth()/2 and "LEFT" or "RIGHT"
		dropdown()
		EasyMenu(menu,dd,self,0,0)
	end--
	if(self.Name == "cB_Gnomed_Bag") then
		local filters = CreateFrame("Button", nil, self)
		filters:SetWidth(24)
		filters:SetHeight(24)
		filters:SetNormalTexture('Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up')
		filters:SetPushedTexture('Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down')
		filters:SetHighlightTexture('Interface\\Buttons\\UI-Common-MouseHilight')
		filters:SetScript("OnClick", showDropdown)
		
		filters.text = filters:CreateFontString(nil,"OVERLAY","GameFontNormal")
		filters.text:SetPoint("BOTTOMLEFT",self,"BOTTOMLEFT",0,0)
		filters.text:SetText("Filters")
		filters.text:SetFont(db.Font, db.FSize, db.FOutline)
		filters:SetPoint("LEFT",filters.text,"RIGHT",3,0)
	end--

	local bagType
	if(self.Name == "cB_Gnomed_Bag") then
		bagType = "bags" -- We want to add all bags to our bag button bar
	else
		bagType = "bank" -- the bank gets bank bags, of course
	end

	  if(self.Name == "cB_Gnomed_Bag" or self.Name == "cB_Gnomed_Bank") then
		-- The font string for bag space display
		-- You can see, it works with tags, - [free], [max], [used] are currently supported
		local space = self:SpawnPlugin("Space", "[free] / [max] free", bagType)
		if(space) then
			space:SetPoint("BOTTOMLEFT", self, self.Name == "cB_Gnomed_Bag" and 70 or 0, 0)
			space:SetJustifyH"LEFT"
			space:SetFont(db.Font, db.FSize, db.FOutline)
		end


		-- The frame for money display
		if self.Name == "cB_Gnomed_Bag" then
			local money = self:SpawnPlugin("Money")
			if(money) then
				money:SetPoint("TOPRIGHT", self, "TOPRIGHT", -10,-2)
			end
			local anywhere = self:SpawnPlugin("Anywhere")
			if(anywhere) then
				anywhere:SetPoint("LEFT",self.Caption,"RIGHT",2,-2)
			end
		end
		
		 -- A nice bag bar for changing/toggling bags
		local bagButtons = self:SpawnPlugin("BagBar", bagType)
		if(bagButtons) then
			bagButtons:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -15)
			bagButtons:SetScale(0.85)
			
			local backdrop = CreateFrame("Frame",nil,bagButtons)
			backdrop:SetBackdrop{ 
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\AddOns\\cargBags_Gnomed\\Media\\UI-Tooltip-Border", 
				tile = true, 
				tileSize = 8, 
				edgeSize =16, 
				insets = { left = 4,right = 4,top = 4,bottom = 4} 
				}
			backdrop:SetBackdropColor(0,0,0)
			backdrop:SetBackdropBorderColor(.2,.2,.2)
			backdrop:SetFrameStrata("MEDIUM")
			backdrop:SetPoint("TOPLEFT",-6,6)
			backdrop:SetPoint("BOTTOMRIGHT",6,-6)
			
			bagButtons:Hide()

			-- main window gets a fake bag button for toggling key ring
			if(self.Name == "cB_Gnomed_Bag") then
				local keytoggle = bagButtons:CreateKeyRingButton()
				keytoggle:SetScript("OnClick", function()
					if cB_Gnomed_Keyring:IsShown() then
						cB_Gnomed_Keyring:Hide()
						keytoggle:SetChecked(0)
					else
						cB_Gnomed_Keyring:Show()
						keytoggle:SetChecked(1)
					end
				end)
			end
		end		

		-- We don't need the bag bar every time, so let's create a toggle button for them to show
		local bagToggle = CreateFrame("CheckButton", nil, self)
		bagToggle:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		bagToggle:SetWidth(40)
		bagToggle:SetHeight(12)
		bagToggle:SetPoint("BOTTOMRIGHT", self,"BOTTOMRIGHT",0,0)
		bagToggle:RegisterForClicks("LeftButtonUp")
		bagToggle:SetScript("OnClick", function() --ToggleFrame(self.Object.BagBar) end)
			if(self.BagBar:IsShown()) then
				self.BagBar:Hide()
			else
				self.BagBar:Show()
			end
			self:UpdateDimensions()	-- The bag buttons take space, so let's update the height of the frame
		end)
		local bagToggleText = bagToggle:CreateFontString(nil, "OVERLAY")
		bagToggleText:SetPoint("CENTER", bagToggle)
		bagToggleText:SetFont(db.Font, db.FSize, db.FOutline)
		bagToggleText:SetText("Bags")
		-- kRestack
		if select(4,GetAddOnInfo("kRestack"))then
			local restack = createSmallButton("R", self,"BOTTOMRIGHT",self,"BOTTOMRIGHT",-35,-2)
			restack:SetScript("OnClick", function() kRestack(bagType) end)
		end

	  end	

	-- For purchasing bank slots
	if(self.Name == "cB_Gnomed_Bank") then
		local purchase = self:SpawnPlugin("Purchase")
		if(purchase) then
			purchase:SetText(BANKSLOTPURCHASE)
			purchase:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -60, 0)
			if(self.BagBar) then purchase:SetParent(self.BagBar) end

			purchase.Cost = self:SpawnPlugin("Money", "static")
			purchase.Cost:SetParent(purchase)
			purchase.Cost:SetPoint("RIGHT", purchase, "LEFT", -2, 0)
		end
	end	

	-- And the frame background!
	local backdrop = CreateFrame("Frame",nil,self)
	backdrop:SetBackdrop{ 
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\AddOns\\cargBags_Gnomed\\Media\\UI-Tooltip-Border", 
	tile = true, 
	tileSize = 8, 
	edgeSize =16, 
	insets = { left = 4,right = 4,top = 4,bottom = 4} 
	}
	if strfind(self.Name, "Bank") then
		backdrop:SetBackdropColor(0,0,0)
	else
		backdrop:SetBackdropColor(0,180/255,1)
	end
	backdrop:SetBackdropBorderColor(.2,.2,.2)
	backdrop:SetFrameStrata("MEDIUM")
	backdrop:SetFrameLevel(4)
	backdrop:SetPoint("TOPLEFT",-6,6)
	backdrop:SetPoint("BOTTOMRIGHT",6,-6)
	

	return self
end

-- Register the style with cargBags
cargBags:RegisterStyle("Gnomed", setmetatable({}, {__call = func}))


local INVERTED = -1 -- with inverted filters (using -1), everything goes into this bag when the filter returns false

--------------------
--General filters
--------------------

-- Bag filter
local onlyBags = function(item) return item.bagID >= 0 and item.bagID <= 4 end
--Keyring filter
local onlyKeyring = function(item) return item.bagID == -2 end
-- Bank filter
local onlyBank = function(item) return item.bagID == -1 or item.bagID >= 5 and item.bagID <= 11 end

----------------
-- Bag filters
----------------

-- Stuff filter
local onlyArmor = function(item) return item.type and item.type == L.Armor end -- for stuff
local onlyWeapon = function(item) return item.type and item.type == L.Weapon end
local onlyStuff = function(item) return item.type and (item.type == L.Armor or item.type == L.Weapon) end

-- Hide unused slots
local hideEmpty = function(item) return item.texture ~= nil end -- for keyring, stuff, quest, consumable
-- Quest items filter
local onlyQuest = function(item) return item.type and item.type == L.Quest end
-- Consumables filter
local onlyConsumables = function(item) return item.type and item.type == L.Consumables end
-- Trade goods filter
local onlyTradeGoods = function(item) return item.type and item.type == L.Trades end
-- Gem filter
local onlyGems = function(item) return item.type and item.type == L.Gem end
-- Glyphs
local onlyGlyphs = function(item) return item.type and item.type == L.Glyph end
-- Projectiles
local onlyPJ = function(item) return item.type and item.type == L.Projectile end
-- Custom
--~ local onlyCustom = function (item) end
-- Filters filters :)
local nothing = function(item) return end

-- Blizzard filter
local fItemSets = function(item)
    if not item.link then return false end
    -- Check ItemRack sets:
    if item2setIR[string.match(item.link,"item:(.+):%-?%d+")] then return true end
    -- Check Outfitter sets:
    local _,_,itemStr = string.find(item.link, "^|c%x+|H(.+)|h%[.*%]")
    if item2setOF[itemStr] then return true end
    -- Check Equipment Manager sets:
    local _,itemID = strsplit(":", itemStr)
    if item2setEM[tonumber(itemID)] then return true end    
    return false
end

-----------------
-- Bank filters
-----------------
-- Stuff
local onlyBankArmor = function(item) return onlyBank(item) and onlyArmor(item) end
local onlyBankWeapons = function(item) return onlyBank(item) and onlyWeapon(item) end
local onlyBankStuff = function(item) return onlyBank(item) and onlyStuff(item) end
-- Consumables
local onlyBankConsumables = function(item) return onlyBank(item) and onlyConsumables(item) end
-- Trade Goods
local onlyBankTG = function(item) return onlyBank(item) and onlyTradeGoods(item) end
-- Quest
local onlyBankQuest = function(item) return onlyBank(item) and onlyQuest(item) end

------------------
-- Frames Spawns
------------------


-- Bank frame and bank bags
-- TODO: those filters
--
local bankStuff = cargBags:Spawn("cB_Gnomed_Bank Stuff", bank)
bankStuff:SetFilter(onlyBankStuff, true)
bankStuff:SetFilter(hideEmpty)

local bankQuest = cargBags:Spawn("cB_Gnomed_Bank Quest", bankStuff)
bankQuest:SetFilter(onlyBankQuest, true)
bankQuest:SetFilter(hideEmpty, true)

local bankConso = cargBags:Spawn("cB_Gnomed_Bank Consumables", bankQuest)
bankConso:SetFilter(onlyBankConsumables, true)
bankConso:SetFilter(hideEmpty, true)

local bankTGoods = cargBags:Spawn("cB_Gnomed_Bank Trade Goods", bankConso)
bankTGoods:SetFilter(onlyBankTG, true)
bankTGoods:SetFilter(hideEmpty, true) --]]


local bank = cargBags:Spawn("cB_Gnomed_Bank")
bank:SetFilter(onlyBank, true)

-- Stuff frames
local equipment = cargBags:Spawn("cB_Gnomed_Equipment",main)
equipment:SetFilter(fItemSets,true)
equipment:SetFilter(hideEmpty, true)

local stuff = cargBags:Spawn("cB_Gnomed_Stuff",equipment)
stuff:SetFilter(onlyStuff , true)
stuff:SetFilter(hideEmpty, true)


-- Quest frame
local quest = cargBags:Spawn("cB_Gnomed_Quest",stuff)
quest:SetFilter(onlyQuest, true)
quest:SetFilter(hideEmpty, true)

-- Consumable
local consumables = cargBags:Spawn("cB_Gnomed_Consumables",main)
consumables:SetFilter(onlyConsumables, true)
consumables:SetFilter(hideEmpty, true)

-- Trade goods
local tgoods = cargBags:Spawn("cB_Gnomed_Trade Goods",consumables)
tgoods:SetFilter(onlyTradeGoods, true)
tgoods:SetFilter(hideEmpty, true)

-- Glyphs
local gl = cargBags:Spawn("cB_Gnomed_Glyphs", tgoods)
gl:SetFilter(onlyGlyphs, true)
gl:SetFilter(hideEmpty, true)

-- Gems
local gems = cargBags:Spawn("cB_Gnomed_Gems", isHunter and pj or gl)
gems:SetFilter(onlyGems, true)
gems:SetFilter(hideEmpty, true) --]]

-- Bagpack and bags
local main = cargBags:Spawn("cB_Gnomed_Bag")
main:SetFilter(onlyBags, true)

-- Keyring
local key = cargBags:Spawn("cB_Gnomed_Keyring",main)
key:SetFilter(onlyKeyring, true)
key:SetFilter(hideEmpty, true)


-- Now let's set the points
local bak = { }

local function SetPointToParent(frame, ...)
	frame:SetPoint(...)
end

function HideIfMain()
	if not main:IsShown() then
		CloseCargBags()
	end
end

local function PlaceFrame(frame, parent,...)
	tinsert(cargBags_Gnomed.Frames, frame)
	HideIfMain()
	bak[frame] = {}
	bak[frame].Point = {...}
	bak[frame].ParentPoint = {parent:GetPoint()}
	
	SetPointToParent(frame,...)	
	-- Go upward
	parent:SetScript("OnHide", function(self) 
		HideIfMain()
		frame:ClearAllPoints()
		SetPointToParent(frame,unpack(bak[frame].ParentPoint))
	end)
		
		-- Go to the last position
	parent:SetScript("OnShow", function(self)
		HideIfMain()
		frame:ClearAllPoints()
		SetPointToParent(frame,unpack(bak[frame].Point))				
	end)
end

	-- Bags
main:SetPoint("RIGHT",-65-80)


PlaceFrame(consumables,main,"BOTTOM",main,"TOP",0,15)
PlaceFrame(tgoods,consumables,"BOTTOM",consumables,"TOP",0,15)
PlaceFrame(gl, tgoods, "BOTTOM", tgoods, "TOP",0,15)
PlaceFrame(gems, gl, "BOTTOM", gl, "TOP",0,15)
PlaceFrame(equipment,main,"BOTTOMRIGHT",main,"BOTTOMLEFT",-15,0)
PlaceFrame(stuff,equipment,"BOTTOM",equipment,"TOP",0,15)
PlaceFrame(quest,stuff,"BOTTOM",stuff,"TOP",0,15)
PlaceFrame(key,quest,"BOTTOM",quest,"TOP",0,15)


	-- Bank
bank:SetPoint("LEFT", 15, -80)

 
PlaceFrame(bankStuff, bank, "BOTTOM", bank, "TOP", 0, 15) 
PlaceFrame(bankQuest, bankStuff, "BOTTOM", bankStuff, "TOP", 0, 15)
PlaceFrame(bankConso, bankQuest, "BOTTOM", bankQuest, "TOP", 0, 15) 
PlaceFrame(bankTGoods, bankConso, "BOTTOM", bankConso, "TOP", 0, 15)


function ToggleCargBags(forceopen)
	if(main:IsShown() and not forceopen) then CloseCargBags() else OpenCargBags() end
end


-- Opening / Closing Functions
function OpenCargBags() 
	main:Show()
	for _, f in pairs(cargBags_Gnomed.Frames) do
		str = f:GetName()
		name = strmatch(str, "cB_Gnomed_([%w ]+)")
		if (not strfind(name,"Bank")) then
			f:Show()
			key:Hide()
			CollapseEmpty(f)
		end			
	end	
end

function CloseCargBags() 
	main:Hide()
	for _, f in pairs(cargBags_Gnomed.Frames) do
		str = f:GetName()
		name = strmatch(str, "cB_Gnomed_([%w ]+)")
		if (not strfind(name,"Bank")) then
			f:Hide()
		end			
	end	
end
-- To toggle containers when entering / leaving a bank
local bankToggle = CreateFrame"Frame"
bankToggle:RegisterEvent"BANKFRAME_OPENED"
bankToggle:RegisterEvent"BANKFRAME_CLOSED"
bankToggle:SetScript("OnEvent", function(self, event)
	if(event == "BANKFRAME_OPENED") then 
		main:Show()
		bank:Show()
		for _, f in pairs(cargBags_Gnomed.Frames) do
			f:Show()
			key:Hide()
			CollapseEmpty(f)
		end	
	else 
		bank:Hide()
		for _, f in pairs(cargBags_Gnomed.Frames) do
		str = f:GetName()
		name = strmatch(str, "cB_Gnomed_([%w ]+)")
		if(strfind(name,"Bank")) then
			f:Hide()
		end			
	end
	end
end)

--~ main:SetScript("OnShow", function() main:Hide() main:SetScript("OnShow",function() end) end)
--~ bank:SetScript("OnShow", function() bank:Hide() bank:SetScript("OnShow",function() end) end)
-- Close real bank frame when our bank frame is hidden
bank:SetScript("OnHide", CloseBankFrame)


-- Hide the original bank frame
BankFrame:UnregisterAllEvents()

-- Blizzard Replacement Functions
ToggleBackpack = ToggleCargBags
ToggleBag = function() ToggleCargBags() end
OpenAllBags = ToggleBag
CloseAllBags = CloseCargBags
OpenBackpack = OpenCargBags
CloseBackpack = CloseCargBags


-- Set Anywhere as the default handler if it exists
if(cargBags.Handler["Anywhere"]) then
	cargBags:SetActiveHandler("Anywhere")
end
