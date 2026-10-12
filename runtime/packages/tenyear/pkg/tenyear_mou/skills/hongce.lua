local hongce = fk.CreateSkill {
  name = "hongce",
  dynamic_desc = function (self, player, lang)
    if player:getMark("hongce-noclear") > 0 then
      return "hongce_inner" .. player:getMark("hongce-noclear")
    end
  end,
}

Fk:loadTranslationTable{
  ["hongce"] = "宏策",
  [":hongce"] = "首轮开始时，你令一名角色选择一项执行：<br>"..
  "1.将一半手牌替换为伤害牌，并视为使用一张【杀】；<br>2.重铸一张手牌，视为使用一张单目标普通锦囊牌；<br>"..
  "3.摸三张牌，这些牌不计入手牌上限。<br>然后你修改此技能为“出牌阶段限一次，你可以令一名角色执行首轮开始时被选择的选项”。",

  [":hongce_inner1"] = "出牌阶段限一次，你可以令一名角色将一半手牌替换为伤害牌，并视为使用一张【杀】。",
  [":hongce_inner2"] = "出牌阶段限一次，你可以令一名角色重铸一张手牌，并视为使用一张单目标普通锦囊牌。",
  [":hongce_inner3"] = "出牌阶段限一次，你可以令一名角色摸三张牌，这些牌不计入手牌上限。",

  ["#hongce1"] = "宏策：令一名角色将一半手牌替换为伤害牌，并视为使用一张【杀】",
  ["#hongce-ask"] = "宏策：请将%arg张手牌替换为伤害牌",
  ["#hongce-slash"] = "宏策：请视为使用一张【杀】",
  ["#hongce2"] = "宏策：令一名角色重铸一张手牌，并视为使用一张单目标普通锦囊牌",
  ["#hongce-recast"] = "宏策：请重铸一张手牌",
  ["#hongce-use"] = "宏策：请视为使用一张单目标普通锦囊牌",
  ["#hongce3"] = "宏策：令一名角色摸三张牌，这些牌不计入手牌上限",
  ["@@hongce-inhand"] = "宏策",

  ["#hongce-choose"] = "宏策：令一名角色选择一项执行",
  ["hongce1"] = "将一半手牌替换为伤害牌，视为使用一张【杀】",
  ["hongce2"] = "重铸一张手牌，视为使用一张单目标普通锦囊牌",
  ["hongce3"] = "摸三张牌，这些牌不计入手牌上限",

  ["$hongce1"] = "金刀刘，做王侯，千里蜀川化冕旒！",
  ["$hongce2"] = "蜀狐如牛毛，待我取之，为公子裘。",
  ["$hongce3"] = "阴选精兵，径袭成都，如此大事可定。",
  ["$hongce4"] = "遣使惑敌，擒酋取兵，璋必自溃。",
  ["$hongce5"] = "退白帝，还荆州，亦可徐而图之。",
}

hongce:addEffect("active", {
  mute = true,
  max_phase_use_time = 1,
  prompt = function (self, player, selected_cards, selected_targets)
    return "#hongce" .. player:getMark("hongce-noclear")
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(hongce.name, Player.HistoryPhase) == 0 and
      player:getMark("hongce-noclear") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      if player:getMark("hongce-noclear") ~= 2 then
        return not to_select:isKongcheng()
      else
        return true
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    player:broadcastSkillInvoke(hongce.name, 2 + player:getMark(hongce.name))
    room:notifySkillInvoked(player, hongce.name, "drawcard")
    if player:getMark("hongce-noclear") == 1 then
      if not target:isKongcheng() then
        local n = (target:getHandcardNum() + 1) // 2
        local cards = room:askToCards(target, {
          min_num = n,
          max_num = n,
          include_equip = false,
          skill_name = hongce.name,
          cancelable = false,
          prompt = "#hongce-ask:::"..n,
        })
        room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, hongce.name, nil, true, target)
        if target.dead then return end
        cards = table.filter(room.draw_pile, function (id)
          return Fk:getCardById(id).is_damage_card
        end)
        if #cards > 0 then
          cards = room:tableRandomPick(cards, n)
          room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonPrey, hongce.name, nil, true, target)
          if target.dead then return end
          if #cards < n then
            target:drawCards(n - #cards, hongce.name)
          end
        else
          target:drawCards(n, hongce.name)
        end
        if target.dead then return end
      end
      room:askToUseVirtualCard(target, {
        name = "slash",
        skill_name = hongce.name,
        prompt = "#hongce-slash",
        cancelable = false,
        extra_data = {
          bypass_times = true,
          extraUse = true,
        },
      })
    elseif player:getMark("hongce-noclear") == 2 then
      if not target:isKongcheng() then
        local cards = room:askToCards(target, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = hongce.name,
          cancelable = true,
          prompt = "#hongce-recast",
        })
        room:recastCard(cards, target, hongce.name)
        if target.dead then return end
      end
      local all_names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card:isCommonTrick() and not (card.is_derived or card.multiple_targets or card.is_passive) then
          table.insertIfNeed(all_names, card.name)
        end
      end
      local names = target:getViewAsCardNames(hongce.name, all_names)
      if #names > 0 then
        room:askToUseVirtualCard(target, {
          name = names,
          skill_name = hongce.name,
          prompt = "#hongce-use",
          cancelable = false,
          extra_data = {
            bypass_times = true,
            extraUse = true,
          },
        })
      end
    elseif player:getMark("hongce-noclear") == 3 then
      target:drawCards(3, hongce.name, nil, "@@hongce-inhand")
    end
  end,
})

hongce:addEffect(fk.RoundStart, {
  anim_type = "support",
  audio_index = { 1, 2 },
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(hongce.name) and player.room:getBanner("RoundCount") == 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      skill_name = hongce.name,
      prompt = "#hongce-choose",
      cancelable = false,
    })[1]

    local choices = {}
    if not to:isKongcheng() then
      table.insertTable(choices, { "hongce1", "hongce2" })
    end
    table.insert(choices, "hongce3")

    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = hongce.name,
      all_choices = { "hongce1", "hongce2", "hongce3" },
    })
    local n = tonumber(choice[7])
    room:setPlayerMark(player, "hongce-noclear", n)
    local skill = Fk.skills[hongce.name]
    skill:onUse(room, {
      from = player,
      tos = {to},
    })
  end,
})

hongce:addEffect("maxcards", {
  exclude_from = function (self, player, card)
    return card:getMark("@@hongce-inhand") > 0
  end,
})

hongce:addAI(Fk.Ltk.AI.newChoosePlayersStrategy{
  choose_players = function(self, ai)
    local ret = ai:askToChoosePlayers({
      targets = ai:getEnabledTargets(),
      min_num = 1,
      max_num = 1,
      skill_name = self.skill_name,
      benefit_func = function (logic, p)
        logic.benefit = ai:needHelp(p)
      end,
    })
    if ret then
      return ret
    else
      return { ai.player }
    end
  end,
})

return hongce
