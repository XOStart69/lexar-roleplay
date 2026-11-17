Consumable = {}

Consumable.anim = {
    eat = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger', flag = 49 },
    drink = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
    pill = { dict = 'mp_suicide', clip = 'pill', flag = 49 },
    idle_a =  { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
}

Consumable.prop = {
    burger = { model = 'prop_cs_burger_01', bone = 60309, pos = vec3(0.0, 0.0, -0.02), rot = vec3(30, 0.0, 0.0) },
    water = { model = 'vw_prop_casino_water_bottle_01a', bone = 60309, pos = vec3(0.0, 0.0, -0.05), rot = vec3(0.0, 0.0, -40) },
    beer = { model = 'prop_cs_beer_bot_40oz', bone = 60309, pos = vec3(0.0, 0.0, -0.05), rot = vec3(0.0, 0.0, -40) },
    bandage = { model = `prop_rolled_sock_02`, bone = 60309, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
}