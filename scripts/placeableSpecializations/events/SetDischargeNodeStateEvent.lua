---@class SetDischargeNodeStateEvent : Event
---@field placeable PlaceableObject
---@field index number
---@field state number
SetDischargeNodeStateEvent = {}

local SetDischargeNodeStateEvent_mt = Class(SetDischargeNodeStateEvent, Event)

InitEventClass(SetDischargeNodeStateEvent, 'SetDischargeNodeStateEvent')

---@return SetDischargeNodeStateEvent
function SetDischargeNodeStateEvent.emptyNew()
    ---@type SetDischargeNodeStateEvent
    local self = Event.new(SetDischargeNodeStateEvent_mt)
    return self
end

---@param placeable PlaceableObject
---@param index number
---@param state number
---@return SetDischargeNodeStateEvent
function SetDischargeNodeStateEvent.new(placeable, index, state)
    local self = SetDischargeNodeStateEvent.emptyNew()

    self.placeable = placeable
    self.index = index
    self.state = state

    return self
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.index, DischargeNode.SEND_NUM_BITS_INDEX)
    streamWriteUIntN(streamId, self.state, Dischargeable.SEND_NUM_BITS_DISCHARGE_STATE)
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeStateEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.index = streamReadUIntN(streamId, DischargeNode.SEND_NUM_BITS_INDEX)
    self.state = streamReadUIntN(streamId, Dischargeable.SEND_NUM_BITS_DISCHARGE_STATE)

    self:run(connection)
end

---@param connection Connection
function SetDischargeNodeStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.placeable)
    end

    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        self.placeable:setDischargeNodeState(self.index, self.state, true)
    end
end

---@param placeable PlaceableObject
---@param index number
---@param state number
---@param noEventSend boolean | nil
function SetDischargeNodeStateEvent.sendEvent(placeable, index, state, noEventSend)
    if not noEventSend then
        local event = SetDischargeNodeStateEvent.new(placeable, index, state)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
