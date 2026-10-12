local caishi = fk.CreateSkill {
  name = "ofl_heg__caishi",
}

Fk:loadTranslationTable{
  ["ofl_heg__caishi"] = "才识",
  [":ofl_heg__caishi"] = "摸牌阶段结束时，你可以选择一项：1.本回合手牌上限+2；2.回复1点体力，本回合不能对其他角色使用牌。",

  ["ofl_heg__caishi_maxcards"] = "本回合手牌上限+2",
  ["ofl_heg__caishi_recover"] = "回复1点体力，本回合不能对其他角色用牌",

  ["$ofl_heg__caishi1"] = "清识难尚，至德可师。",
  ["$ofl_heg__caishi2"] = "知书达礼，博古通今。",
}

caishi:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(caishi.name) and player.phase == Player.Draw
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "ofl_heg__caishi_maxcards", "ofl_heg__caishi_recover", "Cancel" },
      skill_name = caishi.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "ofl_heg__caishi_maxcards" then
      room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 2)
    else
      room:setPlayerMark(player, "ofl_heg__caishi-turn", 1)
      room:recover{
        who = player,
        num = 1,
        skillName = caishi.name,
      }
    end
  end,
})

caishi:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return card and from and from:getMark("ofl_heg__caishi-turn") > 0 and from ~= to
  end,
})

return caishi
