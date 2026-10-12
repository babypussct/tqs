local shuanghuai = fk.CreateSkill {
  name = "shuanghuai",
}

Fk:loadTranslationTable{
  ["shuanghuai"] = "霜怀",
  [":shuanghuai"] = "每回合限一次，当与你距离1以内的其他角色受到伤害时，你可以选择一项：1.防止此伤害；2.令其从弃牌堆中获得一张【桃】。"..
    "若该角色与你上一次发动时：相同，你与其各摸一张牌；不同，你失去1点体力。",

  ["shuanghuai_prevent"] = "防止此次伤害",
  ["shuanghuai_peach"] = "令%dest从弃牌堆获得【桃】",

  ["@shuanghuai"] = "霜怀",

  ["$shuanghuai1"] = "女子有节，宁兰摧玉折，无负心违愿。",
  ["$shuanghuai2"] = "谦则德之柄，顺则妇之行。",
  ["$shuanghuai3"] = "颜子贵于能改，仲尼嘉其不贰，而况妇人者哉。",
}

shuanghuai:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  times = function(self, player)
    return 1 - player:usedSkillTimes(shuanghuai.name)
  end,
  can_trigger = function(self, event, target, player, data)
    return player ~= target and player:hasSkill(shuanghuai.name) and player:usedSkillTimes(shuanghuai.name) < 1 and
      target:distanceTo(player) == 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player,{
      choices = {"shuanghuai_prevent", "shuanghuai_peach::" .. target.id, "Cancel"},
      skill_name = shuanghuai.name,
    })
    if choice ~= "Cancel" then
      local index = 2
      local mark = player:getMark("@shuanghuai")
      if mark ~= target and mark ~= 0 then
        index = 3
      elseif choice == "shuanghuai_prevent" then
        index = 1
      end
      event:setCostData(self, { choice = choice, tos = { target }, audio_index = index })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local skillName = shuanghuai.name
    local room = player.room

    local side_effect = ""
    local mark = player:getMark("@shuanghuai")
    if mark == 0 then
      room:setPlayerMark(player, "@shuanghuai", target)
    elseif mark == target then
      side_effect = "draw"
    else
      room:setPlayerMark(player, "@shuanghuai", target)
      side_effect = "loseHp"
    end

    local choice = event:getCostData(self).choice
    if choice == "shuanghuai_prevent" then
      data:preventDamage()
    else
      local cards = room:getCardsFromPileByRule("peach", 1, "discardPile")
      if #cards > 0 then
        room:obtainCard(target, cards, true, fk.ReasonJustMove, player, skillName)
      end
    end

    if side_effect == "draw" then
      if not player.dead then
        player:drawCards(1, skillName)
      end
      if not target.dead then
        target:drawCards(1, skillName)
      end
    elseif side_effect == "loseHp" then
      room:loseHp(player, 1, skillName)
    end
  end,
})

shuanghuai:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@shuanghuai", 0)
end)

return shuanghuai
