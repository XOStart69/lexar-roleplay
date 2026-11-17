local sconfig = require 'interface.idcard.config.shared'

local metadataKeyMap = {
    ktp = 'ktpdata',
    kia = 'kiadata',
    weaponlicense = { key = 'licences', subkey = 'weapon' },
    -- driver_license_a = { key = 'licences', subkey = 'driver_a' },
    -- driver_license_c = { key = 'licences', subkey = 'driver_c' },
    helicopter_license = { key = 'licences', subkey = 'helicopter' },
    huntinglicense = { key = 'licences', subkey = 'hunting' },
    kartu_kesehatan = 'health_card',
    kta_mechanic = { key = 'kta_data', subkey = 'mechanic' },
    kta_pabrik = { key = 'kta_data', subkey = 'pabrik' },
    kta_reporter = { key = 'kta_data', subkey = 'reporter' },
    kta_taxi = { key = 'kta_data', subkey = 'taxi' },
    kta_police = { key = 'kta_data', subkey = 'police' },
    kta_ambulance = { key = 'kta_data', subkey = 'ambulance' },
    kta_government = { key = 'kta_data', subkey = 'government' },
}

local fieldMappings = {
    ktp = {
        { oldKey = 'nik', id = 'card_id', label = 'NIK' },
        { id = 'spacer_1', kind = 'spacer' },
        { oldKey = 'nama', id = 'name', label = 'Nama Lengkap' },
        { oldKey = 'ttl', id = 'ttl', label = 'Tempat / Tgl Lahir' },
        { oldKey = 'gender', id = 'gender', label = 'Jenis Kelamin' },
        { oldKey = 'golongandarah', id = 'bloodType', label = 'Golongan Darah' },
        { oldKey = 'expires', id = 'expired', label = 'Berlaku Hingga' },
    },
    kia = {
        { oldKey = 'nik', id = 'card_id', label = 'NIK' },
        { id = 'spacer_1', kind = 'spacer' },
        { oldKey = 'nama', id = 'name', label = 'Nama Lengkap' },
        { oldKey = 'ttl', id = 'ttl', label = 'Tempat / Tgl Lahir' },
        { oldKey = 'gender', id = 'gender', label = 'Jenis Kelamin' },
        { oldKey = 'nationality', id = 'citizenship', label = 'Kewarganegaraan' },
        { oldKey = 'issued_date', id = 'createdate', label = 'Dikeluarkan' },
        { oldKey = 'expires', id = 'expired', label = 'Berlaku Hingga' },
        { oldKey = 'issued_by', id = 'createdby', label = 'Diterbitkan Oleh' },
    },
    license = {
        { oldKey = 'citizenid', id = 'card_id', label = 'License No' },
        { id = 'spacer_1', kind = 'spacer' },
        { fromPlayer = 'name', id = 'name', label = 'Nama' },
        { fromPlayer = 'dob', id = 'tanggal_lahir', label = 'Tanggal Lahir' },
        { fromPlayer = 'citizenship', id = 'kewarganegaraan', label = 'Kewarganegaraan' },
        { oldKey = 'issued_date', id = 'createdate', label = 'Dikeluarkan' },
        { oldKey = 'expires', id = 'expired', label = 'Berlaku hingga' },
        { oldKey = 'issued_by', id = 'createdby', label = 'Diterbitkan Oleh' },
    },
    health_card = {
        { oldKey = 'citizenid', id = 'card_id', label = 'Card No' },
        { fromPlayer = 'name', id = 'name', label = 'Nama' },
        { fromPlayer = 'dob', id = 'ttl', label = 'Tanggal Lahir' },
        { fromPlayer = 'bloodType', id = 'bloodType', label = 'Golongan Darah' },
        { fromPlayer = 'citizenship', id = 'citizenship', label = 'Kewarganegaraan' },
        { oldKey = 'issued_date', id = 'createdate', label = 'Dibuat' },
        { oldKey = 'expires', id = 'expired', label = 'Expired' },
        { oldKey = 'medical_notes', id = 'medic_notes', label = 'Medic Note' },
        { oldKey = 'issued_by', id = 'createdby', label = 'Dibuat oleh' },
    },
    kta = {
        { oldKey = 'employee_id', id = 'id_karyawan', label = 'ID Karyawan' },
        { id = 'spacer_1', kind = 'spacer' },
        { fromPlayer = 'name', id = 'name', label = 'Nama' },
        { fromPlayer = 'jobtitle', id = 'jobtitle', label = 'Jabatan' },
        { fromPlayer = 'dob', id = 'tanggal_lahir', label = 'Tanggal Lahir' },
        { fromPlayer = 'citizenship', id = 'kewarganegaraan', label = 'Kewarganegaraan' },
        { oldKey = 'issued_date', id = 'createdate', label = 'Dikeluarkan' },
        { oldKey = 'expires', id = 'expired', label = 'Berlaku hingga' },
        { oldKey = 'issued_by', id = 'createdby', label = 'Diterbitkan Oleh' },
    },
}

local function getOldData(playermeta, itemName)
    if not playermeta then
        return nil
    end

    local mapping = metadataKeyMap[itemName]

    if not mapping then
        return nil
    end

    if type(mapping) == 'string' then
        return playermeta[mapping]
    end

    if type(mapping) == 'table' then
        local parentData = playermeta[mapping.key]

        if parentData and mapping.subkey then
            return parentData[mapping.subkey]
        end

        return parentData
    end

    return nil
end

