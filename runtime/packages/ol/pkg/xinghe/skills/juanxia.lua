local juanxia = fk.CreateSkill{
  name = "juanxia",
}

Fk:loadTranslationTable{
  ["juanxia"] = "狷狭",
  [":juanxia"] = "结束阶段，你可以选择一名其他角色，依次视为对其使用至多两张仅指定唯一目标的普通锦囊牌。"..
  "若如此做，该角色的下回合结束阶段开始时，其可以依次视为对你使用等量的【杀】。",

  ["#juanxia-choose"] = "狷狭：你可以选择一名角色，依次视为对其使用至多两张仅指定唯一目标的普通锦囊牌",
  ["#juanxia-invoke"] = "狷狭：你可以视为对 %dest 再使用一张锦囊",
  ["#juanxia-slash"] = "狷狭：是否视为对 %src 使用%arg张【杀】？",
  ["@juanxia"] = "狷狭",

  ["$juanxia1"] = "汝有何功？竟能居我之上！",
  ["$juanxia2"] = "恃才傲立，恩怨必偿。",
}

juanxia:addAuxActiveSkill("juanxia_active", {
  card_num = 0,
  card_filter = Util.FalseFunc,
  interaction_helper = function(self, player, selected_cards, selected_targets, extra_data)
    return UI.CardNameBox { choices = self.juanxia_names }
  end,
  fix_targets = function(self, player, selected_cards, _, extra_data)
    --UI only，传空表可以让photo不变暗
    if self.interaction.data == nil then return {} end
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    local name = self.interaction.data
    if name == nil then return false end
    local card = Fk:cloneCard(name, Card.NoSuit, 0, juanxia.name)
    if #selected == 0 then
      local target = self.juanxia_target
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

juanxia:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juanxia.name) and player.phase == Player.Finish and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("juanxia_names")
    if mark == 0 then
      mark = table.filter(Fk:getAllCardNames("t"), function(name)
        local trick = Fk:cloneCard(name)
        --暂定必须手动选目标吧，懒得考虑固定以下家为目标之类的牌
        return not trick.multiple_targets and trick.skill:getMinTargetNum(player) > 0
      end)
      room:setPlayerMark(player, "juanxia_names", mark)
    end
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "juanxia_active",
      prompt = "#juanxia-choose",
      cancelable = true,
      extra_data = {
        juanxia_names = mark,
      }
    })
    if success then
      event:setCostData(self, {extra_data = dat})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self).extra_data
    local name = dat.interaction
    local to = dat.targets[1]
    room:useCard{
      from = player,
      tos = dat.targets,
      card = Fk:cloneCard(name, Card.NoSuit, 0, juanxia.name),
    }
    if player.dead or to.dead then return false end
    local x = 1
    local mark = table.filter(player:getTableMark("juanxia_names"), function(_name)
      if name == _name then return false end
      local card = Fk:cloneCard(_name, Card.NoSuit, 0, juanxia.name)
      return not player:prohibitUse(card) and not player:isProhibited(to, card) and
        card.skill:targetFilter(player, to, {}, {}, card, nil)
    end)
    if #mark > 0 then
      local success = false
      success, dat = room:askToUseActiveSkill(player, {
        skill_name = "juanxia_active",
        prompt = "#juanxia-invoke::"..to.id,
        cancelable = true,
        extra_data = {
          juanxia_names = mark,
          juanxia_target = to,
        }
      })
      if success and dat then
        room:useCard{
          from = player,
          tos = dat.targets,
          card = Fk:cloneCard(dat.interaction, Card.NoSuit, 0, juanxia.name),
        }
        if player.dead or to.dead then return false end
        x = x + 1
      end
    end
    room:setPlayerMark(to, "@juanxia", x)
    room:setPlayerMark(to, "juanxia_record", player)
  end,
})

juanxia:addEffect(fk.EventPhaseStart, {
  priority = 2,
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and
      target:getMark("juanxia_record") == player and
      not player.dead and target:getMark("@juanxia") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = target:getMark("@juanxia")
    for i = 1, n, 1 do
      local slash = Fk:cloneCard("slash", Card.NoSuit, 0, juanxia.name)
      if not target:canUseTo(slash, player, { bypass_distances = true, bypass_times = true }) or
      (i == 1 and not room:askToSkillInvoke(target, {
        skill_name = juanxia.name,
        prompt = "#juanxia-slash:"..player.id.."::"..n,
      })) then break end
      room:useVirtualCard("slash", nil, target, player, juanxia.name, true)
      if player.dead or target.dead then break end
    end
  end,

  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@juanxia", 0)
    room:setPlayerMark(player, "juanxia_record", 0)
  end,
})

return juanxia
