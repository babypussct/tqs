local huzhong = fk.CreateSkill {
  name = "os__huzhong",
}

Fk:loadTranslationTable{
  ["os__huzhong"] = "护众",
  [":os__huzhong"] = "当你于出牌阶段使用普【杀】指定其他角色为唯一目标时，你可以摸一张牌并选择一项：1.此【杀】可额外选择一个目标；" ..
  "2.弃置其一张手牌。然后若此【杀】造成伤害，你本阶段使用【杀】次数+1。",

  ["os__huzhong_own"] = "此【杀】可额外选择一个目标",
  ["os__huzhong_other"] = "弃置%dest一张手牌",
  ["#os__huzhong-extra"] = "护众：此【杀】可额外选择一个目标",
  ["@os__huzhong-phase"] = "护众",

  ["$os__huzhong1"] = "此难当头，吾誓保百姓无恙！",
  ["$os__huzhong2"] = "天崩于前，吾必先众人而死！",
}

huzhong:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huzhong.name) and
      player.phase == Player.Play and data.card.name == "slash" and data:isOnlyTarget(data.to) and
      (#data:getExtraTargets({ bypass_times = true, bypass_distances = false }) > 0 or not data.to:isKongcheng())
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = huzhong.name
    local room = player.room
    player:drawCards(1, skillName)
    if not player:isAlive() then return end
    local all_choices = {"os__huzhong_own", "os__huzhong_other::" .. data.to.id}
    local choices = table.simpleClone(all_choices)
    local targets = data:getExtraTargets({ bypass_times = true, bypass_distances = false })
    if #targets == 0 then
      table.remove(choices, 1)
    end
    local to = data.to
    if to:isKongcheng() then
      table.remove(choices)
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = skillName,
      all_choices = all_choices
    })
    if choice == "os__huzhong_own" then
      local victims = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__huzhong-extra",
        skill_name = skillName,
        cancelable = false
      })
      if #victims > 0 then
        local victim = victims[1]
        data:addTarget(victim)
      end
    else
      local cid = room:askToChooseCard(player, {
        target = to,
        flag = "h",
        skill_name = skillName
      })
      room:throwCard({cid}, skillName, to, player)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.os__huzhong = true
  end,
})

huzhong:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.extra_data or {}).os__huzhong and data.damageDealt
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@os__huzhong-phase")
  end,
})

huzhong:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if player:getMark("@os__huzhong-phase") ~= 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@os__huzhong-phase")
    end
  end,
})

return huzhong
