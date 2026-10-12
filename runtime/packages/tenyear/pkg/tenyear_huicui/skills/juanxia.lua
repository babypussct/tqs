local juanxia = fk.CreateSkill {
  name = "ty__juanxia",
}

Fk:loadTranslationTable{
  ["ty__juanxia"] = "狷狭",
  [":ty__juanxia"] = "结束阶段，你可以选择一名其他角色，依次视为对其使用至多三张牌名各不相同的仅指定唯一目标的普通锦囊牌（无距离限制）。"..
  "若如此做，该角色的结束阶段，其可以视为对你使用等量张【杀】。",

  ["#ty__juanxia-choose"] = "狷狭：选择一名其他角色，视为对其使用至多三张仅指定唯一目标的普通锦囊",
  ["#ty__juanxia-invoke"] = "狷狭：你可以视为对 %dest 使用一张锦囊（第%arg张，至多3张）",
  ["@ty__juanxia"] = "狷狭",
  ["#ty__juanxia-slash"] = "狷狭：你可以视为对 %src 使用 %arg 张【杀】",

  ["$ty__juanxia1"] = "放之海内，知我者少、同我者无，可谓高处胜寒。",
  ["$ty__juanxia2"] = "满堂朱紫，能文者不武，为将者少谋，唯吾兼备。",
}

juanxia:addAuxActiveSkill("ty__juanxia_active", {
  card_num = 0,
  card_filter = Util.FalseFunc,
  interaction_helper = function(self, player, selected_cards, selected_targets, extra_data)
    return UI.CardNameBox { choices = self.ty__juanxia_names }
  end,
  fix_targets = function(self, player, selected_cards, _, extra_data)
    --UI only，传空表可以让photo不变暗
    if self.interaction.data == nil then return {} end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    local name = self.interaction.data
    if name == nil then return false end
    local card = Fk:cloneCard(name, Card.NoSuit, 0, juanxia.name)
    if #selected == 0 then
      local target = self.ty__juanxia_target
      if target then
        return to_select == target
      end
      return to_select ~= player and card.skill:targetFilter(player, to_select, {}, {}, card, nil) and
        not player:isProhibited(to_select, card)
    else
      if card.skill:getMinTargetNum(player) == 1 then return false end
      return card.skill:targetFilter(player, to_select, selected, {}, card, nil)
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    local name = self.interaction.data
    if name == nil then return false end
    local to_use = Fk:cloneCard(name, Card.NoSuit, 0, juanxia.name)
    return to_use.skill:feasible(player, selected, {}, to_use)
  end,
})

juanxia:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juanxia.name) and player.phase == Player.Finish and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#ty__juanxia-choose",
      skill_name = juanxia.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local mark = player:getMark("ty__juanxia_names")
    if mark == 0 then
      mark = table.filter(Fk:getAllCardNames("t"), function(name)
        local trick = Fk:cloneCard(name)
        --暂定必须手动选目标吧，懒得考虑固定以下家为目标之类的牌
        return not trick.multiple_targets and trick.skill:getMinTargetNum(player) > 0
      end)
      room:setPlayerMark(player, "ty__juanxia_names", table.simpleClone(mark))
    end
    local x = 0
    for i = 1, 3 do
      local names = table.filter(mark, function(name)
        local card = Fk:cloneCard(name, Card.NoSuit, 0, juanxia.name)
        return not player:prohibitUse(card) and not player:isProhibited(to, card) and
          card.skill:targetFilter(player, to, {}, {}, card, nil)
      end)
      if #names == 0 then break end
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "ty__juanxia_active",
        prompt = "#ty__juanxia-invoke::" .. to.id..":"..i,
        cancelable = true,
        extra_data = {
          ty__juanxia_names = names,
          ty__juanxia_target = to,
        }
      })
      if success and dat then
        table.removeOne(mark, dat.interaction)
        x = x + 1
        room:useCard{
          from = player,
          tos = dat.targets,
          card = Fk:cloneCard(dat.interaction, Card.NoSuit, 0, juanxia.name),
        }
      else
        break
      end
      if player.dead or to.dead then return end
    end
    if x == 0 then return end
    room:addPlayerMark(to, "@ty__juanxia", x)
    mark = to:getTableMark("ty__juanxia_record")
    mark[tostring(player.id)] = (mark[tostring(player.id)] or 0) + x
    room:setPlayerMark(to, "ty__juanxia_record", mark)
  end,
})

juanxia:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and not target.dead and target:getMark("@ty__juanxia") > 0 and
      target:getMark("ty__juanxia_record") ~= 0 and
      target:getMark("ty__juanxia_record")[tostring(player.id)] ~= nil
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getMark("ty__juanxia_record")[tostring(player.id)]
    for i = 1, n, 1 do
      local slash = Fk:cloneCard("slash")
      slash.skillName = juanxia.name
      if not target:canUseTo(slash, player, {bypass_distances = true, bypass_times = true}) or
      (i == 1 and not room:askToSkillInvoke(target, {
        skill_name = juanxia.name,
        prompt = "#ty__juanxia-slash:"..player.id.."::"..n,
      })) then break end
      room:useVirtualCard("slash", nil, target, player, juanxia.name, true)
      if player.dead or target.dead then break end
    end
  end,

  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and (player:getMark("@ty__juanxia") > 0 or player:getMark("ty__juanxia_record") ~= 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@ty__juanxia", 0)
    room:setPlayerMark(player, "ty__juanxia_record", 0)
  end,
})

return juanxia
