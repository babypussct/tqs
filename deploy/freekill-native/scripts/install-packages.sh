#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DEPLOY_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$DEPLOY_DIR/versions.env"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

RUNTIME_DIR="${FREEKILL_RUNTIME_DIR:-$FREEKILL_INSTALL_ROOT/current}"
PACKAGES_DIR="$RUNTIME_DIR/packages"
PACKAGE_DB="$PACKAGES_DIR/packages.db"
PACKAGE_SEED_DIR="${FREEKILL_PACKAGE_SEED_DIR:-$FREEKILL_INSTALL_ROOT/releases/freekill-asio-static-$FREEKILL_ASIO_RELEASE-amd64/packages}"

[[ -d "$RUNTIME_DIR" ]] || die "Runtime directory does not exist: $RUNTIME_DIR"
[[ -f "$PACKAGES_DIR/init.sql" ]] || die "Missing package schema: $PACKAGES_DIR/init.sql"
command -v git >/dev/null 2>&1 || die "git is required"
command -v sqlite3 >/dev/null 2>&1 || die "sqlite3 is required"

mkdir -p "$PACKAGES_DIR"

clone_at_commit() {
  local name="$1"
  local url="$2"
  local commit="$3"
  local destination="$PACKAGES_DIR/$name"

  if [[ -e "$destination" && ! -d "$destination/.git" ]]; then
    die "Package path exists but is not a Git checkout: $destination"
  fi

  if [[ ! -d "$destination/.git" && -d "$PACKAGE_SEED_DIR/$name/.git" ]]; then
    # A previous verified runtime can seed the exact pinned checkout locally.
    # This avoids downloading large, immutable package histories again when
    # the source binary is rebuilt on a host with an unreliable remote link.
    mkdir -p "$destination"
    cp -a "$PACKAGE_SEED_DIR/$name/." "$destination/"
  fi

  if [[ ! -d "$destination/.git" ]]; then
    # Fetch the pinned object directly instead of cloning the moving default
    # branch. Several of the pinned Gitee repositories are large enough that
    # a full clone can lose its TLS connection before the exact revision is
    # available locally.
    mkdir -p "$destination"
    git -C "$destination" init -q
    git -C "$destination" remote add origin "$url"
  fi

  # Some Gitee repositories do not advertise older commit IDs through the
  # upload-pack endpoint. If a prior clone already resolved the exact pin,
  # avoid a redundant fetch that can fail even though the checkout is usable.
  if [[ "$(git -C "$destination" rev-parse HEAD 2>/dev/null || true)" == "$commit" ]]; then
    return
  fi

  if [[ -n "$(git -C "$destination" status --porcelain)" ]]; then
    die "Package checkout has uncommitted changes: $destination"
  fi

  git -C "$destination" fetch --depth 1 origin "$commit" >/dev/null 2>&1 || \
    git -C "$destination" fetch origin "$commit"
  git -C "$destination" checkout --detach "$commit" >/dev/null

  local actual
  actual="$(git -C "$destination" rev-parse HEAD)"
  [[ "$actual" == "$commit" ]] || die "$name resolved to $actual, expected $commit"
}

clone_at_commit "freekill-core" "$FREEKILL_CORE_URL" "$FREEKILL_CORE_COMMIT"
clone_at_commit "utility" "$UTILITY_URL" "$UTILITY_COMMIT"
clone_at_commit "hegemony" "$HEGEMONY_URL" "$HEGEMONY_COMMIT"
clone_at_commit "gamemode" "$GAMEMODE_URL" "$GAMEMODE_COMMIT"
clone_at_commit "standard_ex" "$STANDARD_EX_URL" "$STANDARD_EX_COMMIT"
clone_at_commit "shzl" "$SHZL_URL" "$SHZL_COMMIT"
clone_at_commit "yj" "$YJ_URL" "$YJ_COMMIT"
clone_at_commit "mobile" "$MOBILE_URL" "$MOBILE_COMMIT"
clone_at_commit "sp" "$SP_URL" "$SP_COMMIT"
clone_at_commit "tenyear" "$TENYEAR_URL" "$TENYEAR_COMMIT"
clone_at_commit "overseas" "$OVERSEAS_URL" "$OVERSEAS_COMMIT"
clone_at_commit "mougong" "$MOUGONG_URL" "$MOUGONG_COMMIT"
clone_at_commit "jsrg" "$JSRG_URL" "$JSRG_COMMIT"
clone_at_commit "ol" "$OL_URL" "$OL_COMMIT"

