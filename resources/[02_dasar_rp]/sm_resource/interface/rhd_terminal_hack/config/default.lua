---Supports: preset names (cyan, blue, green, yellow, red, purple, pink, orange, amber)
---          hex (#FF0000, #F00), hexa (#FF0000FF), rgb (rgb(255,0,0)), rgba (rgba(255,0,0,1))
---@alias TerminalMinigameTheme string
---@alias TerminalMinigameDifficulty 'easy' | 'medium' | 'hard'

---@class TerminalHackMinigameData
---@field totalForlder number
---@field totalFile number
---@field totalTime number
---@field totalDecoy number

---@class TerminalHackMinigameParam: TerminalHackMinigameData
---@field theme TerminalMinigameTheme

---@class TerminalHackConfig
---@field theme TerminalMinigameTheme
---@field difficulty table<TerminalMinigameDifficulty, TerminalHackMinigameData>

return {
    theme = 'cyan',
    difficulty = {
        easy = {
            totalForlder = 1,
            totalFile = 1,
            totalTime = 800,
            totalDecoy = 1
        },
        medium = {
            totalForlder = 2,
            totalFile = 2,
            totalTime = 400,
            totalDecoy = 2
        },
        hard = {
            totalForlder = 3,
            totalFile = 3,
            totalTime = 200,
            totalDecoy = 3
        },
    },
}