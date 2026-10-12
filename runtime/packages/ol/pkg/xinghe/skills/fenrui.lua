local fenrui = fk.CreateSkill{
  name = "fenrui",
}

Fk:loadTranslationTable{
  ["fenrui"] = "奋锐",
  [":fenrui"] = "结束阶段，你可以：弃置一张牌并复原一个装备栏，随机使用一张对应装备牌，"..
    "然后你可以对一名装备区里牌数小于你的角色造造成X点伤害（X为你与其装备区里牌数之差），"..
    "若如此做，你不能再以此法造成伤害。",

  ["#fenrui-invoke"] = "奋锐：你可以弃置一张牌恢复一个装备栏，随机使用一张对应的装备牌",
  ["@@fenrui"] = "已奋锐",
  ["#fenrui-choose"] = "奋锐：你可以对一名装备少于你的角色造成你与其装备数之差的伤害！（每局限一次）",

  ["$fenrui1"] = "待其疲敝，则可一击破之。",
  ["$fenrui2"] = "覆军斩将，便在旦夕之间。",
}

fenrui:addAuxActiveSkill("fenrui_active", {
  card_num = 1,
  target_num = 0,
  interaction = function(self, player)
    local choices = table.simpleClone(player.sealedSlots)
    table.removeOne(choices, Player.JudgeSlot)
    return UI.OptionBox { options = choices, direct_send = true }
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
})

fenrui:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fenrui.name) and player.phase == Player.Finish then
      if table.every(player.sealedSlots, function(slot)
        return slot == Player.JudgeSlot
      end) then
        return player:getMark("@@fenrui") == 0 and table.find(player.room.alive_players, function(p)
          return #p:getCardIds("e") < #player:getCardIds("e")
        end)
      else
        return not player:isNude()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = table.simpleClone(player.sealedSlots)
    table.removeOne(choices, Player.JudgeSlot)
    if #choices == 0 then
      local x = #player:getCardIds("e")
      local targets = table.filter(room.alive_players, function(p)
        return #p:getCardIds("e") < x
      end)
      targets = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = fenrui.name,
        prompt = "#fenrui-choose",
        cancelable = true,
      })
      if #targets > 0 then
        event:setCostData(self, { tos = targets })
        return true
      end
    else
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "fenrui_active",
        prompt = "#fenrui-invoke",
        cancelable = true,
      })
      if success and dat then
        event:setCostData(self, { cards = dat.cards, choice = dat.interaction })
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self)
    local to = dat.tos
    if dat.cards then
      room:throwCard(dat.cards, fenrui.name, player, player)
      if player.dead then return end
      local choice = dat.choice
      room:resumePlayerArea(player, choice)
      if player.dead then return end
      local sub_type = Util.convertSubtypeAndEquipSlot(choice)
      local equips = table.filter(table.connect(room.draw_pile, room.discard_pile), function (id)
        local c = Fk:getCardById(id)
        return c.sub_type == sub_type and player:canUseTo(c, player)
      end)
      if #equips > 0 then
        room:useCard({
          from = player,
          tos = {player},
          card = Fk:getCardById(room:tableRandomPick(equips)),
        })
        if player.dead then return end
      end
      if player:getMark("@@fenrui") == 0 then
        local x = #player:getCardIds("e")
        local targets = table.filter(room.alive_players, function(p)
          return #p:getCardIds("e") < x
        end)
        if #targets == 0 then return end
        to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = fenrui.name,
          prompt = "#fenrui-choose",
          cancelable = true,
        })
      end
    end
    if to and #to > 0 then
      room:setPlayerMark(player, "@@fenrui", 1)
      room:damage{
        from = player,
        to = to[1],
        damage = #player:getCardIds("e") - #to[1]:getCardIds("e"),
        skillName = fenrui.name,
      }
    end
  end
})

return fenrui
