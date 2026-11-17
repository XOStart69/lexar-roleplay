local L0_1, L1_1, L2_1
function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = SetWaterAreaClipRect
  L1_2 = -4000
  L2_2 = -4000
  L3_2 = 4500
  L4_2 = 8000
  L0_2(L1_2, L2_2, L3_2, L4_2)
  L0_2 = LoadWaterFromPath
  L1_2 = "amb-roxwood-map"
  L2_2 = "water.xml"
  L0_2(L1_2, L2_2)
end
L1_1 = CreateThread
function L2_1()
  local L0_2, L1_2
  L0_2 = L0_1
  L0_2()
end
L1_1(L2_1)
