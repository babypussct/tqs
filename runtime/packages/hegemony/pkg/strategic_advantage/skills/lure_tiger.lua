local lureTigerSkill = fk.CreateSkill{
  name = "lure_tiger_skill",
}
local H = require "packages.hegemony.util"
lureTigerSkill:addEffect("cardskill", {
  prompt = "#lure_tiger_skill",
  min_target_num = 1,
  max_target_num = 2,
  mod_target_filter = function(self, player, to_select, selected)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local target = effect.to
    room:setPlayerMark(target, "@@lure_tiger-turn", 1)
    room:setPlayerMark(target, MarkEnum.PlayerRemoved .. "-turn", 1)
    room.logic:trigger(H.PlayerRemoved, target, {who = target}) -- FIXME
  end,
})

lureTigerSkill:addEffect('prohibit', {
  global = true,
  prohibit_use = function(self, player, card)
    return player:hasMark("@@lure_tiger", MarkEnum.TempMarkSuffix)
  end,
  is_prohibited = function(self, from, to, card)
    return to and card and to:hasMark("@@lure_tiger", MarkEnum.TempMarkSuffix)
  end,
})
lureTigerSkill:addEffect(fk.PreHpRecover, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasMark("@@lure_tiger", MarkEnum.TempMarkSuffix)
  end,
  on_refresh = function(self, event, target, player, data)
    data:preventRecover()
  end,
})
lureTigerSkill:addEffect(fk.PreHpLost, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasMark("@@lure_tiger", MarkEnum.TempMarkSuffix)
  end,
  on_refresh = function(self, event, target, player, data)
    data:preventHpLost()
    player.room:sendLog{
      type = "#lure_tiger-prevent",
      to = {player.id},
      toast = true,
    }
  end,
})
lureTigerSkill:addEffect(fk.DamageInflicted, {
  global = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasMark("@@lure_tiger", MarkEnum.TempMarkSuffix)
  end,
  on_refresh = function(self, event, target, player, data)
    data:preventDamage()
    player.room:sendLog{
      type = "#lure_tiger-prevent",
      to = {player.id},
      toast = true,
    }
  end,
})
lureTigerSkill:addEffect("targetmod", {
  global = true,
  target_tip_func = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if not card or selectable then return end
    if to_select:hasMark("@@lure_tiger", MarkEnum.TempMarkSuffix) then return {{content = "lure_tiger-prohibit", type = "warning"}} end
  end,
})

lureTigerSkill:addTest(function(room, me)
  local card = room:printCard("lure_tiger")
  local comp2, comp3, comp4 = room.players[2], room.players[3], room.players[4]
  FkTest.runInRoom(function()
    room:loseHp(comp2, 1)
    room:useCard{
      from = me,
      tos = {comp2, comp3},
      card = card,
    }
  end)
  lu.assertEquals(me:distanceTo(comp2), -1)
  lu.assertEquals(me:distanceTo(comp3), -1)
  lu.assertEvalToFalse(me:compareDistance(comp3, 1, "<="))
  lu.assertEquals(me:distanceTo(comp4), 1)
  lu.assertIs(me:getNextAlive(), comp4)
  lu.assertIsFalse(comp2:canUse(card))
  lu.assertIsFalse(me:canUseTo(card, comp2))

  FkTest.runInRoom(function()
    room:damage{to = comp2, damage = 1}
  end)
  lu.assertEquals(comp2.hp, 3)
  FkTest.runInRoom(function()
    room:loseHp(comp2, 1)
  end)
  lu.assertEquals(comp2.hp, 3)
  FkTest.runInRoom(function()
    room:recover{who = comp2, num = 1}
  end)
  lu.assertEquals(comp2.hp, 3)

  -- 回合后
  FkTest.runInRoom(function()
    GameEvent.Turn:create(TurnData:new(me, "game_rule", { Player.Finish })):exec()
  end)
  lu.assertIs(me:getNextAlive(), comp2)
  lu.assertEquals(me:distanceTo(comp3), 2)
end)

Fk:loadTranslationTable{
  ["lure_tiger"] = "调虎离山", -- 标记：MarkEnum.PlayerRemoved 不计入距离和座次的计算；"@@lure_tiger" 不能使用牌，且不是牌的合法目标，且体力值不会改变。均可带后缀
  [":lure_tiger"] = "锦囊牌<br/>"..
  "<b>时机</b>：出牌阶段<br/>"..
  "<b>目标</b>：一至两名其他角色<br/>"..
  "<b>效果</b>：目标角色于此回合内不计入距离和座次的计算，且不能使用牌，且不是牌的合法目标，且体力值不会改变。",
  ["#lure_tiger_skill"] = "选择一至两名角色，这些角色本回合不计入距离座次计算、不能使用牌、不是牌的合法目标、体力值不会改变",

  ["lure_tiger_desc"] = "调离：被调离的角色不计入距离和座次的计算，且不能使用牌，且不是牌的合法目标，且体力值不会改变。",
  ["#lure_tiger-prevent"] = "由于【调虎离山】的效果，防止 %to 的体力值改变",
  ["lure_tiger-prohibit"] = "受调虎离山保护",

  ["@@lure_tiger-turn"] = "调离",
  ["@@lure_tiger"] = "调离",
  ["lure_tiger_skill"] = "调离",
}

return lureTigerSkill
