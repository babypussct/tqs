local wurong = fk.CreateSkill{
  name = "m_ex__wurong",
}

Fk:loadTranslationTable{
  ["m_ex__wurong"] = "怃戎",
  [":m_ex__wurong"] = "出牌阶段限一次，你可以与一名其他角色谋弈，根据双方选择的结果：<br>"..
  "镇压-反抗，你对其造成1点伤害，然后你摸一张牌。<br>"..
  "镇压-归顺，你获得其一张牌，然后交给其两张牌。<br>"..
  "安抚-反抗，你受到1点伤害，然后你摸一张牌。<br>"..
  "安抚-归顺，其交给你两张牌，若其牌数不足两张，则改为跳过其下一个摸牌阶段。",

  ["#m_ex__wurong"] = "怃戎：与一名其他角色谋弈",
  ["wurong-zhenya"] = "镇压",
  ["wurong-anfu"] = "安抚",
  ["wurong-fankang"] = "反抗",
  ["wurong-guishun"] = "归顺",
  [":wurong-zhenya"] = "对方选择“反抗”，你对其造成1点伤害，然后你摸一张牌<br>对方选择“归顺”，你获得其一张牌，然后交给其两张牌",
  [":wurong-anfu"] = "对方选择“反抗”，你受到1点伤害，然后你摸一张牌<br>对方选择“归顺”，其交给你两张牌，若其牌数不足两张，改为跳过其下一个摸牌阶段",
  [":wurong-fankang"] = "对方选择“镇压”，其对你造成1点伤害，然后其摸一张牌<br>对方选择“安抚”，其受到1点伤害，然后其摸一张牌",
  [":wurong-guishun"] = "对方选择“镇压”，其获得你一张牌，然后其交给你两张牌<br>对方选择“安抚”，你交给其两张牌，若你牌数不足两张，改为跳过你下一个摸牌阶段",
  ["#m_ex__wurong-prey"] = "怃戎：获得 %dest 一张牌",
  ["#m_ex__wurong-give"] = "怃戎：请交给 %dest 两张牌",
  ["@@m_ex__wurong_skip"] = "跳过摸牌",

  ["$m_ex__wurong1"] = "平乱羌，怃蛮夷，开旧道，复驿亭！",
  ["$m_ex__wurong2"] = "识断明果，以肃越巂千里蛮疆！",
  ["$m_ex__wurong3"] = "蛮不从化，化不及蛮，此嶷之过也。",
}

local U = require "packages.utility.utility"

wurong:addEffect("active", {
  mute = true,
  card_num = 0,
  target_num = 1,
  prompt = "#m_ex__wurong",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  target_filter = function (self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    player:broadcastSkillInvoke(wurong.name, 1)
    room:notifySkillInvoked(player, wurong.name, "offensive", {target.id})
    local result = U.doStrategy(room, player, target, {"wurong-zhenya", "wurong-anfu"}, {"wurong-fankang", "wurong-guishun"}, wurong.name, 666)
    room:sendLog{
      type = "#Choice",
      from = player.id,
      arg = result[1],
      toast = true,
    }
    room:sendLog{
      type = "#Choice",
      from = target.id,
      arg = result[2],
      toast = true,
    }
    if result[1] == "wurong-zhenya" then
      if result[2] == "wurong-fankang" then
        player:broadcastSkillInvoke(wurong.name, 3)
        room:doIndicate(player, {target})
        room:damage({
          from = player,
          to = target,
          damage = 1,
          skillName = wurong.name,
        })
        if not player.dead then
          player:drawCards(1, wurong.name)
        end
      else
        player:broadcastSkillInvoke(wurong.name, 2)
        if not target:isNude() then
          local cards = room:askToChooseCard(player, {
            target = target, flag = "he", skill_name = wurong.name,
            prompt = "#m_ex__wurong-prey::"..target.id,
          })
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, wurong.name, nil, false, player)
        end
        if player.dead or target.dead or player:isNude() then return end
        local cards = player:getCardIds("he")
        if #cards > 2 then
          cards = room:askToCards(player, {
            max_num = 2, min_num = 2, include_equip = true, skill_name = wurong.name, cancelable = false,
            prompt = "#m_ex__wurong-give::"..target.id,
          })
        end
        room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, wurong.name, nil, false, player)
      end
    else
      if result[2] == "wurong-fankang" then
        player:broadcastSkillInvoke(wurong.name, 3)
        room:damage({
          to = player,
          damage = 1,
          skillName = wurong.name,
        })
        if not player.dead then
          player:drawCards(1, wurong.name)
        end
      else
        player:broadcastSkillInvoke(wurong.name, 2)
        if #target:getCardIds("he") < 2 then
          room:setPlayerMark(target, "@@m_ex__wurong_skip", 1)
        else
          local cards = room:askToCards(target, {
            min_num = 2, max_num = 2, include_equip = true, skill_name = wurong.name, cancelable = false,
            prompt = "#m_ex__wurong-give::"..player.id,
          })
          room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, wurong.name, nil, false, target)
        end
      end
    end
  end,
})

wurong:addEffect(fk.EventPhaseChanging, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@m_ex__wurong_skip") > 0 and data.phase == Player.Draw
  end,
  on_use = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "@@m_ex__wurong_skip", 0)
    data.skipped = true
  end,
})

return wurong
