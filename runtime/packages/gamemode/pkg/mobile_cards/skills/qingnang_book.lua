local skill = fk.CreateSkill {
  name = "#qingnang_book_skill",
  attached_equip = "qingnang_book",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["#qingnang_book_skill"] = "青囊书",
}

skill:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getEquipments(Card.SubtypeTreasure)) do
      local card = player:getVirtualEquip(id) or Fk:getCardById(id)
      if card and card:getMark("qingnang_book_durability") > 0 then
        room:removeCardMark(card, "qingnang_book_durability", 1)
        if card:getMark("qingnang_book_durability") == 0 then
          room:sendLog{
            type = "#DestructCards",
            card = Card:getIdList(card),
          }
          room:moveCardTo(card, Card.Void, nil, fk.ReasonJustMove)
        end
        break
      end
    end
    if player.dead then return end
    room:changeMaxHp(player, 1)
    if not player.dead then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skill.name,
      }
    end
  end,
})

return skill
