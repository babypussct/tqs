local knownBothSkill = fk.CreateSkill{
  name = "known_both_skill",
}

local H = require "packages.hegemony.util"

knownBothSkill:addEffect("cardskill", {
  prompt = "#known_both_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected)
    return player ~= to_select and (not to_select:isKongcheng() or to_select.general == "anjiang" or to_select.deputyGeneral == "anjiang")
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    if target.dead or player.dead then return end
    local all_choices = {"known_both_main", "known_both_deputy", "known_both_hand"}
    local choices = table.clone(all_choices)
    if not target.deputyGeneral or target.deputyGeneral ~= "anjiang" then
      table.remove(choices, 2)
    end
    if target:isKongcheng() then
      table.remove(choices)
    end
    if target.general ~= "anjiang" then
      table.remove(choices, 1)
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {choices = choices, skill_name = "known_both", prompt = "#known_both-choice::"..target.id, cancelable = false, all_choices = all_choices})
    if choice == "known_both_hand" then
      room:viewCards(player, { cards = target:getCardIds("h"), skill_name = "known_both", prompt = "#known_both-hand::"..target.id })
      for _, p in ipairs(room:getOtherPlayers(player, false)) do
        p:doNotify("GameLog", {
          type = "#know_hand",
          from = player.id,
          to = {target.id},
          toast = true,
        })
      end
    else
      local isMain = choice == "known_both_main"
      H.viewGeneral(player, target, knownBothSkill.name, isMain, not isMain)
      local log = {
        type = "#WatchGeneral",
        from = player.id,
        to = {target.id},
        arg = isMain and "mainGeneral" or "deputyGeneral",
        arg2 = isMain and target:getMark("__heg_general") or target:getMark("__heg_deputy"),
      }
      player:doNotify("GameLog", log)
    end
  end,
})

knownBothSkill:addAI(Fk.Ltk.AI.newCardSkillStrategy {
  keep_value = 3.24,
  use_value = 5,
  use_priority = 9.1,
})


knownBothSkill:addTest(function (room, me)
  local card = Fk:cloneCard("known_both")
  local comp2 = room.players[2]
  FkTest.setNextReplies(me, {"known_both_main", "1", "known_both_deputy", "1", "known_both_hand"})
  FkTest.runInRoom(function()
    room:setPlayerProperty(comp2, "deputyGeneral", "zhouyu")
    comp2:hideGeneral(false)
    comp2:hideGeneral(true)
    room:obtainCard(comp2, 1)
    for _ = 1, 3 do
      room:useCard {
        from = me,
        tos = { comp2 },
        card = card,
      }
    end
  end)
end)

Fk:loadTranslationTable{
  ["known_both"] = "知己知彼",
  ["known_both_skill"] = "知己知彼",
  [":known_both"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br/><b>效果</b>：观看目标角色一张暗置的武将牌或其手牌。",
  ["#known_both-choice"] = "知己知彼：选择对 %dest 执行的一项",
  ["known_both_main"] = "观看主将",
  ["known_both_deputy"] = "观看副将",
  ["known_both_hand"] = "观看手牌",
  ["#KnownBothGeneral"] = "观看 %1 武将",
  ["#known_both-general"] = "知己知彼：观看%dest的%arg",
  ["#known_both-hand"] = "知己知彼：观看%dest的手牌",
  ["#known_both_skill"] = "选择一名其他角色，观看其一张暗置的武将牌或其手牌",
  ["#know_hand"] = "%from 观看了 %to 的手牌",
  ["#know_general"] = "%from 观看了 %to 的 %arg",
  ["#WatchGeneral"] = "%from 观看了 %to 的 %arg %arg2",
}

return knownBothSkill
