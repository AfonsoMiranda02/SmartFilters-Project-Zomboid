SmartFilter = SmartFilter or {}
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"
require "ISUI/ISTickBox"
require "ISUI/ISScrollingListBox"
require "ISUI/ISColorPicker"

SmartFilterCreatorUI = ISPanel:derive("SmartFilterCreatorUI")

function SmartFilterCreatorUI:createChildren()
    ISPanel.createChildren(self)
    
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local btnHeight = math.max(20, fontHeight + 4)
    local margin = 10
    
    -- Filter Name
    local y = margin
    self.nameLabel = ISLabel:new(margin, y, fontHeight, "Filter Name:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.nameLabel)
    
    self.nameEntry = ISTextEntryBox:new("My Custom Filter", margin + 80, y, 200, btnHeight)
    self.nameEntry:initialise()
    self.nameEntry:instantiate()
    self:addChild(self.nameEntry)
    y = y + btnHeight + margin
    
    -- List Boxes Labels
    local listWidth = 175
    local listHeight = 200
    local btnX = margin + listWidth + margin
    local selectedX = btnX + 40 + margin
    
    self.availLabel = ISLabel:new(margin, y, fontHeight, "Available:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.availLabel)
    
    self.selLabel = ISLabel:new(selectedX, y, fontHeight, "Selected:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.selLabel)
    
    y = y + fontHeight + 5
    
    -- List Boxes
    self.availableList = ISScrollingListBox:new(margin, y, listWidth, listHeight)
    self.availableList:initialise()
    self.availableList:instantiate()
    self.availableList.itemheight = btnHeight
    self.availableList.font = UIFont.Small
    self.availableList.doDrawItem = SmartFilterCreatorUI.drawListItem
    self.availableList.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        list.parent.selectedList.selected = -1
    end
    self:addChild(self.availableList)
    
    self.btnAdd = ISButton:new(btnX, y + listHeight/2 - 25, 40, btnHeight, ">>", self, SmartFilterCreatorUI.onClickAdd)
    self.btnAdd:initialise()
    self.btnAdd:instantiate()
    self:addChild(self.btnAdd)
    
    self.btnRemove = ISButton:new(btnX, y + listHeight/2 + 5, 40, btnHeight, "<<", self, SmartFilterCreatorUI.onClickRemove)
    self.btnRemove:initialise()
    self.btnRemove:instantiate()
    self:addChild(self.btnRemove)
    
    self.selectedList = ISScrollingListBox:new(selectedX, y, listWidth, listHeight)
    self.selectedList:initialise()
    self.selectedList:instantiate()
    self.selectedList.itemheight = btnHeight
    self.selectedList.font = UIFont.Small
    self.selectedList.doDrawItem = SmartFilterCreatorUI.drawListItem
    self.selectedList.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        list.parent.availableList.selected = -1
    end
    self:addChild(self.selectedList)
    
    y = y + listHeight + margin
    
    -- Items Input Area
    self.itemsLabel = ISLabel:new(margin, y, fontHeight, "Specific Items Search or Drop here:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.itemsLabel)
    y = y + fontHeight + 2
    
    local searchWidth = self.width - margin*2
    
    self.itemsEntry = ISTextEntryBox:new("", margin, y, searchWidth, btnHeight)
    self.itemsEntry:initialise()
    self.itemsEntry:instantiate()
    self.itemsEntry.onTextChange = function(entry) SmartFilterCreatorUI.onSearchEntered(self, entry) end
    self:addChild(self.itemsEntry)
    
    y = y + btnHeight + margin
    
    local onDropItems = function(component, x, y)
        if ISMouseDrag.dragging ~= nil and type(ISMouseDrag.dragging) == "table" then
            local actualItems = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
            if actualItems then
                for _, item in ipairs(actualItems) do
                    if item and item.getFullType then
                        local id = item:getFullType()
                        local scriptItem = getScriptManager():getItem(id)
                        if scriptItem then
                            self:addSpecificItem(scriptItem)
                        end
                    end
                end
            end
            ISMouseDrag.dragging = nil
            if ISMouseDrag.draggingFocus then
                ISMouseDrag.draggingFocus:onMouseUp(0,0)
                ISMouseDrag.draggingFocus = nil
            end
        end
    end
    
    self.itemsEntry.onMouseUp = function(entry, mx, my)
        if ISTextEntryBox.onMouseUp then ISTextEntryBox.onMouseUp(entry, mx, my) end
        onDropItems(entry, mx, my)
    end
    
    -- Selected Items List
    self.specificItemsList = ISScrollingListBox:new(margin, y, self.width - margin*2, listHeight)
    self.specificItemsList:initialise()
    self.specificItemsList:instantiate()
    self.specificItemsList.itemheight = 36
    self.specificItemsList.font = UIFont.Small
    self.specificItemsList.doDrawItem = SmartFilterCreatorUI.drawSpecificItemRow
    self.specificItemsList.onMouseDown = function(list, lx, ly)
        ISScrollingListBox.onMouseDown(list, lx, ly)
        local row = list:rowAt(lx, ly)
        if row > 0 and row <= #list.items then
            if lx > list.width - 60 then
                list:removeItemByIndex(row)
            end
        end
    end
    self:addChild(self.specificItemsList)
    
    y = y + listHeight + margin
    y = y + btnHeight + margin
    
    -- Color Picker Button & Label
    self.colorLabel = ISLabel:new(margin + 210, y, fontHeight, "Highlight Color:", 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(self.colorLabel)
    
    self.btnColor = ISButton:new(margin + 210, y + fontHeight + 2, 80, btnHeight, "Pick Color", self, SmartFilterCreatorUI.onClickColorPick)
    self.btnColor:initialise()
    self.btnColor:instantiate()
    self.btnColor.backgroundColor = {r=1, g=0, b=0, a=1} -- Red by default
    self.highlightColor = {r=1, g=0, b=0, a=1}
    self:addChild(self.btnColor)
    
    -- Tick boxes
    self.tickBox = ISTickBox:new(margin, y, 200, btnHeight, "", self, SmartFilterCreatorUI.onTickBox)
    self.tickBox:initialise()
    self.tickBox:instantiate()
    self.tickBox:addOption("Filter by Category")
    self.tickBox:addOption("Filter by Specific Items")
    self.tickBox.selected[1] = true -- Usa a propriedade interna para forÃ§ar o visto
    self.tickBox.selected[2] = false
    self:addChild(self.tickBox)
    y = y + btnHeight*2 + margin
    
    -- Save/Cancel
    self.btnSave = ISButton:new(self.width/2 - 60, y, 50, btnHeight, "Save Filter", self, SmartFilterCreatorUI.onClickSave)
    self.btnSave:initialise()
    self.btnSave:instantiate()
    self:addChild(self.btnSave)
    
    self.btnCancel = ISButton:new(self.width/2 + 10, y, 50, btnHeight, "Cancel", self, SmartFilterCreatorUI.close)
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self:addChild(self.btnCancel)
    
    -- A Dropdown List tem de ser adicionada no fim para desenhar POR CIMA das outras coisas!
    self.searchDropdown = ISScrollingListBox:new(margin, self.itemsEntry:getY() + self.itemsEntry:getHeight(), searchWidth, 160)
    self.searchDropdown:initialise()
    self.searchDropdown:instantiate()
    self.searchDropdown.itemheight = 36
    self.searchDropdown.font = UIFont.Small
    self.searchDropdown.doDrawItem = SmartFilterCreatorUI.drawSearchDropdownRow
    self.searchDropdown.onMouseDown = function(list, lx, ly)
        local row = list:rowAt(lx, ly)
        if row > 0 and row <= #list.items then
            local scriptItem = list.items[row].item
            self:addSpecificItem(scriptItem)
            list:setVisible(false)
            self.itemsEntry:setText("")
        end
    end
    self.searchDropdown.onMouseDownOutside = function(list, lx, ly)
        if list:isVisible() then list:setVisible(false) end
    end
    self.searchDropdown:setVisible(false)
    self:addChild(self.searchDropdown)
    
    self:populateCategories()
    
    -- -------------------------------------------------------------------------
    -- EDIT MODE: Pre-carregar dados se estivermos a editar
    -- -------------------------------------------------------------------------
    if self.editFilterName then
        local modData = getPlayer():getModData()
        local fData = modData.SmartFilters and modData.SmartFilters[self.editFilterName]
        if fData then
            self.nameEntry:setText(self.editFilterName)
            if fData.specificItems and fData.specificItems ~= "" then
                -- O specificItems era guardado como "Base.Axe, Base.Apple"
                for itemID in string.gmatch(fData.specificItems, "([^,]+)") do
                    itemID = itemID:match("^%s*(.-)%s*$")
                    local scriptItem = getScriptManager():getItem(itemID)
                    if scriptItem then
                        self:addSpecificItem(scriptItem)
                    end
                end
            end
            
            self.tickBox.selected[1] = fData.useCategories == true
            self.tickBox.selected[2] = fData.useItems == true
            
            if fData.highlightColor then
                self.highlightColor = fData.highlightColor
                self.btnColor.backgroundColor = {r = fData.highlightColor.r, g = fData.highlightColor.g, b = fData.highlightColor.b, a = 1}
            end
            
            -- Mover as categorias selecionadas da esquerda para a direita
            if fData.categories then
                for _, cat in ipairs(fData.categories) do
                    -- Encontrar na lista da esquerda
                    for i, item in ipairs(self.availableList.items) do
                        if item.item == cat then
                            self.selectedList:addItem(item.text, item.item)
                            self.availableList:removeItemByIndex(i)
                            break
                        end
                    end
                end
            end
            
            -- Guardamos o estado antigo do highlightActive para nÃ£o perder
            self.oldHighlightActive = fData.highlightActive
        end
    end
end

function SmartFilterCreatorUI:populateCategories()
    -- Preenche a lista da esquerda com todas as categorias do jogo
    local uniqueCategories = {}
    local player = getPlayer()
    local inventory = player:getInventory()
    
    local commonCats = {"Weapon", "Food", "Medical", "Clothing", "Container", "Literature", "Animal", "Tool", "Material", "Fishing", "Farming"}
    for _, cat in ipairs(commonCats) do
        uniqueCategories[cat] = cat
    end
    
    if inventory then
        local items = inventory:getItems()
        for i=0, items:size()-1 do
            local item = items:get(i)
            local fullCat = item:getDisplayCategory() or item:getCategory()
            if fullCat then
                for catID in string.gmatch(fullCat, "[^/]+") do
                    catID = catID:match("^%s*(.-)%s*$")
                    if catID ~= "" then
                        local baseCat = catID
                        local masterGroups = {"Weapon", "Container", "Clothing", "Food", "Literature", "Bag", "Tool", "Ammo"}
                        
                        for _, group in ipairs(masterGroups) do
                            if string.find(catID, group, 1, true) then
                                baseCat = group
                                break
                            end
                        end
                        
                        if baseCat ~= "" then
                            uniqueCategories[baseCat] = baseCat
                        end
                    end
                end
            end
        end
    end
    
    local sorted = {}
    for cat, _ in pairs(uniqueCategories) do table.insert(sorted, cat) end
    table.sort(sorted)
    
    for _, cat in ipairs(sorted) do
        self.availableList:addItem(cat, cat)
    end
end

function SmartFilterCreatorUI:drawListItem(y, item, alt)
    -- O 'self' aqui dentro Ã© a ISScrollingListBox e nÃ£o o SmartFilterCreatorUI
    local isSelected = self.selected == item.itemindex
    
    if isSelected then
        self:drawRect(0, y, self:getWidth(), item.height, 0.3, 0.7, 0.35, 0.15)
        self:drawRectBorder(0, y, self:getWidth(), item.height, 0.9, 1, 1, 1)
    elseif alt then
        self:drawRect(0, y, self:getWidth(), item.height, 0.15, 0.3, 0.3, 0.3)
    end
    
    local textHeight = getTextManager():getFontHeight(self.font)
    local textY = y + (item.height - textHeight) / 2
    
    -- Texto desenhado com margem de 10 pixels Ã  esquerda para nÃ£o colar Ã  borda
    self:drawText(item.text, 10, textY, 1, 1, 1, 1, self.font)
    
    return y + item.height
end

function SmartFilterCreatorUI:onClickAdd()
    local selectedIndex = self.availableList.selected
    local selectedItem = self.availableList.items[selectedIndex]
    if not selectedItem then return end
    
    -- Adiciona Ã  lista da direita
    self.selectedList:addItem(selectedItem.text, selectedItem.item)
    
    -- Remove da lista da esquerda
    self.availableList:removeItemByIndex(selectedIndex)
    
    -- MantÃ©m a seleÃ§Ã£o no item que subiu para ocupar o lugar
    if selectedIndex > #self.availableList.items then
        self.availableList.selected = #self.availableList.items
    else
        self.availableList.selected = selectedIndex
    end
end

function SmartFilterCreatorUI:onClickRemove()
    local selectedIndex = self.selectedList.selected
    local selectedItem = self.selectedList.items[selectedIndex]
    if not selectedItem then return end
    
    -- Adiciona de volta Ã  lista da esquerda
    self.availableList:addItem(selectedItem.text, selectedItem.item)
    
    -- Ordena a lista da esquerda alfabeticamente para ficar arrumada
    table.sort(self.availableList.items, function(a, b) return a.text < b.text end)
    
    -- Remove da lista da direita
    self.selectedList:removeItemByIndex(selectedIndex)
    
    -- MantÃ©m a seleÃ§Ã£o
    if selectedIndex > #self.selectedList.items then
        self.selectedList.selected = #self.selectedList.items
    else
        self.selectedList.selected = selectedIndex
    end
end

function SmartFilterCreatorUI:onClickSave()
    local filterName = self.nameEntry:getText()
    if filterName == "" or filterName == "My Custom Filter" then 
        filterName = "New Filter " .. ZombRand(100)
    end
    
    local modData = getPlayer():getModData()
    modData.SmartFilters = modData.SmartFilters or {}
    
    -- Se o nome jÃ¡ existe E nÃ£o somos nÃ³s prÃ³prios a editar o nosso nome para o mesmo
    if modData.SmartFilters[filterName] and self.editFilterName ~= filterName then
        local modal = ISModalDialog:new(0, 0, 250, 150, "A filter named '" .. filterName .. "' already exists. Overwrite?", true, self, SmartFilterCreatorUI.onConfirmOverwrite)
        modal.filterNameToSave = filterName
        modal:initialise()
        modal:addToUIManager()
        return
    end
    
    self:performSave(filterName)
end

function SmartFilterCreatorUI:onConfirmOverwrite(button)
    if button.internal == "YES" then
        self:performSave(button.parent.filterNameToSave)
    end
end

function SmartFilterCreatorUI:performSave(filterName)
    local categories = {}
    for _, item in ipairs(self.selectedList.items) do
        table.insert(categories, item.item)
    end
    
    local itemsStr = ""
    for i, item in ipairs(self.specificItemsList.items) do
        local id = item.item:getFullName()
        if i == 1 then
            itemsStr = id
        else
            itemsStr = itemsStr .. ", " .. id
        end
    end
    
    local useCategories = self.tickBox:isSelected(1)
    local useItems = self.tickBox:isSelected(2)
    
    local modData = getPlayer():getModData()
    modData.SmartFilters = modData.SmartFilters or {}
    
    -- Se editÃ¡mos o nome, apagamos o filtro antigo!
    if self.editFilterName and self.editFilterName ~= filterName then
        modData.SmartFilters[self.editFilterName] = nil
    end
    
    local filterData = {
        name = filterName,
        categories = categories,
        specificItems = itemsStr,
        useCategories = useCategories,
        useItems = useItems,
        highlightColor = self.highlightColor,
        highlightActive = self.oldHighlightActive or false,
        isPlayerFilter = true
    }
    
    modData.SmartFilters[filterName] = filterData
    
    self:close()
    
    if SmartFilter.managerUI and SmartFilter.managerUI:getIsVisible() then
        SmartFilter.managerUI:populateList()
    end
end

function SmartFilterCreatorUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function SmartFilterCreatorUI:new(x, y, width, height, editFilterName)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.moveWithMouse = true
    o.editFilterName = editFilterName
    return o
end

-- =========================================================================
-- FUNÃ‡ÃƒO GLOBAL PARA ABRIR A UI
-- =========================================================================
function SmartFilter.openCreatorUI(filterName)
    local ui = SmartFilterCreatorUI:new(getCore():getScreenWidth()/2 - 220, getCore():getScreenHeight()/2 - 325, 440, 650, filterName)
    ui:initialise()
    ui:instantiate()
    ui:addToUIManager()
end

function SmartFilterCreatorUI:onTickBox(index, selected)
    -- FunÃ§Ã£o vazia apenas para evitar erros quando clicas na checkbox
end

function SmartFilterCreatorUI:onClickColorPick()
    local colorPicker = ISColorPicker:new(self:getAbsoluteX() + self:getWidth(), self:getAbsoluteY(), nil)
    colorPicker:initialise()
    colorPicker.keepOnScreen = true
    colorPicker.pickedTarget = self
    colorPicker.pickedFunc = SmartFilterCreatorUI.onColorPicked
    colorPicker:addToUIManager()
end

function SmartFilterCreatorUI:onColorPicked(color, mouseUp)
    -- O Zomboid retorna um ColorInfo object que usa funÃ§Ãµes getR(), getG(), getB()
    local r = color.r or (color.getR and color:getR()) or 1
    local g = color.g or (color.getG and color:getG()) or 1
    local b = color.b or (color.getB and color:getB()) or 1
    
    self.highlightColor = {r = r, g = g, b = b, a = 1}
    self.btnColor.backgroundColor = {r = r, g = g, b = b, a = 1}
end

-- =========================================================================
-- SPECIFIC ITEMS LOGIC & RENDERING
-- =========================================================================

function SmartFilterCreatorUI:onSearchEntered(entry)
    local rawText = entry:getText()
    if not rawText or rawText == "" then 
        self.searchDropdown:setVisible(false)
        return
    end
    
    local query = string.lower(rawText)
    self.searchDropdown:clear()
    
    local allItems = getScriptManager():getAllItems()
    local added = 0
    for i=0, allItems:size()-1 do
        local scriptItem = allItems:get(i)
        if not scriptItem:getObsolete() then
            local rawName = scriptItem:getDisplayName()
            local displayName = rawName and string.lower(rawName) or ""
            
            local rawFull = scriptItem:getFullName()
            local fullName = rawFull and string.lower(rawFull) or ""
            
            if string.find(displayName, query, 1, true) or string.find(fullName, query, 1, true) then
                self.searchDropdown:addItem(rawName or fullName, scriptItem)
                added = added + 1
                if added > 50 then break end -- Limite para não crashar
            end
        end
    end
    
    if added > 0 then
        self.searchDropdown:setVisible(true)
    else
        self.searchDropdown:setVisible(false)
    end
end

function SmartFilterCreatorUI:addSpecificItem(scriptItem)
    if not scriptItem then return end
    -- Check for duplicates
    for _, item in ipairs(self.specificItemsList.items) do
        if item.item:getFullName() == scriptItem:getFullName() then
            return
        end
    end
    self.specificItemsList:addItem(scriptItem:getDisplayName(), scriptItem)
end

function SmartFilterCreatorUI:drawSearchDropdownRow(y, item, alt)
    local isSelected = self.selected == item.itemindex
    
    if isSelected then
        self:drawRect(0, y, self:getWidth(), item.height, 0.3, 0.7, 0.35, 0.15)
    elseif alt then
        self:drawRect(0, y, self:getWidth(), item.height, 0.15, 0.3, 0.3, 0.3)
    else
        self:drawRect(0, y, self:getWidth(), item.height, 1.0, 0.1, 0.1, 0.1)
    end
    
    local scriptItem = item.item
    local icon = scriptItem:getIcon()
    if icon then
        local tex = Texture.getSharedTexture('Item_' .. icon)
        if tex then
            self:drawTextureScaledAspect(tex, 4, y + 4, 28, 28, 1, 1, 1, 1)
        end
    end
    
    self:drawText(scriptItem:getDisplayName(), 40, y + (item.height - 14)/2, 1, 1, 1, 1, self.font)
    self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, 0.5, 0.5, 1)
    
    return y + item.height
end

function SmartFilterCreatorUI:drawSpecificItemRow(y, item, alt)
    local isHovered = self:isMouseOver() and self:rowAt(self:getMouseX(), self:getMouseY()) == item.itemindex
    
    if alt then
        self:drawRect(0, y, self:getWidth(), item.height, 0.15, 0.3, 0.3, 0.3)
    end
    
    local scriptItem = item.item
    local icon = scriptItem:getIcon()
    if icon then
        local tex = Texture.getSharedTexture('Item_' .. icon)
        if tex then
            self:drawTextureScaledAspect(tex, 4, y + 4, 28, 28, 1, 1, 1, 1)
        end
    end
    
    self:drawText(scriptItem:getDisplayName(), 40, y + 4, 1, 1, 1, 1, self.font)
    self:drawText(scriptItem:getFullName(), 40, y + 18, 0.5, 0.5, 0.5, 1, UIFont.Small)
    
    if isHovered then
        self:drawRect(self.width - 60, y + 4, 50, item.height - 8, 1.0, 0.8, 0.2, 0.2)
        self:drawTextCentre('Remove', self.width - 35, y + (item.height - 14)/2, 1, 1, 1, 1, self.font)
    end
    
    self:drawRectBorder(0, y, self:getWidth(), item.height, 0.2, 0.5, 0.5, 0.5)
    
    return y + item.height
end


