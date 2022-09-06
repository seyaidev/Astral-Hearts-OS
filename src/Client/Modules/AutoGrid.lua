local AutoGrid = {}

function AutoGrid:Update(PADDING, SIZE, AbsoluteSize, AbsoluteContentSize)
    -- Convert desired values to offset
    local NewPadding = PADDING * AbsoluteSize
    NewPadding = UDim2.new(0, NewPadding.X, 0, NewPadding.Y)
    local NewSize = SIZE * AbsoluteSize
    NewSize = UDim2.new(0, NewSize.X, 0, NewSize.Y)

    return NewPadding, NewSize, UDim2.new(0, AbsoluteContentSize.X, 0, AbsoluteContentSize.Y)
end

return AutoGrid