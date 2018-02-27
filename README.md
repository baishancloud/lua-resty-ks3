# lua-resty-ks3
金山云 ks3 lua sdk，基于openresty

使用方法
```lua

local resty_ks3 = require "resty.ks3.ks3"

local accessKey	  =   "your accessKey";
local secretKey	  =   "your secretKey";
local bucket      =   "your bucket",

local opts = {
    endpoint = 'your ks3 endpoint',
    timeout  = 'request timeout',
}

local key_name = 'your key name'

local client, err_code, err_msg = resty_ks3.new(bucket, ak, sk, opts)
if err_code == nil then
    local _
     _, err_code, err_msg = client:delete_object(key_name)
end

if err_code ~= nil then
    ngx.log(ngx.ERR, to_str('delete ks3 file error. key_name:',
        key_name, ', err_code:', err_code, ', err_msg:', err_msg))

    return nil, 'DeleteKS3Error', err_msg
end

```

## 已实现方法

* delete_object     删除文件

## TODO
完整实现所有api，参考[金山云 ks3 API文档](https://docs.ksyun.com/directories/1083)

基本功能是没有问题的，欢迎使用
