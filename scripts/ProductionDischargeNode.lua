---@class ProductionDischargeNode : DischargeNode
---@field placeable PlaceableProductionDischargeable
---@field stopDischargeIfNotActive boolean
---@field stopDischargeIfNotRunning boolean
---@field stopDischargeIfNoOutputSpace boolean
---@field superClass fun(): DischargeNode
ProductionDischargeNode = {}

local ProductionDischargeNode_mt = Class(ProductionDischargeNode, DischargeNode)

---@param schema XMLSchema
---@param key string
function ProductionDischargeNode.registerXMLPaths(schema, key)
    DischargeNode.registerXMLPaths(schema, key)

    schema:register(XMLValueType.FLOAT, key .. '#emptySpeed', "Empty speed in l/sec", 250)
    schema:register(XMLValueType.BOOL, key .. '#stopDischargeIfNotActive', 'Stop discharge if there are no active productions', true)
    schema:register(XMLValueType.BOOL, key .. '#stopDischargeIfNotRunning', 'Stop discharge if there are no running productions', false)
    schema:register(XMLValueType.BOOL, key .. '#stopDischargeIfNoOutputSpace', 'Stop discharge if there are no output space for active production', false)
    schema:register(XMLValueType.BOOL, key .. '#useTimescale', 'If discharge speed should be multiplied with timescale', false)
end

---@param placeable PlaceableProductionDischargeable
---@param index number
---@param dirtyFlag number
---@return ProductionDischargeNode
---@nodiscard
function ProductionDischargeNode.new(placeable, index, dirtyFlag)
    local self = DischargeNode.new(placeable, index, dirtyFlag, ProductionDischargeNode_mt)
    ---@cast self ProductionDischargeNode

    self.stopDischargeIfNotActive = true
    self.stopDischargeIfNotRunning = false
    self.stopDischargeIfNoOutputSpace = false
    self:setEmptySpeed(250)
    self.useEffectiveTimeScale = false

    return self
end

---@param xmlFile XMLFile
---@param key string
---@return boolean
---@nodiscard
function ProductionDischargeNode:load(xmlFile, key)
    if not self:superClass().load(self, xmlFile, key) then
        return false
    end

    self:setEmptySpeed(xmlFile:getValue(key .. '#emptySpeed', self.emptySpeed))
    self.stopDischargeIfNotActive = xmlFile:getValue(key .. '#stopDischargeIfNotActive', self.stopDischargeIfNotActive)
    self.stopDischargeIfNotRunning = xmlFile:getValue(key .. '#stopDischargeIfNotRunning', self.stopDischargeIfNotRunning)
    self.stopDischargeIfNoOutputSpace = xmlFile:getValue(key .. '#stopDischargeIfNoOutputSpace', self.stopDischargeIfNoOutputSpace)
    self.useEffectiveTimeScale = xmlFile:getValue(key .. '#useTimescale', self.useEffectiveTimeScale)

    return true
end

---@return number
---@nodiscard
function ProductionDischargeNode:addFillLevel(fillLevelDelta)
    local storage = self:getStorage()
    local fillTypeIndex = self:getDischargeFillType()
    local fillLevel = storage:getFillLevel(fillTypeIndex)

    storage:setFillLevel(fillLevel + fillLevelDelta, fillTypeIndex)

    return storage:getFillLevel(fillTypeIndex) - fillLevel
end

---@return boolean
---@nodiscard
function ProductionDischargeNode:getIsActive()
    local isActive, isRunning = self:getProductionsStatus()

    if self.stopDischargeIfNotActive and not isActive then
        return false
    elseif self.stopDischargeIfNotRunning and not isRunning then
        return false
    end

    return true
end

---@return Storage
---@nodiscard
function ProductionDischargeNode:getStorage()
    return self.placeable.spec_productionPoint.productionPoint.storage
end

---@return number fillLevel
---@return number fillTypeIndex
---@nodiscard
function ProductionDischargeNode:getFillLevel()
    local storage = self:getStorage()
    local fillTypeIndex = self:getDischargeFillType()

    return storage:getFillLevel(fillTypeIndex), fillTypeIndex
end

---@return { status: number }[]
---@nodiscard
function ProductionDischargeNode:getProductions()
    return self.placeable.spec_productionPoint.productionPoint.productions
end

---@return boolean hasActiveProductions
---@return boolean hasRunningProductions
---@nodiscard
function ProductionDischargeNode:getProductionsStatus()
    local isActive = false
    local isRunning = false

    for _, production in ipairs(self:getProductions()) do
        if production.status ~= ProductionPoint.PROD_STATUS.INACTIVE then
            isActive = true

            if production.status == ProductionPoint.PROD_STATUS.RUNNING then
                isRunning = true
            elseif production.status == ProductionPoint.PROD_STATUS.NO_OUTPUT_SPACE and not self.stopDischargeIfNoOutputSpace then
                isRunning = true
            end
        end
    end

    return isActive, isRunning
end

---@param value number
function ProductionDischargeNode:setEmptySpeed(value)
    self.litersPerMs = value / 1000
    self.emptySpeed = value
end
