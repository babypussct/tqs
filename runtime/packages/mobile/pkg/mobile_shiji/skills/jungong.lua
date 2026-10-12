local jungong = fk.CreateSkill {
  name = "jungong",
}

Fk:loadTranslationTable{
  ["jungong"] = "峻攻",
  [":jungong"] = "出牌阶段，你可以弃置X+1张牌或失去X+1点体力（X为你于本回合内发动过本技能的次数），并视为使用一张无距离次数限制的【杀】。"..
  "若此【杀】对目标角色造成伤害，本技能于本回合内失效。",

  ["#jungong"] = "峻攻：你可以执行一项，视为使用一张无距离次数限制的【杀】",
  ["jungong_discard"] = "弃置%arg张牌",
  ["jungong_loseHp"] = "失去%arg点体力",

  ["$jungong1"] = "曹军营守，不能野战，此乃攻敌之机！",
  ["$jungong2"] = "若此营攻之不下，览何颜面见袁公！",
}

jungong:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#jungong",
  interaction = function(self, player)
    local n = player:usedSkillTimes(jungong.name) + 1
    local choices = { "jungong_discard:::"..n }
    if player.hp > 0 then
      table.insert(choices, "jungong_loseHp:::"..n)
    end
    return UI.ComboBox { choices = choices }
  end,
  card_filter = function(self, player, to_select, selected)
    if self.interaction.data:startsWith("jungong_discard") then
      return #selected <= player:usedSkillTimes(jungong.name, Player.HistoryTurn) and not player:prohibitDiscard(to_select)
    else
      return false
    end
  end,
  view_as = function(self, player, cards)
    if self.interaction.data:startsWith("jungong_discard") and
      #cards ~= player:usedSkillTimes(jungong.name, Player.HistoryTurn) + 1 then
      return
    end
    local card = Fk:cloneCard("slash")
    card.skillName = jungong.name
    self.extra_data = cards
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    if self.extra_data and #self.extra_data > 0 then
      room:throwCard(self.extra_data, jungong.name, player, player)
      self.extra_data = nil
    else
      room:loseHp(player, player:usedSkillTimes(jungong.name, Player.HistoryTurn))
    end
  end,
})
jungong:addEffect(fk.Damage, {
  can_refresh = function (self, event, target, player, data)
    return target == player and not data.chain and data.card and table.contains(data.card.skillNames, "jungong")
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:invalidateSkill(player, jungong.name, "-turn")
  end,
})
jungong:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return card and table.contains(card.skillNames, jungong.name)
  end,
  bypass_times = function (self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, jungong.name)
  end,
})

return jungong
