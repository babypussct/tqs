
local lianpian = fk.CreateSkill {
  name = "ld__lianpian",
}

Fk:loadTranslationTable {
  ["ld__lianpian"] = "联翩",
  [":ld__lianpian"] = "准备阶段，你可以将手牌摸至体力上限；若如此做，直到你下回合开始或死亡，" ..
  "与你势力相同的其他角色摸牌阶段改为将手牌数摸至与你相同（至多摸五张）。",

  ["#ld__lianpian-invoke"] = "联翩：将手牌摸至体力上限，直到下回合开始同势力角色摸牌阶段改为摸牌至与你相同",
  ["@@ld__lianpian"] = "联翩",

  ["$ld__lianpian1"] = "需持续投入，方有回报。",
  ["$ld__lianpian2"] = "心无旁骛，断而敢行。",
}

local H = require "packages.hegemony.util"

lianpian:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lianpian.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = lianpian.name,
      prompt = "#ld__lianpian-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ld__lianpian", 1)
    local num = player.maxHp - player:getHandcardNum()
    if num > 0 then
      player:drawCards(num, lianpian.name)
    end
  end,
})

lianpian:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(lianpian.name) and target.phase == Player.Draw and
      H.compareKingdomWith(target, player) and player:getMark("@@ld__lianpian") > 0 and
      not data.phase_end
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, { tos = { target } })
    return true
  end,
  on_use = function(self, event, target, player, data)
    data.phase_end = true
    local num = player:getHandcardNum() - target:getHandcardNum()
    if num > 0 then
      target:drawCards(math.min(num, 5), lianpian.name)
    end
  end,
})

lianpian:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@ld__lianpian", 0)
  end,
})

return lianpian
