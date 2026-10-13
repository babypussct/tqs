local xunzhi = fk.CreateSkill {
  name = "xunzhi",
}

Fk:loadTranslationTable{
  ["xunzhi"] = "殉志",
  [":xunzhi"] = "准备阶段，若你的上家和下家与你的体力值均不相等，你可以失去1点体力，你的手牌上限+2。",

  ["$xunzhi1"] = "春秋大义，自在我心！",
  ["$xunzhi2"] = "成大义者，这点牺牲算不得什么！",
}

xunzhi:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xunzhi.name) and player.phase == Player.Start then
      for _, p in ipairs(player.room:getOtherPlayers(player, false)) do
        if (player:getNextAlive() == p or p:getNextAlive() == player) and player.hp == p.hp then return end
      end
      return player.hp > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, xunzhi.name)
    if not player.dead then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 2)
    end
  end,
})

return xunzhi
