return {
    garage = 'Garasi Bandara',
    platePrefix = 'STR',
    fuel = 100.0,
    sessionSeconds = 600,
    claimRadius = 5.0,
    renderDistance = 30.0,
    interactDistance = 2.0,

    ped = {
        model = 'a_m_y_business_03',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
    },

    locations = {
        vec4(-1040.479126, -2731.582520, 20.164062, 238.110229),
    },

    items = {
        { name = 'boxstarterpack', count = 1 },
    },

    vehicles = {
        [0] = { model = 'hilux1', color = 0 },
        [1] = { model = 'navfit', color = 51, livery = -1 },
    },

    intro = 'Jawab semua pertanyaan dengan benar untuk menerima starter pack dan kendaraan pertamamu.',

    quiz = {
        {
            question = 'Apa aturan pertama dalam roleplay?',
            description = 'Pertanyaan ini menguji pemahaman dasar Anda tentang roleplay.',
            correct = 'Selalu tetap dalam karakter',
            wrong = { 'Abaikan pemain lain', 'Keluar dari karakter untuk bersenang-senang', 'Gunakan pengetahuan di luar karakter' },
        },
        {
            question = 'Apa yang harus kamu lakukan jika seseorang melanggar aturan server?',
            description = 'Pertanyaan ini menguji pengetahuan Anda tentang etika bermain di server.',
            correct = 'Laporkan ke admin/staff',
            wrong = { 'Konfrontasi mereka dalam roleplay', 'Abaikan saja', 'Mulai berkelahi dengan mereka' },
        },
        {
            question = 'Apa arti "Fail RP"?',
            description = 'Pertanyaan ini menguji pemahaman Anda tentang istilah roleplay.',
            correct = 'Tindakan yang merusak imersi roleplay',
            wrong = { 'Menang dalam skenario roleplay', 'Jenis acara roleplay', 'Aturan server tentang berkendara' },
        },
        {
            question = 'Apa itu "Powergaming" dalam roleplay?',
            description = 'Mengacu pada tindakan yang tidak realistis atau memaksa hasil dalam RP.',
            correct = 'Memaksa skenario tanpa persetujuan pemain lain',
            wrong = { 'Bermain sebagai karakter yang lemah', 'Selalu kalah dalam roleplay', 'Menggunakan senjata terlalu banyak' },
        },
        {
            question = 'Apa arti "Metagaming"?',
            description = 'Menggunakan informasi OOC untuk keuntungan IC.',
            correct = 'Menggunakan info luar karakter dalam roleplay',
            wrong = { 'Memainkan karakter dengan kekuatan super', 'Roleplay sebagai polisi', 'Berbicara dalam voice chat' },
        },
    },
}
