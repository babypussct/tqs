local nanyang = fk.CreateSkill {
  name = "peixiu_nanyang",
}

Fk:loadTranslationTable {
  ["peixiu_nanyang"] = "南阳",
  [":peixiu_nanyang"] = "你获得此技能后，可以重铸一张锦囊牌，与一名角色各回复1点体力。",

  ["#peixiu_nanyang-choose"] = "南阳：选择一名角色，重铸一张锦囊牌，与目标各回复1点体力",
}

nanyang:addEffect(fk.EventAcquireSkill, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(nanyang.name) and data.skill.name == nanyang.name and
      not player:isKongcheng() and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to, card = room:askToChooseCardsAndPlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      min_card_num = 1,
      max_card_num = 1,
      pattern = ".|.|.|.|.|trick",
      prompt = "#peixiu_nanyang-choose",
      skill_name = nanyang.name,
      cancelable = true,
    })
    if #to > 0 and #card > 0 then
      event:setCostData(self, { tos = to, cards = card })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:recastCard(event:getCostData(self).cards, player, nanyang.name)
    if not player.dead then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = nanyang.name,
      }
    end
    if not to.dead then
      room:recover{
        who = to,
        num = 1,
        recoverBy = player,
        skillName = nanyang.name,
      }
    end
  end
})

return nanyang
