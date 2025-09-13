package scanner

import (
	"bufio"
	"errors"
	"fmt"
	"net"
	"strconv"
	"sync"
	"time"

	lua "github.com/yuin/gopher-lua"
)

// registerLuaNet adds a minimal TCP client library to the provided Lua state.
// Exposes the following in Lua under the global table `tcp`:
//
//	tcp.connect(host, port, timeout_sec?) -> fd | nil, err
//	tcp.send(fd, data) -> bytes_sent | nil, err
//	tcp.recv(fd, max_bytes, timeout_sec?) -> data | nil, err
//	tcp.close(fd) -> true | nil, err
func registerLuaNet(L *lua.LState) {
	// Per-Lua-state connection registry
	type connRegistry struct {
		mu    sync.Mutex
		next  int64
		conns map[int64]net.Conn
	}

	reg := &connRegistry{conns: make(map[int64]net.Conn), next: 1}

	// Helpers
	getConn := func(fd int64) (net.Conn, error) {
		reg.mu.Lock()
		defer reg.mu.Unlock()
		c, ok := reg.conns[fd]
		if !ok {
			return nil, fmt.Errorf("tcp: invalid fd %d", fd)
		}
		return c, nil
	}

	storeConn := func(c net.Conn) int64 {
		reg.mu.Lock()
		defer reg.mu.Unlock()
		id := reg.next
		reg.next++
		reg.conns[id] = c
		return id
	}

	deleteConn := func(fd int64) {
		reg.mu.Lock()
		defer reg.mu.Unlock()
		delete(reg.conns, fd)
	}

	// tcp.connect(host, port, timeout_sec?)
	connect := L.NewFunction(func(L *lua.LState) int {
		host := L.CheckString(1)
		portVal := L.CheckAny(2)

		var port string
		switch v := portVal.(type) {
		case lua.LString:
			port = string(v)
		case lua.LNumber:
			port = strconv.Itoa(int(v))
		default:
			L.Push(lua.LNil)
			L.Push(lua.LString("tcp.connect: port must be number or string"))
			return 2
		}

		timeout := 10 * time.Second
		if L.GetTop() >= 3 {
			to := L.ToNumber(3)
			if to > 0 {
				timeout = time.Duration(float64(to)) * time.Second
			}
		}

		addr := net.JoinHostPort(host, port)
		conn, err := net.DialTimeout("tcp", addr, timeout)
		if err != nil {
			L.Push(lua.LNil)
			L.Push(lua.LString(err.Error()))
			return 2
		}
		// Set initial deadlines to zero (no deadline)
		_ = conn.SetDeadline(time.Time{})
		fd := storeConn(conn)
		L.Push(lua.LNumber(fd))
		return 1
	})

	// tcp.send(fd, data)
	send := L.NewFunction(func(L *lua.LState) int {
		fd := int64(L.CheckNumber(1))
		data := L.CheckString(2)

		conn, err := getConn(fd)
		if err != nil {
			L.Push(lua.LNil)
			L.Push(lua.LString(err.Error()))
			return 2
		}
		n, err := conn.Write([]byte(data))
		if err != nil {
			L.Push(lua.LNil)
			L.Push(lua.LString(err.Error()))
			return 2
		}
		L.Push(lua.LNumber(n))
		return 1
	})

	// tcp.recv(fd, max_bytes, timeout_sec?)
	recv := L.NewFunction(func(L *lua.LState) int {
		fd := int64(L.CheckNumber(1))
		maxBytes := int(L.CheckNumber(2))
		if maxBytes <= 0 || maxBytes > 10*1024*1024 {
			L.Push(lua.LNil)
			L.Push(lua.LString("tcp.recv: max_bytes out of range"))
			return 2
		}
		timeout := 10 * time.Second
		if L.GetTop() >= 3 {
			to := L.ToNumber(3)
			if to > 0 {
				timeout = time.Duration(float64(to)) * time.Second
			}
		}

		conn, err := getConn(fd)
		if err != nil {
			L.Push(lua.LNil)
			L.Push(lua.LString(err.Error()))
			return 2
		}
		_ = conn.SetReadDeadline(time.Now().Add(timeout))
		defer conn.SetReadDeadline(time.Time{})

		reader := bufio.NewReader(conn)
		buf := make([]byte, maxBytes)
		n, err := reader.Read(buf)
		if err != nil {
			var netErr net.Error
			if errors.As(err, &netErr) && netErr.Timeout() {
				// timeout -> empty payload rather than hard error
				L.Push(lua.LString(""))
				return 1
			}
			L.Push(lua.LNil)
			L.Push(lua.LString(err.Error()))
			return 2
		}
		L.Push(lua.LString(string(buf[:n])))
		return 1
	})

	// tcp.close(fd)
	closeFn := L.NewFunction(func(L *lua.LState) int {
		fd := int64(L.CheckNumber(1))
		conn, err := getConn(fd)
		if err != nil {
			L.Push(lua.LNil)
			L.Push(lua.LString(err.Error()))
			return 2
		}
		_ = conn.Close()
		deleteConn(fd)
		L.Push(lua.LTrue)
		return 1
	})

	// Build tcp table
	tcpTable := L.NewTable()
	L.SetField(tcpTable, "connect", connect)
	L.SetField(tcpTable, "send", send)
	L.SetField(tcpTable, "recv", recv)
	L.SetField(tcpTable, "close", closeFn)
	L.SetGlobal("tcp", tcpTable)
}
