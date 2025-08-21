//
//  Locations.swift
//  TucikMap
//
//  Created by Artem on 8/21/25.
//

enum Locations {
    case abkhazia
    case afghanistan
    case alandIslands
    case albania
    case algeria
    case americanSamoa
    case andorra
    case angola
    case anguilla
    case antarctica
    case antiguaAndBarbuda
    case argentina
    case armenia
    case aruba
    case australia
    case austria
    case azerbaijan
    case bahamas
    case bahrain
    case bangladesh
    case barbados
    case belarus
    case belgium
    case belize
    case benin
    case bermuda
    case bhutan
    case bolivia
    case bosniaAndHerzegovina
    case botswana
    case bouvetIsland
    case brazil
    case britishIndianOceanTerritory
    case britishVirginIslands
    case brunei
    case bulgaria
    case burkinaFaso
    case burundi
    case cambodia
    case cameroon
    case canada
    case capeVerde
    case caymanIslands
    case centralAfricanRepublic
    case chad
    case chile
    case china
    case christmasIsland
    case cocosKeelingIslands
    case colombia
    case comoros
    case congoDRC
    case congoRepublic
    case cookIslands
    case costaRica
    case coteDIvoire
    case croatia
    case cuba
    case curacao
    case cyprus
    case czechRepublic
    case denmark
    case djibouti
    case dominica
    case dominicanRepublic
    case eastTimor
    case ecuador
    case egypt
    case elSalvador
    case equatorialGuinea
    case eritrea
    case estonia
    case ethiopia
    case falklandIslands
    case faroeIslands
    case fiji
    case finland
    case france
    case frenchGuiana
    case frenchPolynesia
    case gabon
    case gambia
    case georgia
    case germany
    case ghana
    case gibraltar
    case greece
    case greenland
    case grenada
    case guadeloupe
    case guam
    case guatemala
    case guernsey
    case guinea
    case guineaBissau
    case guyana
    case haiti
    case honduras
    case hongKong
    case hungary
    case iceland
    case india
    case indonesia
    case iran
    case iraq
    case ireland
    case isleOfMan
    case israel
    case italy
    case jamaica
    case japan
    case jersey
    case jordan
    case kazakhstan
    case kenya
    case kiribati
    case kosovo
    case kuwait
    case kyrgyzstan
    case laos
    case latvia
    case lebanon
    case lesotho
    case liberia
    case libya
    case liechtenstein
    case lithuania
    case luxembourg
    case macedoniaFYROM
    case madagascar
    case malawi
    case malaysia
    case maldives
    case mali
    case malta
    case marshallIslands
    case martinique
    case mauritania
    case mauritius
    case mayotte
    case mexico
    case micronesia
    case moldova
    case monaco
    case mongolia
    case montenegro
    case montserrat
    case morocco
    case mozambique
    case myanmarBurma
    case nagornoKarabakhRepublic
    case namibia
    case nauru
    case nepal
    case netherlands
    case netherlandsAntilles
    case newCaledonia
    case newZealand
    case nicaragua
    case niger
    case nigeria
    case niue
    case norfolkIsland
    case northKorea
    case northernCyprus
    case northernMarianaIslands
    case norway
    case oman
    case pakistan
    case palau
    case palestine
    case panama
    case papuaNewGuinea
    case paraguay
    case peru
    case philippines
    case pitcairnIslands
    case poland
    case portugal
    case puertoRico
    case qatar
    case reunion
    case romania
    case russia
    case rwanda
    case samoa
    case sanMarino
    case saoTomeAndPrincipe
    case saudiArabia
    case senegal
    case serbia
    case seychelles
    case sierraLeone
    case singapore
    case slovakia
    case slovenia
    case solomonIslands
    case somalia
    case southAfrica
    case southGeorgiaAndTheSouthSandwichIslands
    case southKorea
    case southOssetia
    case southSudan
    case spain
    case sriLanka
    case stBarthelemy
    case stKittsAndNevis
    case stLucia
    case stMartin
    case sudan
    case suriname
    case svalbardAndJanMayen
    case swaziland
    case sweden
    case switzerland
    case syria
    case taiwan
    case tajikistan
    case tanzania
    case thailand
    case timorLeste
    case togo
    case tokelau
    case tonga
    case transnistria
    case trinidadAndTobago
    case tristanDaCunha
    case tunisia
    case turkey
    case turkmenistan
    case turksAndCaicosIslands
    case tuvalu
    case usVirginIslands
    case uganda
    case ukraine
    case unitedArabEmirates
    case unitedKingdom
    case unitedStates
    case uruguay
    case uzbekistan
    case vanuatu
    case vaticanCity
    case venezuela
    case vietnam
    case wallisAndFutuna
    case westernSahara
    case yemen
    case zambia
    case zimbabwe

