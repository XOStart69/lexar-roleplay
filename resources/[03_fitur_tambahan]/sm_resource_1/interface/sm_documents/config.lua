return {
    -- Perintah untuk membuka dokumen. Set nil untuk mematikan.
    Command = 'doc',
    -- Contoh: 'k'. Butuh Command terisi. nil = tidak ada keybind.
    RegisterKey = nil,
    -- Nama item yang membuka dokumen. nil = tidak mendaftarkan item.
    DocumentItemName = nil,

    -- Prop kertas yang dipegang saat UI terbuka.
    PaperProp = {
        name = 'prop_cd_paper_pile1',
        xRot = -130.0,
        yRot = -50.0,
        zRot = 0.0
    },

    -- Job yang boleh menerbitkan dokumen.
    -- templateGrades = grade yang boleh mengelola template job tersebut.
    -- logo = nama file di web/src/assets/jobs (tanpa .png). Kalau file-nya
    -- tidak ada, UI otomatis jatuh ke logo SM.
    AvailableJobs = {
        { job = 'police',         templateGrades = { 10, 11, 12, 13, 14, 15, 16 },           logo = 'police' },
        { job = 'ambulance',      templateGrades = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }, logo = 'ambulance' },
        { job = 'puskesmas',      templateGrades = { 0, 1, 2, 3 },                           logo = 'puskesmas' },
        { job = 'mechanic',       templateGrades = { 0, 1, 2, 3, 4 },                        logo = 'teknogarage' },
        { job = 'musicsm',        templateGrades = { 0, 1, 2, 3, 4 },                        logo = 'musicsm' },
        { job = 'kkpgarage',      templateGrades = { 1, 2 },                                 logo = 'kkpgarage' },
        { job = 'government',     templateGrades = { 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 },  logo = 'pemerintah' },
        { job = 'reporter',       templateGrades = { 5, 6, 7, 8 },                           logo = 'sm' },
        { job = 'taxism',         templateGrades = { 3, 4, 5 },                              logo = 'taxism' },
        { job = 'resto',          templateGrades = { 0, 1, 2, 3, 4 },                        logo = 'restogembira' },
        { job = 'digitalden',     templateGrades = { 0, 1, 2, 3, 4 },                        logo = 'digitalden' },
        { job = 'pengadilan',     templateGrades = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }, logo = 'Pengadilan' },
        { job = 'paud',           templateGrades = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },         logo = 'paud' },
        { job = 'usmarshal',      templateGrades = { 0, 1, 2, 3, 4, 5, 6 },                  logo = 'usmarshal' },
        { job = 'mercenarysm',    templateGrades = { 0, 1, 2, 3, 4, 5, 6 },                  logo = 'mercenarysm' },
        { job = 'rsroxwood',      templateGrades = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }, logo = 'rsroxwood' },
        { job = 'pabrik',         templateGrades = { 0, 1, 2, 3, 4, 5, 6 },                  logo = 'sumberezki' },
        { job = 'mechanic969',    templateGrades = { 0, 1, 2, 3, 4 },                        logo = 'mechanic969' },
        { job = 'luxurynightclub',templateGrades = { 3, 4, 5 },                              logo = 'luxurynightclub' },
        { job = 'maxspeedgarage', templateGrades = { 0, 1, 2, 3, 4 },                        logo = 'maxspeedgarage' },
        { job = 'burgenkcafe',    templateGrades = { 0, 1, 2, 3, 4, 5, 6, 7 },               logo = 'burgenkcafe' },
        { job = 'nightclub',      templateGrades = { 3, 4, 5 },                              logo = 'nightclub' },
        { job = 'kkpresto',       templateGrades = { 2, 3, 4 },                              logo = 'kkpresto' },
        { job = 'mhcafe',         templateGrades = { 2, 3, 4 },                              logo = 'mhcafe' },
        { job = 'gzcafe',         templateGrades = { 0, 1, 2, 3, 4 },                        logo = 'gzcafe' },
        { job = 'smmotel',        templateGrades = { 0, 1, 2, 3, 4 },                        logo = 'smmotel' },
        { job = 'hightable',      templateGrades = { 0, 1, 2, 3, 4, 5, 6, 7 },               logo = 'hightable' },
        { job = 'stunberg',       templateGrades = { 0, 1, 2, 3, 4 },                        logo = 'hightable' },
        { job = 'velvetsm',       templateGrades = { 3, 4 },                                 logo = 'velvetsm' },
    },

    -- Template yang bisa dipakai semua warga. Kosongkan ({}) kalau tidak mau
    -- ada template warga; tab "Dokumen Terbit" lalu hanya tampil untuk job.
    CitizenTemplates = {
        {
            id = 'citizen_contract',
            documentName = 'Kontrak Warga',
            documentDescription = 'Dokumen antara dua warga Los Santos. Dokumen ini bersifat legal dan resmi.',
            fields = {
                { name = 'Nama Depan',     value = '' },
                { name = 'Nama Belakang',  value = '' },
                { name = 'Berlaku Sampai', value = '' },
            },
            infoName = 'INFORMASI',
            infoTemplate = ''
        },
    },

    -- Teks sisi client (notifikasi & help text in-game).
    Locale = {
        receiveNotification = 'Anda menerima salinan dokumen: ',
        giveNotification = 'Anda memberikan salinan dokumen: ',
        receiveOriginalNotification = 'Anda menerima dokumen ASLI: ',
        giveOriginalNotification = 'Anda menyerahkan dokumen ASLI: ',
        cancel = 'Batal',
        noPlayersAround = 'Tidak ada seorang pun di sekitar Anda',
        showDocument = 'Tampilkan Dokumen',
        giveCopy = 'Berikan Salinan',
        giveOriginal = 'Serahkan Dokumen Asli',
        registerMapDescription = 'Buka dokumen'
    },

    -- Teks di dalam UI.
    Texts = {
        myDocumentsTitle = 'Dokumen Saya',
        issuedDocumentsTitle = 'Dokumen Terbit',
        templatesTitle = 'Template',
        customDocumentName = 'Nama Dokumen',
        documentType = 'Jenis',
        documentName = 'Nama',
        unnamed = 'Tanpa Nama',
        actions = 'Aksi',
        edit = 'Ubah',
        cancel = 'Batal',
        delete = 'Hapus',
        view = 'Lihat',
        show = 'Perlihatkan',
        copy = 'Salinan',
        giveOriginal = 'Serahkan Asli',
        giveOriginalTitle = 'Serahkan Dokumen Asli',
        giveOriginalQuestion = 'Dokumen ASLI ini akan berpindah tangan dan hilang dari daftar Anda. Tindakan ini tidak bisa dibatalkan. Serahkan dokumen:',
        giveOriginalConfirm = 'Serahkan',
        newTemplateBtn = 'Template Baru',
        deleteTemplateTitle = 'Hapus Template',
        deleteTemplateQuestion = 'Yakin ingin menghapus template ini?',
        date = 'Tanggal',
        newDocumentBtn = 'Dokumen Baru',
        newCitizenDocumentBtn = 'Dokumen Warga',
        deleteDocumentTitle = 'Hapus Dokumen',
        deleteDocumentQuestion = 'Yakin ingin menghapus dokumen ini?',
        signHereText = 'Tanda Tangan',
        selectDocumentType = 'Pilih jenis dokumen',
        cannotIssueDocument = 'Anda tidak bisa menerbitkan dokumen dengan job ini',
        issuerFirstname = 'NAMA DEPAN PENERBIT',
        issuerLastname = 'NAMA BELAKANG PENERBIT',
        issuerDOB = 'TANGGAL LAHIR',
        issuerJob = 'JABATAN',
        termsAndSigning = 'KETENTUAN DAN TANDA TANGAN',
        terms1 = 'Dokumen ini menjadi dokumen resmi setelah ditandatangani.',
        terms2 = 'Dengan menandatangani, Anda terikat secara hukum atas isinya beserta seluruh konsekuensinya.',
        terms3 = 'Setiap salinan dokumen ini bernilai sama dengan aslinya. Berhati-hatilah saat memberikan salinan.',
        terms4 = 'Pastikan Anda memahami sepenuhnya isi dokumen ini sebelum menandatangani.',
        terms5 = 'Jangan ragu meminta pendampingan hukum sebelum menandatangani.',
        requiredError = 'Kolom ini wajib diisi',
        docNameField = 'NAMA DOKUMEN',
        docDescField = 'DESKRIPSI DOKUMEN',
        docFieldField = 'NAMA KOLOM',
        docAddField = 'Tambah Kolom',
        docInfoNameField = 'JUDUL INFORMASI',
        docInfoValueField = 'TEMPLATE INFORMASI',
        docMinGradeField = 'GRADE MINIMUM',
        editTemplateBtn = 'SIMPAN TEMPLATE',
        createTemplateBtn = 'BUAT TEMPLATE',
        createDocumentBtn = 'BUAT DOKUMEN',
        documentCopy = 'SALINAN',
        documentOriginal = 'ASLI',
        emptyDocuments = 'Belum ada dokumen',
        emptyTemplates = 'Belum ada template',
        search = 'Cari...',
        close = 'Tutup',
    }
}
