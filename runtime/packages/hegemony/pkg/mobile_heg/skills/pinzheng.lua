
local pinzheng = fk.CreateSkill {
  name = "m_heg__pinzheng",
}

Fk:loadTranslationTable{
  ["m_heg__pinzheng"] = "品正",
  [":m_heg__pinzheng"] = "每局游戏限你已损失体力值次，出牌阶段，你可以令三名角色（须包含至少一名同势力角色）依次选择各不相同的一项："..
  "1.明置主或副将；2.进入连环状态；3.翻至背面向上。",

  ["#m_heg__pinzheng"] = "品正：令三名角色依次选择选择不同的一项：明置武将牌、进入连环状态、翻至背面向上",
  ["m_heg__pinzheng_show"] = "明置一张武将牌",
  ["m_heg__pinzheng_chain"] = "进入连环状态",

  ["$m_heg__pinzheng1"] = "天下岂独在朕，当与士族共治。",
  ["$m_heg__pinzheng2"] = "九州之事，朕不能知者，自有能知之人。",
  ["$m_heg__pinzheng3"] = "天下在朕御中，天下之事，亦在朕彀中。",
  ["$m_heg__pinzheng4"] = "新政定则士族归，士族归则天下安！",
}

local H = require "packages.hegemony.util"

pinzheng:addEffect("active", {
  anim_type = "control",
  prompt = "#m_heg__pinzheng",
  times = function (self, player)
    return player.phase == Player.Play and player:getLostHp() - player:usedSkillTimes(pinzheng.name, Player.HistoryGame) or -1
  end,
  card_num = 0,
  target_num = 3,
  can_use = function(self, player)
    return player:usedSkillTimes(pinzheng.name, Player.HistoryGame) < player:getLostHp()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected < 3
  end,
  feasible = function (self, player, selected, selected_cards, card)
    return #selected == 3 and
      table.find(selected, function (p)
        return H.compareKingdomWith(player, p)
      end)
  end,
  on_use = function(self, room, effect)
    room:sortByAction(effect.tos)
    local all_choices = { "m_heg__pinzheng_show", "m_heg__pinzheng_chain", "turnOver" }
    for _, p in ipairs(effect.tos) do
      if not p.dead then
        local choices = table.simpleClone(all_choices)
        if p.general ~= "anjiang" and p.deputyGeneral ~= "" and p.deputyGeneral ~= "anjiang" then
          table.removeOne(choices, "m_heg__pinzheng_show")
        end
        if #choices > 0 then
          local choice = room:askToChoice(p, {
            choices = choices,
            skill_name = pinzheng.name,
            all_choices = all_choices,
          })
          table.removeOne(all_choices, choice)
          if choice == "m_heg__pinzheng_show" then
            H.askToRevealGenerals(p, {
              skill_name = pinzheng.name,
              revealAll = false,
              cancelable = false,
            })
          elseif choice == "m_heg__pinzheng_chain" then
            p:setChainState(true)
          elseif choice == "turnOver" then
            if p.faceup then
              p:turnOver()
            end
          end
        end
      end
    end
  end,
})

return pinzheng
