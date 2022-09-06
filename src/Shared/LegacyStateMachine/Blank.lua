local module = {}
module.__index = module
module.id = "blank"

function module:HandleInput() end
function module:Enter() end
function module:Exit() end
function module:Update() end

return module
