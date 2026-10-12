local jilie = fk.CreateSkill {
  name = "jilie"
}

Fk:loadTranslationTable{
  ["jilie"] = "急烈",
  [":jilie"] = "出牌阶段限一次，你可以弃置当前体力值张牌，弃置牌中每弃置一种花色进行两次判定，若结果为【杀】，你可以视为使用之，"..
  "此【杀】伤害基数值为你本回合使用【杀】的次数。",

  ["#jilie"] = "急烈：弃%arg张牌，每弃一种花色进行两次判定，若为【杀】则可以视为使用之",
  ["#jilie-use"] = "急烈：你可以视为使用此【杀】，伤害基数值为%arg！",

  ["$jilie1"] = "吾言不听，吾剑听否！",
  ["$jilie2"] = "再戏同僚，休怪此剑不认故交！",
}

jilie:addEffect("active", {
  anim_type = "offensive",
  prompt = function (self, player)
    return "#jilie:::"..player.hp
  end,
  card_num = function (self, player)
    return player.hp
  end,
  target_num = 0,
  can_use = function (self, player)
    return player:usedSkillTimes(jilie.name, Player.HistoryPhase) == 0 and player.hp > 0
  end,
  card_filter = function(self, player, to_select, selected)
    return not player:prohibitDiscard(to_select) and #selected < player.hp
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local suits = {}
    for _, id in ipairs(effect.cards) do
      table.insertIfNeed(suits, Fk:getCardById(id).suit)
    end
    room:throwCard(effect.cards, jilie.name, player, player)
    for _ = 1, 2 * #suits do
      if player.dead then return end
      local judge = {
        who = player,
        reason = jilie.name,
        pattern = "slash",
      }
      room:judge(judge)
      if player.dead then return end
      if judge:matchPattern() then
        local n = 1
        room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data
          if use.from == player and use.card.trueName == "slash" then
            n = n + 1
          end
        end, Player.HistoryTurn)
        local use = room:askToUseVirtualCard(player, {
          name = judge.card.name,
          skill_name = jilie.name,
          prompt = "#jilie-use:::"..n,
          cancelable = true,
          extra_data = {
            --bypass_distances = true,
            bypass_times = true,
            extraUse = true,
          },
          skip = true,
          card_filter = {
            n = 1,
            cards = { judge.card.id },
          },
        })
        if use then
          local card = Fk:cloneCard(judge.card.name, judge.card.suit, judge.card.number)
          card.skillName = jilie.name
          room:useCard{
            from = player,
            tos = use.tos,
            card = card,
            extraUse = true,
            additionalDamage = n - 1,
          }
        end
      end
    end
  end,
})

return jilie
