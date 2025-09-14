---@class ControlPanelDialog : MessageDialog
---@field list SmoothListElement
---@field placeable? PlaceableObject
---@field items DischargeNode[]
---@field settingsButton ButtonElement
---@field materialButton ButtonElement
---@field listHeaderEmptySpeed TextElement
---@field superClass fun(): MessageDialog
ControlPanelDialog = {}

ControlPanelDialog.CLASS_NAME = 'ControlPanelDialog'
ControlPanelDialog.XML_FILENAME = g_currentModDirectory .. 'xml/dialogs/ControlPanelDialog.xml'

local ControlPanelDialog_mt = Class(ControlPanelDialog, MessageDialog)

---@return ControlPanelDialog
---@nodiscard
function ControlPanelDialog.new()
    local self = MessageDialog.new(nil, ControlPanelDialog_mt)
    ---@cast self ControlPanelDialog

    self.items = {}

    return self
end

function ControlPanelDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[ControlPanelDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function ControlPanelDialog:load()
    g_gui:loadGui(ControlPanelDialog.XML_FILENAME, ControlPanelDialog.CLASS_NAME, self)
end

function ControlPanelDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
end

---@param fn function | nil
---@param target any
function ControlPanelDialog:setSelectCallback(fn, target)
    self.selectCallbackFunction = fn
    self.selectCallbackTarget = target
end

---@param placeable PlaceableObject
function ControlPanelDialog:show(placeable)
    self.placeable = placeable

    g_gui:showDialog(ControlPanelDialog.CLASS_NAME)
end

function ControlPanelDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateItems()
    self:updateMenuButtons()

    if self.placeable.spec_materialDischargeable ~= nil then
        self.listHeaderEmptySpeed:setText(g_i18n:getText('ui_litersPerHour'))
    else
        self.listHeaderEmptySpeed:setText(g_i18n:getText('ui_litersPerSecond'))
    end

    g_messageCenter:subscribe(SetDischargeNodeFillTypeEvent, self.onDischargeNodeChanged, self)
    g_messageCenter:subscribe(SetDischargeNodeSettingsEvent, self.onDischargeNodeChanged, self)
    g_messageCenter:subscribe(SetDischargeNodeEmptySpeedEvent, self.onDischargeNodeChanged, self)
    g_messageCenter:subscribe(SetDischargeNodeEnabledEvent, self.onDischargeNodeChanged, self)
end

function ControlPanelDialog:onClose()
    self:superClass().onClose(self)

    self.dischargeNode = nil
    self.placeable = nil

    g_messageCenter:unsubscribeAll(self)
end

function ControlPanelDialog:updateItems()
    self.items = self.placeable:getDischargeNodes()
    self.list:reloadData()
end

function ControlPanelDialog:updateMenuButtons()
    local dischargeNode = self:getSelectedItem()

    if dischargeNode ~= nil then
        self.materialButton:setVisible(dischargeNode.fillTypes == nil or #dischargeNode.fillTypes > 1)
        self.settingsButton:setVisible(true)
    else
        self.materialButton:setVisible(false)
        self.settingsButton:setVisible(false)
    end
end

---@return DischargeNode | nil
function ControlPanelDialog:getSelectedItem()
    return self.items[self.list:getSelectedIndexInSection()]
end

---@param dischargeNode DischargeNode
function ControlPanelDialog:onDischargeNodeChanged(dischargeNode)
    if self.isOpen and dischargeNode.placeable == self.placeable then
        self.list:reloadData()
        self:updateMenuButtons()
    end
end

---@return number
function ControlPanelDialog:getNumberOfItemsInSection()
    return #self.items
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function ControlPanelDialog:populateCellForItemInSection(list, section, index, cell)
    local dischargeNode = self.items[index]

    if dischargeNode ~= nil then
        local fillTypeIndex = dischargeNode:getDischargeFillType()
        ---@type FillTypeObject?
        local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

        cell:getAttribute('name'):setText(dischargeNode.name)
        cell:getAttribute('fillType'):setText(fillType and fillType.title or 'INVALID')

        if self.placeable.spec_materialDischargeable ~= nil then
            cell:getAttribute('emptySpeed'):setText(g_i18n:formatNumber(dischargeNode.emptySpeed))
        else
            cell:getAttribute('emptySpeed'):setText(string.format('%.0f', dischargeNode.emptySpeed))
        end

        ---@type BitmapElement
        local imageElement = cell:getAttribute('image')

        if fillType ~= nil then
            imageElement:setImageFilename(fillType.hudOverlayFilename)
            imageElement:setVisible(true)
        else
            imageElement:setVisible(false)
        end

        ---@type TextElement
        local statusElement = cell:getAttribute('status')

        if dischargeNode.enabled ~= true then
            statusElement:applyProfile('controlPanelDialog_listItemStatusDisabled', true, true)
            statusElement:setText('Disabled')
        else
            statusElement:applyProfile('controlPanelDialog_listItemStatus', true, true)
            statusElement:setText('Enabled')
        end
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function ControlPanelDialog:onItemDoubleClick(list, section, index, cell)
    local dischargeNode = self.items[index]

    if dischargeNode ~= nil then
        g_dischargeMaterialDialog:show(dischargeNode)
    end
end

function ControlPanelDialog:onClickSettings()
    local dischargeNode = self:getSelectedItem()

    if dischargeNode ~= nil then
        g_dischargeSettingsDialog:show(dischargeNode)
    end
end

function ControlPanelDialog:onClickChangeMaterial()
    local dischargeNode = self:getSelectedItem()

    if dischargeNode ~= nil then
        g_dischargeMaterialDialog:show(dischargeNode)
    end
end
