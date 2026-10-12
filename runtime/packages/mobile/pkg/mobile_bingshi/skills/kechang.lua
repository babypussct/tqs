local kechang = fk.CreateSkill {
  name = "kechang",
  tags = { Skill.Lord, Skill.Compulsory },
  dynamic_desc = function (self, player, lang)
    if player:getMark("@kechang_level-noclear") > 1 then
      return "kechang_update"
    else
      return "kechang"
    end
  end,
}

Fk:loadTranslationTable{
  ["kechang"] = "克昌",
  [":kechang"] = "一级：主公技，锁定技，群势力角色使用【杀】无距离限制。<br/>" ..
  "二级：主公技，锁定技，群势力角色使用【杀】无距离限制；你使用的【杀】不可被响应。",

  ["@kechang_level-noclear"] = "克昌等级",
  [":kechang_update"] = "主公技，锁定技，群势力角色使用【杀】无距离限制；你使用的【杀】不可被响应。",

  ["$kechang1"] = "假使天命在魏，何使司马专权？",
}

kechang:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kechang.name) and
      data.card.trueName == "slash" and player:getMark("@kechang_level-noclear") > 1
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = player.room:getAllPlayers(false)
  end,
})

kechang:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return
      card and
      card.trueName == "slash" and
      player.kingdom == "qun" and
      table.find(Fk:currentRoom().alive_players, function(p)
        return p:hasSkill(kechang.name)
      end)
  end,
})

kechang:addAcquireEffect(function(self, player)
  player.room:setPlayerMark(player, "@kechang_level-noclear", 1)
end)

kechang:addLoseEffect(function(self, player, isDeath)
  if not isDeath then
    player.room:setPlayerMark(player, "@kechang_level-noclear", 0)
  end
end)

return kechang
