local anle = fk.CreateSkill {
  name = "anle",
  tags = { Skill.Compulsory },
  related_skills = { "xiangle" },
}

Fk:loadTranslationTable{
  ["anle"] = "安乐",
  [":anle"] = "锁定技，当你受到伤害后，你移除当前的<a href='#tuoquan_fuchen'>“季汉辅臣”</a>，然后你与当前回合角色各摸一张牌；" ..
  "若你没有上阵的“季汉辅臣”，你视为拥有〖享乐〗。",

  ["$anle1"] = "耳有丝竹之悦，形无案牍之劳，此真乐事。",
  ["$anle2"] = "烦恼皆自扰，心宽体自胖。朕深谙此道！",
}

anle:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(anle.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getTableMark("@tuoquan_fuchen") == 0 then
      return false
    end

    table.forEach(player:getTableMark("@tuoquan_fuchen"), function(fuchen)
      room:addTableMarkIfNeed(player, "tuoquan_removed", fuchen)
    end)
    room:setPlayerMark(player, "@tuoquan_fuchen", 0)

    for _, p in ipairs({ player, room.current }) do
      if p and p:isAlive() then
        p:drawCards(1, anle.name)
      end
    end

    room:handleAddLoseSkills(player, "xiangle", anle.name)
  end,
})

anle:addAcquireEffect(function(self, player, is_start)
  if #player:getTableMark("@tuoquan_fuchen") == 0 then
    player.room:handleAddLoseSkills(player, "xiangle", anle.name, true, is_start)
  end
end)

return anle
