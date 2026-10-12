
local liangzi = fk.CreateSkill {
  name = "liangzi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["liangzi"] = "梁姿",
  [":liangzi"] = "锁定技，你的装备牌只能当【酒】使用，且每回合前X张【酒】无次数限制（X为场上魏势力角色数）。",

  ["#liangzi"] = "梁姿：你的装备牌只能当【酒】使用",

  ["$liangzi1"] = "葡萄美酒甘于鞠，真定御梨大若拳！",
  ["$liangzi2"] = "天资文藻，朕岂非梁姿？",
}

liangzi:addEffect("viewas", {
  anim_type = "control",
  prompt = "#liangzi",
  pattern = "analeptic",
  filter_pattern = {
    min_num = 1,
    max_num = 1,
    pattern = ".|.|.|.|.|equip",
  },
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("analeptic")
    card.skillName = liangzi.name
    card:addSubcards(cards)
    return card
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})

liangzi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:hasSkill(liangzi.name) and card and card.type == Card.TypeEquip
  end,
})

liangzi:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    if player:hasSkill(liangzi.name) and card and card.name == "analeptic" then
      return player:usedCardTimes("analeptic", Player.HistoryTurn) <=
        #table.filter(Fk:currentRoom().alive_players, function (p)
          return p.kingdom == "wei"
        end)
    end
  end,
})

return liangzi
