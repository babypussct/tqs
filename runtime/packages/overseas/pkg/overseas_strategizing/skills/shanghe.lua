local shanghe = fk.CreateSkill {
  name = "os__shanghe",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os__shanghe"] = "觞贺",
  [":os__shanghe"] = "限定技，当你进入濒死状态时，你可令所有其他角色各交给你一张牌，若其中没有【酒】，你将体力回复至1点。",

  ["#os__shanghe-give"] = "觞贺：请交给 %src 一张牌",

  ["$os__shanghe1"] = "今使海内回心，望风而愿治，皆明公之功也。",
  ["$os__shanghe2"] = "明公平定兵乱，使百姓可安，粲当奉觞以贺之。",
}

shanghe:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(shanghe.name) and
      player:usedSkillTimes(shanghe.name, Player.HistoryGame) == 0 and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local not_include = true
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then return end
      if not p:isNude() and not p.dead then
        local id = room:askToCards(p, {
          min_num = 1,
          max_num = 1,
          skill_name = shanghe.name,
          include_equip = true,
          prompt = "#os__shanghe-give:"..player.id,
          cancelable = false,
        })[1]
        if Fk:getCardById(id).trueName == "analeptic" then
          not_include = false
        end
        room:moveCardTo(id, Player.Hand, player, fk.ReasonGive, shanghe.name, nil, false, p)
      end
    end

    if not_include and not player.dead and player.hp < 1 then
      room:recover{
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = shanghe.name,
      }
    end
  end,
})

return shanghe
