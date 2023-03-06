local esx = exports['es_extended']:getSharedObject()
local current = nil
local cachedJobs = nil

function openMultijobMenu()
    if not cachedJobs then
        TriggerServerEvent('maku_multijob:server:cacheJobs')
    end
    while not cachedJobs do
        Citizen.Wait(500)
    end
    local elements = {}
    for k, v in pairs(cachedJobs) do
        if current == k then
            table.insert(elements,
                {
                    label = "<span style='color: lightgreen'>" .. v.job_label .. ' - ' .. v.grade_label .. "</span>",
                    value = k
                })
        else
            table.insert(elements, {
                label = v.job_label .. ' - ' .. v.grade_label,
                value = k
            })
        end
    end
    --table.insert(elements, { label = '---', value = nil })
    table.insert(elements, { label = "<span style='color: orange'>Nezaměstnaný</span>", value = 'unemployed' })
    esx.UI.Menu.Open('default', GetCurrentResourceName(), 'multijob', {
        title = 'Multijob',
        align = 'top-right',
        elements = elements
    }, function(data, menu)
        local job = data.current.value
        if job and current ~= job then
            current = job
            TriggerServerEvent('maku_multijob:server:selectJob', job)
            menu.close()
        else
            esx.ShowNotification('Tento job máš aktivní!', 'error')
        end
    end, function(data, menu)
        menu.close()
    end)
end

RegisterNetEvent('maku_multijob:client:cacheJobs', function(jobs, currentJob)
    cachedJobs = jobs
    current = currentJob
end)

RegisterCommand('multijob', function()
    openMultijobMenu()
end, false)
