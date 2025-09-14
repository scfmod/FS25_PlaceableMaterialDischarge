---@class SetDischargeNodeSettingsEvent : Event
---@field placeable PlaceableObject
---@field index number
---@field canDischargeToGround boolean
---@field canDischargeToObject boolean
---@field canDischargeToVehicle boolean
---@field canDischargeToAnyObject boolean
SetDischargeNodeSettingsEvent = {}

local SetDischargeNodeSettingsEvent_mt = Class(SetDischargeNodeSettingsEvent, Event)

InitEventClass(SetDischargeNodeSettingsEvent, 'SetDischargeNodeSettingsEvent')

---@return SetDischargeNodeSettingsEvent
function SetDischargeNodeSettingsEvent.emptyNew()
    ---@type SetDischargeNodeSettingsEvent
    local self = Event.new(SetDischargeNodeSettingsEvent_mt)
    return self
end

---@param placeable PlaceableObject
---@param index number
---@param canDischargeToGround boolean
---@param canDischargeToObject boolean
---@param canDischargeToVehicle boolean
---@param canDischargeToAnyObject boolean
---@return SetDischargeNodeSettingsEvent
function SetDischargeNodeSettingsEvent.new(placeable, index, canDischargeToGround, canDischargeToObject, canDischargeToVehicle, canDischargeToAnyObject)
    local self = SetDischargeNodeSettingsEvent.emptyNew()

    self.placeable = placeable
    self.index = index
    self.canDischargeToGround = canDischargeToGround
    self.canDischargeToObject = canDischargeToObject
    self.canDischargeToVehicle = canDischargeToVehicle
    self.canDischargeToAnyObject = canDischargeToAnyObject

    return self
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeSettingsEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.index, DischargeNode.SEND_NUM_BITS_INDEX)
    streamWriteBool(streamId, self.canDischargeToGround)
    streamWriteBool(streamId, self.canDischargeToObject)
    streamWriteBool(streamId, self.canDischargeToVehicle)
    streamWriteBool(streamId, self.canDischargeToAnyObject)
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeSettingsEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.index = streamReadUIntN(streamId, DischargeNode.SEND_NUM_BITS_INDEX)
    self.canDischargeToGround = streamReadBool(streamId)
    self.canDischargeToObject = streamReadBool(streamId)
    self.canDischargeToVehicle = streamReadBool(streamId)
    self.canDischargeToAnyObject = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetDischargeNodeSettingsEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.placeable)
    end

    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        self.placeable:setDischargeNodeSettings(self.index, self.canDischargeToGround, self.canDischargeToObject, self.canDischargeToVehicle, self.canDischargeToAnyObject, true)
    end
end

---@param placeable PlaceableObject
---@param index number
---@param canDischargeToGround boolean
---@param canDischargeToObject boolean
---@param canDischargeToVehicle boolean
---@param canDischargeToAnyObject boolean
---@param noEventSend boolean | nil
function SetDischargeNodeSettingsEvent.sendEvent(placeable, index, canDischargeToGround, canDischargeToObject, canDischargeToVehicle, canDischargeToAnyObject, noEventSend)
    if not noEventSend then
        local event = SetDischargeNodeSettingsEvent.new(placeable, index, canDischargeToGround, canDischargeToObject, canDischargeToVehicle, canDischargeToAnyObject)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
