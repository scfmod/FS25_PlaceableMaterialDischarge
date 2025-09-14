source(g_currentModDirectory .. 'scripts/gui/dialogs/ControlPanelDialog.lua')
source(g_currentModDirectory .. 'scripts/gui/dialogs/DischargeMaterialDialog.lua')
source(g_currentModDirectory .. 'scripts/gui/dialogs/DischargeSettingsDialog.lua')

---@class ModGui
ModGui = {}

ModGui.MOD_SETTINGS_FOLDER = g_currentModSettingsDirectory
ModGui.TEXTURE_CONFIG_FILENAME = g_currentModDirectory .. 'textures/ui_elements.xml'

local ModGui_mt = Class(ModGui)

---@return ModGui
---@nodiscard
function ModGui.new()
    ---@type ModGui
    local self = setmetatable({}, ModGui_mt)

    if g_client ~= nil then
        addConsoleCommand('pmdReloadGui', '', 'consoleReloadGui', self)
    end

    return self
end

function ModGui:delete()
    if g_controlPanelDialog.isOpen then
        g_controlPanelDialog:close()
    end
    if g_dischargeMaterialDialog.isOpen then
        g_dischargeMaterialDialog:close()
    end
    if g_dischargeSettingsDialog.isOpen then
        g_dischargeSettingsDialog:close()
    end

    g_gui:showGui(nil)

    g_controlPanelDialog:delete()
    g_dischargeMaterialDialog:delete()
    g_dischargeSettingsDialog:delete()
end

function ModGui:load()
    g_gui.currentlyReloading = true

    self:loadDialogs()

    g_gui.currentlyReloading = false
end

function ModGui:loadDialogs()
    ---@diagnostic disable-next-line: lowercase-global
    g_controlPanelDialog = ControlPanelDialog.new()
    g_controlPanelDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_dischargeMaterialDialog = DischargeMaterialDialog.new()
    g_dischargeMaterialDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_dischargeSettingsDialog = DischargeSettingsDialog.new()
    g_dischargeSettingsDialog:load()
end

function ModGui:reload()
    local currentPlaceable = g_controlPanelDialog.placeable

    g_gui.currentlyReloading = true

    g_overlayManager.textureConfigs['placeableMaterialDischarge'] = nil
    g_overlayManager:addTextureConfigFile(ModGui.TEXTURE_CONFIG_FILENAME, 'placeableMaterialDischarge', nil)

    self:delete()
    self:load()

    g_gui.currentlyReloading = false

    if currentPlaceable ~= nil then
        g_controlPanelDialog:show(currentPlaceable)
    end
end

function ModGui:consoleReloadGui()
    if g_server ~= nil and not g_currentMission.missionDynamicInfo.isMultiplayer then
        self:reload()

        return 'Reloaded GUI'
    end

    return 'Only available in single player'
end

---@diagnostic disable-next-line: lowercase-global
g_modGui = ModGui.new()
