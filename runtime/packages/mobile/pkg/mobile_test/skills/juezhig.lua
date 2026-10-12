local juezhi = fk.CreateSkill {
  name = "juezhig",
  max_branches_use_time = {
    ["juezhig_duel"] = {
      [Player.HistoryPhase] = 1
    },
    ["juezhig_recover"] = {
      [Player.HistoryPhase] = 1
    },
  },
}

Fk:loadTranslationTable{
  ["juezhig"] = "决止",
  [":juezhig"] = "出牌阶段每项各限一次：1.你可以摸一张牌，视为使用一张【决斗】，然后弃置手牌中的所有非伤害牌；" ..
  "2.你可以摸一张牌，回复1点体力，然后弃置手牌中的所有伤害牌。",

  ["#juezhi"] = "决止：你可以摸一张牌并执行选项",
  ["juezhig_duel"] = "使用决斗",
  ["juezhig_recover"] = "回复体力",

  ["$juezhig1"] = "刀剑无眼，文远小心提防。",
  ["$juezhig2"] = "闻君枪法通神，今日且来领教。",
  ["$juezhig3"] = "但较武艺，不论输赢。",
  ["$juezhig4"] = "此为切磋，点到为止。",
}

juezhi:addEffect("active", {
  mute = true,
  prompt = "#juezhi",
  interaction = function(self, player)
    local choices = {}
    if juezhi:withinBranchTimesLimit(player, "juezhig_duel", Player.HistoryPhase) then
      table.insert(choices, "juezhig_duel")
    end
    if juezhi:withinBranchTimesLimit(player, "juezhig_recover", Player.HistoryPhase) then
      table.insert(choices, "juezhig_recover")
    end
    if #choices == 0 then
      return
    end

    return UI.ComboBox { choices = choices, all_choices = { "juezhig_duel", "juezhig_recover" } }
  end,
  can_use = function(self, player)
    return
      juezhi:withinBranchTimesLimit(player, "juezhig_duel", Player.HistoryPhase) or
      juezhi:withinBranchTimesLimit(player, "juezhig_recover", Player.HistoryPhase)
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = juezhi.name
    local player = effect.from
    local branch = self.interaction.data

    local isDuel = branch == "juezhig_duel"
    room:notifySkillInvoked(player, skillName, isDuel and "offensive" or "defensive")
    player:broadcastSkillInvoke(skillName, isDuel and math.random(1, 2) or math.random(3, 4))
    player:addSkillBranchUseHistory(skillName, branch, 1)

    player:drawCards(1, skillName)
    if player.dead then return end

    if isDuel then
      room:askToUseVirtualCard(player, {
        name = "duel",
        skill_name = skillName,
        cancelable = false,
      })
      if player:isAlive() then
        local toDiscard = table.filter(player:getCardIds("h"), function(id)
          return Fk:getCardById(id).damage_type == nil and not player:prohibitDiscard(id)
        end)
        room:throwCard(toDiscard, skillName, player, player)
      end
    else
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skillName,
      }
      if player:isAlive() then
        local toDiscard = table.filter(player:getCardIds("h"), function(id)
          return Fk:getCardById(id).damage_type ~= nil and not player:prohibitDiscard(id)
        end)
        room:throwCard(toDiscard, skillName, player, player)
      end
    end
  end,
})

return juezhi
