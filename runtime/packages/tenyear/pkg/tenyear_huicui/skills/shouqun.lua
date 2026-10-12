local shouqun = fk.CreateSkill {
  name = "shouqun",
  related_skills = { "ty__yuxiang" },
}

Fk:loadTranslationTable{
  ["shouqun"] = "兽群",
  [":shouqun"] = "摸牌阶段，你可以改为展示牌堆顶你的体力上限张牌，并选择一项：" ..
  "1.获得其中的坐骑牌、锦囊牌、【杀】和【酒】，然后你的体力上限+1（不能超过初始上限）；" ..
  "2.获得展示亮出牌，然后直到你的下回合开始，你获得〖驭象〗且每次受到火焰伤害后，体力上限-1。",

  ["#shouqun-invoke"] = "兽群：你可以放弃摸牌，亮出%arg张牌并选择一项",
  ["shouqun_obtain"] = "获得其中的坐骑牌、锦囊牌、【杀】和【酒】",
  ["shouqun_yuxiang"] = "获得所有亮出牌，获得技能“驭象”",

  ["$shouqun1"] = "山精野怪听我号令，虎豹豺狼随我旗行！",
  ["$shouqun2"] = "象狮虎豹狼豺魈，哇呀呀！皆列阵前行！",
}

shouqun:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Draw and
      not data.phase_end and
      player:hasSkill(shouqun.name)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(
      player,
      { skill_name = shouqun.name, prompt = "#shouqun-invoke:::" .. player.maxHp }
    )
  end,
  on_use = function (self, event, target, player, data)
    ---@type string
    local skillName = shouqun.name
    local room = player.room
    data.phase_end = true

    local toDisplay = room:getNCards(player.maxHp)
    room:turnOverCardsFromDrawPile(player, toDisplay, skillName)
    room:delay(2000)
    if not player:isAlive() then
      return false
    end

    local choice = room:askToChoice(
      player,
      {
        choices = { "shouqun_obtain", "shouqun_yuxiang" },
        skill_name = skillName,
      }
    )

    if choice == "shouqun_obtain" then
      local toObtain = table.filter(toDisplay, function(id)
        local card = Fk:getCardById(id)
        return
          table.contains({ Card.TypeTrick, Card.TypeEquip }, card.type) or
          table.contains({ "slash", "analeptic" }, card.trueName)
      end)

      if #toObtain == 0 then
        return false
      end

      room:obtainCard(player, toObtain, true, fk.ReasonPrey, player, skillName)
      local initialHp = player:getMark("shouqun_initial_hp")
      if player.maxHp < initialHp then
        room:changeMaxHp(player, 1)
      end
    else
      room:obtainCard(player, toDisplay, true, fk.ReasonPrey, player, skillName)
      room:setPlayerMark(player, "shouqun_yuxiang", 1)
      room:handleAddLoseSkills(player, "ty__yuxiang")
    end

    room:cleanProcessingArea(toDisplay, skillName)
  end,
})

shouqun:addEffect(fk.Damaged, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.damageType == fk.FireDamage and player:getMark("shouqun_yuxiang") > 0
  end,
  on_use = function (self, event, target, player, data)
    player.room:changeMaxHp(player, -1)
  end,
})

shouqun:addEffect(fk.TurnStart, {
  priority = 2,
  is_delay_effect = true,
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:getMark("shouqun_yuxiang") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "shouqun_yuxiang", 0)
    room:handleAddLoseSkills(player, "-ty__yuxiang")
  end,
})

shouqun:addAcquireEffect(function (self, player)
  if player:getMark("shouqun_initial_hp") == 0 then
    player.room:setPlayerMark(player, "shouqun_initial_hp", player.maxHp)
  end
end)

shouqun:addLoseEffect(function (self, player, isDeath)
  if isDeath then
    player.room:handleAddLoseSkills(player, "-ty__yuxiang")
  end
end)

return shouqun
