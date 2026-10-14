local M={}

local PURPOSES={
   secret={path="settings.html",description="view the zone secret"},
   cgen={path="cgen.html",description="download the zone-specific C module"}
}

local CHALLENGE_TTL=10*60
local GRANT_TTL=60
local MAX_ATTEMPTS=5
local RESEND_DELAY=60
local ISSUE_WINDOW=60*60
local MAX_ISSUES=5
local CLEANUP_PREVIEW_TTL=5*60

local function constantTimeEquals(left,right)
   if type(left) ~= "string" or type(right) ~= "string" or #left ~= #right then
      return false
   end
   local different=0
   for i=1,#left do
      different=different | (left:byte(i) ~ right:byte(i))
   end
   return different == 0
end

local function state(session)
   local value=session.sensitiveAction
   if type(value) ~= "table" then
      value={}
      session.sensitiveAction=value
   end
   return value
end

local function code()
   return ba.rndbs(6):gsub(".",function(byte)
      return string.format("%02X",byte:byte())
   end)
end

function M.purpose(name)
   return type(name) == "string" and PURPOSES[name] or nil
end

function M.csrf(session)
   local value=state(session)
   if type(value.csrf) ~= "string" then
      value.csrf=ba.b64urlencode(ba.rndbs(32))
   end
   return value.csrf
end

function M.validCsrf(session,supplied)
   return constantTimeEquals(M.csrf(session),supplied)
end

function M.createCleanupPreview(session,zid,cutoff,devices,now)
   now=now or os.time()
   local eligible={}
   for _,device in ipairs(devices) do eligible[tostring(device.did)]=true end
   local preview={
      id=ba.b64urlencode(ba.rndbs(24)),
      zid=zid,
      cutoff=cutoff,
      eligible=eligible,
      expires=now+CLEANUP_PREVIEW_TTL
   }
   state(session).cleanupPreview=preview
   return preview.id,preview.expires
end

function M.consumeCleanupPreview(session,id,zid,now)
   now=now or os.time()
   local value=state(session)
   local preview=value.cleanupPreview
   value.cleanupPreview=nil
   if type(preview) ~= "table" or type(preview.id) ~= "string" or
      type(preview.expires) ~= "number" or preview.expires < now or
      type(preview.eligible) ~= "table" or preview.zid ~= zid or
      not constantTimeEquals(preview.id,id) then
      return nil
   end
   return preview.cutoff,preview.eligible
end

function M.begin(session,purposeName,now)
   local purpose=M.purpose(purposeName)
   if not purpose then return nil,"invalid_purpose" end
   now=now or os.time()
   local value=state(session)
   local issued={}
   for _,timestamp in ipairs(type(value.issued) == "table" and value.issued or {}) do
      if type(timestamp) == "number" and now-timestamp < ISSUE_WINDOW then
         issued[#issued+1]=timestamp
      end
   end
   value.issued=issued
   if #issued >= MAX_ISSUES then
      return nil,"rate_limited",math.max(1,ISSUE_WINDOW-(now-issued[1]))
   end
   if type(value.lastIssued) == "number" and now-value.lastIssued < RESEND_DELAY then
      return nil,"cooldown",math.max(1,RESEND_DELAY-(now-value.lastIssued))
   end

   local challenge=value.challenge
   if type(challenge) ~= "table" or challenge.purpose ~= purposeName or
      type(challenge.code) ~= "string" or type(challenge.expires) ~= "number" or
      challenge.expires < now or type(challenge.attempts) ~= "number" or
      challenge.attempts >= MAX_ATTEMPTS then
      challenge={
         code=code(),
         purpose=purposeName,
         expires=now+CHALLENGE_TTL,
         attempts=0
      }
      value.challenge=challenge
   end
   issued[#issued+1]=now
   value.lastIssued=now
   return challenge,purpose
end

function M.hasChallenge(session,purposeName,now)
   now=now or os.time()
   local challenge=state(session).challenge
   return type(challenge) == "table" and challenge.purpose == purposeName and
      type(challenge.code) == "string" and type(challenge.expires) == "number" and
      type(challenge.attempts) == "number" and challenge.expires >= now and
      challenge.attempts < MAX_ATTEMPTS
end

function M.verify(session,purposeName,submitted,now)
   now=now or os.time()
   local value=state(session)
   local challenge=value.challenge
   local purpose=M.purpose(purposeName)
   local verification=type(submitted) == "string" and submitted:upper():gsub("%s","") or ""
   if not purpose or type(challenge) ~= "table" or challenge.purpose ~= purposeName or
      type(challenge.code) ~= "string" or type(challenge.expires) ~= "number" or
      type(challenge.attempts) ~= "number" or challenge.expires < now or
      challenge.attempts >= MAX_ATTEMPTS then
      value.challenge=nil
      return nil,"expired"
   end
   challenge.attempts=challenge.attempts+1
   if constantTimeEquals(challenge.code,verification) then
      value.challenge=nil
      value.grant={purpose=purposeName,expires=now+GRANT_TTL}
      return purpose
   end
   if challenge.attempts >= MAX_ATTEMPTS then
      value.challenge=nil
      return nil,"expired"
   end
   return nil,"invalid"
end

function M.consume(session,purposeName,now)
   now=now or os.time()
   local value=state(session)
   local grant=value.grant
   if type(grant) ~= "table" or type(grant.expires) ~= "number" or grant.expires < now then
      value.grant=nil
      return false
   end
   if grant.purpose ~= purposeName then return false end
   value.grant=nil
   return true
end

return M
