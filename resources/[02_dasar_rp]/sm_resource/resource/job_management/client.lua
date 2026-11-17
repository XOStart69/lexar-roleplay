local function getNearbyPlayers()
    local players = {}
    local nearbyPlayers = lib.getNearbyPlayers(RHDCache.coords.xyz, 10)

    if nearbyPlayers and #nearbyPlayers > 0 then
        array.forEach(nearbyPlayers, function (val)
            local player = val.id
            local serverId = GetPlayerServerId(player)

            local playerState = Player(serverId)?.state
            local playername = playerState?.name or 'Unknown'
            local playercitizenid = playerState?.citizenid or 'Unknown'

            players[#players+1] = {
                name = playername,
                citizenid = playercitizenid,
                source = serverId,
            }
        end)
    end

    return players
end

local DynamicMenuItems = {}
local exportsWrapper = require 'export_wrapper'

local mechanicJobs = {
    ['mechanic'] = true,
    ['maxspeedgarage'] = true,
    ['mechanic969'] = true,
    ['stunberg'] = true,
}

local function AddBossMenuItem(data, id)
    local menuID = id or (#DynamicMenuItems + 1)
    DynamicMenuItems[menuID] = lib.table.deepclone(data)
    return menuID
end

exportsWrapper('qb-management', 'AddBossMenuItem', AddBossMenuItem)

local function RemoveBossMenuItem(id)
    DynamicMenuItems[id] = nil
end

exportsWrapper('qb-management', 'RemoveBossMenuItem', RemoveBossMenuItem)

local shops = localmodule 'config.shops'
local locations = localmodule 'config.location'
local pedModule = require 'modules.pedHandle.client'
local whitelistjob = localmodule 'config.whitelistjob'

---@param employee table
---@param lockedFrom number?
local function manageEmployee(employee, lockedFrom)
    local playerjob = QBPlayerData?.job
    if not (playerjob?.isboss) then return end

    local menuOptions = {
        {
            title = employee.name,
            description = ('%s | %s'):format(employee.grade.name, employee.online and 'Online' or 'Offline'),
            icon = 'fa-solid fa-circle-info',
            isMenuHeader = true
        }
    }

    local gradeList = qb_jobs[playerjob.name].grades
    local gradeLevels = {}

    for k in pairs(gradeList) do
        gradeLevels[#gradeLevels+1] = tonumber(k)
    end

    table.sort(gradeLevels)

    array.forEach(gradeLevels, function (level)
        local grade = gradeList[tostring(level)]
        local isCurrent = level == employee.grade.level

        menuOptions[#menuOptions+1] = {
            title = grade.name,
            description = isCurrent and ('Grade: %s (saat ini)'):format(level) or ('Grade: %s'):format(level),
            icon = 'fa-solid fa-file-pen',
            disabled = isCurrent or level > playerjob.grade.level or (lockedFrom and (level >= lockedFrom or employee.grade.level >= lockedFrom)) or false,
            onSelect = function()
                TriggerServerEvent('job_management:GradeUpdate', {
                    cid = employee.empSource,
                    grade = level
                })
            end
        }
    end)

    menuOptions[#menuOptions+1] = {
        title = 'Fire Employee',
        description = '',
        icon = 'fa-solid fa-user-large-slash',
        disabled = employee.grade.level > playerjob.grade.level or (lockedFrom and employee.grade.level >= lockedFrom) or false,
        onSelect = function()
            local confirm = lib.alertDialog({
                header = 'Pecat Karyawan',
                content = ('Pecat **%s** dari %s?'):format(employee.name, playerjob.label),
                centered = true,
                cancel = true,
            })

            if confirm ~= 'confirm' then
                manageEmployee(employee, lockedFrom)
                return
            end

            TriggerServerEvent('job_management:FireEmployee', employee.empSource)
        end
    }

    lib.registerContext({
        id = 'manage_employee_menu',
        title = ('Manage %s - %s'):format(employee.name, playerjob.label:upper()),
        options = menuOptions,
        onBack = function() end,
        menu = 'employees_menu'
    })
    lib.showContext('manage_employee_menu')
end

local function employeelist()
    local playerjob = QBPlayerData?.job
    if not (playerjob?.isboss) then return end

    local employees, lockedFrom = lib.callback.await('job_management:getEmployees')

    if not employees then employees = {} end

    local menuOptions = {
        {
            title = ('Manage Employees - %s'):format(playerjob.label:upper()),
            description = '',
            icon = 'fa-solid fa-circle-info',
            readOnly = true
        }
    }

    if #employees > 0 then
        array.forEach(employees, function (employee)
            menuOptions[#menuOptions+1] = {
                title = employee.name,
                description = employee.grade.name .. " | " .. employee.last_updated,
                icon = 'fa-solid fa-circle-user',
                onSelect = function()
                    manageEmployee(employee, lockedFrom)
                end
            }
        end)
    end

    lib.registerContext({
        id = 'employees_menu',
        title = ('Manage Employees - %s'):format(playerjob.label:upper()),
        options = menuOptions,
        onBack = function () end,
        menu = 'boss_menu'
    })

    lib.showContext('employees_menu')
end

local function HireMenu()
    local playerjob = QBPlayerData?.job
    if not (playerjob?.isboss) then return end

    local menuOptions = {
        {
            title = ('Hire Employees - %s'):format(playerjob.label:upper()),
            description = '',
            icon = 'fa-solid fa-circle-info',
            isMenuHeader = true
        }
    }

    local players = getNearbyPlayers()

    if players and #players > 0 then
        array.forEach(players, function (player)
            menuOptions[#menuOptions+1] = {
                title = player.name,
                description = ('Citizen ID: %s - ID: %s'):format(player.citizenid, player.source),
                icon = 'fa-solid fa-user-check',
                onSelect = function()
                    TriggerServerEvent('job_management:HireEmployee', player.source)
                end
            }
        end)
    end

    lib.registerContext({
        id = 'hire_menu',
        title = ('Hire Employees - %s'):format(playerjob.label:upper()),
        options = menuOptions,
        onBack = function () end,
        menu = 'boss_menu'
    })
    lib.showContext('hire_menu')
end

local function openMenu()
    local playerjob = QBPlayerData?.job
    if not (playerjob?.isboss) then return end

    local count, max = lib.callback.await('job_management:getmembercount', 1500)

    local menuOptions = {
        {
            title = ('Boss Menu - %s'):format(playerjob.label:upper()),
            description = "Member saat ini: " .. count .. "/" .. max,
            icon = 'fa-solid fa-circle-info',
            isMenuHeader = true
        },
        {
            title = 'Manage Employees',
            description = 'Check your Employees List',
            icon = 'fa-solid fa-list',
            onSelect = employeelist
        },
        {
            title = 'Hire Employees',
            description = 'Hire Nearby Civilians',
            icon = 'fa-solid fa-hand-holding',
            onSelect = HireMenu
        },
        {
            title = 'Storage Access',
            description = 'Open Storage',
            icon = 'fa-solid fa-box-open',
            onSelect = function()
                TriggerServerEvent('qb-bossmenu:server:stash')
            end
        },
        {
            title = 'Outfits',
            description = 'See Saved Outfits',
            icon = 'fa-solid fa-shirt',
            onSelect = function()
                exports.sm_appearance:openOutfitMenu()
            end
        },
    }

    if mechanicJobs[playerjob.name] then
        menuOptions[#menuOptions+1] = {
            title = 'Discount Codes',
            description = 'Manage Discount Codes',
            icon = 'fa-solid fa-tags',
            onSelect = function()
                local codes = lib.callback.await('job_management:getDiscountCodes')

                local codeOptions = {
                    {
                        title = ('Discount Codes - %s'):format(playerjob.label:upper()),
                        description = '',
                        icon = 'fa-solid fa-circle-info',
                        readOnly = true
                    },
                    {
                        title = 'Create New Code',
                        description = 'Generate a new discount code',
                        icon = 'fa-solid fa-plus',
                        onSelect = function()
                            local percentages = { 5, 10, 15, 20 }
                            local percentOptions = {
                                {
                                    title = 'Select Percentage',
                                    description = '',
                                    icon = 'fa-solid fa-circle-info',
                                    readOnly = true
                                }
                            }

                            array.forEach(percentages, function(pct)
                                percentOptions[#percentOptions+1] = {
                                    title = ('%d%%'):format(pct),
                                    icon = 'fa-solid fa-percent',
                                    onSelect = function()
                                        local counts = { 1, 2, 3, 4, 5, 10, 15, 20 }
                                        local countOptions = {
                                            {
                                                title = ('Usage Count - %d%% Discount'):format(pct),
                                                description = '',
                                                icon = 'fa-solid fa-circle-info',
                                                readOnly = true
                                            }
                                        }

                                        array.forEach(counts, function(cnt)
                                            countOptions[#countOptions+1] = {
                                                title = ('%dx'):format(cnt),
                                                icon = 'fa-solid fa-hashtag',
                                                onSelect = function()
                                                    TriggerServerEvent('job_management:createDiscountCode', pct, cnt)
                                                end
                                            }
                                        end)

                                        lib.registerContext({
                                            id = 'discount_count_menu',
                                            title = ('Usage Count - %d%% Discount'):format(pct),
                                            options = countOptions,
                                            onBack = function() end,
                                            menu = 'discount_percent_menu'
                                        })
                                        lib.showContext('discount_count_menu')
                                    end
                                }
                            end)

                            lib.registerContext({
                                id = 'discount_percent_menu',
                                title = 'Select Percentage',
                                options = percentOptions,
                                onBack = function() end,
                                menu = 'discount_codes_menu'
                            })
                            lib.showContext('discount_percent_menu')
                        end
                    }
                }

                if codes and #codes > 0 then
                    array.forEach(codes, function(entry)
                        codeOptions[#codeOptions+1] = {
                            title = entry.code,
                            description = ('%d%% | Usage: %d/%d'):format(entry.percentage, entry.currently_using, entry.count_to_use),
                            icon = 'fa-solid fa-ticket',
                            onSelect = function()
                                local actionOptions = {
                                    {
                                        title = entry.code,
                                        description = ('%d%% | Usage: %d/%d'):format(entry.percentage, entry.currently_using, entry.count_to_use),
                                        icon = 'fa-solid fa-circle-info',
                                        readOnly = true
                                    },
                                    {
                                        title = 'Copy Code',
                                        description = 'Copy to clipboard',
                                        icon = 'fa-solid fa-copy',
                                        onSelect = function()
                                            lib.setClipboard(entry.code)
                                            lib.notify({ description = 'Code copied!', type = 'success' })
                                        end
                                    },
                                    {
                                        title = 'Delete Code',
                                        description = 'Remove this discount code',
                                        icon = 'fa-solid fa-trash',
                                        onSelect = function()
                                            local confirm = lib.alertDialog({
                                                header = 'Delete Discount Code',
                                                content = ('Delete code **%s** (%d%%)?'):format(entry.code, entry.percentage),
                                                centered = true,
                                                cancel = true,
                                            })
                                            if confirm == 'confirm' then
                                                TriggerServerEvent('job_management:deleteDiscountCode', entry.code)
                                            end
                                        end
                                    }
                                }

                                lib.registerContext({
                                    id = 'discount_action_menu',
                                    title = entry.code,
                                    options = actionOptions,
                                    onBack = function() end,
                                    menu = 'discount_codes_menu'
                                })
                                lib.showContext('discount_action_menu')
                            end
                        }
                    end)
                end

                lib.registerContext({
                    id = 'discount_codes_menu',
                    title = ('Discount Codes - %s'):format(playerjob.label:upper()),
                    options = codeOptions,
                    onBack = function() end,
                    menu = 'boss_menu'
                })
                lib.showContext('discount_codes_menu')
            end
        }
    end

    for _, v in pairs(DynamicMenuItems) do
        menuOptions[#menuOptions+1] = v
    end

    local shopdata = shops[playerjob.name]

    if shopdata then
        menuOptions[#menuOptions+1] = {
            title = 'Job Shop',
            description = 'Access ' .. shopdata.label,
            icon = 'fa-solid fa-shopping-cart',
            onSelect = function()
                TriggerServerEvent('job_management:openShop')
            end
        }
    end

    lib.registerContext({
        id = 'boss_menu',
        title = ('Boss Menu - %s'):format(playerjob.label:upper()),
        options = menuOptions
    })

    lib.showContext('boss_menu')
end

RegisterNetEvent('job_management:openMenu', function()
    if source == '' then return end

    openMenu()
end)

RegisterNetEvent('job_management:openShop', function(shopId)
    if source == '' then return end
    ox_inventory:openInventory('shop', { type = shopId })
end)

CreateThread(function()
    for job, data in pairs(locations) do

        local locationList = data.coords and {data} or data

        for i = 1, #locationList do
            local loc = locationList[i]
            local coords = loc.coords
            local zoneName = job .. '_bossmenu_' .. i

            if loc.usePed then
                pedModule:new({
                    model = whitelistjob[job] and "A_M_Y_Business_02" or "G_M_M_ChiBoss_01",
                    coords = coords,
                    renderDistance = 30.0,
                    anim = {
                        dict = "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a",
                        name = "idle_a",
                        flag = 63
                    },
                    prop = {
                        model = "prop_cs_tablet",
                        bone = 28422,
                        rot = vec3(0.0, 0.0, 0.03),
                        pos = vec3(0.0, 0.0, 0.03),
                    },
                    target = {
                        {
                            label = "Boss Menu",
                            name = zoneName,
                            icon = "folder",
                            onSelect = openMenu,
                            distance = loc.targetDistance,
                            canInteract = function(entity, distance, coords)
                                local playerjob = QBPlayerData?.job
                                return playerjob?.name == job and playerjob.isboss
                            end
                        }
                    }
                })
            else
                ox_target:addSphereZone({
                    coords = coords.xyz,
                    radius = 0.8,
                    debug = false,
                    options = {
                        {
                            label = "Boss Menu",
                            name = zoneName,
                            icon = "folder",
                            distance = loc.targetDistance,
                            onSelect = function()
                                openMenu()
                            end,
                            canInteract = function()
                                local playerjob = QBPlayerData?.job
                                return playerjob?.name == job and playerjob.isboss
                            end
                        }
                    }
                })
            end
        end
    end
end)