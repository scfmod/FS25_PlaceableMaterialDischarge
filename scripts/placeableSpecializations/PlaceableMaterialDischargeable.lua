---@class PlaceableMaterialDischargeable_spec
---@field dirtyFlag number
---@field dischargeNodes MaterialDischargeNode[]
---@field activatable MaterialDischargeableActivatable

---@class PlaceableMaterialDischargeable : Placeable
---@field spec_materialDischargeable PlaceableMaterialDischargeable_spec
PlaceableMaterialDischargeable = {}

PlaceableMaterialDischargeable.SPEC_NAME = 'spec_' .. g_currentModName .. '.materialDischargeable'
PlaceableMaterialDischargeable.MOD_NAME = g_currentModName

function PlaceableMaterialDischargeable.prerequisitesPresent()
    return true
end

---@param schema XMLSchema
function PlaceableMaterialDischargeable.registerXMLPaths(schema)
    schema:setXMLSpecializationType('MaterialDischargeable')

    MaterialDischargeNode.registerXMLPaths(schema, 'placeable.materialDischargeable.dischargeNodes.dischargeNode(?)')
    MaterialDischargeableActivatable.registerXMLPaths(schema, 'placeable.materialDischargeable.activationTrigger')

    schema:setXMLSpecializationType()
end

---@param schema XMLSchema
---@param key string
function PlaceableMaterialDischargeable.registerSavegameXMLPaths(schema, key)
    schema:setXMLSpecializationType('MaterialDischargeable')

    DischargeNode.registerSavegameXMLPaths(schema, key .. '.dischargeNode(?)')

    schema:setXMLSpecializationType()
end

---@param placeableType table
function PlaceableMaterialDischargeable.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, 'getDischargeNode', PlaceableMaterialDischargeable.getDischargeNode)
    SpecializationUtil.registerFunction(placeableType, 'getDischargeNodes', PlaceableMaterialDischargeable.getDischargeNodes)
    SpecializationUtil.registerFunction(placeableType, 'setDischargeNodeEmptySpeed', PlaceableMaterialDischargeable.setDischargeNodeEmptySpeed)
    SpecializationUtil.registerFunction(placeableType, 'setDischargeNodeEnabled', PlaceableMaterialDischargeable.setDischargeNodeEnabled)
    SpecializationUtil.registerFunction(placeableType, 'setDischargeNodeFillType', PlaceableMaterialDischargeable.setDischargeNodeFillType)
    SpecializationUtil.registerFunction(placeableType, 'setDischargeNodeState', PlaceableMaterialDischargeable.setDischargeNodeState)
    SpecializationUtil.registerFunction(placeableType, 'setDischargeNodeSettings', PlaceableMaterialDischargeable.setDischargeNodeSettings)
end

function PlaceableMaterialDischargeable.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, 'onLoad', PlaceableMaterialDischargeable)
    SpecializationUtil.registerEventListener(placeableType, 'onFinalizePlacement', PlaceableMaterialDischargeable)
    SpecializationUtil.registerEventListener(placeableType, 'onDelete', PlaceableMaterialDischargeable)
    SpecializationUtil.registerEventListener(placeableType, 'onUpdate', PlaceableMaterialDischargeable)
    SpecializationUtil.registerEventListener(placeableType, 'onUpdateTick', PlaceableMaterialDischargeable)

    SpecializationUtil.registerEventListener(placeableType, 'onWriteStream', PlaceableMaterialDischargeable)
    SpecializationUtil.registerEventListener(placeableType, 'onReadStream', PlaceableMaterialDischargeable)

    SpecializationUtil.registerEventListener(placeableType, 'onWriteUpdateStream', PlaceableMaterialDischargeable)
    SpecializationUtil.registerEventListener(placeableType, 'onReadUpdateStream', PlaceableMaterialDischargeable)
end

