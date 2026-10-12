local guli = fk.CreateSkill {
  name = "os__guli",
}

Fk:loadTranslationTable{
  ["os__guli"] = "孤厉",
  [":os__guli"] = "每回合限一次，你可以将所有手牌当一张无视目标防具、无次数限制且不计入次数的【杀】使用。" ..
  "此牌结算结束后，你可将手牌摸至体力上限，然后若此牌未造成过伤害，你失去1点体力。",

  ["#os__guli"] = "孤厉：你可以将所有手牌当一张无视防具、无次数限制且不计入次数的【杀】使用",
  ["#os__guli-invoke"] = "孤厉：你可以将手牌摸至体力上限，若此牌未造成伤害，你失去体力",

  ["$os__guli1"] = "狼性乖厉，身寡亦不畏群獒！",
  ["$os__guli2"] = "孤身叛主，凶困重围皆不惧！",
}

guli:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#os__guli",
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

    use.extraUse = true
  end,
  after_use = function (self, player, use)
    local room = player.room
    if
      player:isAlive() and
      player:getHandcardNum() < player.maxHp and
      room:askToSkillInvoke(
        player,
        {
          skill_name = guli.name,
          prompt = "#os__guli-invoke",
        }
      )
    then
      player:drawCards(player.maxHp - player:getHandcardNum(), guli.name)
      if not use.damageDealt and player:isAlive() then
        room:loseHp(player, 1, guli.name)
      end
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(guli.name) == 0 and not player:isKongcheng()
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(guli.name) == 0 and not player:isKongcheng()
  end,
})

guli:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, guli.name)
  end,
})

guli:addEffect(fk.TargetSpecified, {
  can_refresh = function (self, event, target, player, data)
    return player:isAlive() and (data.extra_data or {}).guliUser == player.id and data.to:isAlive()
  end,
  on_refresh = function (self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})

return guli
