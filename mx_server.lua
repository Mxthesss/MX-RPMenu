ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('ev-menu:getData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local result = MySQL.Sync.fetchAll("SELECT users.phone_number FROM users WHERE users.identifier = @identifier", {
		['@identifier'] = xPlayer.identifier}
	)
    local data = {}
	if result[1] ~= nil and result[1].phone_number ~= nil then
        data   = {
            name    = xPlayer.getName("firstname"),
            money   = xPlayer.getMoney(),
            bank    = xPlayer.getAccount('bank').money,
            black   = xPlayer.getAccount('black_money').money,
            dateofbirth     = xPlayer.get('dateofbirth'),
            sex     = xPlayer.get('sex'),
            height  = xPlayer.get('height'),
            phone   = result[1].phone_number
        }


		
    else
        data   = {
            name    = xPlayer.getName(),
            money   = xPlayer.getMoney(),
            bank    = xPlayer.getAccount('bank').money,
            black   = xPlayer.getAccount('black_money').money,
            dateofbirth     = xPlayer.get('dateofbirth'),
            sex     = xPlayer.get('sex'),
            height  = xPlayer.get('height'),
            phone   = _U('no_phone')
        }
    end
    if xPlayer.get('sex') == 'm' then
        data.sex = 'male'
    else
        data.sex = 'female'
    end
    cb(data)
end)

MySQL.Async.fetchAll('SELECT firstname, lastname, dateofbirth, sex, height FROM users WHERE identifier = @identifier', {['@identifier'] = identifier},
function (user)
	if (user[1] ~= nil) then
		MySQL.Async.fetchAll('SELECT type FROM user_licenses WHERE owner = @identifier', {['@identifier'] = identifier},
		function (licenses)
			if type ~= nil then
				for i=1, #licenses, 1 do
					if type == 'driver' then
						if licenses[i].type == 'drive' or licenses[i].type == 'drive_bike' or licenses[i].type == 'drive_truck' then
							show = true
						end
					elseif type =='weapon' then
						if licenses[i].type == 'weapon' then
							show = true
						end
					end
				end
			else
				show = true
			end

			if show then
				local array = {
					user = user,
					licenses = licenses
				}
				TriggerClientEvent('jsfour-idcard:open', _source, array, type)
			else
				TriggerClientEvent('esx:showNotification', _source, "You don't have that type of license..")
			end
		end)
	end
end)


--[[
    Gotta clarify that this is not my code. This is just stuff I have modified. The authors of this are the following: 
    - https://github.com/rubbertoe98        // Carry | Hostage | Carry on Arms
    - https://github.com/barbiesv           // Carry baby 
]]

local piggybacking = {}
local beingPiggybacked = {}
local carrying = {}
local carried = {}
local takingHostage = {}
local takenHostage = {}

RegisterServerEvent('Piggyback:sync')
AddEventHandler('Piggyback:sync', function(targetSrc)
	local source = source
	local sourcePed = GetPlayerPed(source)
    	local sourceCoords = GetEntityCoords(sourcePed)
	local targetPed = GetPlayerPed(targetSrc)
    	local targetCoords = GetEntityCoords(targetPed)
	if #(sourceCoords - targetCoords) <= 3.0 then 
		TriggerClientEvent('Piggyback:syncTarget', targetSrc, source)
		piggybacking[source] = targetSrc
		beingPiggybacked[targetSrc] = source
	end
end)

RegisterServerEvent('CarryPeople:sync')
AddEventHandler('CarryPeople:sync', function(targetSrc)
	local source = source
	local sourcePed = GetPlayerPed(source)
   	local sourceCoords = GetEntityCoords(sourcePed)
	local targetPed = GetPlayerPed(targetSrc)
        local targetCoords = GetEntityCoords(targetPed)
	if #(sourceCoords - targetCoords) <= 3.0 then 
		TriggerClientEvent('CarryPeople:syncTarget', targetSrc, source)
		carrying[source] = targetSrc
		carried[targetSrc] = source
	end
end)

