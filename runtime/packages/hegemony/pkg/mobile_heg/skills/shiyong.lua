local shiyong = fk.CreateSkill{
  name = "m_heg__shiyong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["m_heg__shiyong"] = "恃勇",
  [":m_heg__shiyong"] = "锁定技，你受到伤害后，若：你未发动过〖耀武〗且造成伤害的牌不为红色你摸一张牌；"..
  "你发动过〖耀武〗且造成伤害的牌不为黑色，伤害来源摸一张牌。",

  ["$m_heg__shiyong1"] = "定要关外诸候，知我威名！",
  ["$m_heg__shiyong2"] = "哈哈哈哈！现在谁不知我华雄？",
}

shiyong:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shiyong.name) and data.card then
      if player:getMark("m_heg__yaowu-noclear") > 0 then
        return data.card.color ~= Card.Black and data.from and data.from:isAlive()
      else
        return data.card.color ~= Card.Red
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(shiyong.name)
    if player:getMark("m_heg__yaowu-noclear") > 0 then
      room:notifySkillInvoked(player, shiyong.name, "negative")
      data.from:drawCards(1, shiyong.name)
    else
      room:notifySkillInvoked(player, shiyong.name, "drawcard")
      player:drawCards(1, shiyong.name)
    end
  end,
})

return shiyong
