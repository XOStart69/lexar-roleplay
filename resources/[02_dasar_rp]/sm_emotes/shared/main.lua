---@enum AnimFlag
AnimFlag = {
    MOVING = 51,
    LOOP = 1,
    STUCK = 50,
}

---@enum ScenarioType
ScenarioType = {
    MALE = 'MaleScenario',
    SCENARIO = 'Scenario',
    OBJECT = 'ScenarioObject',
}

---@enum Category
Category = {
    EXPRESSIONS = 'Expressions',
    WALKS = 'Walks',
    SHARED = 'Shared',
    DANCES = 'Dances',
    ANIMAL_EMOTES = 'AnimalEmotes',
    EXITS = 'Exits',
    EMOTES = 'Emotes',
    PROP_EMOTES = 'PropEmotes',
    CUSTOM_ANIMATIONS = "CustomAnimations"
}

---@enum UiLabel
Label = {
    Scenario = 'Scenario',

    [Category.EXPRESSIONS] = 'Expressions',
    [Category.WALKS] = 'Walks',
    [Category.SHARED] = 'Shared Emote',
    [Category.DANCES] = 'Dances Emote',
    [Category.ANIMAL_EMOTES] = 'Animal Emote',
    [Category.EMOTES] = 'General Emote',
    [Category.PROP_EMOTES] = 'Prop Emote',
    [Category.CUSTOM_ANIMATIONS] = 'Custom Emote',
}

---@enum PlacementState
PlacementState = {
    NONE = 'None',
    PREVIEWING = 'Previewing',
    WALKING = 'Walking',
    IN_ANIMATION = 'In Animation'
}