# Evidence-backed compatibility repair.  The pinned Hegemony declaration for
# overseas Duan Wei uses the unqualified `langmie`, while the exact upstream
# implementation is tenyear's `ty__langmie`.  Keep the package commit pin
# unchanged and repair only this declaration after checkout.
HEGEMONY_OVERSEAS_INIT="$PACKAGES_DIR/hegemony/pkg/overseas_heg/init.lua"
if grep -Fq 'General:new(extension, "os_heg__duanwei", "qun", 4):addSkills { "langmie" }' "$HEGEMONY_OVERSEAS_INIT"; then
  perl -0pi -e 's/General:new\(extension, "os_heg__duanwei", "qun", 4\):addSkills \{ "langmie" \}/General:new(extension, "os_heg__duanwei", "qun", 4):addSkills { "ty__langmie" }/' "$HEGEMONY_OVERSEAS_INIT"
fi
grep -Fq 'General:new(extension, "os_heg__duanwei", "qun", 4):addSkills { "ty__langmie" }' "$HEGEMONY_OVERSEAS_INIT" ||
  die "Pinned overseas Duan Wei declaration repair did not apply"

# Evidence-backed server hardening. The pinned core client already uses
# insertIfNeed for prelight projection, while the upstream ServerPlayer copy
# still appends duplicates. A repeated true request followed by one false
# request would then leave the hidden skill active on the server. Keep the
# native server aligned with the client and the vendored runtime; fail closed
# if the upstream function shape changes instead of patching an unknown body.
CORE_SERVERPLAYER="$PACKAGES_DIR/freekill-core/ltk/server/serverplayer.lua"
if grep -Fq 'table.insert(self.prelighted_skills, skill)' "$CORE_SERVERPLAYER" &&
    grep -Fq 'table.insert(self.prelighted_skills, s)' "$CORE_SERVERPLAYER"; then
  perl -0pi -e 's/table\.insert\(self\.prelighted_skills, skill\)/table.insertIfNeed(self.prelighted_skills, skill)/g; s/table\.insert\(self\.prelighted_skills, s\)/table.insertIfNeed(self.prelighted_skills, s)/g' "$CORE_SERVERPLAYER"
fi
grep -Fq 'table.insertIfNeed(self.prelighted_skills, skill)' "$CORE_SERVERPLAYER" ||
  die "Native ServerPlayer prelight projection hardening did not apply"
grep -Fq 'table.insertIfNeed(self.prelighted_skills, s)' "$CORE_SERVERPLAYER" ||
  die "Native ServerPlayer related prelight projection hardening did not apply"

# A hidden/changed general can re-attach a previously prelighted skill as a
# fake skill. Re-emit the retained prelight state after AddSkill so the live
# dashboard agrees with syncFakeSkills() on reconnect and with server hasSkill.
if grep -Fq 'self:doNotify("AddSkill", { self.id, skill.name, true })' "$CORE_SERVERPLAYER" &&
    ! grep -Fq 'self:doNotify("PrelightSkill", { skill.name, true })' "$CORE_SERVERPLAYER"; then
  perl -0pi -e 's{  self:doNotify\("AddSkill", \{ self\.id, skill\.name, true \}\)\nend}{  self:doNotify("AddSkill", { self.id, skill.name, true })\n  -- A hidden/replaced general can retain a prelighted skill when it becomes fake again.\n  if table.contains(self.prelighted_skills, skill) then\n    self:doNotify("PrelightSkill", { skill.name, true })\n  end\nend}s' "$CORE_SERVERPLAYER"
fi
grep -Fq 'self:doNotify("PrelightSkill", { skill.name, true })' "$CORE_SERVERPLAYER" ||
  die "Native ServerPlayer retained prelight notification hardening did not apply"

# The browser/native dashboard is not an authority for skill ownership. Only
# accept a true prelight request for a fake skill currently attached to the
# player's hidden generals. A false request is only stale-state cleanup for a
# choice the server still retains; otherwise prelightSkill() could register
# an unrelated skill in the room even though no projection existed.
CORE_ROOM="$PACKAGES_DIR/freekill-core/ltk/server/room.lua"
if grep -Fq 'p:prelightSkill(data[3], data[4] == "true")' "$CORE_ROOM"; then
  perl -0pi -e 's{function Room:handlePrelight\(id, data\)\n  local controller = self:getPlayerById\(id\)\n  if not controller then return end\n\n  local p = table\.find\(self\.players, function\(player\)\n    return table\.contains\(player\._observers, controller\._splayer\)\n  end\)\n  if p then\n    p:prelightSkill\(data\[3\], data\[4\] == "true"\)\n  end\nend}{function Room:handlePrelight(id, data)\n  local controller = self:getPlayerById(id)\n  if not controller then return end\n\n  if type(data) ~= "table" or type(data[3]) ~= "string" or\n      (data[4] ~= "true" and data[4] ~= "false") then\n    return\n  end\n\n  local skill = Fk.skills[data[3]]\n  if not skill then return end\n\n  local p = table.find(self.players, function(player)\n    return table.contains(player._observers, controller._splayer)\n  end)\n  if not p then return end\n\n  local isPrelight = data[4] == "true"\n  -- A browser/native client may only toggle a fake skill currently attached\n  -- to this player\x27s hidden generals.\n  if isPrelight and not p:isFakeSkill(skill) then return end\n\n  p:prelightSkill(skill, isPrelight)\nend}s' "$CORE_ROOM"
