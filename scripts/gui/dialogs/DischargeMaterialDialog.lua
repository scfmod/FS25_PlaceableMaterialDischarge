---@class DischargeMaterialDialog : MessageDialog
---@field settingsButton ButtonElement
---@field list SmoothListElement
---@field items FillTypeObject[]
---@field dischargeNode? DischargeNode
---@field superClass fun(): MessageDialog
DischargeMaterialDialog = {}

DischargeMaterialDialog.CLASS_NAME = 'DischargeMaterialDialog'
DischargeMaterialDialog.XML_FILENAME = g_currentModDirectory .. 'xml/dialogs/DischargeMaterialDialog.xml'

local DischargeMaterialDialog_mt = Class(DischargeMaterialDialog, MessageDialog)

---@return DischargeMaterialDialog
---@nodiscard
function DischargeMaterialDialog.new()
    local self = MessageDialog.new(nil, DischargeMaterialDialog_mt)
    ---@cast self DischargeMaterialDialog

    self.items = {}

    return self
end

function DischargeMaterialDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[DischargeMaterialDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function DischargeMaterialDialog:load()
    g_gui:loadGui(DischargeMaterialDialog.XML_FILENAME, DischargeMaterialDialog.CLASS_NAME, self)
end

function DischargeMaterialDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)
end

---@param fn function | nil
---@param target any
function DischargeMaterialDialog:setSelectCallback(fn, target)
    self.selectCallbackFunction = fn
    self.selectCallbackTarget = target
end

---@param dischargeNode DischargeNode
function DischargeMaterialDialog:show(dischargeNode)
    self.dischargeNode = dischargeNode

    g_gui:showDialog(DischargeMaterialDialog.CLASS_NAME)

    self:setSelectedItem(dischargeNode.currentFillType)
end

function DischargeMaterialDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateItems()
end

function DischargeMaterialDialog:onClose()
    self:superClass().onClose(self)

    self.dischargeNode = nil

    g_messageCenter:unsubscribeAll(self)
end

function DischargeMaterialDialog:updateItems()
    ---@type DischargeNode
    local dischargeNode = self.dischargeNode

    if dischargeNode.fillTypes == nil then
        self.items = {}
        if dischargeNode.placeable.spec_materialDischargeable ~= nil then
            for _, fillType in ipairs(g_fillTypeManager:getFillTypes()) do
                if DensityMapHeightUtil.getCanTipToGround(fillType.index) then
                    table.insert(self.items, fillType)
                end
            end
        else
            ---@cast dischargeNode ProductionDischargeNode
            local storage = dischargeNode:getStorage()

            for fillTypeIndex, _accepted in pairs(storage.fillTypes) do
                local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

                if fillType ~= nil and DensityMapHeightUtil.getCanTipToGround(fillType.index) then
                    table.insert(self.items, fillType)
                end
            end
        end
    else
        self.items = table.clone(dischargeNode.fillTypes)
    end

    table.sort(self.items, function (a, b)
        return a.title < b.title
    end)

    self.list:reloadData()
end

---@param fillTypeIndex number | nil
function DischargeMaterialDialog:setSelectedItem(fillTypeIndex)
    if fillTypeIndex ~= nil then
        for index, fillType in ipairs(self.items) do
            if fillType.index == fillTypeIndex then
                self.list:setSelectedIndex(index)
                return
            end
        end
    end

    self.list:setSelectedIndex(1)
end

function DischargeMaterialDialog:getNumberOfItemsInSection()
    return #self.items
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function DischargeMaterialDialog:populateCellForItemInSection(list, section, index, cell)
    local fillType = self.items[index]

    if fillType ~= nil then
        cell:getAttribute('image'):setImageFilename(fillType.hudOverlayFilename)
        cell:getAttribute('name'):setText(fillType.title)
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell ListItemElement
function DischargeMaterialDialog:onItemDoubleClick(list, section, index, cell)
    self:setFillType(index)
end

function DischargeMaterialDialog:onClickApply()
    self:setFillType(self.list:getSelectedIndexInSection())
end

---@param itemIndex number
function DischargeMaterialDialog:setFillType(itemIndex)
    local fillType = self.items[itemIndex]

    if fillType ~= nil then
        self.dischargeNode.placeable:setDischargeNodeFillType(self.dischargeNode.index, fillType.index)
    end

    self:close()
end
