local xiezhi = fk.CreateSkill {
  name = "xiezhi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xiezhi"] = "挟志",
  [":xiezhi"] = "锁定技，当你的体力变化后，你获得X点蓄力点（X为本次变化的值）。若你会因此获得超额蓄力点，你的手牌上限和使用【杀】的次数上限+1。",

  ["@xiezhi_buff"] = "挟志",

  ["$xiezhi1"] = "西蜀沃野千里，何故思归魏阙？",
  ["$xiezhi2"] = "姜维降我而非降魏，此即天命所归。",
}

local U = require "packages.utility.utility"

xiezhi:addEffect(fk.HpChanged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiezhi.name) and data.num ~= 0
  end,
  on_use = function(self, event, target, player, data)
    local diff = player:getMark("skill_charge_max") - player:getMark("skill_charge")
    local num = math.abs(data.num)
    U.skillCharged(player, num)
    if diff < num then
      local room = player.room
      room:addPlayerMark(player, "@xiezhi_buff")
      room:addPlayerMark(player, MarkEnum.AddMaxCards)
      room:addPlayerMark(player, MarkEnum.SlashResidue)
    end
  end,
})

return xiezhi
