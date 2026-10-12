local lifengh = fk.CreateSkill {
  name = "os__lifengh",
}

Fk:loadTranslationTable{
  ["os__lifengh"] = "砺锋",
  [":os__lifengh"] = "出牌阶段限两次，你可以弃置两张点数不同的牌，对一名距离X以内的角色造成1点伤害（X为你弃置的牌点数的差），其受到此伤害时，"..
  "可以重铸一张手牌，若此牌点数与你弃置的两张牌中至少一张点数相同，防止此伤害。若你弃置的牌点数的差大于此阶段你上一次以此法弃置的牌的差，则你摸一张牌且此技能此阶段可发动次数+1。",

  ["#os__lifengh"] = "砺锋：弃两张牌，对一名距离这两张牌点数之差以内的角色造成1点伤害",
  ["#os__lifengh_first"] = "砺锋：弃两张牌，对一名距离%arg以内的角色造成1点伤害",
  ["#os__lifengh_last"] = "砺锋：弃两张牌，对一名距离这两张牌点数之差以内的角色造成1点伤害。<br>若弃的牌点数差大于%arg，你摸一张牌且发动次数+1",
  ["#os__lifengh_bigger"] = "砺锋：弃两张牌，对一名距离%arg以内的角色造成1点伤害，<br>摸一张牌且发动次数+1",
  ["#os__lifengh_not_bigger"] = "砺锋：弃两张牌，对一名距离%arg以内的角色造成1点伤害，<br>（无法摸牌且发动次数+1）",
  ["#os__lifengh-recast"] = "砺锋：%src 对你造成伤害，是否重铸一张手牌？若点数为%arg或%arg2则防止伤害",
  ["@os__lifengh_diff-phase"] = "砺锋",

  ["$os__lifengh1"] = "十载磨一剑，今日欲以贼三军拭锋！",
  ["$os__lifengh2"] = "业火炼锋，江水淬刃，方铸此师！",
}

lifengh:addEffect("active", {
  anim_type = "offensive",
  prompt = function (self, player, selected_cards, selected_targets)
    local last_diff = player:getMark("@os__lifengh_diff-phase")
    if last_diff == 0 then
      return #selected_cards < 2 and "#os__lifengh" or "#os__lifengh_first:::" .. math.abs(Fk:getCardById(selected_cards[1]).number - Fk:getCardById(selected_cards[2]).number)
    elseif #selected_cards < 2 then
      return "#os__lifengh_last:::" .. last_diff
    else
      local diff = math.abs(Fk:getCardById(selected_cards[1]).number - Fk:getCardById(selected_cards[2]).number)
      return diff > last_diff
        and "#os__lifengh_bigger:::" .. diff or "#os__lifengh_not_bigger:::" .. diff
    end
  end,
  card_num = 2,
  target_num = 1,
  times = function (self, player)
    return 2 + player:getMark("os__lifengh_times-phase") - player:usedSkillTimes(lifengh.name, Player.HistoryPhase)
  end,
  can_use = function (self, player)
    return 2 + player:getMark("os__lifengh_times-phase") > player:usedSkillTimes(lifengh.name, Player.HistoryPhase)
  end,
  card_filter = function (self, player, to_select, selected)
    if #selected < 2 and not player:prohibitDiscard(to_select) then
      if #selected == 0 then
        return true
      else
        return Fk:getCardById(to_select).number ~= Fk:getCardById(selected[1]).number
      end
    end
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected_cards == 2 then
      return player:distanceTo(to_select) <=
        math.abs(Fk:getCardById(selected_cards[1]).number - Fk:getCardById(selected_cards[2]).number)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local nums = table.map(effect.cards, function (id)
      return Fk:getCardById(id).number
    end)
    room:throwCard(effect.cards, lifengh.name, player, player)
    local last_diff = player:getMark("@os__lifengh_diff-phase")
    local diff = math.abs(nums[1] - nums[2])
    room:setPlayerMark(player, "@os__lifengh_diff-phase", diff)
    if target.dead then return end
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = lifengh.name,
      extra_data = {
        os__lifengh = {player.id, nums},
      }
    }
    if player.dead then return end
    if diff > last_diff and last_diff ~= 0 then
      player:drawCards(1, lifengh.name)
      room:addPlayerMark(player, "os__lifengh_times-phase")
    end
  end,
})

lifengh:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.skillName == lifengh.name
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local src = room:getPlayerById(data.extra_data.os__lifengh[1])
    local nums = data.extra_data.os__lifengh[2]
    table.sort(nums)
    local card = {}
    if not player:isKongcheng() then
      card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = lifengh.name,
        cancelable = true,
        prompt = "#os__lifengh-recast:"..src.id.."::"..nums[1]..":"..nums[2],
      })
      if #card > 0 then
        room:recastCard(card, player, lifengh.name)
      end
    end
    if #card > 0 then
      local n = Fk:getCardById(card[1]).number
      if n == nums[1] or n == nums[2] then
        data:preventDamage()
      end
    end
  end,
})

return lifengh
