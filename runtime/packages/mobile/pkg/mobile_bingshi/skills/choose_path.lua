local choosePath = fk.CreateSkill {
  name = "#choose_path",
}

Fk:loadTranslationTable{
  ["#choose_path"] = "选择路径",

  ["#PathDesc"] = "使用（发动）者与目标（选定）者之间的，单向遍历其间所有角色的一条路径。“路径上的角色”不包含首尾角色。",
  ["path_beginner"] = "起始角色",
  ["path_player"] = "路径角色",
  ["path_end"] = "终点角色",
}

choosePath:addEffect("active", {
  card_num = 0,
  target_num = 0,
  interaction = function(self, player)
    local target = Fk:currentRoom():getPlayerById(self.pathTarget)
    local choices = {}
    local yourNext = player:getNextAlive()
    if yourNext ~= player and yourNext ~= target then
      table.insert(choices, "anticlockwise")
    end

    local targetNext = target:getNextAlive()
    if targetNext ~= target and targetNext ~= player then
      table.insert(choices, "clockwise")
    end

    if #choices == 0 then
      return
    end
    return UI.ComboBox { choices = choices, all_choices = { "clockwise", "anticlockwise" } }
  end,
  target_filter = Util.FalseFunc,
  card_filter = Util.FalseFunc,
  target_tip = function(self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if to_select:isRemoved() then
      return
    end

    if to_select == player then
      return "path_beginner"
    end

    local target = Fk:currentRoom():getPlayerById(self.pathTarget)
    if to_select == target then
      return "path_end"
    end

    local room = Fk:currentRoom()
    if self.interaction.data == "clockwise" then
      local curPlayer = to_select
      for _ = 1, #room.alive_players do
        curPlayer = curPlayer:getNextAlive(true)
        if curPlayer == player then
          return "path_player"
        elseif curPlayer == target then
          break
        end
      end
    elseif self.interaction.data == "anticlockwise" then
      local curPlayer = to_select
      for _ = 1, #room.alive_players do
        curPlayer = curPlayer:getNextAlive(true)
        if curPlayer == target then
          return "path_player"
        elseif curPlayer == player then
          break
        end
      end
    end
  end,
})

return choosePath
