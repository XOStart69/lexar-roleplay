local TODDLER_MODELS = {
    GetHashKey('ks_ias'),
    GetHashKey('Paws_Ricie'),
    GetHashKey('Paws_Naya'),
    GetHashKey('jwcbaby_nata'),
    GetHashKey('babysen'),
    GetHashKey('gs_mora'),
    GetHashKey('sps_rebecca'),
    GetHashKey('aiz_biel'),
    GetHashKey('Paws_Hunter'),
    GetHashKey('Paws_Relio'),
    GetHashKey('Paws_Relia'),
    GetHashKey('lpxnf_alyourna'),
    GetHashKey('paws_moon'),
    GetHashKey('carxpoppy'),
    GetHashKey('Paws_Ana'),
    GetHashKey('ks_putri'),
    GetHashKey('vs_hawa'),
    GetHashKey('paws_shashe2'),
    GetHashKey('paws_yinhua'),
    GetHashKey('paws_yinhuo'),
    GetHashKey('gs_fel'),
    GetHashKey('MadisonToddler_WWMods'),
    GetHashKey('paws_shashe3'),
    GetHashKey('ps_luna'),
    GetHashKey('carxbaby_jeni'),
    GetHashKey('SPS_HANNABIE'),
    GetHashKey('baby_yuma'),
    GetHashKey('cm_theas'),
    GetHashKey('yoyukihime'),
    GetHashKey('Yoshiehime'),
    GetHashKey('cm_kasya'),
    GetHashKey('carxbaby_blythe'),
    GetHashKey('Paws_Ara'),
    GetHashKey('baby_1'),
    GetHashKey('paws_isa'),
    GetHashKey('Paws_Anyaa'),
    GetHashKey('Paws_Anya'),
    GetHashKey('twzl_vion'),
    GetHashKey('twzl_viona'),
    GetHashKey('carxb2603'),
    GetHashKey('paws_ale'),
    GetHashKey('ks_todelsy'),
    GetHashKey('paws_bastian'),
    GetHashKey('carxb2601'),
    GetHashKey('paws_ayya'),
    GetHashKey('paws_ceylo'),
    GetHashKey('paws_kiara'),
    GetHashKey('carxmoon'),
    GetHashKey('Paws_Ael'),
    GetHashKey('ps_berlin'),
    GetHashKey('baby_kikoo'),
    GetHashKey('baby_Yuuki'),
    GetHashKey('paws_achell'),
    GetHashKey('paws_orel'),
    GetHashKey('una'),
    GetHashKey('ps_keycoa'),
    GetHashKey('hn_gireng'),
    GetHashKey('paws_senn'),
    GetHashKey('carxyin'),
    GetHashKey('paws_rochelle'),
    GetHashKey('paws_noland'),
    GetHashKey('paws_rachel'),
    GetHashKey('paws_mikanw'),
    GetHashKey('carxbaby_liya'),
    GetHashKey('haq_babydrew'),
    GetHashKey('eps_yume'),
    GetHashKey('ks_ikkie'),
    GetHashKey('ks_makotod'),
    GetHashKey('wilstore_dhynosaurus'),
    GetHashKey('ws_cala'),
    GetHashKey('paws_nokk'),
    GetHashKey('Paws_Xaviero'),
    GetHashKey('paws_alicia'),
    GetHashKey('7star_BabyBT'),
    GetHashKey('Paws_Noah'),
    GetHashKey('paws_tomoyoy'),
    GetHashKey('paws_lily'),
    GetHashKey('paws_ajeng'),
    GetHashKey('paws_biwa'),
    GetHashKey('paws_lexia'),
    GetHashKey('wilstore_jrhden'),
    GetHashKey('celix_jasrig_0058'),
    GetHashKey('sorsorbaby_milen'),
    GetHashKey('paws_lexio'),
    GetHashKey('7star_keii'),
    GetHashKey('wilstore_maple'),
    GetHashKey('wilstore_mochi'),
    GetHashKey('wilstore_mochaa'),
    GetHashKey('cm_mekdi'),
    GetHashKey('Paws_Renata'),
    GetHashKey('Paws_Akira'),
    GetHashKey('ame_news'),
    GetHashKey('paws_cost'),
    GetHashKey('carxchachu'),
    GetHashKey('paws_miya'),
    GetHashKey('carxblana'),
    GetHashKey('candies_cecil'),
    GetHashKey('gh_livya'),
    GetHashKey('paws_cyrus'),
    GetHashKey('paws_niel'),
    GetHashKey('paws_ame'),
    GetHashKey('paws_queenn'),
    GetHashKey('paws_richie'),
    GetHashKey('paws_caca'),
    GetHashKey('candiesbaby_surya'),
    GetHashKey('wilstore_oreo'),
    GetHashKey('wilstore_milk'),
    GetHashKey('wilstore_choco'),
    GetHashKey('carxcmale'),
    GetHashKey('jumjum_co'),
    GetHashKey('paws_akiw'),
    GetHashKey('cm_kasya3'),
}

local ToddlerHashSet = {}
for _, hash in ipairs(TODDLER_MODELS) do
    ToddlerHashSet[hash] = true
end

local CAM_OFFSET_Z = -0.85

local toddlerCam = nil
local camActive  = false
local threadActive = false

local function DestroyToddlerCam()
    if toddlerCam and DoesCamExist(toddlerCam) then
        RenderScriptCams(false, false, 0, true, true)
        SetCamActive(toddlerCam, false)
        DestroyCam(toddlerCam, false)
    end
    toddlerCam = nil
    camActive = false
end

local function StartCamThread()
    if threadActive then return end
    threadActive = true

    CreateThread(function()
        while ToddlerHashSet[GetEntityModel(cache.ped)] do
            if not IsPedInAnyVehicle(cache.ped, false) and not IsPedDeadOrDying(cache.ped, true) then
                local viewMode = GetFollowPedCamViewMode()

                if viewMode == 4 then
                    if camActive then
                        DestroyToddlerCam()
                    end
                    Wait(100)
                else
                    if not camActive then
                        toddlerCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                        SetCamActive(toddlerCam, true)
                        RenderScriptCams(true, false, 0, true, true)
                        camActive = true
                    end

                    local gameCamCoord = GetGameplayCamCoord()
                    local gameCamRot   = GetGameplayCamRot(2)
                    local gameCamFov   = GetGameplayCamFov()

                    SetCamCoord(toddlerCam, gameCamCoord.x, gameCamCoord.y, gameCamCoord.z + CAM_OFFSET_Z)
                    SetCamRot(toddlerCam, gameCamRot.x, gameCamRot.y, gameCamRot.z, 2)
                    SetCamFov(toddlerCam, gameCamFov)

                    Wait(0)
                end
            else
                if camActive then
                    DestroyToddlerCam()
                end
                Wait(500)
            end
        end

        DestroyToddlerCam()
        threadActive = false
    end)
end

lib.onCache('ped', function(ped)
    if ToddlerHashSet[GetEntityModel(ped)] then
        StartCamThread()
    end
end)

if ToddlerHashSet[GetEntityModel(cache.ped)] then
    StartCamThread()
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DestroyToddlerCam()
    end
end)