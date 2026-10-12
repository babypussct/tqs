local luanji = fk.CreateSkill{
  name = "m_ex__luanji",
}

Fk:loadTranslationTable{
  ["m_ex__luanji"] = "乱击",
  [":m_ex__luanji"] = "出牌阶段，你可以将两张手牌当【万箭齐发】使用（不能使用本阶段发动此技能已使用过的花色）；其他角色响应你使用的"..
  "【万箭齐发】打出【闪】时，其摸一张牌；你使用【万箭齐发】结算后，若没有角色受到此牌伤害，你摸此【万箭齐发】指定目标数的牌。",

  ["#m_ex__luanji"] = "乱击：将两张手牌当【万箭齐发】使用，不能使用本阶段已用过的花色",
  ["@m_ex__luanji-phase"] = "乱击",

  ["$m_ex__luanji1"] = "万箭穿心，灭其士气。",
  ["$m_ex__luanji2"] = "卿当与本公同心戮力，共安社稷。",
}

luanji:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#m_ex__luanji",
  filter_pattern = function (self, player, card_name, selected)
    local suits = {"spade", "heart", "club", "diamond"}
    for _, v in ipairs(player:getTableMark("@m_ex__luanji-phase")) do
      table.removeOne(suits, string.sub(v, 5))
    end
    if #suits > 0 then
      return {
        min_num = 2,
        max_num = 2,
        pattern = ".|.|".. table.concat(suits, ",") .. "|^equip",
      }
    end
  end,
  handly_pile = true,
  view_as = function(self, player, cards)
    if #cards ~= 2 then return end
    local card = Fk:cloneCard("archery_attack")
    card:addSubcards(cards)
    return card
  end,
  before_use = function (self, player, use)
    local mark = player:getTableMark("@m_ex__luanji-phase")
    for _, id in ipairs(use.card.subcards) do
      table.insertIfNeed(mark, Fk:getCardById(id):getSuitString(true))
    end
    player.room:setPlayerMark(player, "@m_ex__luanji-phase", mark)
  end,
})
luanji:addEffect(fk.CardResponding, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(luanji.name) and data.card.name == "jink" and
      data.responseToEvent and data.responseToEvent.from == player and
      data.responseToEvent.card.trueName == "archery_attack" and not target.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    target:drawCards(1, luanji.name)
  end,
})
luanji:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(luanji.name) and data.card.trueName == "archery_attack" and
      not data.damageDealt and #data.tos > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player:drawCards(#data.tos, luanji.name)
  end,
})

return luanji
