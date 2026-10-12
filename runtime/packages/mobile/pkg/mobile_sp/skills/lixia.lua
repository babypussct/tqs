local lixia = fk.CreateSkill{
  name = "lixia",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["lixia"] = "礼下",
  [":lixia"] = "锁定技，其他角色的结束阶段，若你不在其攻击范围内，你选择一项：1.摸一张牌；2.令其摸一张牌。"..
  "然后其他角色计算与你的距离-1。",

  ["lixia_draw"] = "令%src摸一张牌",

  ["$lixia1"] = "将军真乃国之栋梁。",
  ["$lixia2"] = "英雄可安身立命于交州之地。",
}

lixia:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(lixia.name) and target.phase == Player.Finish and
      not target:inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw1"}
    if not target.dead then
      table.insert(choices, "lixia_draw:"..target.id)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = lixia.name,
      cancelable = false,
    })
    if choice == "draw1" then
      player:drawCards(1, lixia.name)
    else
      target:drawCards(1, lixia.name)
    end
    if player.dead then return end
    local num = tonumber(player:getMark("@shixie_distance")) - 1
    room:setPlayerMark(player,"@shixie_distance", num > 0 and "+"..num or num)
  end,
})

lixia:addEffect("distance", {
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@shixie_distance"))
    if num < 0 then
      return num
    end
  end,
})

return lixia
