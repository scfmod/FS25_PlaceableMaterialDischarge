---@class PlaceableProductionDischargeable_spec
---@field dirtyFlag number
---@field dischargeNodes ProductionDischargeNode[]
---@field activatable ProductionDischargeableActivatable

---@class PlaceableProductionDischargeable :Placeable
---@field spec_productionDischargeable PlaceableProductionDischargeable_spec
---@field spec_productionPoint PlaceableProductionPoint
PlaceableProductionDischargeable = {}

PlaceableProductionDischargeable.SPEC_NAME = 'spec_' .. g_currentModName .. '.productionDischargeable'
PlaceableProductionDischargeable.MOD_NAME = g_currentModName

function PlaceableProductionDischargeable.prerequisitesPresent()
    return true
end

---@param schema XMLSchema
function PlaceableProductionDischargeable.registerXMLPaths(schema)
    schema:setXMLSpecializationType('ProductionDischargeable')

    ProductionDischargeNode.registerXMLPaths(schema, 'placeable.productionDischargeable.dischargeNodes.dischargeNode(?)')
    ProductionDischargeableActivatable.registerXMLPaths(schema, 'placeable.productionDischargeable.activationTrigger')

    schema:setXMLSpecializationType()
end

---@param schema XMLSchema
---@param key string
function PlaceableProductionDischargeable.registerSavegameXMLPaths(schema, key)
    schema:setXMLSpecializationType('ProductionDischargeable')

    DischargeNode.registerSavegameXMLPaths(schema, key .. '.dischargeNode(?)')

    schema:setXMLSpecializationType()
end

---@param placeableType table
function PlaceableProductionDischargeable.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, 'getDischargeNode', PlaceableProductionDischargeable.getDischargeNode)
    SpecializationUtil.registerFunction(placeableType, 'getDischargeNodes', PlaceableProductionDischargeable.getDischargeNodes)
    SpecializationUtil.registerFunction(placeableType, 'setDischargeNodeEmptySpeed', PlaceableProductionDischargeable.setDischargeNodeEmptySpeed)
    SpecializationUtil.registerFunction(placeableType, 'setDischargeNodeEnabled', PlaceableProductionDischargeable.setDischargeNodeEnabled)
    SpecializationUtil.registerFunction(placeableType, 'setDischargeNodeFillType', PlaceableProductionDischargeable.setDischargeNodeFillType)
    SpecializationUtil.registerFunction(placeableType, 'setDischargeNodeState', PlaceableProductionDischargeable.setDischargeNodeState)
    SpecializationUtil.registerFunction(placeableType, 'setDischargeNodeSettings', PlaceableProductionDischargeable.setDischargeNodeSettings)
end

function PlaceableProductionDischargeable.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, 'onLoad', PlaceableProductionDischargeable)
    SpecializationUtil.registerEventListener(placeableType, 'onFinalizePlacement', PlaceableProductionDischargeable)
    SpecializationUtil.registerEventListener(placeableType, 'onDelete', PlaceableProductionDischargeable)
    SpecializationUtil.registerEventListener(placeableType, 'onUpdate', PlaceableProductionDischargeable)
    SpecializationUtil.registerEventListener(placeableType, 'onUpdateTick', PlaceableProductionDischargeable)

    SpecializationUtil.registerEventListener(placeableType, 'onWriteStream', PlaceableProductionDischargeable)
    SpecializationUtil.registerEventListener(placeableType, 'onReadStream', PlaceableProductionDischargeable)

    SpecializationUtil.registerEventListener(placeableType, 'onWriteUpdateStream', PlaceableProductionDischargeable)
    SpecializationUtil.registerEventListener(placeableType, 'onReadUpdateStream', PlaceableProductionDischargeable)
end

