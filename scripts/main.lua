source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetDischargeNodeEmptySpeedEvent.lua')
source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetDischargeNodeEnabledEvent.lua')
source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetDischargeNodeFillTypeEvent.lua')
source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetDischargeNodeSettingsEvent.lua')
source(g_currentModDirectory .. 'scripts/placeableSpecializations/events/SetDischargeNodeStateEvent.lua')

g_overlayManager:addTextureConfigFile(g_currentModDirectory .. 'textures/ui_elements.xml', 'placeableMaterialDischarge', nil)

source(g_currentModDirectory .. 'scripts/ModGui.lua')
source(g_currentModDirectory .. 'scripts/DischargeUtils.lua')
source(g_currentModDirectory .. 'scripts/DischargeNode.lua')
source(g_currentModDirectory .. 'scripts/MaterialDischargeNode.lua')
source(g_currentModDirectory .. 'scripts/ProductionDischargeNode.lua')

if g_client ~= nil then
    g_modGui:load()
end
