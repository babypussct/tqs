local quanchong = fk.CreateSkill{
  name = "quanchong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["quanchong"] = "权宠",
  [":quanchong"] = "锁定技，每轮限一次，结束阶段，你弃置所有牌，并于当前回合结束后执行一个额外的回合。若你的体力值不为全场唯一最大，"..
  "此回合开始时，你失去1点体力。",

  ["$quanchong1"] = "朝堂有我一日，汝便休想翻身。",
  ["$quanchong2"] = "大胆庞宏，竟敢瞧我不起？",
  ["$quanchong3"] = "这点小事，何劳陛下过问？",
  ["$quanchong4"] = "陛下万般恩宠，臣常思竭诚相报。",
}

quanchong:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(quanchong.name) and player.phase == Player.Finish and
      player:usedSkillTimes(quanchong.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("he", quanchong.name)
    if not player.dead then
      player:gainAnExtraTurn(true, quanchong.name)
    end
  end,
})

quanchong:addEffect(fk.TurnStart, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.reason == quanchong.name and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p.hp >= player.hp
      end)
  end,
  on_use = function (self, event, target, player, data)
    player.room:loseHp(player, 1, quanchong.name)
  end,
})

return quanchong
