-- -- DEV: Scene placement tool
-- -- /placescene => placement mode, preview ped mengikuti raycast
-- -- [KLIK KIRI]  = konfirmasi posisi + copy coords ke clipboard
-- -- [E]          = play scene di posisi preview ped (tanpa pindah preview)
-- -- [SCROLL]     = putar heading
-- -- [BACKSPACE]  = batal

-- local placementActive = false
-- local devEntities = {}

-- local function clearDevEntities()
--     for _, e in pairs(devEntities) do
--         pcall(DeleteEntity, e)
--     end
--     devEntities = {}
-- end

-- --- Play hack scene on a ped at given coords (non-blocking, returns thread)
-- local function playHackScene(ped, coords, useCard, adjustments)
--     local animDict = lib.requestAnimDict("anim@heists@ornate_bank@hack")

--     lib.requestModel("hei_prop_hst_laptop")
--     lib.requestModel("hei_p_m_bag_var22_arm_s")

--     SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
--     SetEntityHeading(ped, coords.w)
--     FreezeEntityPosition(ped, true)

--     local pcoords   = GetEntityCoords(ped)
--     local protation = GetEntityRotation(ped, 2)

--     local animPos  = GetAnimInitialOffsetPosition(animDict, "hack_enter", coords.x, coords.y, coords.z, coords.x, coords.y, coords.z, 0, 2)
--     local animPos2 = GetAnimInitialOffsetPosition(animDict, "hack_loop",  coords.x, coords.y, coords.z, coords.x, coords.y, coords.z, 0, 2)
--     local animPos3 = GetAnimInitialOffsetPosition(animDict, "hack_exit",  coords.x, coords.y, coords.z, coords.x, coords.y, coords.z, 0, 2)

--     -- copy vector values into mutable numbers to avoid mutating FiveM vector objects
--     local ax, ay, az = animPos.x, animPos.y, animPos.z
--     local bx, by, bz = animPos2.x, animPos2.y, animPos2.z
--     local cx, cy, cz = animPos3.x, animPos3.y, animPos3.z

--     -- apply optional adjustment offsets per scene
--     if adjustments then
--         local ae = adjustments.enter or {x = 0.0, y = 0.0, z = 0.0}
--         local al = adjustments.loop  or {x = 0.0, y = 0.0, z = 0.0}
--         local axx = adjustments.exit  or {x = 0.0, y = 0.0, z = 0.0}

--         ax = ax + (ae.x or 0.0)
--         ay = ay + (ae.y or 0.0)
--         az = az + (ae.z or 0.0)

--         bx = bx + (al.x or 0.0)
--         by = by + (al.y or 0.0)
--         bz = bz + (al.z or 0.0)

--         cx = cx + (axx.x or 0.0)
--         cy = cy + (axx.y or 0.0)
--         cz = cz + (axx.z or 0.0)
--     end

--     local bag    = CreateObject(`hei_p_m_bag_var22_arm_s`, ax, ay, az, true, true, false)
--     local laptop = CreateObject(`hei_prop_hst_laptop`,     ax, ay, az, true, true, false)
--     local card   = useCard and CreateObject(joaat('hei_prop_heist_card_hack_02'), ax, ay, az, true, true, false)

--     devEntities.bag    = bag
--     devEntities.laptop = laptop
--     devEntities.card   = card

--     local netScene  = NetworkCreateSynchronisedScene(ax,  ay,  az,  protation.x, protation.y, protation.z, 2, false, false, 1065353216, 0, 1.3)
--     local netScene2 = NetworkCreateSynchronisedScene(bx,  by,  bz,  protation.x, protation.y, protation.z, 2, false, true,  1065353216, 0, 1.3)
--     local netScene3 = NetworkCreateSynchronisedScene(cx,  cy,  cz,  protation.x, protation.y, protation.z, 2, false, false, 1065353216, 0, 1.3)

--     NetworkAddPedToSynchronisedScene(ped, netScene, animDict, "hack_enter", 1.5, -4.0, 1, 16, 1148846080, 0)
--     NetworkAddEntityToSynchronisedScene(bag,    netScene, animDict, "hack_enter_bag",    4.0, -8.0, 1)
--     NetworkAddEntityToSynchronisedScene(laptop, netScene, animDict, "hack_enter_laptop", 4.0, -8.0, 1)
--     if card then NetworkAddEntityToSynchronisedScene(card, netScene, animDict, "hack_enter_card", 4.0, -8.0, 1) end

