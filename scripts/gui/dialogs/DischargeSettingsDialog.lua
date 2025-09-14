---@class DischargeSettingsDialog : MessageDialog
---@field dischargeNode? DischargeNode
---
---@field enabledOption BinaryOptionElement
---@field dischargeToGroundOption BinaryOptionElement
---@field dischargeToObjectOption BinaryOptionElement
---@field dischargeToVehicleOption BinaryOptionElement
---@field dischargeToAnyObjectOption BinaryOptionElement
---@field emptySpeedInput TextInputElement
---@field emptySpeedTitle TextElement
---
---@field superClass fun(): MessageDialog
DischargeSettingsDialog = {}

DischargeSettingsDialog.CLASS_NAME = 'DischargeSettingsDialog'
DischargeSettingsDialog.XML_FILENAME = g_currentModDirectory .. 'xml/dialogs/DischargeSettingsDialog.xml'

local DischargeSettingsDialog_mt = Class(DischargeSettingsDialog, MessageDialog)

---@return DischargeSettingsDialog
---@nodiscard
function DischargeSettingsDialog.new()
    local self = MessageDialog.new(nil, DischargeSettingsDialog_mt)
    ---@cast self DischargeSettingsDialog

    return self
end

function DischargeSettingsDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[DischargeSettingsDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function DischargeSettingsDialog:load()
    g_gui:loadGui(DischargeSettingsDialog.XML_FILENAME, DischargeSettingsDialog.CLASS_NAME, self)
end

---@param dischargeNode DischargeNode
function DischargeSettingsDialog:show(dischargeNode)
    self.dischargeNode = dischargeNode

    g_gui:showDialog(DischargeSettingsDialog.CLASS_NAME)
end

function DischargeSettingsDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateItems()

    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == DischargeSettingsDialog.CLASS_NAME then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.enabledOption)
        self:setSoundSuppressed(false)
    end

    g_messageCenter:subscribe(SetDischargeNodeEnabledEvent, self.onDischargeNodeChanged, self)
    g_messageCenter:subscribe(SetDischargeNodeSettingsEvent, self.onDischargeNodeChanged, self)
end

function DischargeSettingsDialog:onClose()
    self:superClass().onClose(self)

    self.dischargeNode = nil

    g_messageCenter:unsubscribeAll(self)
end

function DischargeSettingsDialog:updateItems()
    local dischargeNode = self.dischargeNode

    if dischargeNode ~= nil then
        self.enabledOption:setIsChecked(dischargeNode.enabled)
        self.dischargeToGroundOption:setIsChecked(dischargeNode.canDischargeToGround)
        self.dischargeToObjectOption:setIsChecked(dischargeNode.canDischargeToObject)
        self.dischargeToVehicleOption:setIsChecked(dischargeNode.canDischargeToVehicle)
        self.dischargeToAnyObjectOption:setIsChecked(dischargeNode.canDischargeToAnyObject)

        if dischargeNode.placeable.spec_materialDischargeable ~= nil then
            self.emptySpeedInput.formatDecimalPlaces = 0
            self.emptySpeedTitle:setText(g_i18n:getText('ui_litersPerHour'))
            self.emptySpeedInput:setText(string.format('%.0f', dischargeNode.emptySpeed))
        else
            self.emptySpeedInput.formatDecimalPlaces = 2
            self.emptySpeedTitle:setText(g_i18n:getText('ui_litersPerSecond'))
            self.emptySpeedInput:setText(string.format('%.2f', dischargeNode.emptySpeed))
        end
    end
end

---@param dischargeNode DischargeNode
function DischargeSettingsDialog:onDischargeNodeChanged(dischargeNode)
    if self.isOpen and dischargeNode == self.dischargeNode then
        self:updateItems()
    end
end

function DischargeSettingsDialog:onClickEnabledOption(state)
    local dischargeNode = self.dischargeNode

    if dischargeNode ~= nil then
        dischargeNode.placeable:setDischargeNodeEnabled(dischargeNode.index, state == CheckedOptionElement.STATE_CHECKED)
    end
end

---@param element TextInputElement
function DischargeSettingsDialog:onEnterPressedInput(element)
    local dischargeNode = self.dischargeNode

    if dischargeNode ~= nil then
        local value = tonumber(element.text)

        if value ~= nil and value > 0 then
            dischargeNode.placeable:setDischargeNodeEmptySpeed(dischargeNode.index, value)
        else
            if dischargeNode.placeable.spec_materialDischargeable ~= nil then
                self.emptySpeedInput:setText(string.format('%.0f', dischargeNode.emptySpeed))
            else
                self.emptySpeedInput:setText(string.format('%.2f', dischargeNode.emptySpeed))
            end
        end
    end
end

function DischargeSettingsDialog:onClickDischargeToGroundOption(state)
    local dischargeNode = self.dischargeNode

    if dischargeNode ~= nil then
        dischargeNode.placeable:setDischargeNodeSettings(
            dischargeNode.index,
            state == CheckedOptionElement.STATE_CHECKED,
            dischargeNode.canDischargeToObject,
            dischargeNode.canDischargeToVehicle,
            dischargeNode.canDischargeToAnyObject
        )
    end
end

function DischargeSettingsDialog:onClickDischargeToObjectOption(state)
    local dischargeNode = self.dischargeNode

    if dischargeNode ~= nil then
        dischargeNode.placeable:setDischargeNodeSettings(
            dischargeNode.index,
            dischargeNode.canDischargeToGround,
            state == CheckedOptionElement.STATE_CHECKED,
            dischargeNode.canDischargeToVehicle,
            dischargeNode.canDischargeToAnyObject
        )
    end
end

function DischargeSettingsDialog:onClickDischargeToVehicleOption(state)
    local dischargeNode = self.dischargeNode

    if dischargeNode ~= nil then
        dischargeNode.placeable:setDischargeNodeSettings(
            dischargeNode.index,
            dischargeNode.canDischargeToGround,
            dischargeNode.canDischargeToObject,
            state == CheckedOptionElement.STATE_CHECKED,
            dischargeNode.canDischargeToAnyObject
        )
    end
end

function DischargeSettingsDialog:onClickDischargeToAnyObjectOption(state)
    local dischargeNode = self.dischargeNode

    if dischargeNode ~= nil then
        dischargeNode.placeable:setDischargeNodeSettings(
            dischargeNode.index,
            dischargeNode.canDischargeToGround,
            dischargeNode.canDischargeToObject,
            dischargeNode.canDischargeToVehicle,
            state == CheckedOptionElement.STATE_CHECKED
        )
    end
end
