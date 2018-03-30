Python asyncio cheatsheet
=========================

.. contents:: Table of Contents
    :backlinks: none


What is @asyncio.coroutine?
---------------------------

.. code-block:: python

    import asyncio
    import inspect
    from functools import wraps

    Future = asyncio.futures.Future
    def coroutine(func):
        """Simple prototype of coroutine"""
        @wraps(func)
        def coro(*a, **k):
            res = func(*a, **k)
            if isinstance(res, Future) or inspect.isgenerator(res):
                res = yield from res
            return res
        return coro

    @coroutine
    def foo():
        yield from asyncio.sleep(1)
        print("Hello Foo")

    @asyncio.coroutine
    def bar():
        print("Hello Bar")

    loop = asyncio.get_event_loop()
    tasks = [loop.create_task(foo()),
             loop.create_task(bar())]
    loop.run_until_complete(
         asyncio.wait(tasks))
    loop.close()

output:

.. code-block:: console

    $ python test.py
    Hello Bar
    Hello Foo


What is a Task?
---------------

.. code-block:: python

    # goal: supervise coroutine run state
    # ref: asyncio/tasks.py

    import asyncio
    Future = asyncio.futures.Future

    class Task(Future):
        """Simple prototype of Task"""

        def __init__(self, gen, *,loop):
            super().__init__(loop=loop)
            self._gen = gen
            self._loop.call_soon(self._step)

        def _step(self, val=None, exc=None):
            try:
                if exc:
                    f = self._gen.throw(exc)
                else:
                    f = self._gen.send(val)
            except StopIteration as e:
                self.set_result(e.value)
            except Exception as e:
                self.set_exception(e)
            else:
                f.add_done_callback(
                     self._wakeup)

        def _wakeup(self, fut):
            try:
                res = fut.result()
            except Exception as e:
                self._step(None, e)
            else:
                self._step(res, None)

    @asyncio.coroutine
    def foo():
        yield from asyncio.sleep(3)
        print("Hello Foo")

    @asyncio.coroutine
    def bar():
        yield from asyncio.sleep(1)
        print("Hello Bar")

    loop = asyncio.get_event_loop()
    tasks = [Task(foo(), loop=loop),
             loop.create_task(bar())]
    loop.run_until_complete(
            asyncio.wait(tasks))
    loop.close()

output:

.. code-block:: console

    $ python test.py
    Hello Bar
    hello Foo


What event loop doing? (Without polling)
----------------------------------------

.. code-block:: python

    import asyncio
    from collections import deque

    def done_callback(fut):
        fut._loop.stop()

    class Loop:
        """Simple event loop prototype"""

        def __init__(self):
            self._ready = deque()
            self._stopping = False

        def create_task(self, coro):
            Task = asyncio.tasks.Task
            task = Task(coro, loop=self)
            return task

        def run_until_complete(self, fut):
            tasks = asyncio.tasks
            # get task
            fut = tasks.ensure_future(
                        fut, loop=self)
            # add task to ready queue
            fut.add_done_callback(done_callback)
            # run tasks
            self.run_forever()
            # remove task from ready queue
            fut.remove_done_callback(done_callback)

        def run_forever(self):
            """Run tasks until stop"""
            try:
                while True:
                    self._run_once()
                    if self._stopping:
                        break
            finally:
                self._stopping = False

        def call_soon(self, cb, *args):
            """Append task to ready queue"""
            self._ready.append((cb, args))
        def call_exception_handler(self, c):
            pass

        def _run_once(self):
            """Run task at once"""
            ntodo = len(self._ready)
            for i in range(ntodo):
                t, a = self._ready.popleft()
                t(*a)

        def stop(self):
            self._stopping = True

        def close(self):
            self._ready.clear()

        def get_debug(self):
            return False

    @asyncio.coroutine
    def foo():
        print("Foo")

    @asyncio.coroutine
    def bar():
        print("Bar")

    loop = Loop()
    tasks = [loop.create_task(foo()),
             loop.create_task(bar())]
    loop.run_until_complete(
            asyncio.wait(tasks))
    loop.close()

output:

.. code-block:: console

    $ python test.py
    Foo
    Bar


What ``asyncio.wait`` doing?
-----------------------------