--     NetworkAddPedToSynchronisedScene(ped, netScene2, animDict, "hack_loop", 1.5, -4.0, 1, 16, 1148846080, 0)
--     NetworkAddEntityToSynchronisedScene(bag,    netScene2, animDict, "hack_loop_bag",    4.0, -8.0, 1)
--     NetworkAddEntityToSynchronisedScene(laptop, netScene2, animDict, "hack_loop_laptop", 4.0, -8.0, 1)
--     if card then NetworkAddEntityToSynchronisedScene(card, netScene2, animDict, "hack_loop_card", 4.0, -8.0, 1) end

--     NetworkAddPedToSynchronisedScene(ped, netScene3, animDict, "hack_exit", 1.5, -4.0, 1, 16, 1148846080, 0)
--     NetworkAddEntityToSynchronisedScene(bag,    netScene3, animDict, "hack_exit_bag",    4.0, -8.0, 1)
--     NetworkAddEntityToSynchronisedScene(laptop, netScene3, animDict, "hack_exit_laptop", 4.0, -8.0, 1)
--     if card then NetworkAddEntityToSynchronisedScene(card, netScene3, animDict, "hack_exit_card", 4.0, -8.0, 1) end

--     Wait(200)
--     NetworkStartSynchronisedScene(netScene)
--     Wait(6300)
--     NetworkStartSynchronisedScene(netScene2)
--     Wait(4000)
--     NetworkStartSynchronisedScene(netScene3)
--     Wait(4600)
--     NetworkStopSynchronisedScene(netScene3)

--     FreezeEntityPosition(ped, false)
--     clearDevEntities()
-- end


