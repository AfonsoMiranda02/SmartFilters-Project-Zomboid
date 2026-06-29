SmartFilter = SmartFilter or {}

if not SmartFilter.original_onFilterMenu then
    SmartFilter.original_onFilterMenu = ISInventoryPane.onFilterMenu
end

-- =========================================================================
-- [ISContextMenu Hook] Prevents the context menu from closing when 
-- clicking on toggle options like ON/OFF for Highlights.
-- =========================================================================
if not SmartFilter.original_ISContextMenu_onMouseUp then
    SmartFilter.original_ISContextMenu_onMouseUp = ISContextMenu.onMouseUp
    function ISContextMenu:onMouseUp(x, y)
        if self.mouseOver ~= -1 and self:getIsVisible() then
            local option = self.options[self.mouseOver]
            if option and option.keepMenuOpen then
                if option.onSelect and not option.notAvailable and not option.isDisabled then
                    ISContextMenu.globalPlayerContext = self.player
                    option.onSelect(option.target, option.param1, option.param2, option.param3)
                    
                    if option.isHighlightToggle then
                        local isOnOpt = option.param2
                        for _, sibling in ipairs(self.options) do
                            if sibling.isHighlightToggle and sibling.param1 == option.param1 then
                                if sibling.param2 == true then
                                    sibling.name = isOnOpt and "[V] ON" or "ON"
                                else
                                    sibling.name = not isOnOpt and "[V] OFF" or "OFF"
                                end
                            end
                        end
                    end
                end
                return
            end
        end
        SmartFilter.original_ISContextMenu_onMouseUp(self, x, y)
    end
end

