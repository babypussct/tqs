
local ganjue = fk.CreateSkill {
  name = "ganjue",
}

Fk:loadTranslationTable{
  ["ganjue"] = "敢决",
  [":ganjue"] = "出牌阶段限一次，你可以将一张装备区的牌当不计入次数且无距离次数限制的【杀】使用，若目标角色没有与此【杀】花色相同的手牌，"..
  "其不可响应此【杀】。",

  ["#ganjue"] = "敢决：将装备区一张牌当无距离次数限制的【杀】使用，若目标没有相同颜色手牌则不可响应",

  ["$ganjue1"] = "坚毅果敢，勇而有决，大丈夫当如是也。",
  ["$ganjue2"] = "将贵及时应变，早溃贼军。",
}

ganjue:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#ganjue",
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|equip",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local card = Fk:cloneCard("slash")
    card:addSubcard(cards[1])
    card.skillName = ganjue.name
    return card
  end,
  before_use = function (self, player, use)
    use.extraUse = true
  end,
  enabled_at_play = function (self, player)
    return player:usedSkillTimes(ganjue.name, Player.HistoryPhase) == 0
  end,
})

ganjue:addEffect("targetmod", {
  bypass_distances = function (self, player, skill, card, to)
    return card and table.contains(card.skillNames, ganjue.name)
  end,
  bypass_times = function (self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, ganjue.name)
  end,
})

ganjue:addEffect(fk.PreCardEffect, {
  can_refresh = function(self, event, target, player, data)
    return
      player == data.to and
      data.card.trueName == "slash" and
      table.contains(data.card.skillNames, ganjue.name) and
      not table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):compareSuitWith(data.card)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsive = true
  end,
})

return ganjue
