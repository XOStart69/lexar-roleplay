---@meta

lib = lib
cache = cache
locale = locale

---@alias RequireJobs string|string[]|table<string, number|number[]>

---@class PedComponent
---@field component_id number
---@field drawable number
---@field texture number

---@class PedProp
---@field prop_id number
---@field drawable number
---@field texture number

---@class PedHeadBlend
---@field shapeFirst number
---@field shapeSecond number
---@field shapeThird number
---@field skinFirst number
---@field skinSecond number
---@field skinThird number
---@field shapeMix number
---@field skinMix number
---@field thirdMix number

---@class PedHeadOverlay
---@field style number
---@field opacity number
---@field color number
---@field secondColor number

---@class PedHair
---@field style number
---@field color number
---@field highlight number
---@field texture number
---@field fade number?

---@class Tattoo
---@field name string
---@field label string
---@field hashMale string
---@field hashFemale string
---@field zone string
---@field collection string
---@field opacity number?

---@alias PedTattoos table<string, Tattoo[]>
---@alias PedFaceFeatures table<string, number>
---@alias PedHeadOverlays table<string, PedHeadOverlay>

---@class PedAppearance
---@field model string
---@field headBlend PedHeadBlend
---@field faceFeatures PedFaceFeatures
---@field headOverlays PedHeadOverlays
---@field components PedComponent[]
---@field props PedProp[]
---@field hair PedHair
---@field tattoos PedTattoos
---@field eyeColor number

---@class RangeSetting
---@field min number
---@field max number
---@field factor number?
---@field blacklist number[]?

---@class BlacklistSettings
---@field drawables number[]
---@field textures number[]

---@class BlacklistEntry
---@field drawables number[]?
---@field textures number[]?
---@field jobs RequireJobs?
---@field gangs RequireJobs?
---@field aces string[]?
---@field identifiers string[]?
---@field citizenids string[]?

---@alias BlacklistSlots table<string, BlacklistEntry[]>
---@alias BlacklistGroup { hair: BlacklistEntry[]?, components: BlacklistSlots?, props: BlacklistSlots? }

---@class PedGroup
---@field label string?
---@field models string[]
---@field jobs RequireJobs?
---@field gangs RequireJobs?
---@field aces string[]?
---@field identifiers string[]?

---@class PedRule : PedGroup
---@field id number

---@class DialogField
---@field type "input"|"select"
---@field label string
---@field placeholder string?
---@field default string?
---@field required boolean?
---@field disabled boolean?
---@field options { label: string, value: string }[]?

---@class MenuOption
---@field title string
---@field description string?
---@field menu string? id of a submenu to open instead of running onSelect
---@field onSelect fun(args: any)?
---@field args any

---@class MenuDefinition
---@field id string
---@field title string
---@field menu string? id of the parent menu
---@field options MenuOption[]

---@class Outfit
---@field id number
---@field name string
---@field model string
---@field components PedComponent[]
---@field props PedProp[]

---@class HalfPed
---@field id number
---@field name string
---@field gender string
---@field drawable number

---@class BlacklistRow
---@field id number
---@field gender string
---@field category string
---@field slot string
---@field drawable number
---@field textures number[]?
---@field jobs RequireJobs?
---@field gangs RequireJobs?
---@field aces string[]?
---@field citizenids string[]?

---@class HalfPedAccess
---@field id number
---@field halfPedId number
---@field name string
---@field citizenid string
---@field gender string
---@field drawable number
---@field expires string?
