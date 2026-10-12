
local jinqu = fk.CreateSkill({
  name = "m_ex__jinqu",
  tags = { Skill.Compulsory },
})

Fk:loadTranslationTable{
  ["m_ex__jinqu"] = "进趋",
  [":m_ex__jinqu"] = "锁定技，你每于回合内使用两张基本牌或普通锦囊牌后，你令一名角色获得1点蓄力点；"..
  "结束阶段，你摸X张牌（X为本回合你蓄力点数存在过的最高值）。",

  ["#m_ex__jinqu-choose"] = "进趋：令一名角色获得1点蓄力点",

  ["$m_ex__jinqu1"] = "和远先和己身，定众当在己心。",
  ["$m_ex__jinqu2"] = "夫民逸则易虑，民苦则思难。",
  ["$m_ex__jinqu3"] = "伐吴当有经年之备，岂争朝夕之间。",
  ["$m_ex__jinqu4"] = "积蓄水陆之实，用时必有所为！",
}

local U = require "packages.utility.utility"

jinqu:addEffect(fk.CardUseFinished, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jinqu.name) and
      player.room:getCurrent() == player and (data.extra_data or {}).m_ex__jinqu and
      table.find(player.room.alive_players, function (p)
        return p:getMark("skill_charge") < p:getMark("skill_charge_max") and
          table.find(p:getSkillNameList(), function(s)
            return Fk.skills[s]:hasTag(Skill.Charge)
          end) ~= nil
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return p:getMark("skill_charge") < p:getMark("skill_charge_max") and
        table.find(p:getSkillNameList(), function(s)
          return Fk.skills[s]:hasTag(Skill.Charge)
        end) ~= nil
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#m_ex__jinqu-choose",
      skill_name = jinqu.name,
      cancelable = false,
    })[1]
    U.skillCharged(to, 1)
  end,

  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(jinqu.name, true) and
      player.room:getCurrent() == player and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, jinqu.name, 1)
    if player:getMark(jinqu.name) >= 2 then
      room:setPlayerMark(player, jinqu.name, 0)
      data.extra_data = data.extra_data or {}
      data.extra_data.m_ex__jinqu = true
    end
  end,
})

jinqu:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(jinqu.name) and player.phase == Player.Finish and
      player:getMark("m_ex__jinqu-turn") > 0
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(player:getMark("m_ex__jinqu-turn"), jinqu.name)
  end,
})

jinqu:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(jinqu.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "m_ex__jinqu-turn", player:getMark("skill_charge"))
  end,
})

jinqu:addEffect(U.SkillChargeChanged, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(jinqu.name, true) and
      player.room:getCurrent() == player and player:getMark("skill_charge") > player:getMark("m_ex__jinqu-turn")
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "m_ex__jinqu-turn", player:getMark("skill_charge"))
  end,
})

jinqu:addAcquireEffect(function (self, player, is_start, src)
  local room = player.room
  if room:getCurrent() == player then
    room:setPlayerMark(player, "m_ex__jinqu-turn", player:getMark("skill_charge"))
  end
end)

jinqu:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, jinqu.name, 0)
end)

return jinqu
