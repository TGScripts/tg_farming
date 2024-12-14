Config = {}

Config.Debug    =   false   -- Debug Modus
Config.Locale   =   'de'    -- Sprache einstellen (Set Default Language)

Config.Gatherers = {
    {
        coords = vector3(2337.9727, 5003.0479, 42.3976),
        areaRadius = 25.0,

        props = { "prop_tree_birch_05" },
        adjustPropHeight = -0.2,
        maxProps = 20,

        animation = "WORLD_HUMAN_GARDENER_PLANT",

        items = {
            { name = "orange", min = 1, max = 8 }
        },
        gatherTime = 10,

        jobRestricted = false,
        allowedJobs = {},

        blip = { 
            show = true, 
            sprite = 836, 
            color = 2, 
            scale = 1.0, 
            name = "Orangen Sammler" 
        }
    }
}

Config.Processors = {
    {
        coords = vector3(-46.2736, 1946.3582, 190.3582),

        processing = {
            input = "orange", output = "orange_juice", input_rate = 5, output_rate = 1
        },
        processingTime = 7,

        animation = {
            dict = "mp_common",
            anim = "givetake1_a"
        },

        jobRestricted = false,
        allowedJobs = {},
        
        spawnNPC = true,
        npc = {
            coords = vector3(-46.6427, 1947.0558, 189.5558),
            heading = 209.1224,
            pedType = "a_m_m_farmer_01"
        },

        blip = { 
            show = true, 
            sprite = 402, 
            color = 3, 
            scale = 1.2, 
            name = "Orangen Verarbeiter" 
        }
    }
}

Config.Sellers = {
    {
        coords = vector3(-512.5840, -682.8521, 33.1848),

        sellableItems = {
            { name = "orange_juice", price = 50 },
            { name = "packaged_chicken", price = 100 }
        },

        animation = {
            dict = "mp_common",
            anim = "givetake1_a"
        },

        jobRestricted = false,
        allowedJobs = {},

        spawnNPC = true,
        npc = {
            coords = vector3(-512.5840, -682.8521, 32.1848),
            heading = 1.8347,
            pedType = "a_m_y_business_02"
        },

        blip = { 
            show = true, 
            sprite = 500, 
            color = 5, 
            scale = 1.0, 
            name = "Obstverkäufer"
        }
    }
}