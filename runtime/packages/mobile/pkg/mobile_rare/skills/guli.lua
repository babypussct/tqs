local guli = fk.CreateSkill {
  name = "guli",
}

Fk:loadTranslationTable{
  ["guli"] = "孤厉",
  [":guli"] = "出牌阶段限一次，你可以将所有手牌当一张无视防具的【杀】使用。此牌结算后，若此牌造成过伤害，你可以失去1点体力，然后将手牌摸至体力上限。",

  ["#guli"] = "孤厉：你可以将所有手牌当一张无视防具的【杀】使用",
  ["#guli-invoke"] = "孤厉：你可以失去1点体力，将手牌补至体力上限",

  ["$guli1"] = "今若弑此昏聩主，纵蒙恶名又如何？",
  ["$guli2"] = "韩玄少谋多忌，吾今当诛之！",
}

guli:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#guli",
  filter_pattern = function (self, player, card_name, selected)
    local cards = player:getCardIds("h")
    local n = #cards
    if n > 0 then
      return {
        min_num = n,
        max_num = n,
        pattern = ".|.|.|hand",
        subcards = cards
      }
    end
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, player, cards)
    local card = Fk:cloneCard("slash")
    card:addSubcards(player:getCardIds("h"))
    card.skillName = guli.name
    return card
  end,
  before_use = function (self, player, use)
    use.extra_data = use.extra_data or {}
    use.extra_data.guliUser = player.id
  end,
  after_use = function (self, player, use)
    local room = player.room
    if use.damageDealt and not player.dead and
      player.room:askToSkillInvoke(player, {
        skill_name = guli.name,
        prompt = "#guli-invoke",
      }) then
      room:loseHp(player, 1, guli.name)
      if player.dead or player:getHandcardNum() >= player.maxHp then return end
      player:drawCards(player.maxHp - player:getHandcardNum(), "guli")
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(guli.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
})
guli:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(player:getTableMark("guli-phase"), to.id)
  end,
})
guli:addEffect(fk.TargetSpecified, {
  can_refresh = function (self, event, target, player, data)
    return not player.dead and (data.extra_data or {}).guliUser == player.id and not data.to.dead
  end,
  on_refresh = function (self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})

return guli
