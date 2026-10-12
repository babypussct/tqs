local fangzong = fk.CreateSkill {
  name = "fangzong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fangzong"] = "芳踪",
  [":fangzong"] = "锁定技，出牌阶段，你使用伤害牌不能指定你攻击范围内的角色为目标；攻击范围内含有你的其他角色使用伤害牌不能指定你为目标。"..
  "结束阶段，你将手牌摸至X张（X为场上存活人数）。",

  ["$fangzong1"] = "一战结缘难再许，痛为大义斩此情！",
  ["$fangzong2"] = "将军处处留情，小女芳心暗许。",
}

fangzong:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fangzong.name) and player.phase == Player.Finish and
      player:getHandcardNum() < #player.room.alive_players
  end,
  on_use = function(self, event, target, player, data)
    local x = #player.room.alive_players - player:getHandcardNum()
    player:drawCards(x, fangzong.name)
  end,
})
fangzong:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    if card and from and from:inMyAttackRange(to) and card.is_damage_card then
      if to:hasSkill(fangzong.name) then
        return true
      end
      if from:hasSkill(fangzong.name) and from.phase == Player.Play then
        return true
      end
    end
  end,
})

return fangzong
