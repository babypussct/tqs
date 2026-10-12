
local kongcheng = fk.CreateSkill{
  name = "hs__kongcheng",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["hs__kongcheng"] = "空城",
  [":hs__kongcheng"] = "锁定技，若你没有手牌：1.当你成为【杀】或【决斗】的目标时，取消此目标；"..
  "2.你的回合外，其他角色交给你的牌改为置于你的武将牌上，摸牌阶段开始时，你获得这些牌。",

  ["zither"] = "琴",

  ["$hs__kongcheng1"] = "（抚琴声）",
  ["$hs__kongcheng2"] = "（抚琴声）",
}

kongcheng:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kongcheng.name) and
      player:isKongcheng() and (data.card.trueName == "slash" or data.card.name == "duel")
  end,
  on_use = function(self, event, target, player, data)
    data:cancelTarget(player)
  end
})

kongcheng:addEffect(fk.BeforeCardsMove, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(kongcheng.name) and player:isKongcheng() and player.room:getCurrent() ~= player then
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonGive and move.to == player and move.toArea == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    local mirror_moves = {}
    for _, move in ipairs(data) do
      if move.moveReason == fk.ReasonGive and move.to == player and move.toArea == Card.PlayerHand then
        local mirror_info = move.moveInfo
        if #mirror_info > 0 then
          move.moveInfo = {}
          local mirror_move = move:copy()
          mirror_move.toArea = Card.PlayerSpecial
          mirror_move.specialName = "zither"
          mirror_move.moveVisible = true
          mirror_move.moveMark = nil
          mirror_move.moveInfo = mirror_info
          table.insert(mirror_moves, mirror_move)
        end
      end
    end
    table.insertTable(data, mirror_moves)
  end
})

kongcheng:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kongcheng.name) and player == target and player.phase == Player.Draw and
      #player:getPile("zither") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:obtainCard(player, player:getPile("zither"), true)
  end
})

return kongcheng
