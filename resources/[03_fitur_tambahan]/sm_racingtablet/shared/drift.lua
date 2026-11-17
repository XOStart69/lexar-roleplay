ConfigDrift = {
    useDrift = true, -- enable/disable drift racing features
    scoring = {
        holdCurrentUntilReset = true,
        multiplierMax = 10,
        multiplierTimer = 3000,
        driftThreshold = 15,
        minDriftSpeed = 10.0,
        multiplierIncrementTime = 2000,
        scoreIncrement = 10,
        tickInterval = 100,
    },
    finishCountdown = 9, -- seconds to countdown for remaining racers after first finisher
    checkpointTimePenalty = {
        usePenalty = true, -- whether to apply point penalties for taking too long between checkpoints
        penaltySeconds = 15, -- how many seconds after which penalty is applied (if a racer does not their next checkpoint within this time their points will be penalized)
        penaltyAmount = 100, -- how many points to deduct per penalty occurrence.
        penaltyPercentage = 0.5, -- (0.0-1.0 where 1.0 is 100% of current score) Should be used as alternative, or together with the above. Will reduce total score by a percentage instead.
        stackPenalties = true -- whether penalties should stack for multiple intervals exceeded
    },
}