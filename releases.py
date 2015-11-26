RELEASE_BRANCH_MILESTONE = {
  "CMSSW_7_5_5_patchX": 58,
  "CMSSW_8_0_X": 57,
  "CMSSW_7_6_X": 55,
  "CMSSW_7_5_X": 51,
  "CMSSW_7_4_X": 50,
  "CMSSW_7_3_X": 49,
  "CMSSW_7_0_X": 38,
  "CMSSW_7_1_X": 47,
  "CMSSW_7_2_X": 48,
  "CMSSW_6_2_X": 21,
  "CMSSW_6_2_X_SLHC": 9,
  "CMSSW_5_3_X": 20,
  "CMSSW_4_4_X": 8,
  "CMSSW_4_2_X": 35,
  "CMSSW_4_1_X": 7,
  "CMSSW_6_2_SLHCDEV_X": 52,
  "CMSSW_7_1_4_patchX": 53,
  "CMSSW_7_4_1_patchX": 54,
  "CMSSW_7_4_12_patchX": 56,
}

RELEASE_BRANCH_CLOSED = [
  "CMSSW_4_1_X",
  "CMSSW_4_2_X",
  "CMSSW_4_4_X",
  "CMSSW_6_1_X",
  "CMSSW_6_1_X_SLHC",
  "CMSSW_6_2_X",
  "CMSSW_7_0_X",
]

RELEASE_BRANCH_PRODUCTION = [
  "CMSSW_8_0_X",
  "CMSSW_7_6_X",
  "CMSSW_7_5_X",
  "CMSSW_7_4_X",
  "CMSSW_7_3_X",
  "CMSSW_7_2_X",
  "CMSSW_7_1_X",
  "CMSSW_7_0_X",
  "CMSSW_6_2_X_SLHC",
  "CMSSW_5_3_X",
]

SPECIAL_RELEASE_MANAGERS = ["slava77", "smuzaffar"]

RELEASE_MANAGERS = {
  "CMSSW_8_0_X": ["degano"],
  "CMSSW_7_6_X": ["degano"],
  "CMSSW_7_5_X": ["degano"],
  "CMSSW_7_4_X": ["degano"],
  "CMSSW_7_3_X": ["degano"],
  "CMSSW_7_2_X": ["degano"],
  "CMSSW_7_1_X": ["degano"],
  "CMSSW_7_0_X": ["degano"],
  "CMSSW_6_2_X": ["degano"],
  "CMSSW_6_2_X_SLHC": ["fratnikov", "mark-grimes"],
  "CMSSW_6_2_SLHCDEV_X": ["fratnikov", "mark-grimes"],
  "CMSSW_5_3_X": ["smuzaffar"],
  "CMSSW_4_4_X": ["smuzaffar", "davidlt"],
  "CMSSW_4_2_X": ["smuzaffar", "davidlt"],
  "CMSSW_4_1_X": ["smuzaffar", "davidlt"],
}

DEVEL_RELEASE_CYCLE = {
  "CMSSW_7_4_X" :"CMSSW_7_6_X",
  "CMSSW_7_5_X" :"CMSSW_7_6_X",
}

RELEASE_MANAGERS_FOR_NEW_RELEASE_CYCLES = ["degano"]
