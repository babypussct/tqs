
local yongjin = fk.CreateSkill{
  name = "yongjin",
  tags = {Skill.Limited},
}

Fk:loadTranslationTable{
  ["yongjin"] = "勇进",
  [":yongjin"] = "限定技，出牌阶段，你可以将场上至多三张装备牌移至不同角色的装备区内。",
  ["#yongjin-choose"] = "勇进：你可以将场上至多三张装备牌移至不同角色的装备区内",

  ["$yongjin1"] = "急流勇进，覆戈倒甲！",
  ["$yongjin2"] = "长缨缚敌，先登夺旗！",
}

yongjin:addEffect("active", {
  can_use = function(self, player)
    return player:usedSkillTimes(yongjin.name, Player.HistoryGame) == 0
  end,
  anim_type = "big",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local tos = {}
    for i = 1, 3, 1 do
      if #room:canMoveCardInBoard("e") == 0 or player.dead then break end
      local targets = {}
      for _, p in ipairs(room.alive_players) do
        if not table.contains(tos, p) then
          table.insertIfNeed(targets, p)
        end
      end
      local to = room:askToChooseToMoveCardInBoard(player, {
        prompt = "#yongjin-choose",
        skill_name = yongjin.name,
        cancelable = true,
        flag = "e",
        tos = targets,
        no_indicate = false,
      })
      if #to == 2 then
        local result = room:askToMoveCardInBoard(player, {
          target_one = to[1],
          target_two = to[2],
          skill_name = yongjin.name,
          flag = "e",
        })
        if not table.contains(tos, to[2]) then
          table.insert(tos, to[2])
        end
        if not result then
          break
        end
      else
        break
      end
    end
  end,
})


return yongjin
