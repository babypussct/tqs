local hongyic = fk.CreateSkill {
  name = "hongyic",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["hongyic"] = "弘毅",
  [":hongyic"] = "锁定技，游戏开始时，你获得2枚“毅”标记；当你造成或受到伤害后，你获得1枚“毅”标记；你至多拥有4枚“毅”标记。<br>"..
  "准备阶段，你选择一项，本回合下个结束阶段你执行另一项：1.摸X张牌（X为你此时的“毅”标记数）；2.弃置所有“毅”标记。",

  ["@hongyic"] = "毅",
  ["#hongyic-choice"] = "弘毅：请选择一项，结束阶段执行另一项",
  ["hongyic_draw"] = "摸%arg张牌",
  ["hongyic_discard"] = "弃置所有“毅”标记",

  ["$hongyic1"] = "路虽千里，行则将至。",
  ["$hongyic2"] = "纵具万险，亦须一试。",
  ["$hongyic3"] = "非弘不能胜其重，非毅无以至其远。",
  ["$hongyic4"] = "士不可以不弘毅，任重而道远。",
}

hongyic:addEffect(fk.GameStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(hongyic.name) and player:getMark("@hongyic") < 4
  end,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@hongyic", math.min(2, 4 - player:getMark("@hongyic")))
  end,
})

local sepc = {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(hongyic.name) and player:getMark("@hongyic") < 4
  end,
  on_use = function (self, event, target, player, data)
    player.room:addPlayerMark(player, "@hongyic", 1)
  end,
}
hongyic:addEffect(fk.Damage, sepc)
hongyic:addEffect(fk.Damaged, sepc)

hongyic:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hongyic.name) and player.phase == Player.Start and
      player:getMark("@hongyic") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {
        "hongyic_draw:::"..player:getMark("@hongyic"),
        "hongyic_discard",
      },
      skill_name = hongyic.name,
      prompt = "#hongyic-choice",
    })
    if choice == "hongyic_discard" then
      room:setPlayerMark(player, "hongyic_draw-turn", player:getMark("@hongyic"))
      room:setPlayerMark(player, "@hongyic", 0)
    else
      room:setPlayerMark(player, "hongyic_draw-turn", -1)
      if player:getMark("@hongyic") > 0 then
        player:drawCards(player:getMark("@hongyic"), hongyic.name)
      end
    end
  end,
})

hongyic:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and target.phase == Player.Finish and player:getMark("hongyic_draw-turn") ~= 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n = player:getMark("hongyic_draw-turn")
    room:setPlayerMark(player, "hongyic_draw-turn", 0)
    if n > 0 then
      player:drawCards(n, hongyic.name)
    else
      room:setPlayerMark(player, "@hongyic", 0)
    end
  end,
})

return hongyic
