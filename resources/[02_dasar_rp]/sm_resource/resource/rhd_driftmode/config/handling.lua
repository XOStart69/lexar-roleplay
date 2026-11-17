return {
    floats = {
        fPercentSubmerged = 85.000000,
        fDriveBiasFront = 0.000000,
        fInitialDriveForce = 1.570000,
        fDriveInertia = 0.4,
        fClutchChangeRateScaleUpShift = 9.900000,
        fClutchChangeRateScaleDownShift = 9.000000,
        fInitialDriveMaxFlatVel = 180.000000,
        fBrakeForce = 2.850000,
        fBrakeBiasFront = 1.000000,
        fHandBrakeForce = 6.500000,
        fSteeringLock = 75.000000,
        fTractionCurveMax = 1.200000,
        fTractionCurveMin = 1.450000,
        fTractionCurveLateral = 25.000000,
        fTractionSpringDeltaMax = 0.150000,
        fLowSpeedTractionLossMult = 0.1500000,
        fTractionBiasFront = 0.450000,
        fTractionLossMult = 1.000000,
        fSuspensionForce = 2.800000,
        fSuspensionCompDamp = 1.400000,
        fSuspensionReboundDamp = 2.200000,
        fSuspensionUpperLimit = 0.060000,
        fSuspensionLowerLimit = -0.050000,
        fSuspensionRaise = -0.000000,
        fSuspensionBiasFront = 0.500000
    },

    ints = {
        nInitialDriveGears = 6,
    },

    vectors = {
        vecCentreOfMassOffset  = vector3(0.000000, 0.000000, 0.000000),
        vecInertiaMultiplier   = vector3(1.000000, 1.000000, 1.000000),
    },

    engineMultiplier = 190.0,

    custom = {
        [`niko370z`] = {
            floats = {
                fSteeringLock = 70.000000,
                fTractionCurveMax = 1.200000,
                fTractionCurveMin = 1.450000,
                fTractionBiasFront = 0.400000,
            },
            engineMultiplier = 190.0,
        }
    }
}