function PlaceableProductionDischargeable:onLoad()
    ---@type PlaceableProductionDischargeable_spec
    local spec = self[PlaceableProductionDischargeable.SPEC_NAME]
    self.spec_productionDischargeable = spec

    ---@type XMLFile
    local xmlFile = self.xmlFile

    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.dischargeNodes = {}

    xmlFile:iterate('placeable.productionDischargeable.dischargeNodes.dischargeNode', function (_, key)
        local dischargeNode = ProductionDischargeNode.new(self, #spec.dischargeNodes + 1, spec.dirtyFlag)

        if dischargeNode:load(xmlFile, key) then
            table.insert(spec.dischargeNodes, dischargeNode)
        end
    end)

    if self.isClient then
        spec.activatable = ProductionDischargeableActivatable.new(self)
        spec.activatable:load(xmlFile, 'placeable.productionDischargeable.activationTrigger')
    end
end

function PlaceableProductionDischargeable:onDelete()
    local spec = self.spec_productionDischargeable

    for _, dischargeNode in ipairs(spec.dischargeNodes) do
        dischargeNode:delete()
    end

    spec.dischargeNodes = {}

    if spec.activatable ~= nil then
        spec.activatable:delete()
    end

    spec.activatable = nil
end

function PlaceableProductionDischargeable:onFinalizePlacement()
    if self.isServer then
        self:raiseActive()
    end
end

---@param xmlFile XMLFile
---@param key string
function PlaceableProductionDischargeable:loadFromXMLFile(xmlFile, key)
    xmlFile:iterate(key .. '.dischargeNode', function (index, nodeKey)
        local dischargeNode = self:getDischargeNode(index)

        if dischargeNode ~= nil then
            dischargeNode:loadFromXMLFile(xmlFile, nodeKey)
        end
    end)
end

---@param xmlFile XMLFile
---@param key string
function PlaceableProductionDischargeable:saveToXMLFile(xmlFile, key)
    for i, dischargeNode in ipairs(self:getDischargeNodes()) do
        local nodeKey = string.format('%s.dischargeNode(%i)', key, i - 1)

        dischargeNode:saveToXMLFile(xmlFile, nodeKey)
    end
end

function PlaceableProductionDischargeable:onUpdate(dt)
    local spec = self.spec_productionDischargeable

    for _, dischargeNode in ipairs(spec.dischargeNodes) do
        dischargeNode:update(dt)
    end
end

function PlaceableProductionDischargeable:onUpdateTick(dt)
    local spec = self.spec_productionDischargeable

    for _, dischargeNode in ipairs(spec.dischargeNodes) do
        dischargeNode:updateTick(dt)
    end

    if self.isServer then
        self:raiseActive()
    end
end

---@return ProductionDischargeNode[]
---@nodiscard
function PlaceableProductionDischargeable:getDischargeNodes()
    return self.spec_productionDischargeable.dischargeNodes
end

---@param index number
---@return ProductionDischargeNode
---@nodiscard
function PlaceableProductionDischargeable:getDischargeNode(index)
    return self.spec_productionDischargeable.dischargeNodes[index]
end

---@param index number
---@param emptySpeed number
---@param noEventSend? boolean
function PlaceableProductionDischargeable:setDischargeNodeEmptySpeed(index, emptySpeed, noEventSend)
    local dischargeNode = self:getDischargeNode(index)

    if dischargeNode ~= nil and dischargeNode.emptySpeed ~= emptySpeed then
        SetDischargeNodeEmptySpeedEvent.sendEvent(self, index, emptySpeed, noEventSend)

        dischargeNode:setEmptySpeed(emptySpeed)

        g_messageCenter:publish(SetDischargeNodeEmptySpeedEvent, dischargeNode, emptySpeed)
    end
end

---@param index number
---@param enabled boolean
---@param noEventSend? boolean
function PlaceableProductionDischargeable:setDischargeNodeEnabled(index, enabled, noEventSend)
    local dischargeNode = self:getDischargeNode(index)

    if dischargeNode ~= nil and dischargeNode.enabled ~= enabled then
        SetDischargeNodeEnabledEvent.sendEvent(self, index, enabled, noEventSend)

        dischargeNode.enabled = enabled

        if not enabled then
            dischargeNode:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
        end

        g_messageCenter:publish(SetDischargeNodeEnabledEvent, dischargeNode, enabled)
    end
end

---@param index number
---@param fillTypeIndex number
---@param noEventSend? boolean
function PlaceableProductionDischargeable:setDischargeNodeFillType(index, fillTypeIndex, noEventSend)
    local dischargeNode = self:getDischargeNode(index)

    if dischargeNode ~= nil and dischargeNode.currentFillType ~= fillTypeIndex then
        SetDischargeNodeFillTypeEvent.sendEvent(self, index, fillTypeIndex, noEventSend)

        dischargeNode.currentFillType = fillTypeIndex

        g_messageCenter:publish(SetDischargeNodeFillTypeEvent, dischargeNode, fillTypeIndex)
    end
end

---@param index number
---@param state number
---@param noEventSend? boolean
function PlaceableProductionDischargeable:setDischargeNodeState(index, state, noEventSend)
    local dischargeNode = self:getDischargeNode(index)

    if dischargeNode ~= nil then
        dischargeNode:setDischargeState(state, noEventSend)
    end
end

---@param index number
---@param canDischargeToGround boolean
---@param canDischargeToObject boolean
---@param canDischargeToVehicle boolean
---@param canDischargeToAnyObject boolean
---@param noEventSend? boolean
function PlaceableProductionDischargeable:setDischargeNodeSettings(index, canDischargeToGround, canDischargeToObject, canDischargeToVehicle, canDischargeToAnyObject, noEventSend)
    local dischargeNode = self:getDischargeNode(index)

    if dischargeNode ~= nil then
        SetDischargeNodeSettingsEvent.sendEvent(self, index, canDischargeToGround, canDischargeToObject, canDischargeToVehicle, canDischargeToAnyObject, noEventSend)

        dischargeNode.canDischargeToGround = canDischargeToGround
        dischargeNode.canDischargeToObject = canDischargeToObject
        dischargeNode.canDischargeToVehicle = canDischargeToVehicle
        dischargeNode.canDischargeToAnyObject = canDischargeToAnyObject

        g_messageCenter:publish(SetDischargeNodeSettingsEvent, dischargeNode, canDischargeToGround, canDischargeToObject, canDischargeToVehicle, canDischargeToAnyObject)
    end
end

---@param streamId number
---@param connection Connection
function PlaceableProductionDischargeable:onWriteStream(streamId, connection)
    local spec = self.spec_productionDischargeable

    if not connection:getIsServer() then
        for _, dischargeNode in ipairs(spec.dischargeNodes) do
            dischargeNode:writeStream(streamId, connection)
        end
    end
end

---@param streamId number
---@param connection Connection
function PlaceableProductionDischargeable:onReadStream(streamId, connection)
    local spec = self.spec_productionDischargeable

    if connection:getIsServer() then
        for _, dischargeNode in ipairs(spec.dischargeNodes) do
            dischargeNode:readStream(streamId, connection)
        end
    end
end

---@param streamId number
---@param connection Connection
function PlaceableProductionDischargeable:onWriteUpdateStream(streamId, connection, dirtyMask)
    local spec = self.spec_productionDischargeable

    if not connection:getIsServer() then
        if not streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            for _, dischargeNode in ipairs(spec.dischargeNodes) do
                dischargeNode:writeUpdateStream(streamId, connection)
            end
        end
    end
end

---@param streamId number
---@param connection Connection
function PlaceableProductionDischargeable:onReadUpdateStream(streamId, timestamp, connection)
    local spec = self.spec_productionDischargeable

    if connection:getIsServer() then
        if streamReadBool(streamId) then
            for _, dischargeNode in ipairs(spec.dischargeNodes) do
                dischargeNode:readUpdateStream(streamId, connection)
            end
        end
    end
end

---@class ProductionDischargeableActivatable
---@field placeable PlaceableProductionDischargeable
---@field triggerNode number
---@field activateText string
---@field requireAccess 'admin'|'farmManager'|'none'
ProductionDischargeableActivatable = {}

local ProductionDischargeableActivatable_mt = Class(ProductionDischargeableActivatable)

---@param schema XMLSchema
---@param key string
function ProductionDischargeableActivatable.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. '#node', 'Activation trigger node for opening control panel', nil, false)
    schema:register(XMLValueType.STRING, key .. '#requireAccess', 'Access required in order to access the control panel (multiplayer only) [admin,farmManager,none]', 'farmManager', false)
