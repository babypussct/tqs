local shiyuan = fk.CreateSkill {
  name = "shiyuan",
  max_branches_use_time = function(self, player)
    if player:hasSkill("yuwei") and Fk:currentRoom().current and Fk:currentRoom().current.kingdom == "qun" then
      return {
        ["1"] = {
          [Player.HistoryTurn] = 2
        },
        ["2"] = {
          [Player.HistoryTurn] = 2
        },
        ["3"] = {
          [Player.HistoryTurn] = 2
        },
      }
    else
      return {
        ["1"] = {
          [Player.HistoryTurn] = 1
        },
        ["2"] = {
          [Player.HistoryTurn] = 1
        },
        ["3"] = {
          [Player.HistoryTurn] = 1
        },
      }
    end
  end,
}

Fk:loadTranslationTable{
  ["shiyuan"] = "诗怨",
  [":shiyuan"] = "每回合每项限一次，当你成为其他角色使用牌的目标后：1.若其体力值比你多，你摸三张牌；2.若其体力值与你相同，你摸两张牌；"..
  "3.若其体力值比你少，你摸一张牌。",

  ["$shiyuan1"] = "感怀诗于前，绝怨赋于后。",
  ["$shiyuan2"] = "汉宫楚歌起，四面无援矣。",
}

shiyuan:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(shiyuan.name) and
      data.from and data.from ~= player then
      if data.from.hp > player.hp then
        return shiyuan:withinBranchTimesLimit(player, "1", Player.HistoryTurn)
      elseif data.from.hp == player.hp then
        return shiyuan:withinBranchTimesLimit(player, "2", Player.HistoryTurn)
      elseif data.from.hp < player.hp then
        return shiyuan:withinBranchTimesLimit(player, "3", Player.HistoryTurn)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from.hp > player.hp then
      player:addSkillBranchUseHistory(shiyuan.name, "1", 1)
      player:drawCards(3, shiyuan.name)
    elseif data.from.hp == player.hp then
      player:addSkillBranchUseHistory(shiyuan.name, "2", 1)
      player:drawCards(2, shiyuan.name)
    elseif data.from.hp < player.hp then
      player:addSkillBranchUseHistory(shiyuan.name, "3", 1)
      player:drawCards(1, shiyuan.name)
    end
  end,
})

shiyuan:addAI(Fk.Ltk.AI.newInvokeStrategy{
  think = function(self, ai)
    local data = ai.room.logic:getCurrentEvent().data._data
    return ai:getBenefitOfEvents(function(logic)
      local n = 0
      if data.from.hp > ai.player.hp then
        n = 3
      elseif data.from.hp == ai.player.hp then
        n = 2
      elseif data.from.hp < ai.player.hp then
        n = 1
      end
      logic:drawCards(ai.player, n)
    end) >= 0
  end,
})

return shiyuan