fi
if grep -Fq 'if isPrelight and not p:isFakeSkill(skill) then return end' "$CORE_ROOM"; then
  perl -0pi -e 's/  if isPrelight and not p:isFakeSkill\(skill\) then return end/  if isPrelight then\n    if not p:isFakeSkill(skill) then return end\n  elseif not table.contains(p.prelighted_skills, skill) then\n    return\n  end/' "$CORE_ROOM"
fi
grep -Fq 'if not p:isFakeSkill(skill) then return end' "$CORE_ROOM" ||
  die "Native Room fake-skill ownership hardening did not apply"
grep -Fq 'elseif not table.contains(p.prelighted_skills, skill) then' "$CORE_ROOM" ||
  die "Native Room stale-prelight cleanup hardening did not apply"

# The parent native process owns the admin pack lock list and passes it to the
# Lua worker through an environment value. Apply it after the mode's own
# disabled list so a browser cannot re-enable an admin locked package by
# changing CreateRoom settings.
CORE_RPC_FK="$PACKAGES_DIR/freekill-core/lua/server/rpc/fk.lua"
if grep -Fq 'function fk.GetDisabledPacks()' "$CORE_RPC_FK" &&
    ! grep -Fq 'function fk.GetTqsLockedPacks()' "$CORE_RPC_FK"; then
  perl -0pi -e 's{return os\.getenv\("FK_DISABLED_PACKS"\) or "\[\]"\nend}{return os.getenv("FK_DISABLED_PACKS") or "[]"\nend\n\n---@return string\nfunction fk.GetTqsLockedPacks()\n  return os.getenv("FK_TQS_LOCKED_PACKS") or "[]"\nend}s' "$CORE_RPC_FK"
fi
grep -Fq 'function fk.GetTqsLockedPacks()' "$CORE_RPC_FK" ||
  die "TQS locked-pack RPC environment bridge did not apply"

if ! grep -Fq 'fk.GetTqsLockedPacks()' "$CORE_ROOM"; then
  perl -0pi -e 's{  self\.disabled_generals = self:getSettings\('\''disabledGenerals'\''\)}{  local tqs_locked_packs = json.decode(fk.GetTqsLockedPacks())\n  if type(tqs_locked_packs) == "table" then\n    table.insertTable(self.disabled_packs, tqs_locked_packs)\n  end\n  self.disabled_generals = self:getSettings('\''disabledGenerals'\'')}s' "$CORE_ROOM"
fi
grep -Fq 'fk.GetTqsLockedPacks()' "$CORE_ROOM" ||
  die "TQS Room forced pack lock hardening did not apply"

sqlite3 "$PACKAGE_DB" < "$PACKAGES_DIR/init.sql"
sqlite3 "$PACKAGE_DB" <<SQL
DELETE FROM packages WHERE name IN ('freekill-core', 'utility', 'hegemony', 'gamemode', 'standard_ex', 'shzl', 'yj', 'mobile', 'sp', 'tenyear', 'overseas', 'mougong', 'jsrg', 'ol');
INSERT INTO packages (name, url, hash, enabled)
VALUES ('freekill-core', '$FREEKILL_CORE_URL', '$FREEKILL_CORE_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('utility', '$UTILITY_URL', '$UTILITY_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('hegemony', '$HEGEMONY_URL', '$HEGEMONY_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('gamemode', '$GAMEMODE_URL', '$GAMEMODE_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('standard_ex', '$STANDARD_EX_URL', '$STANDARD_EX_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('shzl', '$SHZL_URL', '$SHZL_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('yj', '$YJ_URL', '$YJ_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('mobile', '$MOBILE_URL', '$MOBILE_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('sp', '$SP_URL', '$SP_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('tenyear', '$TENYEAR_URL', '$TENYEAR_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('overseas', '$OVERSEAS_URL', '$OVERSEAS_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('mougong', '$MOUGONG_URL', '$MOUGONG_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('jsrg', '$JSRG_URL', '$JSRG_COMMIT', 1);
INSERT INTO packages (name, url, hash, enabled)
VALUES ('ol', '$OL_URL', '$OL_COMMIT', 1);
SQL

CONFIG_DEST="$RUNTIME_DIR/freekill.server.config.json"
if [[ ! -e "$CONFIG_DEST" || "${FORCE_CONFIG:-0}" == "1" ]]; then
  install -m 0644 "$DEPLOY_DIR/server/freekill.server.config.json" "$CONFIG_DEST"
fi

printf '%s\n' "Installed pinned packages into $RUNTIME_DIR"
sqlite3 "$PACKAGE_DB" "SELECT name || ' @ ' || substr(hash, 1, 12) || ' enabled=' || enabled FROM packages ORDER BY name;"
