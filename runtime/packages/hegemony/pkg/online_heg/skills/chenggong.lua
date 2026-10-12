local chenggong = fk.CreateSkill {
  name = "ol_heg__chenggong",
}

Fk:loadTranslationTable {
  ["ol_heg__chenggong"] = "逞功",
  [":ol_heg__chenggong"] = "每回合限一次，相邻角色使用牌指定多个目标后，你可以摸一张牌，然后其弃置其中一个目标的一张牌。",

  ["#ol_heg__chenggong-invoke"] = "逞功：摸一张牌，然后令 %src 弃置其中一个目标的一张牌",
  ["#ol_heg__chenggong-choose"] = "逞功：选择一名角色，弃置其的一张牌",
  ["#ol_heg__chenggong-discard"] = "逞功：选择 %src 的一张牌弃置",
}

chenggong:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chenggong.name) and data.firstTarget and #data.use.tos > 1
    and not target.dead and (target == player:getLastAlive() or target == player:getNextAlive())
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return room:askToSkillInvoke(player,{
      skill_name = chenggong.name,
      prompt = "#ol_heg__chenggong-invoke:"..target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, chenggong.name)
    local targets = table.filter(data.use.tos, function(p) return not p:isNude() and p:isAlive() end)
    if target.dead or #targets == 0 then return end
      local to = room:askToChoosePlayers(target,{
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ol_heg__chenggong-choose",
        skill_name = chenggong.name,
        cancelable = false,
    })
    if #to > 0 then
      local card = room:askToChooseCard(target,{
        target = to[1],
        flag = "he",
        prompt = "#ol_heg__chenggong-discard:"..to[1].id,
        skill_name = chenggong.name,
      })
      room:moveCardTo(card, Player.Discard, to[1], fk.ReasonDiscard, chenggong.name, nil, true, target)
    end
  end,
})

return chenggong
