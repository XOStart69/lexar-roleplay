return {
    enabled = true,

    restartSchedule = {
        { hour = 6,  min = 0 },
        { hour = 18, min = 0 },
    },

    kickBeforeMinutes = 2,
    warnAtMinutes = { 5, 3, 1 },

    useTxAdminEvent = true,

    kickReason = 'Server akan restart dalam %d menit.\n\nKamu di-kick otomatis agar inventory & data tersimpan dengan aman (mencegah rollback).\n\nSilakan join kembali setelah server selesai restart.',

    warnTitle = 'Server Restart',
    warnMessage = 'Restart dalam %d menit. Semua player akan di-kick otomatis %d menit sebelum restart untuk mencegah rollback.',

    useChatMessage = true,
    chatName = 'Sistem',
    chatCategory = 'BERITA',

    useTxAnnouncement = true,
    txAnnouncementAuthor = 'Sistem Restart',
}
