local jiaoxia = fk.CreateSkill {
  name = "ol_fd__jiaoxia",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ol_fd__jiaoxia"] = "狡黠",
  [":ol_fd__jiaoxia"] = "锁定技，友方角色的黑色手牌不计入手牌上限。",
}

jiaoxia:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return table.find(Fk:currentRoom().alive_players, function (p)
      return p:hasSkill(jiaoxia.name) and p:isFriend(player)
    end) and card.color == Card.Black
  end,
})

return jiaoxia
