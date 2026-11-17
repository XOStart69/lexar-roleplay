--[[
    Which ped models the editor offers.

    In "allowlist" mode only the models named below are offered. In "blacklist" mode every model in
    data/peds.lua is offered except the ones named below. Either way a group with no requirement
    applies to everybody, and a group that names a job, gang, ace or citizen id applies only to
    whoever meets it: in allowlist mode meeting it hands the models over, in blacklist mode meeting
    it hands them back.

    Job and gang requirements accept the same shapes as the blacklist: "police", { "police", "ems" },
    { police = 3 } for grade 3 and up, or { police = { 2, 5 } } for those grades exactly.

    A lone "*" stands in for every model in data/peds.lua, and keeps covering whatever is added to it
    later. Naming models one by one is only worth it for a rule that should stay fixed.

    Admins add further rules through /appearanceadmin. Once the panel has imported this file, the
    database takes over and what is written here is no longer read.
]]
---@type { mode: "allowlist"|"blacklist", groups: PedGroup[] }
return {
    mode = "allowlist",
    groups = {}
}


