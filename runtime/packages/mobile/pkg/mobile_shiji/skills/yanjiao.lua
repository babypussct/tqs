local yanjiao = fk.CreateSkill {
  name = "mobile__yanjiao",
}

Fk:loadTranslationTable{
  ["mobile__yanjiao"] = "严教",
  [":mobile__yanjiao"] = "出牌阶段限一次，你可以将手牌中一种花色的所有牌交给一名其他角色，然后对其造成1点伤害，若如此做，"..
  "你的下个回合开始时，你摸X张牌（X为你以此法给出的牌数）。",

  ["#mobile__yanjiao"] = "严教：选择一种花色和一名角色，将手牌中所有该花色的牌交给其并对其造成1点伤害",
  ["@mobile__yanjiao"] = "严教",

  ["$mobile__yanjiao1"] = "此篇未记，会儿便不可嬉戏。",
  ["$mobile__yanjiao2"] = "母亲虽严，却皆为汝好。",
}

yanjiao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#mobile__yanjiao",
  interaction = function(self, player)
    local all_choices = {"log_spade", "log_heart", "log_club", "log_diamond"}
    local choices = table.filter(all_choices, function (s)
      return table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getSuitString(true) == s
      end) ~= nil
    end)
    return UI.ComboBox {choices = choices, all_choices = all_choices}
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(yanjiao.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getSuitString(true) == self.interaction.data
    end)
    room:addPlayerMark(player, "@mobile__yanjiao", #cards)
    room:moveCardTo(cards, Player.Hand, target, fk.ReasonGive, yanjiao.name, nil, false, player)
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = yanjiao.name,
      }
    end
  end,
})
yanjiao:addEffect(fk.TurnStart, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player:getMark("@mobile__yanjiao") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("@mobile__yanjiao")
    room:setPlayerMark(player, "@mobile__yanjiao", 0)
    player:drawCards(n, yanjiao.name)
  end,
})

return yanjiao
