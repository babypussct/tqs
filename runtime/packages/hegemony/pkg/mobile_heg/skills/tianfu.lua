
local tianfu = fk.CreateSkill {
  name = "m_heg__tianfu",
  tags = { Skill.MainPlace },
}

Fk:loadTranslationTable{
  ["m_heg__tianfu"] = "天覆",
  [":m_heg__tianfu"] = "主将技，<a href='m_heg_summon'>阵法技</a>，你的回合内，你可以将一张♠手牌当【无懈可击】使用；"..
  "当你处于队列时，改为与你处于同一队列的角色的回合内，你可以将一张黑色手牌当【无懈可击】使用。",

  ["#m_heg__tianfu"] = "天覆：你可以将一张♠手牌当【无懈可击】使用",
  ["#m_heg__tianfu_update"] = "天覆：你可以将一张黑色手牌当【无懈可击】使用",

  ["$m_heg__tianfu1"] = "哼，有破绽。",
  ["$m_heg__tianfu2"] = "丞相已教我识得此计。",
}

local H = require "packages.hegemony.util"

tianfu:addEffect("viewas", {
  anim_type = "control",
  pattern = "nullification|.|black",
  prompt = function (self, player, selected_cards, selected)
    if #H.getFormationRelation(player) > 0 then
      return "#m_heg__tianfu_update"
    else
      return "#m_heg__tianfu"
    end
  end,
  handly_pile = true,
  filter_pattern = function (self, player, card_name, selected)
    if #H.getFormationRelation(player) > 0 then
      return {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|black|^equip",
      }
    else
      return {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|spade|^equip",
      }
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = tianfu.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_nullification = function (self, player, data)
    if #player:getHandlyIds() > 0 then
      local current = Fk:currentRoom():getCurrent()
      if current == player then
        return true
      else
        return current and H.inFormationRelation(current, player)
      end
    end
  end,
})

tianfu:addAI(nil, "vs_skill")

return tianfu
