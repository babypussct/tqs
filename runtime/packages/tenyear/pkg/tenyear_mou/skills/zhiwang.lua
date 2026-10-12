local zhiwang = fk.CreateSkill {
  name = "zhiwang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhiwang"] = "质亡",
  [":zhiwang"] = "锁定技，结束阶段开始时，你弃置装备区里的所有牌。若你以此法弃置了牌，你选择弃牌堆里的一张伤害牌，" ..
  "令一名其他角色使用此牌（此牌对你造成的伤害视为无来源）。",

  ["#zhiwang-chooseCard"] = "质亡：请选择一张伤害牌",
  ["#zhiwang-chooseTarget"] = "质亡：请选择一名其他角色使用此牌",
  ["#zhiwang-use"] = "质亡：请使用此牌",

  ["$zhiwang1"] = "宁为玉碎，不为瓦全！",
  ["$zhiwang2"] = "生义相左，唯舍生而取忠孝！",
}

zhiwang:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhiwang.name) and player.phase == Player.Finish and #player:getCardIds("e") > 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = zhiwang.name
    local room = player.room
    local tempEquipments = player:getCardIds("e")
    room:throwCard(player:getCardIds("e"), skillName, player, player)
    if player:isAlive() and table.find(tempEquipments, function(id) return not table.contains(player:getCardIds("e"), id) end) then
      local targets = room:getOtherPlayers(player, false)
      if #targets == 0 then
        return false
      end

      local damageCards = table.filter(room.discard_pile, function(id) return Fk:getCardById(id).is_damage_card end)
      if #damageCards == 0 then
        return false
      end

      local toUse = room:askToChooseCard(
        player,
        {
          target = player,
          flag = { card_data = { { "pile_discard", damageCards } } },
          skill_name = skillName,
          prompt = "#zhiwang-chooseCard",
        }
      )

      local to = room:askToChoosePlayers(
        player,
        {
          targets = targets,
          min_num = 1,
          max_num = 1,
          skill_name = skillName,
          prompt = "#zhiwang-chooseTarget",
          cancelable = false,
        }
      )[1]

      local use = room:askToUseRealCard(
        to,
        {
          pattern = { toUse },
          skill_name = skillName,
          cancelable = false,
          extra_data = {
            expand_pile = { toUse },
          },
          prompt = "#zhiwang-use",
          skip = true,
        }
      )

      if use then
        use.extra_data = use.extra_data or {}
        use.extra_data.zhiwangUser = player

        room:useCard(use)
      end
    end
  end,
})

zhiwang:addEffect(fk.PreDamage, {
  is_delay_effect = true,
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if not data.card then
      return false
    end

    local use = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not use then
      return false
    end

    return (use.data.extra_data or {}).zhiwangUser == player and player == data.to and player:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    data.from = nil
  end,
})

return zhiwang
