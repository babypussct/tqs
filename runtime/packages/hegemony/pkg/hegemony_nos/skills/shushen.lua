
local shushen = fk.CreateSkill{
  name = "nos_heg__shushen",
}

Fk:loadTranslationTable{
  ["nos_heg__shushen"] = "淑慎",
  [":nos_heg__shushen"] = "当你回复1点体力后，你可以令一名其他角色摸一张牌。",

  ["#nos_heg__shushen-choose"] = "淑慎：你可以令一名其他角色摸一张牌",

  ["$nos_heg__shushen1"] = "船到桥头自然直。",
  ["$nos_heg__shushen2"] = "妾身无恙，相公请安心征战。",
}

shushen:addEffect(fk.HpRecover, {
  anim_type = "support",
  trigger_times = function (self, event, target, player, data)
    return data.num
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      skill_name = shushen.name,
      prompt = "#nos_heg__shushen-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    event:getCostData(self).tos[1]:drawCards(1, shushen.name)
  end,
})

return shushen
