local xianghai = fk.CreateSkill {
  name = "xianghai",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xianghai"] = "乡害",
  [":xianghai"] = "锁定技，其他角色的手牌上限-1，你手牌中的装备牌均视为【酒】。",

  ["$xianghai1"] = "快快闪开，伤到你们可就不好了，哈哈哈！",
  ["$xianghai2"] = "你自己撞上来的，这可怪不得小爷我！",
}

xianghai:addEffect("filter", {
  anim_type = "offensive",
  card_filter = function(self, to_select, player)
    return player:hasSkill(xianghai.name) and to_select.type == Card.TypeEquip and
      table.contains(player:getCardIds("h"), to_select.id)
  end,
  view_as = function(self, player, to_select)
    return Fk:cloneCard("analeptic", to_select.suit, to_select.number)
  end,
})
xianghai:addEffect("maxcards", {
  correct_func = function(self, player)
    return - #table.filter(Fk:currentRoom().alive_players, function(p)
      return p:hasSkill(xianghai.name) and p ~= player
    end)
  end,
})

return xianghai
