local tanshi = fk.CreateSkill {
  name = "jiange__tanshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiange__tanshi"] = "贪食",
  [":jiange__tanshi"] = "锁定技，结束阶段，你弃置一张手牌。",
}

tanshi:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tanshi.name) and player.phase == Player.Finish and
      not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = tanshi.name,
      cancelable = false,
    })
  end,
})

return tanshi
