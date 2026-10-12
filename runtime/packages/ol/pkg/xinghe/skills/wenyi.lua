local wenyi = fk.CreateSkill {
  name = "wenyi",
}

Fk:loadTranslationTable{
  ["wenyi"] = "温宜",
  [":wenyi"] = "每局游戏限1次，一名角色于一个回合内体力值变为1后，你可对其使用一张【桃】，"..
    "或交给其一张装备牌令其使用之，然后其复原武将牌。",

  ["#wenyi-invoke"] = "是否对 %dest 发动 温宜，选择一项效果",
  ["wenyi_peach"] = "对其使用【桃】",
  ["wenyi_equip"] = "给其一张装备牌",
  ["#wenyi-peach"] = "温宜：你可以对 %dest 使用【桃】",

  ["$wenyi1"] = "烦忧烟云散，妾意润心田。",
  ["$wenyi2"] = "温言软语，可解君忧？",
}

local U = require "packages.utility.utility"

local spec = {
  times = function(self, player)
    return 1 + player:getMark(wenyi.name) - player:usedSkillTimes(wenyi.name, Player.HistoryGame)
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(wenyi.name) and not target.dead and target.hp == 1 and
      player:usedSkillTimes(wenyi.name, Player.HistoryGame) < 1 + player:getMark(wenyi.name)
  end,
  on_cost = function(self, event, target, player, data)
    --FIXME: 桃未提前做合法性判定，暂且偷懒
    local cards, choice = U.askForCardByMultiPatterns(
      player,
      {
        { "", 0, 0, "wenyi_peach" },
        { ".|.|.|.|.|equip", 1, 1, "wenyi_equip" }
      },
      wenyi.name,
      true,
      "#wenyi-invoke::" .. target.id
    )
    if choice == "" then return false end
    event:setCostData(self, { tos = { target }, cards = cards })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skillName = wenyi.name
    local cards = event:getCostData(self).cards ---@type integer[]
    if #cards > 0 then
      if player ~= target or not table.contains(player:getCardIds("h"), cards[1]) then
        room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, skillName, nil, false, player)
        if target.dead then return end
      end
      if table.contains(target:getCardIds("h"), cards[1]) then
        local card = Fk:getCardById(cards[1])
        if card.type == Card.TypeEquip and target:canUseTo(card, target) then
          room:useCard({
            from = target,
            tos = { target },
            card = card,
          })
        if target.dead then return end
        end
      end
      target:reset()
    else
      local params = { ---@type AskToUseCardParams
        skill_name = skillName,
        pattern = "peach",
        prompt = "#wenyi-peach::" .. target.id,
        cancelable = true,
        extra_data = {
          must_targets = { target.id },
          fix_targets = { target.id }
        }
      }
      local peach_use = room:askToUseCard(player, params)
      if not peach_use then return end
      peach_use.tos = { target }
      room:useCard(peach_use)
    end
  end,
}

wenyi:addEffect(fk.Damaged, spec)

wenyi:addEffect(fk.HpLost, spec)

wenyi:addEffect(fk.HpRecover, spec)

wenyi:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, wenyi.name, 0)
end)

return wenyi
