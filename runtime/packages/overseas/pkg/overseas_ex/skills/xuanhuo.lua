local xuanhuo = fk.CreateSkill {
  name = "os_ex__xuanhuo"
}

Fk:loadTranslationTable{
  ["os_ex__xuanhuo"] = "眩惑",
  [":os_ex__xuanhuo"] = "摸牌阶段结束时，你可以交给一名其他角色两张牌并选择另一名角色，然后获得牌的角色选择一项："..
  "1.视为对你选择的角色使用一张【杀】或【决斗】；2.你获得其两张牌。",

  ["#os_ex__xuanhuo-target"] = "眩惑：选择两名角色，交给第一名角色两张牌，其视为对第二名角色使用【杀】或【决斗】，否则你获得其两张牌",
  ["#os_ex__xuanhuo-use"] = "眩惑：视为对 %dest 使用【杀】或【决斗】，或点“取消”令 %src 获得你的两张牌",

  ["$os_ex__xuanhuo1"] = "收人钱财，替人消灾。",
  ["$os_ex__xuanhuo2"] = "哼，叫你十倍奉还！",
}

xuanhuo:addAuxActiveSkill("#os_ex__xuanhuo_active", {
  card_num = 2,
  target_num = 2,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return to_select ~= player and #selected < 2 and #selected_cards == 2
  end,
})

xuanhuo:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuanhuo.name) and player.phase == Player.Draw and #player:getCardIds("he") > 1
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "#os_ex__xuanhuo_active",
      prompt = "#os_ex__xuanhuo-target",
    })
    if success and dat then
      event:setCostData(self, { cards = dat.cards, tos = dat.targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = xuanhuo.name
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, to, fk.ReasonGive, skillName, nil, false, player)
    if not to:isAlive() then
      return false
    end

    local victim = event:getCostData(self).tos[2]
    if not victim:isAlive() then
      if player:isAlive() and not to:isKongcheng() then
        room:obtainCard(player, room:askToChooseCards(
          player,
          {
            min = 2,
            max = 2,
            target = to,
            flag = "he",
            skill_name = skillName,
          }
        ), false, fk.ReasonPrey, player, skillName)
        return false
      end
    end
    local use = room:askToUseVirtualCard(to, {
      name = "slash,duel",
      skill_name = xuanhuo.name,
      prompt = "#os_ex__xuanhuo-use:" .. player.id .. ":" .. victim.id,
      extra_data = {
        must_targets = { victim.id },
        bypass_distances = true,
        bypass_times = true,
      },
      cancelable = true,
    })
    if use then
      room:useCard(use)
    elseif not to:isNude() then
      local cards = room:askToChooseCards(player, {
        min = 2,
        max = 2,
        target = to,
        flag = "he",
        skill_name = skillName,
      })
      room:obtainCard(player, cards, false, fk.ReasonPrey, player, skillName)
    end
  end,
})

return xuanhuo
