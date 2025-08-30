function tryObjectEnter()
    return false
end

function onObjectLeaveContainer(container)
    if container ~= self then
        return
    end

    -- wait one second, then destroy the container when it's empty
    Wait.time(function()
        Wait.condition(
                function()
                    if container ~= nil then
                        container.destruct()
                    end
                end,
                function()
                    return container ~= nil and container.getQuantity() == 0
                end
        )
    end, 1)
end
