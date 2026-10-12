
local junwei = fk.CreateSkill{
  name = "m_heg__junwei",
}

Fk:loadTranslationTable{
  ["m_heg__junwei"] = "君威",
  [":m_heg__junwei"] = "出牌阶段，若场上没有你的专属装备，你可以弃置一张牌，从场外使用你的专属装备。你死亡时，同势力角色各失去1点体力。",

  ["#m_heg__junwei"] = "君威：弃置一张牌，使用【%arg】",

  ["$m_heg__junwei1"] = "",
  ["$m_heg__junwei2"] = "",
}

local H = require "packages.hegemony.util"

local mapper = {
  m_heg__lordcaocao = { "mobile__liulongcanjia", Card.Heart, 13 },
  m_heg__lordliubei = { "mobile__dragon_phoenix", Card.Spade, 2 },
  m_heg__lordsunquan = { "mobile__luminous_pearl", Card.Diamond, 6 },
  m_heg__lordyuanshao = { "grand_ensign", Card.Heart, 3 },
}

junwei:addEffect("active", {
  anim_type = "drawcard",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#m_heg__junwei:::"..mapper[player.general][1]
  end,
  card_num = 1,
  target_num = 0,
  can_use = function (self, player)
    return mapper[player.general] and
      Fk:currentRoom():getCardArea(Fk:currentRoom():prepareDeriveCards({ mapper[player.general] }, junwei.name)[1]) == Card.Void
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, junwei.name, player, player)
    local id = room:prepareDeriveCards({ mapper[player.general] }, junwei.name)[1]
    local card = Fk:getCardById(id)
    room:setCardMark(card, MarkEnum.DestructOutEquip, 1)
    if player:canUseTo(card, player) then
      room:useCard{
        from = player,
        tos = { player },
        card = card,
      }
    end
  end,
})

junwei:addEffect(fk.Death, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(junwei.name, false, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if H.compareKingdomWith(p, player) and not p.dead then
        room:loseHp(p, 1, junwei.name)
      end
    end
  end,
})

return junwei
