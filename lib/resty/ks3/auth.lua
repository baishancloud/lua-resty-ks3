local strutil = require("acid.strutil")
local tableutil = require("acid.tableutil")
local urlutil = require("acid.urlutil")

local _M = {
    __version = "0.01"
}


local sub_resource = {
    ['acl']=true, ['cors']=true, ['defaultObjectAcl']=true, ['location']=true, ['logging']=true,
    ['partNumber']=true, ['policy']=true, ['requestPayment']=true, ['torrent']=true,
    ['versioning']=true, ['versionId']=true, ['versions']=true, ['website']=true,
    ['uploads']=true, ['uploadId']=true, ['response-content-type']=true,
    ['response-content-language']=true, ['response-expires']=true,
    ['response-cache-control']=true, ['response-content-disposition']=true,
    ['response-content-encoding']=true, ['delete']=true, ['lifecycle']=true,
    ['tagging']=true, ['restore']=true, ['notification']=true, ['thumbnail']=true, ['queryadp']=true,
    ['adp']=true, ['asyntask']=true, ['querytask']=true, ['domain']=true,
    ['storageClass']=true,
    ['websiteConfig']=true,
    ['compose']=true,
}

local function canonical_headers(headers)
    local can_keys = {}
    for key, _ in pairs(headers) do
        if strutil.startswith(key, 'x-kss-') then
            table.insert(can_keys, key)
        end
    end

    if next(headers) == nil then
        return ''
    end

    table.sort(can_keys)

    local buf_list = {}
    for _, key in ipairs(can_keys) do
        table.insert(buf_list, key .. ':' .. headers[key])
    end

    return table.concat(buf_list, '\n')
end

local function encode_query_string(query_string)
    if query_string == '' then
        return ''
    end

    local map_args = {}
    if type(query_string) == 'table' then
        map_args = query_string
    else
        for _, param in ipairs(strutil.split(query_string, '&')) do
            local kv = strutil.split(param, '=', {maxsplit=1})
            local k = kv[1]
            if #kv == 1 then
                map_args[k] = ''
            else
                map_args[k] = kv[2]
            end
        end
    end

    if next(map_args) == nil then
        return ''
    end

    local map_keys = tableutil.keys(map_args)

    table.sort(map_keys)

    local buf_list = {}
    for _, k in ipairs(map_keys) do
        if sub_resource[k] ~= nil then
            local v = map_args[k]
            if v == '' then
                table.insert(buf_list, k)
            else
                table.insert(buf_list, k .. '='.. v)
            end
        end
    end

    return table.concat(buf_list, '&')
end

local function url_encode(key)
    return urlutil.url_escape_plus(key, '+*~/')
end

local function canonical_resource(bucket, key, query_string)
    local buf = "/"

    if bucket ~= '' then
        buf = buf .. bucket .. '/'
    end

    if key ~= '' then
        buf = buf .. url_encode(key)
    end

    buf = string.gsub(buf, '//', '/%%2F')

    query_string = encode_query_string(query_string)
    if query_string ~= '' then
        buf = buf .. '?' .. query_string
    end

    return buf
end

local function canonical_string(verb, bucket, key, headers, query_string)
    local can_headers = canonical_headers(headers)
    local can_resource = canonical_resource(bucket, key, query_string)

    local content_md5 = headers['Content-MD5'] or ''
    local content_type = headers['Content-Type'] or ''
    local date = headers['Date'] or ''

    local sign_list = {verb, content_md5, content_type, date}

    if can_headers ~= '' then
        table.insert(sign_list, can_headers)
    end

    if can_resource ~= '' then
        table.insert(sign_list, can_resource)
    end

    return table.concat(sign_list, '\n')
end

function _M.add_auth_header(ak, sk, verb, bucket, key, headers, query_string)
    bucket = bucket or ''
    key = key or ''
    query_string = query_string or ''
    headers = tableutil.dup(headers or {}, true)

    headers['Date'] = headers['Date'] or ngx.http_time(ngx.time())

    local c_str = canonical_string(verb, bucket, key, headers, query_string)
    local key = ngx.encode_base64(ngx.hmac_sha1(sk, c_str))

    return string.format("KSS %s:%s", ak, key)
end

return _M

