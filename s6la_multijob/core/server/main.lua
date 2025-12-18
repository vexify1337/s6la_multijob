local qb_core = nil
local esx = nil
local framework = nil

local webhook = "discord.com/api/webhooks/blabalala"

function get_player_name(source)
    if framework == 'qb-core' then
        local player = qb_core.Functions.GetPlayer(source)
        if player then
            return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        end
    elseif framework == 'es_extended' then
        local x_player = esx.GetPlayerFromId(source)
        if x_player then
            return x_player.getName()
        end
    end
    return 'Unknown'
end

function send_webhook_log(source, action, details, color)
   
    if not webhook then
        print('^1[s6la_multijob]^7 Webhook is not set')
        return
    end
    
    local player_name = get_player_name(source)
    local identifier = get_player_identifier(source)
    
    local embed = {
        {
            ["title"] = "MultiJob - " .. action,
            ["description"] = details,
            ["type"] = "rich",
            ["color"] = color or 3447003,
            ["fields"] = {
                {
                    ["name"] = "Player",
                    ["value"] = player_name .. " (" .. identifier .. ")",
                    ["inline"] = true
                },
                {
                    ["name"] = "Server ID",
                    ["value"] = tostring(source),
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "s6la_multijob",
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = "MultiJob System",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

function log_action(source, action, details, color)
    local player_name = get_player_name(source)
    local identifier = get_player_identifier(source)
    print(string.format('^3[s6la_multijob]^7 [%s] %s - %s (ID: %s)', player_name, action, details, identifier))
    send_webhook_log(source, action, details, color)
end


CreateThread(function()
    Wait(Config.detection_delay)
    if GetResourceState(Config.frameworks.qb_core) == 'started' then
        framework = 'qb-core'
        qb_core = exports[Config.frameworks.qb_core]:GetCoreObject()
    elseif GetResourceState(Config.frameworks.es_extended) == 'started' then
        framework = 'es_extended'
        esx = exports[Config.frameworks.es_extended]:getSharedObject()
    end
end)

function get_player_identifier(source)
    if framework == 'qb-core' then
        local player = qb_core.Functions.GetPlayer(source)
        if player then
            return player.PlayerData.citizenid
        end
    elseif framework == 'es_extended' then
        local x_player = esx.GetPlayerFromId(source)
        if x_player then
            return x_player.identifier
        end
    end
    return nil
end


function get_player_job(source)
    if framework == 'qb-core' then
        local player = qb_core.Functions.GetPlayer(source)
        if player then
            local job = player.PlayerData.job
            return {
                name = job.name,
                label = job.label,
                grade = job.grade.level,
                grade_label = job.grade.name,
                salary = job.payment or 0
            }
        end
    elseif framework == 'es_extended' then
        local x_player = esx.GetPlayerFromId(source)
        if x_player then
            local job = x_player.job
            return {
                name = job.name,
                label = job.label,
                grade = job.grade,
                grade_label = job.grade_label,
                salary = job.grade_salary or 0
            }
        end
    end
    return nil
end

function set_player_job(source, job_name, grade)
    if framework == 'qb-core' then
        if qb_core then
            local player = qb_core.Functions.GetPlayer(source)
            if player then
                player.Functions.SetJob(job_name, grade)
            end
        end
    elseif framework == 'es_extended' then
        if esx then
            local x_player = esx.GetPlayerFromId(source)
            if x_player then
                x_player.setJob(job_name, grade)
            end
        end
    end
end


function auto_add_job(source, job_name, job_grade)
    if not job_name or job_name == 'unemployed' then return false end
    
    local identifier = get_player_identifier(source)
    if not identifier then return false end
    
    local exists = MySQL.query.await('SELECT id FROM s6la_multijob WHERE identifier = ? AND job_name = ?', {identifier, job_name})
    if exists and #exists > 0 then
        if job_grade then
            MySQL.query('UPDATE s6la_multijob SET grade = ?, grade_label = ?, salary = ? WHERE identifier = ? AND job_name = ?', {
                job_grade.grade,
                job_grade.grade_label or '',
                job_grade.salary or 0,
                identifier,
                job_name
            })
        end
        return true
    end
    
    local current_job = get_player_job(source)
    local grade_to_save = 0
    local grade_label_to_save = ''
    local salary_to_save = 0
    
    if job_grade then
        grade_to_save = job_grade.grade or 0
        grade_label_to_save = job_grade.grade_label or ''
        salary_to_save = job_grade.salary or 0
    elseif current_job and current_job.name == job_name then
        grade_to_save = current_job.grade or 0
        grade_label_to_save = current_job.grade_label or ''
        salary_to_save = current_job.salary or 0
    else
        salary_to_save = 0
    end
    
    local job_label = job_name
    if framework == 'qb-core' then
        if qb_core and qb_core.Shared and qb_core.Shared.Jobs then
            local job_config = qb_core.Shared.Jobs[job_name]
            if job_config then
                job_label = job_config.label or job_name
            end
        end
    elseif framework == 'es_extended' then
        if esx then
            local job_config = ESX.GetJobs()[job_name]
            if job_config then
                job_label = job_config.label or job_name
            end
        end
    end
    
    MySQL.insert('INSERT INTO s6la_multijob (identifier, job_name, job_label, grade, grade_label, salary) VALUES (?, ?, ?, ?, ?, ?)', {
        identifier,
        job_name,
        job_label,
        grade_to_save,
        grade_label_to_save,
        salary_to_save
    })
    log_action(source, 'JOB_ADDED', string.format('Job: %s (%s) | Grade: %s (%d)', job_label, job_name, grade_label_to_save, grade_to_save), 3066993)
    return true
end

RegisterNetEvent('s6la_multijob:get_jobs', function(source_param)
    local source = source_param or source
    local identifier = get_player_identifier(source)
    if not identifier then return end

    local jobs = MySQL.query.await('SELECT * FROM s6la_multijob WHERE identifier = ?', {identifier})
    local current_job = get_player_job(source)

    if not jobs then jobs = {} end

    for i, job in ipairs(jobs) do
        jobs[i].salary = 0
    end

    if current_job and current_job.name and current_job.name ~= 'unemployed' then
        local current_job_exists = false
        for _, job in ipairs(jobs) do
            if job.job_name == current_job.name then
                current_job_exists = true
                job.grade = current_job.grade
                job.grade_label = current_job.grade_label or ''
                job.salary = 0
                break
            end
        end
        
        if not current_job_exists then
            table.insert(jobs, {
                job_name = current_job.name,
                job_label = current_job.label,
                grade = current_job.grade,
                grade_label = current_job.grade_label or '',
                salary = 0
            })
        end
    end

    TriggerClientEvent('s6la_multijob:update_ui', source, jobs, current_job, Config.job_icons)
end)

RegisterNetEvent('s6la_multijob:select_job', function(job_name)
    local source = source
    local identifier = get_player_identifier(source)
    if not identifier then return end

    local current_job = get_player_job(source)
    
    if job_name == nil or job_name == 'unemployed' or job_name == 'OFFDUTY' then
        if current_job and current_job.name and current_job.name ~= 'unemployed' then
            local existing_job = MySQL.query.await('SELECT id FROM s6la_multijob WHERE identifier = ? AND job_name = ?', {identifier, current_job.name})
            if existing_job and #existing_job > 0 then
                MySQL.query('UPDATE s6la_multijob SET grade = ?, grade_label = ?, salary = ? WHERE identifier = ? AND job_name = ?', {
                    current_job.grade,
                    current_job.grade_label or '',
                    current_job.salary or 0,
                    identifier,
                    current_job.name
                })
            else
                auto_add_job(source, current_job.name, {
                    grade = current_job.grade,
                    grade_label = current_job.grade_label,
                    salary = current_job.salary
                })
            end
        end
        local previous_job_label = current_job and current_job.label or 'Unknown'
        set_player_job(source, 'unemployed', 0)
        log_action(source, 'JOB_SELECTED', string.format('Switched to: Unemployed (from %s)', previous_job_label), 15158332)
        TriggerClientEvent('s6la_multijob:notify', source, 'You are now unemployed', 'success')
        TriggerEvent('s6la_multijob:get_jobs', source)
        return
    end

    local job = MySQL.query.await('SELECT * FROM s6la_multijob WHERE identifier = ? AND job_name = ?', {identifier, job_name})
    if job and #job > 0 then
        if current_job and current_job.name and current_job.name ~= 'unemployed' and current_job.name ~= job_name then
            local current_job_in_db = MySQL.query.await('SELECT id FROM s6la_multijob WHERE identifier = ? AND job_name = ?', {identifier, current_job.name})
            if current_job_in_db and #current_job_in_db > 0 then
                MySQL.query('UPDATE s6la_multijob SET grade = ?, grade_label = ?, salary = ? WHERE identifier = ? AND job_name = ?', {
                    current_job.grade,
                    current_job.grade_label or '',
                    current_job.salary or 0,
                    identifier,
                    current_job.name
                })
            else
                auto_add_job(source, current_job.name, {
                    grade = current_job.grade,
                    grade_label = current_job.grade_label,
                    salary = current_job.salary
                })
            end
        end
        
        local saved_grade = job[1].grade or 0
        local previous_job_label = current_job and current_job.label or 'Unemployed'
        set_player_job(source, job_name, saved_grade)
        log_action(source, 'JOB_SELECTED', string.format('Switched to: %s (Grade: %s) | From: %s', job[1].job_label, job[1].grade_label or saved_grade, previous_job_label), 3447003)
        TriggerClientEvent('s6la_multijob:notify', source, 'Switched to ' .. job[1].job_label, 'success')
        TriggerEvent('s6la_multijob:get_jobs', source)
    elseif current_job and current_job.name == job_name then
        set_player_job(source, job_name, current_job.grade)
        log_action(source, 'JOB_SELECTED', string.format('Switched to: %s (Grade: %s) | Already current job', current_job.label, current_job.grade_label or current_job.grade), 3447003)
        TriggerClientEvent('s6la_multijob:notify', source, 'Switched to ' .. current_job.label, 'success')
        TriggerEvent('s6la_multijob:get_jobs', source)
    else
        log_action(source, 'JOB_SELECT_FAILED', string.format('Attempted to select: %s | Reason: Not in job list', job_name), 15158332)
        TriggerClientEvent('s6la_multijob:notify', source, 'Job not found in your list', 'error')
    end
end)

RegisterNetEvent('s6la_multijob:job_switched', function(previous_job_name, new_job_name)
    local source = source
    local identifier = get_player_identifier(source)
    if not identifier then return end
    
    if not previous_job_name or previous_job_name == 'unemployed' then return end
    
    local current_job = get_player_job(source)
    if not current_job or current_job.name ~= new_job_name then
        log_action(source, 'JOB_SWITCH_FAILED', string.format('Previous: %s | New: %s | Reason: Job mismatch or invalid', previous_job_name, new_job_name or 'nil'), 15158332)
        return
    end
    
    local previous_job_exists = MySQL.query.await('SELECT grade, grade_label, salary FROM s6la_multijob WHERE identifier = ? AND job_name = ?', {identifier, previous_job_name})
    if previous_job_exists and #previous_job_exists > 0 then
        MySQL.query('UPDATE s6la_multijob SET grade = ?, grade_label = ?, salary = ? WHERE identifier = ? AND job_name = ?', {
            previous_job_exists[1].grade,
            previous_job_exists[1].grade_label or '',
            previous_job_exists[1].salary or 0,
            identifier,
            previous_job_name
        })
    else
        local previous_job_data = nil
        if framework == 'qb-core' then
            if qb_core and qb_core.Shared and qb_core.Shared.Jobs then
                local job_config = qb_core.Shared.Jobs[previous_job_name]
                if job_config then
                    previous_job_data = {
                        grade = 0,
                        grade_label = '',
                        salary = 0
                    }
                end
            end
        elseif framework == 'es_extended' then
            if esx then
                local job_config = ESX.GetJobs()[previous_job_name]
                if job_config then
                    previous_job_data = {
                        grade = 0,
                        grade_label = '',
                        salary = 0
                    }
                end
            end
        end
        
        if previous_job_data then
            auto_add_job(source, previous_job_name, previous_job_data)
        end
    end
    
    log_action(source, 'JOB_SWITCHED', string.format('From: %s | To: %s', previous_job_name, new_job_name))
    TriggerEvent('s6la_multijob:get_jobs', source)
end)

RegisterNetEvent('s6la_multijob:player_loaded', function(job_name)
    local source = source
    local identifier = get_player_identifier(source)
    if not identifier then return end
    
    if not job_name or job_name == 'unemployed' then return end
    
    local current_job = get_player_job(source)
    if not current_job or current_job.name ~= job_name then
        log_action(source, 'PLAYER_LOADED_FAILED', string.format('Job: %s | Reason: Job mismatch or invalid', job_name), 15158332)
        return
    end
    
    auto_add_job(source, job_name, {
        grade = current_job.grade,
        grade_label = current_job.grade_label,
        salary = current_job.salary
    })
    log_action(source, 'PLAYER_LOADED', string.format('Job added on load: %s (Grade: %s)', current_job.label, current_job.grade_label or current_job.grade), 3066993)
end)

RegisterNetEvent('s6la_multijob:remove_job', function(job_name)
    local source = source
    local identifier = get_player_identifier(source)
    if not identifier then return end

    local job_info = MySQL.query.await('SELECT job_label FROM s6la_multijob WHERE identifier = ? AND job_name = ?', {identifier, job_name})
    MySQL.query('DELETE FROM s6la_multijob WHERE identifier = ? AND job_name = ?', {identifier, job_name})
    local job_label = job_info and job_info[1] and job_info[1].job_label or job_name
    log_action(source, 'JOB_REMOVED', string.format('Job: %s (%s)', job_label, job_name), 15158332)
    TriggerClientEvent('s6la_multijob:notify', source, 'Job removed from your list', 'success')
    TriggerEvent('s6la_multijob:get_jobs', source)
end)


RegisterCommand(Config.command, function(source, args)
    TriggerClientEvent('s6la_multijob:open_ui', source)
end, false)

AddEventHandler('onResourceStart', function(resourceName)

    print([[
  _______  ______  __  __  _____   _      ___  
 |__   __||  ____||  \/  ||  __ \ | |    ( _ ) 
    | |   | |__   | \  / || |__) || |    / _ \ 
    | |   |  __|  | |\/| ||  ___/ | |   | (_) |
    | |   | |____ | |  | || |     | |____\___/ 
    |_|   |______||_|  |_||_|     |______|     

------------------------------------------------
 Thank you for choosing TEMPL8 Scripts ❤️
------------------------------------------------
]])
if resourceName ~= 's6la_multijob' then print('^1[s6la_multijob]^7 Buckaroo, please dont change the name of the asset.') return end
end)
