local jinjing = fk.CreateSkill {
  name = "jinjing",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jinjing"] = "金睛",
  [":jinjing"] = "锁定技，其他角色的手牌对你可见。",

  ["$jinjing1"] = "嗯？有妖气！",
  ["$jinjing2"] = "融石为甲，披焰成袍，火眼金睛，踏碎凌霄。",
}

jinjing:addEffect("visibility", {
  card_visible = function(self, player, card)
    if player:hasSkill(jinjing.name) and Fk:currentRoom():getCardArea(card) == Card.PlayerHand then
      return true
    end
  end
})

return jinjing
