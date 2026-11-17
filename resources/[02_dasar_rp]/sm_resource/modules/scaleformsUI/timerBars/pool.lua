---@class TimerBarPool
---@field bars table
local TimerBarPool = lib.class('TimerBarPool')

function TimerBarPool:constructor()
    self.bars = {}
end

---@param timerBar table
function TimerBarPool:addBar(timerBar)
    timerBar.handle = #self.bars + 1
    self.bars[timerBar.handle] = timerBar
end

---@param timerBar table
function TimerBarPool:removeBar(timerBar)
    if timerBar.handle then
        self.bars[timerBar.handle] = nil
    end
end

function TimerBarPool:draw()
    local offset = 0
    
    -- if ScaleformUI and ScaleformUI.Scaleforms and ScaleformUI.Scaleforms.InstructionalButtons then
    --     if #ScaleformUI.Scaleforms.InstructionalButtons.ControlButtons > 0 or 
    --        ScaleformUI.Scaleforms.InstructionalButtons.IsSaving then
    --         offset = 9
    --     end
    -- end
    
    for k, v in pairs(self.bars) do
        if v.draw then
            v:draw((k * 10) + offset)
        end
    end
end

---@return number
function TimerBarPool:count()
    local count = 0
    for _ in pairs(self.bars) do
        count = count + 1
    end
    return count
end

function TimerBarPool:clear()
    self.bars = {}
end

return TimerBarPool