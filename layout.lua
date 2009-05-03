--[[
TODO
	-- Bank filtering
	-- maybe subcategories)
]]--

local L = {}
local gl = GetLocale()
if gl == "enGB" or gl == "enUS" then
	L.Armor = "Armor"
	L.Weapon = "Weapon"
	L.Gem = "Gem"
	L.Trades = "Trade Goods"
	L.Consumables = "Consumable"
	L.Quest = "Quest"
elseif gl == "frFR" then
	L.Armor = "Armure"
	L.Weapon = "Arme"
	L.Gem = "Gemme"
	L.Trades = "Artisanat"
	L.Consumables = "Consommable"
	L.Quest = "Quête"
elseif gl == "ruRU" then
	L.Armor = "Доспехи"
	L.Weapon = "Оружие"
	L.Gem = "Самоцветы"
	L.Trades = "Хозяйственные товары"
	L.Consumables = "Расходуемые"
	L.Quest = "Задания"
elseif gl == "zhTW" then
	L.Armor = "護甲"
	L.Weapon = "武器"
	L.Gem = "珠寶"
	L.Trades = "商品"
	L.Consumables = "消耗品"
	L.Quest = "任務"
elseif gl == "zhCN" then
	L.Armor = "护甲"
	L.Weapon = "武器"
	L.Gem = "珠宝"
	L.Trades = "商品"
	L.Consumables = "消耗品"
	L.Quest = "任务"
elseif gl == "deDE" then
	L.Armor = "Rüstung"
	L.Weapon = "Waffe"
	L.Gem = "Juwelen"
	L.Trades = "Handwerkswaren"
	L.Consumables = "Verbrauchbar"
	L.Quest = "Quest"
end
	

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
		
		local link = GetContainerItemLink(item.bagID, slot)
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
	if(item.rarity and item.rarity > 1) then
		if(not button.Glow) then createGlow(button) end
		button.Glow:SetVertexColor(GetItemQualityColor(item.rarity))
		button.Glow:Show()
	else
		if(button.Glow) then button.Glow:Hide() end
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

	-- This variable stores the size of the item button container
	self.ContainerHeight = (row + (col>0 and 1 or 0)) * 38

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
	if(self.BagBar and self.BagBar:IsShown()) then
		height = height + 43				-- Bag button space
	end
	if(self.Space) then
		height = height + 16	-- additional info display space
	end
	if(self.Money) then
		height = height + 16
	end
	if(self.Caption) then	-- Space for captions
		height = height + 20
	end
	self:SetHeight(self.ContainerHeight + height)
end