.. code-block:: python

    import asyncio

    async def wait(fs, loop=None):
        fs = {asyncio.ensure_future(_) for _ in set(fs)}
        if loop is None:
            loop = asyncio.get_event_loop()

        waiter = loop.create_future()
        counter = len(fs)

        def _on_complete(f):
            nonlocal counter
            counter -= 1
            if counter <= 0 and not waiter.done():
                 waiter.set_result(None)

        for f in fs:
            f.add_done_callback(_on_complete)

        # wait all tasks done
        await waiter

        done, pending = set(), set()
        for f in fs:
            f.remove_done_callback(_on_complete)
            if f.done():
                done.add(f)
            else:
                pending.add(f)
        return done, pending

    async def slow_task(n):
        await asyncio.sleep(n)
        print('sleep "{}" sec'.format(n))

    loop = asyncio.get_event_loop()

    try:
        print("---> wait")
        loop.run_until_complete(
                wait([slow_task(_) for _ in range(1,3)]))
        print("---> asyncio.wait")
        loop.run_until_complete(
                asyncio.wait([slow_task(_) for _ in range(1,3)]))
    finally:
        loop.close()

output:

.. code-block:: bash

    ---> wait
    sleep "1" sec
    sleep "2" sec
    ---> asyncio.wait
    sleep "1" sec
    sleep "2" sec


Future like object
--------------------

.. code-block:: python

    >>> import sys
    >>> PY_35 = sys.version_info >= (3, 5)
    >>> import asyncio
    >>> loop = asyncio.get_event_loop()
    >>> class SlowObj:
    ...     def __init__(self, n):
    ...         print("__init__")
    ...         self._n = n
    ...     if PY_35:
    ...         def __await__(self):
    ...             print("__await__ sleep({})".format(self._n))
    ...             yield from asyncio.sleep(self._n)
    ...             print("ok")
    ...             return self
    ...
    >>> async def main():
    ...     obj = await SlowObj(3)
    ...
    >>> loop.run_until_complete(main())
    __init__
    __await__ sleep(3)
    ok


Future like object ``__await__`` other task
--------------------------------------------

.. code-block:: python

    >>> import sys
    >>> PY_35 = sys.version_info >= (3, 5)
    >>> import asyncio
    >>> loop = asyncio.get_event_loop()
    >>> async def slow_task(n):
    ...     await asyncio.sleep(n)
    ...
    >>> class SlowObj:
    ...     def __init__(self, n):
    ...         print("__init__")
    ...         self._n = n
    ...     if PY_35:
    ...         def __await__(self):
    ...             print("__await__")
    ...             yield from slow_task(self._n).__await__()
    ...             yield from asyncio.sleep(self._n)
    ...             print("ok")
    ...             return self
    ...
    >>> async def main():
    ...     obj = await SlowObj(1)
    ...
    >>> loop.run_until_complete(main())
    __init__
    __await__
    ok


Patch loop runner ``_run_once``
--------------------------------

.. code-block:: python

    >>> import asyncio
    >>> def _run_once(self):
    ...     num_tasks = len(self._scheduled)
    ...     print("num tasks in queue: {}".format(num_tasks))
    ...     super(asyncio.SelectorEventLoop, self)._run_once()
    ...
    >>> EventLoop = asyncio.SelectorEventLoop
    >>> EventLoop._run_once = _run_once
    >>> loop = EventLoop()
    >>> asyncio.set_event_loop(loop)
    >>> async def task(n):
    ...     await asyncio.sleep(n)
    ...     print("sleep: {} sec".format(n))
    ...
    >>> coro = loop.create_task(task(3))
    >>> loop.run_until_complete(coro)
    num tasks in queue: 0
    num tasks in queue: 1
    num tasks in queue: 0
    sleep: 3 sec
    num tasks in queue: 0
    >>> loop.close()


Put blocking task into Executor
--------------------------------

.. code-block:: python

    >>> import asyncio
    >>> from concurrent.futures import ThreadPoolExecutor
    >>> e = ThreadPoolExecutor()
    >>> loop = asyncio.get_event_loop()
    >>> async def read_file(file_):
    ...     with open(file_) as f:
    ...         data = await loop.run_in_executor(e, f.read)
    ...         return data

    >>> task = loop.create_task(read_file('/etc/passwd'))
    >>> ret = loop.run_until_complete(task)


Socket with asyncio
-------------------

