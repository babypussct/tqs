local quxian = fk.CreateSkill {
  name = "quxian",
}

Fk:loadTranslationTable{
  ["quxian"] = "驱险",
  [":quxian"] = "回合开始时和结束时，你可以从牌堆中获得一张【杀】并选择一名其他角色，攻击范围内含有有其的其他角色依次可以对其使用一张【杀】，"..
    "每有一名角色使用【杀】你摸一张牌。若其未以此法受到过伤害，未使用【杀】的角色各失去X点体力（X为以此法使用【杀】的角色数）。",

  ["#quxian-choose"] = "驱险：选择一名角色，攻击范围含有其的其他角色可以对其使用【杀】",
  ["#quxian-use"] = "驱险：你可以对 %dest 使用【杀】",

  ["$quxian1"] = "曹贼坐据之处，建功立业之途。",
  ["$quxian2"] = "策马赴国难，醉卧青山头。",
}


---@type TrigSkelSpec<TurnFunc>
local spec = {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(quxian.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:getCardsFromPileByRule("slash", 1)
    if #card > 0 then
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, quxian.name, nil, false, player)
    end
    if player.dead then return end
    local targets = room:getOtherPlayers(player, false)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = quxian.name,
      prompt = "#quxian-choose",
      cancelable = false,
    })[1]
    targets = table.filter(room.players, function (p)
      return not p.dead and p:inMyAttackRange(to)
    end)
    if #targets == 0 then return end
    local x = 0
    local to_loseHp = {}
    local no_damage = true
    for _, p in ipairs(targets) do
      if not p.dead then
        local use = room:askToUseCard(p, {
          skill_name = quxian.name,
          pattern = "slash",
          prompt = "#quxian-use::"..to.id,
          extra_data = {
            bypass_times = true,
            exclusive_targets = {to.id},
          }
        })
        if use then
          use.extraUse = true
          room:useCard(use)
          x = x + 1
          if use.damageDealt and use.damageDealt[to] then
            no_damage = false
          end
        else
          table.insert(to_loseHp, p)
        end
      end
    end
    if x > 0 and not player.dead then
      player:drawCards(x, quxian.name)
    end
    if no_damage then
      x = #targets - #to_loseHp
      if x > 0 then
        for _, p in ipairs(to_loseHp) do
          if not p.dead then
            room:loseHp(p, x, quxian.name)
          end
        end
      end
    end
  end,
}

quxian:addEffect(fk.TurnStart, spec)
quxian:addEffect(fk.TurnEnd, spec)

return quxian
