local gebo = fk.CreateSkill {
  name = "os__gebo",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__gebo"] = "戈帛",
  [":os__gebo"] = "锁定技，游戏开始时或一名角色回复体力后，你亮出牌堆顶三张牌，选择获得一张牌，其余牌置于<a href='RenPile_href'>“仁”区</a>中。",

  ["#os__gebo-ask"] = "戈帛：获得一张牌，其余牌置于“仁”区",

  ["$os__gebo1"] = "今温使蜀，乃为化干戈为玉帛。",
  ["$os__gebo2"] = "愿吴蜀两国尽释前嫌，再为唇齿。",
}

local U = require "packages.utility.utility"

---@type TrigSkelSpec<NilEventFunc>
local spec = {
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(gebo.name)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3)
    room:turnOverCardsFromDrawPile(player, cards, gebo.name)
    local id = room:askToChooseCard(player, {
      target = player,
      flag = {
        card_data = {
          { "pile_draw", cards }
        }
      },
      skill_name = gebo.name,
      prompt = "#os__gebo-ask",
    })
    room:obtainCard(player, id, true, fk.ReasonPrey, player, gebo.name)
    cards = room:filterCardsByArea(cards, Card.Processing)
    U.AddToRenPile(player, cards, gebo.name)
  end,
}


gebo:addEffect(fk.GameStart, spec)

gebo:addEffect(fk.HpRecover, spec)

return gebo
