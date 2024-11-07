-- IMPORTANT NOTE: when laying out the bundled cable the order for colours is as follows:
    -- [1] White
    -- [2] Orange
    -- [3] Magenta
    -- [4] Light Blue
    -- [5] Yellow 
    -- [6] Lime 
    -- [7] Pink 
    -- [8] Gray 
    -- [9] Light Gray
    -- [10] Cyan
    -- [11] Purple
    -- [12] Blue
    -- [13] Brown
    -- [14] Green
    -- [15] Red
    -- [16] Black
-- This order is fixed and can't be changed so make sure you lay out your redstone in the correct order

-- This program runs in an infinite loop, it can be terminated by pressing Ctrl + C

-- CONFIGURATION AREA

    --Side from which the Bundled Cable Input arrives. use cardinal directions in quotation marks ("up", "down", "north", "south", "east", "west")
    local rsInput = "down"

    --Side from which the Bundled Cable Output is transmitted. use cardinal directions in quotation marks ("up", "down", "north", "south", "east", "west")
    local rsOutput = "up"

    --Side from which the main Override signal enters. use cardinal directions in quotation marks ("up", "down", "north", "south", "east", "west"))
    local rsShutdown = "south"

    -- amount of systems that will be controlled by the program (maximum: 16)
    local systemCount = 16

    --List of all Systems present (maximum of 16)
    local Systems = {
        "Crushers",
        "Centrifuges",
        "Ore Washing Plants",
        "Chemical Baths",
        "Thermal Centrifuges",
        "Sifters",
        "Electrolyzers",
        "Small Processing Lines",
        "Rare Earth Processing",
        "Cerium Processing",
        "Samarium Processing",
        "Platinum Line",
        "Bastnatite Line",
        "Monazite Line",
        "Naquadah Line",
        "Isamilling Plant"
        }

-- END OF CONFIGURATION AREA, DON'T CHANGE ANYTHING BEYOND THIS POINT!

local serial = require("serialization")
local event = require("event")
local component = require("component")
local colors = require("colors")
local sides = require("sides")
local rs = component.redstone

rsInput = sides[rsInput]
rsOutput = sides[rsOutput]
rsShutdown = sides[rsShutdown]

local function load() -- Loads rsStates or creates a list to fill rsStates with if no such file exists
    
    local rsStates = {}
    
    local file = io.open("rsStates", "r")
    if file ~= nil then
        rsStates = serial.unserialize(file:read("*a"))
        if rsStates == nil or #rsStates ~= systemCount then
            rsStates = {}
            for i = 1, systemCount do
                rsStates[i] = false
            end
        end
        file:close()
    else
        for i = 1, systemCount do
            rsStates[i] = false
        end
    end
    return rsStates
end

local function save() -- Saves rsStates to file, file used in case of reboot/restart/crash
    local file = io.open("rsStates", "w")
    file:write(serial.serialize(rsStates))
    file:close()
end

local function systemShutdown() -- Will shut down all outgoing redstone signals, disabling all the systems
    print("System Override triggered")
    for i = 1, systemCount do
        j = i - 1
        local isActive = rs.getBundledOutput(rsOutput, j) > 0
        if isActive == true then
            rs.setBundledOutput(rsOutput, i, 0)
            print("Turning off", colors[j], Systems[i])
        end
    end
    print("All systems stopped")
end

local function systemStartup() -- Will restart the system with the previously provided variables
    print("System restarting")
    for i = 1, systemCount do
        j = i - 1
        if rsStates[i] == true then
            rs.setBundledOutput(rsOutput, i, 255)
            print("Turning on", colors[j], Systems[i])
        end
    end
    print("All systems started")
end

local function RSstartup()
    local Override = rs.getInput(rsShutdown)
    if Override == 0 then
        systemStartup()
    end
end

local function RSupdate(_, _, side, _, newValue, colour) -- Will act upon a changing redstone signal
    local process = colour + 1
    if side == rsShutdown then
        if newValue > 0 then
            systemShutdown()
        else
            systemStartup()
        end
    elseif side == rsInput then
        if newValue > 0 then
            if rsStates[process] == false then
                rs.setBundledOutput(rsOutput, colour, 255)
                rsStates[process] = true
                save()
                print("Turned On", colors[colour], Systems[process])
            else
                rs.setBundledOutput(rsOutput, colour, 0)
                rsStates[process] = false
                save()
                print("Turned Off", colors[colour], Systems[process])
                
            end
        end
    end
end

rsStates = load()
RSstartup()
local running = true

while running do
    local ID, _, side, _, value, colour = event.pullMultiple(20, "redstone_changed", "interrupted")
    if ID == "interrupted" then
        systemShutdown()
        running = false
        print("Program Stopped")
    else
        RSupdate(side, value, colour)
    end
end