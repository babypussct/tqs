local meiyan = fk.CreateSkill {
  name = "meiyan",
}

Fk:loadTranslationTable{
  ["meiyan"] = "媒言",
  [":meiyan"] = "出牌阶段限一次，你可以与所有体力值大于等于你的角色议事，若议事结果为红色，你获得所有红色意见牌；"..
  "若议事结果为黑色，你与意见为红色的角色各摸一张牌。",

  ["#meiyan"] = "媒言：与所有体力值不小于你的角色议事，若为红色你获得红色意见牌，若为黑色你摸牌",

  ["$meiyan1"] = "啊呀，玄德生得龙眉凤目，真乃帝王根本。",
  ["$meiyan2"] = "玄德驾到，老朽真感蓬荜生辉。",
}

local U = require "packages.utility.utility"

meiyan:addEffect("active", {
  anim_type = "control",
  prompt = "#meiyan",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(meiyan.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.filter(room.alive_players, function(p)
      return not p:isKongcheng() and p.hp >= player.hp
    end)
    room:doIndicate(player, targets)
    local discussion = U.Discussion(player, targets, meiyan.name)
    if discussion.color == "red" then
      if not player.dead then
        local cards = {}
        for _, p in ipairs(targets) do
          if not p.dead and p ~= player and discussion.results[p].opinion == "red" then
            local ids = table.filter(discussion.results[p].toCards, function (id)
              return table.contains(p:getCardIds("h"), id)
            end)
            if #ids > 0 then
              table.insertTableIfNeed(cards, ids)
            end
          end
        end
        if #cards > 0 then
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, meiyan.name, nil, true, player)
        end
      end
    elseif discussion.color == "black" then
      player:drawCards(1, meiyan.name)
      for _, p in ipairs(room:getAlivePlayers()) do
        if not p.dead and discussion.results[p] and discussion.results[p].opinion == "red" then
          p:drawCards(1, meiyan.name)
        end
      end
    end
  end,
})

return meiyan
