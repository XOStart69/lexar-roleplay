-- Rekonstruksi sm_core/server/player/method.lua (qb-core compatible)

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

---Wrapper yang aman dikirim lintas resource (fungsi jadi function reference).
---@param player table
---@return table
function PreparePlayerTable(player)
    return { PlayerData = player.PlayerData, Functions = player.Functions, Offline = player.Offline }
end

---@param self table
function SetupPlayerMethods(self)
    local fn = self.Functions

    -- kirim satu key (atau semua) ke client. Client: event QBCore:Player:setPData
    local function sync(key, val, subVal)
        if self.Offline then return end
        local src = self.PlayerData.source
        if key == nil then
            TriggerEvent('QBCore:Player:SetPlayerData', self.PlayerData)
            TriggerClientEvent('QBCore:Player:setPData', src, 'all', self.PlayerData)
        elseif subVal ~= nil then
            TriggerClientEvent('QBCore:Player:setPData', src, key, val, subVal)
        else
            TriggerClientEvent('QBCore:Player:setPData', src, key, val)
        end
    end

    function fn.UpdatePlayerData()
        sync()
    end

    function fn.SetPlayerData(key, val)
        if type(key) ~= 'string' then return end
        self.PlayerData[key] = val
        sync(key, val)
    end

    ---------------------------------------------------------------- metadata
    function fn.SetMetaData(meta, val)
        if type(meta) ~= 'string' then return end

        if (meta == 'hunger' or meta == 'thirst' or meta == 'stress') and type(val) == 'number' then
            val = clamp(val, 0, 100)
        end

        self.PlayerData.metadata[meta] = val

        if val == nil then
            sync('metadata', self.PlayerData.metadata)
        else
            sync('metadata', meta, val)
        end

        if meta == 'inlaststand' or meta == 'isdead' then
            fn.Save()
        end
    end

    function fn.GetMetaData(meta)
        if meta == nil then return self.PlayerData.metadata end
        return self.PlayerData.metadata[meta]
    end

    ---------------------------------------------------------------- job / gang
    function fn.SetJob(job, grade)
        if not job then return false end
        local built = QBCore.Player.BuildJob(tostring(job), grade or 0)
        if not built then return false end

        self.PlayerData.job = built
        if not self.Offline then
            local src = self.PlayerData.source
            sync('job', built)
            TriggerEvent('QBCore:Server:OnJobUpdate', src, built)
            TriggerClientEvent('QBCore:Client:OnJobUpdate', src, built)
        end
        return true
    end

    function fn.SetGang(gang, grade)
        if not gang then return false end
        local built = QBCore.Player.BuildGang(tostring(gang), grade or 0)
        if not built then return false end

        self.PlayerData.gang = built
        if not self.Offline then
            local src = self.PlayerData.source
            sync('gang', built)
            TriggerEvent('QBCore:Server:OnGangUpdate', src, built)
            TriggerClientEvent('QBCore:Client:OnGangUpdate', src, built)
        end
        return true
    end

    function fn.SetJobDuty(onDuty)
        self.PlayerData.job.onduty = onDuty and true or false
        if not self.Offline then
            local src = self.PlayerData.source
            sync('job', self.PlayerData.job)
            TriggerEvent('QBCore:Server:SetDuty', src, self.PlayerData.job.onduty)
            TriggerClientEvent('QBCore:Client:SetDuty', src, self.PlayerData.job.onduty)
        end
    end

    ---------------------------------------------------------------- money
    local function moneyEvents(moneytype, amount, action, reason, hudNegative)
        if self.Offline then return end
        local src = self.PlayerData.source
        sync('money', self.PlayerData.money)
        TriggerClientEvent('hud:client:OnMoneyChange', src, moneytype, amount, hudNegative)
        TriggerClientEvent('QBCore:Client:OnMoneyChange', src, moneytype, amount, action, reason)
        TriggerEvent('QBCore:Server:OnMoneyChange', src, moneytype, amount, action, reason)
    end

    function fn.GetMoney(moneytype)
        moneytype = tostring(moneytype or ''):lower()
        return self.PlayerData.money[moneytype] or false
    end

    function fn.AddMoney(moneytype, amount, reason)
        reason = reason or 'unknown'
        moneytype = tostring(moneytype or ''):lower()
        amount = tonumber(amount)
        if not amount or amount < 0 then return false end
        if self.PlayerData.money[moneytype] == nil then return false end

        self.PlayerData.money[moneytype] += amount
        moneyEvents(moneytype, amount, 'add', reason, false)
        return true
    end

    function fn.RemoveMoney(moneytype, amount, reason)
        reason = reason or 'unknown'
        moneytype = tostring(moneytype or ''):lower()
        amount = tonumber(amount)
        if not amount or amount < 0 then return false end
        local balance = self.PlayerData.money[moneytype]
        if balance == nil then return false end

        for _, noMinus in pairs(QBConfig.Money.DontAllowMinus) do
            if noMinus == moneytype and balance - amount < 0 then return false end
        end
        if balance - amount < QBConfig.Money.MinusLimit then return false end

        self.PlayerData.money[moneytype] = balance - amount
        moneyEvents(moneytype, amount, 'remove', reason, true)
        return true
    end

    function fn.SetMoney(moneytype, amount, reason)
        reason = reason or 'unknown'
        moneytype = tostring(moneytype or ''):lower()
        amount = tonumber(amount)
        if not amount or amount < 0 then return false end
        local old = self.PlayerData.money[moneytype]
        if old == nil then return false end

        self.PlayerData.money[moneytype] = amount
        local difference = amount - old
        moneyEvents(moneytype, math.abs(difference), 'set', reason, difference < 0)
        return true
    end

    ---------------------------------------------------------------- inventory (ox_inventory)
    -- Pemetaan ini ASUMSI standar ox_inventory; sesuaikan jika resource sm_* memakai API lain.
    function fn.AddItem(item, amount, slot, info)
        return exports.ox_inventory:AddItem(self.PlayerData.source, item, amount or 1, info, slot)
    end

    function fn.RemoveItem(item, amount, slot, info)
        return exports.ox_inventory:RemoveItem(self.PlayerData.source, item, amount or 1, info, slot)
    end

    function fn.GetItemByName(item)
        return exports.ox_inventory:GetItem(self.PlayerData.source, item, nil, false)
    end

    function fn.GetItemsByName(item)
        return exports.ox_inventory:Search(self.PlayerData.source, 'slots', item)
    end

    function fn.ClearInventory(keep)
        return exports.ox_inventory:ClearInventory(self.PlayerData.source, keep)
    end

    ---------------------------------------------------------------- lifecycle
    function fn.Save()
        if self.Offline then
            QBCore.Player.SaveOffline(self.PlayerData)
        else
            QBCore.Player.Save(self.PlayerData.source)
        end
    end

    function fn.Logout()
        if self.Offline then return end
        QBCore.Player.Logout(self.PlayerData.source)
    end

    function fn.AddMethod(methodName, handler)
        fn[methodName] = handler
    end

    function fn.AddField(fieldName, data)
        self[fieldName] = data
    end
end
