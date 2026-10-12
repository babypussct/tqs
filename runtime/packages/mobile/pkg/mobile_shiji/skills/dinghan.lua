local dinghan = fk.CreateSkill {
  name = "dinghan",
}

Fk:loadTranslationTable{
  ["dinghan"] = "定汉",
  [":dinghan"] = "当你成为锦囊牌的目标时，若此牌牌名未被记录，则记录此牌名，然后取消此目标；回合开始时，你可以增加或移除一种锦囊牌的牌名记录。",

  ["@$dinghan"] = "定汉",
  ["dinghan_add"] = "增加定汉牌名",
  ["dinghan_remove"] = "移除定汉牌名",

  ["$dinghan1"] = "杀身有地，报国有时。",
  ["$dinghan2"] = "益国之事，虽死弗避。",
}

local U = require "packages.utility.utility"

dinghan:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dinghan.name) and not data.cancelled and
      data.card.type == Card.TypeTrick and
      data.card.name ~= "raid_and_frontal_attack" and
      not table.contains(player:getTableMark("@$dinghan"), data.card.trueName)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:addTableMark(player, "@$dinghan", data.card.trueName)
    data:cancelCurrentTarget()
  end,
})
dinghan:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dinghan.name)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local record = player:getTableMark("@$dinghan")
    local choices = {"Cancel"}
    if #record > 0 then
      table.insert(choices, 1, "dinghan_remove")
    end
    local all_names = table.filter(Fk:getAllCardNames("td"), function (name)
      return not table.contains(record, name)
    end)
    if #all_names > 0 then
      table.insert(choices, 1, "dinghan_add")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = dinghan.name,
    })
    if choice == "Cancel" then return end
    local name = room:askToChoice(player, {
      choices= choice == "dinghan_add" and all_names or record,
      skill_name = dinghan.name,
    })
    event:setCostData(self, {choice = choice, extra_data = name})
    return true
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice == "dinghan_add" then
      room:addTableMark(player, "@$dinghan", event:getCostData(self).extra_data)
    else
      room:removeTableMark(player, "@$dinghan", event:getCostData(self).extra_data)
    end
  end,
})

return dinghan
