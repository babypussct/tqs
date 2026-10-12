local yingzi = fk.CreateSkill{
  name = "ld__lordsunquan_yingzi",
  tags = { Skill.Compulsory },
}

yingzi:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    data.n = data.n + 1
  end,
})

yingzi:addEffect("maxcards", {
  fixed_func = function(self, player)
    if player:hasShownSkill(yingzi.name) then
      return player.maxHp
    end
  end
})
yingzi:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(yingzi.name)
      and player.phase == Player.Discard and player:hasShownSkill(yingzi.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke(yingzi.name)
    player.room:notifySkillInvoked(player, yingzi.name, "defensive")
  end,
})

Fk:loadTranslationTable{
  ["ld__lordsunquan_yingzi"] = "英姿",

  [":ld__lordsunquan_yingzi"] = "锁定技，摸牌阶段，你多摸一张牌。你的手牌上限为你的体力上限。",

  ["$ld__lordsunquan_yingzi1"] = "大吴江山，儒将辈出。",
  ["$ld__lordsunquan_yingzi2"] = "千夫奉儒将，百兽伏麒麟",
}

return yingzi
