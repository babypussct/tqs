
local zongzi = fk.CreateSkill{
  name = "zongzi",
  tags = { Skill.Wake },
  related_skills = { "jinhuo" },
}

Fk:loadTranslationTable{
  ["zongzi"] = "纵恣",
  [":zongzi"] = "觉醒技，你本局游戏已造成或受到共计至少3点伤害后，你加1点体力上限，回复1点体力，然后你选择一项："..
  "1.再增加1点体力上限，失去〖精练〗并获得〖矜祸〗；2.令〖挟术〗取消次数限制。",

  ["zongzi_jinhuo"] = "再加1点体力上限，失去“精练”，获得“矜祸”",
  ["zongzi_xieshu"] = "“挟术”取消次数限制",

  ["$zongzi1"] = "",
  ["$zongzi2"] = "",
}

local spec = {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zongzi.name) and
      player:usedSkillTimes(zongzi.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local n = data.damage
    local id = player.room.logic:getCurrentEvent().id
    player.room.logic:getActualDamageEvents(1, function(e)
      local damage = e.data
      if e.id < id then
        if damage.from == player then
          n = n + damage.damage
        end
        if damage.to == player then
          n = n + damage.damage
        end
        return n > 2
      end
    end, Player.HistoryGame)
    return n > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player.dead then return end
    room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = zongzi.name,
    }
    if player.dead then return end
    local choice = room:askToChoice(player, {
      skill_name = zongzi.name,
      choices = { "zongzi_jinhuo", "zongzi_xieshu" },
    })
    if choice == "zongzi_jinhuo" then
      room:changeMaxHp(player, 1)
      if player.dead then return end
      room:handleAddLoseSkills(player, "-jinglian|jinhuo")
    else
      room:setPlayerMark(player, "ty__xieshu", 1)
    end
  end,
}
zongzi:addEffect(fk.Damage, spec)
zongzi:addEffect(fk.Damaged, spec)

return zongzi
