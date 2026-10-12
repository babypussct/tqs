local zhuguo = fk.CreateSkill {
  name = "zhuguo",
}

Fk:loadTranslationTable{
  ["zhuguo"] = "助国",
  [":zhuguo"] = "出牌阶段限一次，你可以令一名角色将手牌调整至X张（X为其体力上限，至多为5）。然后若其：没有摸牌，其回复1点体力；"..
  "因此摸牌且手牌数全场最多，你可以选择另一名角色，令其选择是否对此角色使用一张无距离次数限制的【杀】。",

  ["#zhuguo"]= "助国：令一名角色将手牌调整至体力上限（至多为5）并执行效果",
  ["#zhuguo-choose"] = "助国：选择另一名角色，%dest 可以对其使用【杀】",
  ["#zhuguo-use"] = "助国：你可以对 %dest 使用一张无距离次数限制的【杀】",

  ["$zhuguo1"] = "宁与其生死一决，亦不可送质于彼。",
  ["$zhuguo2"] = "此非一时之权，实乃万世之利。",
  ["$zhuguo3"] = "以妾之微智，成国之远图。",
}

zhuguo:addEffect("active", {
  anim_type = "support",
  prompt = "#zhuguo",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zhuguo.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = target:getHandcardNum() - math.min(target.maxHp, 5)
    if n > 0 then
      room:askToDiscard(target, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = zhuguo.name,
        cancelable = false,
      })
    elseif n < 0 then
      target:drawCards(-n, zhuguo.name)
    end
    if target.dead then return end
    if n >= 0 then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = zhuguo.name,
      }
    elseif n < 0 and table.every(room.alive_players, function (p)
      return p:getHandcardNum() <= target:getHandcardNum()
    end) and #room:getOtherPlayers(target, false) > 0 then
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = room:getOtherPlayers(target, false),
        skill_name = zhuguo.name,
        prompt = "#zhuguo-choose::"..target.id,
        cancelable = true,
      })
      if #to > 0 then
        to = to[1]
        local use = room:askToUseCard(target, {
          skill_name = zhuguo.name,
          pattern = "slash",
          prompt = "#zhuguo-use::"..to.id,
          extra_data = {
            bypass_times = true,
            bypass_distances = true,
            exclusive_targets = {to.id},
          }
        })
        if use then
          use.extraUse = true
          room:useCard(use)
        end
      end
    end
  end,
})

return zhuguo
