local jiebian = fk.CreateSkill {
  name = "jiebian",
}

Fk:loadTranslationTable{
  ["jiebian"] = "劫辩",
  [":jiebian"] = "一名角色的出牌阶段结束时，若本阶段没有角色受到过伤害，你可以与当前回合角色或体力值最低的角色拼点" ..
  "（你可以用“业”进行此次拼点），若你赢，你选择一项：1.对没赢的角色造成1点伤害；2.令没赢的角色回复1点体力并摸一张牌，然后获得其两张牌。",

  ["#jiebian-invoke"] = "劫辩：你可与其中一名角色拼点",
  ["jiebian_damage"] = "对%dest造成1点伤害",
  ["jiebian_recover"] = "令%dest回复体力摸牌，然后你获得其牌",

  ["$jiebian1"] = "轮回诸趣众生类，速生我刹受安乐。",
  ["$jiebian2"] = "常运慈心拔有情，度尽无边苦众生。",
}

jiebian:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    if not (
      target.phase == Player.Play and
      player:hasSkill(jiebian.name) and
      #player.room.logic:getActualDamageEvents(1, Util.TrueFunc, Player.HistoryPhase) == 0
    ) then
      return false
    end

    local room = player.room
    local targets = {}
    for _, p in ipairs(room.alive_players) do
      if #targets == 0 or p.hp == targets[1].hp then
        table.insert(targets, p)
      elseif p.hp < targets[1].hp then
        targets = { p }
      end
    end

    if room.current and room.current:isAlive() then
      table.insertIfNeed(targets, room.current)
    end

    targets = table.filter(targets, function(p) return player:canPindian(p) end)

    if #targets > 0 then
      event:setCostData(self, { targets = targets })
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local targets = event:getCostData(self).targets
    if #targets == 0 then
      return false
    end

    local tos = player.room:askToChoosePlayers(
      player,
      {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = jiebian.name,
        prompt = "#jiebian-invoke",
      }
    )

    if #tos > 0 then
      event:setCostData(self, { to = tos[1] })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = jiebian.name
    local room = player.room
    local to = event:getCostData(self).to
    local pindian = {
      from = player,
      tos = { to },
      reason = skillName,
      results = {},
      expandCards = { [player] = {
        num = 1,
        min_num = 1,
        include_equip = false,
        pattern = ".",
        reason = skillName,
        expand_pile = "futu_ye",
      } },
    }

    room:pindian(pindian)
    local winner = pindian.results[to].winner
    if not (winner and winner:isAlive() and winner == player) then
      return false
    end

    local loser = to
    if not loser:isAlive() then
      return false
    end

    local choice = room:askToChoice(
      winner,
      {
        choices = { "jiebian_damage::" .. loser.id, "jiebian_recover::" .. loser.id },
        skill_name = skillName,
      }
    )

    if choice:startsWith("jiebian_damage") then
      room:damage{
        from = winner,
        to = loser,
        damage = 1,
        skillName = skillName,
      }
    else
      room:recover{
        who = loser,
        num = 1,
        recoverBy = winner,
        skillName = skillName,
      }

      if not loser:isAlive() then
        return false
      end

      loser:drawCards(1, skillName)

      if not loser:isAlive() or loser:isNude() then
        return false
      end

      local ids = room:askToChooseCards(
        player,
        {
          min = 2,
          max = 2,
          flag = "he",
          target = loser,
          skill_name = skillName,
        }
      )

      room:obtainCard(winner, ids, false, fk.ReasonPrey, winner, skillName)
    end
  end,
})

return jiebian
