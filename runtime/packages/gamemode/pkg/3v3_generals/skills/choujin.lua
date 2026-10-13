local choujin = fk.CreateSkill {
  name = "choujin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["choujin"] = "筹进",
  [":choujin"] = "锁定技，亮将结束后，你选择一名对方角色：每回合限两次，当己方角色对该角色造成伤害后，该己方角色摸一张牌。",

  ["#choujin-choose"] = "筹进：标记一名对方角色，每回合限两次，己方角色对该角色造成伤害后摸一张牌",
  ["@@choujin"] = "筹进",

  ["$choujin1"] = "预则立，不预则废！",
  ["$choujin2"] = "就用你，给我军祭旗！",
}

choujin:addEffect(fk.GamePrepared, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(choujin.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = player:getEnemies(),
      min_num = 1,
      max_num = 1,
      prompt = "#choujin-choose",
      skill_name = choujin.name,
      cancelable = false,
    })[1]
    room:setPlayerMark(to, "@@choujin", 1)
  end
})

choujin:addEffect(fk.Damage, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target and player:usedSkillTimes(choujin.name, Player.HistoryGame) > 0 and
      data.to:getMark("@@choujin") > 0 and
      target:isFriend(player) and data.to:isEnemy(player) and
      player:usedEffectTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(1, choujin.name)
  end
})

return choujin