.. code-block:: python

    import asyncio
    import socket

    host = 'localhost'
    port = 9527
    loop = asyncio.get_event_loop()
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.setblocking(False)
    s.bind((host, port))
    s.listen(10)

    async def handler(conn):
        while True:
            msg = await loop.sock_recv(conn, 1024)
            if not msg:
                break
            await loop.sock_sendall(conn, msg)
        conn.close()

    async def server():
        while True:
            conn, addr = await loop.sock_accept(s)
            loop.create_task(handler(conn))

    loop.create_task(server())
    loop.run_forever()
    loop.close()

output: (bash 1)

.. code-block:: console

    $ nc localhost 9527
    Hello
    Hello

output: (bash 2)

.. code-block:: console

    $ nc localhost 9527
    World
    World


Event Loop with polling
-----------------------

.. code-block:: python

    # using selectors
    # ref: PyCon 2015 - David Beazley

    import asyncio
    import socket
    import selectors
    from collections import deque

    @asyncio.coroutine
    def read_wait(s):
        yield 'read_wait', s

    @asyncio.coroutine
    def write_wait(s):
        yield 'write_wait', s

    class Loop:
        """Simple loop prototype"""

        def __init__(self):
            self.ready = deque()
            self.selector = selectors.DefaultSelector()

        @asyncio.coroutine
        def sock_accept(self, s):
            yield from read_wait(s)
            return s.accept()

        @asyncio.coroutine
        def sock_recv(self, c, mb):
            yield from read_wait(c)
            return c.recv(mb)

        @asyncio.coroutine
        def sock_sendall(self, c, m):
            while m:
                yield from write_wait(c)
                nsent = c.send(m)
                m = m[nsent:]

        def create_task(self, coro):
            self.ready.append(coro)

        def run_forever(self):
            while True:
                self._run_once()

        def _run_once(self):
            while not self.ready:
                events = self.selector.select()
                for k, _ in events:
                    self.ready.append(k.data)
                    self.selector.unregister(k.fileobj)

            while self.ready:
                self.cur_t = ready.popleft()
                try:
                    op, *a = self.cur_t.send(None)
                    getattr(self, op)(*a)
                except StopIteration:
                    pass

        def read_wait(self, s):
            self.selector.register(s, selectors.EVENT_READ, self.cur_t)

        def write_wait(self, s):
            self.selector.register(s, selectors.EVENT_WRITE, self.cur_t)

    loop = Loop()
    host = 'localhost'
    port = 9527

    s = socket.socket(
            socket.AF_INET,
            socket.SOCK_STREAM, 0)
    s.setsockopt(
            socket.SOL_SOCKET,
            socket.SO_REUSEADDR, 1)
    s.setblocking(False)
    s.bind((host, port))
    s.listen(10)

    @asyncio.coroutine
    def handler(c):
        while True:
            msg = yield from loop.sock_recv(c, 1024)
            if not msg:
                break
            yield from loop.sock_sendall(c, msg)
        c.close()

    @asyncio.coroutine
    def server():
        while True:
            c, addr = yield from loop.sock_accept(s)
            loop.create_task(handler(c))

    loop.create_task(server())
    loop.run_forever()


Transport and Protocol
-----------------------

.. code-block:: python

    import asyncio

    class EchoProtocol(asyncio.Protocol):

        def connection_made(self, transport):
            peername = transport.get_extra_info('peername')
            print('Connection from {}'.format(peername))
            self.transport = transport

        def data_received(self, data):
            msg = data.decode()
            self.transport.write(data)

    loop = asyncio.get_event_loop()
    coro = loop.create_server(EchoProtocol, 'localhost', 5566)
    server = loop.run_until_complete(coro)

    try:
        loop.run_forever()
    except:
        loop.run_until_complete(server.wait_closed())
    finally:
        loop.close()

output:

.. code-block:: bash

    # console 1
    $ nc localhost 5566
    Hello
    Hello

    # console 2
    $ nc localhost 5566
    World
    World

Transport and Protocol with SSL
---------------------------------

