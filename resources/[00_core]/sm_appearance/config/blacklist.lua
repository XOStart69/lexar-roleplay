--[[
    Drawables the editor refuses to offer. Only slots that need a rule have to be listed; anything
    left out is unrestricted. An entry with a job, gang, ace or citizen id requirement is lifted for
    whoever meets it, and one with none is blocked for everybody. See BlacklistEntry in typings.lua.

    Naming textures takes only those, for whichever of the entry's drawables is being worn. Leaving
    them out takes the drawables whole.

    Admins add further entries through /appearanceadmin, and those are stored in the database.
]]
---@type table<string, BlacklistGroup>
return {
    male = {
        hair = {
         	{
                drawables = { 933, 1018, 1019, 1020, 1170, 1203, 1204, 1205 },
                citizenids = { "TWD32132", "IFE99613" } --lopezssss 
            },
            {
                drawables = { 941, 942 },
                citizenids = { "IHO70542" } --Aeron
            },
            {
                drawables = { 940, 943, 945 },
                citizenids = { "TKK99710" } --Pascal
            },
            {
                drawables = { 953 },
                citizenids = { "OVJ50676" } --Luca Van Extouris
            },
            {
                drawables = { 958 },
                citizenids = { "OLE26452" } --Kyler
            },
            {
                drawables = { 959 },
                citizenids = { "XBC65184" } --Gunnar
            },
            {
                drawables = { 985 },
                citizenids = { "NUD40205" } --Yuki
            },
            {
                drawables = { 987 },
                citizenids = { "DQU80628" } --kenzo
            },
            {
                drawables = { 988 },
                citizenids = { "EUB56218" } --Vyan
            },
            {
                drawables = { 993 },
                citizenids = { "UYE76112" } --kucingrp
            },
            {
                drawables = { 1000 },
                citizenids = { "IVC60196" } --Agra
            },
            {
                drawables = { 1001 },
                citizenids = { "ZWF10662" } --Lucas
            },
            {
                drawables = { 1009 },
                citizenids = { "TKA94648" } --komikki
            },
            {
                drawables = { 1012, 1013, 1014 },
                citizenids = { "BHI33650" } --pablo
            },
            {
                drawables = { 1024 },
                citizenids = { "QPM15261" } --gokong
            },
            {
                drawables = { 1028, 1029 },
                citizenids = { "XKV83995", "IFE99613" } --Kuro
            },
            {
                drawables = { 1045 },
                citizenids = { "UEH15952" } --Devon Stunberg
            },
            {
                drawables = { 1050 },
                citizenids = { "UYE76112" } --kucingrp
            },
            {
                drawables = { 1058 },
                citizenids = { "YJG75104" } --kohcun
            },
            {
                drawables = { 1070, 1071 },
                citizenids = { "TDG45936", "VKQ71518", "NWM13331", "YFE44073" } --andre keshy
            },
            {
                drawables = { 1119 },
                citizenids = { "BOH88301" } --irfannmalikk
            },
               {
                drawables = { 1161 },
                citizenids = { "JSY26477" } --KaelMikhael
            },
            {
                drawables = { 1162 },
                citizenids = { "XIM36342" } --Louis Xav
            },
             {
                drawables = { 1163 },
                citizenids = { "FSQ79440" } --Joko Sancez
            },
            {
                drawables = { 1165 },
                citizenids = { "GSU26290" } --Gore Gone
            },
            {
                drawables = { 1168 },
                citizenids = { "SVE63051" } --Mozes Ignacio derevan
            },
            {
                drawables = { 1171 },
                citizenids = { "XII58730" } --KUNTET SMURF BIRU ( SIMON )
            },
            {
                drawables = { 1173 },
                citizenids = { "RNK48601" } --Fransisco Xavier Key
            },
            {
                drawables = { 1177 },
                citizenids = { "GAF87843" } --Wil wilder
            },
            {
                drawables = { 1185 },
                citizenids = { "LYY23858" } --Bas SM
            },
            {
                drawables = { 1186 },
                citizenids = { "OHF05185" } --Nok SM
            },
            {
                drawables = { 1190 },
                citizenids = { "ZFR34630" } --Dan D Less
            },
            {
                drawables = { 1193, 1194 },
                citizenids = { "NLF04501" } --Daigo
            },
            {
                drawables = { 1197 },
                citizenids = { "HMC73397", "IFE99613" } --Ze Tzu Sloane Oklama
            },
            {
                drawables = { 1198 },
                citizenids = { "NLK63710", "IFE99613" } --Enzel Ignatius S
            },
            {
                drawables = { 1209 },
                citizenids = { "NVY53536" } --Rumi V Helsing
            },
               {
                drawables = { 1209, 1210 },
                citizenids = { "ACJ98901" } --Aurelius Valerio
            },
            {
                drawables = { 1213 },
                citizenids = { "VSY18936" } --John Cooper Olathe
            },
            {
                drawables = { 1215 },
                citizenids = { "WHQ06353" } --zake draker
            },
            {
                drawables = { 1220 },
                citizenids = { "GMF50217" } --Kaydeniel Levi Connor
            },
            {
                drawables = { 1221 },
                citizenids = { "NPA00376" } --Kenzie Kisaragi
            },
             {
                drawables = { 1222 },
                citizenids = { "KDF00238" } --Jinwoo na
            },
            {
                drawables = { 1226 },
                citizenids = { "VGI79407", "IFE99613" } --Keshy v2 jangan dihapus
            },
             {
                drawables = { 1227 },
                citizenids = { "OYE30573" } --Rodrigo Esteban
            },
              {
                drawables = { 1231 },
                citizenids = { "QBK85740" } --Laden
            },
               {
                drawables = { 1232 },
                citizenids = { "XSH13262" } --Yujin
            },
            {
                drawables = { 1239 },
                citizenids = { "LVY38456" } --SENO MAGENTANO
            },
            {
                drawables = { 1240 },
                citizenids = { "JCB76402" } --Auren Roux
            },
            {
                drawables = { 1244 },
                citizenids = { "PND48307" } --bobibob
            },
             {
                drawables = { 1246 },
                citizenids = { "MGB92046" } --Ilia Topuria
            },
             {
                drawables = { 1247 },
                citizenids = { "CJW11389" } --Alexander Kemboja
            },
            {
                drawables = { 1248 },
                citizenids = { "IOX47886" } --kings (admin)
            },
            {
                drawables = { 1249 },
                citizenids = { "HPK14740" } --Joel S Leonhart
            },
             {
                drawables = { 1251 },
                citizenids = { "XYQ20546" } -- Levi de Baskerville 
            },
             {
                drawables = { 1252 },
                citizenids = { "VDA59803" } -- Lax Parrow 
            },
            {
                drawables = { 1254 },
                citizenids = { "AJP453D4" } -- Jugo Neo
            },
            {
                drawables = { 1257 },
                citizenids = { "XKV83995" } -- Kuro Verlly 
            },
            {
                drawables = { 1259 },
                citizenids = { "XPE13846" } -- gibo 
            },
            {
                drawables = { 1260 },
                citizenids = { "MJB93270" } -- Newo aja 
            },
            {
                drawables = { 1266 },
                citizenids = { "FAM32356" } -- SKY Z KOBAYASHI 
            },
            {
                drawables = { 1267 },
                citizenids = { "WKO88580" } -- jacob schmidt soltice 
            },
            {
                drawables = { 1268 },
                citizenids = { "ZOB58987" } -- Josh Hesky 
            },
            {
                drawables = { 1271, 1272, 1273 },
                citizenids = { "VKS90571" } -- lopezz 
            },
            {
                drawables = { 1274 },
                citizenids = { "IIT45230" } -- Fanzo Hasashi 
            },
            {
                drawables = { 1275 },
                citizenids = { "WOD87729" } -- Aaron Junior 
            },
            {
                drawables = { 1276 },
                citizenids = { "QUJ13762" } -- GADGAD 
            },
            {
                drawables = { 1279 },
                citizenids = { "NFA90442" } -- Black DAngelo 
            },
            {
                drawables = { 1280 },
                citizenids = { "WTY80694" } -- Jun Costantine Elstone 
            },
            {
                drawables = { 1281 },
                citizenids = { "HKT44760" } -- VLAD DESCHOARRA HEMSWORTH 
            },
            {
                drawables = { 1282 },
                citizenids = { "YYY02495" } -- Dominic Wilder 
            },
            {
                drawables = { 1284 },
                citizenids = { "KGA77823" } -- Joe Buddy 
            },
            {
                drawables = { 1285 },
                citizenids = { "PIU09337" } -- Jordy Valmores 
            },
            {
                drawables = { 1290 },
                citizenids = { "ZOB58987" } -- Josh Hesky 
            },
            {
                drawables = { 1291 },
                citizenids = { "ZIH36897" } -- Chan Hawkins 
            },
            {
                drawables = { 1293, 1294, 1295 },
                citizenids = { "MGB92046" } -- victor frankenstein 
            },
            {
                drawables = { 1296 },
                citizenids = { "QDP50599" } -- Corvin Brooks 
            },
            {
                drawables = { 1298 },
                citizenids = { "JHS06512" } -- Pacilo 
            },

        },
        components = {
            masks = {
                {
                    drawables = {316, 317},
                    jobs = {"admin"} -- masks_badside
                },
                {
                    drawables = {350},
                    jobs = {"hightable"} -- masker hightable
                },
            },
            upperBody = {},
            lowerBody = {
                {
                    drawables = {667, 668},
                    jobs = {"admin"} -- pants_badside
                },
                {
                    drawables = {670},
                    citizenids = { "MDE71750", "BOH88301", "IFE99613" } --rialdynt
                },
                {
                    drawables = {671, 681, 682, 695},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
                {
                    drawables = {681},
                    citizenids = {"IFE99613", "TWD32132"} -- Kemeja lopez
                },
                {
                    drawables = {684, 709},
                    jobs = {"hightable"} -- celana hightable
                },
                {
                    drawables = {691},
                    citizenids = {"IFE99613", "TWD32132"} -- lopez
                },
                {
                    drawables = {713},
                    citizenids = {"IFE99613", "JHS06512"} -- Celana Pacilo
                },
                {
                    drawables = {714},
                    citizenids = {"TDS73632"} --Justin Remedi
                },
                {
                    drawables = {718},
                    citizenids = { "DJB89865", "JHS06512" } --Mikhayla G
                },
            },
            bags = {
				{
                    drawables = {222, 225, 231, 257},
                    jobs = {"admin"} -- bags_badside
                },
                {
                    drawables = {229},
                    citizenids = { "IOX47886", "IFE99613" } --Kings
                },
                {
                    drawables = {232},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
                {
                    drawables = {280},
                    jobs = {"hightable"} -- bags hightable
                },
			},
            shoes = {
                {
                    drawables = {403},
                    citizenids = {"IFE99613", "TWD32132"} -- lopez
                },
                {
                    drawables = {404},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
            },
            scarfAndChains = {
                {
                    drawables = {550, 637, 639},
                    jobs = {"admin"} -- bags_badside
                },
                {
                    drawables = {561, 636},
                    jobs = {"hightable"} -- scarf and chains hightable
                },
                {
                    drawables = {566},
                    citizenids = {"IFE99613", "TWD32132"} -- lopez
                },
                 {
                    drawables = {570},
                    citizenids = {"AXX38698"} --Noi Van Jeager
                },
                {
                    drawables = {571},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
            },
            shirts = {
                {
                    drawables = {343},
                    jobs = {"admin"} -- m_shirts_rb
                },
                {
                    drawables = {345},
                    citizenids = {"QPM15261", "IFE99613", "TWD32132"} -- dalaman jas gokong
                },
                {
                    drawables = {348, 354, 372},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
                {
                    drawables = {355, 402, 403},
                    jobs = {"hightable"} -- shirt hightable
                },
            },
            bodyArmor = {
                {
                    drawables = {224, 225, 226, 227, 228, 229, 232, 233, 234, 235, 236, 237, 238, 239, 241, 242, 243, 246, 249, 250, 262, 263, 279, 287, 291, 292, 293, 294, 300, 303, 305, 313, 314, 318, 319, 376, 377, 381, 384, 387, 390, 395, 396 },
                    jobs = {"admin"} -- m_bodyArmor_badside
                },
                {
                    drawables = {253},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
                {
                    drawables = {306},
                    jobs = {"hightable"} -- shirts hightable
                },
                {
                    drawables = {289},
                    citizenids = {"IFE99613", "TWD32132"} -- lopez
                },
            },
            jackets = {
                {
                    drawables = {1494, 1521, 1522, 1523, 1524, 1525, 1526, 1527, 1528, 1529, 1530, 1531, 1532, 1541, 1542, 1550, 1551, 1552, 1553, 1556, 1557, 1558, 1559, 1560, 1564, 1565, 1566, 1567, 1568, 1569, 1574, 1575, 1577, 1578, 1579, 1585, 1586, 1587, 1589, 1590, 1596, 1598, 1599, 1600, 1654, 1663, 1664, 1665, 1717, 1718, 1744, 1748, 1752, 1754, 1766, 1767, 1776, 1782, 1783, 1784, 1807, 1859, 1862, 1895, 1904, 1905, 1920},
                    jobs = {"admin"} -- m_jackets in order: wd1, wd2, bz1, bz2, bmc1, bmc2, lfa1, lfa2, rb1, shinrai, ht1, ht2, bxd1, bxd2, brv1, brv2, gvr, bfl, gdp1, ggd1, cmc1, ls1, sdmc1, sdmc2, wtmc1, blackjack1-4, nexus1, heavenhell1, pam1, abyssal1-2, gehanom1-2, fleelinks1, gaviria1-2, crimsonreign1, kuroyama1, lmc1, omc1, babayo1, 
                },
                {
                    drawables = {1594},
                    citizenids = {"QPM15261", "IFE99613", "TWD32132"} -- jas gokong
                },
                {
                    drawables = {1611},
                    citizenids = {"MDE71750", "BOH88301", "IFE99613"} -- rialdynt
                },
                {
                    drawables = {1612, 1613, 1614, 1615, 1616, 1666, 1667, 1668, 1669, 1670, 1671, 1793, 1794},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
                {
                    drawables = {1621},
                    citizenids = {"QPM15261", "NAI99251"} -- Jas Inagawa
                },
                {
                    drawables = {1652},
                    citizenids = {"IFE99613", "TWD32132"} -- Kemeja lopez
                },
                {
                    drawables = {1693, 1746, 1850, 1868, 1869, 1870},
                    jobs = {"hightable"} -- jaket hightable
                },
                 {
                    drawables = {1696},
                    citizenids = {"LSI06116", "BJF18213"} -- Cheongsam Black Jckoy
                },
                {
                    drawables = {1709},
                    citizenids = {"SIN57419"} -- PekkoAndrea
                },
                {
                    drawables = {1713},
                    citizenids = {"HYE13461", "XII58730", "MZB13210"} -- kuntet jaket
                },
                {
                    drawables = {1742, 1743},
                    citizenids = {"IFE99613", "TWD32132"} -- lopez
                },
                {
                    drawables = {1781},
                    citizenids = {"HWE68240"} --wedding
                },
                {
                    drawables = {1876, 1901},
                    citizenids = {"DHD82795", "HCA96326"} --baju uby minta masukin
                },
                {
                    drawables = {1909},
                    jobs = {"gokudosm"} -- jaket gokudo
                },
                {
                    drawables = {1915},
                    citizenids = {"TDS73632"} --Justin Remedi
                },
                {
                    drawables = {1922},
                    citizenids = {"UKH61857"} --Naga
                },
                {
                    drawables = {1921, 1923, 1924},
                    jobs = {"admin"} -- Baju Admin SM
                },
            }
        },
        props = {
            hats = {
                {
                    drawables = {282, 288},
                    citizenids = {"NAI99251", "IFE99613"} --Helm AGV RYU     
                },
                {
                    drawables = {283, 305},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels 
                },
                  {
                    drawables = {292},
                    citizenids = {"NAI99251", "UKH61857"} --Helm AGV RYU,NAGA     
                },
                  {
                    drawables = {301, 302},
                    citizenids = {"TWD32132"} --Lopezhat  
                },
                  {
                    drawables = {303},
                    citizenids = {"LYY23858"} --Lopezhat  
                },
            },
            glasses = {},
            ear = {
                  {
                    drawables = {113, 114},
                    citizenids = {"TWD32132"} --Lopez Ears    
                },
                
            },
            watches = {},
            bracelets = {}
        }
    },

    female = {
        hair = {
            {
                drawables = { 1232, 1233, 1234, 1235, 1236, 1237 },
                citizenids = { "XHK74627", "YWX48857", "YFE44073" } --ruby
            },
            {
                drawables = { 1249 },
                citizenids = { "ONL70435" } --sunnybee
            },
            {
                drawables = { 1259, 1268 },
                citizenids = { "XUM58389" } --bianca
            },
            {
                drawables = { 1272 },
                citizenids = { "TSA35459" } --Qinara
            },
            {
                drawables = { 1280 },
                citizenids = { "FIT55983" } --Ebyla
            },
            {
                drawables = { 1289 },
                citizenids = { "OKY50523" } --Lalalili
            },
            {
                drawables = { 1293 },
                citizenids = { "ACJ98901" } --Aurelia
            },
            {
                drawables = { 1300, 1301 },
                citizenids = { "XUM58389" } --bianca
            },
            {
                drawables = { 1309 },
                citizenids = { "OTS82260" } --zeeva
            },
            {
                drawables = { 1313 },
                citizenids = { "YZT60845" } --caitlin
            },
            {
                drawables = { 1320 },
                citizenids = { "GEP86052", "IFE99613" } --Khara
            },
            {
                drawables = { 1335 },
                citizenids = { "RGK45908" } --Madeleine Campbell
            },
            {
                drawables = { 1341 },
                citizenids = { "IIK92723", "IFE99613" } --lele
            },
            {
                drawables = { 1345, 1346 },
                citizenids = { "HII69647" } --Avee
            },
            {
                drawables = { 1358 },
                citizenids = { "SCL89201" } --CRESENTIA
            },
            {
                drawables = { 1400 },
                citizenids = { "YFD28320", "MDA38825" } --Jura cintaku 
            },
            {
                drawables = { 1401 },
                citizenids = { "BJF26747" } --cacacui
            },
            {
                drawables = { 1413 },
                citizenids = { "YUX40781" } --KQA
            },
            {
                drawables = { 1420 },
                citizenids = { "YZT60845" } --CLEXIE NADELEINE
            },
            {
                drawables = { 1421, 1445, 1446 },
                citizenids = { "IFE99613", "YTZ08751", "YFE44073", "XFY62303" } --rambut kasya di lock pake cid niko
            },
            {
                drawables = { 1394 },
                citizenids = { "GXS66583" } --Lucien Leonette
            },
              {
                drawables = { 1447 },
                citizenids = { "YCD34293" } --Alexandra Leonora 
            },
             {
                drawables = { 1448 },
                citizenids = { "FIT55983" } --Ebyla
            },
              {
                drawables = { 1449 },
                citizenids = { "XAN56412" } --Onizuka Sayumi
            },
            {
                drawables = { 1450 },
                citizenids = { "IIK92723" } --lele
            },
             {
                drawables = { 1452 },
                citizenids = { "INV76207", "BJF18213" } --SkylerKarina
            },
            {
                drawables = { 1453 },
                citizenids = { "INV76207", "BJF18213" } --SkylerKarina
            },
            {
                drawables = { 1454 },
                citizenids = { "ITJ76693", "BJF18213" } --Nina Kim
            },
            {
                drawables = { 1455 },
                citizenids = { "GXS66583" } --Lucien
            },
            {
                drawables = { 1456 },
                citizenids = { "UKX79197" } --Casey Galahad
            },
            {
                drawables = { 1458 },
                citizenids = { "OMU72247" } --Brielle Moretti
            },
            {
                drawables = { 1459 },
                citizenids = { "QEA61718" } --Nuy Sunandar
            },
            {
                drawables = { 1463 },
                citizenids = { "QLX95539" } --lastreesha
            },
            {
                drawables = { 1464, 1465, 1466, 1467, 1468, 1469, 1470, 1471 },
                citizenids = { "QLV93122", "OPE11112", "IFE99613" } --ilaalang
            },
            {
                drawables = { 1472 },
                citizenids = { "GXS66583" } --Lucien Leonette
            },
            {
                drawables = { 1475 },
                citizenids = { "GJC10529" } --Belphys
            },
            {
                drawables = { 1477 },
                citizenids = { "JFW02000" } --Jiana Stacy
            },
            {
                drawables = { 1478, 1492 },
                citizenids = { "LMF41483", "YFE44073", "IFE99613" } --Kyona Debug
            },
             {
                drawables = { 1479, 1480, 1483 },
                citizenids = { "PRU38290" } --Ellena Gabriel
            },
             {
                drawables = { 1482 },
                citizenids = { "CJO49336" } --Cala Luna Inagawa
            },
             {
                drawables = { 1485 },
                citizenids = { "YCD34293" } --Tisya
            },
             {
                drawables = { 1486 },
                citizenids = { "RGK45908" } --madeleine 
            },
            {
                drawables = { 1488 },
                citizenids = { "SLK49095" } --Kaizel Rozelyn 
            },
            {
                drawables = { 1489, 1490 },
                citizenids = { "CJO49336" } --Cala Luna ( modra ) 
            },
            {
                drawables = { 1499 },
                citizenids = { "EGJ31409" } --Hanami Aishitera
            },
            {
                drawables = { 1444 },
                citizenids = { "YCD34293" } --Alexandra leonora H
            },
             {
                drawables = { 1505 },
                citizenids = { "ITJ76693" } --NINA KIM
            },
             {
                drawables = { 1510 },
                citizenids = { "EMS82340" } --meimei
            },
            {
                drawables = { 1511, 1512, 1513 },
                citizenids = { "NMB88607" } --Jeprass (streamer kyo)
            },
             {
                drawables = { 1515, 1516 },
                citizenids = { "GEP86052", "MZB13210" } --Khara Rylee
            },
            {
                drawables = { 1518 },
                citizenids = { "HNA46839" } --Bella Kitsune
            },
            {
                drawables = { 1522 },
                citizenids = { "FPB71284" } --Qaseh Buddy
            },
            {
                drawables = { 1527 },
                citizenids = { "HPB35756" } --Hyoona Eo
            },
            {
                drawables = { 1528, 1529, 1530, 1531 },
                citizenids = { "CJO49336" } --cala luna inagawa
            },
            {
                drawables = { 1532 },
                citizenids = { "KHS62054" } --Yin Flo La Baskerville
            },
            {
                drawables = { 1536 },
                citizenids = { "GXS66583" } --Yin Lou Xien L
            },
            {
                drawables = { 1537 },
                citizenids = { "YFE44073" } --DEBUGMODE KIYOWO
            },
            {
                drawables = { 1540 },
                citizenids = { "QCQ53829" } --Blue Berry Rex
            },
            {
                drawables = { 1541 },
                citizenids = { "ANI57990" } --Kyubi Claire C Rupawan
            },
            {
                drawables = { 1543 },
                citizenids = { "FKS88434" } --DEBUGMODE KIYOWO
            },
            {
                drawables = { 1544 },
                citizenids = { "HPB35756", "FOM20621" } --Hyoona Eo
            },
            {
                drawables = { 1545 },
                citizenids = { "HPB35756", "FOM20621" } --Hyoona Eo
            },
            {
                drawables = { 1549 },
                citizenids = { "BKZ34069", "FOM20621" } --Noirelle Horison
            },
          
          
        },
        components = {
            masks = {
                {
                    drawables = {407, 408},
                    jobs = {"admin"} -- masks_badside
                },
                {
                    drawables = {447},
                    jobs = {"hightable"} -- masker hightable
                },
            },
            upperBody = {
                {
                 drawables = { 285 },
                 citizenids = { "IFE99613", "PHB58375" } --baju nikahan omi
                },
            },
            lowerBody = {
                -- {
                --  drawables = { 233 },
                --  citizenids = { "IFE99613", "PHB58375" } --baju nikahan omi
                -- },
                {
                    drawables = {211, 212},
                    jobs = {"admin"} -- pants_badside
                },
                {
                    drawables = {214, 221, 222, 233},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
                {
                    drawables = {224, 245},
                    jobs = {"hightable"} -- pants hightable
                },
            },
            bags = {
				{
                    drawables = {486, 489, 491, 516},
                    jobs = {"admin"} -- bags_badside
                },
                {
                    drawables = {492},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
                {
                    drawables = {509},
                    citizenids = { "QLV93122", "OPE11112", "IFE99613" } --ilalang scarlett
                },
                {
                    drawables = {540},
                    jobs = {"hightable"} -- bags hightable
                },
			},
            shoes = {
                {
                    drawables = {478},
                    citizenids = { "OKY50523" } --Lalalili
                },
                {
                    drawables = {480},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
                {
                 drawables = { 486 },
                 citizenids = { "CJO49336" } --cala luna
                },
            },
            scarfAndChains = {
                {
                    drawables = {752, 828, 830},
                    jobs = {"admin"} -- teef_badside
                },
                {
                    drawables = {761},
                    jobs = {"hightable"} -- scarf and chains hightable
                },
                {
                    drawables = {765},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
            },
            shirts = {
                {
                    drawables = {1096},
                    jobs = {"admin"} -- f_shirts_rb
                },
                {
                    drawables = {1098, 1104, 1116},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
                {
                    drawables = {1105, 1145, 1146, 1147},
                    jobs = {"hightable"} -- shirts hightable
                },
            },
            bodyArmor = {
                {
                    drawables = {474, 475, 476, 477, 478, 481, 482, 483, 484, 485, 486, 487, 488, 492, 493, 494, 496, 499, 501, 502, 518, 519, 535, 542, 547, 550, 551, 552, 553, 559, 564, 567, 569, 570, 572, 579, 580, 585, 586, 651, 652, 658, 662, 668, 677, 678},
                    jobs = {"admin"} -- f_bodyArmor_wd1
                },
                {
                    drawables = {571},
                    jobs = {"hightable"} -- shirts hightable
                },
                {
                    drawables = {505},
                    citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
                {
                    drawables = {512, 516, 517},
                    citizenids = { "OPE11112", "IFE99613" } --babayo ilalang
                },
            },
            jackets = {
                {
                 drawables = { 2271 },
                 citizenids = { "IFE99613", "HTI83598", "OPE11112", "IIK92723" } --baju ilalang ipang icip bool
                },
                {
                 drawables = { 2165 },
                 citizenids = { "IFE99613", "PHB58375" } --baju nikahan omi
                },
                {
                 drawables = { 2167, 2180 },
                 citizenids = { "IFE99613", "IIK92723", "MZB13210", "OKY50523" } --baju nikahan bool
                },
                {
                 drawables = { 402 },
                 citizenids = { "IFE99613", "MDA38825" } --baju kasya di lock pake cid niko
                },
                {
                    drawables = {1916, 1943, 1944, 1945, 1946, 1947, 1948, 1949, 1950, 1951, 1952, 1953, 1954, 1963, 1964, 1973, 1974, 1975, 1976, 1979, 1980, 1981, 1982, 1983, 1987, 1988, 1989, 1990, 1991, 1992, 1999, 2000, 2001, 2002, 2003, 2009, 2010, 2011, 2012, 2016, 2018, 2019, 2020, 2076, 2077, 2131, 2132, 2151, 2156, 2157, 2170, 2171, 2179, 2185, 2186, 2216, 2261, 2264, 2290, 2298, 2309 },
                    jobs = {"admin"} -- f_jackets in order: wd1, wd2, bz1, bz2, bmc1, bmc2, lfa1, lfa2, rb1, shinrai, ht1, ht2, bxd1, bxd2, brv1, brv2, gvr, bfl, gdp1, ggd1, cmc1, ls1, sdmc1, sdmc2, wtmc1, blackjack1-4, nexus1, heavenhell1, pam1, abyssal1-2, gehanom1-2, fleelinks1, gaviria1, crimsonreign1, kuroyama1, lmc1, omc1, 
                },
                {
                 drawables = { 1997 },
                 citizenids = { "XHK74627", "YWX48857", "YFE44073",  "IIK92723" } --ruby
                },
                {
                 drawables = { 2031, 2032, 2033, 2034, 2035, 2078, 2079, 2080, 2081, 2082, 2083, 2201, 2202 },
                 citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
                {
                 drawables = { 2058 },
                 citizenids = { "OPE11112", "IFE99613" } --babayo ilalang
                },
                {
                    drawables = {2110, 2152, 2255, 2268, 2269, 2270},
                    jobs = {"hightable"} -- jaket hightable
                },
                 {
                 drawables = { 2112 },
                 citizenids = { "YZT60845", "OKY50523","BJF18213","HZS89106" } --Black Lala Clexie Bea
                },
                 {
                 drawables = { 2123 },
                 citizenids = { "YZT60845" } --CLEXIE NAEZANI BLACK
                },
                {
                 drawables = { 2183, 2184 },
                 citizenids = { "CJO49336" } --wedding
                },
                {
                 drawables = { 2198, 2199, 2200, 2252, 2253, 2254 },
                 citizenids = { "CJO49336" } --cala luna pregnant
                },
                {
                 drawables = { 2272 },
                 citizenids = { "EGJ31409" } --Hanami Aishitera Oishi bumil
                },
                {
                    drawables = {2304},
                    jobs = {"gokudosm"} -- jaket gokudo
                },
                {
                    drawables = {2310, 2311, 2312},
                    jobs = {"admin"} -- Baju Admin SM
                },
            }
        },
        props = {
            hats = {
                {
                 drawables = { 186, 203 },
                 citizenids = {"IFE99613", "YFE44073", "NEL29196", "DVT91172", "VEF86682", "TDG45936", "KRL54282", "RDC02147", "XHK74627", "OKY50523", "DQO27280", "IJY57834", "HYE13461", "XII58730", "MZB13210", "UFX24035", "NQY29028", "OYW99923", "HTI83598", "OPE11112", "IIK92723", "UNT38874", "URR85998", "PUE70997" } -- Baju Roels
                },
                {
                 drawables = { 202 },
                 citizenids = { "IFE99613", "IIK92723" } --baju bool
                },
            },
            glasses = {},
            ear = {},
            watches = {},
            bracelets = {}
        }
    }
}
