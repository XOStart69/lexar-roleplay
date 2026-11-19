-- Memuat seluruh server kasino. Urutan mengikuti dependensi: game lebih dulu,
-- leaderboard terakhir karena membaca tabel yang dibuat game.
require 'casino.blackjack.server'
require 'casino.holdemPoker.server'
require 'casino.insidetrack.server'
require 'casino.luckywheel.server'
require 'casino.roulette.server'
require 'casino.slots.server'
require 'casino.sportsbook.server'

require 'leaderboards.server'