-- =========================================================================
-- [Menu Injection] Injects the custom Filter menus into the vanilla 
-- Zomboid Inventory Context Menu.
-- =========================================================================
function ISInventoryPane:onFilterMenu(button)
    SmartFilter.original_onFilterMenu(self, button)
    
    local context = getPlayerContextMenu(self.player)
    
    if context then
        
        local filterSubMenu = ISContextMenu:getNew(context)
        context:addSubMenu(context:addOption("Filter", nil, nil), filterSubMenu)
        
        local zomboidSubMenu = ISContextMenu:getNew(filterSubMenu)
        filterSubMenu:addSubMenu(filterSubMenu:addOption("Zomboid", nil, nil), zomboidSubMenu)
        
        local playerSubMenu = ISContextMenu:getNew(filterSubMenu)
        filterSubMenu:addSubMenu(filterSubMenu:addOption("Player", nil, nil), playerSubMenu)

        filterSubMenu:addOption("Clear Filters", self, SmartFilter.applyFilter, "All")

        playerSubMenu:addOption("Create a New Filter", nil, SmartFilter.openCreatorUI, nil)
        
        playerSubMenu:addOption("Edit a Filter", nil, SmartFilter.openManagerUI, nil)
        
        local highlightsSubMenu = ISContextMenu:getNew(playerSubMenu)
        playerSubMenu:addSubMenu(playerSubMenu:addOption("Highlights", nil, nil), highlightsSubMenu)
        
        local modData = getPlayer():getModData()
        if modData.SmartFilters then
            for fName, fData in pairs(modData.SmartFilters) do
                local filterHighlightSub = ISContextMenu:getNew(highlightsSubMenu)
                local opt = highlightsSubMenu:addOption(fName, nil, nil)
                highlightsSubMenu:addSubMenu(opt, filterHighlightSub)
                
                local isOn = fData.highlightActive
                
                local onText = "ON"
                if isOn then onText = "[V] ON" end
                local onOpt = filterHighlightSub:addOption(onText, nil, SmartFilter.toggleHighlight, fName, true)
                onOpt.keepMenuOpen = true
                onOpt.isHighlightToggle = true
                
                local offText = "OFF"
                if not isOn then offText = "[V] OFF" end
                local offOpt = filterHighlightSub:addOption(offText, nil, SmartFilter.toggleHighlight, fName, false)
                offOpt.keepMenuOpen = true
                offOpt.isHighlightToggle = true
            end
        end

        -- D) Filtros criados pelo jogador prontos a aplicar
        if modData.SmartFilters then
            for fName, fData in pairs(modData.SmartFilters) do
                playerSubMenu:addOption(fName, self, SmartFilter.applyFilter, fData)
            end
        end

        -- Adicionamos as opções na aba do Zomboid!
        zomboidSubMenu:addOption("All", self, SmartFilter.applyFilter, "All")
        
        -- [Dynamic Categories] Reads the current inventory and dynamically 
        -- generates filter options based only on what the player actually has.
        local uniqueCategories = {}
        local items = self.inventory:getItems()
        
        for i=0, items:size()-1 do
            local item = items:get(i)
            local fullCat = item:getDisplayCategory() or item:getCategory()
            
            if fullCat then
                -- O Zomboid junta categorias com "/" (ex: "Weapon/Fishing")
                for catID in string.gmatch(fullCat, "[^/]+") do
                    catID = catID:match("^%s*(.-)%s*$")
                    
                    if catID ~= "" then
                        -- Agrupamento inteligente de categorias: se o nome da categoria contiver
                        -- uma destas palavras-chave principais, agrupamos tudo na palavra-chave.
                        -- Exemplo: "WaterContainer" -> "Container", "Melee Weapon" -> "Weapon"
                        local baseCat = catID
                        local masterGroups = {"Weapon", "Container", "Clothing", "Food", "Literature", "Bag", "Tool", "Ammo"}
                        
                        for _, group in ipairs(masterGroups) do
                            if string.find(catID, group, 1, true) then
                                baseCat = group
                                break
                            end
                        end
                        
                        if baseCat ~= "" and not uniqueCategories[baseCat] then
                            uniqueCategories[baseCat] = baseCat
                        end
                    end
                end
            end
        end
        
        -- Ordenar as categorias alfabeticamente para o menu ficar bonito
        local sortedCatIDs = {}
        for catID, _ in pairs(uniqueCategories) do
            table.insert(sortedCatIDs, catID)
        end
        table.sort(sortedCatIDs, function(a, b) return uniqueCategories[a] < uniqueCategories[b] end)
        
        -- Adicionar as opções geradas dinamicamente ao menu do ZOMBOID
        for _, catID in ipairs(sortedCatIDs) do
            zomboidSubMenu:addOption(uniqueCategories[catID], self, SmartFilter.applyFilter, catID)
        end
        
    end
end

function SmartFilter.applyFilter(target, filterTypeOrData)
    local inventoryPane = target
    if not inventoryPane or not inventoryPane.inventory then return end
    
    -- Verifica se recebemos uma string (Zomboid) ou uma tabela de dados (Player Filter)
    if type(filterTypeOrData) == "table" then
        inventoryPane.smartFilterActive = filterTypeOrData.name
        inventoryPane.smartFilterData = filterTypeOrData
    else
        inventoryPane.smartFilterActive = filterTypeOrData
        inventoryPane.smartFilterData = nil
    end
    
    -- Forçamos a UI a atualizar a lista de itens!
    inventoryPane:refreshContainer()
end

-- =========================================================================
-- [Highlight System] Intercepts the rendering of inventory items to 
-- draw custom colored backgrounds behind items that match active filters.
-- =========================================================================
if not SmartFilter.original_render then
    SmartFilter.original_render = ISInventoryPane.render
end

