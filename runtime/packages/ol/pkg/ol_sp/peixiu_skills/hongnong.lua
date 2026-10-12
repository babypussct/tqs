local hongnong = fk.CreateSkill {
  name = "peixiu_hongnong",
}

Fk:loadTranslationTable {
  ["peixiu_hongnong"] = "弘农",
  [":peixiu_hongnong"] = "你获得此技能后，可以重铸任意张装备牌并回复1点体力。",

  ["#peixiu_hongnong-discard"] = "弘农：重铸任意张装备牌并回复1点体力",
}

hongnong:addEffect(fk.EventAcquireSkill, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(hongnong.name) and data.skill.name == hongnong.name and
      not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = hongnong.name,
      pattern = ".|.|.|.|.|equip",
      prompt = "#peixiu_hongnong-discard",
      cancelable = true,
    })
    if #card > 0 then
      event:setCostData(self, { cards = card })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards or {}
    room:recastCard(cards, player, hongnong.name)
    if not player.dead then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = hongnong.name,
      }
    end
  end
})

return hongnong
