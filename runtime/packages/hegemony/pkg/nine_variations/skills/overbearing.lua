
local skill = fk.CreateSkill {
  name = "overbearing_skill",
}

local H = require "packages.hegemony.util"

skill:addEffect("cardskill", {
  prompt = "#overbearing_skill",
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected, card)
    return to_select.kingdom ~= "unknown"
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local target = effect.to
    if room:askToChoice(target, {
        choices = { "transformDeputy", "Cancel" },
        skill_name = skill.name,
      }) ~= "Cancel" then
        H.transformGeneral(room, target)
    end
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        card = effect.card,
        damage = 1,
        skillName = skill.name,
      }
    end
  end,
})

skill:addAI(Fk.Ltk.AI.newCardSkillStrategy {
  keep_value = 3.5,
  use_value = 5.5,
  use_priority = 4.5,

  on_effect = function(self, logic, effect)
    logic:damage({
      from = effect.from,
      to = effect.to,
      card = effect.card,
      damage = 1,
      skillName = skill.name,
    })
  end,
})

return skill
