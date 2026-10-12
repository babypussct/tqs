local zuobao = fk.CreateSkill {
  name = "zuobao",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["zuobao"] = "作保",
  [":zuobao"] = "限定技，你参与的议事展示意见时，你可以令此次议事中，所有♠意见牌视为<font color='red'>♥</font>。",

  ["#zuobao-invoke"] = "作保：是否令本次议事所有♠意见牌视为<font color='red'>♥</font>？",

  ["$zuobao1"] = "此计欠通，那刘备乃汉室宗亲，可以配得郡主！",
  ["$zuobao2"] = "内穿铠甲，外罩袍服，防而不备，备而不防。"
}

local U = require "packages.utility.utility"

zuobao:addEffect(U.DiscussionCardsDisplaying, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zuobao.name) and data.results[player] and
      player:usedSkillTimes(zuobao.name, Player.HistoryGame) == 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zuobao.name,
      prompt = "#zuobao-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, result in pairs(data.results) do
      if result.toCards then
        table.insertTableIfNeed(cards, result.toCards)
      end
    end
    room:setBanner("zuobao-phase", cards)
  end,
})

zuobao:addEffect(U.DiscussionFinished, {
  can_refresh = function (self, event, target, player, data)
    return player.room:getBanner("zuobao-phase")
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setBanner("zuobao-phase", 0)
  end,
})

zuobao:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return Fk:currentRoom():getBanner("zuobao-phase") and
      table.contains(Fk:currentRoom():getBanner("zuobao-phase"), card.id) and
      card.suit == Card.Spade
  end,
  view_as = function(self, player, to_select)
    return Fk:cloneCard(to_select.name, Card.Heart, to_select.number)
  end,
})

return zuobao
