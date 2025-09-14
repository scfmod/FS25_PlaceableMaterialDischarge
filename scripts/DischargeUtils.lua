---@class DischargeUtils
DischargeUtils = {}

---@param xmlFile XMLFile
---@param key string
---@return FillUnitObject[]?
function DischargeUtils.loadDischargeFillTypes(xmlFile, key)
    ---@type string?
    local strFillTypes = xmlFile:getValue(key)

    if strFillTypes ~= nil then
        local registered = {}
        local fillTypes = {}
        local fillTypeNames = strFillTypes:split(' ')

        for _, name in ipairs(fillTypeNames) do
            name = name:upper()

            ---@type FillTypeObject?
            local fillType = g_fillTypeManager:getFillTypeByName(name)

            if fillType ~= nil and not registered[fillType] and DensityMapHeightUtil.getCanTipToGround(fillType.index) then
                registered[fillType] = true
                table.insert(fillTypes, fillType)
            end
        end

        return fillTypes
    end
end

---@param node DischargeNode
---@param xmlFile XMLFile
---@param key string
function DischargeUtils.loadDischargeInfo(node, xmlFile, key)
    ---@diagnostic disable-next-line: missing-fields
    node.info = {}

    node.info.width = xmlFile:getValue(key .. '.info#width', 1) / 2
    node.info.length = xmlFile:getValue(key .. '.info#length', 1) / 2
    node.info.zOffset = xmlFile:getValue(key .. '.info#zOffset', 0)
    node.info.yOffset = xmlFile:getValue(key .. '.info#yOffset', 2)
    node.info.limitToGround = xmlFile:getValue(key .. '.info#limitToGround', true)
    node.info.useRaycastHitPosition = xmlFile:getValue(key .. '.info#useRaycastHitPosition', false)

    node.info.node = xmlFile:getValue(key .. '.info#node', node.node, node.placeable.components, node.placeable.i3dMappings)

    if node.info.node == node.node then
        node.info.node = createTransformGroup('dischargeInfoNode')
        link(node.node, node.info.node)
    end
end

---@param dischargeNode DischargeNode
---@param xmlFile XMLFile
---@param key string
function DischargeUtils.loadDischargeRaycast(dischargeNode, xmlFile, key)
    ---@diagnostic disable-next-line: missing-fields
    dischargeNode.raycast = {}

    dischargeNode.raycast.useWorldNegYDirection = xmlFile:getValue(key .. '.raycast#useWorldNegYDirection', false)
    dischargeNode.raycast.yOffset = xmlFile:getValue(key .. '.raycast#yOffset', 0)

    dischargeNode.raycast.node = xmlFile:getValue(key .. '.raycast#node', dischargeNode.node, dischargeNode.placeable.components, dischargeNode.placeable.i3dMappings)

    local maxDistance = xmlFile:getValue(key .. '.raycast#maxDistance', 10)

    dischargeNode.maxDistance = xmlFile:getValue(key .. '#maxDistance', maxDistance)
end

---@param dischargeNode DischargeNode
---@param xmlFile XMLFile
---@param key string
function DischargeUtils.loadDischargeTriggers(dischargeNode, xmlFile, key)
    ---@diagnostic disable-next-line: missing-fields
    dischargeNode.trigger = {}

    dischargeNode.trigger.node = xmlFile:getValue(key .. '.trigger#node', nil, dischargeNode.placeable.components, dischargeNode.placeable.i3dMappings)
    dischargeNode.trigger.objects = {}
    dischargeNode.trigger.numObjects = 0

    if dischargeNode.trigger.node ~= nil then
        addTrigger(dischargeNode.trigger.node, 'dischargeTriggerCallback', dischargeNode)
        setTriggerReportStatics(dischargeNode.trigger.node, true)
    end

    ---@diagnostic disable-next-line: missing-fields
    dischargeNode.activationTrigger = {}

    dischargeNode.activationTrigger.node = xmlFile:getValue(key .. '.activationTrigger#node', nil, dischargeNode.placeable.components, dischargeNode.placeable.i3dMappings)
    dischargeNode.activationTrigger.objects = {}
    dischargeNode.activationTrigger.numObjects = 0

    if dischargeNode.activationTrigger.node ~= nil then
        addTrigger(dischargeNode.activationTrigger.node, 'dischargeActivationTriggerCallback', dischargeNode)
    end
end

---@param dischargeNode DischargeNode
---@param xmlFile XMLFile
---@param key string
function DischargeUtils.loadDischargeEffects(dischargeNode, xmlFile, key)
    dischargeNode.effects = g_effectManager:loadEffect(xmlFile, key .. '.effects', dischargeNode.placeable.components, dischargeNode.placeable, dischargeNode.placeable.i3dMappings, math.huge)

    if dischargeNode.isClient then
        dischargeNode.playSound = xmlFile:getValue(key .. '#playSound')
        dischargeNode.soundNode = xmlFile:getValue(key .. '#soundNode', nil, dischargeNode.placeable.components, dischargeNode.placeable.i3dMappings)

        if dischargeNode.playSound then
            dischargeNode.dischargeSample = g_soundManager:loadSampleFromXML(xmlFile, key, 'dischargeSound', dischargeNode.placeable.baseDirectory, dischargeNode.placeable.components, 0, AudioGroup.VEHICLE, dischargeNode.placeable.i3dMappings, dischargeNode.placeable)
        end

        if xmlFile:getValue(key .. '.dischargeSound#overwriteSharedSound', false) then
            dischargeNode.playSound = false
        end

        dischargeNode.dischargeStateSamples = g_soundManager:loadSamplesFromXML(xmlFile, key, "dischargeStateSound", dischargeNode.placeable.baseDirectory, dischargeNode.placeable.components, 0, AudioGroup.VEHICLE, dischargeNode.placeable.i3dMappings, dischargeNode.placeable)
        dischargeNode.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", dischargeNode.placeable.components, dischargeNode.placeable, dischargeNode.placeable.i3dMappings)
        dischargeNode.effectAnimationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".effectAnimationNodes", dischargeNode.placeable.components, dischargeNode.placeable, dischargeNode.placeable.i3dMappings)
    end

    dischargeNode.lastEffect = dischargeNode.effects[#dischargeNode.effects]
end

---@param node DischargeNode
---@param xmlFile XMLFile
---@param key string
function DischargeUtils.loadDischargeObjectChanges(node, xmlFile, key)
    node.distanceObjectChanges = {}

    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key .. '.distanceObjectChanges', node.distanceObjectChanges, node.placeable.components, node.placeable)

    if #node.distanceObjectChanges == 0 then
        node.distanceObjectChanges = nil
    else
        node.distanceObjectChangeThreshold = xmlFile:getValue(key .. '.distanceObjectChanges#threshold', 0.5)
        ObjectChangeUtil.setObjectChanges(node.distanceObjectChanges, false, node.placeable, nil, true)
    end


    node.stateObjectChanges = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key .. '.stateObjectChanges', node.stateObjectChanges, node.placeable.components, node.placeable)

    if #node.stateObjectChanges == 0 then
        node.stateObjectChanges = nil
    else
        ObjectChangeUtil.setObjectChanges(node.stateObjectChanges, false, node.placeable, nil, true)
    end
end
