local yingmou = fk.CreateSkill {
  name = "yingmou",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["yingmou"] = "英谋",
  [":yingmou"] = "转换技，游戏开始时可自选阴阳状态。每回合限一次，当你对其他角色使用牌后，你可以选择其中一个目标："..
    "<br>阳：你摸牌至与其相同（至多摸5张），然后视为对其使用【火攻】；"..
    "<br>阴：令全场手牌数最多的一名角色对其使用手中所有【杀】和伤害锦囊牌（没有需弃牌至与你相同）。"..
    "<br>若其未因此受到伤害，你对其造成1点火焰伤害。",

  ["#yingmou_yang-invoke"] = "英谋：选择一名角色，你将手牌补至与其相同，然后视为对其使用【火攻】",
  ["#yingmou_yin-invoke"] = "英谋：选择一名角色，然后令手牌最多的角色对其使用手牌中所有【杀】和伤害锦囊牌",
  ["#yingmou-choose"] = "英谋：选择手牌数最多的一名角色，其对 %dest 使用手牌中所有【杀】和伤害锦囊牌",

  ["#tymou_switch-choice"] = "%arg：选择阴阳状态",
  ["tymou_switch"] = "%arg（%arg2）",

  ["$yingmou1"] = "行计以险，纵略以奇，敌虽百万亦戏之如犬豕。",
  ["$yingmou2"] = "若生铸剑为犁之心，须有纵钺止戈之力。",
}

local U = require "packages.utility.utility"

yingmou:addEffect(fk.CardUseFinished, {
  anim_type = "switch",
  times = function (_, player)
    return 1 - player:usedSkillTimes(yingmou.name, Player.HistoryTurn)
  end,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingmou.name) and data.tos and
      table.find(data.tos, function(p)
        return p ~= player and not p.dead
      end) and
      player:usedEffectTimes(yingmou.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = table.filter(data.tos, function(p)
        return p ~= player and not p.dead
      end),
      min_num = 1,
      max_num = 1,
      skill_name = yingmou.name,
      cancelable = true,
      prompt = "#yingmou_"..player:getSwitchSkillState(yingmou.name, false, true).."-invoke",
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    U.SetSwitchSkillState(player, yingmou.name, player:getSwitchSkillState(yingmou.name, false))
    local to = event:getCostData(self).tos[1]
    if player:currentSwitchState() == fk.SwitchYang then
      local x = to:getHandcardNum() - player:getHandcardNum()
      if x > 0 then
        player:drawCards(math.min(x, 5), yingmou.name)
      end
      if to.dead then return end
      if not player.dead then
        local card = Fk:cloneCard("fire_attack")
        card.skillName = yingmou.name
        if player:canUseTo(card, to) then
          local use = { ---@type UseCardDataSpec
            from = player,
            tos = { to },
            card = card
          }
          room:useCard(use)
          if use.damageDealt and use.damageDealt[to] or to.dead then
            return
          end
        end
      end
    else
      local targets = {}
      local max_h = to:getHandcardNum()
      for _, p in ipairs(room.alive_players) do
        if p ~= to then
          local x = p:getHandcardNum()
          if x > max_h then
            max_h = x
            targets = { p }
          elseif x == max_h then
            table.insert(targets, p)
          end
        end
      end
      if #targets > 0 then
        local src
        if #targets == 1 then
          src = targets[1]
        else
          src = room:askToChoosePlayers(player, {
            targets = targets,
            min_num = 1,
            max_num = 1,
            skill_name = yingmou.name,
            cancelable = false,
            no_indicate = true,
            prompt = "#yingmou-choose::"..to.id,
          })[1]
        end
        local cards = src:getCardIds("h")
        local card
        local i = 1
        while i <= max_h do
          local c = Fk:getCardById(cards[i])
          if c.trueName == "slash" or (c.is_damage_card and c:isCommonTrick()) then
            card = c
            break
          end
          i = i + 1
        end
        if card == nil then
          local x = max_h - player:getHandcardNum()
          if x > 0 then
            room:askToDiscard(src, {
              min_num = x,
              max_num = x,
              include_equip = false,
              skill_name = yingmou.name,
              cancelable = false
            })
          end
        else
          local damaged = false
          for j = i, max_h, 1 do
            card = Fk:getCardById(cards[j])
            if (card.trueName == "slash" or (card.is_damage_card and card:isCommonTrick())) and
              table.contains(src:getCardIds("h"), cards[j]) and
              src:canUseTo(card, to, { bypass_distances = true, bypass_times = true }) then
              local use = { ---@type UseCardDataSpec
                from = src,
                tos = { to },
                card = card,
                extraUse = true
              }
              room:useCard(use)
              if to.dead then return end
              if use.damageDealt and use.damageDealt[to] then
                damaged = true
              end
              if src.dead then break end
            end
          end
          if damaged then
            return
          end
        end
      end
    end
    room:damage {
      from = player,
      to = to,
      damage = 1,
      damageType = fk.FireDamage
    }
  end,
})

yingmou:addEffect(fk.GameStart, {
  mute = true,
  is_delay_effect = true,
  priority = 1.5,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yingmou.name, true)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = { "tymou_switch:::yingmou:yang", "tymou_switch:::yingmou:yin" },
      skill_name = yingmou.name,
      prompt = "#tymou_switch-choice:::yingmou",
    })
    choice = choice:endsWith("yang") and fk.SwitchYang or fk.SwitchYin
    U.SetSwitchSkillState(player, yingmou.name, choice)
  end,
})

return yingmou
