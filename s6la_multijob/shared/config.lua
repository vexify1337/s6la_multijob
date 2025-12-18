Config = {}

Config.frameworks = {
    qb_core = 'qb-core',
    es_extended = 'es_extended'
}

Config.detection_delay = 100

Config.command = 'multijob'


-- just the icons that sit next to the job name in the ui so if you have more jobs add them here, find the right thing here  https://fontawesome.com/icons
Config.job_icons = {
    ['unemployed'] = 'fa-user-slash',
    ['police'] = 'fa-shield-halved',
    ['mechanic'] = 'fa-wrench',
    ['trucker'] = 'fa-truck',
    ['ambulance'] = 'fa-truck-medical',
    ['taxi'] = 'fa-taxi',
    ['lawyer'] = 'fa-gavel',
    ['reporter'] = 'fa-microphone',
    ['realestate'] = 'fa-house'
}
