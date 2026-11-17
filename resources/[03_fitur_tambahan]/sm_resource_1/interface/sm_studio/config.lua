return {
    Debug = false,

    EnterRange = 60.0,

    MaxFiles = 200,
    MaxSongs = 50,
    MaxTracks = 16,
    MaxRecordSeconds = 300,
    MaxImportSeconds = 600,
    ImportCooldown = 15,
    UploadCooldown = 3,
    ExportBytesPerSecond = 1048576,

    Studios = {
        dream_records = {
            label = 'DREAM RECORDS',
            forall = false,
            jobs = { musicsm = 1 },
            blip = {
                coords = vec3(1283.810913, -348.140625, 75.910294),
                sprite = 136,
                color = 18,
                scale = 0.8,
                label = 'DREAM RECORDS',
            },
            zone = {
                height = 18.0,
                points = {
                    vec3(1276.0799560547, -337.91000366211, 76.0),
                    vec3(1290.0, -342.57998657227, 76.0),
                    vec3(1301.9000244141, -346.55999755859, 76.0),
                    vec3(1298.5400390625, -361.26998901367, 76.0),
                    vec3(1297.3299560547, -365.42001342773, 76.0),
                    vec3(1288.1999511719, -363.19000244141, 76.0),
                    vec3(1281.5300292969, -361.39001464844, 76.0),
                    vec3(1278.9000244141, -368.70999145508, 76.0),
                    vec3(1270.3100585938, -366.7200012207, 76.0),
                    vec3(1272.3100585938, -359.94000244141, 76.0),
                    vec3(1272.9300537109, -352.76998901367, 76.0),
                    vec3(1273.0, -353.0, 76.0),
                },
            },
            computer = {
                coords = vec3(1283.810913, -348.140625, 75.910294),
                radius = 1.5,
                maxVolumeDistance = 100.0,
            },
            microphone = {
                coords = vec3(1295.140747, -350.932861, 76.767090),
                radius = 0.5,
            },
            television = {
                model = `vw_prop_vw_cinema_tv_01`,
                coords = vec3(1285.033691, -348.088013, 77.664307),
                rotation = vec3(0.0, 0.0, 255.0),
                target = 'tvscreen',
            },
        },
    },

    Animations = {
        microphone = {
            dict = 'mic_pose_1@darksj',
            clip = 'mic_pose_1_clip',
            flag = 51,
            prop = `sf_prop_sf_mic_01a`,
            bone = 28422,
            placement = { 0.068, 0.019, -0.022, 0.0, 0.0, 170.0 },
        },
        computer = {
            dict = 'anim@amb@nightclub@djs@solomun@',
            clip = 'sol_idle_ctr_mid_a_sol',
            flag = 1,
        },
    },

    Labels = {
        open_computer = 'Buka Komputer',
        take_record = 'Ambil/Lepas Mic',
        mic_settings = 'Pengaturan Mic',
    },

    Notify = {
        unauthorized = { 'Akses ditolak.', 'error', 5000 },
        studio_not_found = { 'Kamu tidak berada di studio.', 'error', 5000 },
        computer_busy = { 'Komputer sedang dipakai.', 'error', 5000 },
        microphone_busy = { 'Mic sedang dipakai.', 'error', 5000 },
        microphone_empty = { 'Belum ada yang di mic.', 'error', 5000 },
        recording_started = { 'Rekaman dimulai!', 'success', 4000 },
        recording_saved = { 'Rekaman selesai, sedang diupload.', 'success', 5000 },
        recording_discarded = { 'Rekaman dibatalkan.', 'info', 5000 },
        went_wrong = { 'Terjadi kesalahan.', 'error', 5000 },
        record_uploading_wait = { 'Rekaman sedang diupload, tunggu sebentar.', 'info', 5000 },
        on_mic = { 'Kamu di mic.', 'success', 5000 },
        out_mic = { 'Kamu meninggalkan mic.', 'info', 5000 },
    },
}