function ISInventoryPane:render()
    -- Precisamos saber se há filtros ativos antes de desenhar
    local modData = getPlayer():getModData()
    local activeFilters = {}
    
    if self.mode == "details" and self.itemslist and modData and modData.SmartFilters then
        for fName, fData in pairs(modData.SmartFilters) do
            if fData.highlightActive then
                table.insert(activeFilters, fData)
            end
        end
    end
    
    -- Desenha os nossos highlights PRIMEIRO (por trás de tudo)
    if #activeFilters > 0 then
        local y = 0
        for k, v in ipairs(self.itemslist) do
            local count = 1
            if self.collapsed and not self.collapsed[v.name] then
                count = v.count or #v.items
            end
            
            for i = 1, count do
                if v.items and v.items[i] then
                    self:checkAndDrawHighlight(v.items[i], y, activeFilters)
                    y = y + 1
                end
            end
        end
    end
    
    -- Chama o original POR ÚLTIMO (desenha o texto, ícones e sombreados originais POR CIMA das nossas cores!)
    if SmartFilter.original_render then
        SmartFilter.original_render(self)
    end
end

function ISInventoryPane:checkAndDrawHighlight(item, y, activeFilters)
    if type(item) ~= "userdata" then return end
    
    local highlightColor = nil
    local itemID = item:getFullType()
    local itemCat = item:getDisplayCategory() or item:getCategory()
    
    for _, fData in ipairs(activeFilters) do
        local matches = false
        
        if fData.useItems and fData.specificItems and fData.specificItems ~= "" then
            if string.find(fData.specificItems, itemID, 1, true) then
                matches = true
            end
        end
        
        if not matches and fData.useCategories and itemCat and fData.categories then
            for _, cat in ipairs(fData.categories) do
                if string.find(itemCat, cat, 1, true) then
                    matches = true
                    break
                end
            end
        end
        
        if matches and fData.highlightColor then
            highlightColor = fData.highlightColor
            break
        end
    end
    
    if highlightColor then
        local top = self.headerHgt + y * self.itemHgt
        local screenY = top + self:getYScroll()
        
        -- Apenas desenhar se estiver visível na janela
        if screenY + self.itemHgt > 0 and screenY < self.height then
            -- Opacidade reduzida para 0.25 para não carregar tanto visualmente
            self:drawRect(1, top, self.column4 or self:getWidth() - 2, self.itemHgt, 0.25, highlightColor.r, highlightColor.g, highlightColor.b)
        end
    end
end

function SmartFilter.toggleHighlight(target, filterName, state)
    local modData = getPlayer():getModData()
    if modData.SmartFilters and modData.SmartFilters[filterName] then
        modData.SmartFilters[filterName].highlightActive = state
    end
end

function SmartFilter.deleteFilter(target, filterName, pane)
    local modData = getPlayer():getModData()
    if modData.SmartFilters and modData.SmartFilters[filterName] then
        modData.SmartFilters[filterName] = nil
        if pane and pane.smartFilterActive == filterName then
            pane.smartFilterActive = "All"
            pane:refreshContainer()
        end
    end
end

-- =========================================================================
-- [Filter Logic] Hooks into refreshContainer to hide items that do not 
-- match the currently active smart filter or search bar text.
-- =========================================================================
if not SmartFilter.original_refreshContainer then
    SmartFilter.original_refreshContainer = ISInventoryPane.refreshContainer
end

