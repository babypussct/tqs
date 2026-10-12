
local xunde = fk.CreateSkill{
  name = "xunde",
}

Fk:loadTranslationTable{
  ["xunde"] = "勋德",
  [":xunde"] = "当一名角色受到伤害后，若你与其距离1以内，你可判定，若点数不小于6且该角色不为你，你令其获得此判定牌；"..
  "若点数不大于6，你令来源弃置一张手牌。",

  ["#xunde-invoke"] = "勋德：%dest 受到伤害，你可以判定，根据点数执行效果",

  ["$xunde1"] = "陛下所托，臣必尽心尽力！",
  ["$xunde2"] = "纵吾荏弱难持，亦不推诿君命！",
}

xunde:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xunde.name) and not target.dead and (player == target or player:distanceTo(target) == 1)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = xunde.name,
      prompt = "#xunde-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = xunde.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.number >= 6 and player ~= target and not target.dead and room:getCardArea(judge.card) == Card.DiscardPile then
      room:obtainCard(target, judge.card, true, fk.ReasonJustMove, target, xunde.name)
    end
    if judge.card.number <= 6 and data.from and not data.from.dead then
      room:askToDiscard(data.from, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = xunde.name,
        cancelable = false,
      })
    end
  end,
})

return xunde
