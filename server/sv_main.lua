local esx = exports['es_extended']:getSharedObject()
local cachedJobs = {}

function player(client)
    return esx.GetPlayerFromId(client)
end

function getJobs(client)
    if not cachedJobs[client] then
        local result = MySQL.Sync.fetchAll('SELECT * FROM multijob WHERE identifier = @identifier', {
            ['@identifier'] = player(client).identifier
        })
        local jobs = json.decode(result[1].jobs)
        cachedJobs[client] = jobs
    end
    return cachedJobs[client]
end

exports('getJobs', getJobs)

function addJob(client, job, grade)
    local player = player(client)
    local jobs = getJobs(client)
    jobs[job] = grade
    cachedJobs[client] = jobs
    saveJobs(client, player)
    player.setJob(job, grade)
    cacheJobs_client(client)
end

exports('addJob', addJob)

function removeJob(client, job)
    local player = player(client)
    local jobs = getJobs(client)
    jobs[job] = nil
    cachedJobs[client] = jobs
    saveJobs(client, player)
    player.setJob('unemployed', 0)
    cacheJobs_client(client)
end

exports('removeJob', removeJob)

function removeJobIdentifier(identifier, job)
    local player = esx.GetPlayerFromIdentifier(identifier)
    if player then
        local client = player.source
        local jobs = getJobs(client)
        jobs[job] = nil
        cachedJobs[client] = jobs
        saveJobs(client, player)
        player.setJob('unemployed', 0)
        cacheJobs_client(client)
    else
        local result = MySQL.Sync.fetchAll('SELECT * FROM multijob WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        })
        local jobs = json.decode(result[1].jobs)
        jobs[job] = nil
        MySQL.Sync.execute('UPDATE multijob SET jobs = @jobs WHERE identifier = @identifier', {
            ['@jobs'] = json.encode(jobs),
            ['@identifier'] = identifier
        })
    end
end

exports('removeJobIdentifier', removeJobIdentifier)

function saveJobs(client, player)
    if not player then
        player = player(client)
    end
    local jobs = cachedJobs[client]
    if jobs == nil then
        jobs = getJobs(client)
    end
    MySQL.Sync.execute('UPDATE multijob SET jobs = @jobs WHERE identifier = @identifier', {
        ['@jobs'] = json.encode(jobs),
        ['@identifier'] = player.identifier
    })
end

exports('saveJobs', saveJobs)

function cacheJobs_client(client)
    local jobs = {}
    for k, v in pairs(getJobs(client)) do
        local job = esx.Jobs[k]
        print('caching', k, v)
        jobs[k] = {
            job_label = job.label,
            grade = v,
            grade_label = job.grades[tostring(v)].label
        }
    end
    TriggerClientEvent('maku_multijob:client:cacheJobs', client, jobs, player(client).job.name)
end

exports('cacheJobs_client', cacheJobs_client)

AddEventHandler('esx:playerLoaded', function(client)
    init(client)
end)

function init(client)
    local player = player(client)
    local result = MySQL.Sync.fetchAll('SELECT * FROM multijob WHERE identifier = @identifier', {
        ['@identifier'] = player.identifier
    })
    if #result == 0 then
        local result2 = MySQL.Sync.fetchAll(
            'SELECT job, job_grade, secondjob, secondjob_grade FROM users WHERE identifier = @identifier'
            ,
            {
                ['@identifier'] = player.identifier
            })
        local jobs = {}
        if #result2 ~= 0 then
            jobs[result2[1].job] = result2[1].job_grade
            jobs[result2[1].secondjob] = result2[1].secondjob_grade
            jobs['unemployed'] = nil
        end
        MySQL.Sync.execute('INSERT INTO multijob (identifier, jobs) VALUES (@identifier, @jobs)', {
            ['@identifier'] = player.identifier,
            ['@jobs'] = json.encode(jobs)
        })
    end
end

RegisterCommand('*initplayer', function(src)
    init(src)
end)

AddEventHandler('esx:playerDropped', function(client)
    local player = player(client)
    saveJobs(client, player)
end)

RegisterNetEvent('maku_multijob:server:cacheJobs', function()
    local client = source
    cacheJobs_client(client)
end)

RegisterNetEvent('maku_multijob:server:selectJob', function(job)
    local client = source
    local player = player(client)
    local jobs = getJobs(client)
    local grade = nil
    print(job)
    print(jobs[job])
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

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS multijob (
            identifier VARCHAR(255) NOT NULL,
            jobs TEXT NOT NULL,
            PRIMARY KEY (identifier)
        )
    ]])
end)