-- Style of the bag and its contents
local func = function(settings, self, type)
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
	--if(self.Name == "cB_Gnomed_Bag" or self.Name =="cB_Gnomed_Bank") then
		self:SetMovable(true)
		self:SetUserPlaced(false)
		self:RegisterForClicks("LeftButton", "RightButton");
	    self:SetScript("OnMouseDown", function() 
	            self:ClearAllPoints() 
	            self:StartMoving() 
	    end)
	    self:SetScript("OnMouseUp",  self.StopMovingOrSizing)
	--end

	if(self.Name =="cB_Gnomed_Keyring") then
		self:SetScale(0.75)	-- Make key ring a bit smaller
		self.Columns = 8
	elseif(self.Name == "cB_Gnomed_Bank") then
		self.Columns = 14
	else 
		self.Columns = 8
	end

	if (self.Name ~= "cB_Gnomed_Bag" or self.Name ~= "cB_Gnomed_Bank" or self.Name ~= "cB_Gnomed_Keyring") then
		self:SetScale(0.9)
	end

	self.ContainerHeight = 0
	self:UpdateDimensions()
	self:SetWidth(38*self.Columns)	-- Set the frame's width based on the columns

	--if(self.Name == "cB_Gnomed_Bag" or self.Name == "cB_Gnomed_Bank" or self.Name == "cB_Gnomed_Armor" or self.Name == "cB_Gnomed_Weapon" or self.Name == "cB_Gnomed_Quest" or self.Name == "cB_Gnomed_Consumables" or self.Name == "cB_Gnomed_TradeGoods") then

		-- Caption and close button
		local caption = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		if(caption) then
			caption:SetText(self.Name)
			caption:SetPoint("TOPLEFT", 0, 0)
			self.Caption = caption

			local close = CreateFrame("Button", nil, self, "UIPanelCloseButton")
			close:SetPoint("TOPRIGHT", 5, 8)
			close:SetScript("OnClick", function(self) self:GetParent():Hide() end)
		end


	  if(self.Name == "cB_Gnomed_Bag" or self.Name == "cB_Gnomed_Bank") then
		-- The font string for bag space display
		-- You can see, it works with tags, - [free], [max], [used] are currently supported
		local space = self:SpawnPlugin("Space", "[free] / [max] free")
		if(space) then
			space:SetPoint("BOTTOMLEFT", self, 0, 0)
			space:SetJustifyH"LEFT"
		end

		-- The frame for money display
		local money = self:SpawnPlugin("Money")
		if(money) then
			money:SetPoint("BOTTOMLEFT", space, "TOPLEFT", 0,2)
		end

		 -- A nice bag bar for changing/toggling bags
		local bagType
		if(self.Name == "cB_Gnomed_Bag") then
			bagType = "bags"	-- We want to add all bags to our bag button bar
		else
			bagType = "bank"	-- the bank gets bank bags, of course
		end
		local bagButtons = self:SpawnPlugin("BagBar", bagType)
		if(bagButtons) then
			bagButtons:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 15)
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
		bagToggle:SetScript("OnClick", function()
			if(self.BagBar:IsShown()) then
				self.BagBar:Hide()
			else
				self.BagBar:Show()
			end
			self:UpdateDimensions()	-- The bag buttons take space, so let's update the height of the frame
		end)
		local bagToggleText = bagToggle:CreateFontString(nil, "OVERLAY")
		bagToggleText:SetPoint("CENTER", bagToggle)
		bagToggleText:SetFontObject(GameFontNormalSmall)
		bagToggleText:SetText("Bags")

	  end

	

	-- For purchasing bank slots
	if(self.Name == "cB_Gnomed_Bank") then
		local purchase = self:SpawnPlugin("Purchase")
		if(purchase) then
			purchase:SetText(BANKSLOTPURCHASE)
			purchase:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 20)
			if(self.BagBar) then purchase:SetParent(self.BagBar) end

			purchase.Cost = self:SpawnPlugin("Money", "static")
			purchase.Cost:SetParent(purchase)
			purchase.Cost:SetPoint("BOTTOMRIGHT", purchase, "TOPRIGHT", 0, 2)
		end
	end

	-- And the frame background!
	local color_rb
	local color_gb
	local color_bb
	local alpha_fb

	if (self.Name == "cB_Gnomed_Bank" or self.Name =="cB_Gnomed_Bank-Armor") then	
		color_rb = 0
		color_gb = 0,25
		color_bb = 0,53
		alpha_fb = 1
		
	else
		color_rb = 0
		color_gb = 0
		color_bb = 0
		alpha_fb = 1
	end		

	local background = CreateFrame("Frame", nil, self)
	background:SetBackdrop{
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true, tileSize = 16, 
		insets = {left = 0, right = 0, top = 0, bottom = 0},
	}
	background:SetFrameStrata("BACKGROUND")
	background:SetBackdropColor(color_rb,color_gb,color_bb,alpha_fb)

	background:SetPoint("TOPLEFT", 0,0)
	background:SetPoint("BOTTOMRIGHT",0,0)


	local frameborder = "Interface\\AddOns\\cargBags_Gnomed\\frameborder3"

	local TopLeft = self:CreateTexture(nil, "OVERLAY")
	TopLeft:SetTexture(frameborder)
	TopLeft:SetTexCoord(0, 1/3, 0, 1/3)
	TopLeft:SetPoint("TOPLEFT", self, -6, 6)
	TopLeft:SetWidth(20) TopLeft:SetHeight(20)
	TopLeft:SetVertexColor(color_rb,color_gb,color_bb,alpha_fb)

	local TopRight = self:CreateTexture(nil, "OVERLAY")
	TopRight:SetTexture(frameborder)
	TopRight:SetTexCoord(2/3, 1, 0, 1/3)
	TopRight:SetPoint("TOPRIGHT", self, 6, 6)
	TopRight:SetWidth(20) TopRight:SetHeight(20)
	TopRight:SetVertexColor(color_rb,color_gb,color_bb,alpha_fb)

	local BottomLeft = self:CreateTexture(nil, "OVERLAY")
	BottomLeft:SetTexture(frameborder)
	BottomLeft:SetTexCoord(0, 1/3, 2/3, 1)
	BottomLeft:SetPoint("BOTTOMLEFT", self, -6, -6)
	BottomLeft:SetWidth(20) BottomLeft:SetHeight(20)
	BottomLeft:SetVertexColor(color_rb,color_gb,color_bb,alpha_fb)

	local BottomRight = self:CreateTexture(nil, "OVERLAY")
	BottomRight:SetTexture(frameborder)
	BottomRight:SetTexCoord(2/3, 1, 2/3, 1)
	BottomRight:SetPoint("BOTTOMRIGHT", self, 6, -6)
	BottomRight:SetWidth(20) BottomRight:SetHeight(20)
	BottomRight:SetVertexColor(color_rb,color_gb,color_bb,alpha_fb)

	local TopEdge = self:CreateTexture(nil, "OVERLAY")
	TopEdge:SetTexture(frameborder)
	TopEdge:SetTexCoord(1/3, 2/3, 0, 1/3)
	TopEdge:SetPoint("TOPLEFT", TopLeft, "TOPRIGHT")
	TopEdge:SetPoint("TOPRIGHT", TopRight, "TOPLEFT")
	TopEdge:SetHeight(20)
	TopEdge:SetVertexColor(color_rb,color_gb,color_bb,alpha_fb)
		
	local BottomEdge = self:CreateTexture(nil, "OVERLAY")
	BottomEdge:SetTexture(frameborder)
	BottomEdge:SetTexCoord(1/3, 2/3, 2/3, 1)
	BottomEdge:SetPoint("BOTTOMLEFT", BottomLeft, "BOTTOMRIGHT")
	BottomEdge:SetPoint("BOTTOMRIGHT", BottomRight, "BOTTOMLEFT")
	BottomEdge:SetHeight(20)
	BottomEdge:SetVertexColor(color_rb,color_gb,color_bb,alpha_fb)
		
	local LeftEdge = self:CreateTexture(nil, "OVERLAY")
	LeftEdge:SetTexture(frameborder)
	LeftEdge:SetTexCoord(0, 1/3, 1/3, 2/3)
	LeftEdge:SetPoint("TOPLEFT", TopLeft, "BOTTOMLEFT")
	LeftEdge:SetPoint("BOTTOMLEFT", BottomLeft, "TOPLEFT")
	LeftEdge:SetWidth(20)
	LeftEdge:SetVertexColor(color_rb,color_gb,color_bb,alpha_fb)
		
	local RightEdge = self:CreateTexture(nil, "OVERLAY")
	RightEdge:SetTexture(frameborder)
	RightEdge:SetTexCoord(2/3, 1, 1/3, 2/3)
	RightEdge:SetPoint("TOPRIGHT", TopRight, "BOTTOMRIGHT")
	RightEdge:SetPoint("BOTTOMRIGHT", BottomRight, "TOPRIGHT")
	RightEdge:SetWidth(20)
	RightEdge:SetVertexColor(color_rb,color_gb,color_bb,alpha_fb)	

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

