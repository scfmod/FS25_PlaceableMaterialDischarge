---@class SetDischargeNodeEmptySpeedEvent : Event
---@field placeable PlaceableObject
---@field index number
---@field emptySpeed number
SetDischargeNodeEmptySpeedEvent = {}

local SetDischargeNodeEmptySpeedEvent_mt = Class(SetDischargeNodeEmptySpeedEvent, Event)

InitEventClass(SetDischargeNodeEmptySpeedEvent, 'SetDischargeNodeEmptySpeedEvent')

---@return SetDischargeNodeEmptySpeedEvent
---@nodiscard
function SetDischargeNodeEmptySpeedEvent.emptyNew()
    return Event.new(SetDischargeNodeEmptySpeedEvent_mt)
end

---@param placeable PlaceableObject
---@param index number
---@param emptySpeed number
---@return SetDischargeNodeEmptySpeedEvent
---@nodiscard
function SetDischargeNodeEmptySpeedEvent.new(placeable, index, emptySpeed)
    local self = SetDischargeNodeEmptySpeedEvent.emptyNew()

    self.placeable = placeable
    self.index = index
    self.emptySpeed = emptySpeed

    return self
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeEmptySpeedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.index, DischargeNode.SEND_NUM_BITS_INDEX)
    streamWriteFloat32(streamId, self.emptySpeed)
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeEmptySpeedEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.index = streamReadUIntN(streamId, DischargeNode.SEND_NUM_BITS_INDEX)
    self.emptySpeed = streamReadFloat32(streamId)

    self:run(connection)
end

---@param connection Connection
function SetDischargeNodeEmptySpeedEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.placeable)
    end

    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        self.placeable:setDischargeNodeEmptySpeed(self.index, self.emptySpeed, true)
    end
end

---@param placeable PlaceableObject
---@param index number
---@param emptySpeed number
---@param noEventSend boolean | nil
function SetDischargeNodeEmptySpeedEvent.sendEvent(placeable, index, emptySpeed, noEventSend)
    if not noEventSend then
        local event = SetDischargeNodeEmptySpeedEvent.new(placeable, index, emptySpeed)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