.. code-block:: python

    import asyncio
    import ssl

    def make_header():
        head  = b'HTTP/1.1 200 OK\r\n'
        head += b'Content-Type: text/html\r\n'
        head += b'\r\n'
        return head

    def make_body():
        resp  = b"<html>"
        resp += b"<h1>Hello SSL</h1>"
        resp += b"</html>"
        return resp

    sslctx = ssl.SSLContext(ssl.PROTOCOL_SSLv23)
    sslctx.load_cert_chain(certfile='./root-ca.crt',
                           keyfile='./root-ca.key')

    class Service(asyncio.Protocol):

        def connection_made(self, tr):
            self.tr = tr
            self.total = 0

        def data_received(self, data):
            if data:
                resp  = make_header()
                resp += make_body()
                self.tr.write(resp)
            self.tr.close()


    async def start():
        server = await loop.create_server(Service,
                                         'localhost',
                                         4433,
                                         ssl=sslctx)
        await server.wait_closed()

    try:
        loop = asyncio.get_event_loop()
        loop.run_until_complete(start())
    finally:
        loop.close()


output:

.. code-block:: bash

    $ openssl genrsa -out root-ca.key 2048
    $ openssl req -x509 -new -nodes -key root-ca.key -days 365 -out root-ca.crt
    $ python3 ssl_web_server.py

    # then open browser: https://localhost:4433


What ``loop.create_server`` do?
--------------------------------

.. code-block:: python

    import asyncio
    import socket

    loop = asyncio.get_event_loop()

    async def create_server(loop, protocol_factory, host,
                            port, *args, **kwargs):
       sock = socket.socket(socket.AF_INET,
                            socket.SOCK_STREAM, 0)
       sock.setsockopt(socket.SOL_SOCKET,
                       socket.SO_REUSEADDR, 1)
       sock.setblocking(False)
       sock.bind((host, port))
       sock.listen(10)
       sockets = [sock]
       server = asyncio.base_events.Server(loop, sockets)
       loop._start_serving(protocol_factory, sock, None, server)

       return server


    class EchoProtocol(asyncio.Protocol):
        def connection_made(self, transport):
            peername = transport.get_extra_info('peername')
            print('Connection from {}'.format(peername))
            self.transport = transport

        def data_received(self, data):
            message = data.decode()
            self.transport.write(data)

    # Equal to: loop.create_server(EchoProtocol,
    #                              'localhost', 5566)
    coro = create_server(loop, EchoProtocol, 'localhost', 5566)
    server = loop.run_until_complete(coro)

    try:
        loop.run_forever()
    finally:
        server.close()
        loop.run_until_complete(server.wait_closed())
        loop.close()

output:

.. code-block:: bash

    # console1
    $ nc localhost 5566
    Hello
    Hello

    # console2
    $ nc localhost 5566
    asyncio
    asyncio

Inline callback
---------------

.. code-block:: python

    >>> import asyncio
    >>> async def foo():
    ...     await asyncio.sleep(1)
    ...     return "foo done"
    ...
    >>> async def bar():
    ...     await asyncio.sleep(.5)
    ...     return "bar done"
    ...
    >>> async def ker():
    ...     await asyncio.sleep(3)
    ...     return "ker done"
    ...
    >>> async def task():
    ...     res = await foo()
    ...     print(res)
    ...     res = await bar()
    ...     print(res)
    ...     res = await ker()
    ...     print(res)
    ...
    >>> loop = asyncio.get_event_loop()
    >>> loop.run_until_complete(task())
    foo done
    bar done
    ker done

Asynchronous Iterator
---------------------

.. code-block:: python

    # ref: PEP-0492
    # need Python >= 3.5

    >>> class AsyncIter:
    ...     def __init__(self, it):
    ...         self._it = iter(it)
    ...     async def __aiter__(self):
    ...         return self
    ...     async def __anext__(self):
    ...         await asyncio.sleep(1)
    ...         try:
    ...             val = next(self._it)
    ...         except StopIteration:
    ...             raise StopAsyncIteration
    ...         return val
    ...
    >>> async def foo():
    ...     it = [1,2,3]
    ...     async for _ in AsyncIter(it):
    ...         print(_)
    ...
    >>> loop = asyncio.get_event_loop()
    >>> loop.run_until_complete(foo())
    1
    2
    3

What is asynchronous iterator
------------------------------

