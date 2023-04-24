--[[draws projectile trajectories]]

---@alias AimTarget { entity : Entity, pos : Vector3, angles : EulerAngles, factor : number }

---@type boolean, lnxLib
local libLoaded, lnxLib = pcall(require, "lnxLib")
assert(libLoaded, "lnxLib not found, please install it!")
--assert(lnxLib.GetVersion() >= 0.967, "LNXlib version is too old, please update it!")

local menuLoaded, MenuLib = pcall(require, "Menu")                               -- Load MenuLib
assert(menuLoaded, "MenuLib not found, please install it!")                      -- If not found, throw error
assert(MenuLib.Version >= 1.44, "MenuLib version is too old, please update it!") -- If version is too old, throw error

--[[ Menu ]]
local menu         = MenuLib.Create("Trajectories", MenuFlags.AutoSize)
menu.Style.TitleBg = { 125, 155, 255, 255 }
menu.Style.Outline = true


menu:AddComponent(MenuLib.Label("                   [ Draw ]", ItemFlags.FullWidth))

local mEnagle        = menu:AddComponent(MenuLib.Checkbox("Enable", true))


---@param pLocal WPlayer
---@---@param userCmd UserCmd
---@
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
        draw.SetFont( myfont )
        draw.Color( 255, 255, 255, 255 )
        local w, h = draw.GetScreenSize()
        local screenPos = { w / 2 - 15, h / 2 + 35}


          
        me = entities.GetLocalPlayer();
        local source = me:GetAbsOrigin() + me:GetPropVector( "localdata", "m_vecViewOffset[0]" );
        local destination = source + engine.GetViewAngles():Forward() * 1000;
        source = source + engine.GetViewAngles():Forward() * 10;
        local trace = engine.TraceLine( source, destination, MASK_SHOT_HULL );

        if (trace.entity == nil) then return end
        

          local startPos = source + Vector3(-20, -20, -20)
          local endPos = trace.endpos
          
        local path = CalculateProjectilePath(source, endPos, FIXED_VELOCITY)
        if path == nil then return end
   -- draw predicted enemy position with strafe prediction connecting his local point and predicted position with line.
   for i, point in ipairs(path) do
    local startScreenPos = client.WorldToScreen(path[i])
    local endScreenPos = client.WorldToScreen(path[i+1])
    if startScreenPos ~= nil and endScreenPos ~= nil then
      draw.Line(startScreenPos[1], startScreenPos[2], endScreenPos[1], endScreenPos[2])
    end
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