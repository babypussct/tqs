local bingjie = fk.CreateSkill {
  name = "ol__bingjie",
}

Fk:loadTranslationTable{
  ["ol__bingjie"] = "秉节",
  [":ol__bingjie"] = "出牌阶段开始时，你可以减1点体力上限，然后当你本回合使用【杀】或普通锦囊牌指定第一个目标后，除你以外的目标角色各弃置一张牌。",

  ["@@ol__bingjie-turn"] = "秉节",

  ["$ol__bingjie1"] = "秉节之使，衔命直指。",
  ["$ol__bingjie2"] = "执德秉节，不负国恩。",
}

bingjie:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bingjie.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@ol__bingjie-turn", 1)
    room:changeMaxHp(player, -1)
  end,
})

bingjie:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:getMark("@@ol__bingjie-turn") > 0 and
      data.firstTarget and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(data.use.tos, function(p)
        return p ~= player and p:isAlive()
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.filter(data.use.tos, function(p)
      return p ~= player and p:isAlive()
    end)
    room:sortByAction(tos)
    for _, to in ipairs(tos) do
      if to:isAlive() and not to:isNude() then
        room:askToDiscard(
          to,
          {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            skill_name = bingjie.name,
            cancelable = false,
          }
        )
      end
    end
  end,
})

return bingjie