.. code-block:: python

    >>> import asyncio
    >>> class AsyncIter:
    ...     def __init__(self, it):
    ...         self._it = iter(it)
    ...     async def __aiter__(self):
    ...         return self
    ...     async def __anext__(self):
    ...         await asyncio.sleep(1)
    ...         try:
    ...             val = next(self._it)
    ...         except StopIteration:
    ...             raise StopAsyncIteration
    ...         return val
    ...
    >>> async def foo():
    ...     _ = [1,2,3]
    ...     running = True
    ...     it = AsyncIter(_)
    ...     while running:
    ...         try:
    ...             res = await it.__anext__()
    ...             print(res)
    ...         except StopAsyncIteration:
    ...             running = False
    ...
    >>> loop = asyncio.get_event_loop()
    >>> loop.run_until_complete(loop.create_task(foo()))
    1
    2
    3

Asynchronous context manager
----------------------------

.. code-block:: python

    # ref: PEP-0492
    # need Python >= 3.5

    >>> class AsyncCtxMgr:
    ...     async def __aenter__(self):
    ...         await asyncio.sleep(3)
    ...         print("__anter__")
    ...         return self
    ...     async def __aexit__(self, *exc):
    ...         await asyncio.sleep(1)
    ...         print("__aexit__")
    ...
    >>> async def hello():
    ...     async with AsyncCtxMgr() as m:
    ...         print("hello block")
    ...
    >>> async def world():
    ...     print("world block")
    ...
    >>> t = loop.create_task(world())
    >>> loop.run_until_complete(hello())
    world block
    __anter__
    hello block
    __aexit__


What is asynchronous context manager
-------------------------------------

.. code-block:: python

    >>> import asyncio
    >>> class AsyncManager:
    ...     async def __aenter__(self):
    ...         await asyncio.sleep(5)
    ...         print("__aenter__")
    ...     async def __aexit__(self, *exc_info):
    ...         await asyncio.sleep(3)
    ...         print("__aexit__")
    ...
    >>> async def foo():
    ...     import sys
    ...     mgr = AsyncManager()
    ...     await mgr.__aenter__()
    ...     print("body")
    ...     await mgr.__aexit__(*sys.exc_info())
    ...
    >>> loop = asyncio.get_event_loop()
    >>> loop.run_until_complete(loop.create_task(foo()))
    __aenter__
    body
    __aexit__


decorator ``@asynccontextmanager``
------------------------------------

**New in Python 3.7**

- Issue 29679_ - Add @contextlib.asynccontextmanager

.. code-block:: python

    >>> import asyncio
    >>> from contextlib import asynccontextmanager
    >>> @asynccontextmanager
    ... async def coro(msg):
    ...     await asyncio.sleep(1)
    ...     yield msg
    ...     await asyncio.sleep(0.5)
    ...     print('done')
    ...
    >>> async def main():
    ...     async with coro("Hello") as m:
    ...         await asyncio.sleep(1)
    ...         print(m)
    ...
    >>> loop = asyncio.get_event_loop()
    >>> loop.run_until_complete(main())
    Hello
    done


What `loop.sock_*` do?
-----------------------

.. code-block:: python

    import asyncio
    import socket

    def sock_accept(self, sock, fut=None, registed=False):
        fd = sock.fileno()
        if fut is None:
            fut = self.create_future()
        if registed:
            self.remove_reader(fd)
        try:
            conn, addr = sock.accept()
            conn.setblocking(False)
        except (BlockingIOError, InterruptedError):
            self.add_reader(fd, self.sock_accept, sock, fut, True)
        except Exception as e:
            fut.set_exception(e)
        else:
            fut.set_result((conn, addr))
        return fut

    def sock_recv(self, sock, n , fut=None, registed=False):
        fd = sock.fileno()
        if fut is None:
            fut = self.create_future()
        if registed:
            self.remove_reader(fd)
        try:
            data = sock.recv(n)
        except (BlockingIOError, InterruptedError):
            self.add_reader(fd, self.sock_recv, sock, n ,fut, True)
        except Exception as e:
            fut.set_exception(e)
        else:
            fut.set_result(data)
        return fut

    def sock_sendall(self, sock, data, fut=None, registed=False):
        fd = sock.fileno()
        if fut is None:
            fut = self.create_future()
        if registed:
            self.remove_writer(fd)
        try:
            n = sock.send(data)
        except (BlockingIOError, InterruptedError):
            n = 0
        except Exception as e:
            fut.set_exception(e)
            return
        if n == len(data):
            fut.set_result(None)
        else:
            if n:
                data = data[n:]
            self.add_writer(fd, sock, data, fut, True)
        return fut

    async def handler(loop, conn):
        while True:
            msg = await loop.sock_recv(conn, 1024)
            if msg: await loop.sock_sendall(conn, msg)
            else: break
        conn.close()

    async def server(loop):
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.setblocking(False)
        sock.bind(('localhost', 9527))
        sock.listen(10)

        while True:
            conn, addr = await loop.sock_accept(sock)
            loop.create_task(handler(loop, conn))

    EventLoop = asyncio.SelectorEventLoop
    EventLoop.sock_accept = sock_accept
    EventLoop.sock_recv = sock_recv
    EventLoop.sock_sendall = sock_sendall
    loop = EventLoop()

    try:
        loop.run_until_complete(server(loop))
    except KeyboardInterrupt:
        pass
    finally:
        loop.close()

