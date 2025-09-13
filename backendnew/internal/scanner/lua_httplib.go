package scanner

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	lua "github.com/yuin/gopher-lua"
)

// registerLuaHTTP exposes a minimal HTTP client to Lua under the global `http` table.
// Functions:
//
//	http.request(method, url, body?, headersTable?, timeoutSec?) -> statusCode(number), body(string), headers(table) | nil, err
//	http.get(url, headersTable?, timeoutSec?) -> statusCode, body, headers | nil, err
//	http.post(url, body, headersTable?, timeoutSec?) -> statusCode, body, headers | nil, err
func registerLuaHTTP(L *lua.LState) {
	// Helpers to move between Lua and Go types
	toHeaders := func(tbl lua.LValue) http.Header {
		h := make(http.Header)
		if tbl == lua.LNil {
			return h
		}
		t, ok := tbl.(*lua.LTable)
		if !ok {
			return h
		}
		t.ForEach(func(k, v lua.LValue) {
			key := k.String()
			switch vv := v.(type) {
			case lua.LString:
				h.Set(key, string(vv))
			case lua.LNumber:
				h.Set(key, fmt.Sprintf("%v", float64(vv)))
			default:
				h.Set(key, v.String())
			}
		})
		return h
	}

	headersToLua := func(h http.Header) *lua.LTable {
		t := L.NewTable()
		for k, vals := range h {
			L.SetField(t, k, lua.LString(strings.Join(vals, ", ")))
		}
		return t
	}

	doRequest := func(method, url, bodyStr string, headers http.Header, timeout time.Duration) (int, string, http.Header, error) {
		var body io.Reader
		if bodyStr != "" {
			body = bytes.NewBufferString(bodyStr)
		}
		req, err := http.NewRequest(method, url, body)
		if err != nil {
			return 0, "", nil, err
		}
		for k, vals := range headers {
			for _, v := range vals {
				req.Header.Add(k, v)
			}
		}
		if req.Header.Get("User-Agent") == "" {
			req.Header.Set("User-Agent", "RegTech-LuaScanner/1.0")
		}

		ctx := req.Context()
		if timeout > 0 {
			var cancel context.CancelFunc
			ctx, cancel = context.WithTimeout(ctx, timeout)
			defer cancel()
		}
		req = req.WithContext(ctx)

		client := &http.Client{Timeout: timeout}
		resp, err := client.Do(req)
		if err != nil {
			return 0, "", nil, err
		}
		defer resp.Body.Close()

		// Limit body to 10MB to avoid memory blowups
		const maxBody = 10 * 1024 * 1024
		lr := io.LimitReader(resp.Body, maxBody)
		b, err := io.ReadAll(lr)
		if err != nil {
			return 0, "", nil, err
		}
		return resp.StatusCode, string(b), resp.Header, nil
	}

	// http.request(method, url, body?, headers?, timeoutSec?)
	requestFn := L.NewFunction(func(L *lua.LState) int {
		method := strings.ToUpper(L.CheckString(1))
		url := L.CheckString(2)
		bodyStr := ""
		if L.GetTop() >= 3 && L.Get(3) != lua.LNil {
			bodyStr = L.ToString(3)
		}
		hdrs := toHeaders(lua.LNil)
		if L.GetTop() >= 4 {
			hdrs = toHeaders(L.Get(4))
		}
		timeout := 15 * time.Second
		if L.GetTop() >= 5 {
			to := L.ToNumber(5)
			if to > 0 {
				timeout = time.Duration(float64(to)) * time.Second
			}
		}

		status, body, respHdrs, err := doRequest(method, url, bodyStr, hdrs, timeout)
		if err != nil {
			L.Push(lua.LNil)
			L.Push(lua.LString(err.Error()))
			return 2
		}
		L.Push(lua.LNumber(status))
		L.Push(lua.LString(body))
		L.Push(headersToLua(respHdrs))
		return 3
	})

	// http.get(url, headers?, timeoutSec?)
	getFn := L.NewFunction(func(L *lua.LState) int {
		url := L.CheckString(1)
		hdrs := toHeaders(lua.LNil)
		if L.GetTop() >= 2 {
			hdrs = toHeaders(L.Get(2))
		}
		timeout := 15 * time.Second
		if L.GetTop() >= 3 {
			to := L.ToNumber(3)
			if to > 0 {
				timeout = time.Duration(float64(to)) * time.Second
			}
		}
		status, body, respHdrs, err := doRequest(http.MethodGet, url, "", hdrs, timeout)
		if err != nil {
			L.Push(lua.LNil)
			L.Push(lua.LString(err.Error()))
			return 2
		}
		L.Push(lua.LNumber(status))
		L.Push(lua.LString(body))
		L.Push(headersToLua(respHdrs))
		return 3
	})

	// http.post(url, body, headers?, timeoutSec?)
	postFn := L.NewFunction(func(L *lua.LState) int {
		url := L.CheckString(1)
		bodyStr := L.CheckString(2)
		hdrs := toHeaders(lua.LNil)
		if L.GetTop() >= 3 {
			hdrs = toHeaders(L.Get(3))
		}
		timeout := 15 * time.Second
		if L.GetTop() >= 4 {
			to := L.ToNumber(4)
			if to > 0 {
				timeout = time.Duration(float64(to)) * time.Second
			}
		}
		status, body, respHdrs, err := doRequest(http.MethodPost, url, bodyStr, hdrs, timeout)
		if err != nil {
			L.Push(lua.LNil)
			L.Push(lua.LString(err.Error()))
			return 2
		}
		L.Push(lua.LNumber(status))
		L.Push(lua.LString(body))
		L.Push(headersToLua(respHdrs))
		return 3
	})

	tbl := L.NewTable()
	L.SetField(tbl, "request", requestFn)
	L.SetField(tbl, "get", getFn)
	L.SetField(tbl, "post", postFn)
	L.SetGlobal("http", tbl)
}
