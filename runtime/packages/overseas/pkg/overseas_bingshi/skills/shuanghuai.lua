local shuanghuai = fk.CreateSkill {
  name = "os__shuanghuai",
}

Fk:loadTranslationTable{
  ["os__shuanghuai"] = "霜怀",
  [":os__shuanghuai"] = "每回合限一次，当与你距离1以内的角色受到伤害时，你可以选择一项：1.防止此伤害；2.令其从弃牌堆中获得一张【桃】。"..
    "若其为此技能上次发动的目标，你与其各摸一张牌，否则你失去1点体力。",

  ["os__shuanghuai_prevent"] = "防止此次伤害",
  ["os__shuanghuai_peach"] = "令%dest从弃牌堆获得【桃】",

  ["@os__shuanghuai"] = "霜怀",

  ["$os__shuanghuai1"] = "妾闻古之烈女，守节持义，至死不渝。",
  ["$os__shuanghuai2"] = "吾生虽艰，然不改己志；烈女虽穷，然不负其节。",
  ["$os__shuanghuai3"] = "兄长若违我愿，身赴清池可矣。",
}

shuanghuai:addEffect(fk.DetermineDamageInflicted, {
  anim_type = "defensive",
  times = function(self, player)
    return 1 - player:usedSkillTimes(shuanghuai.name)
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shuanghuai.name) and player:usedSkillTimes(shuanghuai.name) < 1 and
      target:distanceTo(player) <= 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player,{
      choices = {"os__shuanghuai_prevent", "os__shuanghuai_peach::" .. target.id, "Cancel"},
      skill_name = shuanghuai.name,
    })
    if choice ~= "Cancel" then
      local index = 2
      local mark = player:getMark("@os__shuanghuai")
      if mark ~= target and mark ~= 0 then
        index = 3
      elseif choice == "os__shuanghuai_prevent" then
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
    local mark = player:getMark("@os__shuanghuai")
    if mark == 0 then
      room:setPlayerMark(player, "@os__shuanghuai", target)
    elseif mark == target then
      side_effect = "draw"
    else
      room:setPlayerMark(player, "@os__shuanghuai", target)
      side_effect = "loseHp"
    end

    local choice = event:getCostData(self).choice
    if choice == "os__shuanghuai_prevent" then
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
    elseif side_effect == "loseHp" and player:isAlive() then
      room:loseHp(player, 1, skillName)
    end
  end,
})

shuanghuai:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@os__shuanghuai", 0)
end)

return shuanghuai