function ISInventoryPane:refreshContainer()
    -- 1. Deixamos o jogo carregar e ordenar TODOS os itens normalmente
    SmartFilter.original_refreshContainer(self)
    
    -- 2. Se houver um filtro ativo ou uma pesquisa de texto
    local hasFilter = (self.smartFilterActive and self.smartFilterActive ~= "All")
    local hasSearch = (self.smartSearchText and self.smartSearchText ~= "")
    
    if hasFilter or hasSearch then
        local filteredList = {}
        local searchText = hasSearch and string.lower(self.smartSearchText) or ""
        
        -- 3. Percorremos a lista de pilhas de itens (stacks) que o jogo gerou
        for i, stack in ipairs(self.itemslist) do
            -- stack.items[1] é sempre um item válido dessa pilha
            local item = stack.items[1]
            
            if item then
                local itemCat = item:getDisplayCategory() or item:getCategory()
                local itemID = item:getFullType() -- ex: Base.Axe
                local itemName = string.lower(item:getName())
                
                local matchesFilter = not hasFilter
                local matchesSearch = not hasSearch
                
                -- Verifica Filtros de Categoria/Itens
                if hasFilter then
                    if self.smartFilterData then
                        local data = self.smartFilterData
                        local matched = false
                        
                        if data.useCategories and itemCat and data.categories then
                            for _, savedCat in ipairs(data.categories) do
                                if string.find(itemCat, savedCat, 1, true) then
                                    matched = true
                                    break
                                end
                            end
                        end
                        
                        if data.useItems and itemID and not matched and data.specificItems then
                            if string.find(data.specificItems, itemID, 1, true) then
                                matched = true
                            end
                        end
                        matchesFilter = matched
                    else
                        if itemCat and string.find(itemCat, self.smartFilterActive, 1, true) then
                            matchesFilter = true
                        end
                    end
                end
                
                -- Verifica Pesquisa de Texto
                if hasSearch then
                    if string.find(itemName, searchText, 1, true) or (itemID and string.find(string.lower(itemID), searchText, 1, true)) then
                        matchesSearch = true
                    end
                end
                
                if matchesFilter and matchesSearch then
                    table.insert(filteredList, stack)
                end
            end
        end
        
        -- 4. Substituímos a lista mostrada pela nossa lista filtrada!
        self.itemslist = filteredList
    end
end

-- =========================================================================
-- [Search Bar Injection] Injects a text entry box into the inventory header
-- to allow real-time item searching by name or ID.
-- =========================================================================
if not SmartFilter.original_ISInventoryPage_createChildren then
    SmartFilter.original_ISInventoryPage_createChildren = ISInventoryPage.createChildren
end

function ISInventoryPage:createChildren()
    SmartFilter.original_ISInventoryPage_createChildren(self)
    
    -- Calcular a largura do texto do título (ex: "Inventory" ou "Loot")
    local titleWidth = getTextManager():MeasureStringX(UIFont.Small, self.title or "Inventory")
    local fontHgt = getTextManager():getFontHeight(UIFont.Small)
    local buttonHeight = math.max(16, fontHgt + 1) - 2
    local buttonOffset = 1 + (5 - getCore():getOptionFontSizeReal()) * 2
    
    -- Posição: Encostado ao botão de informação (i)
    local startX = (self.infoButton and self.infoButton:getRight() or 0) + buttonOffset + 5
    
    -- Se for o inventário do jogador (onCharacter), o Zomboid escreve "Inventory" ou a capacidade,
    -- por isso damos um avanço para não sobrepor o texto!
    if self.onCharacter then
        local titleWidth = getTextManager():MeasureStringX(UIFont.Small, self.title or "Inventory")
        startX = startX + titleWidth + 10
    end
    
    -- Ícone de Lupa do Zomboid
    local iconTex = getTexture("media/ui/Search_Icon_Off.png")
    self.smartSearchIcon = ISImage:new(startX, 1, buttonHeight, buttonHeight, iconTex)
    self.smartSearchIcon:initialise()
    self.smartSearchIcon:instantiate()
    self.smartSearchIcon.scaledWidth = buttonHeight
    self.smartSearchIcon.scaledHeight = buttonHeight
    self:addChild(self.smartSearchIcon)
    
    startX = startX + buttonHeight + 2
    local barWidth = 100
    
    self.smartSearchBar = ISTextEntryBox:new("", startX, 1, barWidth, buttonHeight)
    self.smartSearchBar.font = UIFont.Small
    self.smartSearchBar.tooltip = "Search items by name or ID..."
    self.smartSearchBar:initialise()
    self.smartSearchBar:instantiate()
    
    -- Quando o texto muda, atualiza a lista de itens instantaneamente
    self.smartSearchBar.onTextChange = function(entry)
        if self.inventoryPane then
            self.inventoryPane.smartSearchText = entry:getText()
            self.inventoryPane:refreshContainer()
        end
    end
    
    self:addChild(self.smartSearchBar)
end