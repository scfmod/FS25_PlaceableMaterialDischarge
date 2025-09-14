---@class SetDischargeNodeEnabledEvent : Event
---@field placeable PlaceableObject
---@field index number
---@field enabled boolean
SetDischargeNodeEnabledEvent = {}

local SetDischargeNodeEnabledEvent_mt = Class(SetDischargeNodeEnabledEvent, Event)

InitEventClass(SetDischargeNodeEnabledEvent, 'SetDischargeNodeEnabledEvent')

---@return SetDischargeNodeEnabledEvent
function SetDischargeNodeEnabledEvent.emptyNew()
    ---@type SetDischargeNodeEnabledEvent
    local self = Event.new(SetDischargeNodeEnabledEvent_mt)
    return self
end

---@param placeable PlaceableObject
---@param index number
---@param enabled boolean
---@return SetDischargeNodeEnabledEvent
function SetDischargeNodeEnabledEvent.new(placeable, index, enabled)
    local self = SetDischargeNodeEnabledEvent.emptyNew()

    self.placeable = placeable
    self.index = index
    self.enabled = enabled

    return self
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeEnabledEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.index, DischargeNode.SEND_NUM_BITS_INDEX)
    streamWriteBool(streamId, self.enabled)
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeEnabledEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.index = streamReadUIntN(streamId, DischargeNode.SEND_NUM_BITS_INDEX)
    self.enabled = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetDischargeNodeEnabledEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.placeable)
    end

    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        self.placeable:setDischargeNodeEnabled(self.index, self.enabled, true)
    end
end

---@param placeable PlaceableObject
---@param index number
---@param enabled boolean
---@param noEventSend boolean | nil
function SetDischargeNodeEnabledEvent.sendEvent(placeable, index, enabled, noEventSend)
    if not noEventSend then
        local event = SetDischargeNodeEnabledEvent.new(placeable, index, enabled)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
