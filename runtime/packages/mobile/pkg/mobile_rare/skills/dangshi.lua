local dangshi = fk.CreateSkill {
  name = "dangshi",
}

Fk:loadTranslationTable{
  ["dangshi"] = "荡势",
  [":dangshi"] = "当你使用伤害牌结算完毕后，你可以令其中一名目标其他角色选择一项：1.弃置X张牌（X为所有角色本轮选择此选项的次数，至少为1）；"..
  "2.你对其造成1点伤害。",

  ["#dangshi-choose"] = "荡势：你可以令一名目标角色选择执行一项",
  ["dangshi_use"] = "对%src使用一张【%arg】",
  ["dangshi_discard"] = "弃置%arg张牌",
  ["dangshi_damage"] = "受到1点伤害",
  ["#dangshi-use"] = "荡势：对%src使用一张【%arg】，或点“取消”受到1点伤害",

  ["$dangshi1"] = "尔等退路已绝，还不下马受戮！",
  ["$dangshi2"] = "此皆吾敢死之士，尔等可有胆一战？",
  ["$dangshi3"] = "今承天威荡寇，贼子何不束手！",
  ["$dangshi4"] = "敌军已溃，急令追击！",
}

---@param room AbstractRoom
---@param player Player
---@param friend string
---@return boolean
local function HeyuFriend(room, player, friend)
  return (room:isGameMode("1v2_mode") or room:isGameMode("2v2_mode")) and
    not not table.find(room.alive_players, function (p)
      return p.role == player.role and (p.general:endsWith(friend) or p.deputyGeneral:endsWith(friend))
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
      prompt = "#dangshi-choose",
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
    local n = math.max(player:getMark("dangshi-round"), 1)
    if HeyuFriend(room, player, "thoroughbred__lidian") then
      n = 3
    end
    local all_choices = {
      --"dangshi_use:"..player.id.."::"..data.card.trueName,
      "dangshi_discard:::"..n,
      "dangshi_damage",
    }
    local choices = table.simpleClone(all_choices)
    if #table.filter(to:getCardIds("he"), function (id)
      return not to:prohibitDiscard(id)
    end) < n then
      table.remove(choices, 1)
    end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = dangshi.name,
      all_choices = all_choices,
    })
    --local yes = false
    if choice:startsWith("dangshi_use") then
      local use = room:askToUseCard(to, {
        skill_name = dangshi.name,
        pattern = data.card.trueName,
        prompt = "#dangshi-use:"..player.id.."::"..data.card.trueName,
        extra_data = {
          exclusive_targets = { player.id },
          bypass_times = true,
        }
      })
      if use then
        --yes = room:addTableMarkIfNeed(player, "dangshi-phase", 1)
        use.extraUse = true
        use.tos = { player }
        room:useCard(use)
      else
        --yes = room:addTableMarkIfNeed(player, "dangshi-phase", 3)
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = dangshi.name,
        }
      end
    elseif choice:startsWith("dangshi_discard") then
      room:addPlayerMark(player, "dangshi-round", 1)
      --yes = room:addTableMarkIfNeed(player, "dangshi-phase", 2)
      room:askToDiscard(to, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = dangshi.name,
        cancelable = false,
      })
    else
      --yes = room:addTableMarkIfNeed(player, "dangshi-phase", 1)
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = dangshi.name,
      }
    end
    --if yes and not player.dead then
    --  player:drawCards(1, dangshi.name)
    --end
  end,
})

return dangshi
