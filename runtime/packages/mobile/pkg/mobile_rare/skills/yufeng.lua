local yufeng = fk.CreateSkill {
  name = "mobile__yufeng",
}

Fk:loadTranslationTable{
  ["mobile__yufeng"] = "御风",
  [":mobile__yufeng"] = "出牌阶段限一次，你可以进行一次御风飞行。"..
  "若失败你摸X张牌；若成功，你可以选择至多X名其他角色，其下一个准备阶段进行一次判定："..
  "若结果为黑色，其跳过本回合的出牌和弃牌阶段；若结果为红色，其跳过本回合的摸牌阶段" ..
  "（若选择角色数不足X，剩余的分数改为摸等量张牌，X为御风飞行得分）。",

  ["#mobile__yufeng"] = "御风：你可以玩一次小游戏，根据得分执行效果",
  ["#mobile__yufeng-choose"] = "御风：选择至多%arg名其他角色，其下回合跳过摸牌或出牌弃牌阶段",
  ["@@mobile__yufeng"] = "御风",
  ["mobile__yufeng0"] = "惜哉，未能窥见星辰。",
  ["mobile__yufeng1"] = "风紧，赶紧跑。",
  ["mobile__yufeng2"] = "星辰已纳入囊中。",
  ["mobile__yufeng3"] = "满载而归，哈哈。",

  ["$mobile__yufeng1"] = "广开兮天门，纷吾乘兮玄云。",
  ["$mobile__yufeng2"] = "高飞兮安翔，乘清气兮御阴阳。",
}

Fk:addMiniGame {
  name = yufeng.name,
  qml_path = "packages/mobile/qml/FlappyBird",
  default_choice = function(player, data)
    return "0,false"
  end,
}

yufeng:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  prompt = "#mobile__yufeng",
  can_use = function(self, player)
    return player:usedSkillTimes(yufeng.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local data_table = {}
    for _, p in ipairs(room.players) do
      data_table[p.id] = {
      }
    end
    local req = room:askToMiniGame(room.players, {
      skill_name = yufeng.name,
      game_type = yufeng.name,
      data_table = data_table,
    })
    local result = req:getResult(player)
    if type(result) ~= "string" then
      result = "0,true"
    end
    local score = tonumber(result[1])  ---@cast score integer
    local success = result[3] == "f"
    player:chat(Fk:translate("mobile__yufeng"..score))

    if success and score > 0 then
      local tos = player.room:askToChoosePlayers(player, {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = score,
        prompt = "#mobile__yufeng-choose:::" .. score,
        skill_name = yufeng.name,
        cancelable = true,
      })
      if #tos > 0 then
        for _, p in ipairs(tos) do
          room:setPlayerMark(p, "@@mobile__yufeng", 1)
        end
      end
      score = score - #tos
    end
    if score > 0 then
      player:drawCards(score, yufeng.name)
    end
  end,
})
yufeng:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Start and player:getMark("@@mobile__yufeng") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@mobile__yufeng", 0)
    local judge = {
      who = player,
      reason = yufeng.name,
      pattern = {
        [".|.|black,red"] = "good",
        [".|.|red"] = "red",
        [".|.|black"] = "black",
        ["else"] = "bad",
      },
    }
    room:judge(judge)
    if not judge.results then return false end
    if table.contains(judge.results, "black") then
      player:skip(Player.Play)
      player:skip(Player.Discard)
    elseif table.contains(judge.results, "red") then
      player:skip(Player.Draw)
    end
  end,
})

return yufeng