local function removeOldData(source, itemName)
    local player = qb_ecore:GetPlayer(source)
    local playermeta = player and player.PlayerData.metadata
    if not playermeta then
        return
    end

    local mapping = metadataKeyMap[itemName]

    if not mapping then
        return
    end

    if type(mapping) == 'string' and playermeta[mapping] then
        qb_ecore:SetMetaData(source, mapping, nil)
    end

    if type(mapping) == 'table' then
        local parentData = playermeta[mapping.key]

        if parentData and mapping.subkey then
            parentData[mapping.subkey] = nil
        end

        qb_ecore:SetMetaData(source, mapping.key, parentData)
    end
end

local function getFieldMapping(itemName)
    if itemName == 'ktp' then
        return fieldMappings.ktp
    end

    if itemName == 'kia' then
        return fieldMappings.kia
    end

    if itemName == 'weaponlicense' or itemName == 'driver_license_a' or
       itemName == 'driver_license_c' or itemName == 'helicopter_license' or
       itemName == 'huntinglicense' then
        return fieldMappings.license
    end

    if itemName == 'kartu_kesehatan' then
        return fieldMappings.health_card
    end

    if itemName:match('^kta_') then
        return fieldMappings.kta
    end

    return nil
end

local function getPlayerData(source)
    local player = qb_ecore:GetPlayer(source)
    if not player then return nil end

    local playerData = player.PlayerData
    local charinfo = playerData.charinfo
    local metadata = playerData.metadata

    return {
        name = ('%s %s'):format(charinfo.firstname, charinfo.lastname),
        dob = charinfo.birthdate,
        ttl = ('Los Santos, %s'):format(charinfo.birthdate),
        gender = charinfo.gender == 1 and 'Perempuan' or 'Laki-laki',
        bloodType = metadata.bloodtype or '-',
        citizenship = charinfo.nationality or 'WNI',
        jobtitle = playerData.job.grade.name,
        citizenid = playerData.citizenid,
    }
end

local function convertToMetadata(source, item)
    local itemName = item.name

    local player = qb_ecore:GetPlayer(source)
    local playermeta = player and player.PlayerData.metadata
    local old_data = getOldData(playermeta, itemName)

    if not old_data then
        return
    end

    local template = sconfig.template[itemName]
    if not template then
        return lib.notify(source, {
            description = 'Template kartu tidak ditemukan!',
            type = 'error',
            duration = 8000
        })
    end

    local playerData = getPlayerData(source)

    local new_data = {
        config = template.config,
        fields = {},
        location = 'Unknown'
    }

    local mapping = getFieldMapping(itemName)

    if mapping then
        for _, field in ipairs(mapping) do
            local fieldEntry = {
                kind = field.kind or 'data',
                id = field.id,
                label = field.label
            }

            if field.kind ~= 'spacer' then
                if field.oldKey then
                    local value = old_data[field.oldKey]
                    if value then
                        fieldEntry.value = value
                    end
                end

                if field.fromPlayer and playerData then
                    local value = playerData[field.fromPlayer]
                    if value then
                        fieldEntry.value = value
                    end
                end
            end

            new_data.fields[#new_data.fields + 1] = fieldEntry
        end
    end

    if old_data.fotourl then
        ---@diagnostic disable-next-line: inject-field
        new_data.config.profileImage = old_data.fotourl
    end

    removeOldData(source, itemName)

    return {
        cards = new_data,
        citizenid = playerData?.citizenid
    }
end

lib.addCommand('buatkartulama', {
    help = 'Buat semua kartu untuk player (Admin)',
    params = {{ name = 'id', type = 'number', optional = true }},
    restricted = 'group.admin'
}, function(source, args)
    local targetId = args.id or source
    local Player = qb_ecore:GetPlayer(targetId)
    if not Player then
        return lib.notify(source, { description = "Player tidak ditemukan", type = 'error' })
    end

    local char = Player.PlayerData.charinfo
    local citizenid = Player.PlayerData.citizenid
    local name = char.firstname .. ' ' .. char.lastname
    local today = os.date("%Y-%m-%d")
        
    local base = {
        citizenid = citizenid, nik = citizenid, nama = name,
        ttl = 'LOS SANTOS, ' .. char.birthdate,
        gender = char.gender == 0 and 'LAKI-LAKI' or 'PEREMPUAN',
        fotourl = "https://r2.fivemanage.com/image/f4VrakSkr3gP.png",
        birthdate = char.birthdate,
        expires = os.date("%Y-%m-%d", os.time() + 365 * 24 * 60 * 60),
        nationality = char.nationality or "WNI",
        issued_date = today,
        issued_by = "ADMIN SYSTEM",
        golongandarah = Player.PlayerData.metadata.bloodtype or "O+",
        medical_notes = "SEHAT"
    }

    local metadata = Player.PlayerData.metadata
    local created, failed, idx = 0, 0, 0

    for item, mapping in pairs(metadataKeyMap) do
        idx = idx + 1
        local data = lib.table.deepclone(base)

        if type(mapping) == 'table' then
            data.type = mapping.subkey
            data.jobType = mapping.subkey
            data.employee_id = ("EMP-%03d"):format(idx * 100 + targetId)
            metadata[mapping.key] = metadata[mapping.key] or {}
            metadata[mapping.key][mapping.subkey] = data
        else
            metadata[mapping] = data
        end

        if exports.ox_inventory:AddItem(targetId, item, 1) then
            created = created + 1
        else
            failed = failed + 1
        end
    end

    for key in pairs({ ktpdata = 1, kiadata = 1, health_card = 1, licences = 1, kta_data = 1 }) do
        if metadata[key] then qb_ecore:SetMetaData(targetId, key, metadata[key]) end
    end

    lib.notify(source, { description = ("Dibuat %d kartu untuk %s%s"):format(created, name, failed > 0 and (" (%d gagal)"):format(failed) or ""), type = 'success' })
    if targetId ~= source then
        lib.notify(targetId, { description = "Admin membuat semua kartu untuk Anda!", type = 'success' })
    end
end)

return convertToMetadata