-- -- Command: adjustscene -> enter adjustment mode
-- RegisterCommand('adjustscene', function()
--     local placementActive = true
--     TriggerEvent('chat:addMessage', { args = { "^3[DEV]", "Adjustment mode: 1=enter 2=loop 3=exit | Scroll/keys adjust | LEFT CLICK copy | E play | BACKSPACE cancel" } })

--     CreateThread(function()
--         local playerPed   = cache.ped
--         local playerModel = GetEntityModel(playerPed)
--         local startCoords = GetEntityCoords(playerPed)

--         lib.requestModel(playerModel)
--         local previewPed = CreatePed(4, playerModel, startCoords.x, startCoords.y, startCoords.z, 0.0, false, false)
--         SetEntityAlpha(previewPed, 180, false)
--         SetEntityCollision(previewPed, false, false)
--         FreezeEntityPosition(previewPed, true)
--         SetEntityInvincible(previewPed, true)
--         SetBlockingOfNonTemporaryEvents(previewPed, true)

--         local heading = GetEntityHeading(playerPed)
--         local rotateSpeed = 3.0
--         local scenePlaying = false

--         local adjustments = {
--             enter = {x = 0.0, y = 0.0, z = 0.0},
--             loop  = {x = 0.0, y = 0.0, z = 0.0},
--             exit  = {x = 0.0, y = 0.0, z = 0.0}
--         }
--         local selected = 'enter' -- enter, loop, exit
--         local moveSpeed = 0.005

--         while placementActive do
--             local hit, _, hitCoords = lib.raycast.cam(1 + 16, 4, 20)

--             if hit then
--                 SetEntityCoords(previewPed, hitCoords.x, hitCoords.y, hitCoords.z, false, false, false, false)
--                 SetEntityHeading(previewPed, heading)

--                 -- switch selected scene part
--                 if IsDisabledControlJustPressed(0, 157) then selected = 'enter' end -- 1
--                 if IsDisabledControlJustPressed(0, 158) then selected = 'loop' end  -- 2
--                 if IsDisabledControlJustPressed(0, 160) then selected = 'exit' end  -- 3

--                 -- Adjust offsets with scroll/buttons
--                 if IsDisabledControlPressed(0, 175) then -- right (increase Y)
--                     adjustments[selected].y = adjustments[selected].y + moveSpeed
--                 end
--                 if IsDisabledControlPressed(0, 174) then -- left (decrease Y)
--                     adjustments[selected].y = adjustments[selected].y - moveSpeed
--                 end
--                 if IsDisabledControlPressed(0, 172) then -- up (increase X)
--                     adjustments[selected].x = adjustments[selected].x + moveSpeed
--                 end
--                 if IsDisabledControlPressed(0, 173) then -- down (decrease X)
--                     adjustments[selected].x = adjustments[selected].x - moveSpeed
--                 end
--                 if IsDisabledControlPressed(0, 44) then -- Q (increase Z)
--                     adjustments[selected].z = adjustments[selected].z + moveSpeed
--                 end
--                 if IsDisabledControlPressed(0, 20) then -- Z (decrease Z)
--                     adjustments[selected].z = adjustments[selected].z - moveSpeed
--                 end

--                 -- HUD - help + current values
--                 local baseY = 0.86
--                 SetTextFont(0)
--                 SetTextScale(0.35, 0.35)
--                 SetTextColour(255, 255, 255, 230)
--                 SetTextEntry("STRING")
--                 AddTextComponentString("Adjust Scene Controls:")
--                 DrawText(0.02, baseY)

--                 SetTextScale(0.32, 0.32)
--                 SetTextColour(255, 255, 0, 220)
--                 SetTextEntry("STRING")
--                 AddTextComponentString("1 = enter | 2 = loop | 3 = exit   E = play   LEFT CLICK = copy & exit   BACKSPACE = cancel")
--                 DrawText(0.02, baseY + 0.03)

--                 SetTextScale(0.32, 0.32)
--                 SetTextColour(180, 240, 180, 220)
--                 SetTextEntry("STRING")
--                 AddTextComponentString(string.format("Selected: %s   X=%.4f  Y=%.4f  Z=%.4f", selected, adjustments[selected].x, adjustments[selected].y, adjustments[selected].z))
--                 DrawText(0.02, baseY + 0.06)

--                 -- Play scene with current adjustments
--                 if IsDisabledControlJustPressed(0, 38) and not scenePlaying then -- E
--                     scenePlaying = true
--                     lib.requestModel(playerModel)
--                     local scenePed = CreatePed(4, playerModel, hitCoords.x, hitCoords.y, hitCoords.z, heading, true, true)
--                     SetEntityInvincible(scenePed, true)
--                     SetBlockingOfNonTemporaryEvents(scenePed, true)

--                     while not NetworkHasControlOfEntity(scenePed) do
--                         NetworkRequestControlOfEntity(scenePed)
--                         Wait(0)
--                     end

--                     SetEntityVisible(previewPed, false, false)

--                     CreateThread(function()
--                         playHackScene(scenePed, vector4(hitCoords.x, hitCoords.y, hitCoords.z, heading), true, adjustments)
--                         DeleteEntity(scenePed)
--                         SetEntityVisible(previewPed, true, false)
--                         scenePlaying = false
--                         TriggerEvent('chat:addMessage', { args = { "^2[DEV]", "Scene selesai." } })
--                     end)
--                 end

--                 -- LEFT CLICK: copy adjustments to clipboard as Lua table
--                 if IsDisabledControlJustPressed(0, 24) and not scenePlaying then
--                     local s = string.format("{ enter = { x=%.4f, y=%.4f, z=%.4f }, loop = { x=%.4f, y=%.4f, z=%.4f }, exit = { x=%.4f, y=%.4f, z=%.4f } }",
--                         adjustments.enter.x, adjustments.enter.y, adjustments.enter.z,
--                         adjustments.loop.x, adjustments.loop.y, adjustments.loop.z,
--                         adjustments.exit.x, adjustments.exit.y, adjustments.exit.z
--                     )
--                     lib.setClipboard(s)
--                     TriggerEvent('chat:addMessage', { args = { "^2[DEV] Copied offsets:", s } })
--                     placementActive = false
--                     break
--                 end
--             end

--             if IsControlJustPressed(0, 177) and not scenePlaying then -- BACKSPACE cancel
--                 placementActive = false
--                 break
--             end

--             DisableAllControlActions(0)
--             EnableControlAction(0, 1,   true)
--             EnableControlAction(0, 2,   true)
--             EnableControlAction(0, 24,  true)
--             EnableControlAction(0, 38,  true)
--             EnableControlAction(0, 177, true)
--             EnableControlAction(0, 15,  true)
--             EnableControlAction(0, 16,  true)
--             EnableControlAction(0, 30,  true)
--             EnableControlAction(0, 31,  true)
--             EnableControlAction(0, 21,  true)
--             EnableControlAction(0, 36,  true)
--             Wait(0)
--         end

--         while scenePlaying do Wait(100) end

--         DeleteEntity(previewPed)
--         clearDevEntities()
--     end)
-- end, false)

