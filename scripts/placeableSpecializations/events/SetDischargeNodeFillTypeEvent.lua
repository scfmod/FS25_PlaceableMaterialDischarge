---@class SetDischargeNodeFillTypeEvent : Event
---@field placeable PlaceableObject
---@field index number
---@field fillTypeIndex number
SetDischargeNodeFillTypeEvent = {}

local SetDischargeNodeFillTypeEvent_mt = Class(SetDischargeNodeFillTypeEvent, Event)

InitEventClass(SetDischargeNodeFillTypeEvent, 'SetDischargeNodeFillTypeEvent')

---@return SetDischargeNodeFillTypeEvent
---@nodiscard
function SetDischargeNodeFillTypeEvent.emptyNew()
    return Event.new(SetDischargeNodeFillTypeEvent_mt)
end

---@param placeable PlaceableObject
---@param index number
---@param fillTypeIndex number
---@return SetDischargeNodeFillTypeEvent
---@nodiscard
function SetDischargeNodeFillTypeEvent.new(placeable, index, fillTypeIndex)
    local self = SetDischargeNodeFillTypeEvent.emptyNew()

    self.placeable = placeable
    self.index = index
    self.fillTypeIndex = fillTypeIndex

    return self
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeFillTypeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.index, DischargeNode.SEND_NUM_BITS_INDEX)
    streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
end

---@param streamId number
---@param connection Connection
function SetDischargeNodeFillTypeEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.index = streamReadUIntN(streamId, DischargeNode.SEND_NUM_BITS_INDEX)
    self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

    self:run(connection)
end

---@param connection Connection
function SetDischargeNodeFillTypeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.placeable)
    end

    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        self.placeable:setDischargeNodeFillType(self.index, self.fillTypeIndex, true)
    end
end

---@param placeable PlaceableObject
---@param index number
---@param fillTypeIndex number
---@param noEventSend boolean | nil
function SetDischargeNodeFillTypeEvent.sendEvent(placeable, index, fillTypeIndex, noEventSend)
    if not noEventSend then
        local event = SetDischargeNodeFillTypeEvent.new(placeable, index, fillTypeIndex)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
