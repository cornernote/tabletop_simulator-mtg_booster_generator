local packLua = [[
-- Any MTG Booster Generator by CoRNeRNoTe
-- Most recent script can be found on GitHub:
-- https://github.com/cornernote/tabletop_simulator-mtg_booster_generator/blob/main/lua/booster-generator.lua
local defaultSetCode = "???"
local defaultPack = "https://steamusercontent-a.akamaihd.net/ugc/12555777445170015064/1F22F21DA19B1C5D668D761C2CA447889AE98A2A/"
function tryObjectEnter()
    return false
end
function onObjectLeaveContainer(container)
    if container ~= self then
        return
    end
    Wait.condition(function()
        Wait.time(function()
            if container then
                container.destruct()
            end
        end, 1)
    end, function()
        return container and container.getQuantity() == 0
    end)
end
function onLoad()
    local setCode = string.upper(self.getDescription()):match("SET:%s*(%S+)") or self.getName():match("^(.-)%s+Booster$")
    if self.getCustomObject().diffuse == defaultPack then
        self.createButton({
            label = setCode and (setCode .. " Booster") or self.getName(),
            click_function = 'noop',
            function_owner = self,
            position = { 0, 0.2, -1.6 },
            rotation = { 0, 0, 0 },
            width = 1000,
            height = 200,
            font_size = 150,
            color = { 0, 0, 0, 95 },
            hover_color = { 0, 0, 0, 95 },
            press_color = { 0, 0, 0, 95 },
            font_color = { 1, 1, 1, 95 },
        })
    end
    if setCode ~= defaultSetCode and #self.getObjects() > 0 then
        self.createButton({
            label = "Unpack",
            click_function = "unpackDeck",
            function_owner = self,
            position = { 0, 0.2, 0 },
            rotation = { 0, 0, 0 },
            width = 600,
            height = 200,
            font_size = 150,
            color = { 0, 0, 0, 95 },
            font_color = { 1, 1, 1, 95 },
        })
    end
end
function unpackDeck()
    local contained = self.getObjects()
    if #contained == 0 then
        return
    end
    local entryGuid = contained[1].guid
    local takePos = self.getPosition() + Vector(0, 6, 0)
    local deck = self.takeObject({ guid = entryGuid, position = takePos, smooth = true })
    if not deck then
        return
    end
    deck.setLock(true)
    deck.setScale({ 2, 1, 2 })
    Wait.time(function()
        spreadDeck(deck)
    end, 0.1)
end
function spreadDeck(deck)
    if not deck then
        return
    end
    local startPos = self.getPosition() + Vector(-2.3 * 2, 2, 3.2)
    local colCount = 5
    local spacingX = 2.3
    local spacingZ = 3.2
    local total = 1
    if deck.tag == "Deck" then
        total = deck.getQuantity()
    end
    for index = 1, total do
        Wait.time(function()
            local row = math.floor((index - 1) / colCount)
            local col = (index - 1) % colCount
            local pos = startPos + Vector(col * spacingX, 2, -row * spacingZ)
            if deck.tag == "Deck" then
                local card = deck.takeObject({ position = pos, smooth = true })
                Wait.time(function()
                    card.setScale({ 1, 1, 1 })
                end, 0.05)
                if deck.remainder then
                    deck = deck.remainder
                    deck.setLock(true)
                end
            else
                deck.setScale({ 1, 1, 1 })
                deck.setLock(false)
                deck.setPositionSmooth(pos, false, false)
            end
        end, index * 0.8)
    end
    self.destruct()
end
function noop()
end
]]

return packLua
