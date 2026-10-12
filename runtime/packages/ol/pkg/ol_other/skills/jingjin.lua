
local jingjin = fk.CreateSkill {
  name = "jingjin",
}

Fk:loadTranslationTable{
  ["jingjin"] = "精进",
  [":jingjin"] = "出牌阶段限四次，你可以获得牌至四张（若手牌数大于2，则先将手牌弃至2），然后用手牌完成一次24点或结束出牌阶段。"..
  "你每成功完成一次24点，本阶段使用【杀】次数+1。",

  ["#jingjin"] = "精进：摸至四张手牌，然后完成一次24点！",
  ["#jingjin-discard"] = "精进：弃置至两张手牌，然后摸至四张手牌，完成一次24点！",
  ["jingjin_result"] = "东吴二十一年教学检测题",
  ["#JingjinSelfSolved"] = "%from 成功解出了 %arg2：%arg",
  ["#JingjinOtherSolved"] = "%to 解出了 %from 没有解出的 %arg2 ：%arg",
  ["#JingjinHasSolve"] = "%from %arg2 有解：%arg",
  ["#JingjinNoSolve"] = "%from %arg2（%arg）无解",

  ["$jingjin1"] = "我本来想到了一个精彩的解法，但位置太少摆不下。",
  ["$jingjin2"] = "注意到，这江东究竟你是六，还是我是六？",
}

Fk:addMiniGame {
  name = jingjin.name,
  qml_path = "packages/ol/qml/JingJinBox",
  default_choice = function(player, data)
    return {}
  end,
}

jingjin:addEffect("active", {
  anim_type = "drawcard",
  prompt = function (self, player)
    return player:getHandcardNum() - 2 > 0 and "#jingjin-discard" or "#jingjin"
  end,
  max_phase_use_time = 4,
  times = function (self, player)
    return 4 - player:usedSkillTimes(jingjin.name, Player.HistoryPhase)
  end,
  card_num = function (self, player)
    return math.max(0, player:getHandcardNum() - 2)
  end,
  target_num = 0,
  can_use = function (self, player)
    return player:usedSkillTimes(jingjin.name, Player.HistoryPhase) < 4
  end,
  card_filter = function (self, player, to_select, selected, selected_targets)
    return #selected < math.max(0, player:getHandcardNum() - 2) and
        not player:prohibitDiscard(to_select) and
        table.contains(player:getCardIds(Player.Hand), to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local cards = effect.cards
    room:throwCard(cards, jingjin.name, player, player)
    if player.dead then return end
    local num = 4 - player:getHandcardNum()
    if num > 0 then
      player:drawCards(num, jingjin.name)
      if player.dead then return end
    end
    if player:isKongcheng() then
      player:endPlayPhase()
    else
      local cards = player:getCardIds("h")
      local nums = table.map(cards, function (id)
        return Fk:getCardById(id).number
      end)

      local operators = { "+", "-", "×", "÷" }
      local evaluate = function(values, signs)
        local numbers = { table.unpack(values) }
        local pending = { table.unpack(signs) }
        local i = 1
        while i <= #pending do
          if pending[i] == "×" or pending[i] == "÷" then
            if pending[i] == "÷" and numbers[i + 1] == 0 then return nil end
            local result = pending[i] == "×" and numbers[i] * numbers[i + 1]
              or numbers[i] / numbers[i + 1]
            table.remove(numbers, i)
            table.remove(numbers, i)
            table.insert(numbers, i, result)
            table.remove(pending, i)
          else
            i = i + 1
          end
        end

        local result = numbers[1]
        for j = 1, #pending do
          if pending[j] == "+" then
            result = result + numbers[j + 1]
          elseif pending[j] == "-" then
            result = result - numbers[j + 1]
          end
        end
        return result
      end

      ---@param values integer[]
      ---@return string[], integer[]?
      local find_operators = function(values)
        local indexes = { 1, 2, 3, 4 }
        local used = {}
        local selected = {}

        local function search(sign_index)
          if sign_index > 3 then
            local arranged = {}
            for _, index in ipairs(indexes) do
              table.insert(arranged, values[index])
            end
            local result = evaluate(arranged, selected)
            if result and math.abs(result - 24) < 1e-6 then
              return { table.unpack(selected) }, arranged
            end
            return nil, nil
          end

          for _, sign in ipairs(operators) do
            selected[sign_index] = sign
            local result, arranged = search(sign_index + 1)
            if result then return result, arranged end
          end
          return nil, nil
        end

        local function permute(position)
          if position > #indexes then
            local result, arranged = search(1)
            if result then return result, arranged end
            return nil
          end
          for i = 1, #indexes do
            if not used[i] then
              used[i] = true
              indexes[position] = i
              local result, arranged = permute(position + 1)
              if result then return result, arranged end
              used[i] = nil
            end
          end
          return nil
        end

        local res, arranged = permute(1)
        if res then
          return res, arranged
        else
          return {
          operators[math.random(#operators)],
          operators[math.random(#operators)],
          operators[math.random(#operators)],
          }, nil -- 随机假符号组合
        end
      end

      local solution_operators, solution_numbers = find_operators(nums)
      local data_table = {}
      for _, p in ipairs(room.players) do
        data_table[p.id] = {
          numbers = nums,
          operators = solution_operators,
        }
      end
      local req = room:askToMiniGame(room.players, {
        skill_name = jingjin.name,
        game_type = jingjin.name,
        data_table = data_table,
      })
      local res = req:getResult(player)
      local hasExpression = function(r)
        return r and type(r) == "string" and r ~= "" and r ~= "__cancel"
      end
      if hasExpression(res) then
        room:sendLog{
          type = "#JingjinSelfSolved",
          from = player.id,
          arg = res,
          arg2 = jingjin.name,
          toast = true,
        }
        room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase", 1)
      else
        local results = {}
        local someoneSolved = false
        for _, p in ipairs(room:getAlivePlayers()) do
          res = req:getResult(p)
          if hasExpression(res) then
            someoneSolved = true
            results[res] = results[res] or {}
            table.insert(results[res], p.id)
          end
        end
        if someoneSolved then
          for r, tos in pairs(results) do
            room:sendLog{
              type = "#JingjinOtherSolved",
              from = player.id,
              to = tos,
              arg = r,
              arg2 = jingjin.name,
              toast = true,
            }
          end
        elseif solution_numbers then
          local solve = tostring(solution_numbers[1])
          for i, op in ipairs(solution_operators) do
            solve = solve .. op .. tostring(solution_numbers[i + 1])
          end
          room:sendLog{
            type = "#JingjinHasSolve",
            from = player.id,
            arg = solve,
            arg2 = jingjin.name,
            toast = true,
          }
        else
          room:sendLog{
            type = "#JingjinNoSolve",
            from = player.id,
            arg = table.concat(nums, " "),
            arg2 = jingjin.name,
            toast = true,
          }
        end
        player:endPlayPhase()
      end
    end
  end,
})

return jingjin