end

---@param placeable PlaceableProductionDischargeable
---@return ProductionDischargeableActivatable
---@nodiscard
function ProductionDischargeableActivatable.new(placeable)
    ---@type ProductionDischargeableActivatable
    local self = setmetatable({}, ProductionDischargeableActivatable_mt)

    self.placeable = placeable
    self.activateText = g_i18n:getText('action_controlPanel')
    self.requireAccess = 'farmManager'

    return self
end

function ProductionDischargeableActivatable:delete()
    g_currentMission.activatableObjectsSystem:removeActivatable(self)

    if self.triggerNode ~= nil then
        removeTrigger(self.triggerNode)
    end
end

---@param xmlFile XMLFile
---@param key string
function ProductionDischargeableActivatable:load(xmlFile, key)
    self.triggerNode = xmlFile:getValue(key .. '#node', nil, self.placeable.components, self.placeable.i3dMappings)
    self.requireAccess = xmlFile:getValue(key .. '#requireAccess', self.requireAccess)

    if self.triggerNode ~= nil then
        if CollisionFlag.getHasMaskFlagSet(self.triggerNode, CollisionFlag.PLAYER) then
            addTrigger(self.triggerNode, 'activationTriggerCallback', self)
        else
            Logging.xmlWarning(xmlFile, 'Missing PLAYER collision flag on node: %s', key .. '#node')
        end
    end
end

function ProductionDischargeableActivatable:run()
    g_controlPanelDialog:show(self.placeable)
end

---@return boolean
function ProductionDischargeableActivatable:getIsActivatable()
    if self.requireAccess == 'admin' then
        return g_server ~= nil or g_currentMission.isMasterUser
    elseif self.requireAccess == 'farmManager' then
        return g_currentMission:getHasPlayerPermission(Farm.PERMISSION.MANAGE_RIGHTS, nil, self.placeable:getOwnerFarmId())
    else
        return true
    end
end

---@param x number
---@param y number
---@param z number
function ProductionDischargeableActivatable:getDistance(x, y, z)
    local tx, ty, tz = getWorldTranslation(self.triggerNode)

    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end

---@param triggerId number
---@param otherActorId number | nil
---@param onEnter boolean
---@param onLeave boolean
---@param onStay boolean
---@param otherShapeId number | nil
function ProductionDischargeableActivatable:activationTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if (onEnter or onLeave) and g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode then
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(self)
        else
            g_currentMission.activatableObjectsSystem:removeActivatable(self)
        end
    end
end
