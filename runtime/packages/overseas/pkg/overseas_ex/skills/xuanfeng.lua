local xuanfeng = fk.CreateSkill {
  name = "os_ex__xuanfeng",
}

Fk:loadTranslationTable{
  ["os_ex__xuanfeng"] = "旋风",
  [":os_ex__xuanfeng"] = "当你失去装备区里的牌后，或当你于弃牌阶段弃置过至少两张牌，你可以选择一项："..
  "1.弃置至多两名其他角色的共计两张牌；2.将一名其他角色装备区里的一张牌移动到另一名其他角色的对应区域。背水：废除一个装备栏。",

  ["#os_ex__xuanfeng-choose"] = "旋风：弃置其他角色共计两张牌，或移动其他角色的一张装备",
  ["os_ex__xuanfeng_movecard"] = "移动场上的一张装备牌",
  ["os_ex__xuanfeng_discard"] = "弃置至多两名其他角色的共计两张牌",
  ["os_ex__xuanfeng_beishui"] = "背水：废除一个装备栏",
  ["#os_ex__xuanfeng-discard"] = "旋风：你可以选择一名角色，弃置其一张牌",
  ["#os_ex__xuanfeng-move"] = "旋风：将一名其他角色的一张装备移动到另一名其他角色",
  ["#os_ex__xuanfeng-abort"] = "旋风：请废除一个装备栏",

  ["$os_ex__xuanfeng1"] = "风起而浪勇，舟行而军振。",
  ["$os_ex__xuanfeng2"] = "风急，帆骤，吾军心奋，敌将胆颤也！",
}

xuanfeng:addAuxActiveSkill("#os_ex__xuanfeng_active", {
  card_filter = Util.FalseFunc,
  interaction = function(self, player)
    return UI.ComboBox { choices = { "os_ex__xuanfeng_discard", "os_ex__xuanfeng_movecard", "os_ex__xuanfeng_beishui" }}
  end,
  target_filter = function(self, player, to_select, selected)
    if to_select == player then return false end
    if self.interaction.data == "os_ex__xuanfeng_movecard" then
      if #selected == 0 then
        return #to_select:getCardIds("e") > 0
      elseif #selected == 1 then
        return selected[1]:canMoveCardsInBoardTo(to_select, "e") or to_select:canMoveCardsInBoardTo(selected[1], "e")
      end
    else
      return #selected == 0 and not to_select:isNude()
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if self.interaction.data == "os_ex__xuanfeng_movecard" then
      return #selected == 2
    end
    return #selected == 1
  end,
})

xuanfeng:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xuanfeng.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
          if player.phase == Player.Discard and move.moveReason == fk.ReasonDiscard and
            move.skillName == "phase_discard" and player:usedSkillTimes(xuanfeng.name, Player.HistoryPhase) == 0 then
            local x = 0
            local logic = player.room.logic
            logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
              for _, move2 in ipairs(e.data) do
                if move2.from == player and move2.moveReason == fk.ReasonDiscard then
                  x = x + #move2.moveInfo
                  if x > 1 then
                    return true
                  end
                end
              end
            end, Player.HistoryPhase)
            return x > 1
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#os_ex__xuanfeng_active",
      prompt = "#os_ex__xuanfeng-choose",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, { tos = dat.targets, choice = dat.interaction })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self)
    if dat.choice ~= "os_ex__xuanfeng_movecard" then
      local to = dat.tos[1]
      local card = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = xuanfeng.name,
      })
      room:throwCard(card, xuanfeng.name, to, player)
      if player.dead then return end
      local tos = table.filter(room:getOtherPlayers(player, false), function (p)
        return not p:isNude()
      end)
      if #tos > 0 then
        tos = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = tos,
          skill_name = xuanfeng.name,
          prompt = "#os_ex__xuanfeng-discard",
          cancelable = true,
        })
        if #tos > 0 then
          to = tos[1]
          card = room:askToChooseCard(player, {
            target = to,
            flag = "he",
            skill_name = xuanfeng.name,
          })
          room:throwCard(card, xuanfeng.name, to, player)
          if player.dead then return end
        end
      end
    end
    local yes = false
    if dat.choice ~= "os_ex__xuanfeng_discard" and
      #room:canMoveCardInBoard("e", room:getOtherPlayers(player, false)) > 0 then
      yes = true
      if #dat.tos ~= 2 then
        dat.tos = room:askToChooseToMoveCardInBoard(player, {
          skill_name = xuanfeng.name,
          froms = room:getOtherPlayers(player, false),
          tos = room:getOtherPlayers(player, false),
          flag = "e",
          prompt = "#os_ex__xuanfeng-move",
          cancelable = false,
        })
      end
      room:askToMoveCardInBoard(player, {
        target_one = dat.tos[1],
        target_two = dat.tos[2],
        skill_name = xuanfeng.name,
        flag = "e",
      })
    end
    if dat.choice == "os_ex__xuanfeng_beishui" and yes and not player.dead and
      #player:getAvailableEquipSlots() > 0 then
      local choice = room:askToChoice(player, {
        choices = player:getAvailableEquipSlots(),
        skill_name = xuanfeng.name,
        prompt = "#os_ex__xuanfeng-abort",
      })
      room:abortPlayerArea(player, choice)
    end
  end,
})

return xuanfeng