    var coordinate: SIMD2<Double> {
        switch self {
        case .abkhazia: return SIMD2(43.001525, 41.023415)
        case .afghanistan: return SIMD2(34.575503, 69.240073)
        case .alandIslands: return SIMD2(60.1, 19.933333)
        case .albania: return SIMD2(41.327546, 19.818698)
        case .algeria: return SIMD2(36.752887, 3.042048)
        case .americanSamoa: return SIMD2(-14.275632, -170.702036)
        case .andorra: return SIMD2(42.506317, 1.521835)
        case .angola: return SIMD2(-8.839988, 13.289437)
        case .anguilla: return SIMD2(18.214813, -63.057441)
        case .antarctica: return SIMD2(-90, 0)
        case .antiguaAndBarbuda: return SIMD2(17.12741, -61.846772)
        case .argentina: return SIMD2(-34.603684, -58.381559)
        case .armenia: return SIMD2(40.179186, 44.499103)
        case .aruba: return SIMD2(12.509204, -70.008631)
        case .australia: return SIMD2(-35.282, 149.128684)
        case .austria: return SIMD2(48.208174, 16.373819)
        case .azerbaijan: return SIMD2(40.409262, 49.867092)
        case .bahamas: return SIMD2(25.047984, -77.355413)
        case .bahrain: return SIMD2(26.228516, 50.58605)
        case .bangladesh: return SIMD2(23.810332, 90.412518)
        case .barbados: return SIMD2(13.113222, -59.598809)
        case .belarus: return SIMD2(53.90454, 27.561524)
        case .belgium: return SIMD2(50.85034, 4.35171)
        case .belize: return SIMD2(17.251011, -88.75902)
        case .benin: return SIMD2(6.496857, 2.628852)
        case .bermuda: return SIMD2(32.294816, -64.781375)
        case .bhutan: return SIMD2(27.472792, 89.639286)
        case .bolivia: return SIMD2(-16.489689, -68.119294)
        case .bosniaAndHerzegovina: return SIMD2(43.856259, 18.413076)
        case .botswana: return SIMD2(-24.628208, 25.923147)
        case .bouvetIsland: return SIMD2(-54.43, 3.38)
        case .brazil: return SIMD2(-15.794229, -47.882166)
        case .britishIndianOceanTerritory: return SIMD2(21.3419, 55.4778)
        case .britishVirginIslands: return SIMD2(18.428612, -64.618466)
        case .brunei: return SIMD2(4.903052, 114.939821)
        case .bulgaria: return SIMD2(42.697708, 23.321868)
        case .burkinaFaso: return SIMD2(12.371428, -1.51966)
        case .burundi: return SIMD2(-3.361378, 29.359878)
        case .cambodia: return SIMD2(11.544873, 104.892167)
        case .cameroon: return SIMD2(3.848033, 11.502075)
        case .canada: return SIMD2(45.42153, -75.697193)
        case .capeVerde: return SIMD2(14.93305, -23.513327)
        case .caymanIslands: return SIMD2(19.286932, -81.367439)
        case .centralAfricanRepublic: return SIMD2(4.394674, 18.55819)
        case .chad: return SIMD2(12.134846, 15.055742)
        case .chile: return SIMD2(-33.44889, -70.669265)
        case .china: return SIMD2(39.904211, 116.407395)
        case .christmasIsland: return SIMD2(-10.420686, 105.679379)
        case .cocosKeelingIslands: return SIMD2(-12.188834, 96.829316)
        case .colombia: return SIMD2(4.710989, -74.072092)
        case .comoros: return SIMD2(-11.717216, 43.247315)
        case .congoDRC: return SIMD2(-4.441931, 15.266293)
        case .congoRepublic: return SIMD2(-4.26336, 15.242885)
        case .cookIslands: return SIMD2(-21.212901, -159.782306)
        case .costaRica: return SIMD2(9.928069, -84.090725)
        case .coteDIvoire: return SIMD2(6.827623, -5.289343)
        case .croatia: return SIMD2(45.815011, 15.981919)
        case .cuba: return SIMD2(23.05407, -82.345189)
        case .curacao: return SIMD2(12.1091242, -68.9316546)
        case .cyprus: return SIMD2(35.185566, 33.382276)
        case .czechRepublic: return SIMD2(50.075538, 14.4378)
        case .denmark: return SIMD2(55.676097, 12.568337)
        case .djibouti: return SIMD2(11.825138, 42.590275)
        case .dominica: return SIMD2(15.309168, -61.379355)
        case .dominicanRepublic: return SIMD2(18.486058, -69.931212)
        case .eastTimor: return SIMD2(-8.556856, 125.560314)
        case .ecuador: return SIMD2(-0.180653, -78.467838)
        case .egypt: return SIMD2(30.04442, 31.235712)
        case .elSalvador: return SIMD2(13.69294, -89.218191)
        case .equatorialGuinea: return SIMD2(3.750412, 8.737104)
        case .eritrea: return SIMD2(15.322877, 38.925052)
        case .estonia: return SIMD2(59.436961, 24.753575)
        case .ethiopia: return SIMD2(8.980603, 38.757761)
        case .falklandIslands: return SIMD2(-51.796253, -59.523613)
        case .faroeIslands: return SIMD2(62.007864, -7.075533)
        case .fiji: return SIMD2(-18.124809, 178.450079)
        case .finland: return SIMD2(60.169856, 24.938379)
        case .france: return SIMD2(48.856614, 2.352222)
        case .frenchGuiana: return SIMD2(4.92242, -52.313453)
        case .frenchPolynesia: return SIMD2(-17.535326, -149.569595)
        case .gabon: return SIMD2(0.416198, 9.467268)
        case .gambia: return SIMD2(13.454876, -16.579032)
        case .georgia: return SIMD2(41.715138, 44.827096)
        case .germany: return SIMD2(52.520007, 13.404954)
        case .ghana: return SIMD2(5.603717, -0.186964)
        case .gibraltar: return SIMD2(36.140773, -5.353599)
        case .greece: return SIMD2(37.983917, 23.72936)
        case .greenland: return SIMD2(64.18141, -51.694138)
        case .grenada: return SIMD2(12.056098, -61.7488)
        case .guadeloupe: return SIMD2(16.014453, -61.706411)
        case .guam: return SIMD2(13.470891, 144.751278)
        case .guatemala: return SIMD2(14.634915, -90.506882)
        case .guernsey: return SIMD2(49.455443, -2.536871)
        case .guinea: return SIMD2(9.641185, -13.578401)
        case .guineaBissau: return SIMD2(11.881655, -15.617794)
        case .guyana: return SIMD2(6.801279, -58.155125)
        case .haiti: return SIMD2(18.594395, -72.307433)
        case .honduras: return SIMD2(14.072275, -87.192136)
        case .hongKong: return SIMD2(22.396428, 114.109497)
        case .hungary: return SIMD2(47.497912, 19.040235)
        case .iceland: return SIMD2(64.126521, -21.817439)
        case .india: return SIMD2(28.613939, 77.209021)
        case .indonesia: return SIMD2(-6.208763, 106.845599)
        case .iran: return SIMD2(35.689198, 51.388974)
        case .iraq: return SIMD2(33.312806, 44.361488)
        case .ireland: return SIMD2(53.349805, -6.26031)
        case .isleOfMan: return SIMD2(54.152337, -4.486123)
        case .israel: return SIMD2(32.0853, 34.781768)
        case .italy: return SIMD2(41.902784, 12.496366)
        case .jamaica: return SIMD2(18.042327, -76.802893)
        case .japan: return SIMD2(35.709026, 139.731992)
        case .jersey: return SIMD2(49.186823, -2.106568)
        case .jordan: return SIMD2(31.956578, 35.945695)
        case .kazakhstan: return SIMD2(51.160523, 71.470356)
        case .kenya: return SIMD2(-1.292066, 36.821946)
        case .kiribati: return SIMD2(1.451817, 172.971662)
        case .kosovo: return SIMD2(42.662914, 21.165503)
        case .kuwait: return SIMD2(29.375859, 47.977405)
        case .kyrgyzstan: return SIMD2(42.874621, 74.569762)
        case .laos: return SIMD2(17.975706, 102.633104)
        case .latvia: return SIMD2(56.949649, 24.105186)
        case .lebanon: return SIMD2(33.888629, 35.495479)
        case .lesotho: return SIMD2(-29.363219, 27.51436)
        case .liberia: return SIMD2(6.290743, -10.760524)
        case .libya: return SIMD2(32.887209, 13.191338)
        case .liechtenstein: return SIMD2(47.14103, 9.520928)
        case .lithuania: return SIMD2(54.687156, 25.279651)
        case .luxembourg: return SIMD2(49.611621, 6.131935)
        case .macedoniaFYROM: return SIMD2(41.997346, 21.427996)
        case .madagascar: return SIMD2(-18.87919, 47.507905)
        case .malawi: return SIMD2(-13.962612, 33.774119)
        case .malaysia: return SIMD2(3.139003, 101.686855)
        case .maldives: return SIMD2(4.175496, 73.509347)
        case .mali: return SIMD2(12.639232, -8.002889)
        case .malta: return SIMD2(35.898909, 14.514553)
        case .marshallIslands: return SIMD2(7.116421, 171.185774)
        case .martinique: return SIMD2(14.616065, -61.05878)
        case .mauritania: return SIMD2(18.07353, -15.958237)
        case .mauritius: return SIMD2(-20.166896, 57.502332)
        case .mayotte: return SIMD2(-12.780949, 45.227872)
        case .mexico: return SIMD2(19.432608, -99.133208)
        case .micronesia: return SIMD2(6.914712, 158.161027)
        case .moldova: return SIMD2(47.010453, 28.86381)
        case .monaco: return SIMD2(43.737411, 7.420816)
        case .mongolia: return SIMD2(47.886399, 106.905744)
        case .montenegro: return SIMD2(42.43042, 19.259364)
        case .montserrat: return SIMD2(16.706523, -62.215738)
        case .morocco: return SIMD2(33.97159, -6.849813)
        case .mozambique: return SIMD2(-25.891968, 32.605135)
        case .myanmarBurma: return SIMD2(19.763306, 96.07851)
        case .nagornoKarabakhRepublic: return SIMD2(39.826385, 46.763595)
        case .namibia: return SIMD2(-22.560881, 17.065755)
        case .nauru: return SIMD2(-0.546686, 166.921091)
        case .nepal: return SIMD2(27.717245, 85.323961)
        case .netherlands: return SIMD2(52.370216, 4.895168)
        case .netherlandsAntilles: return SIMD2(12.1091242, -68.9316546)
        case .newCaledonia: return SIMD2(-22.255823, 166.450524)
        case .newZealand: return SIMD2(-41.28646, 174.776236)
        case .nicaragua: return SIMD2(12.114993, -86.236174)
        case .niger: return SIMD2(13.511596, 2.125385)
        case .nigeria: return SIMD2(9.076479, 7.398574)
        case .niue: return SIMD2(-19.055371, -169.917871)
        case .norfolkIsland: return SIMD2(-29.056394, 167.959588)
        case .northKorea: return SIMD2(39.039219, 125.762524)
        case .northernCyprus: return SIMD2(35.185566, 33.382276)
        case .northernMarianaIslands: return SIMD2(15.177801, 145.750967)
        case .norway: return SIMD2(59.913869, 10.752245)
        case .oman: return SIMD2(23.58589, 58.405923)
        case .pakistan: return SIMD2(33.729388, 73.093146)
        case .palau: return SIMD2(7.500384, 134.624289)
        case .palestine: return SIMD2(31.9073509, 35.5354719)
        case .panama: return SIMD2(9.101179, -79.402864)
        case .papuaNewGuinea: return SIMD2(-9.4438, 147.180267)
        case .paraguay: return SIMD2(-25.26374, -57.575926)
        case .peru: return SIMD2(-12.046374, -77.042793)
        case .philippines: return SIMD2(14.599512, 120.98422)
        case .pitcairnIslands: return SIMD2(-25.06629, -130.100464)
        case .poland: return SIMD2(52.229676, 21.012229)
        case .portugal: return SIMD2(38.722252, -9.139337)
        case .puertoRico: return SIMD2(18.466334, -66.105722)
        case .qatar: return SIMD2(25.285447, 51.53104)
        case .reunion: return SIMD2(-20.882057, 55.450675)
        case .romania: return SIMD2(44.426767, 26.102538)
        case .russia: return SIMD2(55.755826, 37.6173)
        case .rwanda: return SIMD2(-1.957875, 30.112735)
        case .samoa: return SIMD2(-13.850696, -171.751355)
        case .sanMarino: return SIMD2(43.935591, 12.447281)
        case .saoTomeAndPrincipe: return SIMD2(0.330192, 6.733343)
        case .saudiArabia: return SIMD2(24.749403, 46.902838)
        case .senegal: return SIMD2(14.764504, -17.366029)
        case .serbia: return SIMD2(44.786568, 20.448922)
        case .seychelles: return SIMD2(-4.619143, 55.451315)
        case .sierraLeone: return SIMD2(8.465677, -13.231722)
        case .singapore: return SIMD2(1.280095, 103.850949)
        case .slovakia: return SIMD2(48.145892, 17.107137)
        case .slovenia: return SIMD2(46.056947, 14.505751)
        case .solomonIslands: return SIMD2(-9.445638, 159.9729)
        case .somalia: return SIMD2(2.046934, 45.318162)
        case .southAfrica: return SIMD2(-25.747868, 28.229271)
        case .southGeorgiaAndTheSouthSandwichIslands: return SIMD2(-54.28325, -36.493735)
        case .southKorea: return SIMD2(37.566535, 126.977969)
        case .southOssetia: return SIMD2(42.22146, 43.964405)
        case .southSudan: return SIMD2(4.859363, 31.57125)
        case .spain: return SIMD2(40.416775, -3.70379)
        case .sriLanka: return SIMD2(6.89407, 79.902478)
        case .stBarthelemy: return SIMD2(17.896435, -62.852201)
        case .stKittsAndNevis: return SIMD2(17.302606, -62.717692)
        case .stLucia: return SIMD2(14.010109, -60.987469)
        case .stMartin: return SIMD2(18.067519, -63.082466)
        case .sudan: return SIMD2(15.500654, 32.559899)
        case .suriname: return SIMD2(5.852036, -55.203828)
        case .svalbardAndJanMayen: return SIMD2(78.062, 22.055)
        case .swaziland: return SIMD2(-26.305448, 31.136672)
        case .sweden: return SIMD2(59.329323, 18.068581)
        case .switzerland: return SIMD2(46.947974, 7.447447)
        case .syria: return SIMD2(33.513807, 36.276528)
        case .taiwan: return SIMD2(25.032969, 121.565418)
        case .tajikistan: return SIMD2(38.559772, 68.787038)
        case .tanzania: return SIMD2(-6.162959, 35.751607)
        case .thailand: return SIMD2(13.756331, 100.501765)
        case .timorLeste: return SIMD2(-8.556856, 125.560314)
        case .togo: return SIMD2(6.172497, 1.231362)
        case .tokelau: return SIMD2(-9.2005, -171.848)
        case .tonga: return SIMD2(-21.139342, -175.204947)
        case .transnistria: return SIMD2(46.848185, 29.596805)
        case .trinidadAndTobago: return SIMD2(10.654901, -61.501926)
        case .tristanDaCunha: return SIMD2(-37.068042, -12.311315)
        case .tunisia: return SIMD2(36.806495, 10.181532)
        case .turkey: return SIMD2(39.933364, 32.859742)
        case .turkmenistan: return SIMD2(37.960077, 58.326063)
        case .turksAndCaicosIslands: return SIMD2(21.467458, -71.13891)
        case .tuvalu: return SIMD2(-8.520066, 179.198128)
        case .usVirginIslands: return SIMD2(18.3419, -64.930701)
        case .uganda: return SIMD2(0.347596, 32.58252)
        case .ukraine: return SIMD2(50.4501, 30.5234)
        case .unitedArabEmirates: return SIMD2(24.299174, 54.697277)
        case .unitedKingdom: return SIMD2(51.507351, -0.127758)
        case .unitedStates: return SIMD2(38.907192, -77.036871)
        case .uruguay: return SIMD2(-34.901113, -56.164531)
        case .uzbekistan: return SIMD2(41.299496, 69.240073)
        case .vanuatu: return SIMD2(-17.733251, 168.327325)
        case .vaticanCity: return SIMD2(41.902916, 12.453389)
        case .venezuela: return SIMD2(10.480594, -66.903606)
        case .vietnam: return SIMD2(21.027764, 105.83416)
        case .wallisAndFutuna: return SIMD2(-13.282509, -176.176447)
        case .westernSahara: return SIMD2(27.153611, -13.203333)
        case .yemen: return SIMD2(15.369445, 44.191007)
        case .zambia: return SIMD2(-15.387526, 28.322816)
        case .zimbabwe: return SIMD2(-17.825166, 31.03351)
        }
    }
}
