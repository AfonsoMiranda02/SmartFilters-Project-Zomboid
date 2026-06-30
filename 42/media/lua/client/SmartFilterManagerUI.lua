SmartFilterManagerUI = ISPanel:derive("SmartFilterManagerUI")
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISScrollingListBox"
require "ISUI/ISModalDialog"

function SmartFilterManagerUI:createChildren()
    ISPanel.createChildren(self)
    
    local margin = 15
    local btnHeight = 25
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local titleHeight = getTextManager():getFontHeight(UIFont.Medium)
    
    -- [Title Label]
    self.titleLabel = ISLabel:new(self.width / 2, margin, titleHeight, getText("IGUI_SmartFilter_ManagerTitle"), 1, 1, 1, 1, UIFont.Medium, true)
    self.titleLabel.center = true
    self:addChild(self.titleLabel)
    
    local listY = margin * 2 + titleHeight
    local listHeight = self.height - listY - btnHeight - margin * 2
    
    -- [Filter List]
    self.filterList = ISScrollingListBox:new(margin, listY, self.width - margin*2, listHeight)
    self.filterList:initialise()
    self.filterList:instantiate()
    self.filterList.itemheight = btnHeight
    self.filterList.font = UIFont.Small
    self.filterList.doDrawItem = SmartFilterManagerUI.drawListItem
    self.filterList.drawBorder = true
    self:addChild(self.filterList)
    
    self:populateList()
    
    -- [Action Buttons]
    local btnY = self.height - btnHeight - margin
    local btnWidth = 80
    
    self.btnEdit = ISButton:new(margin, btnY, btnWidth, btnHeight, getText("IGUI_SmartFilter_ManagerEdit"), self, SmartFilterManagerUI.onClickEdit)
    self.btnEdit:initialise()
    self.btnEdit:instantiate()
    self.btnEdit.borderColor = {r=1, g=1, b=1, a=0.3}
    self:addChild(self.btnEdit)
    
    self.btnDelete = ISButton:new(margin + btnWidth + 10, btnY, btnWidth, btnHeight, getText("IGUI_SmartFilter_ManagerDelete"), self, SmartFilterManagerUI.onClickDelete)
    self.btnDelete:initialise()
    self.btnDelete:instantiate()
    self.btnDelete.borderColor = {r=1, g=0, b=0, a=0.5}
    self.btnDelete.textColor = {r=1, g=0.3, b=0.3, a=1}
    self:addChild(self.btnDelete)
    
    self.btnCancel = ISButton:new(self.width - btnWidth - margin, btnY, btnWidth, btnHeight, getText("IGUI_SmartFilter_CreatorCancel"), self, SmartFilterManagerUI.close)
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self.btnCancel.borderColor = {r=1, g=1, b=1, a=0.3}
    self:addChild(self.btnCancel)
end

function SmartFilterManagerUI:populateList()
    self.filterList:clear()
    local smartFilters = SmartFilterSettings.getFilters()
    if smartFilters then
        for fName, fData in pairs(smartFilters) do
            self.filterList:addItem(fName, fName)
        end
    end
end

function SmartFilterManagerUI:drawListItem(y, item, alt)
    local a = 0.9
    self:drawRectBorder(0, y, self:getWidth(), self.itemheight - 1, a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.3, 0.2, 1.0, 0.2)
    elseif alt then
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.15, 0.0, 0.0, 0.0)
    end

    self:drawText(item.text, 10, y + (self.itemheight - getTextManager():getFontHeight(self.font)) / 2, 1, 1, 1, 1, self.font)
    return y + self.itemheight
end

function SmartFilterManagerUI:onClickEdit()
    local selectedItem = self.filterList.items[self.filterList.selected]
    if selectedItem then
        local filterName = selectedItem.item
        self:setVisible(false)
        self:removeFromUIManager()
        SmartFilter.openCreatorUI(filterName)
    end
end

function SmartFilterManagerUI:onClickDelete()
    local selectedItem = self.filterList.items[self.filterList.selected]
    if selectedItem then
        local filterName = selectedItem.item
        -- Native dialog confirmation
        local modal = ISModalDialog:new(self:getAbsoluteX() + 50, self:getAbsoluteY() + 50, 300, 150, getText("IGUI_SmartFilter_ManagerConfirmDelete", filterName), true, self, SmartFilterManagerUI.onConfirmDelete, nil, filterName)
        modal:initialise()
        modal:addToUIManager()
    end
end

function SmartFilterManagerUI:onConfirmDelete(button, filterName)
    if button.internal == "YES" then
        if SmartFilter.deleteFilter then
            SmartFilter.deleteFilter(nil, filterName, nil)
        end
        self:populateList()
    end
end

function SmartFilterManagerUI:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function SmartFilterManagerUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0, g=0, b=0, a=0.85}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.moveWithMouse = true
    return o
end

-- =========================================================================
-- [Global Function] Opens the Manager UI
-- =========================================================================
function SmartFilter.openManagerUI()
    local ui = SmartFilterManagerUI:new(getCore():getScreenWidth()/2 - 150, getCore():getScreenHeight()/2 - 200, 300, 400)
    ui:initialise()
    ui:instantiate()
    ui:addToUIManager()
end