output:

.. code-block:: bash

    # console 1
    $ python3 async_sock.py &
    $ nc localhost 9527
    Hello
    Hello

    # console 2
    $ nc localhost 9527
    asyncio
    asyncio


Simple asyncio connection pool
-------------------------------

.. code-block:: python

    import asyncio
    import socket
    import uuid

    class Transport:

        def __init__(self, loop, host, port):
            self.used = False

            self._loop = loop
            self._host = host
            self._port = port
            self._sock = socket.socket(
                    socket.AF_INET, socket.SOCK_STREAM)
            self._sock.setblocking(False)
            self._uuid = uuid.uuid1()

        async def connect(self):
            loop, sock = self._loop, self._sock
            host, port = self._host, self._port
            return (await loop.sock_connect(sock, (host, port)))

        async def sendall(self, msg):
            loop, sock = self._loop, self._sock
            return (await loop.sock_sendall(sock, msg))

        async def recv(self, buf_size):
            loop, sock = self._loop, self._sock
            return (await loop.sock_recv(sock, buf_size))

        def close(self):
            if self._sock: self._sock.close()

        @property
        def alive(self):
            ret = True if self._sock else False
            return ret

        @property
        def uuid(self):
            return self._uuid


    class ConnectionPool:

        def __init__(self, loop, host, port, max_conn=3):
            self._host = host
            self._port = port
            self._max_conn = max_conn
            self._loop = loop

            conns = [Transport(loop, host, port) for _ in range(max_conn)]
            self._conns = conns

        def __await__(self):
            for _c in self._conns:
                yield from _c.connect().__await__()
            return self

        def getconn(self, fut=None):
            if fut is None:
                fut = self._loop.create_future()

            for _c in self._conns:
                if _c.alive and not _c.used:
                    _c.used = True
                    fut.set_result(_c)
                    break
            else:
                loop.call_soon(self.getconn, fut)

            return fut

        def release(self, conn):
            if not conn.used:
                return
            for _c in self._conns:
                if _c.uuid != conn.uuid:
                    continue
                _c.used = False
                break

        def close(self):
            for _c in self._conns:
                _c.close()


    async def handler(pool, msg):
        conn = await pool.getconn()
        byte = await conn.sendall(msg)
        mesg = await conn.recv(1024)
        pool.release(conn)
        return 'echo: {}'.format(mesg)


    async def main(loop, host, port):
        try:
            # creat connection pool
            pool = await ConnectionPool(loop, host, port)

            # generate messages
            msgs = ['coro_{}'.format(_).encode('utf-8') for _ in range(5)]

            # create tasks
            fs = [loop.create_task(handler(pool, _m)) for _m in msgs]

            # wait all tasks done
            done, pending = await asyncio.wait(fs)
            for _ in done: print(_.result())
        finally:
            pool.close()


    loop = asyncio.get_event_loop()
    host = '127.0.0.1'
    port = 9527

    try:
        loop.run_until_complete(main(loop, host, port))
    except KeyboardInterrupt:
        pass
    finally:
        loop.close()

output:

.. code-block:: bash

    $ ncat -l 9527 --keep-open --exec "/bin/cat" &
    $ python3 conn_pool.py
    echo: b'coro_1'
    echo: b'coro_0'
    echo: b'coro_2'
    echo: b'coro_3'
    echo: b'coro_4'


Simple asyncio UDP echo server
--------------------------------

