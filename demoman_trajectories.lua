--[[draws projectile trajectories]]

---@alias AimTarget { entity : Entity, pos : Vector3, angles : EulerAngles, factor : number }

---@param pLocal WPlayer
---@param userCmd UserCmd
local GRAVITY = 800 -- gravity in units/s^2
local FIXED_VELOCITY = 1300 -- fixed initial velocity in Hammer units

function CalculateProjectilePath(startPos, endPos, velocity)
    local distance = (endPos - startPos):Length()
    local direction = (endPos - startPos)
  
    if not velocity then
      velocity = FIXED_VELOCITY
    end
  
    assert(startPos ~= nil and type(startPos) == "userdata", "Invalid start position")
    assert(endPos ~= nil and type(endPos) == "userdata", "Invalid end position")
    assert(velocity ~= nil and type(velocity) == "number", "Invalid velocity")
  
    local angle = math.deg(math.asin((GRAVITY * distance) / (velocity * velocity)) / 2)
    local timeToTarget = velocity * math.sin(math.rad(angle))
    local height = velocity * math.sin(math.rad(angle)) * timeToTarget - 0.5 * GRAVITY * timeToTarget * timeToTarget
  
    local path = {}
    local interval = 0.04 -- time interval between each point in seconds
    local currentTime = 0
  
    while currentTime <= timeToTarget do
      local x = velocity * math.cos(math.rad(angle)) * currentTime
      local y = velocity * math.sin(math.rad(angle)) * currentTime - 0.5 * GRAVITY * currentTime * currentTime + height
      local z = velocity * math.cos(math.rad(angle)) * currentTime
  
      local point = startPos + direction * x + Vector3(0, 0, z)
      table.insert(path, point)
  
      currentTime = currentTime + interval
    end
    
    return path
end

local function OnCreateMove(pCmd)
    --
end

local myfont = draw.CreateFont("Verdana", 16, 800) -- Create a font for doDraw
local function doDraw()
    local me = entities.GetLocalPlayer()
    if not me then return end

    if engine.Con_IsVisible() or engine.IsGameUIVisible() then
        return
    end

    draw.SetFont(myfont)
    draw.Color(255, 255, 255, 255)
    local w, h = draw.GetScreenSize()
    local screenPos = { w / 2 - 15, h / 2 + 35}

    -- Get source and destination points
    local source = me:GetAbsOrigin() + me:GetPropVector("localdata", "m_vecViewOffset[0]")
    local destination = source + engine.GetViewAngles():Forward() * 1000
    source = source + engine.GetViewAngles():Forward() * 10

    -- Trace line to get end position
    local trace = engine.TraceLine(source, destination, MASK_SHOT_HULL)
    if not trace then return end

    local startPos = source + Vector3(-20, -20, -20)
    local endPos = trace.endpos

    -- Calculate and draw projectile path
    local path = CalculateProjectilePath(startPos, endPos, FIXED_VELOCITY)
    if not path then return end

    for i, point in ipairs(path) do
        local startScreenPos = client.WorldToScreen(path[i])
        local endScreenPos = client.WorldToScreen(path[i+1])

        if startScreenPos and endScreenPos then
            draw.Line(startScreenPos[1], startScreenPos[2], endScreenPos[1], endScreenPos[2])
        end
    end

    -- Debug draw for testing
    local vStart = entities.GetLocalPlayer():GetShootPos()
    local vForward = entities.GetLocalPlayer():GetPropVector("localdata", "m_vecViewOffset[0]")
    local vEnd = vStart + vForward * 10000
    local tr = engine.TraceLine({ start = vStart, endpos = vEnd, filter = entities.GetLocalPlayer() })
    local vTargetPos = tr.HitPos
    local vDistance = vTargetPos - vStart
    local fTimeInAir = math.sqrt((vDistance.x * vDistance.x + vDistance.y * vDistance.y) / (500 * 500))
    local vVelocity = vDistance / fTimeInAir - Vector(0, 0, 0.5 * 800 * fTimeInAir)
    local vLastPos = vStart

    for i = 0, fTimeInAir, 0.01 do
        local vNewPos = vStart + vVelocity * i + Vector(0, 0, 0.5 * -600 * i * i + 800 * i * 0.01)
        debugoverlay.Line(vLastPos, vNewPos, 0.01, Color(0, 255, 0, 255), true)
        vLastPos = vNewPos
    end
end

--[[ Remove the menu when unloaded ]]--
local function OnUnload()                                -- Called when the script is unloaded
    MenuLib.RemoveMenu(menu)                             -- Remove the menu
    client.Command('play "ui/buttonclickrelease"', true) -- Play the "buttonclickrelease" sound
end


--[[ Unregister previous callbacks ]]--
callbacks.Unregister("CreateMove", "MCT_CreateMove")            -- Unregister the "CreateMove" callback
callbacks.Unregister("Unload", "MCT_Unload")                    -- Unregister the "Unload" callback
callbacks.Unregister("Draw", "MCT_Draw")                        -- Unregister the "Draw" callback
--[[ Register callbacks ]]--
callbacks.Register("CreateMove", "MCT_CreateMove", OnCreateMove)             -- Register the "CreateMove" callback
callbacks.Register("Unload", "MCT_Unload", OnUnload)                         -- Register the "Unload" callback
callbacks.Register("Draw", "MCT_Draw", doDraw)                               -- Register the "Draw" callback
--[[ Play sound when loaded ]]--
client.Command('play "ui/buttonclick"', true) -- Play the "buttonclick" sound when the script is loaded