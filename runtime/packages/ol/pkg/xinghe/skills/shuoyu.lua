local shuoyu = fk.CreateSkill {
  name = "shuoyu",
}

Fk:loadTranslationTable{
  ["shuoyu"] = "妁语",
  [":shuoyu"] = "每回合限一次，你攻击范围内的角色成为【杀】的目标时，你可以与所有体力值不大于你的角色议事，"..
  "若意见为红色，弃置所有意见牌，将此【杀】转移给一名未参与议事的角色。",

  ["#shuoyu-invoke"] = "妁语：%dest 成为【杀】的目标，你可以与所有体力值不大于你的角色议事，若为红色则转移此【杀】",
  ["#shuoyu-choose"] = "妁语：将此【杀】转移给一名未参与议事的角色",

  ["$shuoyu1"] = "国太将贵女招赘刘备，真是一喜！",
  ["$shuoyu2"] = "佳偶配得，天上当生瑞彩。"
}

local U = require "packages.utility.utility"

shuoyu:addEffect(fk.TargetConfirming, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shuoyu.name) and not data.cancelled and
      data.card.trueName == "slash" and player:inMyAttackRange(target) and
      table.find(player.room.alive_players, function (p)
        return p.hp <= player.hp and not p:isKongcheng()
      end) and
      player:usedSkillTimes(shuoyu.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
      return player.room:askToSkillInvoke(player, {
        skill_name = shuoyu.name,
        prompt = "#shuoyu-invoke::"..target.id,
      })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p.hp <= player.hp and not p:isKongcheng()
    end)
    room:doIndicate(player, targets)
    local discussion = U.Discussion(player, targets, shuoyu.name)
    if discussion.color == "red" then
      local moves = {}
      for _, p in ipairs(targets) do
        if not p.dead then
          local ids = table.filter(discussion.results[p].toCards, function (id)
            return table.contains(p:getCardIds("h"), id)
          end)
          if #ids > 0 then
            table.insert(moves, {
              ids = ids,
              from = p,
              toArea = Card.DiscardPile,
              moveReason = fk.ReasonDiscard,
              skillName = shuoyu.name,
              proposer = player,
              moveVisible = true,
            })
          end
        end
      end
      if #moves > 0 then
        room:moveCards(table.unpack(moves))
      end
      if not player.dead then
        local tos = table.filter(room:getOtherPlayers(target, false), function (p)
          return not table.contains(targets, p) and p ~= data.from and not data.from:isProhibited(p, data.card)
        end)
        if #tos > 0 then
          local to = room:askToChoosePlayers(player, {
            min_num = 1,
            max_num = 1,
            targets = tos,
            skill_name = shuoyu.name,
            prompt = "#shuoyu-choose",
            cancelable = false,
          })[1]
          if data:cancelCurrentTarget() then
            data:addTarget(to)
          end
        end
      end
    end
  end,
})

return shuoyu
