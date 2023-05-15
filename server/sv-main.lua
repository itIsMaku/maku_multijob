esx = exports['es_extended']:getSharedObject()
cachedJobs = {}

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS multijob (
            identifier VARCHAR(255) NOT NULL,
            jobs TEXT NOT NULL,
            PRIMARY KEY (identifier)
        )
    ]])
end)

AddEventHandler('esx:playerLoaded', function(client)
    init(client)
end)

AddEventHandler('esx:playerDropped', function(client)
    local player = player(client)
    saveJobs(client, player)
end)

RegisterNetEvent('maku_multijob:server:cacheJobs', function()
    local client = source
    cacheJobs(client)
end)

RegisterNetEvent('maku_multijob:server:selectJob', function(job)
    local client = source
    local player = player(client)
    local jobs = getJobs(client)
    local grade = nil
    if not jobs[job] and job ~= 'unemployed' then
        print('myb cheating?')
        return
    end
    if job == 'unemployed' then
        grade = 0
    else
        grade = jobs[job]
    end
    player.setJob(job, grade)
    player.showNotification(('Přepl sis své zaměstnání na %s - %s.'):format(esx.Jobs[job].label,
        esx.Jobs[job].grades[tostring(grade)].label), 'info')
end)

AddEventHandler('esx:setJob', function(client, job, lastJob)
    if job.name == 'unemployed' then
        return
    end
    local jobs = getJobs(client)
    if jobs[job.name] == nil then
        addJob(client, job.name, job.grade, true)
    end
end)
