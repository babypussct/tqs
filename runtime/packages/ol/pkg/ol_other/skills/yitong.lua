local yitong = fk.CreateSkill{
  name = "qin__yitong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["qin__yitong"] = "一统",
  [":qin__yitong"] = "锁定技，你使用【杀】、【过河拆桥】、【顺手牵羊】、【火攻】无距离限制且改为指定所有非秦势力角色为目标。",

  ["#yitong_slash_skill"] = "对所有非秦势力角色造成1点伤害",
  ["#yitong_dismantlement_skill"] = "弃置所有非秦势力角色区域内的一张牌",
  ["#yitong_snatch_skill"] = "获得所有非秦势力角色区域内的一张牌",
  ["#yitong_fire_attack_skill"] = "令所有非秦势力角色展示一张手牌，然后你可以弃置一张花色相同的手牌对其造成1点火焰伤害",

  ["$qin__yitong"] = "秦得一统，安乐升平！",
}

yitong:addEffect(fk.AfterCardTargetDeclared, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(yitong.name) and
      table.contains({ "slash", "dismantlement", "snatch", "fire_attack" }, data.card.trueName)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, yitong.name, "offensive")
    player:broadcastSkillInvoke(yitong.name)
    for _, p in ipairs(room:getAlivePlayers()) do
      if p.kingdom ~= "qin" and not table.contains(data.tos, p) and
        data.card.skill:modTargetFilter(player, p, {}, data.card, { bypass_distances = true }) then
        room:doIndicate(player, { p })
        data:addTarget(p)
      end
    end
  end,
})

yitong:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(yitong.name) and card and
      table.contains({"slash", "dismantlement", "snatch", "fire_attack"}, card.trueName)
  end,
})

yitong:addEffect("filter", {
  card_skill_filter = function (self, card, player)
    if player:hasSkill(yitong.name) and table.contains({"slash", "dismantlement", "snatch", "fire_attack"}, card.trueName) then
      return "#yitong__"..card.trueName.."_skill"
    end
  end,
})

return yitong
