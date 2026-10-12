local saojian = fk.CreateSkill {
  name = "mobile__saojian",
}

Fk:loadTranslationTable {
  ["mobile__saojian"] = "扫奸",
  [":mobile__saojian"] = "出牌阶段限一次，你可以观看一名其他角色的手牌并选择其中一张，然后其重复弃置一张手牌，" ..
      "直至弃置了五张牌或你选择的牌。",

  ["#mobile__saojian"] = "扫奸：观看一名其他角色的手牌，令其弃置手牌直到弃到你所选的牌",
  ["#mobile__saojian-discard"] = "扫奸：请弃置一张手牌，直到你弃置到“扫奸”选择的牌（剩余%arg次）",

  ["$mobile__saojian1"] = "今某作司隶，此曹子安得容乎！",
  ["$mobile__saojian2"] = "满朝虫豸，何以言政，必诛之！",
  ["$mobile__saojian3"] = "哎，奸路既生，再难尽除！",
}

saojian:addEffect("active", {
  anim_type = "control",
  audio_index = { 1, 2 },
  prompt = "#mobile__saojian",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(saojian.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    if target:isKongcheng() then return end
    local card = room:askToChooseCard(player, {
      target = target,
      flag = { card_data = { { target.general, target:getCardIds("h") } } },
      skill_name = saojian.name,
    })
    for i = 1, 5 do
      local ids = room:askToDiscard(target, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = saojian.name,
        cancelable = false,
        prompt = "#mobile__saojian-discard:::" .. 6 - i,
      })
      if #ids == 0 or ids[1] == card or target.dead then
        break
      end
      if i == 5 then
        player:broadcastSkillInvoke(saojian.name, 3)
      end
    end
  end,
})

saojian:addAI(Fk.Ltk.AI.newActiveStrategy {
  think = function(self, ai)
    local ret, benefit = nil, 0
    for _, p in ipairs(ai:getEnabledTargets()) do
      local tmp = 0
      local cards = table.filter(p:getCardIds("h"), function(id)
        return not p:prohibitDiscard(id)
      end)
      if #cards > 0 then
        tmp = ai:getBenefitOfEvents(function(logic)
          logic:throwCard(table.random(cards), self.skill_name, p, p)
        end)
      end
      if tmp >= benefit then
        ret, benefit = p, tmp
      end
    end
    if ret then
      return { { }, { ret } }, benefit
    end
  end,
})

return saojian
