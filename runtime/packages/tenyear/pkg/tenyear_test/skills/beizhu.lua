
local beizhu = fk.CreateSkill{
  name = "ty__beizhu",
  dynamic_desc = function (self, player, lang)
    if player:getMark("ty__beizhu1") ~= 0 then
      local ret = "ty__beizhu_inner"
      for i = 1, 3 do
        local str = Fk:translate(player:getMark("ty__beizhu"..i), lang)
        str = string.gsub(str, "%%arg", i)
        ret = ret..":"..str
      end
      return ret
    end
  end,
}

Fk:loadTranslationTable{
  ["ty__beizhu"] = "备诛",
  [":ty__beizhu"] = "每回合结束时，若你本回合满足过以下一项，你可以执行与之相邻的一项，然后令一名角色执行剩余的一项："..
  "1.至少受到序号数点伤害；2.至少弃置序号数张牌；3.至少摸序号数张牌。你的回合开始时，你可以交换两个相邻的选项。",

  [":ty__beizhu_inner"] = "每回合结束时，若你本回合满足过以下一项，你可以执行与之相邻的一项，然后令一名角色执行剩余的一项："..
  "1.至少{1}；2.至少{2}；3.至少{3}。你的回合开始时，你可以交换两个相邻的选项。",

  ["#ty__beizhu-invoke"] = "备诛：你可以选择执行一项，然后令一名角色执行剩余的一项",
  ["ty__beizhu_damage"] = "受到%arg点伤害",
  ["ty__beizhu_discard"] = "弃置%arg张牌",
  ["ty__beizhu_draw"] = "摸%arg张牌",
  ["#ty__beizhu-choose"] = "备诛：选择一名角色，令其执行效果",
  ["#ty__beizhu-swap"] = "备诛：你可以交换两个相邻选项",
  ["ty__beizhu_swap"] = "%arg和%arg2",

  ["$ty__beizhu1"] = "",
  ["$ty__beizhu2"] = "",
}

local function beizhuChoices(player)
  local room = player.room
  local choices = {}
  for i = 1, 3 do
    local n = 0
    if player:getMark("ty__beizhu"..i) == "ty__beizhu_damage" then
      room.logic:getActualDamageEvents(1, function (e)
        if e.data.to == player then
          n = n + e.data.damage
          if n >= i then
            return true
          end
        end
      end, Player.HistoryTurn)
    elseif player:getMark("ty__beizhu"..i) == "ty__beizhu_discard" then
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                n = n + 1
                if n >= i then
                  return true
                end
              end
            end
          end
        end
      end, Player.HistoryTurn)
    elseif player:getMark("ty__beizhu"..i) == "ty__beizhu_draw" then
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.to == player and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
            n = n + #move.moveInfo
            if n >= i then
              return true
            end
          end
        end
      end, Player.HistoryTurn)
    end
    if n >= i then
      if i == 2 then
        table.insertIfNeed(choices, player:getMark("ty__beizhu1")..":::"..3)
        table.insertIfNeed(choices, player:getMark("ty__beizhu1")..":::"..3)
      else
        table.insertIfNeed(choices, player:getMark("ty__beizhu2")..":::"..2)
      end
    end
  end
  return choices
end

local function beizhuEffect(player, choice)
  local room = player.room
  local n = tonumber(choice:split(":")[4])  ---@cast n integer
  if choice:startsWith("ty__beizhu_damage") then
    room:damage{
      to = player,
      damage = n,
      skillName = beizhu.name,
    }
  elseif choice:startsWith("ty__beizhu_discard") then
    room:askToDiscard(player, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = beizhu.name,
      cancelable = false,
    })
  elseif choice:startsWith("ty__beizhu_draw") then
    player:drawCards(n, beizhu.name)
  end
end

beizhu:addAuxActiveSkill("#ty__beizhu_active", {
  card_num = 0,
  target_num = 1,
  interaction = function (self, player)
    return UI.ComboBox { choices = self.choices, all_choices = self.all_choices }
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected)
    return #selected == 0
  end,
})

beizhu:addEffect(fk.TurnEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(beizhu.name) and #beizhuChoices(player) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {}
    for i = 1, 3 do
      table.insert(all_choices, player:getMark("ty__beizhu"..i)..":::"..i)
    end
    local choice = room:askToChoice(player, {
      choices = beizhuChoices(player),
      all_choices = all_choices,
      skill_name = beizhu.name,
      prompt = "#ty__beizhu-invoke",
      cancelable = true,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = choice })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local choices = beizhuChoices(player)
    table.removeOne(choices, choice)
    beizhuEffect(player, choice)
    if player.dead then return end
    local all_choices = {}
    for i = 1, 3 do
      table.insert(all_choices, player:getMark("ty__beizhu"..i)..":::"..i)
    end
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "#ty__beizhu_active",
      prompt = "#ty__beizhu-choose",
      cancelable = false,
      extra_data = {
        choices = choices,
        all_choices = all_choices,
      }
    })
    if not (success and dat) then
      dat = {}
      dat.targets = { player }
      dat.interaction = choices[1]
    end
    beizhuEffect(dat.targets[1], dat.interaction)
  end,
})

local mapper = {
  ty__beizhu_damage = "damaged",
  ty__beizhu_discard = "discard_card",
  ty__beizhu_draw = "draw_card",
}

beizhu:addEffect(fk.TurnStart, {
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {}
    table.insert(choices, "ty__beizhu_swap:::"..mapper[player:getMark("ty__beizhu1")]..":"..mapper[player:getMark("ty__beizhu2")])
    table.insert(choices, "ty__beizhu_swap:::"..mapper[player:getMark("ty__beizhu2")]..":"..mapper[player:getMark("ty__beizhu3")])
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = beizhu.name,
      prompt = "#ty__beizhu-swap",
      cancelable = true,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, { choice = table.indexOf(choices, choice) })
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local str1, str2 = player:getMark("ty__beizhu1"), player:getMark("ty__beizhu2")
    if choice == 2 then
      str1, str2 = player:getMark("ty__beizhu2"), player:getMark("ty__beizhu3")
      room:setPlayerMark(player, "ty__beizhu2", str2)
      room:setPlayerMark(player, "ty__beizhu3", str1)
    else
      room:setPlayerMark(player, "ty__beizhu1", str2)
      room:setPlayerMark(player, "ty__beizhu2", str1)
    end
  end,
})

beizhu:addAcquireEffect(function (self, player, is_start, src)
  local room = player.room
  room:setPlayerMark(player, "ty__beizhu1", "ty__beizhu_damage")
  room:setPlayerMark(player, "ty__beizhu2", "ty__beizhu_discard")
  room:setPlayerMark(player, "ty__beizhu3", "ty__beizhu_draw")
end)

return beizhu