.. code-block:: python

    import asyncio
    import socket

    loop = asyncio.get_event_loop()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.setblocking(False)

    host = 'localhost'
    port = 3553

    sock.bind((host, port))

    def recvfrom(loop, sock, n_bytes, fut=None, registed=False):
        fd = sock.fileno()
        if fut is None:
            fut = loop.create_future()
        if registed:
            loop.remove_reader(fd)

        try:
            data, addr = sock.recvfrom(n_bytes)
        except (BlockingIOError, InterruptedError):
            loop.add_reader(fd, recvfrom, loop, sock, n_bytes, fut, True)
        else:
            fut.set_result((data, addr))
        return fut

    def sendto(loop, sock, data, addr, fut=None, registed=False):
        fd = sock.fileno()
        if fut is None:
            fut = loop.create_future()
        if registed:
            loop.remove_writer(fd)
        if not data:
            return

        try:
            n = sock.sendto(data, addr)
        except (BlockingIOError, InterruptedError):
            loop.add_writer(fd, sendto, loop, sock, data, addr, fut, True)
        else:
            fut.set_result(n)
        return fut

    async def udp_server(loop, sock):
        while True:
            data, addr = await recvfrom(loop, sock, 1024)
            n_bytes = await sendto(loop, sock, data, addr)

    try:
        loop.run_until_complete(udp_server(loop, sock))
    finally:
        loop.close()

output:

.. code-block:: bash

    $ python3 udp_server.py
    $ nc -u localhost 3553
    Hello UDP
    Hello UDP


Simple asyncio web server
-------------------------

.. code-block:: python

    import asyncio
    import socket

    host = 'localhost'
    port = 9527
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.setblocking(False)
    s.bind((host, port))
    s.listen(10)

    loop = asyncio.get_event_loop()

    def make_header():
        header  = b"HTTP/1.1 200 OK\r\n"
        header += b"Content-Type: text/html\r\n"
        header += b"\r\n"
        return header

    def make_body():
        resp  = b'<html>'
        resp += b'<body><h3>Hello World</h3></body>'
        resp += b'</html>'
        return resp

    async def handler(conn):
        req = await loop.sock_recv(conn, 1024)
        if req:
            resp = make_header()
            resp += make_body()
            await loop.sock_sendall(conn, resp)
        conn.close()

    async def server(sock, loop):
        while True:
            conn, addr = await loop.sock_accept(sock)
            loop.create_task(handler(conn))

    try:
        loop.run_until_complete(server(s, loop))
    except KeyboardInterrupt:
        pass
    finally:
        loop.close()
        s.close()
    # Then open browser with url: localhost:9527


Simple HTTPS asyncio web server
--------------------------------

.. code-block:: python

    import asyncio
    import socket
    import ssl

    def make_header():
        head  = b'HTTP/1.1 200 OK\r\n'
        head += b'Content-type: text/html\r\n'
        head += b'\r\n'
        return head

    def make_body():
        resp  = b'<html>'
        resp += b'<h1>Hello SSL</h1>'
        resp += b'</html>'
        return resp

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM, 0)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.setblocking(False)
    sock.bind(('localhost' , 4433))
    sock.listen(10)

    sslctx = ssl.SSLContext(ssl.PROTOCOL_SSLv23)
    sslctx.load_cert_chain(certfile='./root-ca.crt',
                           keyfile='./root-ca.key')


    def do_handshake(loop, sock, waiter):
        sock_fd = sock.fileno()
        try:
            sock.do_handshake()
        except ssl.SSLWantReadError:
            loop.remove_reader(sock_fd)
            loop.add_reader(sock_fd, do_handshake,
                            loop, sock, waiter)
            return
        except ssl.SSLWantWriteError:
            loop.remove_writer(sock_fd)
            loop.add_writer(sock_fd, do_handshake,
                            loop, sock, waiter)
            return

        loop.remove_reader(sock_fd)
        loop.remove_writer(sock_fd)
        waiter.set_result(None)


    def handle_read(loop, conn, waiter):
        try:
            req = conn.recv(1024)
        except ssl.SSLWantReadError:
            loop.remove_reader(conn.fileno())
            loop.add_reader(conn.fileno(), handle_read,
                            loop, conn, waiter)
            return
        loop.remove_reader(conn.fileno())
        waiter.set_result(req)


    def handle_write(loop, conn, msg, waiter):
        try:
            resp = make_header()
            resp += make_body()
            ret = conn.send(resp)
        except ssl.SSLWantReadError:
            loop.remove_writer(conn.fileno())
            loop.add_writer(conn.fileno(), handle_write,
                            loop, conn, waiter)
            return
        loop.remove_writer(conn.fileno())
        conn.close()
        waiter.set_result(None)


    async def server(loop):
        while True:
            conn, addr = await loop.sock_accept(sock)
            conn.setblocking(False)
            sslconn = sslctx.wrap_socket(conn,
                                         server_side=True,
                                         do_handshake_on_connect=False)
            # wait SSL handshake
            waiter = loop.create_future()
            do_handshake(loop, sslconn, waiter)
            await waiter

            # wait read request
            waiter = loop.create_future()
            handle_read(loop, sslconn, waiter)
            msg = await waiter

            # wait write response
            waiter = loop.create_future()
            handle_write(loop, sslconn, msg, waiter)
            await waiter

    loop = asyncio.get_event_loop()
    try:
        loop.run_until_complete(server(loop))
    finally:
        loop.close()

