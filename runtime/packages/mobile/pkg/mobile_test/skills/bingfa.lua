local bingfa = fk.CreateSkill {
  name = "bingfa",
}

Fk:loadTranslationTable{
  ["bingfa"] = "禀法",
  [":bingfa"] = "每轮开始时，你可以指定两条<a href='#LawsDesc'>律法</a>，令所有武将牌正面朝上的角色进行选择。若如此做，本轮内结束时，" ..
  "你依次执行被选择次数最多的项。",

  ["#LawsDesc"] = "1.本轮造成伤害最多的角色受到2点无来源伤害；<br />" ..
  "2.本轮获得牌数最多的角色手牌上限-2；<br />" ..
  "3.本轮体力变化次数最多的角色减1点体力上限；<br />" ..
  "4.场上区域内牌数最多的角色交给每名其他角色各一张牌。",
  ["m_liuyi_laws_damage"] = "本轮造成伤害最多的角色受到2点无来源伤害",
  ["m_liuyi_laws_gain"] = "本轮获得牌数最多的角色手牌上限-2",
  ["m_liuyi_laws_hp"] = "本轮体力变化次数最多的角色减1点体力上限",
  ["m_liuyi_laws_cards"] = "场上区域内牌数最多的角色交给每名其他角色各一张牌",
  [":m_liuyi_laws_damage"] = "",
  [":m_liuyi_laws_gain"] = "",
  [":m_liuyi_laws_hp"] = "",
  [":m_liuyi_laws_cards"] = "",
  ["#bingfa-choose_basic"] = "禀法：请选择两条律法令所有未翻面的角色进行选择",
  ["#bingfa-choose"] = "禀法：请选择一条律法，被选择最多的将成为本轮律法",
  ["#bingfa-extra_choose"] = "禀法：请为其他角色选择本轮律法（还需选择%arg次）",
  ["@[bingfaDesc]bingfa_record-round"] = "禀法",
  ["#bingfa-distribute"] = "禀法：请分配给每名角色各一张牌",

  ["$bingfa1"] = "法者，天下之程式，万事之仪表。",
  ["$bingfa2"] = "明主之国，无书简之文，以法为教。",
  ["$bingfa3"] = "诚有功，则虽疏贱必赏；诚有过，则虽近爱必诛。",
  ["$bingfa4"] = "赏偷，则功臣墯其业，赦罚，则奸臣易为非。",
}

local laws = { "m_liuyi_laws_damage", "m_liuyi_laws_gain", "m_liuyi_laws_hp", "m_liuyi_laws_cards" }

bingfa:addEffect(fk.RoundStart, {
  audio_index = { 1, 2 },
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(bingfa.name)
  end,
  on_cost = function(self, event, target, player, data)
    local choices = player.room:askToChoices(
      player,
      {
        min_num = 2,
        max_num = 2,
        choices = laws,
        skill_name = bingfa.name,
        prompt = "#bingfa-choose_basic"
      }
    )

    if #choices == 2 then
      event:setCostData(self, { choices = choices })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = event:getCostData(self).choices
    local extraChoose = {}
    local targets = table.filter(room.alive_players, function(p)
      if p.faceup then
        if table.contains(p:getTableMark("bingfa_skip-noclear"), player.id) then
          room:removeTableMark(p, "bingfa_skip-noclear", player.id)
          table.insert(extraChoose, player)
          return false
        end

        return true
      end
    end)

    if #targets == 0 then
      return false
    end

    local result = room:askToJointChoice(
      player,
      {
        players = targets,
        choices = choices,
        skill_name = bingfa.name,
        prompt = "#bingfa-choose",
      }
    )

    local lawCount = {}
    table.forEach(extraChoose, function(p, index)
      local choice = room:askToChoice(
        p,
        {
          choices = choices,
          skill_name = bingfa.name,
          prompt = "#bingfa-extra_choose:::" .. #extraChoose - index + 1,
        }
      )

      lawCount[choice] = (lawCount[choice] or 0) + 1
    end)

    for _, choice in pairs(result) do
      lawCount[choice] = (lawCount[choice] or 0) + 1
    end

    local maxCount = 0
    local roundLaws = {}
    for choice, num in pairs(lawCount) do
      if num > maxCount then
        roundLaws = { choice }
        maxCount = num
      elseif num == maxCount then
        table.insert(roundLaws, choice)
      end
    end

    if #roundLaws > 0 then
      table.sort(roundLaws, function(a, b)
        return table.indexOf(laws, a) < table.indexOf(laws, b)
      end)
      room:setPlayerMark(player, "@[bingfaDesc]bingfa_record-round", roundLaws)
    end
  end,
})

