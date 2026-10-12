local qiuxin = fk.CreateSkill{
  name = "qiuxin",
}

Fk:loadTranslationTable{
  ["qiuxin"] = "求心",
  [":qiuxin"] = "出牌阶段限一次，你可以令一名其他角色声明一项：1.当你对其使用一张【杀】后，你可以视为对其使用一张普通锦囊牌；"..
  "2.当你对其使用一张普通锦囊牌后，你可以视为对其使用一张无距离限制的【杀】。",

  --使用【杀】无距离限制、锦囊牌有距离限制，这很规则集

  ["#qiuxin"] = "求心：令一名其他角色声明一项",
  ["#qiuxin-choice"] = "求心：声明一项“求心”，%src 对你使用声明项后，可以视为对你使用另一项",
  ["@@qiuxin_slash"] = "求心 杀",
  ["@@qiuxin_trick"] = "求心 锦囊",
  ["#qiuxin-slash"] = "求心：是否视为对 %dest 使用【杀】？",
  ["#qiuxin-trick"] = "求心：是否视为对 %dest 使用锦囊？",

  ["$qiuxin1"] = "此生所求者，顺心意尔。",
  ["$qiuxin2"] = "羡孔丘知天命之岁，叹吾生之不达。",
}

qiuxin:addAuxActiveSkill("qiuxin_viewas", {
  card_num = 0,
  card_filter = Util.FalseFunc,
  interaction_helper = function(self, player)
    local all_names = Fk:getAllCardNames("t")
    local to = Fk:currentRoom():getPlayerById(self.qiuxin_to)
    local names = table.filter(all_names, function(card_name)
      local card = Fk:cloneCard(card_name)
      card.skillName = "qiuxin"
      return not (player:prohibitUse(card) or player:isProhibited(to, card)) and
        card.skill:modTargetFilter(player, to, {}, card)
    end)
    return UI.CardNameBox {choices = names, all_choices = all_names}
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "qiuxin"
    local to = Fk:currentRoom():getPlayerById(self.qiuxin_to)
    if #selected == 0 then
      return to_select == to and
        not player:isProhibited(to_select, card) and
        card.skill:modTargetFilter(player, to_select, {}, card)
    elseif card.skill:getMinTargetNum(player) > 1 then
      return card.skill:targetFilter(player, to_select, selected, {}, card)
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if not self.interaction.data then return false end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = "qiuxin"
    local to = Fk:currentRoom():getPlayerById(self.qiuxin_to)
    return #selected >= card.skill:getMinTargetNum(player) and selected[1] == to
  end,
})

qiuxin:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    room:removeTableMark(p, "@@qiuxin_slash", player.id)
    room:removeTableMark(p, "@@qiuxin_trick", player.id)
  end
end)

qiuxin:addEffect("active", {
  anim_type = "control",
  prompt = "#qiuxin",
  card_num = 0,
  target_num = 1,
  times = function (self, player)
    return 1 - player:usedEffectTimes(qiuxin.name, Player.HistoryPhase)
  end,
  can_use = function(self, player)
    return player:usedEffectTimes(qiuxin.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choice = room:askToChoice(target, {
      choices = {"slash", "trick"},
      skill_name = qiuxin.name,
      prompt = "#qiuxin-choice:"..player.id,
    })
    room:addTableMarkIfNeed(target, "@@qiuxin_"..choice, player.id)
  end,
})
qiuxin:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  mute = true,
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(qiuxin.name) then
      local qiuxin_type = ""
      if data.card.trueName == "slash" then
        qiuxin_type = "slash"
      elseif data.card:isCommonTrick() then
        qiuxin_type = "trick"
      else
        return false
      end
      return table.find(data.tos, function (p)
        return table.contains(p:getTableMark("@@qiuxin_"..qiuxin_type), player.id) and not p.dead
      end)
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if data.card.trueName == "slash" then
      for _, p in ipairs(room:getAlivePlayers()) do
        if player.dead then break end
        if not p.dead and table.contains(data.tos, p) and
          table.contains(p:getTableMark("@@qiuxin_slash"), player.id) then
          local success, dat = room:askToUseActiveSkill(player, {
            skill_name = "qiuxin_viewas",
            prompt = "#qiuxin-trick::"..p.id,
            cancelable = true,
            extra_data = {
              qiuxin_to = p.id,
            }
          })
          if success and dat then
            room:removeTableMark(p, "@@qiuxin_slash", player.id)
            local card = Fk:cloneCard(dat.interaction)
            card.skillName = qiuxin.name
            room:useCard{
              from = player,
              tos = dat.targets,
              card = card,
            }
          end
        end
      end
    elseif data.card:isCommonTrick() then
      for _, p in ipairs(room:getAlivePlayers()) do
        if player.dead then break end
        if not p.dead and table.contains(data.tos, p) and
          table.contains(p:getTableMark("@@qiuxin_trick"), player.id) then
          local slash = Fk:cloneCard("slash")
          slash.skillName = qiuxin.name
          if player:prohibitUse(slash) then break end
          if not player:isProhibited(p, slash) and room:askToSkillInvoke(player, {
            skill_name = qiuxin.name,
            prompt = "#qiuxin-slash::"..p.id,
          }) then
            room:removeTableMark(p, "@@qiuxin_trick", player.id)
            room:useCard {
              from = player,
              tos = { p },
              card = slash,
              extraUse = true,
            }
          end
        end
      end
    end
  end,
})

return qiuxin