output:

.. code-block:: bash

    # console 1

    $ openssl genrsa -out root-ca.key 2048
    $ openssl req -x509 -new -nodes -key root-ca.key -days 365 -out root-ca.crt
    $ python3 Simple_https_server.py

    # console 2

    $ curl https://localhost:4433 -v          \
    >      --resolve localhost:4433:127.0.0.1 \
    >      --cacert ~/test/root-ca.crt


Simple asyncio WSGI web server
------------------------------

.. code-block:: python

    # ref: PEP333

    import asyncio
    import socket
    import io
    import sys

    from flask import Flask, Response

    host = 'localhost'
    port = 9527
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.setblocking(False)
    s.bind((host, port))
    s.listen(10)

    loop = asyncio.get_event_loop()

    class WSGIServer(object):

        def __init__(self, sock, app):
            self._sock = sock
            self._app = app
            self._header = []

        def parse_request(self, req):
            """ HTTP Request Format:

            GET /hello.htm HTTP/1.1\r\n
            Accept-Language: en-us\r\n
            ...
            Connection: Keep-Alive\r\n
            """
            # bytes to string
            req_info = req.decode('utf-8')
            first_line = req_info.splitlines()[0]
            method, path, ver = first_line.split()
            return method, path, ver

        def get_environ(self, req, method, path):
            env = {}

            # Required WSGI variables
            env['wsgi.version']      = (1, 0)
            env['wsgi.url_scheme']   = 'http'
            env['wsgi.input']        = req
            env['wsgi.errors']       = sys.stderr
            env['wsgi.multithread']  = False
            env['wsgi.multiprocess'] = False
            env['wsgi.run_once']     = False

            # Required CGI variables
            env['REQUEST_METHOD']    = method    # GET
            env['PATH_INFO']         = path      # /hello
            env['SERVER_NAME']       = host      # localhost
            env['SERVER_PORT']       = str(port) # 9527
            return env

        def start_response(self, status, resp_header, exc_info=None):
            header = [('Server', 'WSGIServer 0.2')]
            self.headers_set = [status, resp_header + header]

        async def finish_response(self, conn, data, headers):
            status, resp_header = headers

            # make header
            resp = 'HTTP/1.1 {0}\r\n'.format(status)
            for header in resp_header:
                resp += '{0}: {1}\r\n'.format(*header)
            resp += '\r\n'

            # make body
            resp += '{0}'.format(data)
            try:
                await loop.sock_sendall(conn, str.encode(resp))
            finally:
                conn.close()

        async def run_server(self):
            while True:
                conn, addr = await loop.sock_accept(self._sock)
                loop.create_task(self.handle_request(conn))

        async def handle_request(self, conn):
            # get request data
            req = await loop.sock_recv(conn, 1024)
            if req:
                method, path, ver = self.parse_request(req)
                # get environment
                env = self.get_environ(req, method, path)
                # get application execute result
                res = self._app(env, self.start_response)
                res = [_.decode('utf-8') for _ in list(res)]
                res = ''.join(res)
                loop.create_task(
                     self.finish_response(conn, res, self.headers_set))

    app = Flask(__name__)

    @app.route('/hello')
    def hello():
        return Response("Hello WSGI",mimetype="text/plain")

    server = WSGIServer(s, app.wsgi_app)
    try:
        loop.run_until_complete(server.run_server())
    except:
        pass
    finally:
        loop.close()

    # Then open browser with url: localhost:9527/hello


.. _29679: https://bugs.python.org/issue29679