bingfa:addEffect(fk.RoundEnd, {
  audio_index = { 3, 4 },
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@[bingfaDesc]bingfa_record-round") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = bingfa.name
    local room = player.room
    local roundLaws = player:getTableMark("@[bingfaDesc]bingfa_record-round")
    if table.contains(roundLaws, laws[1]) then
      local damageRecord = player:getTableMark("bingfa_damage_record-round")
      local targets = {}
      if next(damageRecord) == nil then
        targets = room:getAlivePlayers(false)
      else
        local maxDamage = 0
        for pId, num in pairs(damageRecord) do
          local p = room:getPlayerById(tonumber(pId))
          if num > maxDamage then
            targets = { p }
            maxDamage = num
          elseif num == maxDamage then
            table.insert(targets, p)
          end
        end
      end

      room:sortByAction(targets)
      table.forEach(targets, function(p)
        if p:isAlive() then
          room:damage{
            to = p,
            damage = 2,
            skillName = skillName,
          }
        end
      end)
    end

    if table.contains(roundLaws, laws[2]) then
      local gainRecord = player:getTableMark("bingfa_gain_record-round")
      local targets = {}
      if next(gainRecord) == nil then
        targets = room:getAlivePlayers(false)
      else
        local maxGain = 0
        for pId, num in pairs(gainRecord) do
          local p = room:getPlayerById(tonumber(pId))
          if num > maxGain then
            targets = { p }
            maxGain = num
          elseif num == maxGain then
            table.insert(targets, p)
          end
        end
      end

      room:sortByAction(targets)
      table.forEach(targets, function(p)
        room:addPlayerMark(p, MarkEnum.MinusMaxCards, 2)
      end)
    end

    if table.contains(roundLaws, laws[3]) then
      local hpRecord = player:getTableMark("bingfa_hp_record-round")
      local targets = {}
      if next(hpRecord) == nil then
        targets = room:getAlivePlayers(false)
      else
        local maxHpChanged = 0
        for pId, num in pairs(hpRecord) do
          local p = room:getPlayerById(tonumber(pId))
          if num > maxHpChanged then
            targets = { p }
            maxHpChanged = num
          elseif num == maxHpChanged then
            table.insert(targets, p)
          end
        end
      end

      room:sortByAction(targets)
      table.forEach(targets, function(p)
        if p:isAlive() then
          room:changeMaxHp(p, -1)
        end
      end)
    end

    if table.contains(roundLaws, laws[4]) then
      local targets = {}
      local maxCount = 0
      table.forEach(room.alive_players, function(p)
        local num = #p:getCardIds("hej")
        if num > maxCount then
          targets = { p }
          maxCount = num
        elseif num == maxCount then
          table.insert(targets, p)
        end
      end)

      table.forEach(targets, function(p)
        if p:isAlive() and not p:isNude() then
          local others = room:getOtherPlayers(p, false)
          local giveNum = math.min(#p:getCardIds("he"), #others)
          room:askToYiji(
            p,
            {
              min_num = giveNum,
              max_num = giveNum,
              targets = others,
              single_max = 1,
              cancelable = false,
              skill_name = skillName,
              prompt = "#bingfa-distribute",
            }
          )
        end
      end)
    end
  end,
})

bingfa:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      table.find(player.room.alive_players, function(p)
        return table.contains(p:getTableMark("@[bingfaDesc]bingfa_record-round"), laws[1])
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    table.forEach(player.room.alive_players, function(p)
      if table.contains(p:getTableMark("@[bingfaDesc]bingfa_record-round"), laws[1]) then
        local damageRecord = p:getTableMark("bingfa_damage_record-round")
        damageRecord[tostring(player.id)] = (damageRecord[tostring(player.id)] or 0) + data.damage
        player.room:setPlayerMark(p, "bingfa_damage_record-round", damageRecord)
      end
    end)
  end,
})

bingfa:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return table.find(data, function(move)
      if move.to == player and move.toArea == Card.PlayerHand then
        return table.find(player.room.alive_players, function(p)
          return table.contains(p:getTableMark("@[bingfaDesc]bingfa_record-round"), laws[2])
        end) ~= nil
      end
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    table.forEach(data, function(move)
      if move.to == player and move.toArea == Card.PlayerHand then
        table.forEach(player.room.alive_players, function(p)
          if table.contains(p:getTableMark("@[bingfaDesc]bingfa_record-round"), laws[2]) then
            local gainRecord = p:getTableMark("bingfa_gain_record-round")
            gainRecord[tostring(player.id)] = (gainRecord[tostring(player.id)] or 0) + #move.moveInfo
            player.room:setPlayerMark(p, "bingfa_gain_record-round", gainRecord)
          end
        end)
      end
    end)
  end,
})

bingfa:addEffect(fk.HpChanged, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      data.num ~= 0 and
      table.find(player.room.alive_players, function(p)
        return table.contains(p:getTableMark("@[bingfaDesc]bingfa_record-round"), laws[3])
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    table.forEach(player.room.alive_players, function(p)
      if table.contains(p:getTableMark("@[bingfaDesc]bingfa_record-round"), laws[3]) then
        local hpRecord = p:getTableMark("bingfa_hp_record-round")
        hpRecord[tostring(player.id)] = (hpRecord[tostring(player.id)] or 0) + 1
        player.room:setPlayerMark(p, "bingfa_hp_record-round", hpRecord)
      end
    end)
  end,
})

Fk:addQmlMark({
  name = "bingfaDesc",
  how_to_show = function(name, value, player)
    if type(value) == "table" then
      return table.concat(table.map(value, function(val) return table.indexOf(laws, val) end), " ")
    end

    return " "
  end,
  qml_path = "packages/utility/qml/DetailBox",
})

return bingfa