RegisterServerEvent('TakeHostage:sync')
AddEventHandler('TakeHostage:sync', function(targetSrc)
	local source = source

	TriggerClientEvent('TakeHostage:syncTarget', targetSrc, source)
	takingHostage[source] = targetSrc
	takenHostage[targetSrc] = source
end)

RegisterServerEvent('cmg:stop')
AddEventHandler('cmg:stop', function(targetSrc)
	local source = source

	if piggybacking[source] then
		TriggerClientEvent('Piggyback:cl_stop', targetSrc)
		piggybacking[source] = nil
		beingPiggybacked[targetSrc] = nil
	elseif beingPiggybacked[source] then
		TriggerClientEvent('Piggyback:cl_stop', beingPiggybacked[source])
		beingPiggybacked[source] = nil
		piggybacking[beingPiggybacked[source]] = nil
	elseif carrying[source] then
		TriggerClientEvent('CarryPeople:cl_stop', targetSrc)
		carrying[source] = nil
		carried[targetSrc] = nil
	elseif carried[source] then
		TriggerClientEvent('CarryPeople:cl_stop', carried[source])			
		carrying[carried[source]] = nil
		carried[source] = nil
	end
end)

RegisterServerEvent('TakeHostage:releaseHostage')
AddEventHandler('TakeHostage:releaseHostage', function(targetSrc)
	local source = source
	if takenHostage[targetSrc] then 
		TriggerClientEvent('TakeHostage:releaseHostage', targetSrc, source)
		takingHostage[source] = nil
		takenHostage[targetSrc] = nil
	end
end)

RegisterServerEvent('TakeHostage:killHostage')
AddEventHandler('TakeHostage:killHostage', function(targetSrc)
	local source = source
	if takenHostage[targetSrc] then 
		TriggerClientEvent('TakeHostage:killHostage', targetSrc, source)
		takingHostage[source] = nil
		takenHostage[targetSrc] = nil
	end
end)

AddEventHandler('playerDropped', function(reason)
	local source = source
	
	if takingHostage[source] then
		TriggerClientEvent('TakeHostage:cl_stop', takingHostage[source])
		takenHostage[takingHostage[source]] = nil
		takingHostage[source] = nil
	end

	if takenHostage[source] then
		TriggerClientEvent('TakeHostage:cl_stop', takenHostage[source])
		takingHostage[takenHostage[source]] = nil
		takenHostage[source] = nil
	end

	if piggybacking[source] then
		TriggerClientEvent('Piggyback:cl_stop', piggybacking[source])
		beingPiggybacked[piggybacking[source]] = nil
		piggybacking[source] = nil
	end

	if beingPiggybacked[source] then
		TriggerClientEvent('Piggyback:cl_stop', beingPiggybacked[source])
		piggybacking[beingPiggybacked[source]] = nil
		beingPiggybacked[source] = nil
	end

	if carrying[source] then
		TriggerClientEvent('CarryPeople:cl_stop', carrying[source])
		carried[carrying[source]] = nil
		carrying[source] = nil
	end

	if carried[source] then
		TriggerClientEvent('CarryPeople:cl_stop', carried[source])
		carrying[carried[source]] = nil
		carried[source] = nil
	end
end)



function getInfo(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
	local identifier = xPlayer.identifier
	local result = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = @identifier", {['@identifier'] = identifier})

    if result[1] ~= nil then
		local info = result[1]

		return {
			firstname = info['firstname'],
			lastname = info['lastname'],
			dateofbirth = info['dateofbirth'],
			sex = info['sex'],
            phone = info['phone_number']
		}
	else
		return nil
	end
end

ESX.RegisterServerCallback('scb_rpmenu:getName', function(source, cb)
    local _source = source
    local info = getInfo(_source)

    cb(info)
end)