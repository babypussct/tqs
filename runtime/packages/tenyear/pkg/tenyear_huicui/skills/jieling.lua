local jieling = fk.CreateSkill {
  name = "jieling",
}

Fk:loadTranslationTable{
  ["jieling"] = "介绫",
  [":jieling"] = "出牌阶段每种花色限一次，你可以将两张花色不同的手牌当无距离次数限制的【杀】使用。若此【杀】：造成伤害，其失去1点体力；"..
  "没造成伤害，其获得一个“生妒”标记。",

  ["#jieling"] = "介绫：将两张花色不同的手牌当【杀】使用，若造成伤害其失去1点体力，若未造成伤害其获得“生妒”标记",
  ["@jieling-phase"] = "介绫",

  ["$jieling1"] = "来人，送冯氏上路！",
  ["$jieling2"] = "我有一求，请姐姐赴之。",
}

jieling:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#jieling",
  pattern = "slash",
  handly_pile = true,
  filter_pattern = function (self, player, card_name, selected)
    local suits = {"spade", "heart", "club", "diamond"}
    for _, v in ipairs(player:getTableMark("jieling-phase")) do
      table.removeOne(suits, v)
    end
    if #suits > 1 then
      for _, id in ipairs(selected) do
        table.removeOne(suits, Fk:getCardById(id):getSuitString())
      end
      if #suits > 0 then
        return {
          max_num = 2,
          min_num = 2,
          pattern = ".|.|".. table.concat(suits, ",") .. "|^equip",
        }
      end
    end
  end,
  view_as = function (self, player, cards)
    if #cards ~= 2 then return end
    local card = Fk:cloneCard("slash")
    card:addSubcards(cards)
    card.skillName = jieling.name
    return card
  end,
  before_use = function (self, player, use)
    use.extraUse = true
    local room = player.room
    for _, id in ipairs(use.card.subcards) do
      room:addTableMark(player, "jieling-phase", Fk:getCardById(id):getSuitString())
    end
  end,
  after_use = function (self, player, use)
    local room = player.room
    for _, p in ipairs(use.tos) do
      if not p.dead then
        if use.damageDealt and use.damageDealt[p] then
          room:loseHp(p, 1, jieling.name)
        elseif table.find(room.alive_players, function (q)
          return q:hasSkill("shengdu", true)
        end) then
          room:addPlayerMark(p, "@shengdu", 1)
        end
      end
    end
  end,
  enabled_at_response = Util.FalseFunc,
})

jieling:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(card.skillNames, jieling.name)
  end,
  bypass_times = function (self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, jieling.name)
  end,
})

return jieling