-- RegisterCommand('placescene', function()
--     if placementActive then return end
--     placementActive = true

--     TriggerEvent('chat:addMessage', { args = { "^3[DEV]", "[KLIK KIRI] copy coords. [E] play scene. [SCROLL] heading. [BACKSPACE] batal." } })

--     CreateThread(function()
--         local playerPed   = cache.ped
--         local playerModel = GetEntityModel(playerPed)
--         local startCoords = GetEntityCoords(playerPed)

--         lib.requestModel(playerModel)
--         local previewPed = CreatePed(4, playerModel, startCoords.x, startCoords.y, startCoords.z, 0.0, false, false)
--         SetEntityAlpha(previewPed, 180, false)
--         SetEntityCollision(previewPed, false, false)
--         FreezeEntityPosition(previewPed, true)
--         SetEntityInvincible(previewPed, true)
--         SetBlockingOfNonTemporaryEvents(previewPed, true)

--         local heading = GetEntityHeading(playerPed)
--         local rotateSpeed = 3.0
--         local scenePlaying = false

--         while placementActive do
--             local hit, _, hitCoords = lib.raycast.cam(1 + 16, 4, 20)

--             if hit then

--                 -- Hanya update posisi preview jika scene TIDAK sedang jalan
--                 if not scenePlaying then
--                     SetEntityCoords(previewPed, hitCoords.x, hitCoords.y, hitCoords.z, false, false, false, false)
--                     SetEntityHeading(previewPed, heading)
--                 end

--                 -- Scroll untuk rotasi heading
--                 if IsDisabledControlPressed(0, 15) then
--                     heading = (heading + rotateSpeed) % 360.0
--                 end
--                 if IsDisabledControlPressed(0, 16) then
--                     heading = (heading - rotateSpeed) % 360.0
--                 end

--                 -- HUD
--                 local displayCoords = scenePlaying and GetEntityCoords(previewPed) or hitCoords
--                 local txt = string.format("vector4(%.4f, %.4f, %.4f, %.4f)%s",
--                     displayCoords.x, displayCoords.y, displayCoords.z, heading,
--                     scenePlaying and "  ^1[PLAYING]" or ""
--                 )
--                 SetTextFont(0)
--                 SetTextScale(0.35, 0.35)
--                 SetTextColour(255, 255, 0, 220)
--                 SetTextEntry("STRING")
--                 AddTextComponentString(txt)
--                 DrawText(0.25, 0.93)

--                 -- [E] Play scene di posisi saat ini
--                 if IsDisabledControlJustPressed(0, 38) and not scenePlaying then
--                     scenePlaying = true
--                     local sceneCoords = vector4(hitCoords.x, hitCoords.y, hitCoords.z, heading)

--                     -- Buat ped baru khusus scene (networked agar sync scene jalan)
--                     lib.requestModel(playerModel)
--                     local scenePed = CreatePed(4, playerModel, sceneCoords.x, sceneCoords.y, sceneCoords.z, sceneCoords.w, true, true)
--                     SetEntityInvincible(scenePed, true)
--                     SetBlockingOfNonTemporaryEvents(scenePed, true)

--                     while not NetworkHasControlOfEntity(scenePed) do
--                         NetworkRequestControlOfEntity(scenePed)
--                         Wait(0)
--                     end

--                     -- Sembunyikan preview, tampilkan scene ped
--                     SetEntityVisible(previewPed, false, false)

--                     CreateThread(function()
--                         playHackScene(scenePed, sceneCoords, true)
--                         DeleteEntity(scenePed)
--                         SetEntityVisible(previewPed, true, false)
--                         scenePlaying = false
--                         TriggerEvent('chat:addMessage', { args = { "^2[DEV]", "Scene selesai. Lanjut placement." } })
--                     end)
--                 end

--                 -- [KLIK KIRI] Confirm + copy coords
--                 if IsDisabledControlJustPressed(0, 24) and not scenePlaying then
--                     local coordsStr = string.format("vector4(%.4f, %.4f, %.4f, %.4f)", hitCoords.x, hitCoords.y, hitCoords.z, heading)
--                     lib.setClipboard(coordsStr)
--                     TriggerEvent('chat:addMessage', { args = { "^2[DEV] Copied:", coordsStr } })
--                     print("[DEV] " .. coordsStr)
--                     placementActive = false
--                     break
--                 end
--             end

--             -- Batal
--             if IsControlJustPressed(0, 177) and not scenePlaying then
--                 placementActive = false
--                 break
--             end

--             DisableAllControlActions(0)
--             EnableControlAction(0, 1,   true) -- look LR
--             EnableControlAction(0, 2,   true) -- look UD
--             EnableControlAction(0, 24,  true) -- attack (confirm)
--             EnableControlAction(0, 38,  true) -- E (play scene)
--             EnableControlAction(0, 177, true) -- backspace
--             EnableControlAction(0, 15,  true) -- scroll up
--             EnableControlAction(0, 16,  true) -- scroll down
--             EnableControlAction(0, 30,  true) -- move LR (A/D)
--             EnableControlAction(0, 31,  true) -- move FB (W/S)
--             EnableControlAction(0, 21,  true) -- sprint (shift)
--             EnableControlAction(0, 36,  true) -- stealth (ctrl)
--             Wait(0)
--         end

--         -- Tunggu scene selesai sebelum cleanup
--         while scenePlaying do Wait(100) end

--         DeleteEntity(previewPed)
--         clearDevEntities()
--         placementActive = false
--     end)
-- end, false)

-- AddEventHandler('onResourceStop', function(resource)
--     if resource == GetCurrentResourceName() then
--         clearDevEntities()
--     end
-- end)