--local hideJunk = function(item) return not item.rarity or item.rarity > 0 end -- for nothing :)
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

-----------------
-- Bank filters
-----------------local onlyBankArmor = function(item) return item.bagID == -1 or (item.bagID >= 5 and item.bagID <= 11) and item.type and item.type == L.Armor end
local onlyBankWeapons = function(item) return item.bagID == -1 or (item.bagID >= 5 and item.bagID <= 11) and item.type and item.type == L.Weapon end
local onlyBankConsumables = function(item) return item.bagID == -1 or (item.bagID >= 5 and item.bagID <= 11) and item.type and item.type == L.Consumables end

-- Frames Spawns

--local bankArmor = cargBags:Spawn("cB_Gnomed_Bank-Armor",bank)
--bankArmor:SetFilter(onlyBankArmor, true)

-- Bank frame and bank bags
local bank = cargBags:Spawn("cB_Gnomed_Bank")
bank:SetFilter(onlyBank, true)
--bank:SetPoint("LEFT", 15, 0)

-- Stuff frames
local armor = cargBags:Spawn("cB_Gnomed_Armor",main)
armor:SetFilter(onlyArmor , true)
armor:SetFilter(hideEmpty, true)
--armor:SetPoint("BOTTOMRIGHT",UIParent,"RIGHT", -400,-200)

