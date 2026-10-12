local luanchao = fk.CreateSkill {
  name = "luanchao",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["luanchao"] = "乱朝",
  [":luanchao"] = "限定技，每轮开始时，你可以令所有角色依次选择从牌堆获得一张【杀】或【闪】。获得【杀】的角色本轮首次造成的伤害+1。",

  ["#luanchao-invoke"] = "乱朝：令所有角色依次选择从牌堆获得一张【杀】或【闪】",
  ["luanchao_slash"] = "获得一张【杀】，本轮首次造成伤害+1",
  ["luanchao_jink"] = "获得一张【闪】",
  ["@luanchao-round"] = "乱朝+",

  ["$luanchao1"] = "这天下的火，我便再替你们添一把！",
  ["$luanchao2"] = "诸君是要束手待毙，还是放手一搏？",
}

luanchao:addEffect(fk.RoundStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(luanchao.name) and
      player:usedSkillTimes(luanchao.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = luanchao.name,
      prompt = "#luanchao-invoke",
    }) then
      event:setCostData(self, { tos = room:getAlivePlayers() })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if not p.dead then
        local choice = room:askToChoice(p, {
          skill_name = luanchao.name,
          choices = { "luanchao_slash", "luanchao_jink" },
        })
        local card = {}
        if choice == "luanchao_slash" then
          room:addPlayerMark(p, "@luanchao-round", 1)
          card = room:getCardsFromPileByRule("slash")
        else
          card = room:getCardsFromPileByRule("jink")
        end
        if #card > 0 then
          room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonJustMove, luanchao.name, nil, true, p)
        end
      end
    end
  end,
})

luanchao:addEffect(fk.DamageCaused, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("@luanchao-round") > 0
  end,
  on_use = function (self, event, target, player, data)
    data:changeDamage(player:getMark("@luanchao-round"))
    player.room:setPlayerMark(player, "@luanchao-round", 0)
  end,
})

return luanchao
