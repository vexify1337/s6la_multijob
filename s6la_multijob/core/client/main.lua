local is_open = false
local framework = nil
local qb_core = nil
local esx = nil
local last_job_name = nil

CreateThread(function()
    Wait(1000)
    if GetResourceState('qb-core') == 'started' then
        framework = 'qb-core'
        qb_core = exports['qb-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        framework = 'es_extended'
        esx = exports['es_extended']:getSharedObject()
    end
end)

function show_notification(message, type)
    if framework == 'qb-core' then
        TriggerEvent('QBCore:Notify', message, type or 'primary', 5000)
    elseif framework == 'es_extended' then
        TriggerEvent('esx:showNotification', message)
    end
end

function get_current_job()
    if framework == 'qb-core' then
        local player_data = qb_core.Functions.GetPlayerData()
        if player_data and player_data.job then
            return {
                name = player_data.job.name,
                label = player_data.job.label,
                grade = player_data.job.grade.level,
                grade_label = player_data.job.grade.name,
                salary = player_data.job.payment or 0
            }
        end
    elseif framework == 'es_extended' then
        local x_player = esx.GetPlayerData()
        if x_player and x_player.job then
            return {
                name = x_player.job.name,
                label = x_player.job.label,
                grade = x_player.job.grade,
                grade_label = x_player.job.grade_label,
                salary = x_player.job.grade_salary or 0
            }
        end
    end
    return nil
end

function on_job_set(job)
    if not job or not job.name then return end
    
    if last_job_name and last_job_name ~= 'unemployed' then
        if job.name == 'unemployed' then
            CreateThread(function()
                Wait(200)
                TriggerServerEvent('s6la_multijob:job_switched', last_job_name, job.name)
            end)
        elseif last_job_name ~= job.name then
            CreateThread(function()
                Wait(200)
                TriggerServerEvent('s6la_multijob:job_switched', last_job_name, job.name)
            end)
        end
    end
    
    last_job_name = job.name
    
    if is_open then
        TriggerServerEvent('s6la_multijob:get_jobs')
    end
end

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job_info)
    on_job_set(job_info)
end)

RegisterNetEvent('esx:setJob', function(job)
    on_job_set(job)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local job = get_current_job()
    if job then
        last_job_name = job.name
        if job.name and job.name ~= 'unemployed' then
            Wait(2000)
            TriggerServerEvent('s6la_multijob:player_loaded', job.name)
        end
    end
end)

RegisterNetEvent('esx:playerLoaded', function(x_player)
    if x_player and x_player.job then
        last_job_name = x_player.job.name
        if x_player.job.name and x_player.job.name ~= 'unemployed' then
            Wait(2000)
            TriggerServerEvent('s6la_multijob:player_loaded', x_player.job.name)
        end
    end
end)

RegisterNetEvent('s6la_multijob:open_ui', function()
    if is_open then
        is_open = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = 'close'
        })
        return
    end
    is_open = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'open',
        jobIcons = Config.job_icons
    })
    Wait(100)
    TriggerServerEvent('s6la_multijob:get_jobs')
end)


RegisterNetEvent('s6la_multijob:update_ui', function(jobs, current_job, job_icons)
    SendNUIMessage({
        action = 'updateJobs',
        jobs = jobs,
        currentJob = current_job,
        jobIcons = job_icons
    })
end)

RegisterNetEvent('s6la_multijob:notify', function(message, type)
    show_notification(message, type)
end)

RegisterNUICallback('close', function(data, cb)
    is_open = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'close'
    })
    cb('ok')
end)

RegisterNUICallback('selectJob', function(data, cb)
    TriggerServerEvent('s6la_multijob:select_job', data.job)
    cb('ok')
end)

RegisterNUICallback('removeJob', function(data, cb)
    TriggerServerEvent('s6la_multijob:remove_job', data.job)
    cb('ok')
end)
-- dont ask why i did this... we had some react issues and we love react being react...
RegisterNUICallback('error', function(data, cb)
    if data and data.message then
        print('^1[NUI Error]^7 ' .. tostring(data.message))
        if data.stack then
            print('^1[Stack]^7 ' .. tostring(data.stack))
        end
        if data.file then
            print('^1[File]^7 ' .. tostring(data.file))
        end
        if data.line then
            print('^1[Line]^7 ' .. tostring(data.line))
        end
    end
    cb('ok')
end)

RegisterCommand(Config.command, function()
    TriggerEvent('s6la_multijob:open_ui')
end, false)

RegisterKeyMapping(Config.command, 'Open MultiJob Menu', 'keyboard', 'F9')