local weapon = cargBags:Spawn("cB_Gnomed_Weapon",main)
weapon:SetFilter(onlyWeapon, true)
weapon:SetFilter(hideEmpty, true)
--weapon:SetPoint("BOTTOMRIGHT", armor, "TOPRIGHT", 0,15)


-- Quest frame
local quest = cargBags:Spawn("cB_Gnomed_Quest",main)
quest:SetFilter(onlyQuest, true)
quest:SetFilter(hideEmpty, true)
--quest:SetPoint("BOTTOMRIGHT", weapon, "TOPRIGHT", 0,15)

-- Consumable
local consumables = cargBags:Spawn("cB_Gnomed_Consumables",main)
consumables:SetFilter(onlyConsumables, true)
consumables:SetFilter(hideEmpty, true)
--consumables:SetPoint("BOTTOMRIGHT", quest, "TOPRIGHT", 0,15)

-- Trade goods
local tgoods = cargBags:Spawn("cB_Gnomed_TradeGoods",main)
tgoods:SetFilter(onlyTradeGoods, true)
tgoods:SetFilter(hideEmpty, true)

-- Bagpack and bags
local main = cargBags:Spawn("cB_Gnomed_Bag")
main:SetFilter(onlyBags, true)
--main:SetPoint("RIGHT", -25, 0)

-- Keyring
local key = cargBags:Spawn("cB_Gnomed_Keyring")
key:SetFilter(onlyKeyring, true)
key:SetFilter(hideEmpty, true)
--key:SetPoint("TOPRIGHT", main, "BOTTOMRIGHT", 1, -15)

-- Now let's set the points
	-- Bags
main:SetPoint("RIGHT",-65,0)
key:SetPoint("BOTTOMLEFT",main,"TOPLEFT",0,15)
consumables:SetPoint("TOP",main,"BOTTOM",0,-15)
tgoods:SetPoint("TOP",consumables,"BOTTOM",0,-15)
armor:SetPoint("TOPRIGHT",main,"TOPLEFT",-15,0)
weapon:SetPoint("TOP",armor,"BOTTOM",0,-15)
quest:SetPoint("TOP",weapon,"BOTTOM",0,-15)
	-- Bank
bank:SetPoint("LEFT", 15, 0)
--bankArmor:SetPoint("TOPLEFT",bank,"BOTTOMLEFT",0,-15)


-- Opening / Closing Functions
function OpenCargBags()
	main:Show()
	armor:Show()
	weapon:Show()
	quest:Show()
	consumables:Show()
	tgoods:Show()
	--key:Show()
end

function CloseCargBags()
	main:Hide()
	bank:Hide()
	armor:Hide()
	weapon:Hide()
	quest:Hide()
	consumables:Hide()
	tgoods:Hide()
	key:Hide()
end


function ToggleCargBags(forceopen)
	if(main:IsShown() and not forceopen) then CloseCargBags() else OpenCargBags() end
end

-- To toggle containers when entering / leaving a bank
local bankToggle = CreateFrame"Frame"
bankToggle:RegisterEvent"BANKFRAME_OPENED"
bankToggle:RegisterEvent"BANKFRAME_CLOSED"
bankToggle:SetScript("OnEvent", function(self, event)
	if(event == "BANKFRAME_OPENED") then
		bank:Show()
		--bankArmor:Show()
	else
		bank:Hide()
		--bankArmor:Hide()
	end
end)

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
