---@class MaterialDischargeNode : DischargeNode
---@field placeable PlaceableMaterialDischargeable
---@field superClass fun(): DischargeNode
MaterialDischargeNode = {}

local MaterialDischargeNode_mt = Class(MaterialDischargeNode, DischargeNode)

---@param schema XMLSchema
---@param key string
function MaterialDischargeNode.registerXMLPaths(schema, key)
    DischargeNode.registerXMLPaths(schema, key)

    schema:register(XMLValueType.FLOAT, key .. '#litersPerHour', 'Empty speed in l/hour', 4000)
    schema:register(XMLValueType.BOOL, key .. '#useTimescale', 'If discharge speed should be multiplied with timescale', true)
end

---@param placeable PlaceableMaterialDischargeable
---@param index number
---@param dirtyFlag number
---@return MaterialDischargeNode
---@nodiscard
function MaterialDischargeNode.new(placeable, index, dirtyFlag)
    local self = DischargeNode.new(placeable, index, dirtyFlag, MaterialDischargeNode_mt)
    ---@cast self MaterialDischargeNode

    self:setEmptySpeed(4000)
    self.useEffectiveTimeScale = true

    return self
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function MaterialDischargeNode:load(xmlFile, key)
    if not self:superClass().load(self, xmlFile, key) then
        return false
    end

    self:setEmptySpeed(xmlFile:getValue(key .. '#litersPerHour', self.emptySpeed))
    self.useEffectiveTimeScale = xmlFile:getValue(key .. '#useTimescale', self.useEffectiveTimeScale)

    return true
end

---@return number
---@nodiscard
function MaterialDischargeNode:addFillLevel(fillLevelDelta)
    return fillLevelDelta
end

---@return number
---@nodiscard
function MaterialDischargeNode:getFillLevel()
    return 100000
end

---@return boolean
---@nodiscard
function MaterialDischargeNode:getIsActive()
    return true
end

---@param value number
function MaterialDischargeNode:setEmptySpeed(value)
    self.litersPerMs = value / 3600000
    self.emptySpeed = value
end