function PlaceableMaterialDischargeable:onLoad()
    ---@type PlaceableMaterialDischargeable_spec
    local spec = self[PlaceableMaterialDischargeable.SPEC_NAME]
    self.spec_materialDischargeable = spec

    ---@type XMLFile
    local xmlFile = self.xmlFile

    spec.dirtyFlag = self:getNextDirtyFlag()
    spec.dischargeNodes = {}

    xmlFile:iterate('placeable.materialDischargeable.dischargeNodes.dischargeNode', function (_, key)
        local dischargeNode = MaterialDischargeNode.new(self, #spec.dischargeNodes + 1, spec.dirtyFlag)

        if dischargeNode:load(xmlFile, key) then
            table.insert(spec.dischargeNodes, dischargeNode)
        end
    end)

    if self.isClient then
        spec.activatable = MaterialDischargeableActivatable.new(self)
        spec.activatable:load(xmlFile, 'placeable.materialDischargeable.activationTrigger')
    end
end

function PlaceableMaterialDischargeable:onDelete()
    local spec = self.spec_materialDischargeable

    for _, dischargeNode in ipairs(spec.dischargeNodes) do
        dischargeNode:delete()
    end

    spec.dischargeNodes = {}

    if spec.activatable ~= nil then
        spec.activatable:delete()
    end

    spec.activatable = nil
end

function PlaceableMaterialDischargeable:onFinalizePlacement()
    if self.isServer then
        self:raiseActive()
    end
end

---@param xmlFile XMLFile
---@param key string
function PlaceableMaterialDischargeable:loadFromXMLFile(xmlFile, key)
    xmlFile:iterate(key .. '.dischargeNode', function (index, nodeKey)
        local dischargeNode = self:getDischargeNode(index)

        if dischargeNode ~= nil then
            dischargeNode:loadFromXMLFile(xmlFile, nodeKey)
        end
    end)
end

---@param xmlFile XMLFile
---@param key string
function PlaceableMaterialDischargeable:saveToXMLFile(xmlFile, key)
    for i, dischargeNode in ipairs(self:getDischargeNodes()) do
        local nodeKey = string.format('%s.dischargeNode(%i)', key, i - 1)

        dischargeNode:saveToXMLFile(xmlFile, nodeKey)
    end
end

function PlaceableMaterialDischargeable:onUpdate(dt)
    local spec = self.spec_materialDischargeable

    for _, dischargeNode in ipairs(spec.dischargeNodes) do
        dischargeNode:update(dt)
    end
end

function PlaceableMaterialDischargeable:onUpdateTick(dt)
    local spec = self.spec_materialDischargeable

    for _, dischargeNode in ipairs(spec.dischargeNodes) do
        dischargeNode:updateTick(dt)
    end

    if self.isServer then
        self:raiseActive()
    end
end

---@return MaterialDischargeNode[]
---@nodiscard
function PlaceableMaterialDischargeable:getDischargeNodes()
    return self.spec_materialDischargeable.dischargeNodes
end

---@param index number
---@return MaterialDischargeNode
---@nodiscard
function PlaceableMaterialDischargeable:getDischargeNode(index)
    return self.spec_materialDischargeable.dischargeNodes[index]
end

---@param index number
---@param emptySpeed number
---@param noEventSend? boolean
function PlaceableMaterialDischargeable:setDischargeNodeEmptySpeed(index, emptySpeed, noEventSend)
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
function PlaceableMaterialDischargeable:setDischargeNodeEnabled(index, enabled, noEventSend)
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
function PlaceableMaterialDischargeable:setDischargeNodeFillType(index, fillTypeIndex, noEventSend)
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
function PlaceableMaterialDischargeable:setDischargeNodeState(index, state, noEventSend)
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
function PlaceableMaterialDischargeable:setDischargeNodeSettings(index, canDischargeToGround, canDischargeToObject, canDischargeToVehicle, canDischargeToAnyObject, noEventSend)
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
function PlaceableMaterialDischargeable:onWriteStream(streamId, connection)
    local spec = self.spec_materialDischargeable

    if not connection:getIsServer() then
        for _, dischargeNode in ipairs(spec.dischargeNodes) do
            dischargeNode:writeStream(streamId, connection)
        end
    end
end

---@param streamId number
---@param connection Connection
function PlaceableMaterialDischargeable:onReadStream(streamId, connection)
    local spec = self.spec_materialDischargeable

    if connection:getIsServer() then
        for _, dischargeNode in ipairs(spec.dischargeNodes) do
            dischargeNode:readStream(streamId, connection)
        end
    end
end

---@param streamId number
---@param connection Connection
function PlaceableMaterialDischargeable:onWriteUpdateStream(streamId, connection, dirtyMask)
    local spec = self.spec_materialDischargeable

    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            for _, dischargeNode in ipairs(spec.dischargeNodes) do
                dischargeNode:writeUpdateStream(streamId, connection)
            end
        end
    end
end

---@param streamId number
---@param connection Connection
function PlaceableMaterialDischargeable:onReadUpdateStream(streamId, timestamp, connection)
    local spec = self.spec_materialDischargeable

    if connection:getIsServer() then
        if streamReadBool(streamId) then
            for _, dischargeNode in ipairs(spec.dischargeNodes) do
                dischargeNode:readUpdateStream(streamId, connection)
            end
        end
    end
end

---@class MaterialDischargeableActivatable
---@field placeable PlaceableMaterialDischargeable
---@field triggerNode number
---@field activateText string
---@field requireAccess 'admin'|'farmManager'|'none'
MaterialDischargeableActivatable = {}

local MaterialDischargeableActivatable_mt = Class(MaterialDischargeableActivatable)

---@param schema XMLSchema
---@param key string
function MaterialDischargeableActivatable.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. '#node', 'Activation trigger node for opening control panel', nil, false)
    schema:register(XMLValueType.STRING, key .. '#requireAccess', 'Access required in order to access the control panel (multiplayer only) [admin,farmManager,none]', 'farmManager', false)
end

---@param placeable PlaceableMaterialDischargeable
---@return MaterialDischargeableActivatable
---@nodiscard
function MaterialDischargeableActivatable.new(placeable)
    ---@type MaterialDischargeableActivatable
    local self = setmetatable({}, MaterialDischargeableActivatable_mt)

    self.placeable = placeable
    self.activateText = g_i18n:getText('action_controlPanel')
    self.requireAccess = 'farmManager'

    return self
end

function MaterialDischargeableActivatable:delete()
    g_currentMission.activatableObjectsSystem:removeActivatable(self)

    if self.triggerNode ~= nil then
        removeTrigger(self.triggerNode)
    end
end

---@param xmlFile XMLFile
---@param key string
function MaterialDischargeableActivatable:load(xmlFile, key)
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

function MaterialDischargeableActivatable:run()
    g_controlPanelDialog:show(self.placeable)
end

---@return boolean
function MaterialDischargeableActivatable:getIsActivatable()
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
function MaterialDischargeableActivatable:getDistance(x, y, z)
    local tx, ty, tz = getWorldTranslation(self.triggerNode)

    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end

---@param triggerId number
---@param otherActorId number | nil
---@param onEnter boolean
---@param onLeave boolean
---@param onStay boolean
---@param otherShapeId number | nil
function MaterialDischargeableActivatable:activationTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if (onEnter or onLeave) and g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode then
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(self)
        else
            g_currentMission.activatableObjectsSystem:removeActivatable(self)
        end
    end
end
