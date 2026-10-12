local guikuang = fk.CreateSkill {
  name = "heg__guikuang",
}

Fk:loadTranslationTable {
  ["heg__guikuang"] = "诡诳",
  [":heg__guikuang"] = "出牌阶段限一次，你可以选择两名势力各不相同的角色，令这两名角色拼点，然后拼点牌为红色的角色依次对拼点没赢的角色造成1点伤害。",

  ["#heg__guikuang"] = "诡诳：选择两名势力各不相同的角色，令这两名角色拼点，然后拼点牌为红色的角色依次对拼点没赢的角色造成1点伤害",

  ["$heg__guikuang1"] = "数载春去秋来，静看大江东流。",
  ["$heg__guikuang2"] = "吞吴克蜀，老臣毕生之志也。",
}

local H = require "packages.hegemony.util"

guikuang:addEffect("active", {
  anim_type = "offensive",
  prompt = "#heg__guikuang",
  can_use = function(self, player)
    return player:usedSkillTimes(guikuang.name, Player.HistoryPhase) == 0
  end,
  card_num = 0,
  target_num = 2,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and not to_select:isKongcheng() then
      return true
    elseif #selected == 1 and to_select:canPindian(selected[1]) then
      return H.compareKingdomWith(to_select, selected[1], true)
    end
  end,
  on_use = function(self, room, effect)
    local to1 = effect.tos[1]
    local to2 = effect.tos[2]
    to1:pindian({ to2 }, guikuang.name)
  end,
})

guikuang:addEffect(fk.PindianFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(guikuang.name) and data.reason == guikuang.name then
      for _, result in pairs(data.results) do
        if result.toCard and player.room:getCardArea(result.toCard) == Card.Processing and data.fromCard and player.room:getCardArea(data.fromCard) == Card.Processing then
          return data.from:isAlive() and data.tos[1]:isAlive()
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.tos[1]
    local targets = {}
    for _, p in ipairs(data.tos) do
      if data.results[p].winner ~= data.from then
        table.insertIfNeed(targets, data.from)
      end
      if data.results[p].winner ~= p then
        table.insertIfNeed(targets, p)
      end
    end
    room:sortByAction(targets)
    if data.fromCard.color == Card.Red then
      for _, p in ipairs(targets) do
        room:damage {
          from = data.from,
          to = p,
          skillName = guikuang.name,
          damage = 1,
        }
      end
    end
    for _, result in pairs(data.results) do
      if result.toCard and room:getCardArea(result.toCard) == Card.Processing then
        if result.toCard.color == Card.Red then
          for _, p in ipairs(targets) do
            room:damage {
              from = to,
              to = p,
              skillName = guikuang.name,
              damage = 1,
            }
          end
        end
      end
    end
  end,
})

return guikuang
