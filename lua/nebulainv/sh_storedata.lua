NebulaStore = {}

NebulaStore.SeasonPass = {
    imgur = "",
    credits = 100,
    enabled = false,
    name = "Season Pass",
    description = "Get a free season pass for the next season.",
    endsAt = os.time() + 3600 * 24 * 31
}

NebulaStore.VaultItems = {
    [1] = {
        itemID = "case_suits1",
        credits = 100,
    },
    [2] = {
        itemID = "weapon_paladin_2",
        credits = 150,
    },
    [3] = {
        itemID = "weapon_paladin_3",
        credits = 1000,
    },
    [4] = {
        itemID = "weapon_grapple_1",
        credits = 1000,
    }
}

NebulaStore.Shop = {
    ["Cases"] = {
        Color = Color(204, 109, 0),
        Items = {
            [1] = {
                itemID = "case_nades",
                money = 7500,
            },
            [2] = {
                itemID = "case_puresteel",
                money = 5000,
            },
            [3] = {
                itemID = "case_red_woopie",
                money = 15000,
            },
        }
    },
    ["Feedback"] = {
        Color = Color(0, 153, 255),
        Items = {
            [1] = {
                itemID = "hitmark_def",
                money = 10000,
                batch = true
            },
            [2] = {
                itemID = "hitmark_squasher",
                money = 12500,
                batch = true
            },
            [3] = {
                itemID = "hitmark_beepo",
                money = 15000,
                batch = true
            },
            [4] = {
                itemID = "vox_scout_tf2",
                money = 5000,
                batch = true
            },
            [5] = {
                itemID = "vox_rick_morty",
                money = 7500,
                batch = true
            },
        }
    }
}