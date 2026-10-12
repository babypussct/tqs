local jiangwu = fk.CreateSkill {
  name = "jiangwu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jiangwu"] = "讲武",
  [":jiangwu"] = "锁定技，首轮开始时，你选择三个价值不同的战法获得。每轮结束时，你进行一次消耗虎符的战法选择。"..
  "每名角色的回合结束时，你获得1枚虎符。",

  ["jiangwu_start"] = "讲武：选择获得三个价值不同的战法（右滑有更多战法）",

  ["$jiangwu1"] = "金戈耀长安，复光炎汉，当以武德昭日月。",
  ["$jiangwu2"] = "铁马临洛水，滚滚烽烟，尽是汉家驿马尘！",
}

local RougeUtil = require "packages.ol.pkg.ol_gamemode.rougelike1v1.util"

jiangwu:addEffect(fk.RoundStart, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jiangwu.name) and
      player.room:getBanner("RoundCount") == 1
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addSkill("#rougelike1v1_talent")
    --123费各两个
    local talents = { {}, {}, {} }
    for _, t in ipairs(RougeUtil.talents) do
      if t[1] > 0 and t[1] < 4 then
        table.insert(talents[t[1]], t)
      end
    end
    for i = 1, 3 do
      talents[i] = room:tableRandomPick(talents[i], 2)
    end
    local dat = {}
    for i = 1, 3 do
      table.insert(dat, { "talent", talents[i][1][1], talents[i][1][2] })
      table.insert(dat, { "talent", talents[i][2][1], talents[i][2][2] })
    end
    local result = room:askToCustomDialog(player, {
      skill_name = jiangwu.name,
      component = {
        url = "packages/ol/qml/JiangwuStart.qml",
        prop = {
          choices = dat,
        },
      }
    })
    if type(result) ~= "table" then
      result = { 1, { dat[1], dat[3], dat[5] } }
    end
    for i = 1, 3 do
      local talent = result[2][i][3]
      room:sendLog {
        type = "#rouge_shop_buy_talent",
        from = player.id,
        arg = talent,
      }
      for _, t in ipairs(RougeUtil.talents) do
        if t[2] == talent then
          t[3](talent, player)
        end
      end
    end
  end,
})

jiangwu:addEffect(fk.RoundEnd, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jiangwu.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:addSkill("#rougelike1v1_talent")
    local all_talents = { {}, {}, {} }
    for _, t in ipairs(RougeUtil.talents) do
      if t[1] > 0 and t[1] < 4 then
        table.insert(all_talents[t[1]], t)
      end
    end
    local talents = { {}, {}, {} }
    for i = 1, 3 do
      local available_talents = table.filter(all_talents[i], function (t)
        return not table.contains(player:getTableMark("@[rouge1v1]mark"), t[2])
      end)
      talents[i] = room:tableRandomPick(available_talents, 2)
    end
    for _ = 1, 10 do
      local dat = {}
      for i = 1, 3 do
        if #talents[i] > 0 then
          for j = 1, #talents[i] do
            table.insert(dat, { "talent", talents[i][j][1], talents[i][j][2] })
          end
        end
      end
      local availableMoney = player:getMark("rouge_money")
      local result = room:askToCustomDialog(player, {
        skill_name = jiangwu.name,
        component = {
          url = "packages/ol/qml/JiangwuRougeShop.qml",
          prop = {
            money = availableMoney,
            rest_money = availableMoney,
            choices = dat,
            ignore_money = player:getMark("@ol__xinghan") > 0,
          },
        }
      })
      if type(result) == "table" then
        if #result[2] == 0 then
          return
        end
        local talent = result[2][1][3]
        local cost = result[2][1][2]
        if player:getMark("@ol__xinghan") > 0 then
          room:removePlayerMark(player, "@ol__xinghan", 1)
        else
          RougeUtil.changeMoney(player, -cost)
        end
        room:sendLog {
          type = "#rouge_shop_buy_talent",
          from = player.id,
          arg = talent,
        }
        for _, t in ipairs(RougeUtil.talents) do
          if t[2] == talent then
            t[3](talent, player)
          end
        end
        if player.dead then return end
        local available_talents = table.filter(all_talents[cost], function (t)
          return not table.contains(player:getTableMark("@[rouge1v1]mark"), t[2])
        end)
        if #available_talents > 0 then
          for t = 1, #talents[cost] do
            if talents[cost][t][2] == talent then
              if #available_talents > 0 then
                talents[cost][t] = room:tableRandomPick(available_talents)
              else
                table.remove(talents[cost], t)
              end
              break
            end
          end
        end
      else
        return
      end
    end
  end,
})

jiangwu:addEffect(fk.TurnEnd, {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(jiangwu.name)
  end,
  on_use = function (self, event, target, player, data)
    RougeUtil.changeMoney(player, 1)
  end,
})

return jiangwu
