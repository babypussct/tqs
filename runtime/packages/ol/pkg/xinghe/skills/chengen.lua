local chengen = fk.CreateSkill{
  name = "chengen",
}

Fk:loadTranslationTable{
  ["chengen"] = "承恩",
  [":chengen"] = "每个回合结束时，若当前回合角色的手牌数不大于你，你可以与一名角色进行拼点。"..
  "若你赢，你可以使用拼点牌（无距离限制）；若你没赢，拼点目标可以对你使用一张【杀】。",

  ["#chengen-choose"] = "承恩：你可以拼点，若赢，你可以使用拼点牌；若没赢，其可以对你使用【杀】",
  ["#chengen-use"] = "承恩：你可以使用拼点牌（无距离限制）",
  ["#chengen-slash"] = "承恩：你可以对 %src 使用【杀】",

  ["$chengen1"] = "承恩长乐不觉久，惟愿君王万载长。",
  ["$chengen2"] = "妾非皎月，但为萤火，与君共明晦。",
}

chengen:addEffect(fk.TurnEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      not target.dead and player:hasSkill(chengen.name) and
      player:getHandcardNum() >= math.max(1, target:getHandcardNum()) and
      table.find(player.room.alive_players, function(p)
        return player:canPindian(p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return player:canPindian(p)
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = chengen.name,
      prompt = "#chengen-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local skillName = chengen.name
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local pindian = player:pindian({to}, skillName)
    if player.dead or pindian.results[to] == nil then return end
    if pindian.results[to].winner == player then
      local ids = {}
      for _, card in ipairs({ pindian.fromCard, pindian.results[to].toCard }) do
        table.insertIfNeed(ids, card:getEffectiveId())
      end
      while true do
        local discardPile = room.discard_pile
        local to_use = table.filter(ids, function(id)
          if table.contains(discardPile, id) then
            local card = Fk:getCardById(id)
            return #card:getAvailableTargets(player, { bypass_distances = true, bypass_times = (card.trueName == "analeptic") }) > 0
          end
        end)
        if #to_use == 0 then break end
        local use = room:askToUseRealCard(player, {
          pattern = ids,
          skill_name = skillName,
          prompt = "#chengen-use",
          extra_data = {
            bypass_distances = true,
            bypass_times = true,
            extraUse = true,
            expand_pile = ids,
          },
          skip = true,
        })
        if use then
          table.removeOne(ids, use.card:getEffectiveId())
          if use.card.trueName == "analeptic" then
            use.extraUse = false
          end
          room:useCard(use)
          if player.dead then break end
        else
          break
        end
      end
    elseif not to.dead then
      local use = room:askToUseCard(to, {
        skill_name = skillName,
        pattern = "slash",
        prompt = "#chengen-slash:" .. player.id,
        extra_data = {
          exclusive_targets = { player.id },
          bypass_times = true,
        }
      })
      if use then
        use.extraUse = true
        room:useCard(use)
      end
    end
  end,
})

return chengen
