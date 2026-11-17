---@class CustomSlot: SlotConfig
---@field model? string
---@field slotId? string

---@alias Itemname string
---@alias ItemSlot string|CustomSlot

---@type table<Itemname, ItemSlot>
return {
-- Pistol slot
    weapon_glock18c = 'pistol',
    weapon_navyrevolver = 'pistol',
    weapon_microsmg = 'pistol',
    weapon_deagle = 'pistol',
    weapon_marksmanpistol = 'pistol',
    weapon_revolver_mk2 = 'pistol',
    weapon_pistol = 'pistol',
    weapon_pdfc66 = 'pistol',
    weapon_pdt22 = 'pistol',
    weapon_pdmkusp = 'pistol',
    weapon_pdmk45 = 'pistol',
    weapon_pdt19 = 'pistol',
    weapon_falcon57 = 'pistol',
    weapon_revolver = 'pistol',
    weapon_flaregun = 'pistol',
    weapon_buckrevolver = 'pistol',
    weapon_minirevolversm = 'pistol',
    weapon_deaglesm = 'pistol',
    weapon_g20va5 = 'pistol',
    weapon_glockbeams = 'pistol',
    weapon_fnxmw = 'pistol',
    weapon_glock18csm = 'pistol',

    -- Rifle slot
    weapon_hntrifle = 'rifle',
    weapon_ak47 = 'rifle',
    weapon_thompson = 'rifle',
    weapon_minismg = 'rifle',
    weapon_heavysniper = 'rifle',
    weapon_heavyrifle = 'rifle',
    weapon_assaultrifle_mk2 = 'rifle',
    weapon_woarp = 'rifle',
    weapon_carbinerifle_mk2 = 'rifle',
    weapon_redm4a1 = 'rifle',
    weapon_carbinerifle = 'rifle',
    weapon_smg = 'rifle',
    weapon_p90sm = 'rifle',
    weapon_m6ic = 'rifle',
    -- weapon_r20rahe = 'rifle',
    weapon_sigmxcvirtus = 'rifle',
    weapon_pddt607 = 'rifle',
    weapon_pddt7 = 'rifle',
    weapon_pdpt870 = 'rifle',
    weapon_pdpt700 = 'rifle',
    weapon_mk417 = 'rifle',
    weapon_pdmk33 = 'rifle',
    weapon_pdbr5 = 'rifle',
    weapon_combatpdw = 'rifle',
    weapon_assaultsmg = 'rifle',
    weapon_bar15 = 'rifle',
    weapon_dmk18 = 'rifle',
    weapon_militaryrifle = 'rifle',
    weapon_combatmg = 'rifle',
    weapon_ak74sm = 'rifle',
    -- weapon_m4a1smm = 'rifle',
    weapon_akstocksm = 'rifle',
    -- weapon_m4magsm = 'rifle',
    -- weapon_saigrysm = 'rifle',
    weapon_bruggersm = 'rifle',
    weapon_skorpiosm = 'rifle',
    weapon_hkmp7sm = 'rifle',
    weapon_dracosm = 'rifle',
    weapon_berettapol = 'rifle',
    weapon_srht = 'rifle',
    weapon_berylmw = 'rifle',
    weapon_ks1army = 'rifle',

    --new
    weapon_pdglock43 = 'pistol',
    weapon_pd357magnum = 'pistol',
    weapon_pdmp9 = 'rifle',
    weapon_pdsigmpx = 'rifle',
    weapon_mk18md1 = 'rifle',
    weapon_pdak104 = 'rifle',
    weapon_pdg36 = 'rifle',
    weapon_pdcqr15 = 'rifle',
    weapon_pdbryson800 = 'rifle',
    weapon_krissvector = 'rifle',
    weapon_pdmcxspear = 'rifle',
    weapon_pdm4a1 = 'rifle',
    weapon_pdmk16 = 'rifle',
    weapon_pdm3super90 = 'rifle',
    weapon_pumpshotgun = 'rifle',
    weapon_spht = 'rifle',

    weapon_ar15c = 'rifle',
    weapon_arpism = 'rifle',
    weapon_mac11sm = 'rifle',
    weapon_hbra3 = 'rifle',

    -- ini prop attach
    fishing_rod_redcrab = {
        model = 'nkprop_fishing_rod_redcrab',
        slotId = 'fishing_rod'
    },
    fishing_rod_greencrocodile = {
        model = 'nkprop_fishing_rod_greencrocodile',
        slotId = 'fishing_rod'
    },
    fishing_rod_pinkshark = {
        model = 'nkprop_fishing_rod_pinkshark',
        slotId = 'fishing_rod'
    },
    fishing_rod_yellowseahorse = {
        model = 'nkprop_fishing_rod_yellowseahorse',
        slotId = 'fishing_rod'
    },
    fishing_rod_normal = {
        model = 'prop_fishing_rod_01',
        slotId = 'fishing_rod'
    },
    fishing_rod_sport = {
        model = 'prop_fishing_rod_02',
        slotId = 'fishing_rod'
    },
    fishing_rod_advanced = {
        model = 'prop_fishing_rod_03',
        slotId = 'fishing_rod'
    },
    fishing_rod_super = {
        model = 'prop_fishing_rod_04',
        slotId = 'fishing_rod'
    },
    meth = { 
        model = 'prop_meth_bag_01',
        slotId = 'meth_props'
    },
    joint = { 
        model = 'sf_prop_sf_bag_weed_01b',
        slotId = 'joint_props'
    },
    cocaine = { 
        model = 'prop_meth_bag_01',
        slotId = 'cocaine_props'
    },
    packaged_meth = { 
        model = 'prop_meth_bag_01',
        slotId = 'meth_props'
    },
    packaged_ganja = { 
        model = 'sf_prop_sf_bag_weed_01b',
        slotId = 'joint_props'
    },
    packaged_cocaine = { 
        model = 'prop_meth_bag_01',
        slotId = 'cocaine_props'
    },
    weapon_heavysniper_mk2 ={
        boneId = 38,
        pos = vec(-0.09, -0.16, 0.03),
        rot = vec(0.00, -3.50, 0.20),
    },
    -- GACHA V1 WEAPONS
    weapon_butcher = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_scimitar = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_scifisword = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_scythe = { -- reaper/tongkat panjang
        pos = vec(-0.28, -0.15, -0.24),
        rot = vec(0.00, 48.95, 0.0),
        boneIndex = 24818
    },
    weapon_twohbattleaxe = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pepperspray = { -- spray gun
        boneId = 35,
        pos = vec(0.07, -0.15, 0.09),
        rot = vec(0.00, 96.00, 0.20),
    },
    weapon_acidspray = { -- spray gun
        boneId = 35,
        pos = vec(0.07, -0.15, 0.09),
        rot = vec(0.00, 96.00, 0.20),
    },
    weapon_barbedbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_bat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_kitchenknife = {
        boneId = 36,
        pos = vec(0.04, -0.17, 0.11),
        rot = vec(0.00, 182.00, 0.20),
    },
    weapon_taccleaver = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_eguitar = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_guitar = { -- tongkat panjang
        boneId = 38,
        pos = vec(0.88, -0.20, -0.03),
        rot = vec(0.00, -89.50, 0.20),
    },
    weapon_pitchfork = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_tacaxe = { -- pisau pendek
        boneId = 38,
        pos = vec(-0.19, -0.15, 0.09),
        rot = vec(0.00, 121.50, 0.20),
    },
    weapon_wclaws = { -- pisau pendek
        boneId = 14,
        pos = vec(0.14, -0.06, 0.09),
        rot = vec(-177.00, -107.00, -1888.80),
    },
    weapon_scissors = {
        boneId = 36,
        pos = vec(0.01, -0.16, -0.14),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_pickaxe = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_screwdriver = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_dildo = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_candycane = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_poolcue = { -- tongkat Panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_hunterknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.00, -0.13, -0.12),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_iceclimber = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_mace = { -- tongkat panjang
        boneId = 38,
        pos = vec(0.34, -0.20, -0.14),
        rot = vec(0.00, -55.00, 0.20),
    },
    weapon_shovel = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_spikedknuckles = {
        boneId = 35,
        pos = vec(0.08, -0.17, -0.14),
        rot = vec(1.50, 5.00, 92.70),
    },
    weapon_crutch = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_brownmachete = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_blackkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_kukri = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_stopsign = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_thorshammer = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_zk = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_redzk = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_bluezk = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_pinkzk = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_spikeybat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_katana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_longmachete = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_tacticalhatchet = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_fireworksingle = {    
        boneId = 36,    
        pos = vec(0.05, -0.19, 0.08),    
        rot = vec(80.50, 17.00, -11.80),
    },
    weapon_spraypaint = { -- spray gun
        boneId = 35,
        pos = vec(0.07, -0.15, 0.09),
        rot = vec(0.00, 96.00, 0.20),
    },

    -- GACHA V2 WEAPONS
    weapon_boltcutter = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.21, -0.17, -0.16),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_plunger = {
        boneId = 98,
        pos = vec(0.57, 0.00, 0.00),
        rot = vec(0.00, -90.00, 0.20),
    },
    weapon_walkingstick = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_skateboard = { -- tongkat panjang
        boneId = 38,
        pos = vec(0.25, -0.10, 0.08),
        rot = vec(86.00, -24.50, -52.30),
    },
    weapon_pimpcane = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pipewrench = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_stool = {
        boneId = 37,
        pos = vec(-0.16, -0.10, 0.17),
        rot = vec(0.00, 97.00, -7.30),
    },
    weapon_chainknuckle = {
        boneId = 36,
        pos = vec(-0.05, 0.14, 0.02),
        rot = vec(173.50, 6.00, -11.30),
    },
    weapon_robotgauntlet = { -- pisau pendek
        boneId = 14,
        pos = vec(0.14, -0.06, 0.09),
        rot = vec(-177.00, -107.00, -1888.80),
    },
    weapon_bbsword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_halberd = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_redsaber = {
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_bluesaber = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_pinksaber = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_lightbluesaber = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_whitesaber = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_greensaber = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_purplesaber = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_yellowsaber = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_cobbsbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_broom = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_warhammer = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_zkvtwo = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_glassshank = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_scalpel = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_cricketbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.29, -0.20, -0.10),
        rot = vec(-72.50, 40.50, -43.80),
    },
    weapon_spikedcricketbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.37, -0.24, -0.19),
        rot = vec(56.00, 41.00, 51.70),
    },
    weapon_poolstick = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_rubberchicken = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_boxcutter = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_toothbrushshank = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_razorblade = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_redkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_maulsaber = {
        boneId = 35,
        pos = vec(0.28, -0.15, -0.07),
        rot = vec(0.00, 50.50, 0.20),
    },
    weapon_tennisracket = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_devilsfork = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.13, -0.16, 0.08),
        rot = vec(-106.50, 48.00, -40.80),
    },
    weapon_elsword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_longsword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.41, -0.16, 0.18),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_katar = { -- pisau pendek
            boneId = 36,
            pos = vec(-0.00, -0.13, -0.06),
            rot = vec(-46.20, -15.20, -97.00),
    },
    weapon_drill = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_spanner = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_chainsawsword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_surgicalsaw = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_saw = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_barbell = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_dumbell = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_nailgun = { -- spray gun
        boneId = 35,
        pos = vec(0.07, -0.15, 0.09),
        rot = vec(0.00, 96.00, 0.20),
    },
    weapon_flamethrower = { -- flamethrow
        boneId = 37,
        pos = vec(0.00, -0.16, 0.00),
        rot = vec(0.00, 1.00, 0.20),
    },

    -- GACHA V3 WEAPONS
    weapon_dirtysyringe = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_peeler = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_ruler = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_donotentersign = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_bigspoon = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_jabsaw = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_telescope = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_meatskewer = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_swordfish = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_lobster = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_pliers = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_handdrill = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_twistedspear = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_snakeknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_crutchknife = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_sharparrow = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_95sign = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_assasingun = { -- spray gun
        boneId = 35,
        pos = vec(0.07, -0.15, 0.09),
        rot = vec(0.00, 96.00, 0.20),
    },
    weapon_baguette = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_banana = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_bike = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_bone = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_buttplug = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_cactus = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_camshaft = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_carjack = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_cone = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_crossspanner = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_cucumber = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_disabledsign = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_elderswand = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_mfireextinguisher = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_fishingrod = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_gascylinder = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_hockeyfstick = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_horn = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_jdbottle = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_keyboard = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_kitchenfork = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_lacrossestick = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_ladder = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_mailbox = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_mic = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_noparkingsign = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pen = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_pencil = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_prosleg = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_rollingpin = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_ronabottle = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_route66sign = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_scooter = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_shockabsorber = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_spartansword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_spatula = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_stepladder = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_streetlight = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_toaster = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_wrongwaysign = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_yari = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_blackbelt = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_bentfork = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_blackbackpack = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_brchicken = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_doorbars = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_earbudblade = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_honeydipper = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_kettle = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_leatherbriefcase = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_makeshiftknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_measuringcup = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_moddednightstick = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_trayrack = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_poker = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_prisonkey = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_viobackpack = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_redbackpack = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_teapot = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_pristoi = {
        boneId = 35,
        pos = vec(-0.14, -0.13, -0.26),
        rot = vec(-77.50, 95.50, 8.20),
    },
    weapon_shiv = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },

    -- GACHA V4 WEAPONS (FEMALE/PINK THEMED)
    weapon_fcomb = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_fpickaxe = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_fspikebat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_fbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_fredheel = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_fpinkheel = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_fblackheel = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_chribag = { -- tongkat panjang
        boneId = 42,
        pos = vec(0.11, -0.01, 0.02),
        rot = vec(-123.20, 7.30, 0.20),
    },
    weapon_fknuckle = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_fhatchet = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_blossomkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_blossomknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_fslippers = {
        boneId = 36,
        pos = vec(0.03, -0.24, 0.06),
        rot = vec(39.50, 93.00, 38.70),
    },
    weapon_fzvtwo = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_fdualsword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.11, -0.18, -0.00),
        rot = vec(0.00, -143.00, 0.20),
    },
    weapon_vibrator = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_fteddy = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_fteddypink = {
        boneId = 36,
        pos = vec(-0.06, -0.20, 0.12),
        rot = vec(0.00, 80.00, 0.20),
    },
    weapon_pinkpillow = {
        boneId = 36,
        pos = vec(-0.01, -0.23, -0.32),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_whitepillow = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pinkpoolnoodle = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_blpurse = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_lipstick = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_roseknife = { -- pisau pendek
        boneId = 38,
        pos = vec(0.16, -0.14, 0.00),
        rot = vec(0.00, -134.50, 0.20),
    },
    weapon_candyknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_lollybat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pinklolly = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_hairbrush = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_steamiron = {
        boneId = 36,
        pos = vec(0.22, -0.16, -0.10),
        rot = vec(9.00, -85.00, 0.20),
    },
    weapon_butterlolly = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_hslolly = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_roundlolly = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_twirlpop = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_babyseat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_kittyaxe = { -- pisau pendek
        boneId = 38,
        pos = vec(-0.16, -0.18, -0.14),
        rot = vec(0.00, 56.00, 0.20),
    },
    weapon_pinkswitchblade = {
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_tweezers = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_babychairfood = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_fguitar = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_feguitar = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_weddingring = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_animedoll = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, 0.20),
        rot = vec(0.00, 65.50, 0.20),
    },
    weapon_blondedoll = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_brunettedoll = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_unicornhorn = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_kittbowyaxe = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_pinkchoker = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_spikedchoker = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_pinkkeyboard = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_weapon_fclosedumbrella = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_fumbrella = { -- tongkat panjang
        boneId = 38,
        pos = vec(0.00, -0.14, 0.00),
        rot = vec(0.00, 86.00, 0.20),
    },
    weapon_blowdryer = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_hairpin = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_flamingo = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_octopusdoll = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_bobsfishingnet = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_kettleball = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_mousedoll = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pinkcybersword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_dragondoll = { -- tongkat panjang
        boneId = 36,
        pos = vec(0.25, -0.21, -0.18),
        rot = vec(10.80, -118.80, -3.00),
    },
    weapon_pinkboltcutters = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.21, -0.17, -0.16),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_pinkfaxe = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_pinkfpickaxe = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pinkscrewdriver = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_tiara = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_pinkcutter = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_fscepter = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_mermaid = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_heartbag = { -- tongkat pendek
        boneId = 61,
        pos = vec(0.06, 0.03, 0.00),
        rot = vec(72.30, -11.10, 0.20),
    },
    weapon_golddigger = { -- tongkat panjang
        boneId = 38,
        pos = vec(0.19, -0.15, -0.04),
        rot = vec(-49.50, -53.50, 32.20),
    },
    weapon_pinkknightstick = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_marshstick = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pinkhandfan = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_radabag = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_luubag = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pinkpepperspray = { -- spray gun
        boneId = 35,
        pos = vec(0.07, -0.15, 0.09),
        rot = vec(0.00, 96.00, 0.20),
    },

    -- JPX CYBER SERIES
    weapon_jpx_cyber_glaive = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_cyber_guitar = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_cyber_staff = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_cyber_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },

    -- JPX HYPER SERIES
    weapon_jpx_hyper_gauntlet = { -- pisau pendek
        boneId = 14,
        pos = vec(0.14, -0.06, 0.09),
        rot = vec(-177.00, -107.00, -1888.80),
    },
    weapon_jpx_hyper_spear = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_hyper_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },

    -- JPX IRIS & VICTORY SERIES
    weapon_jpx_iris_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_victory_axe = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_jpx_victory_hammer = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_victory_spear = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_victory_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },

    -- JPX SAKURA SERIES
    weapon_jpx_sakura_axe = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_jpx_sakura_samurai = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_sakura_scythe = { -- reaper/tongkat panjang
        pos = vec(-0.28, -0.15, -0.24),
        rot = vec(0.00, 48.95, 0.0),
        boneIndex = 24818
    },
    weapon_jpx_sakura_shuriken = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_jpx_sakura_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_sakura_gauntlet = { -- pisau pendek
        boneId = 14,
        pos = vec(0.14, -0.06, 0.09),
        rot = vec(-177.00, -107.00, -1888.80),
    },
    weapon_jpx_sakura_staff = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_sakura_glaive = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_sakura_lance = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_sakura_rod = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_sakura_sword2 = { -- pedang panjang
        boneId = 38,
        pos = vec(0.42, -0.13, 0.12),
        rot = vec(-1.00, -99.00, 4.70),
    },
    weapon_jpx_sakura_gun = { -- spray gun
        boneId = 35,
        pos = vec(0.07, -0.15, 0.09),
        rot = vec(0.00, 96.00, 0.20),
    },

    -- JPX CANDY & CHRISTMAS SERIES
    weapon_jpx_candy_axe = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_jpx_candy_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_christmas_sign = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_husky_tree = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },

    -- JPX WINTER SERIES
    weapon_jpx_winter_fan = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_jpx_winter_gauntlet = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },

    -- JPX STAFF SERIES (CHRISTMAS THEMED)
    weapon_jpx_bell_staff = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_ginger_bread_staff = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_merry_staff = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_santa_staff = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_snowman_staff = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_tree_staff = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_jpx_reindeer_gun = { -- spray gun
        boneId = 35,
        pos = vec(0.07, -0.15, 0.09),
        rot = vec(0.00, 96.00, 0.20),
    },
    --- ini custom slot    
    weapon_nightstick = {
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_jpx_sakura_grim = {
        pos = vec(-0.28, -0.15, -0.24),
        rot = vec(0.00, 48.95, 0.0),
        boneIndex = 24818
    },
    weapon_sawnoffshotgun = {
        pos = vec(-0.07, -0.15, -0.13),
        rot = vec(0.00, 0.00, 0.00),
        boneIndex = 24818
    },
    weapon_hatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_sledgehammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_knife = {
        pos = vec(0.01, -0.16, -0.13),
        rot = vec(0.00, 0.00, 0.00),
        boneIndex = 24816
    },
    weapon_machete = {
        pos = vec(0.02, -0.15, -0.21),
        rot = vec(0.00, 0.00, 0.00),
        boneIndex = 24816
    },
    weapon_wrench = {
        pos = vec(-0.06, -0.15, -0.15),
        rot = vec(0.00, 0.00, 0.00),
        boneIndex = 24816
    },

    weapon_crowbar = {
        pos = vec(-0.36, 0.04, 0.26),
        rot = vec(-96.31, -13.74, -95.19),
        boneIndex = 24816
    },

    weapon_diamondsword = {
    boneId = 38,
    pos = vec(0.36, -0.13, -0.13),
    rot = vec(-2.50, -66.00, 8.70),
    },

    weapon_diamondaxe = {
    boneId = 38,
    pos = vec(0.36, -0.13, -0.13),
    rot = vec(-2.50, -66.00, 8.70),
    },

    weapon_diamondpickaxe = {
    boneId = 38,
    pos = vec(0.36, -0.13, -0.13),
    rot = vec(-2.50, -66.00, 8.70),
    },

    weapon_bonesword =
    {
        boneId = 35,
        pos = vec(0.00, -0.16, -0.10),
        rot = vec(-2.40, 0.90, -0.70),
    },
    weapon_crystalrod =
    {
        boneId = 38,
        pos = vec(-0.08, -0.18, -0.17),
        rot = vec(0.00, 45.50, 0.20),
    },
    weapon_pinkhammer =
    {
        boneId = 2,
        pos = vec(0.04, -0.00, -0.13),
        rot = vec(-90.00, 0.80, -93.80),
    },
    weapon_psledge =
    {
        boneId = 38,
        pos = vec(-0.21, -0.16, -0.18),
        rot = vec(54.90, -6.30, -263.30),
    },
    weapon_skullbat =
    {
        boneId = 38,
        pos = vec(-0.17, -0.16, 0.19),
        rot = vec(0.40, 124.60, 1.00),
    },
    weapon_badmintonbat = 
    {
        boneId = 38,
        pos = vec(-0.22, -0.16, -0.19),
        rot = vec(-2.70, 55.80, 0.20),
    },
    weapon_pan =
    {
        boneId = 14,
        pos = vec(-0.04, -0.00, 0.14),
        rot = vec(-192.50, -86.50, -551.80),
    },
    weapon_kerbsdoll =
    {
        boneId = 37,
        pos = vec(-0.02, -0.33, 0.14),
        rot = vec(21.00, 85.00, 29.70),
    },
    weapon_vacuum =
    {
        boneId = 38,
        pos = vec(-0.37, -0.23, 0.22),
        rot = vec(0.00, 121.00, 0.20),
    },

    weapon_pumpshotgun_mk2 =
    {
        boneId = 38,
        pos = vec(0.15, -0.14, 0.04),
        rot = vec(0.00, 147.50, 0.20),
    },
    weapon_doubleaction =
    {
        boneId = 14,
        pos = vec(0.00, -0.04, 0.12),
        rot = vec(-72.30, -1.00, 0.20),
    },
    weapon_pistol50 =
    {
        boneId = 35,
        pos = vec(0.04, -0.16, 0.00),
        rot = vec(0.00, 72.50, 0.20),
    },
    -- JPX BLEACH SERIES
    weapon_jpx_ichigo_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.39, -0.16, -0.18),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_jpx_kyoraku_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.29, -0.15, -0.16),
        rot = vec(0.00, -42.00, 0.20),
    },
    weapon_jpx_mayuri_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.44, -0.17, 0.00),
        rot = vec(0.00, -90.00, 0.20),
    },
    weapon_jpx_renji_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.36, -0.21, -0.38),
        rot = vec(0.00, -37.50, 0.20),
    },
    weapon_jpx_grimmjow_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.29, -0.20, -0.23),
        rot = vec(0.00, -44.00, 0.20),
    },
    weapon_jpx_toshiro_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.37, -0.16, 0.25),
        rot = vec(0.00, -128.00, 0.20),
    },
    weapon_jpx_ulquiorra_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.00, -0.17, 0.00),
        rot = vec(0.00, -54.50, 0.20),
    },
    weapon_jpx_urahara_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.26, -0.21, -0.18),
        rot = vec(0.00, -54.50, 0.20),
    },

    -- GACHA V5 WEAPONS
    weapon_zmachette = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_zfireaxe = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_wrenchknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_givewaysign = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_zhatchet = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_smallaxe = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_grinderbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_brakediscaxe = { -- pisau pendek
        boneId = 38,
        pos = vec(-0.19, -0.15, 0.09),
        rot = vec(0.00, 121.50, 0.20),
    },
    weapon_customaxe = { -- tongkat panjang (flag stick)
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_bladedbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_zhammer = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_bladehatchet = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_hunterhatchet = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_clawaxe = { -- pisau pendek
        boneId = 38,
        pos = vec(-0.19, -0.15, 0.09),
        rot = vec(0.00, 121.50, 0.20),
    },
    weapon_lucille = { -- tongkat panjang (spiked bat)
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_enhancedbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_sickle = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_spikeysickle = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_zkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_zhalberd = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_crossbow = { -- tongkat panjang
        boneId = 38,
        pos = vec(0.15, -0.14, 0.04),
        rot = vec(0.00, 147.50, 0.20),
    },
    weapon_python = { -- pistol
        boneId = 35,
        pos = vec(0.04, -0.16, 0.00),
        rot = vec(0.00, 72.50, 0.20),
    },
    weapon_huntershotgun = { -- tongkat panjang
        boneId = 38,
        pos = vec(0.15, -0.14, 0.04),
        rot = vec(0.00, 147.50, 0.20),
    },

    -- JPX PIRATE WEAPON
    -- Bottle (sword)
    weapon_jpx_arlong = { -- pedang panjang
        boneId = 38,
        pos = vec(0.39, -0.16, -0.18),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_jpx_bigmum_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.39, -0.16, -0.18),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_jpx_crocodile = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_jpx_eneru_trident = { -- pedang panjang
        boneId = 38,
        pos = vec(0.00, -0.18, 0.00),
        rot = vec(0.00, 90.00, 0.00),
    },
    weapon_jpx_laws_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.39, -0.16, -0.18),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_jpx_light_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.39, -0.16, -0.18),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_jpx_smoker_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.39, -0.16, -0.18),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_jpx_whitebeard_glaive = { -- pedang panjang
        boneId = 38,
        pos = vec(0.39, -0.16, -0.18),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_jpx_yoru = { -- pedang panjang
        boneId = 38,
        pos = vec(0.41, -0.18, 0.00),
        rot = vec(0.00, -90.0, 0.0),
    },
    -- weapon_jpx_zoro = { -- pedang panjang
    --     boneId = 38,
    --     pos = vec(0.39, -0.16, -0.18),
    --     rot = vec(0.00, -58.50, 0.20),
    -- },
    -- Poolcue
    weapon_jpx_kaido_club = { -- pedang panjang
        boneId = 38,
        pos = vec(0.39, -0.16, -0.18),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_jpx_nami_clima_tact = { -- pedang panjang
        boneId = 38,
        pos = vec(0.39, -0.16, -0.18),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_jpx_sabo_pipe = { -- pedang panjang
        boneId = 38,
        pos = vec(0.39, -0.16, -0.18),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_jpx_usopp_kabuto = { -- pedang panjang
        boneId = 38,
        pos = vec(0.39, -0.16, -0.18),
        rot = vec(0.00, -58.50, 0.20),
    },
    -- Machete
    weapon_jpx_perona_umbrella = { -- pedang pendek
        boneId = 38,
        pos = vec(0.11, -0.17, 0.00),
        rot = vec(175.50, 93.00, 0.20),
    },
    -- Knuckle
    weapon_jpx_franky_gauntlet = { -- pisau pendek
        boneId = 14,
        pos = vec(0.14, -0.06, 0.09),
        rot = vec(-177.00, -107.00, -1888.80),
    },
    weapon_jpx_luffy_bounceman = { -- pisau pendek
        boneId = 14,
        pos = vec(0.14, -0.06, 0.09),
        rot = vec(-177.00, -107.00, -1888.80),
    },

    -- JPX LIONDANCE WEAPON
    weapon_jpx_liondance_bottle = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_jpx_liondance_poolcue = { -- pedang panjang
        boneId = 38,
        pos = vec(0.39, -0.16, -0.18),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_jpx_liondance_knuckle = { -- pisau pendek
        boneId = 14,
        pos = vec(0.14, -0.06, 0.09),
        rot = vec(-177.00, -107.00, -1888.80),
    },
    weapon_jpx_liondance_revolver_gun = { -- pistol
        boneId = 35,
        pos = vec(0.04, -0.16, 0.00),
        rot = vec(0.00, 72.50, 0.20),
    },

    -- JPX DEMON SLAYER SERIES
    weapon_jpx_demon_gyutaro_scythe = { -- reaper/tongkat panjang
        pos = vec(-0.28, -0.15, -0.24),
        rot = vec(0.00, 48.95, 0.0),
        boneIndex = 24818
    },
    weapon_jpx_demon_gyutaro_scythe2 = { -- reaper/tongkat panjang
        pos = vec(-0.28, -0.15, -0.24),
        rot = vec(0.00, 48.95, 0.0),
        boneIndex = 24818
    },
    weapon_jpx_demon_inosuke_katana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_demon_kanao_katana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_demon_mitsuri_katana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_demon_rengoku_katana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_demon_shinobu_katana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_demon_tanjiro_katana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_demon_tengen_sword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_demon_zenitsu_katana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_demon_giyu_katana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_demon_muichiro_katana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_demon_obanai_katana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_jpx_demon_sanemi_katana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },

    --baru

    -- PLASMA SWORD
    weapon_plasmasword_blue = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_plasmasword_green = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_plasmasword_orange = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_plasmasword_pink = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_plasmasword_purple = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_plasmasword_rainbow = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_plasmasword_white = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },
    weapon_plasmasword_yellow = { -- pedang panjang
        boneId = 38,
        pos = vec(0.34, -0.14, 0.21),
        rot = vec(0.00, -122.50, 0.20)
    },

    -- DRAGON KATANA
    weapon_dragon_katana_blue = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_dragon_katana_green = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_dragon_katana_purple = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_dragon_katana_red = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_dragon_katana_yellow = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },

    -- CSGO MELEE - KARAMBIT
    weapon_karambit_case_hardened = { -- pisau pendek
        boneId = 36,
        pos = vec(-0.11, -0.17, -0.05),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_karambit_crimson_web = { -- pisau pendek
        boneId = 36,
        pos = vec(-0.11, -0.17, -0.05),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_karambit_emerald = { -- pisau pendek
        boneId = 36,
        pos = vec(-0.11, -0.17, -0.05),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_karambit_night = { -- pisau pendek
        boneId = 36,
        pos = vec(-0.11, -0.17, -0.05),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_karambit_ruby = { -- pisau pendek
        boneId = 36,
        pos = vec(-0.11, -0.17, -0.05),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_karambit_sapphire = { -- pisau pendek
        boneId = 36,
        pos = vec(-0.11, -0.17, -0.05),
        rot = vec(0.00, 0.00, 0.20),
    },

    -- CSGO MELEE - M9 BAYONET
    weapon_m9_bayonet_case_hardened = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_m9_bayonet_crimson_web = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_m9_bayonet_emerald = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_m9_bayonet_night = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_m9_bayonet_ruby = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_m9_bayonet_sapphire = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },

    -- -- KATANA 2
    -- weapon_katana_2 = { -- pedang panjang
    --     boneId = 38,
    --     pos = vec(0.22, -0.15, 0.12),
    --     rot = vec(0.00, -122.70, 0.20),
    -- },

    -- ============================
    -- GACHA V6 WEAPONS
    -- ============================

    -- Gang Katanas
    weapon_lgbtqgkattana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_rgkattana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_bgkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_ogkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_pgkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_ggkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_pinkgkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_lbgkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_ygkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_blackgkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_wgkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_brgkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_olivegkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_greygkat = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },

    -- Gang Machetes
    weapon_lgbtqgmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_rgmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_orgmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_brgmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_ygmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_wgmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_pgmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_olgmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_lbgmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_greygmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_ggmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_blgmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_pinkgmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_bgmach = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },

    -- Gang Knives
    weapon_lgbtqgknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_rgknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_bgknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_ogknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_pgknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_ggknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_pinkgknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_lbgknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_ygknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_blgknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_wgknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_brgknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_olivegknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_greygknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },

    -- Plain Weapons
    weapon_pbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_normsbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_normknife = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_normkatana = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_normbfk = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_normmachete = { -- pedang pendek
        boneId = 38,
        pos = vec(0.22, -0.13, -0.12),
        rot = vec(0.00, -58.50, 0.20),
    },
    weapon_normhatchet = { -- pisau pendek
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_normsledge = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },

    -- Spikey Bandana Bats
    weapon_lgbtqgsbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_rsgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_bsgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_osgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_psgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_gsgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pinksgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_lbsgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_ysgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_blsgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_wsgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_brownysbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_olivesgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_greysgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },

    -- Bandana Bats
    weapon_lgbtqgbbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_rbgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_olivebgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_bbgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_lbbgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_gbgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_bobgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pibgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_orabgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_greybgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_yebgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_blbgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_whbgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pubbgbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },

    -- Gang Hatchets
    weapon_lgbtqghatchet = { -- pisau pendek
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_rghatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_bghatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_yghatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_pughatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_pghatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_oghatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_olghatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_lbghatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_greyghatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_gghatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_blghatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_brghatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },
    weapon_wghatchet = {
        pos = vec(-0.41, 0.04, -0.22),
        rot = vec(-90.90, -10.59, 270.37),
        boneIndex = 24816
    },

    -- Butterfly Knives
    weapon_lgbtqgbfknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_rgbknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_blgbknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_bgbknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_brgbknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_ggbknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_greygbknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_lbgbknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_ogbknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_pgbknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_pugbknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_wgbknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_ygbknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },
    weapon_olgbknife = { -- pisau pendek
        boneId = 36,
        pos = vec(0.02, -0.18, -0.13),
        rot = vec(0.00, 0.50, 0.20),
    },

    -- Gang Sledgehammers
    weapon_lgbtqgshammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_redshammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_blshammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_bshammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_brshammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_gshammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_greyshammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_lbshammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_ogshammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_olgshammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_pgshammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_pushammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_wgshammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },
    weapon_ygshammer = {
        boneId = 38,
        pos = vec(-0.29, -0.18, 0.08),
        rot = vec(90.00, 90.00, 5.70),
    },

    -- ============================
    -- GACHA V7 WEAPONS
    -- ============================

    -- Crop Whips
    weapon_blcropwhip = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_picropwhip = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_purcropwhip = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_redcropwhip = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_ridcrop = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },

    -- Paddles
    weapon_blpaddle = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_dblpaddle = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_heartpaddle = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_pinkpaddle = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_purplepaddle = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_redpaddle = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_wdhrtpaddle = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_wdpaddle = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_spanker = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },

    -- Spear Whips
    weapon_grspearwhip = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_leatherwhip = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pispearwhip = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_puspearwhip = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_redspearwhip = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_skellywhip = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_spearwhip = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_yespearwhip = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_blspearwhip = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },

    -- Valentine / Love Themed
    weapon_bemy = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_bemypillow = {
        boneId = 36,
        pos = vec(-0.01, -0.23, -0.32),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_heartbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_heartbreaker = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_hers = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_his = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_lovebox = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_lovesign = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_rosebat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_roseboq = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_singlerose = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_thornrosebat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_vbag = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_vroseknife = { -- pisau pendek
        boneId = 38,
        pos = vec(0.16, -0.14, 0.00),
        rot = vec(0.00, -134.50, 0.20),
    },
    weapon_vwinebottle = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_lockchoker = { -- pisau pendek
        boneId = 35,
        pos = vec(-0.01, -0.16, -0.23),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_heartpillow = {
        boneId = 36,
        pos = vec(-0.01, -0.23, -0.32),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_heartteddy = {
        boneId = 36,
        pos = vec(-0.06, -0.20, 0.12),
        rot = vec(0.00, 80.00, 0.20),
    },
    weapon_heartarrow = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_rosesword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },

    -- ============================
    -- GACHA V8 WEAPONS (HALLOWEEN)
    -- ============================

    weapon_boneclub = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_coffin = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.29, -0.24, 0.37),
        rot = vec(0.00, 116.00, 0.20),
    },
    weapon_inferno = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_triplebladedscythe = { -- reaper/tongkat panjang
        pos = vec(-0.28, -0.15, -0.24),
        rot = vec(0.00, 48.95, 0.0),
        boneIndex = 24818
    },
    weapon_deathnote = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_hellfiresword = { -- pedang panjang
        boneId = 38,
        pos = vec(0.22, -0.15, 0.12),
        rot = vec(0.00, -122.70, 0.20),
    },
    weapon_stake = { -- pisau pendek
        boneId = 36,
        pos = vec(0.00, -0.14, -0.07),
        rot = vec(0.00, 0.00, 0.20),
    },
    weapon_pumpkin = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_witchbroom = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_bucket = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_soulscythe = { -- reaper/tongkat panjang
        pos = vec(-0.28, -0.15, -0.24),
        rot = vec(0.00, 48.95, 0.0),
        boneIndex = 24818
    },
    weapon_arm = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_leg = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_pumpkinbat = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },
    weapon_voodoo = { -- tongkat pendek
        pos = vec(0.01, 0.03, 0.23),
        rot = vec(90.57, 8.01, -90.45),
        boneIndex = 24816
    },
    weapon_gravestone = { -- tongkat panjang
        boneId = 38,
        pos = vec(-0.32, -0.15, -0.05),
        rot = vec(0.00, 87.00, 0.20),
    },

    weapon_ak47sm = {
        boneId = 38,
        pos = vec(-0.17, -0.18, 0.00),
        rot = vec(-0.60, -0.90, 5.00),
    },

    -- JPX NINJA WEAPON
    weapon_jpx_samehada2 = {
        boneId = 38,
        pos = vec(0.59, -0.28, -0.38),
        rot = vec(-61.00, -6.00, 86.20),
    },
    weapon_jpx_gunbai = {
        boneId = 38,
        pos = vec(0.47, -0.18, -0.30),
        rot = vec(0.00, -59.50, 0.20),
    },
    weapon_jpx_kubikiribocho = {
        boneId = 38,
        pos = vec(0.43, -0.17, -0.43),
        rot = vec(0.00, -49.50, 0.20),
    },
    weapon_jpx_sasuke_sword = {
        boneId = 38,
        pos = vec(0.38, -0.16, -0.22),
        rot = vec(0.00, -48.50, 0.20),
    },
    weapon_jpx_konan_spear = {
        boneId = 38,
        pos = vec(0.19, -0.17, -0.05),
        rot = vec(0.00, -51.00, 0.20),
    },
    weapon_jpx_hidan_scythe = {
        boneId = 38,
        pos = vec(-0.13, -0.18, 0.17),
        rot = vec(0.00, 125.00, 0.20),
    },
    weapon_jpx_samehada = {
        boneId = 38,
        pos = vec(0.46, -0.21, -0.40),
        rot = vec(0.00, -56.00, 0.20),
    },
    weapon_jpx_paper_bomb_kunai = {
        boneId = 38,
        pos = vec(-0.17, -0.16, 0.09),
        rot = vec(-175.00, 0.00, -181.30),
    },
    weapon_jpx_temari_fan = {
        boneId = 38,
        pos = vec(0.28, -0.14, -0.09),
        rot = vec(-9.00, -131.50, -15.30),
    },

    ---@skateboard
    board_default = {
        model = 'board_default',
        slotId = 'skateboard'
    },
    board_rhdxkosh = {
        model = 'board_rhdxkosh',
        slotId = 'skateboard'
    },
    nk_anniv_skateboard = {
        model = 'nk_anniv_skateboard',
        slotId = 'skateboard'
    },
    weapon_katana_2 = {
        model = 'w_me_katana_2_saya',
        slotId = 'weapon_katana_2'
    },
    weapon_jpx_zoro = {
        model = 'jpx_zoro_sword',
        slotId = 'weapon_jpx_zoro'
    },
}