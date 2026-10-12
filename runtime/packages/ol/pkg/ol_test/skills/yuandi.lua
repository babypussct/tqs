local yuandi = fk.CreateSkill {
  name = "ol__yuandi",
  tags = { Skill.Compulsory },
  dynamic_desc = function (self, player, lang)
    if #player:getTableMark(self.name) == 0 then
      return "dummyskill"
    else
      local str = {}
      for _, name in ipairs(player:getTableMark(self.name)) do
        if table.find(player:getTableMark("ol__yuandi_record-turn"), function (dat)
          return dat[1] == name
        end) then
          table.insert(str, "<font color='grey'>【"..Fk:translate(name).."】</font>")
        else
          table.insert(str, "【"..Fk:translate(name).."】")
        end
      end
      return "ol__yuandi_inner:"..table.concat(str, "")
    end
  end,
}

Fk:loadTranslationTable{
  ["ol__yuandi"] = "元嫡",
  [":ol__yuandi"] = "锁定技，当每回合首次有【杀】【闪】【桃】为一组的牌名均进入过弃牌堆后，你摸一张牌。"..
  "若其中有牌不因使用进入弃牌堆，且剩余牌名数大于一，你移除一个牌名。",

  [":ol__yuandi_inner"] = "锁定技，当每回合首次有{1}为一组的牌名均进入过弃牌堆后，你摸一张牌。"..
  "若其中有牌不因使用进入弃牌堆，且剩余牌名数大于一，你移除一个牌名。",

  ["#ol__yuandi-remove"] = "元嫡：请移除一个牌名",

  ["$ol__yuandi1"] = "犹记少年初遇，君予我一往情深。",
  ["$ol__yuandi2"] = "年少缘起，此情无人可代。",
}

yuandi:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(yuandi.name) and player:usedSkillTimes(yuandi.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and
          move.extra_data and move.extra_data.ol__yuandi and move.extra_data.ol__yuandi[player] then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, yuandi.name)
    if player.dead then return end
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and
          move.extra_data and move.extra_data.ol__yuandi and move.extra_data.ol__yuandi[player] then
          if move.extra_data.ol__yuandi[player] == 2 and #player:getTableMark(yuandi.name) > 1 then
            local choice = room:askToChoice(player, {
              skill_name = yuandi.name,
              prompt = "#ol__yuandi-remove",
              choices = player:getTableMark(yuandi.name),
              cancelable = false,
            })
            room:removeTableMark(player, yuandi.name, choice)
          end
        end
      end
  end,

  can_refresh = function (self, event, target, player, data)
    if player:getMark(yuandi.name) ~= 0 then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player:getTableMark(yuandi.name), info.beforeCard.trueName) then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(player:getTableMark(yuandi.name), info.beforeCard.trueName) and
            not table.find(player:getTableMark("ol__yuandi_record-turn"), function (dat)
              return dat[1] == info.beforeCard.trueName
            end) then
            room:addTableMark(player, "ol__yuandi_record-turn", { info.beforeCard.trueName, move.moveReason ~= fk.ReasonUse and 2 or 1 })
            if #player:getTableMark(yuandi.name) == #player:getTableMark("ol__yuandi_record-turn") then
              move.extra_data = move.extra_data or {}
              move.extra_data.ol__yuandi = move.extra_data.ol__yuandi or {}
              local yes = false
              for _, dat in ipairs(player:getTableMark("ol__yuandi_record-turn")) do
                if dat[2] == 2 then
                  yes = true
                  break
                end
              end
              move.extra_data.ol__yuandi[player] = yes and 2 or 1
              room:setPlayerMark(player, "ol__yuandi_record-turn", 0)
              return
            end
          end
        end
      end
    end
  end,
})

yuandi:addAcquireEffect(function (self, player, is_start, src)
  player.room:setPlayerMark(player, yuandi.name, { "slash", "jink", "peach" })
end)

yuandi:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, yuandi.name, 0)
  player.room:setPlayerMark(player, "ol__yuandi_record-turn", 0)
end)

return yuandi
