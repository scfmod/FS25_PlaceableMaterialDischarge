# Material Dischargeable

Generate materials and discharge to ground, vehicles and objects (like pallets).

# Table of Contents

- [Add specialization](#add-specialization-to-placeable-type)
- [Placeable XML](#placeable-xml)
- [Activation trigger](#activation-trigger)
- [Discharge nodes](#discharge-nodes)

## Add specialization to placeable type

```xml
<modDesc>
    ...
    <placeableTypes>
        <!-- Extend parent type, can be anything -->
        <type name="customPlaceable" parent="simplePlaceable" filename="$dataS/scripts/placeables/Placeable.lua">
            <specialization name="FS25_0_PlaceableMaterialDischarge.materialDischargeable" />
        </type>
    </placeableTypes>
</modDesc>
```

## Placeable XML

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<placeable>
    <materialDischargeable>
        <activationTrigger node="playerActivationTrigger" />
        <dischargeNodes>
            ...
        </dischargeNodes>
    </materialDischargeable>
</placeable>
```

## Activation trigger

```
placeable.materialDischargeable.activationTrigger
```

### Attributes

| Name         | Type    | Required | Default     | Description                                                                                                   |
|--------------|---------|----------|-------------|---------------------------------------------------------------------------------------------------------------|
| node         | node    | No       |             | Player activation trigger for openening the control panel interface |
| requireAccess | string | No       | ```farmManager``` | Access required in order to access the control panel. ```admin```, ```farmManager```, ```none``` |


## Discharge nodes

```
placeable.materialDischargeable.dischargeNodes.dischargeNode(%)
```

Custom discharge nodes for placeables, capable of multiple simultaneously discharging. Provides support for the same child elements as the base game Dischargeable:

```
- info
- raycast
- trigger
- activationTrigger
- distanceObjectChanges
- stateObjectChanges
- effects
- dischargeSound
- dischargeStateSound
- animationNodes
- effectAnimationNodes
```

| Name                                 | Type      | Required | Default     | Description                  |
|--------------------------------------|-----------|----------|-------------|------------------------------|
| node                                 | node      | Yes      |             | Discharge node index path    |
| litersPerHour                        | float     | No       | ```4000```  | Discharge speed in liters/hour |
| fillTypes                            | string    | No       |             | Available fill type(s) to choose from, space separated. Leave empty to enable all fill types |
| name                                 | string    | No       |             | Display name. L10N string supported |
| defaultEnabled                       | boolean   | No       | ```true```  | Default enabled value |
| canDischargeToGround                 | boolean   | No       | ```true```  | Can discharge to ground |
| canDischargeToObject                 | boolean   | No       | ```true```  | Can discharge to object |
| canDischargeToVehicle                | boolean   | No       | ```true```  | Can discharge to other vehicles |
| canDischargeToAnyObject              | boolean   | No       | ```false``` | Can discharge any object independent of vehicle ownership |
| stopDischargeIfNotPossible           | boolean   | No       | ```true```  | Stop discharge if not possible |
| useTimeScale                         | boolean   | No       | ```true```  | If discharge speed should be multiplied with timescale |
| effectTurnOffThreshold               | float     | No       | ```0.25```  | After this time (ms) has passed and nothing has been processed the effects are turned off |
| maxDistance                          | float     | No       | ```10```    | Max discharge distance |
| soundNode                            | node      | No       |             | Sound node index path |
| playSound                            | boolean   | No       | ```true```  | Whether to play sounds |
| toolType                             | string    | No       | ```dischargeable``` | Tool type |
