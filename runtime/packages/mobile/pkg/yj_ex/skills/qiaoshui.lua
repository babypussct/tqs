local qiaoshui = fk.CreateSkill {
  name = "m_ex__qiaoshui",
}

Fk:loadTranslationTable{
  ["m_ex__qiaoshui"] = "巧说",
  [":m_ex__qiaoshui"] = "出牌阶段限一次，你可以与一名角色拼点。"..
  "若你赢，本阶段你使用下一张基本牌或普通锦囊牌可以多选择或少选择一个目标（无距离限制）；若你没赢，本阶段你不能使用锦囊牌。",

  ["#m_ex__qiaoshui-active"] = "巧说：选择1名其他角色，与其拼点",
  ["#m_ex__qiaoshui-choose"] = "巧说：你可以为使用的%arg增加/减少1个目标",
  ["@m_ex__qiaoshui-phase"] = "巧说",

  ["$m_ex__qiaoshui1"] = "此事听我一言，定有分明之理。",
  ["$m_ex__qiaoshui2"] = "今日之事，听我一言便是。",
}

qiaoshui:addEffect("active", {
  anim_type = "control",
  prompt = "#m_ex__qiaoshui-active",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(qiaoshui.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, qiaoshui.name)
    if pindian.results[target].winner == player then
      room:setPlayerMark(player, "@m_ex__qiaoshui-phase", "pindianwin")
    else
      room:setPlayerMark(player, "@m_ex__qiaoshui-phase", "pindiannotwin")
    end
  end,
})

qiaoshui:addEffect(fk.AfterCardTargetDeclared, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiaoshui.name) and player:getMark("@m_ex__qiaoshui-phase") == "pindianwin" and
      data.card.type ~= Card.TypeEquip and data.card.sub_type ~= Card.SubtypeDelayedTrick
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@m_ex__qiaoshui-phase", 0)
    local targets = data:getExtraTargets({bypass_distances = true})
    if #data.tos > 1 then
      table.insertTableIfNeed(targets, data.tos)
    end
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#m_ex__qiaoshui-choose:::"..data.card:toLogString(),
      skill_name = qiaoshui.name,
      cancelable = true,
      extra_data = table.map(data.tos, Util.IdMapper),
      target_tip_name = "addandcanceltarget_tip",
    })
    if #tos > 0 then
      local to = tos[1]
      if table.contains(data.tos, to) then
        data:removeTarget(to)
      else
        data:addTarget(to)
      end
    end
  end,
})

qiaoshui:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("@m_ex__qiaoshui-phase") == "pindiannotwin" and card.type == Card.TypeTrick
  end,
})

qiaoshui:addLoseEffect(function(self, player, is_death)
  player.room:setPlayerMark(player, "@m_ex__qiaoshui-phase", 0)
end)

return qiaoshui
