local H = require "packages.hegemony.util"
local halberdActive = fk.CreateSkill{
  name = "sa__halberd_active",
}
halberdActive:addEffect("active", {
  name = "#sa__halberd_targets",
  can_use = Util.FalseFunc,
  min_target_num = 1,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local orig_tos = self.orig_tos
    local targets = self.targets
    local room = Fk:currentRoom()
    return table.contains(targets, to_select.id) and (to_select.kingdom == "unknown" or (table.every(orig_tos, function(id)
      return not H.compareKingdomWith(to_select, room:getPlayerById(id))
    end) and table.every(selected, function(p)
      return not H.compareKingdomWith(to_select, p)
    end)))
  end,
})

return halberdActive
