local dangshi = fk.CreateSkill {
  name = "os__dangshi",
}

Fk:loadTranslationTable{
  ["os__dangshi"] = "荡势",
  [":os__dangshi"] = "当你使用伤害牌结算完毕后，你可以令其中一名目标其他角色选择一项：" ..
  "1.对你使用一张非转化且非虚拟的牌名相同的伤害牌；" ..
  "2.弃置X张牌（X为所有角色本轮选择此选项的次数，至少为1）；"..
  "3.你对其造成1点伤害。" ..
  "然后若其选择了本阶段未被选择过的选项，你摸一张牌且本阶段使用【杀】的次数上限+1。",

  ["#os__dangshi-choose"] = "荡势：你可以令一名目标角色选择执行一项",
  ["os__dangshi_use"] = "对%src使用一张【%arg】",
  ["os__dangshi_discard"] = "弃置%arg张牌",
  ["os__dangshi_damage"] = "受到1点伤害",
  ["#os__dangshi-use"] = "荡势：对%src使用一张【%arg】，或点“取消”受到1点伤害",

  ["$os__dangshi1"] = "尔等残兵，何必不自量力。",
  ["$os__dangshi2"] = "敌胆已寒，何敢再战。",
  ["$os__dangshi3"] = "如此分兵合击，贼寇何处可逃？",
  ["$os__dangshi4"] = "趁势正盛，当追敌残军，尽歼其众。",
}

local function HeyuFriend(room, player, friend)
  return (room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode")) and
    table.find(room.alive_players, function (p)
      return p.role == player.role and (p.general == friend or p.deputyGeneral == friend)
    end)
end

dangshi:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dangshi.name) and
      data.card.is_damage_card and
      table.find(data.tos, function (p)
        return p ~= player and not p.dead
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.simpleClone(data.tos)
    table.removeOne(targets, player)
    local to = room:askToChoosePlayers(player, {
      skill_name = dangshi.name,
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#os__dangshi-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, { tos = to })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = math.max(player:getMark("os__dangshi-round"), 1)
    if HeyuFriend(room, player, "zhangliao__heyu_lidian") then
      n = 3
    end
    local all_choices = {
      "os__dangshi_use:"..player.id.."::"..data.card.trueName,
      "os__dangshi_discard:::"..n,
      "os__dangshi_damage",
    }
    local choices = table.simpleClone(all_choices)
    if #table.filter(to:getCardIds("he"), function (id)
      return not to:prohibitDiscard(id)
    end) < n then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = dangshi.name,
      all_choices = all_choices,
    })
    local yes = false
    if choice:startsWith("os__dangshi_use") then
      local use = room:askToUseRealCard(to, {
        skill_name = dangshi.name,
        pattern = data.card.trueName,
        skip = true,
        prompt = "#os__dangshi-use:"..player.id.."::"..data.card.trueName,
        extra_data = {
          exclusive_targets = { player.id },
          bypass_times = true,
        }
      })
      if use then
        yes = room:addTableMarkIfNeed(player, "os__dangshi-phase", 1)
        use.extraUse = true
        use.tos = { player }
        room:useCard(use)
      else
        yes = room:addTableMarkIfNeed(player, "os__dangshi-phase", 3)
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = dangshi.name,
        }
      end
    elseif choice:startsWith("os__dangshi_discard") then
      room:addPlayerMark(player, "os__dangshi-round", 1)
      yes = room:addTableMarkIfNeed(player, "os__dangshi-phase", 2)
      room:askToDiscard(to, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = dangshi.name,
        cancelable = false,
      })
    else
      yes = room:addTableMarkIfNeed(player, "os__dangshi-phase", 3)
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = dangshi.name,
      }
    end
    if yes and not player.dead then
      player:drawCards(1, dangshi.name)
      room:addPlayerMark(player, MarkEnum.SlashResidue .. "-phase")
    end
  end,
})

return dangshi
