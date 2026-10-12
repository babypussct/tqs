local zhenjun = fk.CreateSkill {
  name = "zhenjun",
}

Fk:loadTranslationTable{
  ["zhenjun"] = "镇军",
  [":zhenjun"] = "出牌阶段开始时，你可以交给一名其他角色一张牌，然后令其选择是否使用一张非黑色的【杀】，" ..
  "且此【杀】结算结束后你摸X张牌（X为此【杀】造成伤害值+1且至多为5）；若其不执行，则你可以对其或其攻击范围内的一名角色造成1点伤害。",

  ["#zhenjun-choose"] = "镇军：将一张牌交给一名其他角色，其选择使用【杀】或你造成伤害",
  ["#zhenjun-use"] = "镇军：请使用一张非黑色的【杀】",
  ["#zhenjun-damage"] = "镇军：你可以对一名角色造成1点伤害",

  ["$zhenjun1"] = "将怀其威，则镇其军。",
  ["$zhenjun2"] = "治军之道，得之于严。",
}

zhenjun:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(zhenjun.name) and player.phase == Player.Play and
      not player:isNude() and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local to, card = room:askToChooseCardsAndPlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      min_card_num = 1,
      max_card_num = 1,
      prompt = "#zhenjun-choose",
      skill_name = zhenjun.name,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to, cards = card })
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:moveCardTo(event:getCostData(self).cards, Player.Hand, to, fk.ReasonGive, zhenjun.name, nil, false, player)
    if to.dead then return end
    local use = room:askToUseCard(to, {
      pattern = "slash|.|^black",
      prompt = "#zhenjun-use",
      skill_name = zhenjun.name,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      }
    })
    if use then
      use.extraUse = true
      room:useCard(use)
      if not player.dead then
        local num = 1
        if use.damageDealt then
          for _, v in pairs(use.damageDealt) do
            num = num + v
          end
        end
        player:drawCards(math.min(num, 5), zhenjun.name)
      end
    else
      local targets = table.filter(room.alive_players, function(p)
        return p == to or to:inMyAttackRange(p)
      end)
      if #targets == 0 then return end
      local victim = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#zhenjun-damage",
        skill_name = zhenjun.name,
      })
      if #victim > 0 then
        room:damage{
          from = player,
          to = victim[1],
          damage = 1,
          skillName = zhenjun.name,
        }
      end
    end
  end,
})

return zhenjun
